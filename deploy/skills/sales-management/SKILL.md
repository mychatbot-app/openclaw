---
name: sales-management
description: Manage MyChatBot sales agents, clients, chats, integrations, and follow-ups. Use when the user asks about their sales bots, leads, conversations, or wants to review account status.
metadata:
  openclaw:
    emoji: "📊"
    requires:
      bins: ["curl"]
---

# Sales Management

Manage your MyChatBot sales agents and CRM data via the MyChatBot API.

## MCP Server

The sales management tools are available via MCP at:

```
${MCB_MCP_URL}
```

**Account ID:** `${MCB_ACCOUNT_ID}`

## Available Tools

### Account Overview
- `get_account_summary` — High-level stats: total assistants, clients, chats, integrations, follow-ups

### Assistants (Sales Bots)
- `list_assistants` — List all active sales bots with name, status, language, model
- `get_assistant(assistant_id)` — Detailed info: instructions, welcome message, integrations, follow-ups config

### Clients (Leads/Customers)
- `list_clients(funnel_status?, limit?, offset?)` — Browse clients, filter by funnel status
- `get_client(client_id)` — Full client details: contact info, funnel status, labels, company

### Chats
- `list_chats(assistant_id?, needs_operator?, limit?)` — Recent conversations, filter by bot or operator-needed
- Chats show: client name, channel (telegram/whatsapp/instagram/etc), last active, unread count

### Integrations
- `list_integrations` — All connected channels, MCPs, and knowledge bases

### Follow-ups
- `list_follow_ups` — Automated follow-up sequences: name, type, status, schedule, targeting

## How to Call Tools

Use `curl` to call the MCP endpoint directly:

```bash
# Initialize
curl -s -X POST "${MCB_MCP_URL}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"openclaw","version":"1.0.0"}}}'

# List tools
curl -s -X POST "${MCB_MCP_URL}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'

# Call a tool
curl -s -X POST "${MCB_MCP_URL}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_account_summary","arguments":{}}}'
```

## Workflow Tips

1. **Start with summary**: Always begin with `get_account_summary` to understand the account
2. **Drill down**: List assistants → pick one → get details → list its chats
3. **Find issues**: Check `list_chats(needs_operator=true)` for conversations needing human help
4. **Client lookup**: Use `list_clients` to find leads, filter by `funnel_status` for pipeline views
