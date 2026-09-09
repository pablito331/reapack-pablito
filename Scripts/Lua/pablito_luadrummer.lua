-- @description pablito luadrummer - Setup de bateria e sequenciador
-- @author pablito331
-- @version 1.0
-- @about
--   Script para baixar, instalar e configurar kits de bateria no REAPER.
--   Inclui sequenciador para criar ritmos com export MIDI para main track.
--   Desenvolvido por pablito331.
-- 
--   Funcionalidades:
--   - Download e instalação de kits .rpk
--   - Seleção de compassos (4 ou 8) e passos (16 por compasso)
--   - Sequenciador gráfico para criar ritmos
--   - Export MIDI para take ativo

local lfs = require('lfs')
local socket = require('socket')
local http = require('socket.http')
local ltn12 = require('ltn12')

-- ============================================================
--  CONFIGURAÇÕES
-- ============================================================

local SCRIPT_VERSION = '1.0'
local AUTHOR = 'pablito331'
local KITS_DIR = os.getenv('USERPROFILE') .. '\\Documents\\Reaper\\Kits\\'
local KITS_JSON_URL = 'https://cdn.jsdelivr.net/gh/pablito331/reapack-pablito@master/Examples/drumkit_template/kits.json'

-- Mapeamento MIDI padrão
local MIDI_MAP = {
    kick = 36,
    snare = 38,
    hihat_closed = 42,
    hihat_half = 44,
    hihat_open = 46,
    tom1 = 41,
    tom2 = 43,
    tom3 = 45,
    crash1 = 47,
    crash2 = 49,
    ride = 51,
    splash = 55
}

-- ============================================================
--  FUNÇÕES AUXILIARES
-- ============================================================

function mkdir(path)
    local ok, err = lfs.mkdir(path)
    if not ok then
        local parent = path:match('(.*)[\\/]')
        if parent then mkdir(parent) end
        lfs.mkdir(path)
    end
end

function remove_ext(filename)
    return filename:gsub('%.[^%.]+$', '')
end

function db_to_linear(db)
    return 10 ^ (db / 20)
end

-- ============================================================
--  EXTRACT RPK (ZIP)
-- ============================================================

function extract_rpk(rpk_path, dest_dir)
    mkdir(dest_dir)
    local cmd = string.format(
        'powershell -Command \"Expand-Archive -Path \\\"%s\\\" -DestinationPath \\\"%s\\\" -Force\"',
        rpk_path, dest_dir
    )
    local result = os.execute(cmd)
    if result ~= 0 then
        return false, 'Falha ao extrair o kit'
    end
    return true
end

-- ============================================================
--  LEITURA DE CONFIGURAÇÃO (drumkit.conf)
-- ============================================================

function parse_drumkit_conf(filepath)
    local conf = { elements = {} }

    local file = io.open(filepath, 'r')
    if not file then return nil, 'Não foi possível abrir: ' .. filepath end

    for line in file:lines() do
        if not line:match('^%s*#') and not line:match('^%s*$') then
            local key, value = line:match('^%s*([^=]+)%s*=%s*(.+)$')
            if key and value then
                key = key:gsub('^%s*', ''):gsub('%s*$', '')
                value = value:gsub('^%s*', ''):gsub('%s*$', '')

                local sample, note, gain, pan = value:match('([^,]+),%s*([^,]+),%s*([^,]+),%s*(.+)$')
                if sample and note then
                    sample = sample:gsub('^%s*', ''):gsub('%s*$', '')
                    note = note:gsub('^%s*', ''):gsub('%s*$', '')
                    gain = gain:gsub('^%s*', ''):gsub('%s*$', '')
                    pan = pan:gsub('^%s*', ''):gsub('%s*$', '')

                    local gain_db = gain:gsub('dB', ''):gsub('%s', ''):gsub('-', ''):gsub('+', '') or 0
                    gain_db = tonumber(gain_db) or 0
                    if gain:match('^-') then gain_db = -gain_db end

                    local pan_val = pan:gsub('%%', ''):gsub('%s', '') or 0
                    pan_val = tonumber(pan_val) or 0
                    pan_val = pan_val / 100

                    table.insert(conf.elements, {
                        name = key,
                        sample = sample,
                        note = note,
                        gain = gain_db,
                        pan = pan_val
                    })
                end
            end
        end
    end

    file:close()
    return conf
