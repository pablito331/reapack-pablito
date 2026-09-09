-- @description Humanizar velocidade e timing de notas MIDI
-- @author MeuNome
-- @version 1.0
-- @about
--   Aplica variação aleatória controlada na velocidade e na posição
--   temporal das notas MIDI do take ativo. Simula a imprecisão humana
--   para deixar sequências programadas mais naturais.

local function random_offset(amount)
    -- Retorna valor aleatório entre -amount e +amount
    return (math.random() * 2 - 1) * amount
end

local function main()
    -- Verificar se há um take MIDI selecionado
    local item = reaper.GetSelectedMediaItem(0, 0)
    if not item then
        reaper.ShowMessageBox("Nenhum item selecionado.", "MIDI Humanize", 0)
        return
    end

    local take = reaper.GetActiveTake(item)
    if not take or not reaper.TakeIsMIDI(take) then
        reaper.ShowMessageBox("O take ativo não é MIDI.", "MIDI Humanize", 0)
        return
    end

    -- Pedir parâmetros ao usuário
    local ok, input = reaper.GetUserInputs(
        "MIDI Humanize",
        2,
        "Variação de velocidade (0-127):,Variação de timing (ms):,extrawidth=80",
        "10,5"
    )
    if not ok then return end

    local vel_var_str, timing_var_str = input:match("^(.*),(.*)$")
    local vel_var    = math.max(0, math.min(127, tonumber(vel_var_str) or 10))
    local timing_ms  = math.max(0, tonumber(timing_var_str) or 5)

    -- Converter ms para PPQ (usa a posição da primeira nota como referência)
    -- PPQ depende do tempo — usamos uma aproximação via projeto
    local bpm, bpi = reaper.GetProjectTimeSignature2(0)
    local ppq_per_beat = 960  -- padrão do REAPER
    local beats_per_sec = bpm / 60.0
    local ppq_per_sec = ppq_per_beat * beats_per_sec
    local timing_ppq = (timing_ms / 1000.0) * ppq_per_sec

    math.randomseed(os.time())

    local retval, note_count = reaper.MIDI_CountEvts(take)

    reaper.Undo_BeginBlock()

    for i = 0, note_count - 1 do
        local r, sel, muted, startppq, endppq, chan, pitch, vel =
            reaper.MIDI_GetNote(take, i)

        -- Variação de velocidade
        local new_vel = vel + math.floor(random_offset(vel_var) + 0.5)
        new_vel = math.max(1, math.min(127, new_vel))

        -- Variação de timing (preserva duração da nota)
        local offset_ppq = math.floor(random_offset(timing_ppq) + 0.5)
        local new_start  = math.max(0, startppq + offset_ppq)
        local new_end    = new_start + (endppq - startppq)  -- mantém duração

        reaper.MIDI_SetNote(take, i, sel, muted, new_start, new_end, chan, pitch, new_vel, false)
    end

    reaper.MIDI_Sort(take)
    reaper.Undo_EndBlock(
        string.format("MIDI Humanize (vel±%d, timing±%.0fms)", vel_var, timing_ms),
        -1
    )
    reaper.UpdateArrange()

    reaper.ShowMessageBox(
        string.format("%d nota(s) humanizada(s).", note_count),
        "MIDI Humanize",
        0
    )
end

main()
