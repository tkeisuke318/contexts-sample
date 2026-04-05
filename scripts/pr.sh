#!/usr/bin/env bash
# Usage: ./scripts/pr.sh <branch-name> "<commit-message>" "<pr-title>" ["<pr-body>"]
#
# Required environment variable:
#   GITHUB_TOKEN  — Personal Access Token (repo scope)
#
# Example:
#   GITHUB_TOKEN=ghp_xxx ./scripts/pr.sh feature/update-concepts "update concepts.md" "concepts.md を最新化"

set -euo pipefail

BRANCH="${1:?branch name required}"
COMMIT_MSG="${2:?commit message required}"
PR_TITLE="${3:?PR title required}"
PR_BODY="${4:-}"

OWNER="tkeisuke318"
REPO="contexts-sample"
BASE="main"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "ERROR: GITHUB_TOKEN is not set."
  echo "  export GITHUB_TOKEN=ghp_your_token"
  exit 1
fi

# 1. ブランチ作成・切替
if git show-ref --quiet "refs/heads/${BRANCH}"; then
  echo "[1/5] Branch '${BRANCH}' already exists, switching..."
  git checkout "${BRANCH}"
else
  echo "[1/5] Creating branch '${BRANCH}'..."
  git checkout -b "${BRANCH}"
fi

# 2. ステージング
echo "[2/5] Staging all changes..."
git add -A

if git diff --cached --quiet; then
  echo "  No changes to commit."
  exit 0
fi

# 3. コミット
echo "[3/5] Committing..."
git commit -m "${COMMIT_MSG}"

# 4. プッシュ
echo "[4/5] Pushing to origin/${BRANCH}..."
git push -u origin "${BRANCH}"

# 5. プルリクエスト作成
echo "[5/5] Creating pull request..."

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${OWNER}/${REPO}/pulls" \
  -d "$(jq -n \
    --arg title "${PR_TITLE}" \
    --arg body "${PR_BODY}" \
    --arg head "${BRANCH}" \
    --arg base "${BASE}" \
    '{title: $title, body: $body, head: $head, base: $base}'
  )")

HTTP_STATUS=$(echo "${RESPONSE}" | tail -1)
BODY=$(echo "${RESPONSE}" | head -n -1)

if [[ "${HTTP_STATUS}" == "201" ]]; then
  PR_URL=$(echo "${BODY}" | jq -r '.html_url')
  echo ""
  echo "Pull request created:"
  echo "  ${PR_URL}"
else
  echo "ERROR: Failed to create PR (HTTP ${HTTP_STATUS})"
  echo "${BODY}" | jq '.message // .' 2>/dev/null || echo "${BODY}"
  exit 1
fi