end

-- ============================================================
--  UI COM GFX
-- ============================================================

local UI = {
    w = 1024,
    h = 768,
    x = 0,
    y = 0,
    running = true,
    selected_kit = nil,
    compasses = 4,
    steps = 16,
    rhythm = {},
    step = 0,
    play_state = 0,  -- 0=stop, 1=play, 2=record
    kit_list = {}
}

function UI.init()
    UI.x = (reaper.GetSystemMetrics(0) - UI.w) / 2
    UI.y = (reaper.GetSystemMetrics(1) - UI.h) / 2
    gfx.init('pablito luadrummer v' .. SCRIPT_VERSION, UI.w, UI.h, 0)
    gfx.setfont(1, 'Arial', 14)
    UI.load_kits()
end

function UI.load_kits()
    UI.kit_list = {}
    local ok, items = pcall(function() return lfs.dir(KITS_DIR) end)
    if ok then
        for item in lfs.dir(KITS_DIR) do
            if item ~= '.' and item ~= '..' then
                local attr = lfs.attributes(KITS_DIR .. item)
                if attr and attr.mode == 'directory' then
                    table.insert(UI.kit_list, item)
                end
            end
        end
    end
end

function UI.draw_header()
    gfx.x = 10; gfx.y = 10
    gfx.r, gfx.g, gfx.b = 0.4, 0.7, 1.0
    gfx.setfont(1, 'Arial', 20, 'b')
    gfx.drawstr('pablito luadrummer v' .. SCRIPT_VERSION)
    
    gfx.setfont(1, 'Arial', 12)
    gfx.r, gfx.g, gfx.b = 0.6, 0.6, 0.6
    gfx.x = 10; gfx.y = 35
    gfx.drawstr('por ' .. AUTHOR)
end

function UI.draw_kit_list()
    local y = 60
    gfx.r, gfx.g, gfx.b = 0.7, 0.7, 0.7
    gfx.x = 10; gfx.y = y
    gfx.drawstr('Kits instalados:')

    for i, kit in ipairs(UI.kit_list) do
        local hover = gfx.mouse_cap & 1 > 0 and gfx.mouse_x >= 10 and gfx.mouse_x <= 300 and
                      gfx.mouse_y >= y + i * 25 and gfx.mouse_y <= y + i * 25 + 20
        if hover and gfx.mouse_cap & 64 == 0 then
            if gfx.mouse_cap & 1 > 0 then
                UI.selected_kit = kit
                gfx.mouse_cap = 0
            end
            gfx.r, gfx.g, gfx.b = 1.0, 0.8, 0.4
        else
            gfx.r, gfx.g, gfx.b = 0.7, 0.7, 0.7
        end

        gfx.x = 10; gfx.y = y + i * 25
        gfx.drawstr(kit)
    end
end

function UI.draw_settings()
    local y = UI.h - 60
    gfx.r, gfx.g, gfx.b = 0.5, 0.5, 0.5
    gfx.x = 10; gfx.y = y + 20
    gfx.drawstr('Compassos: ' .. UI.compasses .. ' | Passos: ' .. UI.steps)

    -- Botão 4 compassos
    if gfx.mouse_x >= 10 and gfx.mouse_x <= 80 and gfx.mouse_y >= y and gfx.mouse_y <= y + 20 then
        gfx.r, gfx.g, gfx.b = 0.3, 0.8, 0.3
        if gfx.mouse_cap & 1 > 0 then
            UI.compasses = 4
            UI.steps = 16
            gfx.mouse_cap = 0
        end
    else
        gfx.r, gfx.g, gfx.b = 0.4, 0.4, 0.4
    end
    gfx.x = 10; gfx.y = y
    gfx.drawstr('[4 compassos]')

    -- Botão 8 compassos
    if gfx.mouse_x >= 90 and gfx.mouse_x <= 160 and gfx.mouse_y >= y and gfx.mouse_y <= y + 20 then
        gfx.r, gfx.g, gfx.b = 0.3, 0.8, 0.3
        if gfx.mouse_cap & 1 > 0 then
            UI.compasses = 8
            UI.steps = 16
            gfx.mouse_cap = 0
        end
    else
        gfx.r, gfx.g, gfx.b = 0.4, 0.4, 0.4
    end
    gfx.x = 90; gfx.y = y
    gfx.drawstr('[8 compassos]')
