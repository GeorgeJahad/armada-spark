#!/bin/bash
# Verify the project compiles before Claude stops
INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Prevent infinite loops - skip if already triggered by a Stop hook
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  echo '{"systemMessage": "Skipped build verification (stop hook already active)"}'
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# Check transcript for files Claude actually edited this session
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')
EDITED_FILES=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  EDITED_FILES=$(grep -oP '"file_path"\s*:\s*"[^"]+"' "$TRANSCRIPT_PATH" 2>/dev/null \
    | sed 's/"file_path"\s*:\s*"//;s/"$//' | sort -u)
fi

BUILD_FILES=$(echo "$EDITED_FILES" | grep -E '\.(scala|java)$|pom\.xml' | head -1)
if [ -z "$BUILD_FILES" ]; then
  echo '{"systemMessage": "Skipped build verification (no code edits this session)"}'
  exit 0
fi

RESULT=$(mvn compile -q 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  ESCAPED_RESULT=$(echo "$RESULT" | head -20 | jq -Rs .)
  echo "{\"systemMessage\": \"Build failed. Fix compilation errors before finishing: ${ESCAPED_RESULT}\"}" >&2
  exit 2
fi

echo '{"systemMessage": "Build verification passed"}'
exit 0
