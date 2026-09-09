# Referência Python para REAPER

Python é a única linguagem de ReaScript que requer instalação separada. Não suporta UI gráfica dentro do REAPER, mas dá acesso a todo o ecossistema Python.

---

## Setup

### 1. Instalar Python
Baixe e instale Python 3.x em [python.org](https://www.python.org/downloads/).

> **Atenção:** REAPER 32-bit precisa de Python 32-bit. REAPER 64-bit precisa de Python 64-bit.

### 2. Habilitar no REAPER
- **Options → Preferences → Plug-Ins → ReaScript**
- Marque **"Enable Python for use with ReaScript"**
- O REAPER normalmente detecta automaticamente. Se não, aponte o caminho manualmente.

### 3. Verificar
Crie um script `.py` e execute. Se aparecer erro de Python não encontrado, verifique o path em Preferences.

---

## Como chamar a API

Em Python, as funções do REAPER ficam no módulo `reapy` ... na verdade, o REAPER injeta diretamente via `import RPR_*` ou usando o módulo `reaper_python`:

```python
# Método padrão — importar funções específicas
from reaper_python import *

# Ou usar o prefixo RPR_
RPR_ShowMessageBox("Olá!", "Teste", 0)
```

O binding padrão usa funções prefixadas com `RPR_`:

```python
from reaper_python import *

# Contar tracks
num_tracks = RPR_CountTracks(0)

# Mensagem
RPR_ShowMessageBox("Número de tracks: " + str(num_tracks), "Info", 0)
```

---

## Estrutura básica de um script

```python
# @description Meu Script Python
# @author Seu Nome
# @version 1.0

from reaper_python import *

def main():
    num_tracks = RPR_CountTracks(0)
    RPR_ShowConsoleMsg(f"Projeto tem {num_tracks} tracks\n")

main()
```

---

## Funções essenciais

```python
from reaper_python import *

# Projeto
num_tracks = RPR_CountTracks(0)
cursor_pos = RPR_GetCursorPosition()

# Track
track = RPR_GetTrack(0, 0)  # projeto=0, índice=0

# Nome da track — Python usa tuplas para múltiplos retornos
retval, track_ref, buf, buf_sz = RPR_GetTrackName(track, "", 512)
name = buf

# Volume e pan
vol = RPR_GetMediaTrackInfo_Value(track, "D_VOL")
pan = RPR_GetMediaTrackInfo_Value(track, "D_PAN")

# Item
item = RPR_GetTrackMediaItem(track, 0)
pos = RPR_GetMediaItemInfo_Value(item, "D_POSITION")
length = RPR_GetMediaItemInfo_Value(item, "D_LENGTH")

# Undo
RPR_Undo_BeginBlock()
# ... modificações ...
RPR_Undo_EndBlock("Descrição", -1)

# Console de debug
RPR_ShowConsoleMsg("debug\n")
```

---

## Diferença importante: múltiplos retornos

Em Lua, múltiplos retornos são atribuídos normalmente:
```lua
local ok, name = reaper.GetTrackName(track)
```

Em Python, a API retorna uma **tupla** com todos os parâmetros (entrada e saída):
```python
# GetTrackName retorna (retval, track, buf, buf_sz)
retval, track_ref, name, buf_sz = RPR_GetTrackName(track, "", 512)
```

Sempre consulte a documentação da API para ver a assinatura exata.

---

## Usando bibliotecas Python externas

Esta é a grande vantagem do Python no REAPER:

```python
from reaper_python import *
import os
import json
import re

# Exemplo: ler um JSON externo e renomear tracks
def rename_tracks_from_json(json_path):
    with open(json_path, "r") as f:
        data = json.load(f)

    RPR_Undo_BeginBlock()
    for i, name in enumerate(data.get("tracks", [])):
        if i >= RPR_CountTracks(0):
            break
        track = RPR_GetTrack(0, i)
        RPR_GetSetMediaTrackInfo_String(track, "P_NAME", name, True)
    RPR_Undo_EndBlock("Renomear tracks via JSON", -1)

rename_tracks_from_json("C:/meu_projeto/tracks.json")
```

---

## Alternativa: biblioteca reapy

[reapy](https://python-reapy.readthedocs.io/) é uma biblioteca de terceiros que oferece uma API Python mais pythônica:

```python
# pip install python-reapy
import reapy

with reapy.inside_reaper():
    project = reapy.Project()
    for track in project.tracks:
        print(track.name)
```

> Requer configuração adicional. Consulte a [documentação do reapy](https://python-reapy.readthedocs.io/).

---

## Quando usar Python vs Lua

| Situação | Recomendação |
|---|---|
| Automação de workflow no REAPER | Lua |
| Interface gráfica dentro do REAPER | Lua |
| Integração com ferramentas externas | Python |
| Análise de dados de áudio/projeto | Python |
| Geração de conteúdo via libs (AI, web) | Python |
| Script simples e portável | Lua |
| Processamento de arquivos externos | Python |

---

## Links

- [ReaScript SDK (Python)](https://www.reaper.fm/sdk/reascript/)
- [Documentação reapy](https://python-reapy.readthedocs.io/)
- [Python.org downloads](https://www.python.org/downloads/)
