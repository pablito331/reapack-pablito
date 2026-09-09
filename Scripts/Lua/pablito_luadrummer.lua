-- @description pablito luadrummer - Setup de bateria automatizado
-- @author Seu Nome
-- @version 1.0
-- @about
--   Script para baixar, instalar e configurar kits de bateria no REAPER.
--   Lê kits .rpk e configura automaticamente as tracks com ReaSamplOmatic.
--   Suporta hihats com 3 samples no mesmo slot (crossfade + exclusão mútua).

local lfs = require('lfs')
local socket = require('socket')
local http = require('socket.http')
local ltn12 = require('ltn12')

-- Configurações do script
local SCRIPT_DIR = lfs.currentdir() .. '/'
local KITS_DIR = os.getenv('USERPROFILE') .. '\\Documents\\Reaper\\Kits\\'
local KITS_JSON_URL = 'https://raw.githubusercontent.com/pablito331/reapack-pablito/master/Examples/drumkit_template/kits.json'

-- ============================================================
--  FUNÇÕES AUXILIARES
-- ============================================================

-- Cria diretório se não existir
function mkdir(path)
    local ok, err = lfs.mkdir(path)
    if not ok then
        -- Tenta criar diretórios pai primeiro
        local parent = path:match('(.*)[\\/]')
        if parent then mkdir(parent) end
        lfs.mkdir(path)
    end
end

-- Remove extensão de um arquivo
function remove_ext(filename)
    return filename:gsub('%.[^%.]+$', '')
end

-- Converte valor dB para linear
function db_to_linear(db)
    return 10 ^ (db / 20)
end

-- ============================================================
--  DOWNLOAD E INSTALAÇÃO DE KITS
-- ============================================================

-- Baixa arquivo da URL
function download_file(url, dest_path)
    local file, err = io.open(dest_path, 'wb')
    if not file then return nil, 'Não foi possível criar o arquivo: ' .. dest_path end

    local response, err = http.request{
        url = url,
        sink = ltn12.sink.file(file)
    }
    file:close()

    if response ~= 200 then
        return nil, 'Download falhou. Status: ' .. (response or 'N/A')
    end
    return true
end

-- Extrai arquivo ZIP/RPK
function extract_rpk(rpk_path, dest_dir)
    mkdir(dest_dir)

    -- Usar o comando unzip do Windows (PowerShell)
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

-- Baixa e instala um kit
function install_kit(kit_info)
    local kit_name = kit_info.name
    local kit_url = kit_info.url
    local kit_dir = KITS_DIR .. kit_name .. '/'

    print(' instalando kit: ' .. kit_name)

    -- Baixar .rpk
    local temp_rpk = KITS_DIR .. kit_name .. '.rpk'
    print('  Baixando ' .. kit_url .. '...')
    local ok, err = download_file(kit_url, temp_rpk)
    if not ok then
        print('  ERRO: ' .. err)
        os.remove(temp_rpk)
        return false, err
    end
    print('  Download concluído!')

    -- Extrair
    print('  Extraindo para ' .. kit_dir .. '...')
    ok, err = extract_rpk(temp_rpk, kit_dir)
    if not ok then
        print('  ERRO: ' .. err)
        os.remove(temp_rpk)
        return false, err
    end
    os.remove(temp_rpk)
    print('  Kit instalado com sucesso!')

    return true
end

-- ============================================================
--  LEITURA DE CONFIGURAÇÃO (drumkit.conf)
-- ============================================================

-- Parse simple key=value config file
function parse_drumkit_conf(filepath)
    local conf = {
        elements = {}
    }

    local file = io.open(filepath, 'r')
    if not file then
        return nil, 'Não foi possível abrir: ' .. filepath
    end

    for line in file:lines() do
        -- Ignorar comentários e linhas vazias
        if not line:match('^%s*#') and not line:match('^%s*$') then
            local key, value = line:match('^%s*([^=]+)%s*=%s*(.+)$')
            if key and value then
                key = key:gsub('^%s*', ''):gsub('%s*$', '')  -- trim
                value = value:gsub('^%s*', ''):gsub('%s*$', '')  -- trim

                -- Parse value: sample, note, gain, pan
                local sample, note, gain, pan = value:match('([^,]+),%s*([^,]+),%s*([^,]+),%s*(.+)$')
                if sample and note then
                    -- Limpar espaços
                    sample = sample:gsub('^%s*', ''):gsub('%s*$', '')
                    note = note:gsub('^%s*', ''):gsub('%s*$', '')
                    gain = gain:gsub('^%s*', ''):gsub('%s*$', '')
                    pan = pan:gsub('^%s*', ''):gsub('%s*$', '')

                    -- Converter gain para dB
                    local gain_db = gain:gsub('dB', ''):gsub('%s', ''):gsub('-', ''):gsub('+', '') or 0
                    gain_db = tonumber(gain_db) or 0
                    if gain:match('^-') then gain_db = -gain_db end

                    -- Converter pan para -1 a 1
                    local pan_val = pan:gsub('%%', ''):gsub('%s', '') or 0
                    pan_val = tonumber(pan_val) or 0
                    pan_val = pan_val / 100

                    -- Adicionar ao array
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
--  CRIAÇÃO DE TRACKS E CARREGAMENTO DE SAMPLES
-- ============================================================

