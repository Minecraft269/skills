#!/usr/bin/env bash
# check-i18n-sync.sh — Structural sync validator for EN/CN skill files
# Usage: bash skills/_shared/check-i18n-sync.sh
# Exit code: 0 = all good, 1 = issues found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ISSUES=0
SKILLS_CHECKED=0

echo "=== i18n Sync Check — minecraft269-skills ==="
echo ""

# Find all English SKILL.md files
for en_file in "$SKILLS_DIR"/*/SKILL.md; do
  skill_name=$(basename "$(dirname "$en_file")")

  # Skip _shared (not a skill directory)
  [[ "$skill_name" == "_shared" ]] && continue

  cn_file="$SKILLS_DIR/$skill_name/locale/SKILL.cn.md"

  echo "--- $skill_name ---"

  # Check CN copy exists
  if [[ ! -f "$cn_file" ]]; then
    echo "  ❌ MISSING: locale/SKILL.cn.md"
    ISSUES=$((ISSUES + 1))
    continue
  fi
  echo "  ✅ CN copy exists"

  # Compare heading structure (count by level — headings differ by language)
  en_h2_count=$(grep -c '^## ' "$en_file" || true)
  cn_h2_count=$(grep -c '^## ' "$cn_file" || true)
  en_h3_count=$(grep -c '^### ' "$en_file" || true)
  cn_h3_count=$(grep -c '^### ' "$cn_file" || true)
  en_h4_count=$(grep -c '^#### ' "$en_file" || true)
  cn_h4_count=$(grep -c '^#### ' "$cn_file" || true)

  h2_ok=true; h3_ok=true; h4_ok=true
  [[ "$en_h2_count" != "$cn_h2_count" ]] && h2_ok=false
  [[ "$en_h3_count" != "$cn_h3_count" ]] && h3_ok=false
  [[ "$en_h4_count" != "$cn_h4_count" ]] && h4_ok=false

  if $h2_ok && $h3_ok && $h4_ok; then
    echo "  ✅ Heading structure matches (H2:$en_h2_count H3:$en_h3_count H4:$en_h4_count)"
  else
    echo "  ⚠️ Heading structure mismatch: EN(H2:$en_h2_count H3:$en_h3_count H4:$en_h4_count) vs CN(H2:$cn_h2_count H3:$cn_h3_count H4:$cn_h4_count)"
    ISSUES=$((ISSUES + 1))
  fi

  # Compare YAML frontmatter key count (should match)
  en_fm_keys=$(sed -n '/^---$/,/^---$/p' "$en_file" | grep -oP '^\w+:' | tr -d ':' | grep -v '^---$' | sort)
  cn_fm_keys=$(sed -n '/^---$/,/^---$/p' "$cn_file" | grep -oP '^\w+:' | tr -d ':' | grep -v '^---$' | sort)

  # Check for keys in EN missing from CN (excluding 'locale')
  while IFS= read -r key; do
    if ! grep -qFx "$key" <<< "$cn_fm_keys"; then
      echo "  ⚠️ Frontmatter key missing in CN: '$key'"
      ISSUES=$((ISSUES + 1))
    fi
  done <<< "$en_fm_keys"

  # Check for keys in CN missing from EN (excluding 'locale')
  while IFS= read -r key; do
    [[ "$key" == "locale" ]] && continue
    if ! grep -qFx "$key" <<< "$en_fm_keys"; then
      echo "  ⚠️ Frontmatter key missing in EN: '$key'"
      ISSUES=$((ISSUES + 1))
    fi
  done <<< "$cn_fm_keys"

  # Compare code block count
  en_blocks=$(grep -c '```' "$en_file" || true)
  cn_blocks=$(grep -c '```' "$cn_file" || true)
  if [[ "$en_blocks" != "$cn_blocks" ]]; then
    echo "  ⚠️ Code block count mismatch: EN=$en_blocks, CN=$cn_blocks"
    ISSUES=$((ISSUES + 1))
  else
    echo "  ✅ Code blocks match ($en_blocks triple-backticks)"
  fi

  # Check line count variance (±10%)
  en_lines=$(wc -l < "$en_file")
  cn_lines=$(wc -l < "$cn_file")
  diff_abs=$(( en_lines - cn_lines ))
  if [[ $diff_abs -lt 0 ]]; then diff_abs=$(( -diff_abs )); fi
  threshold=$(( (en_lines + cn_lines) / 20 + 5 ))
  if [[ $diff_abs -gt $threshold ]]; then
    echo "  ⚠️ Line count variance >5%: EN=$en_lines, CN=$cn_lines"
    ISSUES=$((ISSUES + 1))
  else
    echo "  ✅ Line count within range: EN=$en_lines, CN=$cn_lines"
  fi

  SKILLS_CHECKED=$((SKILLS_CHECKED + 1))
  echo ""
done

# Check docs CN copies exist
echo "--- docs/ ---"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/docs"
for doc in "$DOCS_DIR"/*.md; do
  doc_name=$(basename "$doc")
  # Skip CN copies themselves
  [[ "$doc_name" == *.cn.md ]] && continue
  cn_doc="$DOCS_DIR/${doc_name%.md}.cn.md"
  if [[ ! -f "$cn_doc" ]]; then
    echo "  ❌ MISSING: docs/$doc_name → ${doc_name%.md}.cn.md"
    ISSUES=$((ISSUES + 1))
  else
    echo "  ✅ docs/$doc_name ↔ docs/${doc_name%.md}.cn.md"
  fi
done

echo ""
echo "=== Summary ==="
echo "Skills checked: $SKILLS_CHECKED"
echo "Issues found:   $ISSUES"

if [[ $ISSUES -gt 0 ]]; then
  echo ""
  echo "❌ Sync check FAILED — $ISSUES issue(s) found."
  exit 1
else
  echo ""
  echo "✅ Sync check PASSED — all files in sync."
  exit 0
fi
