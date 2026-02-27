---
name: workspace-files
description: Share workspace files with users by uploading them to static hosting and returning preview-ready URLs. Maintains a local mapping to avoid duplicate uploads.
metadata:
  openclaw:
    emoji: "📁"
    requires:
      bins: ["curl"]
---

# Workspace Files

Share files from your workspace with users by uploading them to static hosting. Once uploaded, files get a permanent public URL that renders inline previews in chat.

## Upload Endpoint

```
POST https://api.mychatbot.app/client_files/${MCB_ACCOUNT_ID}_<filename>
```

Content-Type: `multipart/form-data`, field name: `file`, max size: **50 MB**.

**Response:**
```json
{
  "status": "success",
  "url": "https://static.mychatbot.app/client_files/<account_id>_<filename>",
  "type": "application/pdf"
}
```

## How to Upload a File

```bash
curl -s -X POST "https://api.mychatbot.app/client_files/${MCB_ACCOUNT_ID}_$(basename "<filepath>")" \
  -F "file=@<filepath>" \
  | jq -r '.url'
```

Replace `<filepath>` with the absolute path to the workspace file.

## Upload Mapping

Maintain a JSON mapping file at `workspace/.file_uploads.json` to track uploaded files and avoid re-uploading unchanged files:

```json
{
  "reports/q1_summary.pdf": {
    "url": "https://static.mychatbot.app/client_files/acc123_q1_summary.pdf",
    "size": 245120,
    "uploaded_at": "2026-02-27T10:30:00Z"
  }
}
```

### Rules

1. **Before uploading**, read `.file_uploads.json` and check if the file path already has an entry.
2. **If an entry exists**, compare the current file size with the stored `size`. If they match, reuse the existing `url` — do not re-upload.
3. **If the file is new or the size changed**, upload it **with a different filename** (e.g. append a short timestamp or version suffix like `report_v2.pdf` or `animation_1709048400.html`). The CDN caches files by URL for 24 hours — uploading to the same name will serve the stale version.
4. Update the mapping with the new `url`, `size`, and `uploaded_at`.
5. **After every upload**, write the updated mapping back to `.file_uploads.json`.

## Workflow

1. User asks for a file or you need to share a workspace file
2. Check `.file_uploads.json` for an existing upload
3. If not found or stale, upload via `curl` to the endpoint above
4. Update `.file_uploads.json`
5. Return the URL to the user in your response — the frontend renders file previews automatically

## Supported File Types

Images (png, jpg, gif, webp, svg), documents (pdf, doc, docx, xls, xlsx, csv, txt), archives (zip), and other common formats. The endpoint accepts any file up to 50 MB.

## Tips

- **ALWAYS copy the URL exactly from the `curl` response** — never retype or reconstruct URLs manually. The response JSON `url` field is the canonical link.
- Use descriptive filenames — the URL includes the filename and users see it
- For files larger than 50 MB, suggest the user download directly from the workspace or split the file
- When sharing multiple files, upload them in parallel for speed
- Always include the file URL in your response text so the user can click it
- HTML files will render as an inline preview in the chat automatically
