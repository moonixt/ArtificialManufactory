---
name: video-motion-am
description: Cria e edita vídeos motion (anúncios, posts de LinkedIn/Instagram/Reels/TikTok) na estética visual da Artificial Manufactory — fundo claro, Inter 800 em caixa alta, cenas que entram com movimento — feitos como página HTML animada e renderizados quadro a quadro para MP4 com ffmpeg. Use sempre que o usuário pedir pra criar um vídeo, anúncio, motion, reel ou vídeo de post a partir de um texto; pra editar, traduzir, encurtar ou tirar/colocar cenas de um vídeo desses; pra trocar ou colocar música de fundo; ou pra gerar outra versão (formato, idioma) de um vídeo que já existe — mesmo que ele não fale "motion" nem "HTML". Roda isolada num subagente Opus 5.5 que não vê a conversa — passe no pedido o roteiro/texto completo, a rede (LinkedIn, Reels…), o idioma e o caminho local do .mp3 se houver música.
model: claude-opus-5-5
context: fork
---

# Vídeos motion na estética Artificial Manufactory

Esta skill roda numa **sessão nova e isolada** (subagente Opus 5.5) chamada por outra sessão/modelo. Você não vê a conversa de quem chamou — só este arquivo e o pedido que veio junto (os argumentos). Também não dá pra fazer perguntas no meio: quando faltar informação, use os padrões abaixo e diga no relatório final o que assumiu.

## Entrada (o que vem no pedido)

| Campo | Obrigatório | Padrão se não vier |
|---|---|---|
| Roteiro: texto do post/anúncio, ou o que mudar num vídeo existente | sim | — (sem isso, pare e devolva o que falta) |
| Rede/formato | não | LinkedIn → 4:5; Instagram/Reels/TikTok/Shorts/Status → 9:16; não dito → 4:5 |
| Idioma | não | o idioma do roteiro |
| Nome do vídeo (pasta) | não | slug curto do tema, ex. `linkedin-agente-leads` |
| Música (caminho de um .mp3 local) | não | sem música (áudio mudo) |
| Vídeo existente a editar | não | procure em `~/Vídeos/*/` pelo tema; os HTML de lá são a fonte |

## Saída (o que devolver no fim)

Sua resposta final é o que a sessão que chamou recebe — ela não vê seus passos. Termine com um relatório curto contendo:
- caminho do MP4 final, duração e formato;
- caminho da pasta-fonte (HTML) e da capa;
- lista das cenas (tempo + texto principal);
- o que você assumiu por falta de informação e qualquer aviso (licença da música, texto que precisou encurtar);
- hash do commit em `~/Vídeos`.

Os vídeos não são editados num editor de vídeo: cada um é **uma página HTML** com uma função `render(t)` que desenha exatamente o quadro do segundo `t`. Um script abre a página no Chromium headless, chama `render(t)` para cada quadro (30 fps), tira screenshot e o ffmpeg junta tudo num MP4. Por isso tudo é reproduzível e editar é só mexer no HTML e renderizar de novo.

Arquivos da skill:
- `assets/template.html` — vídeo completo de referência (6 cenas, 4:5) com todos os componentes e o motor de animação. **Comece copiando ele.**
- `scripts/build.sh` — prévia ou build final (quadros → MP4 + trilha + capa + tira de conferência).
- `scripts/render.mjs` — o gravador via Chrome DevTools Protocol (usado pelo build.sh).
- `references/componentes-extras.md` — chip de marca, ícone de app, card de preço, aviso legal no rodapé.

## Onde salvar

Cada vídeo vira uma pasta em `~/Vídeos/<nome-do-video>/` com o HTML (e a música, se tiver), e o MP4 final vai em `~/Vídeos/<nome>-<largura>x<altura>.mp4`. **Nunca deixe a fonte só no scratchpad/`/tmp`** — já perdemos a fonte de um vídeo assim e tivemos que reconstruir do histórico. `~/Vídeos` é um repo git (MP4 é ignorado pelo .gitignore; HTML e mp3 entram): commite a pasta a cada mudança.

## Estética (o que mantém a identidade)

