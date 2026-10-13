# Componentes extras

Peças usadas em vídeos anteriores que não estão no `assets/template.html`. Copie o CSS para o `<style>` e o HTML para a cena.

## Chip de marca (logo + texto)

```css
.chip {
  display: inline-flex;
  align-self: flex-start;
  align-items: center;
  gap: 22px;
  padding: 16px 30px 16px 24px;
  border: 1px solid var(--line-strong);
  border-radius: 999px;
  color: var(--muted);
  font: 600 30px/1 var(--sans);
}
.chip img { height: 40px; width: auto; }
.chip span { padding-left: 22px; border-left: 1px solid var(--line-strong); }
```

```html
<p class="chip" data-in="5.2"><img src="logo.svg" alt="" /><span>Bot · Produto</span></p>
```

## Ícone de app (entra com pop)

```css
.icon {
  width: 300px;
  height: 300px;
  border: 1px solid var(--line);
  border-radius: 72px;
  box-shadow: 0 30px 80px rgba(0, 0, 0, 0.18);
}
```

```html
<img class="icon" src="file:///caminho/absoluto/icone.webp" alt="" data-in="3.7" data-pop />
```

Imagens locais precisam de caminho `file:///` absoluto ou de estar na mesma pasta do HTML (o render abre a página via `file://`).

## Card de preço

```css
.price-row { display: grid; gap: 14px; }
.price-row + .price-row { padding-top: 36px; border-top: 1px solid var(--line); }
.price { display: flex; align-items: baseline; gap: 14px; }
.price small { color: var(--muted); font-size: 44px; font-weight: 500; }
.price strong { font-size: 150px; font-weight: 600; letter-spacing: -0.04em; line-height: 1; }
.price em { color: var(--muted); font-size: 44px; font-style: normal; }
.fine { color: var(--muted); font: 500 32px/1.45 var(--sans); }
```

```html
<p class="tag" data-in="22.7">Preço de abertura</p>
<div class="card" data-in="23.5">
  <div class="price-row">
    <p class="eyebrow">Implantação</p>
    <p class="price"><small>R$</small><strong>300</strong><em>pagamento único</em></p>
  </div>
  <div class="price-row">
    <p class="eyebrow">Manutenção</p>
    <p class="price"><small>R$</small><strong>120</strong><em>/mês</em></p>
  </div>
  <p class="fine">+ observação pequena</p>
</div>
```

## Aviso legal no rodapé (fora das cenas)

Usado quando o vídeo cita marcas de terceiros (ex.: Grok/SpaceX). Fica fora de qualquer `<section>` e usa `data-scene-out` para saber quando sumir — o script do template precisa tratar isso:

```css
.disclaimer {
  position: absolute;
  left: 96px; right: 96px;
  bottom: 300px;            /* 9:16; em 4:5 use ~60px */
  color: var(--dim);
  font: 500 24px/1.45 var(--sans);
  text-align: center;
}
```

```html
<p class="disclaimer" data-in="25" data-scene-out="28.2">
  Consultoria independente. A Artificial Manufactory não é associada à X.
</p>
```

No script, troque o cálculo de `end` dos itens por:

```js
var end = scene
  ? Number(scene.getAttribute("data-scene").split(" ")[1])
  : Number(el.getAttribute("data-scene-out"));
```
