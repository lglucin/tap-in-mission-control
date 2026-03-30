#!/usr/bin/env bash
# Mission Control Dashboard Refresher
# Run manually: ./refresh.sh
# No AI, no tokens — just data + HTML.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$SCRIPT_DIR/index.html"

# Timestamp
NOW_PT=$(TZ="America/Los_Angeles" date "+%Y-%m-%d %I:%M %p PT")
NOW_DATE=$(TZ="America/Los_Angeles" date "+%Y-%m-%d")
YESTERDAY=$(TZ="America/Los_Angeles" date -v-1d "+%Y-%m-%d" 2>/dev/null || date -d "yesterday" "+%Y-%m-%d")

# PRs
echo "→ Fetching PRs..."
PR_JSON=$(gh pr list --repo lglucin/artgg --state open --json number,title,headRefName,createdAt --limit 50 2>/dev/null || echo "[]")
PR_COUNT=$(echo "$PR_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d))" 2>/dev/null || echo "?")

PR_ROWS=""
while IFS= read -r line; do
  num=$(echo "$line" | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d['number'])")
  title=$(echo "$line" | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d['title'][:80])")
  branch=$(echo "$line" | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d['headRefName'])")
  date=$(echo "$line" | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d['createdAt'][:10])")
  PR_ROWS+="      <li>
        <span class=\"pr-number\">#${num}</span>
        <span class=\"pr-title\">${title}</span>
        <span class=\"pr-branch\">${branch}</span>
        <span class=\"pr-date\">${date}</span>
      </li>
"
done < <(echo "$PR_JSON" | python3 -c "import json,sys; [print(json.dumps(r)) for r in json.load(sys.stdin)]")

# Memory
echo "→ Reading memory..."
MEMORY_FILE="$SCRIPT_DIR/../memory/${NOW_DATE}.md"
YESTERDAY_FILE="$SCRIPT_DIR/../memory/${YESTERDAY}.md"
MEMORY_CONTENT=""
MEMORY_LABEL=""

if [ -f "$MEMORY_FILE" ]; then
  MEMORY_CONTENT=$(cat "$MEMORY_FILE")
  MEMORY_LABEL="Today's Memory — ${NOW_DATE}"
elif [ -f "$YESTERDAY_FILE" ]; then
  MEMORY_CONTENT="No log yet for ${NOW_DATE}. Yesterday's highlights:

$(cat "$YESTERDAY_FILE")"
  MEMORY_LABEL="Memory — ${YESTERDAY} (no ${NOW_DATE} log yet)"
else
  MEMORY_CONTENT="No memory file found."
  MEMORY_LABEL="Memory"
fi

# Escape HTML special chars in memory content
MEMORY_CONTENT=$(echo "$MEMORY_CONTENT" | python3 -c "
import sys, html
content = sys.stdin.read()
print(html.escape(content))
")

echo "→ Writing HTML..."
cat > "$OUT" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Mission Control — Tap.In</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: #0d1117;
    color: #e6edf3;
    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', system-ui, sans-serif;
    padding: 20px;
    min-height: 100vh;
  }
  header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
    padding-bottom: 16px;
    border-bottom: 1px solid #21262d;
  }
  header h1 { font-size: 20px; font-weight: 600; letter-spacing: -0.3px; }
  header h1 span { color: #e63946; }
  .updated { font-size: 11px; color: #8b949e; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  .card {
    background: #161b22;
    border: 1px solid #21262d;
    border-radius: 10px;
    padding: 18px;
    overflow: hidden;
  }
  .card.full { grid-column: 1 / -1; }
  .card h2 {
    font-size: 11px; font-weight: 600; text-transform: uppercase;
    letter-spacing: 0.8px; color: #8b949e; margin-bottom: 14px;
  }
  .pr-list { list-style: none; }
  .pr-list li {
    padding: 9px 0; border-bottom: 1px solid #21262d;
    display: flex; justify-content: space-between;
    align-items: flex-start; gap: 10px;
  }
  .pr-list li:last-child { border-bottom: none; }
  .pr-number { color: #e63946; font-weight: 600; font-size: 12px; white-space: nowrap; }
  .pr-title { flex: 1; font-size: 13px; }
  .pr-branch {
    font-size: 10px; color: #8b949e; background: #1c2128;
    padding: 2px 7px; border-radius: 4px;
    font-family: 'SF Mono', 'Fira Code', monospace; white-space: nowrap;
  }
  .pr-date { font-size: 11px; color: #8b949e; white-space: nowrap; }
  .memory-content {
    font-size: 12px; line-height: 1.7;
    max-height: 400px; overflow-y: auto;
    white-space: pre-wrap;
    font-family: 'SF Mono', 'Fira Code', monospace;
    color: #c9d1d9;
    scrollbar-width: thin; scrollbar-color: #30363d #161b22;
  }
  .links { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
  .links a {
    display: block; padding: 10px 14px;
    background: #1c2128; border: 1px solid #21262d;
    border-radius: 8px; color: #e6edf3;
    text-decoration: none; font-size: 12px; font-weight: 500;
    transition: border-color 0.15s, background 0.15s;
  }
  .links a:hover { border-color: #e63946; background: #1a1f27; }
  .links a .link-label { font-size: 10px; color: #8b949e; display: block; margin-bottom: 2px; }
  .stat-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
  .stat-item label { display: block; font-size: 10px; color: #8b949e; margin-bottom: 3px; text-transform: uppercase; letter-spacing: 0.5px; }
  .stat-item value { display: block; font-size: 20px; font-weight: 600; }
  @media (max-width: 640px) {
    body { padding: 12px; }
    .grid { grid-template-columns: 1fr; }
    .links { grid-template-columns: 1fr 1fr; }
    .pr-branch { display: none; }
  }
</style>
</head>
<body>

<header>
  <h1><span>●</span> Mission Control</h1>
  <div class="updated">Last updated: ${NOW_PT}</div>
</header>

<div class="grid">

  <!-- Stats -->
  <div class="card">
    <h2>Tap.In</h2>
    <div class="stat-grid">
      <div class="stat-item">
        <label>Open PRs</label>
        <value>${PR_COUNT}</value>
      </div>
      <div class="stat-item">
        <label>Repo</label>
        <value style="font-size:13px">artgg</value>
      </div>
      <div class="stat-item">
        <label>Agent</label>
        <value style="font-size:13px">Clawdia</value>
      </div>
    </div>
  </div>

  <!-- Quick Links -->
  <div class="card">
    <h2>Quick Links</h2>
    <div class="links">
      <a href="https://github.com/lglucin/artgg/pulls" target="_blank">
        <span class="link-label">GitHub</span>artgg PRs
      </a>
      <a href="https://www.taptaptap.in" target="_blank">
        <span class="link-label">Production</span>taptaptap.in
      </a>
      <a href="https://vercel.com/lglucins-projects" target="_blank">
        <span class="link-label">Deployments</span>Vercel
      </a>
      <a href="https://t-api-n-staging-2eed87cd3eee.herokuapp.com/health" target="_blank">
        <span class="link-label">Staging API</span>Heroku health
      </a>
    </div>
  </div>

  <!-- PRs -->
  <div class="card full">
    <h2>Open PRs — lglucin/artgg (${PR_COUNT} open)</h2>
    <ul class="pr-list">
${PR_ROWS}    </ul>
  </div>

  <!-- Memory -->
  <div class="card full">
    <h2>${MEMORY_LABEL}</h2>
    <div class="memory-content">${MEMORY_CONTENT}</div>
  </div>

</div>
</body>
</html>
HTMLEOF

echo "✓ Dashboard written to $OUT"
