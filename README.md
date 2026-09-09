# Reaper Scripts & Plugins

Repositório pessoal de scripts e plugins para o [Cockos REAPER](https://www.reaper.fm/), organizado por linguagem e categoria.

---

## Estrutura do repositório

```
reaper-pack/
├── Scripts/
│   ├── Lua/            # ReaScripts em Lua (automação, workflow, UI)
│   │   ├── Track/      # Operações em tracks
│   │   ├── MIDI/       # Edição e geração de MIDI
│   │   ├── Items/      # Manipulação de media items
│   │   ├── Projeto/    # Gerenciamento de projetos
│   │   └── UI/         # Interfaces gráficas (ReaImGui / gfx)
│   ├── EEL/            # ReaScripts em EEL2
│   └── Python/         # ReaScripts em Python
├── Effects/
│   └── JSFX/           # Plugins de áudio/MIDI em EEL2 (formato JSFX)
│       ├── Audio/      # Processamento de áudio
│       ├── MIDI/       # Processamento de MIDI
│       └── Util/       # Utilitários (medidores, análise)
├── Docs/               # Guias de referência das linguagens
├── index.xml           # Índice ReaPack (instalação automática)
└── .github/workflows/  # CI: geração automática do index.xml
```

---

## Linguagens do REAPER

O REAPER suporta três linguagens para ReaScripts e uma para plugins JSFX. Cada uma tem seu caso de uso ideal.

### Lua (recomendada para scripts)
- **Extensão:** `.lua`
- **Embutida no REAPER** — sem instalação extra
- Mais fácil de aprender, boa performance, suporte completo à API
- Suporta UI gráfica via `gfx` (nativo) ou [ReaImGui](https://github.com/cfillion/reaimgui) (extensão)
- Ideal para: automação de workflow, manipulação de projetos, ferramentas de composição

### EEL2 (scripts e plugins)
- **Extensão:** `.eel` (scripts) / sem extensão (JSFX)
- **Embutida no REAPER** — sem instalação extra
- Linguagem desenvolvida pela Cockos, similar a C/JavaScript
- Alta performance em tempo real — usada tanto em ReaScripts quanto em JSFX
- Ideal para: plugins de áudio/MIDI em tempo real, scripts de performance crítica

### JSFX (plugins de efeito)
- **Linguagem:** EEL2
- **Extensão:** sem extensão (arquivos de texto simples)
- Formato nativo do REAPER para criar plugins VST-like sem compilação
- Processa áudio e MIDI sample-by-sample em tempo real
- Ideal para: compressores, equalizers, geradores MIDI, analisadores, utilitários

### Python (scripts avançados)
- **Extensão:** `.py`
- **Requer instalação separada** (Python 2.7 ou 3.x) e habilitação em Preferences
- Não suporta UI gráfica dentro do REAPER
- Acesso a todo o ecossistema de bibliotecas Python
- Ideal para: integração com ferramentas externas, análise de dados, automação complexa

---

## Instalação via ReaPack

[ReaPack](https://reapack.com/) é o gerenciador de pacotes do REAPER. Para instalar este repositório:

1. No REAPER: **Extensions → ReaPack → Import a repository**
2. Cole a URL do índice:
   ```
   https://github.com/pablito331/reapack-pablito/raw/master/index.xml
   ```
3. **Extensions → ReaPack → Synchronize Packages**

---

## Instalação manual

1. Abra o REAPER e vá em **Options → Show REAPER resource path in explorer**
2. Copie os arquivos `.lua` / `.eel` / `.py` para a pasta `Scripts/`
3. Copie os arquivos JSFX para a pasta `Effects/`
4. No REAPER: **Actions → ReaScript: Load** para carregar scripts
5. Para JSFX: adicione como efeito em qualquer track via **FX → Add**

---

## API do REAPER

A documentação completa da API está disponível diretamente no REAPER:
- **Help → ReaScript documentation**

Referências online:
- [ReaScript SDK](https://www.reaper.fm/sdk/reascript/)
- [JSFX SDK](https://www.reaper.fm/sdk/js/)
- [API Reference (cockos.com)](https://www.cockos.com/reaper/sdk/reascript/reascripthelp.html)
- [ReaImGui Docs](https://github.com/cfillion/reaimgui/wiki)

---

## Guias internos

| Arquivo | Conteúdo |
|---|---|
| [Docs/lua-reference.md](Docs/lua-reference.md) | Referência rápida de Lua + API do REAPER |
| [Docs/eel2-reference.md](Docs/eel2-reference.md) | Referência de EEL2 para scripts e JSFX |
| [Docs/jsfx-reference.md](Docs/jsfx-reference.md) | Estrutura e seções de um plugin JSFX |
| [Docs/python-reference.md](Docs/python-reference.md) | Setup e uso de Python no REAPER |

---

## Licença

MIT — use, modifique e distribua à vontade.

## Plugins de Referência

Esta coleção inclui plugins de referência para estudo. Veja `Examples/README.md` para uma descrição detalhada dos plugins Tukan e outros criadores.

---
- Examples/             # Plugins de referência (não envia para GitHub)
└── .github/workflows/  # CI: geração automática do index.xml
```

---

## Plugins de Referência

Esta coleção inclui plugins de referência para estudo. Veja `Examples/README.md` para uma descrição detalhada dos plugins Tukan (Drum Samplers, Sintetizadores, Filtros, Effects) e outros criadores.
