-- @description Dividir items selecionados na posição do cursor
-- @author MeuNome
-- @version 1.0
-- @about
--   Divide todos os media items selecionados na posição atual do cursor
--   de edição. Equivale a S no teclado, mas funciona apenas nos
--   items selecionados (o atalho nativo afeta todos na track).

local function main()
    local num_items = reaper.CountSelectedMediaItems(0)

    if num_items == 0 then
        reaper.ShowMessageBox("Nenhum item selecionado.", "Split at Cursor", 0)
        return
    end

    local cursor_pos = reaper.GetCursorPosition()
    local split_count = 0

    reaper.Undo_BeginBlock()

    -- Iterar de trás para frente para não invalidar índices após splits
    for i = num_items - 1, 0, -1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_len   = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local item_end   = item_start + item_len

        -- Só divide se o cursor estiver dentro do item (não nas bordas)
        if cursor_pos > item_start + 0.001 and cursor_pos < item_end - 0.001 then
            reaper.SplitMediaItem(item, cursor_pos)
            split_count = split_count + 1
        end
    end

    reaper.Undo_EndBlock("Split items selecionados no cursor", -1)
    reaper.UpdateArrange()

    if split_count == 0 then
        reaper.ShowMessageBox(
            "Cursor não está sobre nenhum item selecionado.",
            "Split at Cursor",
            0
        )
    end
end

main()
