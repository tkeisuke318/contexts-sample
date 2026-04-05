---
name: pr
description: >-
  git commit してプルリクを作りたい・PRを出したい・変更をGitHubに上げたい・ブランチを切ってコミットしたい、
  といった場面で使う。変更のステージング・コミット・プッシュ・GitHub PRの作成を順番に実行する。
  GITHUB_TOKENが未設定の場合は取得方法を案内する。
argument-hint: "[ブランチ名] [コミットメッセージ] [PRタイトル] [PR説明（省略可）]"
allowed-tools: Bash
---

コード修正からGitHub PRの作成までを、以下のステップで順番に実行してください。

## 引数の解釈

| 引数 | 対応 |
|------|------|
| `$0` | ブランチ名 |
| `$1` | コミットメッセージ |
| `$2` | PRタイトル |
| `$3` | PR説明（省略可、省略時は空文字） |

引数が不足している場合は、不足している項目をユーザーに確認してから進む。

---

## Step 1: 事前チェック

`GITHUB_TOKEN` が設定されているか確認する。

```bash
echo "${GITHUB_TOKEN:-NOT_SET}"
```

`NOT_SET` の場合は以下を案内して中断する。

```
GITHUB_TOKEN が設定されていません。

1. GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Repository: contexts-sample / Permissions: Contents (Read/Write), Pull requests (Read/Write)
3. 発行後、以下を実行してから /pr を再実行してください:
   export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxx
```

`jq` の存在も確認する。

```bash
jq --version 2>/dev/null || echo "NOT_FOUND"
```

`NOT_FOUND` の場合は `winget install jqlang.jq` を案内して中断する。

---

## Step 2: 変更の確認

現在の変更を表示してユーザーに内容を確認させる。

```bash
git status
```

```bash
git diff
```

変更がない場合（ `git status` がクリーンな場合）はその旨を伝えて終了する。

---

## Step 3: ブランチ作成・切替

```bash
git show-ref --quiet "refs/heads/$0" && git checkout "$0" || git checkout -b "$0"
```

現在どのブランチにいるかをユーザーに伝える。

---

## Step 4: ステージング

全変更をステージングする。

```bash
git add -A
```

ステージングされた内容を表示してユーザーに確認させる。

```bash
git diff --cached --stat
```

---

## Step 5: コミット

```bash
git commit -m "$1"
```

---

## Step 6: プッシュ

```bash
git push -u origin "$0"
```

---

## Step 7: プルリクエスト作成

GitHub API でPRを作成する。

```bash
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/tkeisuke318/contexts-sample/pulls" \
  -d "$(jq -n \
    --arg title "$2" \
    --arg body "${3:-}" \
    --arg head "$0" \
    --arg base "main" \
    '{title: $title, body: $body, head: $head, base: $base}'
  )")

HTTP_STATUS=$(echo "${RESPONSE}" | tail -1)
BODY=$(echo "${RESPONSE}" | head -n -1)

if [[ "${HTTP_STATUS}" == "201" ]]; then
  echo "PR created: $(echo "${BODY}" | jq -r '.html_url')"
else
  echo "ERROR: HTTP ${HTTP_STATUS}"
  echo "${BODY}" | jq '.message // .'
fi
```

---

## 完了後

各ステップの結果をまとめてユーザーに報告し、PRのURLを明示する。