- **Cores**: fundo `#f5f5f3`, tinta `#0a0a0a`, cinzas `--muted #55554f` / `--dim #6f6f69`, linhas `rgba(0,0,0,.1)`, único acento é o verde `#1f8a55` (checks, "aprovado", status). Nada de gradiente, brilho ou fundo escuro — já testamos tema escuro com glow e o usuário preferiu o claro e plano.
- **Tipografia**: Inter (Google Fonts). Títulos `.big` em 800, caixa alta, `line-height .88`, `letter-spacing -0.07em`, uma linha por `<span>` (cada linha entra separada). Tamanhos: 150px (`.big`), 124px (`.md`), 104px (`.sm`). Texto de apoio `.lede` 500 46px cinza. Marca "Artificial Manufactory" em Georgia (serif) 64px.
- **Componentes**: `.tag` (pílula preta, caixa alta espaçada), `.rows` (lista numerada 01/02/03 com divisórias), `.checks` (itens com check verde), `.card` branco com borda e sombra leve, `.bubble` com texto sendo digitado, `.pill` (nichos/opções), `.button` preto com seta no CTA, `.url`, `.brand`.
- **Movimento** — escolhido por `var TRANSITION` no script do template:
  - `"mascara"` (**padrão**, o usuário preferiu): cada linha de título `.big > span` sobe de trás de uma máscara (sem fade, easeOut quártico 0.6s); os outros elementos revelam da esquerda pra direita (`clip-path` + desliza 40px); na troca de cena um painel preto (`#wipe`) sobe cobrindo a tela em 0.24s e sai por cima em 0.24s, e a cena nova aparece por trás. A máscara tem folga de `0.14em` em cima e `0.18em` embaixo — com menos, o Ç e vírgulas são cortados ("CAÇA" vira "CACA").
  - `"classica"`: tudo entra subindo 60px com fade (0.55s) e a cena sai com fade (0.35s). Use se o usuário pedir algo mais suave ou "como os primeiros anúncios".
  - Nos dois, `data-pop` faz o elemento crescer de 0.82 → 1 com leve overshoot. Entradas em cascata com 0.25s entre linhas do mesmo título e ~1.2s entre itens de lista.
- **Ritmo**: cenas de 4–8s, vídeo total de 25–35s, 1 ideia por cena. Estrutura que funcionou: gancho grande → o que faz (lista) → demonstração concreta (card/chat) → prova/garantia (checks + frase forte) → oferta/abrangência → CTA ("Quer um …?", botão "Me chama", URL, marca).
- **Texto**: português direto e coloquial, frases curtas. CTA do botão curto ("Me chama" / "Message me") — o usuário pediu pra tirar "no WhatsApp". Não coloque preços a menos que ele peça (pediu pra remover nos anúncios).

## Formatos

| Uso | Tamanho | `.scene inset` | `HEIGHT` |
|---|---|---|---|
| LinkedIn / feed | 1080×1350 (4:5) | `120px 96px` | 1350 |
| Reels / TikTok / Shorts / Status | 1080×1920 (9:16) | `250px 96px 400px` (área segura fora das barras do app) | 1920 |

Troque nos três lugares: `html, body { height }`, `.scene { inset }` e `var HEIGHT` no script. Largura é sempre 1080. Se o pedido não diz a rede, use os padrões da tabela de **Entrada**.

## Linha do tempo (como o HTML funciona)

- `<section class="scene" data-scene="início fim">` — a cena fica visível nesse intervalo.
- `data-in="t"` em qualquer elemento — segundo em que ele entra. Some no fim da cena. No modo máscara, `data-in` direto nos `<span>` filhos de `.big` vira animação de linha (o script embrulha o conteúdo num `.ln`).
- No modo máscara o painel cobre a tela de `início-0.24` a `início+0.24` de cada cena (menos a primeira): não coloque nada importante entrando antes de `início+0.1`.
- **Primeira cena com `data-in` negativo** (-0.6, -0.4, -0.2…) para o texto já estar na tela no quadro 0 — senão a miniatura/capa do vídeo sai vazia.
- `data-type="início fim"` num `.typed` dentro do `.bubble` — efeito de digitação. O texto completo fica num `.ghost` invisível para o balão já ter o tamanho final e nada pular.
- `var DURATION` = fim da última cena.
- Efeitos especiais (ponto pulsando, botão "Aprovar" → "Aprovado ✓") são escritos direto em `render(t)` como função de `t`. **Nunca use CSS animation, transition, setTimeout ou Date** — o render pula de quadro em quadro e só o que depende de `t` aparece certo.

