#!/usr/bin/env bash
# UserPromptSubmit hook: if the message ends with "-parrot", Claude must only
# restate what the user wrote, without doing anything operational.

prompt=$(jq -r '.prompt // ""')

# No keyword at the end (trailing whitespace ignored): do nothing.
if ! printf '%s' "$prompt" | tr -d '\r' | sed -z 's/[[:space:]]*$//' | grep -qziE -e '(^|[[:space:]])-parrot$'; then
  exit 0
fi

read -r -d '' instruction <<'EOF'
PARROT MODE (-parrot) — applies to this turn only.
The user wrote a stream of consciousness and wants to check that you understood it, BEFORE anything else.
- Do NOT use any tool: no reading/editing files, no commands, no searches, no skills.
- Do NOT propose solutions, alternatives, plans or technical assessments.
- Restate it in your own words, in an orderly way: the problem, what they want to achieve, constraints and any solution ideas they already expressed.
- Separate what they said explicitly from what you inferred.
- If there are contradictions or ambiguities, point them out as questions, without resolving them.
- Reply in the user's language and end by asking whether you understood correctly. Then stop.
EOF

jq -n --arg ctx "$instruction" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
