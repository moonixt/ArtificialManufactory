---
name: break
description: >-
  Break one line or short snippet of code, in any language, into a
  source-order table, a table of imported tools with the official docs link
  and the role each plays, an execution-order table, and the same logic
  written in separate lines. Use when the user says "break", "breakdown",
  "quebra essa linha", or asks what comes after the name, parameter, type, or
  other piece of a signature or statement.
disable-model-invocation: true
---

# Break

Explain one line or a short snippet in two orders. Reply in the user's language. Name each piece by what it is. Follow the syntax of the snippet's language. The worked example below is Python. The same steps apply to any language.

## Answer shape

1. Quote the line in a code block.
2. One sentence listing the pieces in source order, left to right.
3. The breakdown table, one row per piece, in that same source order. Headers: `Pedaço` and `O que é` when the user writes in Portuguese. Otherwise `Piece` and `What it is`.
4. The imported-tools table, before the execution table. One row per imported or builtin tool that does work in the snippet. Headers: `Ferramenta`, `De onde vem`, `Papel nesta função`, `Documentação` in Portuguese. Otherwise `Tool`, `Where it comes from`, `Role in this function`, `Documentation`. Quote the import line. Then one short concrete walk of that role with the values in the snippet. A name that only appears as a type annotation is not a tool. State the role as the behavior of that tool. For `defaultdict(list)`, the role is grouping: a missing key receives a new empty list, and `append` adds the item to the list of that key, as in `grouped[word[0]].append(word)`, which groups each word by its first character. Its docs link is [defaultdict](https://docs.python.org/3/library/collections.html#collections.defaultdict).
5. One sentence saying the next table is execution order.
6. The execution table. Headers: `Ordem na linha`, `Pedaço`, `Quando roda` in Portuguese. Otherwise `Order on the line`, `Piece`, `When it runs`.
7. One short closing paragraph. Spell out nested pieces. If the user used the wrong name for a piece, state the right name here.
8. When a call sits inside another call or inside `return`, show the same logic in separate lines. Name each imported tool and each variable the function creates. Then one small table, one row per line.

Keep each cell to one short sentence. Stop after the alternative form.

## Documentation links

Put the official reference URL in `Documentação`. Choose it from the language of the snippet:

- Python: `https://docs.python.org/3/library/`
- JavaScript and TypeScript: `https://developer.mozilla.org/docs/Web/JavaScript/Reference`
- Go: `https://pkg.go.dev/`
- Rust: `https://doc.rust-lang.org/`
- Java: `https://docs.oracle.com/en/java/javase/`
- C#: `https://learn.microsoft.com/dotnet/api/`
- Ruby: `https://docs.ruby-lang.org/`
- PHP: `https://www.php.net/manual/`
- Kotlin: `https://kotlinlang.org/api/`
- Swift: `https://developer.apple.com/documentation/`

For a third-party library, link that library's own docs. Link the page of the symbol, not the site home, when the docs have an anchor. The required link is the official reference, so the step works in every language.

## Execution table

Keep the rows in reading order. The third column says when that piece runs.

- Nested calls run from the innermost parentheses outward. The piece written first on the left runs last, after the parentheses produce a value.
- Say the moment in the third column: primeiro, no meio, por último.
- A line that only declares (`def`, a name, a type, `->`) records names and types. In `Quando roda`, say that nothing is calculated on that line.

## What counts as a piece

Split on the boundaries a reader trips over: keyword, name, parameter name, type annotation, return arrow, operator, literal, call. Keep a type annotation with its colon or arrow (`: list[str]`, `-> dict[str, int]`) so the breakdown shows where the type sits. In the execution table, group a call with its parentheses (`dict(...)`, `Counter(palavras)`).

## Example

User asks about:

```python
return dict(Counter(palavras))
```

Answer:

A ordem na linha, da esquerda para a direita, é: `return`, `dict(...)`, `Counter(palavras)`.

| Pedaço | O que é |
|---|---|
| `return` | devolve o valor para quem chamou a função |
| `dict(...)` | copia a contagem para um dicionário comum |
| `Counter(palavras)` | conta cada string da lista |

`Counter` é uma ferramenta importada. O papel dela entra no breakdown junto com a função.

```python
from collections import Counter
```

| Ferramenta | De onde vem | Papel nesta função | Documentação |
|---|---|---|---|
| `Counter` | `collections` | percorre a lista e monta a contagem: cada string vira chave, o `int` é quantas vezes apareceu | [Counter](https://docs.python.org/3/library/collections.html#collections.Counter) |
| `dict` | embutido do Python | copia essa contagem para um dicionário comum | [dict](https://docs.python.org/3/library/stdtypes.html#dict) |

Com `["gato", "cão", "gato"]`, o `Counter` entrega `{"gato": 2, "cão": 1}`. A função só pede essa contagem e devolve a cópia.

A tabela seguinte é a ordem de execução. As linhas continuam na ordem da leitura. A coluna `Quando roda` diz o momento em que cada pedaço roda.

| Ordem na linha | Pedaço | Quando roda |
|---|---|---|
| 1º escrito | `return` | por último: só devolve o que os parênteses já produziram |
| 2º escrito | `dict(...)` | no meio: espera o `Counter` terminar |
| 3º escrito | `Counter(palavras)` | primeiro: é o parêntese mais de dentro |

O Python entra no parêntese mais interno, sobe um nível e só então chega na palavra que está à esquerda. `Counter` conta, `dict` copia a contagem, e `return` devolve o dicionário.

A mesma função, com a contagem separada do `return`:

```python
def demo_counter(palavras: list[str]) -> dict[str, int]:
    contagem = Counter(palavras)
    return dict(contagem)
```

`Counter` vem de `from collections import Counter`. É a ferramenta pronta. `contagem` é a variável que a função cria para guardar o resultado.

| Linha | O que acontece |
|---|---|
| `contagem = Counter(palavras)` | lê a lista e guarda a contagem |
| `return dict(contagem)` | copia essa contagem e devolve |

A lista chega pronta, fixa ou vinda de outro lugar: `demo_counter(["gato", "cão", "gato"])`. O `Counter` percorre essa lista. Sem `palavras` dentro do `Counter`, não há o que contar.