Para **remover uma cena**: apague a `<section>`, puxe para trás todos os `data-in`/`data-scene`/`data-scene-out` posteriores pela duração removida e diminua `DURATION`. Para **traduzir**: copie para `video-en.html` (mantenha o original), troque `lang`, `<title>` e todos os textos — incluindo aviso legal e textos de botão/eyebrow — e confira linhas que ficaram longas demais ou estranhas em caixa alta (ex.: "SpaceX's AIs" virou "SPACEX'S AIS"; trocamos por "SpaceX AI").

## Fluxo de trabalho

1. Copie `assets/template.html` para `~/Vídeos/<nome>/video.html` e ajuste formato, cenas e textos ao roteiro (geralmente um post que o usuário cola).
2. **Prévia antes do build** (renderizar tudo leva ~1–2 min):
   ```bash
   ~/.claude/skills/video-motion-am/scripts/build.sh ~/Vídeos/<nome>/video.html ~/Vídeos/<nome>-1080x1350.mp4 --preview 1,8.5,14.5,22,27.5,33
   ```
   Escolha um tempo no meio de cada cena (com tudo já entrado) e **olhe a imagem** gerada (`…-preview.png`). Confira: texto estourando a largura (títulos longos em 150px estouram — vá para `.md`/`.sm` ou quebre a linha), sobreposição, cena vazia, resto de idioma errado.
3. **Build final**:
   ```bash
   ~/.claude/skills/video-motion-am/scripts/build.sh ~/Vídeos/<nome>/video.html ~/Vídeos/<nome>-1080x1350.mp4 [--music ~/Vídeos/<nome>/musica.mp3] [--music-start 0]
   ```
   Gera o MP4 (H.264 CRF 18, yuv420p, faststart, AAC — aceito em todas as redes), a capa `-capa.jpg` (quadro de 1s) e `-strip.png` (1 quadro a cada 2s). Olhe a tira para confirmar a sequência inteira.
4. Comite a pasta em `~/Vídeos` (sem push — o repo não tem remote) e termine com o relatório da seção **Saída**. Se a ferramenta SendUserFile existir na sessão, envie o MP4 também.

Se o comando passar de 2 min, rode com timeout maior em vez de mandar para background — e não use `pkill -f render.mjs` para parar um render: o padrão casa com o próprio shell e mata o comando atual.

## Música

- Fonte padrão: **Pixabay Music** (pixabay.com/music) — licença livre para uso comercial, sem atribuição. Arquivos baixados de lá vêm como `artista-titulo-123456.mp3`.
- **Não baixe música por conta própria** (nem de YouTube/YouTube Music): muita faixa "sem copyright" no YouTube é da Epidemic Sound, que só é livre para assinantes, e post comercial pode ser silenciado. Se o pedido trouxer um link em vez de arquivo, faça o vídeo sem música e diga no relatório que é preciso baixar a faixa (de preferência do Pixabay) e passar o caminho do arquivo.
- A faixa vem como arquivo local no pedido; copie para a pasta do vídeo e passe com `--music`. O build corta na duração do vídeo, faz fade-in 0.3s e fade-out nos 2.5s finais e normaliza para −16 LUFS.
- Para escolher o trecho, meça a energia por segundo e alinhe a entrada da batida com a cena de virada:
  ```bash
  ffmpeg -hide_banner -i musica.mp3 -af "aresample=8000,asetnsamples=8000,astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-" -f null - 2>/dev/null | grep -o 'RMS_level=.*' | awk -F= '{printf "%d:%s ", NR-1, int($2)} END{print ""}'
  ```
  Use `--music-start` para começar a faixa num ponto específico.

## Dependências

`chromium`, `node` (≥ 22, usa `fetch`/`WebSocket` nativos), `ffmpeg`, ImageMagick (`magick`). A fonte Inter vem do Google Fonts, então o render precisa de internet; o render.mjs imprime `Inter carregada: true` — se vier `false`, o vídeo sai com fonte errada.
