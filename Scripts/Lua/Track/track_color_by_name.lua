-- @description Colorir tracks automaticamente por palavras-chave no nome
-- @author MeuNome
-- @version 1.0
-- @about
--   Percorre todas as tracks do projeto e aplica cores baseadas em
--   palavras-chave no nome. Útil para padronizar templates de projeto.
--   Edite a tabela COLOR_MAP para personalizar as cores e palavras.
--
--   Se gostou deste script, considere fazer uma doação para apoiar o projeto:
--   Buy me a Coffee: https://buymeacoffee.com/pablocostaguimaraes
--   Agradeço de coração! ❤️

-- Mapa de palavras-chave -> cor (formato RGB como inteiro REAPER)
-- Use reaper.ColorToNative(r, g, b) para converter RGB
local COLOR_MAP = {
    -- Bateria / Percussão
    { keywords = {"kick", "bumbo", "bd"},       color = reaper.ColorToNative(180, 50,  50)  | 0x1000000 },
    { keywords = {"snare", "caixa"},             color = reaper.ColorToNative(200, 80,  80)  | 0x1000000 },
    { keywords = {"hihat", "chimbal", "hat"},    color = reaper.ColorToNative(160, 60,  60)  | 0x1000000 },
    { keywords = {"drum", "bateria", "perc"},    color = reaper.ColorToNative(220, 70,  70)  | 0x1000000 },
    -- Baixo
    { keywords = {"bass", "baixo"},              color = reaper.ColorToNative(50,  100, 180) | 0x1000000 },
    -- Guitarra
    { keywords = {"guitar", "guitarra", "gtr"},  color = reaper.ColorToNative(80,  160, 80)  | 0x1000000 },
    -- Teclado / Synth
    { keywords = {"keys", "piano", "synth", "tecla"}, color = reaper.ColorToNative(180, 140, 50) | 0x1000000 },
    -- Voz
    { keywords = {"vox", "vocal", "voice", "voz", "lead", "bg"}, color = reaper.ColorToNative(160, 80, 200) | 0x1000000 },
    -- Strings / Brass
    { keywords = {"string", "violin", "cello", "viola"},  color = reaper.ColorToNative(80,  180, 160) | 0x1000000 },
    { keywords = {"brass", "trumpet", "trombone", "horn"}, color = reaper.ColorToNative(220, 160, 50) | 0x1000000 },
    -- FX / Bus
    { keywords = {"reverb", "delay", "fx", "send"},  color = reaper.ColorToNative(100, 100, 100) | 0x1000000 },
    { keywords = {"bus", "mix", "master", "sub"},    color = reaper.ColorToNative(60,  60,  60)  | 0x1000000 },
}

-- Verifica se uma string contém alguma das palavras-chave (case insensitive)
local function match_keywords(track_name, keywords)
    local lower_name = track_name:lower()
    for _, kw in ipairs(keywords) do
        if lower_name:find(kw:lower(), 1, true) then
            return true
        end
    end
    return false
end

local function main()
    local num_tracks = reaper.CountTracks(0)
    if num_tracks == 0 then
        reaper.ShowMessageBox("Projeto sem tracks.", "Colorir Tracks", 0)
        return
    end

    local colored = 0

    reaper.Undo_BeginBlock()

    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        local _, name = reaper.GetTrackName(track)

        for _, entry in ipairs(COLOR_MAP) do
            if match_keywords(name, entry.keywords) then
                reaper.SetTrackColor(track, entry.color)
                colored = colored + 1
                break
            end
        end
    end

    reaper.Undo_EndBlock("Colorir tracks por nome", -1)
    reaper.UpdateArrange()

    reaper.ShowMessageBox(
        colored .. " de " .. num_tracks .. " track(s) colorida(s).",
        "Colorir Tracks",
        0
    )
end

main()