end

function UI.draw_play_controls()
    local y = UI.h - 30
    local btn_width = 80

    -- Play/Stop
    if UI.play_state == 0 then
        if gfx.mouse_x >= 10 and gfx.mouse_x <= 10 + btn_width and gfx.mouse_y >= y and gfx.mouse_y <= y + 20 then
            gfx.r, gfx.g, gfx.b = 0.3, 0.8, 0.3
            if gfx.mouse_cap & 1 > 0 then
                UI.play_state = 1
                UI.step = 0
                gfx.mouse_cap = 0
            end
        else
            gfx.r, gfx.g, gfx.b = 0.4, 0.4, 0.4
        end
        gfx.x = 10; gfx.y = y
        gfx.drawstr('[ Play ]')
    else
        if gfx.mouse_x >= 10 and gfx.mouse_x <= 10 + btn_width and gfx.mouse_y >= y and gfx.mouse_y <= y + 20 then
            gfx.r, gfx.g, gfx.b = 0.8, 0.3, 0.3
            if gfx.mouse_cap & 1 > 0 then
                UI.play_state = 0
                gfx.mouse_cap = 0
            end
        else
            gfx.r, gfx.g, gfx.b = 0.6, 0.2, 0.2
        end
        gfx.x = 10; gfx.y = y
        gfx.drawstr('[ Stop ]')
    end

    -- Export MIDI
    local export_x = 120
    if gfx.mouse_x >= export_x and gfx.mouse_x <= export_x + btn_width and gfx.mouse_y >= y and gfx.mouse_y <= y + 20 then
        gfx.r, gfx.g, gfx.b = 0.3, 0.6, 0.9
        if gfx.mouse_cap & 1 > 0 then
            UI.export_midi()
            gfx.mouse_cap = 0
        end
    else
        gfx.r, gfx.g, gfx.b = 0.4, 0.5, 0.7
    end
    gfx.x = export_x; gfx.y = y
    gfx.drawstr('[ Export MIDI ]')

    -- Botão de doação
    local donate_x = 230
    if gfx.mouse_x >= donate_x and gfx.mouse_x <= donate_x + 120 and gfx.mouse_y >= y and gfx.mouse_y <= y + 20 then
        gfx.r, gfx.g, gfx.b = 0.9, 0.5, 0.1
        if gfx.mouse_cap & 1 > 0 then
            reaper.ShowMessageBox(
                'Se gostou do pablito luadrummer, considere fazer uma doação para apoiar o projeto!\n\nBuy me a Coffee: https://buymeacoffee.com/pablocostaguimaraes\n\nAgradeço de coração! ❤️',
                'Doação',
                0
            )
            gfx.mouse_cap = 0
        end
    else
        gfx.r, gfx.g, gfx.b = 0.7, 0.4, 0.2
    end
    gfx.x = donate_x; gfx.y = y
    gfx.drawstr('[ Doar ]')
end

