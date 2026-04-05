---
task_type: "新規開発"
phase: "設計"
kind: "rules"
---

# 設計フェーズ — 規約

## 規約

### 画面設計

- **画面IDの採番**：`SCR-[機能カテゴリ2文字]-[連番4桁]`（例：SCR-OR-0001）

### DB設計

- **テーブル名**：スネークケース・複数形（例：`orders`、`order_details`）
- **カラム名**：スネークケース（例：`created_at`、`customer_id`）
- **主キー**：全テーブルにサロゲートキー（自動採番）を設ける
- **論理削除**：`deleted_at` カラムで実装する（物理削除は定義しない）
- **共通カラム**：全テーブルに `created_at`・`updated_at`・`created_by`・`updated_by` を付与する
- **正規化**：第3正規形以上を原則とする

### クラス・API設計

- **レイヤー依存方向**：Controller → Service → Repository のみ許可（逆方向・横断禁止）
- **クラス命名**：パスカルケース＋役割サフィックス（例：`OrderService`、`OrderRepository`）
- **メソッド命名**：キャメルケース・動詞始まり（例：`createOrder`、`findById`）
- **APIパス**：リソース名は複数形スネークケース（例：`/api/orders`）
- **HTTPメソッド**：GET（参照）/ POST（新規作成）/ PUT（全更新）/ PATCH（部分更新）/ DELETE（削除）
- **エラーレスポンス形式**：全APIで `docs/02_設計/02_API/` 配下のAPI設計書に定義する共通形式を使用する