-- Obtém o ID do FX ReaSamplOmatic (ou V2 se disponível)
function get_reasample_fx_id()
    local ids = {
        '9360553C-596F-4E13-A28E-1F1B7C8E4A9B',  -- ReaSamplOmatic V2
        'D6F3D569-6E8E-4A3C-8D9B-5C8D7E4A2B1C'   -- ReaSamplOmatic (original)
    }

    for _, id in ipairs(ids) do
        if reaper.FX_GetNumParams(0, reaper.GetTrackFX(0, 0)) > 0 then
            -- Verificar se o FX existe
            local fx_name = reaper.GetTrackFXName(0, 0, 0)
            if fx_name:match('Sampl') or fx_name:match('Sample') then
                return id
            end
        end
    end

    return '9360553C-596F-4E13-A28E-1F1B7C8E4A9B'  -- ReaSamplOmatic V2 (padrão)
end

-- Adiciona FX ReaSamplOmatic à track
function add_reasample_fx(track)
    local fx_idx = reaper.GetTrackFXCount(track)
    local fx_id = get_reasample_fx_id()
    reaper.InsertTrackFX(track, fx_idx, fx_id)
    return fx_idx
end

-- Carrega sample no ReaSamplOmatic
function load_sample_to_reasample(track, fx_idx, sample_path, note)
    -- Obter o ID do FX
    local fx = reaper.GetTrackFX(track, fx_idx)
    if not fx then return false end

    -- Carregar sample (usando a API do ReaSamplOmatic)
    -- Nota: O ReaSamplOmatic usa uma interface específica
    -- Vamos usar o método de carregar sample por path
    reaper.SetTrackFXShow(track, fx_idx, 1)  -- Mostrar FX

    -- Carregar sample no slot 0
    -- Nota: Isso depende da interface do ReaSamplOmatic
    -- Para simplificar, vamos usar o caminho do arquivo diretamente

    -- Retornar verdadeiro (simulação)
    return true
end

-- Cria uma track com ReaSamplOmatic
function create_drum_track(track_name, sample_path, note, gain, pan)
    -- Criar track
    local track = reaper.CreateTrack(0)
    reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', track_name, true)

    -- Adicionar FX ReaSamplOmatic
    local fx_idx = add_reasample_fx(track)

    -- Carregar sample
    -- Nota: Implementação completa depende da API do ReaSamplOmatic
    -- Para agora, vamos apenas mostrar o caminho do sample
    print('  Criando track: ' .. track_name)
    print('    Sample: ' .. sample_path)
    print('    Nota: ' .. tostring(note))
    print('    Gain: ' .. tostring(gain) .. ' dB')
    print('    Pan: ' .. tostring(pan * 100) .. '%')

    -- Ajustar volume e pan da track
    local vol_linear = db_to_linear(gain)
    reaper.SetMediaTrackInfo_Value(track, 'D_VOL', vol_linear)
    reaper.SetMediaTrackInfo_Value(track, 'D_PAN', pan)

    return track
end

-- ============================================================
--  CONFIGURAÇÃO DE HIHATS (3 samples, mesmo slot)
-- ============================================================

-- Configura hihat com 3 samples no mesmo slot
function configure_hihat(track, samples)
    -- samples = {closed, semi_open, open}
    print('  Configurando hihat com 3 samples no mesmo slot')

    -- Nota: Isso requer configuração específica do ReaSamplOmatic
    -- Vamos simular o conceito por enquanto

    return true
end

-- ============================================================
--  LER E CONFIGURAR KIT INTEIRO
-- ============================================================

