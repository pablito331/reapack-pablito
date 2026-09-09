-- @description Inspector de track com janela gráfica interativa
-- @author MeuNome
-- @version 1.0
-- @about
--   Abre uma janela flutuante que exibe informações em tempo real
--   da track selecionada: nome, volume, pan, mute, solo, número de items.
--   Demonstra o uso do gfx (interface gráfica nativa do REAPER).
--   Feche a janela clicando no X ou pressionando Escape.

-- Configuração da janela
local WIN_W = 320
local WIN_H = 260
local FONT_SIZE = 14
local BG_COLOR    = {r=0.14, g=0.14, b=0.18}
local HEADER_COLOR= {r=0.20, g=0.20, b=0.28}
local TEXT_COLOR  = {r=0.90, g=0.90, b=0.90}
local ACCENT_COLOR= {r=0.30, g=0.60, b=1.00}
local MUTE_COLOR  = {r=1.00, g=0.35, b=0.35}
local SOLO_COLOR  = {r=1.00, g=0.85, b=0.20}

local function set_color(c, alpha)
    gfx.r = c.r; gfx.g = c.g; gfx.b = c.b; gfx.a = alpha or 1.0
end

local function draw_rect_filled(x, y, w, h, c, alpha)
    set_color(c, alpha)
    gfx.rect(x, y, w, h, true)
end

local function draw_text(x, y, text, c)
    set_color(c)
    gfx.x = x; gfx.y = y
    gfx.drawstr(text)
end

local function draw_bar(x, y, w, h, value, max_val, color)
    -- Fundo da barra
    draw_rect_filled(x, y, w, h, {r=0.1, g=0.1, b=0.1})
    -- Preenchimento
    local fill_w = math.max(0, math.min(w, (value / max_val) * w))
    draw_rect_filled(x, y, fill_w, h, color)
    -- Borda
    set_color({r=0.4, g=0.4, b=0.4})
    gfx.rect(x, y, w, h, false)
end

local function vol_to_db(vol)
    if vol <= 0 then return "-inf dB" end
    return string.format("%.1f dB", 20 * math.log(vol) / math.log(10))
end

local function pan_to_str(pan)
    if math.abs(pan) < 0.01 then return "Centro" end
    return string.format("%.0f%% %s", math.abs(pan) * 100, pan < 0 and "Esq" or "Dir")
end

local function get_track_info()
    local track = reaper.GetSelectedTrack(0, 0)
    if not track then
        return nil
    end

    local _, name = reaper.GetTrackName(track)
    local vol      = reaper.GetMediaTrackInfo_Value(track, "D_VOL")
    local pan      = reaper.GetMediaTrackInfo_Value(track, "D_PAN")
    local mute     = reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1
    local solo     = reaper.GetMediaTrackInfo_Value(track, "I_SOLO") ~= 0
    local items    = reaper.CountTrackMediaItems(track)
    local idx      = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    local total    = reaper.CountTracks(0)

    return {
        name   = name,
        vol    = vol,
        pan    = pan,
        mute   = mute,
        solo   = solo,
        items  = items,
        idx    = idx,
        total  = total,
    }
end

local function draw(info)
    local W = gfx.w
    local H = gfx.h

    -- Fundo
    draw_rect_filled(0, 0, W, H, BG_COLOR)

    -- Header
    draw_rect_filled(0, 0, W, 36, HEADER_COLOR)
    gfx.setfont(1, "Arial", FONT_SIZE + 2, string.byte("b"))
    draw_text(12, 10, "Track Inspector", ACCENT_COLOR)

    if not info then
        gfx.setfont(1, "Arial", FONT_SIZE)
        draw_text(12, 60, "Nenhuma track selecionada.", TEXT_COLOR)
        return
    end

    local pad = 14
    local y   = 50

    -- Nome
    gfx.setfont(1, "Arial", FONT_SIZE + 1, string.byte("b"))
    draw_text(pad, y, info.name, ACCENT_COLOR)
    y = y + 20

    gfx.setfont(1, "Arial", FONT_SIZE - 2)
    draw_text(pad, y, string.format("Track %d / %d", info.idx, info.total), {r=0.5,g=0.5,b=0.5})
    y = y + 22

    -- Separador
    set_color({r=0.25, g=0.25, b=0.35})
    gfx.line(pad, y, W - pad, y)
    y = y + 10

    gfx.setfont(1, "Arial", FONT_SIZE)

    -- Volume
    draw_text(pad, y, "Volume", {r=0.6,g=0.6,b=0.6})
    draw_text(180, y, vol_to_db(info.vol), TEXT_COLOR)
    y = y + 18
    draw_bar(pad, y, W - pad * 2, 8, math.min(info.vol, 2.0), 2.0, ACCENT_COLOR)
    y = y + 18

    -- Pan
    draw_text(pad, y, "Pan", {r=0.6,g=0.6,b=0.6})
    draw_text(180, y, pan_to_str(info.pan), TEXT_COLOR)
    y = y + 18
    -- Barra de pan centralizada
    local bar_w = W - pad * 2
    local center_x = pad + bar_w / 2
    draw_rect_filled(pad, y, bar_w, 8, {r=0.1,g=0.1,b=0.1})
    local pan_fill = (info.pan / 2.0) * (bar_w / 2)
    if pan_fill >= 0 then
        draw_rect_filled(center_x, y, pan_fill, 8, ACCENT_COLOR)
    else
        draw_rect_filled(center_x + pan_fill, y, -pan_fill, 8, ACCENT_COLOR)
    end
    set_color({r=0.4,g=0.4,b=0.4})
    gfx.rect(pad, y, bar_w, 8, false)
    y = y + 22

    -- Items
    draw_text(pad, y, "Media Items", {r=0.6,g=0.6,b=0.6})
    draw_text(180, y, tostring(info.items), TEXT_COLOR)
    y = y + 24

    -- Mute / Solo badges
    local badge_color = info.mute and MUTE_COLOR or {r=0.2,g=0.2,b=0.2}
    draw_rect_filled(pad, y, 70, 22, badge_color)
    gfx.setfont(1, "Arial", FONT_SIZE - 1, string.byte("b"))
    draw_text(pad + 20, y + 4, "MUTE", {r=1,g=1,b=1})

    badge_color = info.solo and SOLO_COLOR or {r=0.2,g=0.2,b=0.2}
    draw_rect_filled(pad + 84, y, 70, 22, badge_color)
    draw_text(pad + 104, y + 4, "SOLO", {r=0.1,g=0.1,b=0.1})
end

-- Loop principal
local function loop()
    local char = gfx.getchar()

    -- Fechar com Escape ou se a janela foi fechada
    if char == 27 or char == -1 then
        gfx.quit()
        return
    end

    local info = get_track_info()
    draw(info)
    gfx.update()

    reaper.defer(loop)
end

-- Inicializar janela
gfx.init("Track Inspector", WIN_W, WIN_H)
gfx.setfont(1, "Arial", FONT_SIZE)

loop()
