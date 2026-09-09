# Referência EEL2 para REAPER

EEL2 (Extensible EEL Language 2) é a linguagem desenvolvida pela Cockos. É usada tanto em **ReaScripts** (`.eel`) quanto em **JSFX** (plugins de efeito). Está embutida no REAPER — sem instalação.

---

## Características da linguagem

- Sintaxe similar a C e JavaScript
- Compilação on-the-fly (sem passo de build)
- Tipagem fraca — todas as variáveis são `float64`
- Sem classes, sem arrays nativos (usa memória compartilhada)
- Alta performance em tempo real

---

## Sintaxe básica

### Variáveis e tipos

```eel
// Todas as variáveis são globais por padrão, exceto dentro de funções
x = 10;
y = 3.14;
nome = "texto";  // strings são limitadas — EEL não é forte em strings

// Variáveis locais (dentro de funções)
function exemplo() local(a, b) (
    a = 5;
    b = 10;
    a + b  // último valor é o retorno
);
```

### Operadores

```eel
x = 2 + 3;      // adição
x = 10 - 4;     // subtração
x = 3 * 4;      // multiplicação
x = 10 / 2;     // divisão
x = 10 % 3;     // módulo
x = 2 ^ 8;      // potência (256)
x = ~5;         // bitwise NOT
x = 5 & 3;      // bitwise AND
x = 5 | 3;      // bitwise OR
x = 5 $ ~ 3;    // bitwise XOR (usa $~)
x = 5 << 2;     // shift left
x = 20 >> 2;    // shift right
```

### Condicionais

```eel
// if / else
x > 0 ? (
    // bloco verdadeiro
) : (
    // bloco falso
);

// Forma alternativa (mais legível)
if (x > 5) (
    y = 1;
) else (
    y = 0;
);
```

### Loops

```eel
// while
i = 0;
while (i < 10) (
    // corpo do loop
    i += 1;
);

// loop (executa N vezes)
loop(100,
    x += 1;
);
```

### Funções

```eel
// Definição
function soma(a, b) (
    a + b  // retorna o último valor avaliado
);

// Com variáveis locais
function media(a, b) local(soma) (
    soma = a + b;
    soma / 2;
);

// Chamada
resultado = soma(3, 7);  // 10
```

---

## Memória compartilhada (arrays)

EEL2 não tem arrays nativos. Em vez disso, usa um buffer de memória global de 64MB:

```eel
// Escrever na posição 0
0[] = 440.0;    // ou: memset(0, 440.0, 1)

// Ler da posição 0
freq = 0[];

// Percorrer como array
i = 0;
loop(10,
    i[] = i * 100;  // posições 0 a 9
    i += 1;
);

// Acessar offset a partir de um ponteiro
ptr = 100;      // começa no endereço 100
ptr[0] = 1.0;
ptr[1] = 2.0;
ptr[2] = 3.0;
```

---

## EEL2 como ReaScript

Scripts EEL têm acesso à mesma API Lua, com sintaxe diferente:

```eel
// Contar tracks
num_tracks = CountTracks(0);

// Pegar track e nome
track = GetTrack(0, 0);
GetTrackName(track, #name);  // string vai para variável #name
ShowMessageBox(#name, "Track 0", 0);

// Iterar tracks
i = 0;
loop(CountTracks(0),
    track = GetTrack(0, i);
    GetTrackName(track, #name);
    ShowConsoleMsg(#name);
    ShowConsoleMsg("\n");
    i += 1;
);
```

> Em EEL, strings são prefixadas com `#`. Ex: `#nome`, `#resultado`

---

## Funções matemáticas built-in

```eel
abs(x)          // valor absoluto
floor(x)        // arredonda para baixo
ceil(x)         // arredonda para cima
sqrt(x)         // raiz quadrada
sin(x)          // seno (x em radianos)
cos(x)          // cosseno
tan(x)          // tangente
asin(x)         // arcoseno
acos(x)         // arcocosseno
atan(x)         // arcotangente
atan2(y, x)     // arcotangente de y/x
exp(x)          // e^x
log(x)          // logaritmo natural
log10(x)        // logaritmo base 10
pow(x, y)       // x^y
max(a, b)       // maior valor
min(a, b)       // menor valor
sign(x)         // -1, 0 ou 1
rand(x)         // número aleatório entre 0 e x
```

---

## Funções de string

```eel
sprintf(#dest, "format", args...)  // formata string (como printf em C)
strlen(#str)                        // comprimento da string
strcpy(#dest, #src)                 // copiar string
strcat(#dest, #src)                 // concatenar
strcmp(#a, #b)                      // comparar (0 = iguais)
strchr(#str, char_code)             // buscar caractere
strsub(#str, start, end)            // substring
str_getchar(#str, pos)              // caractere na posição
str_setchar(#str, pos, char)        // setar caractere
match("pattern", #str)              // regex-like matching
```

---

## Links

- [EEL2 Language Essentials (oficial)](https://www.reaper.fm/sdk/js/basiccode.php)
- [Referência de variáveis especiais JSFX](https://www.reaper.fm/sdk/js/vars.php)
- [JSFX SDK completo](https://www.reaper.fm/sdk/js/)
