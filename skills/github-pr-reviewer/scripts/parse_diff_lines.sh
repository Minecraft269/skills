#!/usr/bin/env bash
# =============================================================================
# parse_diff_lines.sh — Extract file paths and diff line numbers from a unified diff
#
# Purpose: Parse GitHub PR diff output, generate file_path:diff_line_number:side mappings,
#          to assist with line parameter calculation for add_comment_to_pending_review.
#
# Usage:
#   cat pr_diff.txt | bash parse_diff_lines.sh
#   gh pr diff 5 --repo owner/repo | bash parse_diff_lines.sh
#
# Output format (tab-separated):
#   file:<path>	line:<diff line number>	side:<LEFT|RIGHT>
#
# Dependencies: bash (minimum 4.0), grep, sed
# Compatibility: Windows Git Bash / Linux / macOS
# =============================================================================

set -o pipefail

current_file=""
line_number=0

while IFS= read -r raw_line; do
  line_number=$((line_number + 1))

  # Detect file header: diff --git a/<path> b/<path>
  if [[ "$raw_line" =~ ^diff\ --git\ a/(.*)\ b/(.*)$ ]]; then
    current_file="${BASH_REMATCH[1]}"
    continue
  fi

  # Skip separator lines (index / --- / +++)
  if [[ "$raw_line" =~ ^index\  ]] || [[ "$raw_line" =~ ^---\ [^+] ]] || [[ "$raw_line" =~ ^\+\+\+\  ]]; then
    continue
  fi

  # Skip hunk headers (@@ lines) and blank lines
  if [[ "$raw_line" =~ ^@@\  ]] || [[ -z "$raw_line" ]]; then
    continue
  fi

  # Only care about added and deleted lines
  if [[ "$raw_line" =~ ^\+[^+] ]] || [[ "$raw_line" =~ ^\+$ ]]; then
    # Added lines (+ prefix, excluding +++ file header)
    printf "file:%s\tline:%d\tside:RIGHT\n" "$current_file" "$line_number"
  elif [[ "$raw_line" =~ ^\-[^-] ]] || [[ "$raw_line" =~ ^\-$ ]]; then
    # Deleted lines (- prefix, excluding --- file header)
    printf "file:%s\tline:%d\tside:LEFT\n" "$current_file" "$line_number"
  fi
done

# If no output, input was empty or not a unified diff format
if [ "$line_number" -eq 0 ]; then
  echo "parse_diff_lines: input is empty, please provide unified diff content" >&2
  exit 1
fi
