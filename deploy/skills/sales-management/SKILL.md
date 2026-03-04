---
name: sales-management
description: Comprehensive management of MyChatBot sales platform — agents, clients, chats, pipelines, integrations, outreach, and more. Use when the user asks about their sales bots, leads, conversations, orders, or wants to configure the system.
metadata:
  openclaw:
    emoji: "📊"
    requires:
      bins: ["curl"]
---

# Sales Management

Comprehensive management of your MyChatBot sales agents, CRM, and automation platform via MCP.

## MCP Server

The sales management tools are available via MCP at:

```
${MCB_MCP_URL}
```

**Account ID:** `${MCB_ACCOUNT_ID}`

## Available Tools (66)

### Account Overview
- `get_account_summary` — High-level stats: total assistants, clients, chats, integrations, follow-ups, pipelines, orders
- `get_subscription_info` — Current plan, tokens left, expiration date

### Assistants (Sales Bots)
- `list_assistants` — List all active bots with name, status, language, model
- `get_assistant(assistant_id)` — Full detail: instructions, welcome message, integrations, skills, metadata
- `assistant_create(bot_name, instructions?, welcome_message?, language?)` — Create new assistant
- `assistant_update(assistant_id, bot_name?, welcome_message?, language?, status?, model?)` — Update fields
- `assistant_update_instructions(assistant_id, instructions)` — Update system prompt (with moderation)
- `assistant_list_skills(assistant_id)` — List skills with name, description, is_always_active
- `assistant_create_skill(assistant_id, name, description?, instructions?, is_always_active?)` — Create skill
- `assistant_update_skill(skill_id, name?, description?, instructions?, is_always_active?)` — Update skill
- `assistant_delete_skill(skill_id)` — Delete skill
- `assistant_get_config_link(assistant_id)` — Web UI link to configure assistant
- `get_assistant_available_tools(assistant_id)` — List all execution tools available to this assistant (based on integrations, knowledge bases, feature toggles). Use when writing instructions to reference correct tool names.

### Clients (Leads/Customers)
- `list_clients(funnel_status?, labels?, search?, pipeline_id?, has_phone_number?, has_email?, order_by?, limit?, offset?)` — Rich search/filter
- `get_client(client_id)` — Full client record with contact info, labels, metadata
- `client_create(full_name, email?, phone_number?, company_name?, funnel_status?, labels?, pipeline_id?)` — Create lead
- `client_update(client_id, full_name?, email?, phone_number?, company_name?, funnel_status?, labels?, manager_id?)` — Update client
- `client_delete(client_id)` — Delete client and associated chats
- `client_list_notes(client_id, limit?, offset?)` — List notes
- `client_create_note(client_id, content)` — Add note
- `client_delete_note(client_id, note_id)` — Remove note
- `client_list_tasks(client_id, limit?, offset?)` — List tasks
- `client_create_task(client_id, title, description?, priority?, due_date?)` — Create task
- `client_update_task(client_id, task_id, title?, description?, status?, priority?)` — Update task
- `client_delete_task(client_id, task_id)` — Delete task
- `client_list_attachments(client_id, limit?, offset?)` — List file attachments

### Chats (Conversations)
- `list_chats(assistant_id?, needs_operator?, client_id?, limit?)` — Recent conversations
- `get_chat(chat_id)` — Chat details with metadata, follow-up state
- `get_chat_messages(chat_id, limit?)` — Read message history (last N messages from MongoDB)

### Integrations
- `list_integrations(type?)` — All integrations: CRMs, knowledge bases, MCPs (secrets stripped)
- `get_integration(integration_id)` — Detailed config (secrets stripped)
- `get_integration_config_link(integration_id)` — Web UI link

### Follow-ups (Outreach Automations)
- `list_follow_ups(type?, status?)` — All automations with targeting info
- `get_follow_up(follow_up_id)` — Full detail with steps and filters
- `follow_up_create(name, target_status_name?, target_labels?)` — Create postponed follow-up (draft)
- `follow_up_update(follow_up_id, name?, status?, target_status_name?, target_labels?)` — Update
- `follow_up_delete(follow_up_id)` — Delete

