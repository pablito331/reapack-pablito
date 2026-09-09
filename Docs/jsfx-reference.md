# Referência JSFX para REAPER

JSFX (JesuSonic Effects) é o formato de plugin nativo do REAPER. Plugins são arquivos de texto simples escritos em **EEL2**, sem compilação, com reload instantâneo. Funcionam como VST nativos: aparecem no FX chain de qualquer track.

---

## Estrutura de um plugin JSFX

Um arquivo JSFX é dividido em **seções** marcadas por `@`:

```
desc: Nome do Plugin
// cabeçalho com metadados e sliders

@init
// executado uma vez ao carregar o plugin

@slider
// executado quando qualquer slider muda de valor

@block
// executado a cada bloco de amostras (antes do @sample)

@sample
// executado para CADA amostra de áudio — loop principal

@gfx width height
// interface gráfica personalizada (opcional)

@serialize
// salvar/restaurar estado customizado (opcional)
```

---

## Cabeçalho e metadados

```eel
desc: Meu Gain Plugin
author: Seu Nome
version: 1.0
tags: gain utility
about:
  Plugin simples de ganho.
  Amplifica ou atenua o sinal.

// Sliders aparecem na interface do plugin
// slider<N>: valor_default <min, max, step> Nome
slider1:0<-24,24,0.1>Gain (dB)
slider2:0<0,1,1{Stereo,Mono}>Modo

// Inputs e outputs (padrão já é stereo se não declarar)
in_pin:left input
in_pin:right input
out_pin:left output
out_pin:right output
```

### Tipos de slider

```eel
slider1:0<-24,24,0.1>Gain (dB)          // slider contínuo
slider2:0<0,1,1{Off,On}>Bypass          // dropdown (enumeração)
slider3:440<20,20000,1>Frequency (Hz)   // inteiro
```

---

## Variáveis especiais

### Áudio
```eel
spl0    // amostra atual do canal esquerdo (leitura/escrita)
spl1    // amostra atual do canal direito (leitura/escrita)
// spl2, spl3... para mais canais
```

### Configuração
```eel
srate       // sample rate atual (ex: 44100, 48000, 96000)
num_ch      // número de canais de áudio
samplesblock // tamanho do bloco atual (em amostras)
tempo       // BPM do projeto
ts_num      // numerador do compasso (ex: 4 para 4/4)
ts_denom    // denominador do compasso (ex: 4 para 4/4)
beat_position // posição atual em batidas
play_state  // 0=stop, 1=play, 2=pause, 5=record
```

### Sliders
```eel
slider1     // valor do slider 1 (nome automático)
slider2     // valor do slider 2
// etc.
```

---

## Seção @init

Executada uma vez ao carregar. Use para:
- Inicializar variáveis
- Calcular coeficientes que dependem do `srate`
- Alocar memória

```eel
@init

// Converter dB para linear
function db_to_linear(db) (
    10 ^ (db / 20)
);

// Inicializar ganho
gain_linear = db_to_linear(slider1);
```

---

## Seção @slider

Chamada sempre que um slider muda. Recalcule os coeficientes aqui:

```eel
@slider

gain_linear = 10 ^ (slider1 / 20);
```

---

## Seção @block

Executada uma vez por bloco de amostras, antes de `@sample`. Útil para cálculos que não precisam ser feitos sample-by-sample:

```eel
@block

// Atualizar envelope a cada bloco é mais eficiente
envelope_step = (target_gain - current_gain) / samplesblock;
```

---

## Seção @sample

O coração do plugin. Executada para **cada amostra** de áudio. Precisa ser eficiente:

```eel
@sample

// Aplicar ganho nos dois canais
spl0 *= gain_linear;
spl1 *= gain_linear;

// Limitar ao range -1 a 1 (hard clip)
spl0 = max(-1, min(1, spl0));
spl1 = max(-1, min(1, spl1));
```

---

## Seção @gfx (interface gráfica)

