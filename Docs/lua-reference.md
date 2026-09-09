# Referência Lua para REAPER

Lua v5.4 está embutida no REAPER. Não precisa instalar nada.

---

## Estrutura básica de um script

```lua
-- @description Nome do script
-- @author Seu Nome
-- @version 1.0
-- @about
--   Descrição do que o script faz.

-- Código começa aqui
reaper.ShowMessageBox("Olá, REAPER!", "Meu Script", 0)
```

As tags `@description`, `@author`, `@version` são lidas pelo ReaPack para montar o índice.

---

## Como chamar a API

Todas as funções do REAPER ficam no namespace `reaper.`:

```lua
reaper.NomeDaFuncao(parametros)
```

Funções que retornam múltiplos valores usam múltipla atribuição:

```lua
-- retval, trackcolor = GetTrackColor(track)
local ok, trackcolor = reaper.GetTrackColor(track)
```

---

## Funções essenciais

### Projeto e transporte

```lua
-- Número de tracks no projeto
local num_tracks = reaper.CountTracks(0)  -- 0 = projeto atual

-- Posição do cursor de edição (em segundos)
local pos = reaper.GetCursorPosition()

-- Posição de play (em segundos)
local play_pos = reaper.GetPlayPosition()

-- Estado do transporte: 0=stop, 1=play, 2=pause, 4=record, 5=record+pause
local state = reaper.GetPlayState()

-- Iniciar/parar transporte
reaper.OnPlayButton()
reaper.OnStopButton()
reaper.OnRecordButton()
```

### Tracks

```lua
-- Pegar track pelo índice (0-based)
local track = reaper.GetTrack(0, 0)  -- projeto=0, índice=0

-- Nome da track
local ok, name = reaper.GetTrackName(track)

-- Renomear track
reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "Novo Nome", true)

-- Volume e pan (0.0 a 1.0 para volume, -1.0 a 1.0 para pan)
local vol = reaper.GetMediaTrackInfo_Value(track, "D_VOL")
local pan = reaper.GetMediaTrackInfo_Value(track, "D_PAN")

-- Mutar / solear
reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 1)   -- 1=muted, 0=unmuted
reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 1)   -- 1=solo, 0=normal

-- Criar nova track
reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)

-- Track selecionada
local track = reaper.GetSelectedTrack(0, 0)  -- projeto=0, índice=0
local num_sel = reaper.CountSelectedTracks(0)
```

### Media Items

```lua
-- Número de items em uma track
local num_items = reaper.CountTrackMediaItems(track)

-- Pegar item pelo índice
local item = reaper.GetTrackMediaItem(track, 0)

-- Posição e duração do item (em segundos)
local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

-- Mover item
reaper.SetMediaItemInfo_Value(item, "D_POSITION", nova_pos)

-- Take ativo do item
local take = reaper.GetActiveTake(item)

-- Nome do take
local ok, take_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)

-- Source (arquivo de audio/MIDI)
local source = reaper.GetMediaItemTake_Source(take)
local filename = reaper.GetMediaSourceFileName(source)
```

### Time Selection e Loop

```lua
-- Pegar time selection
local start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

-- Definir time selection
reaper.GetSet_LoopTimeRange(true, false, 1.0, 3.0, false)
--                          set?, isLoop?, start, end, allowautoseek

-- Pegar loop points
local loop_start, loop_end = reaper.GetSet_LoopTimeRange(false, true, 0, 0, false)
```

### MIDI

```lua
-- Abrir editor MIDI de um take
reaper.Main_OnCommand(40153, 0)  -- Open MIDI editor for active take

-- Contar notas em um take MIDI
local take = reaper.GetActiveTake(item)
local retval, note_count, cc_count, text_count = reaper.MIDI_CountEvts(take)

-- Pegar nota pelo índice
local retval, selected, muted, startppq, endppq, chan, pitch, vel =
    reaper.MIDI_GetNote(take, 0)

-- Inserir nota
-- startppq/endppq em pulsos, chan 0-15, pitch 0-127, vel 0-127
reaper.MIDI_InsertNote(take, false, false, startppq, endppq, 0, 60, 100, false)

-- Converter tempo (segundos) para PPQ
local ppq = reaper.MIDI_GetPPQPosFromProjTime(take, tempo_em_segundos)
```

