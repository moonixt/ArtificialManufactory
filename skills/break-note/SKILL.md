---
name: break-note
description: >-
  Save a break study note as an Obsidian markdown file in the user's Obsidian
  vault. Use when the user asks to create the .md, save the breakdown to
  Obsidian, or write the note for a function they just learned with break.
---

# Break note

Turn the current `break` into one study note. Reply in the user's language. Write the file. Do not paste the note back into the chat.

## Where

Vault: the user's Obsidian vault; default example: `/home/arch/Clones/Tech Research`. Use the vault path the user names. When they do not name one, use the default example.

File name: the function name plus `.md`, in the vault root, as in `demo_counter.md`. If that file already exists, update it in place.

Write the file directly. Do not pass the body through `obsidian create content=`.

## Source

Use the `break` already done in this conversation: source order, imported tools, execution order, and the separated form. If there is no `break` yet, do that breakdown first, then write the note from it.

Keep a fact only when it came from that breakdown or from a question the user asked about this function. "O que ficou claro" is one short sentence per conclusion, in the order the user reached it.

## Note shape

Frontmatter:

```yaml
---
title: nome_da_funcao
date: YYYY-MM-DD
tags:
  - linguagem
  - assunto
aliases:
  - ferramenta importada
related: "[[nota relacionada]]"
---
```

Quote wikilinks in YAML. Leave a blank line before every table.

1. Title and one sentence naming the source file. Wikilink a sibling note when one exists, such as `[[demo_counter]]` and `[[Listas e dicionarios]]`.
2. The function in a code block, import included.
3. A call with concrete values and the returned value in a comment.
4. `## Ordem da função`, the source-order sentence, then `Pedaço` | `O que é`.
5. `## Ferramentas`, the import line, then `Ferramenta` | `De onde vem` | `Papel nesta função` | `Documentação`. The link is the official docs URL from the `break` skill. Follow with the concrete walk of that tool.
6. One section per extra idea the user actually asked about, with a small table.
7. `## Ordem de execução`, then `Ordem na linha` | `Pedaço` | `Quando roda`. If the function loops, add the table of each lap and the value at the end of the lap.
8. `## A mesma função, em linhas separadas`, the code, then `Linha` | `O que acontece`.
9. `## O que ficou claro`, a numbered list.