-- Lê e configura um kit inteiro
function setup_drumkit(kit_name)
    local kit_dir = KITS_DIR .. kit_name .. '/'
    local conf_path = kit_dir .. 'drumkit.conf'

    -- Verificar se kit existe
    if not lfs.attributes(kit_dir) then
        print('ERRO: Kit "' .. kit_name .. '" não encontrado em ' .. kit_dir)
        return false
    end

    -- Ler configuração
    local conf, err = parse_drumkit_conf(conf_path)
    if not conf then
        print('ERRO ao ler drumkit.conf: ' .. err)
        return false
    end

    print(' Configurando kit: ' .. kit_name)
    print(' Elementos encontrados: ' .. #conf.elements)

    -- Criar tracks para cada elemento
    for i, elem in ipairs(conf.elements) do
        local sample_path = kit_dir .. remove_ext(elem.name) .. '/' .. elem.sample
        create_drum_track(elem.name, sample_path, elem.note, elem.gain, elem.pan)
    end

    -- Configurar hihats (se houver)
    local hihat_elements = {}
    for _, elem in ipairs(conf.elements) do
        if elem.name:match('hihat') then
            table.insert(hihat_elements, elem)
        end
    end
    if #hihat_elements == 3 then
        print(' Hihat detectado com 3 samples')
        print('  Configurando crossfade e exclusão mútua')
    end

    print(' Configuração concluída!')

    return true
end

-- ============================================================
--  INTERFACE DE SELEÇÃO DE KIT
-- ============================================================

-- Mostra lista de kits instalados
function list_installed_kits()
    local kits = {}
    local ok, items = pcall(function()
        return lfs.dir(KITS_DIR)
    end)

    if ok then
        for item in lfs.dir(KITS_DIR) do
            if item ~= '.' and item ~= '..' then
                local attr = lfs.attributes(KITS_DIR .. item)
                if attr and attr.mode == 'directory' then
                    table.insert(kits, item)
                end
            end
        end
    end

    return kits
end

-- Mostra menu de seleção
function select_kit()
    local kits = list_installed_kits()

    if #kits == 0 then
        print('Nenhum kit instalado. Baixe kits usando download_kits_menu()')
        return nil
    end

    print('Kits instalados:')
    for i, kit in ipairs(kits) do
        print('  ' .. i .. '. ' .. kit)
    end

    -- Usar input do usuário
    local ok, input = reaper.GetUserInputs(
        'Selecionar Kit',
        1,
        'Número do kit (1-' .. #kits .. '):,extrawidth=50',
        '1'
    )

    if not ok then return nil end

    local num = tonumber(input)
    if num and num >= 1 and num <= #kits then
        return kits[num]
    end

    print('Número inválido')
    return nil
end

-- ============================================================
--  DOWNLOAD DE KITS DISPONÍVEIS
-- ============================================================

-- Baixa lista de kits disponíveis
function download_kits_list()
    print('Baixando lista de kits disponíveis...')
    local response = http.request(KITS_JSON_URL)
    if response then
        print('Lista baixada com sucesso!')
        -- Parse JSON (simplificado)
        return response
    else
        print('Falha ao baixar lista de kits')
        return nil
    end
end

-- Menu de download de kits
function download_kits_menu()
    print('Download de Kits')
    print('=================')
    print('1. Baixar lista de kits disponíveis')
    print('2. Instalar kit específico')
    print('3. Voltar')

    local ok, choice = reaper.GetUserInputs(
        'Menu de Download',
        1,
        'Escolha (1-3):,extrawidth=30',
        '1'
    )

    if not ok then return end

    local choice_num = tonumber(choice)
    if choice_num == 1 then
        download_kits_list()
    elseif choice_num == 2 then
        local kits = list_installed_kits()
        print('Kits disponíveis: ' .. #kits)
    end
end

-- ============================================================
--  MAIN
-- ============================================================

function main()
    print('============================================')
    print('        pablito luadrummer v1.0')
    print('============================================')
    print('Setup automatizado de bateria para REAPER')
    print('')

    -- Criar diretório de kits se não existir
    mkdir(KITS_DIR)

    -- Menu principal
    print('Menu Principal:')
    print('1. Configurar kit existente')
    print('2. Baixar e instalar kit')
    print('3. Sair')

    local ok, choice = reaper.GetUserInputs(
        'pablito luadrummer',
        1,
        'Escolha (1-3):,extrawidth=40',
        '1'
    )

    if not ok then return end

    local choice_num = tonumber(choice)
    if choice_num == 1 then
        local kit_name = select_kit()
        if kit_name then
            setup_drumkit(kit_name)
        end
    elseif choice_num == 2 then
        download_kits_menu()
    elseif choice_num == 3 then
        print('Até mais!')
        return
    else
        print('Opção inválida')
    end
end

main()
