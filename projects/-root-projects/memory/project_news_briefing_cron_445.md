---
name: project-news-briefing-cron-445
description: ニュース配信cronを4:45開始に前倒し（6:00までに投稿完了させるため）
metadata: 
  node_type: memory
  type: project
  originSessionId: 853e6ab7-2aa9-4bac-bb78-860644ed3b48
---

2026-08-01 Keita「6時に生成するようにして。今日のやつでてないよ」→ 実態は cron 6:00 開始だが生成〜ファクトチェック〜投稿に通常45〜55分（空応答リトライ時〜70分）かかり、投稿は毎日6:45〜7:00頃だった。cron を `0 6` → `45 4` に変更し、6:00 までに Apollo チャット＋Vault へ投稿完了する体制にした。

**Why:** Keita の期待は「6時に出てる」＝投稿完了時刻ベース。開始時刻ではない。

**How to apply:** 配信系 cron の時刻要望は「開始時刻」でなく「届く時刻」で逆算する。関連: [[reference-news-briefing-morning-retry]]（朝の空応答バグ→リトライ）。revert は crontab の `45 4` を `0 6` に戻すだけ。