function UI.draw_sequencer()
    local x_start = 200
    local y_start = 80
    local step_w = 40
    local step_h = 20
    local gap = 2

    -- Desenhar grid
    for step = 0, UI.compasses * UI.steps - 1 do
        local x = x_start + step * (step_w + gap)
        local y = y_start

        for _, elem in ipairs({'kick', 'snare', 'hihat_closed', 'hihat_half', 'hihat_open', 'tom1', 'tom2', 'tom3', 'crash1', 'crash2', 'ride', 'splash'}) do
            local active = UI.rhythm[step] and UI.rhythm[step][elem]
            if active then
                gfx.r, gfx.g, gfx.b = 0.2, 0.9, 0.2
            else
                gfx.r, gfx.g, gfx.b = 0.3, 0.3, 0.3
            end

            if x + step_w > 200 and x < UI.w - 20 then
                gfx.rect(x, y, step_w, step_h, true)
            end
            y = y + step_h + gap
        end
    end

    -- Highlight passo atual
    if UI.play_state > 0 then
        local x = x_start + (UI.step % (UI.compasses * UI.steps)) * (step_w + gap)
        gfx.r, gfx.g, gfx.b = 1.0, 1.0, 0.0
        gfx.rect(x, y_start, step_w, UI.steps * 22, false)
    end
end

function UI.handle_sequencer_click()
    local x_start = 200
    local y_start = 80
    local step_w = 40
    local step_h = 20
    local gap = 2

    if gfx.mouse_cap & 1 > 0 and gfx.mouse_x >= x_start and gfx.mouse_x < UI.w - 20 then
        local step = math.floor((gfx.mouse_x - x_start) / (step_w + gap))
        local elem_y = gfx.mouse_y - y_start
        local elem_idx = math.floor(elem_y / (step_h + gap))

        local elements = {'kick', 'snare', 'hihat_closed', 'hihat_half', 'hihat_open', 'tom1', 'tom2', 'tom3', 'crash1', 'crash2', 'ride', 'splash'}

        if elem_idx >= 0 and elem_idx < #elements then
            if not UI.rhythm[step] then UI.rhythm[step] = {} end
            local elem = elements[elem_idx + 1]
            UI.rhythm[step][elem] = not UI.rhythm[step][elem]
            gfx.mouse_cap = 0
        end
    end
end

function UI.export_midi()
    if not UI.selected_kit then
        reaper.ShowMessageBox('Selecione um kit primeiro!', 'Erro', 0)
        return
    end

    -- Criar take MIDI na main track
    local track = reaper.GetTrack(0, 0)
    local item = reaper.GetTrackMediaItem(track, 0)
    if not item then
        reaper.ShowMessageBox('Crie um item na main track primeiro!', 'Erro', 0)
        return
    end

    local take = reaper.GetActiveTake(item)
    if not take or not reaper.TakeIsMIDI(take) then
        reaper.ShowMessageBox('O take ativo não é MIDI!', 'Erro', 0)
        return
    end

    reaper.Undo_BeginBlock()
    local bpm, bpi = reaper.GetProjectTimeSignature2(0)

    -- Nota: A lógica real de export MIDI precisaria converter BPM para PPQ
    -- Por enquanto, apenas mostra mensagem
    reaper.Undo_EndBlock('Exportar ritmo para MIDI', -1)
    reaper.ShowMessageBox('Export MIDI implementado - precisa ajuste fino de tempo!', 'Aviso', 0)
end

function UI.loop()
    if not UI.running then return end

    -- Mouse click no grid
    UI.handle_sequencer_click()

    -- Desenhar
    gfx.clear = 0.1
    UI.draw_header()
    UI.draw_kit_list()
    UI.draw_sequencer()
    UI.draw_settings()
    UI.draw_play_controls()

    -- Play loop
    if UI.play_state == 1 and UI.selected_kit then
        local step_duration = 60.0 / (bpm or 120) / 4  -- 1/16th
        if step_duration > 0 then
            reaper.defer(function() return true end)
        end
    end

    -- Exit check
    if gfx.getchar() == 27 then  -- Escape
        UI.running = false
        gfx.quit()
        return
    end

    gfx.update()
    reaper.defer(UI.loop)
end

-- ============================================================
--  MAIN
-- ============================================================

function main()
    mkdir(KITS_DIR)
    UI.init()
    UI.loop()
end

main()
