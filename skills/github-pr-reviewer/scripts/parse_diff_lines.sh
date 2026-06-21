#!/usr/bin/env bash
# =============================================================================
# parse_diff_lines.sh — 从 unified diff 中提取文件路径和 diff 行号
#
# 用途：解析 GitHub PR diff 输出，生成 文件路径:diff行号:侧 的映射，
#       辅助 add_comment_to_pending_review 的 line 参数计算。
#
# 用法：
#   cat pr_diff.txt | bash parse_diff_lines.sh
#   gh pr diff 5 --repo owner/repo | bash parse_diff_lines.sh
#
# 输出格式（制表符分隔）：
#   file:<路径>	line:<diff行号>	side:<LEFT|RIGHT>
#
# 依赖：bash（最低 4.0）、grep、sed
# 兼容：Windows Git Bash / Linux / macOS
# =============================================================================

set -o pipefail

current_file=""
line_number=0

while IFS= read -r raw_line; do
  line_number=$((line_number + 1))

  # 检测文件头：diff --git a/<path> b/<path>
  if [[ "$raw_line" =~ ^diff\ --git\ a/(.*)\ b/(.*)$ ]]; then
    current_file="${BASH_REMATCH[1]}"
    continue
  fi

  # 跳过分隔线（index / --- / +++）
  if [[ "$raw_line" =~ ^index\  ]] || [[ "$raw_line" =~ ^---\ [^+] ]] || [[ "$raw_line" =~ ^\+\+\+\  ]]; then
    continue
  fi

  # 跳过 hunk 头部（@@ 行）和空行
  if [[ "$raw_line" =~ ^@@\  ]] || [[ -z "$raw_line" ]]; then
    continue
  fi

  # 只关心新增和删除的行
  if [[ "$raw_line" =~ ^\+[^+] ]] || [[ "$raw_line" =~ ^\+$ ]]; then
    # 新增行（+ 开头，但排除 +++ 文件头）
    printf "file:%s\tline:%d\tside:RIGHT\n" "$current_file" "$line_number"
  elif [[ "$raw_line" =~ ^\-[^-] ]] || [[ "$raw_line" =~ ^\-$ ]]; then
    # 删除行（- 开头，但排除 --- 文件头）
    printf "file:%s\tline:%d\tside:LEFT\n" "$current_file" "$line_number"
  fi
done

# 如果没有任何输出，说明输入为空或格式不是 unified diff
if [ "$line_number" -eq 0 ]; then
  echo "parse_diff_lines: 输入为空，请提供 unified diff 内容" >&2
  exit 1
fi
