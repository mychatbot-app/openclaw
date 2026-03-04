---
name: publish-page
description: Publish a workspace HTML file to a live subdomain at *.page.mychatbot.app so users get an instant public URL for their generated page.
metadata:
  openclaw:
    emoji: "🌐"
    requires:
      bins: ["curl"]
---

# Publish Page

Publish an uploaded HTML file to a custom subdomain like `my-landing.page.mychatbot.app`. This creates a live, publicly accessible page in seconds.

**Prerequisite:** The file must already be uploaded via the **workspace-files** skill. You need the `url` or `s3_key` from that upload.

## Publish Endpoint

```
POST https://api.mychatbot.app/published_sites
Content-Type: application/json
```

**Request body:**

```json
{
  "subdomain": "my-landing",
  "account_id": "${MCB_ACCOUNT_ID}",
  "s3_key": "client_files/<account_id>_<filename>.html"
}
```

**Response:**

```json
{
  "status": "success",
  "subdomain": "my-landing",
  "url": "https://my-landing.page.mychatbot.app",
  "s3_key": "client_files/acc123_landing.html"
}
```

## How to Publish

```bash
curl -s -X POST "https://api.mychatbot.app/published_sites" \
  -H "Content-Type: application/json" \
  -d "{
    \"subdomain\": \"<subdomain>\",
    \"account_id\": \"${MCB_ACCOUNT_ID}\",
    \"s3_key\": \"<s3_key>\"
  }" | jq .
```

The `s3_key` is the storage path — extract it from the workspace-files upload URL:
- Upload URL: `https://static.mychatbot.app/client_files/acc123_landing.html`
- s3_key: `client_files/acc123_landing.html`

## How to Unpublish

```bash
curl -s -X DELETE "https://api.mychatbot.app/published_sites?subdomain=<subdomain>&account_id=${MCB_ACCOUNT_ID}" | jq .
```

## How to List Published Sites

```bash
curl -s "https://api.mychatbot.app/published_sites?account_id=${MCB_ACCOUNT_ID}" | jq .
```

## Subdomain Rules

- Lowercase letters, numbers, and hyphens only
- Cannot start or end with a hyphen
- Max 63 characters
- Must be unique across all accounts — if taken by another account, choose a different name

## Workflow

1. **Generate** the HTML page in your workspace
2. **Upload** it using the workspace-files skill — get the URL back
3. **Ask the user** what subdomain they want (e.g. `my-store`, `bobs-bakery`)
4. **Extract the s3_key** from the upload URL (strip `https://static.mychatbot.app/`)
5. **Publish** via `POST /published_sites`
6. **Share the live URL** with the user: `https://<subdomain>.page.mychatbot.app`

## Updating a Published Page

To update a page that's already published:

1. Upload the new version with a **different filename** (append version suffix, e.g. `landing_v2.html`) — the CDN caches by URL for 24 hours
2. Call `POST /published_sites` again with the same subdomain and the new `s3_key` — this updates the mapping

## Tips

- Always confirm the subdomain choice with the user before publishing
- If a subdomain is taken (409 conflict), suggest alternatives
- The page is live immediately after publishing — no propagation delay
- Published pages are served with a 5-minute cache (`Cache-Control: public, max-age=300`)
- Only one file per subdomain — for multi-page sites, create a single self-contained HTML file with inline CSS/JS
- HTML files should be self-contained (inline styles, inline scripts, embedded images as base64) for best results
