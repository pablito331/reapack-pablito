-- @description Renomear tracks selecionadas em sequência
-- @author MeuNome
-- @version 1.0
-- @about
--   Pede um nome base e numera automaticamente todas as tracks selecionadas.
--   Ex: "Bateria" gera "Bateria 01", "Bateria 02", "Bateria 03"...

local num_sel = reaper.CountSelectedTracks(0)

if num_sel == 0 then
    reaper.ShowMessageBox("Nenhuma track selecionada.", "Renomear Tracks", 0)
    return
end

-- Pede o nome base ao usuário
local ok, input = reaper.GetUserInputs(
    "Renomear Tracks",
    2,
    "Nome base:,Começar em (número):,extrawidth=100",
    "Track,1"
)

if not ok then return end

-- Separar os valores do input
local base_name, start_num_str = input:match("^(.*),(.*)$")
local start_num = tonumber(start_num_str) or 1

reaper.Undo_BeginBlock()

for i = 0, num_sel - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    local num = start_num + i
    -- Formata com zero à esquerda se menor que 10
    local formatted_num = string.format("%02d", num)
    local new_name = base_name .. " " .. formatted_num
    reaper.GetSetMediaTrackInfo_String(track, "P_NAME", new_name, true)
end

reaper.Undo_EndBlock("Renomear tracks selecionadas", -1)
reaper.UpdateArrange()

reaper.ShowMessageBox(
    num_sel .. " track(s) renomeada(s) como \"" .. base_name .. "\".",
    "Renomear Tracks",
    0
)