### Undo

```lua
-- Sempre envolver mudanças em bloco de undo
reaper.Undo_BeginBlock()

  -- ... suas modificações aqui ...

reaper.Undo_EndBlock("Descrição da ação para o histórico", -1)
```

### Diálogos e UI

```lua
-- Caixa de mensagem
-- tipo: 0=OK, 1=OK/Cancel, 2=Abort/Retry/Ignore, 3=Yes/No/Cancel, 4=Yes/No, 5=Retry/Cancel
local result = reaper.ShowMessageBox("Mensagem", "Título", 1)
-- retorna: 1=OK, 2=Cancel, 3=Abort, 4=Retry, 5=Ignore, 6=Yes, 7=No

-- Input dialog
local ok, input = reaper.GetUserInputs("Título", 1, "Campo:,extrawidth=100", "default")

-- Selecionar arquivo
local ok, filename = reaper.GetUserFileNameForRead("", "Abrir arquivo", "")

-- Console de debug
reaper.ShowConsoleMsg("mensagem de debug\n")
```

### Executar Actions

```lua
-- Executar action pelo ID (mesmos IDs da Action List do REAPER)
reaper.Main_OnCommand(40001, 0)  -- Save project

-- Pegar ID de uma action pelo nome
local action_id = reaper.NamedCommandLookup("_SWS_SAVEALLNAMED")
reaper.Main_OnCommand(action_id, 0)
```

---

## Iterar sobre tracks e items

```lua
-- Percorrer todas as tracks
for i = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, i)
    local ok, name = reaper.GetTrackName(track)
    reaper.ShowConsoleMsg(i .. ": " .. name .. "\n")
end

-- Percorrer items de uma track
for i = 0, reaper.CountTrackMediaItems(track) - 1 do
    local item = reaper.GetTrackMediaItem(track, i)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    reaper.ShowConsoleMsg("Item em: " .. pos .. "s\n")
end

-- Percorrer apenas tracks selecionadas
for i = 0, reaper.CountSelectedTracks(0) - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    -- ...
end
```

---

## Defer (loop / script persistente)

Para scripts que precisam rodar continuamente (ex: UI interativa):

```lua
local function loop()
    -- código que roda a cada frame
    reaper.defer(loop)  -- agenda a próxima chamada
end

loop()  -- inicia o loop
```

---

## gfx (interface gráfica nativa)

```lua
-- Abrir janela gráfica
gfx.init("Minha Janela", 400, 300)  -- título, largura, altura

local function draw()
    -- Limpar fundo
    gfx.set(0.2, 0.2, 0.2)  -- cor RGB 0.0-1.0
    gfx.rect(0, 0, gfx.w, gfx.h, true)

    -- Desenhar texto
    gfx.set(1, 1, 1)  -- branco
    gfx.x, gfx.y = 10, 10
    gfx.drawstr("Olá REAPER!")

    -- Atualizar tela
    gfx.update()

    -- Checar fechamento
    if gfx.getchar() ~= -1 then
        reaper.defer(draw)
    end
end

draw()
```

---

## Dicas importantes

- **Sempre use `Undo_BeginBlock` / `Undo_EndBlock`** ao modificar o projeto
- **Índices são 0-based** na API do REAPER
- **`reaper.defer(fn)`** é a forma correta de criar loops — nunca use `while true`
- Use **`reaper.ShowConsoleMsg()`** para debug rápido
- A documentação completa da API está em **Help → ReaScript documentation** dentro do REAPER

---

## Links

- [ReaScript SDK oficial](https://www.reaper.fm/sdk/reascript/)
- [API Reference completa](https://www.cockos.com/reaper/sdk/reascript/reascripthelp.html)
- [ReaImGui (UI moderna)](https://github.com/cfillion/reaimgui)
- [Forum Cockos](https://forum.cockos.com/forumdisplay.php?f=343)
