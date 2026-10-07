---
name: client-management
description: >-
  Use when installing or operating a client's customer management system (an
  Atomic CRM-based CRM branded with each client's own name) through its MCP:
  creating or updating contacts, deals, tasks and notes, or setting up the
  agent's access.
---
# Client management

Each client's customer management system is an Atomic CRM instance (Supabase + front end), but it carries the client's own company or system name. Talk to the client using their system's name, never "Atomic". The agent reaches it through the system's own MCP server (tools `get_schema`, `query`, `mutate`, `complete_task`, `display_task_list`), never directly through the database, because the MCP enforces the user's permissions (RLS).

## 1. Access setup (once per client)

1. In the client's Supabase dashboard, under **Authentication → OAuth Server**: enable the OAuth Server, set the **Authorization Path** to `/#/oauth/consent` (with the `#`, otherwise the consent page loads forever), and turn on **Allow Dynamic OAuth Apps**.
2. Under **Authentication → URL Configuration**, the Site URL must be the client's system address (e.g. their subdomain).
3. Under **Settings → JWT Keys**, the current key must be asymmetric (ECC P256), not "Legacy HS256".
4. Check: `GET https://<ref>.supabase.co/.well-known/oauth-authorization-server/auth/v1` should return JSON with a `registration_endpoint` (not "OAuth server is disabled").
5. Add the MCP server with the URL `https://<ref>.supabase.co/functions/v1/mcp` (also shown on the system's Profile page, "MCP Server" section) and complete the OAuth sign-in with the client's account. If the first sign-in is refused right after changing the settings, wait a few minutes and try again.

## 2. Before writing anything

1. Call `get_schema` once per session.
2. Read the client's configuration: `SELECT config->'noteStatuses', config->'dealStages', config->'dealCategories' FROM configuration`. Only use `value`s that exist there (statuses and stages vary per client).
3. Look for duplicates before creating: search `contacts_summary` by name, `phone_fts` or `email_fts`, and `companies` by name.

## 3. Write rules

- Never set `sales_id`; a trigger fills it with the signed-in user.
- Use `RETURNING id, ...` on every INSERT/UPDATE and check the result.
- **Contact** (`contacts`): `first_name`, `last_name` if known, `status` (one of the `noteStatuses`), `first_seen` and `last_seen` = `now()`, `tags` = `'{}'` if none.
  - Phone in `phone_jsonb`: `[{"number": "+55 11 91234-5678", "type": "Work"}]` (types: Work, Home, Other).
  - Email in `email_jsonb`: `[{"email": "x@y.com", "type": "Work"}]`.
  - Free-form context goes in `background`.
- **Deal** (`deals`): `name`, `contact_ids` (`ARRAY[id]::bigint[]`), `category`, `stage`, `index` (0), and **always** `amount` (use 0 if unknown) and `expected_closing_date` (e.g. `current_date + 30`). A deal with an empty amount or date crashes the UI with a generic error page. `company_id` is optional.
- **Task** (`tasks`): requires `contact_id`; `text`, `type`, `due_date`. To finish one, use `complete_task`. To show tasks, query them and pass them to `display_task_list` instead of listing them as text.
- **Note**: `contact_notes` (`contact_id`, `text`, `status`) or `deal_notes` (`deal_id`, `text`, `type`).
- After creating something new, ask the user to open the screen and check it. If it breaks, compare the record with the required fields above and fix it with an UPDATE.

## 4. Safety

- Reads and record creation the user asked for: go ahead.
- `DELETE`, an UPDATE without `WHERE id = ...`, or changes to more than a few records: show what will change and ask for confirmation first.
- Never message or email a contact from the system without the user approving the draft.
- End customers' data is personal data (LGPD in Brazil): don't copy it out of the system unless explicitly asked.