### Pipelines & Funnel Statuses
- `list_pipelines` — All pipelines
- `get_pipeline(pipeline_id)` — Pipeline + its funnel statuses
- `pipeline_create(name, description?)` — Create pipeline
- `pipeline_update(pipeline_id, name?, description?)` — Update pipeline
- `pipeline_delete(pipeline_id)` — Delete (with safety checks)
- `funnel_status_create(pipeline_id, status_name, color_index?)` — Add stage
- `funnel_status_delete(pipeline_id, status_name)` — Remove stage

### Channels
- `list_channels(assistant_id?)` — All channels with type, status (credentials stripped)
- `channel_toggle(assistant_id, page_id, communication_channel, is_on)` — Enable/disable
- `channel_get_config_link(assistant_id, channel_type)` — Web UI link (channels need manual auth setup)

### Orders
- `list_orders(since_date?, to_date?, client_id?, limit?, offset?)` — Order records
- `get_order_stats(since_date?, to_date?)` — Total count, revenue, by-channel breakdown

### Labels
- `list_labels` — All labels/tags
- `label_create(label_name)` — Create label
- `label_delete(label_name)` — Delete label

### Test Chat
- `test_chat_start(assistant_id)` — Start test session (clears previous history), uses live instructions
- `test_chat_send(assistant_id, message)` — Send message, get AI response (synchronous)
- `test_chat_end(assistant_id)` — End session and clear chat history

### Knowledge Base (FAQ)
- `create_faq_knowledge_base(knowledge_base, name, language?, entries?)` — Create FAQ KB integration, optionally seed with entries (id, question, answer)
- `list_faq_knowledge_base_entries(integration_id)` — List all FAQ entries with IDs, questions, answers
- `update_faq_knowledge_base_entries(integration_id, add?, update?, remove?)` — Granular add/update/remove operations on FAQ entries
- `delete_faq_knowledge_base(integration_id)` — Delete FAQ KB and all indexed data (irreversible)

### Knowledge Base (Products)
- `create_products_integration(knowledge_base, name, language?, products?)` — Create manually-managed product catalog, optionally seed with products (arbitrary attributes; `name` is the primary field)
- `list_products(integration_id)` — List all products with their attributes
- `update_products(integration_id, add?, update?, remove?)` — Granular add/update/remove operations on products
- `delete_products_integration(integration_id)` — Delete Products catalog and all indexed data (irreversible)

### Knowledge Base (Product Feed)
- `create_product_feed_integration(knowledge_base, feed_url, language, name?, index_images?)` — Create Product Feed from URL (JSON/XML/YML/Google Shopping). Async processing — use `get_integration(integration_id)` to check status.

### Usage Statistics
- `get_token_usage(since_date?, to_date?, assistant_id?)` — Token breakdown by model and assistant
- `get_usage_summary(since_date?, to_date?)` — Combined: tokens, orders, chats, clients for period

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

1. **Start with summary**: `get_account_summary` → understand the account landscape
2. **Agent deep dive**: `list_assistants` → `get_assistant` → review instructions → `assistant_update_instructions` to modify
3. **Test changes**: `test_chat_start` → `test_chat_send` (multiple rounds) → `test_chat_end` to verify behavior
4. **Client management**: `list_clients(search="...")` → `get_client` → `client_create_note` / `client_update`
5. **Pipeline setup**: `list_pipelines` → `get_pipeline` → `funnel_status_create` to add stages
6. **Outreach**: `follow_up_create` → `follow_up_update(status="active")` to launch
7. **Chat review**: `list_chats(needs_operator=true)` → `get_chat_messages` to read conversation
8. **Channel setup**: `list_channels` → `channel_get_config_link` → user configures in browser → `channel_toggle(is_on=true)`
9. **Analytics**: `get_usage_summary` → `get_token_usage` → `get_order_stats`
10. **Knowledge base (FAQ)**: `create_faq_knowledge_base` (seed entries) → `list_faq_knowledge_base_entries` → `update_faq_knowledge_base_entries` to maintain
11. **Knowledge base (Product Feed)**: `create_product_feed_integration` with feed URL → `get_integration(integration_id)` to check indexing status
12. **Knowledge base (Products)**: `create_products_integration` (seed products) → `list_products` → `update_products` to maintain catalog
