#!/bin/bash
#
# Agent Team Snapshot
# Dumps the full state of the long-running agent harness:
# project state, tasks, knowledge, quality, git history, and team config.
#
# Usage:
#   ./snapshot.sh              # print to stdout
#   ./snapshot.sh > snap.md    # save to file
#   ./snapshot.sh --json       # machine-readable JSON output

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$ROOT/.claude"
NOW=$(date '+%Y-%m-%d %H:%M:%S')
JSON_MODE=false

[[ "${1:-}" == "--json" ]] && JSON_MODE=true

# ── Helpers ──────────────────────────────────────────────

file_or_na() {
  if [[ -f "$1" ]]; then
    cat "$1"
  else
    echo "[not found]"
  fi
}

json_file_or_null() {
  if [[ -f "$1" ]]; then
    cat "$1"
  else
    echo "null"
  fi
}

count_tasks() {
  local file="$1" status="$2"
  if [[ -f "$file" ]]; then
    grep -c "\"status\": \"$status\"" "$file" 2>/dev/null || echo 0
  else
    echo 0
  fi
}

# ── JSON Mode ────────────────────────────────────────────

if $JSON_MODE; then
  cat <<JSONEOF
{
  "snapshot_time": "$NOW",
  "state": $(json_file_or_null "$ROOT/state.json"),
  "task_plan": $(json_file_or_null "$ROOT/task_plan.json"),
  "adapter_exists": $([ -f "$CLAUDE_DIR/domain/adapter.md" ] && echo true || echo false),
  "preferences_exists": $([ -f "$CLAUDE_DIR/domain/knowledge/preferences.md" ] && echo true || echo false),
  "anti_patterns_exists": $([ -f "$CLAUDE_DIR/domain/knowledge/anti-patterns.md" ] && echo true || echo false),
  "knowledge_files": [$(find "$CLAUDE_DIR/domain/knowledge" -name '*.md' 2>/dev/null | sed 's/.*/"&"/' | paste -sd, - || echo '')],
  "decision_count": $(find "$CLAUDE_DIR/docs/decisions" -name '*.md' 2>/dev/null | wc -l | tr -d ' '),
  "evidence_count": $(find "$CLAUDE_DIR/docs/evidence" -name '*' -not -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' '),
  "recent_commits": [$(git -C "$ROOT" log --oneline -10 2>/dev/null | sed 's/"/\\"/g; s/.*/"&"/' | paste -sd, - || echo '')]
}
JSONEOF
  exit 0
fi

# ── Markdown Mode ────────────────────────────────────────

cat <<EOF
# Agent Team Snapshot
**Generated:** $NOW
**Project root:** $ROOT

---

## Project State (\`state.json\`)

EOF

if [[ -f "$ROOT/state.json" ]]; then
  # Extract key fields for summary
  PROJECT=$(python3 -c "import json; d=json.load(open('$ROOT/state.json')); print(d.get('project','?'))" 2>/dev/null || echo "?")
  PHASE=$(python3 -c "import json; d=json.load(open('$ROOT/state.json')); print(d.get('current_phase','?'))" 2>/dev/null || echo "?")
  LAST_AGENT=$(python3 -c "import json; d=json.load(open('$ROOT/state.json')); print(d.get('last_session',{}).get('agent','?'))" 2>/dev/null || echo "?")
  LAST_STATUS=$(python3 -c "import json; d=json.load(open('$ROOT/state.json')); print(d.get('last_session',{}).get('status','?'))" 2>/dev/null || echo "?")
  LAST_TASK=$(python3 -c "import json; d=json.load(open('$ROOT/state.json')); print(d.get('last_session',{}).get('task_completed','?'))" 2>/dev/null || echo "?")
  NEXT_TASK=$(python3 -c "import json; d=json.load(open('$ROOT/state.json')); print(d.get('last_session',{}).get('next_task','?'))" 2>/dev/null || echo "?")
  KNOWN_ISSUES=$(python3 -c "import json; d=json.load(open('$ROOT/state.json')); issues=d.get('known_issues',[]); [print(f'- {i}') for i in issues] if issues else print('- None')" 2>/dev/null || echo "- [parse error]")

  cat <<EOF
| Field | Value |
|---|---|
| Project | $PROJECT |
| Phase | $PHASE |
| Last agent | $LAST_AGENT |
| Last status | $LAST_STATUS |
| Last task | $LAST_TASK |
| Next task | $NEXT_TASK |

**Known issues:**
$KNOWN_ISSUES

<details><summary>Raw state.json</summary>

