-- @description Gerador de acordes MIDI a partir de notas selecionadas
-- @author MeuNome
-- @version 1.0
-- @about
--   Para cada nota selecionada no editor MIDI, adiciona as notas do
--   acorde escolhido acima dela. Trabalha com o take MIDI ativo.
--   Abra o editor MIDI, selecione as notas raiz e execute o script.
--
--   Se gostou deste script, considere fazer uma doação para apoiar o projeto:
--   Buy me a Coffee: https://buymeacoffee.com/pablocostaguimaraes
--   Agradeço de coração! ❤️

-- Definição dos intervalos de acorde em semitons a partir da raiz
local CHORD_TYPES = {
    ["Maior"]         = {4, 7},           -- terça maior + quinta
    ["Menor"]         = {3, 7},           -- terça menor + quinta
    ["Maior 7"]       = {4, 7, 11},       -- + sétima maior
    ["Dominante 7"]   = {4, 7, 10},       -- + sétima menor
    ["Menor 7"]       = {3, 7, 10},       -- + sétima menor
    ["Sus2"]          = {2, 7},           -- segunda + quinta
    ["Sus4"]          = {5, 7},           -- quarta + quinta
    ["Dim"]           = {3, 6},           -- terça menor + quinta dim
    ["Aug"]           = {4, 8},           -- terça maior + quinta aug
    ["Maior add9"]    = {4, 7, 14},       -- maior + nona
    ["Poder (5th)"]   = {7},              -- só a quinta (power chord)
}

-- Monta lista ordenada para exibir no menu
local chord_names = {}
for name in pairs(CHORD_TYPES) do
    table.insert(chord_names, name)
end
table.sort(chord_names)

local function main()
    -- Verificar take MIDI ativo
    local item = reaper.GetSelectedMediaItem(0, 0)
    if not item then
        reaper.ShowMessageBox("Nenhum item selecionado.", "Chord Generator", 0)
        return
    end

    local take = reaper.GetActiveTake(item)
    if not take or not reaper.TakeIsMIDI(take) then
        reaper.ShowMessageBox("O take ativo não é MIDI.", "Chord Generator", 0)
        return
    end

    -- Montar string de opções para input
    local options_str = table.concat(chord_names, ",")
    local ok, chosen = reaper.GetUserInputs(
        "Tipo de Acorde",
        1,
        "Acorde (" .. options_str .. "):,extrawidth=200",
        chord_names[1]
    )
    if not ok then return end

    local intervals = CHORD_TYPES[chosen]
    if not intervals then
        reaper.ShowMessageBox(
            "Tipo de acorde não reconhecido: \"" .. chosen .. "\"",
            "Chord Generator",
            0
        )
        return
    end

    -- Coletar notas selecionadas
    local retval, note_count = reaper.MIDI_CountEvts(take)
    local selected_notes = {}

    for i = 0, note_count - 1 do
        local r, sel, muted, startppq, endppq, chan, pitch, vel =
            reaper.MIDI_GetNote(take, i)
        if sel then
            table.insert(selected_notes, {
                startppq = startppq,
                endppq   = endppq,
                chan     = chan,
                pitch    = pitch,
                vel      = vel,
                muted    = muted,
            })
        end
    end

    if #selected_notes == 0 then
        reaper.ShowMessageBox(
            "Nenhuma nota selecionada no editor MIDI.",
            "Chord Generator",
            0
        )
        return
    end

    reaper.Undo_BeginBlock()

    -- Inserir notas do acorde para cada nota selecionada
    local inserted = 0
    for _, note in ipairs(selected_notes) do
        for _, interval in ipairs(intervals) do
            local new_pitch = note.pitch + interval
            if new_pitch >= 0 and new_pitch <= 127 then
                reaper.MIDI_InsertNote(
                    take,
                    true,        -- selecionada
                    note.muted,
                    note.startppq,
                    note.endppq,
                    note.chan,
                    new_pitch,
                    note.vel,
                    false        -- não substitui notas existentes
                )
                inserted = inserted + 1
            end
        end
    end

    reaper.MIDI_Sort(take)
    reaper.Undo_EndBlock(
        string.format("Gerar acordes: %s (%d notas)", chosen, inserted),
        -1
    )

    reaper.ShowMessageBox(
        string.format(
            "Acorde \"%s\" aplicado em %d nota(s) raiz.\n%d nota(s) inserida(s).",
            chosen, #selected_notes, inserted
        ),
        "Chord Generator",
        0
    )
end

main()
