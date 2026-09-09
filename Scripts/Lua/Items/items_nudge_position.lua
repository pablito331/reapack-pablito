-- @description Mover items selecionados por um offset em milissegundos
-- @author MeuNome
-- @version 1.0
-- @about
--   Desloca todos os items selecionados para frente ou para trás
--   por um valor em milissegundos. Útil para correção de timing fino.

local function main()
    local num_items = reaper.CountSelectedMediaItems(0)

    if num_items == 0 then
        reaper.ShowMessageBox("Nenhum item selecionado.", "Nudge Items", 0)
        return
    end

    local ok, input = reaper.GetUserInputs(
        "Mover Items",
        1,
        "Offset em ms (negativo = para trás):,extrawidth=80",
        "0"
    )

    if not ok then return end

    local offset_ms = tonumber(input)
    if not offset_ms then
        reaper.ShowMessageBox("Valor inválido. Use um número.", "Nudge Items", 0)
        return
    end

    local offset_sec = offset_ms / 1000.0

    reaper.Undo_BeginBlock()

    for i = 0, num_items - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local pos  = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local new_pos = math.max(0, pos + offset_sec)  -- não vai para antes do início
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_pos)
    end

    reaper.Undo_EndBlock(
        string.format("Nudge items %+.1f ms", offset_ms),
        -1
    )
    reaper.UpdateArrange()
end

main()