\`\`\`json
$(cat "$ROOT/state.json")
\`\`\`

</details>
EOF
else
  echo "*state.json not found — initializer has not been run yet.*"
fi

cat <<EOF

---

## Tasks (\`task_plan.json\`)

EOF

if [[ -f "$ROOT/task_plan.json" ]]; then
  TOTAL=$(count_tasks "$ROOT/task_plan.json" ".*")
  PENDING=$(count_tasks "$ROOT/task_plan.json" "pending")
  IN_PROG=$(count_tasks "$ROOT/task_plan.json" "in_progress")
  DONE=$(count_tasks "$ROOT/task_plan.json" "completed")
  BLOCKED=$(count_tasks "$ROOT/task_plan.json" "blocked")
  GOAL=$(python3 -c "import json; d=json.load(open('$ROOT/task_plan.json')); print(d.get('goal','?'))" 2>/dev/null || echo "?")

  cat <<EOF
**Goal:** $GOAL

| Status | Count |
|---|---|
| Pending | $PENDING |
| In Progress | $IN_PROG |
| Completed | $DONE |
| Blocked | $BLOCKED |

EOF

  # List each task
  python3 -c "
import json
d = json.load(open('$ROOT/task_plan.json'))
tasks = d.get('tasks', [])
for t in tasks:
    status = t.get('status', '?')
    icon = {'pending':'⬜','in_progress':'🔄','completed':'✅','blocked':'🚫'}.get(status, '❓')
    desc = t.get('description', '?')
    print(f'{icon} **{status}** — {desc}')
" 2>/dev/null || echo "*[parse error]*"

  cat <<EOF

<details><summary>Raw task_plan.json</summary>

\`\`\`json
$(cat "$ROOT/task_plan.json")
\`\`\`

</details>
EOF
else
  echo "*task_plan.json not found — no feature plan created yet.*"
fi

cat <<EOF

---

## Long-Term Memory

### Domain Adapter

EOF

if [[ -f "$CLAUDE_DIR/domain/adapter.md" ]]; then
  # Check if it's still the placeholder
  if grep -q "NOT INITIALIZED" "$CLAUDE_DIR/domain/adapter.md" 2>/dev/null; then
    echo "*Adapter exists but has NOT been initialized (still placeholder).*"
  else
    echo "*Adapter is configured.* Sections:"
    grep '^## ' "$CLAUDE_DIR/domain/adapter.md" | sed 's/^## /- /'
  fi
else
  echo "*adapter.md not found.*"
fi

cat <<EOF

### Preferences (\`preferences.md\`)

EOF

if [[ -f "$CLAUDE_DIR/domain/knowledge/preferences.md" ]]; then
  echo "$(wc -l < "$CLAUDE_DIR/domain/knowledge/preferences.md" | tr -d ' ') lines"
  echo ""
  cat "$CLAUDE_DIR/domain/knowledge/preferences.md"
else
  echo "*Not yet created — run the learner agent after human feedback sessions.*"
fi

cat <<EOF

### Anti-Patterns (\`anti-patterns.md\`)

EOF

if [[ -f "$CLAUDE_DIR/domain/knowledge/anti-patterns.md" ]]; then
  echo "$(wc -l < "$CLAUDE_DIR/domain/knowledge/anti-patterns.md" | tr -d ' ') lines"
  echo ""
  cat "$CLAUDE_DIR/domain/knowledge/anti-patterns.md"
else
  echo "*Not yet created — run the learner agent after human feedback sessions.*"
fi

cat <<EOF

### Knowledge Files

EOF

KNOWLEDGE_FILES=$(find "$CLAUDE_DIR/domain/knowledge" -name '*.md' 2>/dev/null)
if [[ -n "$KNOWLEDGE_FILES" ]]; then
  echo "$KNOWLEDGE_FILES" | while read -r f; do
    echo "- \`$(basename "$f")\` ($(wc -l < "$f" | tr -d ' ') lines)"
  done
else
  echo "*No knowledge files yet.*"
fi

cat <<EOF

### Decisions (ADRs)

EOF

DECISION_FILES=$(find "$CLAUDE_DIR/docs/decisions" -name '*.md' 2>/dev/null)
if [[ -n "$DECISION_FILES" ]]; then
  echo "$DECISION_FILES" | while read -r f; do
    TITLE=$(head -1 "$f" | sed 's/^# //')
    echo "- \`$(basename "$f")\` — $TITLE"
  done
else
  echo "*No architectural decisions recorded yet.*"
fi

cat <<EOF

---

## Recent Notes (last 30 lines of \`notes.md\`)

EOF

if [[ -f "$ROOT/notes.md" ]]; then
  tail -30 "$ROOT/notes.md"
else
  echo "*notes.md not found.*"
fi

cat <<EOF

---

## Git History (last 15 commits)

\`\`\`
$(git -C "$ROOT" log --oneline -15 2>/dev/null || echo "[not a git repo]")
\`\`\`

---

## Agent Team Configuration

| Agent | File | Lines |
|---|---|---|
EOF

for f in "$CLAUDE_DIR/agents/"*.md; do
  if [[ -f "$f" ]]; then
    NAME=$(basename "$f" .md)
    LINES=$(wc -l < "$f" | tr -d ' ')
    echo "| $NAME | \`agents/$NAME.md\` | $LINES |"
  fi
done

cat <<EOF

### Harness Protocols

| Protocol | File | Lines |
|---|---|---|
EOF

for f in "$CLAUDE_DIR/harness/"*.md; do
  if [[ -f "$f" ]]; then
    NAME=$(basename "$f" .md)
    LINES=$(wc -l < "$f" | tr -d ' ')
    echo "| $NAME | \`harness/$NAME.md\` | $LINES |"
  fi
done

echo ""
echo "---"
echo "*End of snapshot.*"