```eel
@gfx 400 200  // largura e altura da janela

// Variáveis disponíveis:
// gfx_w, gfx_h  — dimensões atuais da janela
// gfx_x, gfx_y  — posição atual do cursor de desenho
// gfx_r, gfx_g, gfx_b, gfx_a — cor atual (0.0-1.0)
// mouse_x, mouse_y — posição do mouse
// mouse_cap  — estado dos botões do mouse (bitfield)

@gfx 400 200

// Fundo escuro
gfx_r = 0.15; gfx_g = 0.15; gfx_b = 0.15;
gfx_rect(0, 0, gfx_w, gfx_h);

// Texto de nível
gfx_r = 1; gfx_g = 1; gfx_b = 1;
gfx_x = 10; gfx_y = 10;
gfx_setfont(1, "Arial", 14);
gfx_printf("Gain: %.1f dB", slider1);

// Barra de nível simples
level_width = gfx_w * (gain_linear / 4);  // visual
gfx_r = 0.2; gfx_g = 0.8; gfx_b = 0.4;
gfx_rect(0, gfx_h - 20, level_width, 15);
```

### Funções gráficas

```eel
gfx_rect(x, y, w, h)           // retângulo preenchido
gfx_line(x1, y1, x2, y2)       // linha
gfx_circle(x, y, r, fill)      // círculo
gfx_triangle(x1,y1,x2,y2,x3,y3) // triângulo
gfx_printf(fmt, ...)            // texto formatado na posição gfx_x, gfx_y
gfx_measurestr(#str, w, h)      // medir largura/altura de texto
gfx_setfont(idx, font, size)    // definir fonte
gfx_set(r, g, b, a)             // definir cor
gfx_blit(image, scale, rotation) // desenhar imagem
```

---

## Processamento MIDI

```eel
@block

// Ler todos os eventos MIDI do bloco
while (midirecv(offset, msg1, msg2, msg3)) (
    status = msg1 & 0xF0;   // tipo da mensagem
    channel = msg1 & 0x0F;  // canal (0-15)

    status == 0x90 ? (  // Note On
        pitch = msg2;
        velocity = msg3;
        velocity > 0 ? (
            // nota pressionada
        ) : (
            // Note On com vel=0 = Note Off
        );
    );

    status == 0x80 ? (  // Note Off
        pitch = msg2;
    );

    status == 0xB0 ? (  // CC (Control Change)
        cc_num = msg2;
        cc_val = msg3;
    );

    // Reenviar o evento (pass-through)
    midisend(offset, msg1, msg2, msg3);
);
```

### Constantes MIDI úteis

```eel
0x80  // Note Off
0x90  // Note On
0xA0  // Aftertouch (polyphonic)
0xB0  // Control Change
0xC0  // Program Change
0xD0  // Channel Pressure
0xE0  // Pitch Bend
0xF0  // SysEx
```

---

## Onde salvar os arquivos JSFX

Copie para a pasta `Effects/` do resource path do REAPER:
- **Options → Show REAPER resource path in explorer**
- Coloque o arquivo em `Effects/` ou em subpasta (ex: `Effects/MeuNome/plugin.jsfx`)
- O REAPER detecta automaticamente — aparece no FX browser

---

## Exemplo completo: Gain Simples

```eel
desc: Simple Gain
author: MeuNome
version: 1.0

slider1:0<-24,24,0.1>Gain (dB)

@init
gain = 1.0;

@slider
gain = 10 ^ (slider1 / 20);

@sample
spl0 *= gain;
spl1 *= gain;
```

---

## Links

- [JSFX SDK oficial](https://www.reaper.fm/sdk/js/)
- [Language Essentials](https://www.reaper.fm/sdk/js/basiccode.php)
- [Variáveis especiais](https://www.reaper.fm/sdk/js/vars.php)
- [Seções JSFX](https://www.reaper.fm/sdk/js/sections.php)
- [MIDI em JSFX](https://www.reaper.fm/sdk/js/midi.php)
- [Gráficos JSFX](https://www.reaper.fm/sdk/js/graphics.php)
