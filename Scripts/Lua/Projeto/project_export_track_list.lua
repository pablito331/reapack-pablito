-- @description Exportar lista de tracks do projeto para um arquivo de texto
-- @author MeuNome
-- @version 1.0
-- @about
--   Gera um arquivo .txt com informações de todas as tracks do projeto:
--   nome, volume, pan, mute, solo e número de items.
--   Útil para documentação e transferência de informações de sessão.

local function vol_to_db(vol)
    if vol <= 0 then return "-inf" end
    return string.format("%.1f dB", 20 * math.log(vol) / math.log(10))
end

local function pan_to_str(pan)
    if math.abs(pan) < 0.01 then return "C" end
    local pct = math.abs(pan) * 100
    return string.format("%.0f%% %s", pct, pan < 0 and "L" or "R")
end

local function main()
    local num_tracks = reaper.CountTracks(0)
    if num_tracks == 0 then
        reaper.ShowMessageBox("Projeto sem tracks.", "Exportar Track List", 0)
        return
    end

    -- Pegar caminho do projeto para salvar junto
    local proj_path = reaper.GetProjectPath("")
    local default_file = proj_path .. "\\track_list.txt"

    local ok, filename = reaper.GetUserFileNameForWrite(
        default_file,
        "Salvar Track List",
        "txt"
    )
    if not ok or filename == "" then return end

    -- Montar conteúdo
    local proj_name = reaper.GetProjectName(0, "")
    local lines = {}

    table.insert(lines, "=== TRACK LIST ===")
    table.insert(lines, "Projeto : " .. (proj_name ~= "" and proj_name or "(sem nome)"))
    table.insert(lines, "Data    : " .. os.date("%Y-%m-%d %H:%M"))
    table.insert(lines, string.rep("=", 60))
    table.insert(lines, string.format(
        "%-4s  %-30s  %-10s  %-8s  %-6s  %-6s  %s",
        "#", "Nome", "Volume", "Pan", "Mute", "Solo", "Items"
    ))
    table.insert(lines, string.rep("-", 80))

    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        local _, name   = reaper.GetTrackName(track)
        local vol       = reaper.GetMediaTrackInfo_Value(track, "D_VOL")
        local pan       = reaper.GetMediaTrackInfo_Value(track, "D_PAN")
        local mute      = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
        local solo      = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
        local num_items = reaper.CountTrackMediaItems(track)

        table.insert(lines, string.format(
            "%-4d  %-30s  %-10s  %-8s  %-6s  %-6s  %d",
            i + 1,
            name:sub(1, 30),
            vol_to_db(vol),
            pan_to_str(pan),
            mute == 1 and "MUTE" or "-",
            solo ~= 0 and "SOLO" or "-",
            num_items
        ))
    end

    table.insert(lines, string.rep("=", 60))
    table.insert(lines, "Total: " .. num_tracks .. " tracks")

    -- Escrever arquivo
    local file = io.open(filename, "w")
    if not file then
        reaper.ShowMessageBox("Não foi possível criar o arquivo.", "Exportar Track List", 0)
        return
    end

    file:write(table.concat(lines, "\n"))
    file:close()

    reaper.ShowMessageBox(
        "Track list exportada:\n" .. filename,
        "Exportar Track List",
        0
    )
end

main()
