---
name: connect-your-bank-brazil
description: >-
  Use this for free personal Open Finance in Brazil via Meu Pluggy. Always start
  with a detailed setup tutorial in chat. Do not open a browser unless the user
  explicitly asks you to drive setup. Then help with Pluggy API (one Item per
  bank).
---
# Connect your Bank (Brazil)

Free **personal** Open Finance in Brazil via Meu Pluggy + Pluggy API (own CPF only). Not the commercial multi-user plan (~R$ 2.500/mo).

## Hard rules (override everything else)

1. **Default = Tutorial mode.** On skill use, your first user-visible action is to deliver the setup tutorial below (user’s language).  
2. **Do not open a browser, computer-use, or visit** `meu.pluggy.ai` / `dashboard.pluggy.ai` **unless** the user has **explicitly** asked you to drive the setup in this conversation (examples: “conecta você”, “abre aí”, “faz no browser”, “usa o computer use”, “faz pra mim”).  
3. **Having browser/computer-use available is not permission.** Capability ≠ request.  
4. If they only say “quero conectar bancos” / “como conecto” / invoke the skill with no “do it for me” wording → **tutorial only**.  
5. Never paste Client Secret or passwords into chat. Secret stays in a local file; file path OK.

Optional: after the tutorial, one short offer — “Se quiser, eu conduzo no browser (você só faz login/OAuth).” If they decline or ignore, stay on tutorial / API help.

---

## Tutorial mode (always start here)

Deliver this guide cleanly in chat (Portuguese if they write in PT). Do not narrate skill meta or mode tables to the user.

### Overview

1. Connect banks on **Meu Pluggy**.  
2. Create a **Pluggy Dashboard** app and enable **MeuPluggy (connector 200)**.  
3. In **Demo**, authorize via **MeuPluggy** once per bank → copy each **Item ID**.  
4. Keep Client ID + Client Secret (local file) + Item IDs for the API.

Do **not** connect Nubank/Itaú/etc. **directly** in the Dashboard widget for personal free use — that is trial/paid. Use **MeuPluggy** only.

### Step 1 — Meu Pluggy

1. Open https://meu.pluggy.ai and sign up / sign in.  
2. Go to **Conexões** and connect each bank; approve Open Finance in the bank.  
3. Confirm banks on **Overview** (ignore marketing demo balances before login).

### Step 2 — Dashboard

1. Open https://dashboard.pluggy.ai and sign up / sign in.  
2. Create an **Application** (Development is fine).  
3. **Configurar → Credenciais**: copy **Client ID** and **Client Secret** (put the secret only in a local file).  
4. Enable connector **MeuPluggy (`200`)** in the app.  
5. A **15-day trial** banner is about commercial features; personal MeuPluggy via 200 stays free.

### Step 3 — Demo OAuth (one Item per bank)

1. **Aplicações → Iniciar Demo / Ir para Demo**.  
2. **Conectar conta** → choose **MeuPluggy** (search “Meu”), **not** the bank brand.  
3. Authorize; then **⋮ → Copiar Item ID**; label with the bank name.  
4. Repeat once for **each** bank connected in Meu Pluggy.

**Item rules:** 1 Item = 1 bank (checking + card share it). Seeing two Items is two banks — not a max-2 limit. Dev apps ~100 Items. Don’t duplicate the same CPF + institution. Bank on Overview but missing in API → Demo OAuth for that bank still needed.

**If you see:** *Contas de teste só podem conectar conectores sandbox…* → you picked a live bank; use **MeuPluggy**. Skip **Liberar dados reais / Falar com Vendas** for personal free use. Sandbox Pluggy Bank is fake data.

### Step 4 — Give the agent (when ready)

- Client ID (OK in chat)  
- Path to the Client Secret file (not the secret text)  
- One Item ID per bank  

Then ask for an API smoke test or spending summary if they want.

---

## Assisted mode (opt-in only)

**Enter only after** an explicit “do it for me / use the browser” request in this chat.

If they asked for assisted mode but you have **no** browser/computer use: say so in one line and keep helping via the tutorial + API.

If you **do** have browser/computer use and they opted in:

- Drive Meu Pluggy + Dashboard yourself.  
- Hand off only for password, bank consent, 2FA, Meu Pluggy OAuth.  
- Short status lines only.  
- Select **MeuPluggy** in Demo only; copy Item IDs yourself.  
- Confirm secret file is non-empty without printing it.  
- Do not fill sales forms.  
- Finish with the API smoke test below.

Procedure sketch: Meu Pluggy banks → Dashboard app + connector 200 + credentials file → Demo OAuth per bank → smoke test.

---

## API smoke test

Base: `https://api.pluggy.ai`

1. `POST /auth` with `clientId` + `clientSecret` → `apiKey` → `X-API-KEY`.  
2. `GET /accounts?itemId=…` per Item — match Overview.  
3. Transactions: **`GET /v2/transactions`** with `accountId`, `dateFrom`, `dateTo`, cursor `next`/`after`. Legacy `GET /transactions` → **410**.  
4. Amounts: BANK negative ≈ expense; CREDIT positive ≈ purchase. Prefer `description`; optionally skip `Same person transfer` and card payments when summarizing spend.

## Out of scope

- Auto-opening browsers because the tool exists  
- Other people’s banks on the free path  
- Bacen recipient registration  
- Guaranteeing coverage / refresh latency
