---
name: apollo-cookie-expiry-30d
description: 「Apolloが開けない」の定番原因はmc_token Cookieの30日期限切れ。サーバーは正常でも401になる
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9c6ff86a-7b63-45a3-a4f8-bc318319e8cd
---

Keitaが「アポロ開けなくなった」と言った時の第一容疑は認証Cookie（mc_token、maxAge 30日、cxo-agent server/src/lib/auth.ts）の期限切れ。サーバー・トンネルが正常でもきれいなURL（Cookie無し）は401になる。

切り分け手順: (1) `curl localhost:4317/api/healthz`（認証免除）→200ならorigin正常 (2) `https://apollomansion.com/api/healthz` →200ならcloudflaredトンネル正常 (3) ルートが401なら認証問題。

復旧: `.mc.env` の MC_TOKEN で `https://apollomansion.com/?token=<MC_TOKEN>` を渡す（302でCookie再発行）。2026-08-04に実際に発生・この手順で解決。

恒久対策済み（2026-08-04・MC-368・commit f3a57c3）: パスワードログインを実装。401(HTML)でログインフォーム表示→POST /login が `.mc.env` の MC_PASSWORD（Keita指定）照合でCookie発行。Cookie寿命は400日＋アクセス毎スライド更新なので、たまにでも開いていれば実質失効しない。今後「開けない」場合はパスワード再入力だけで復旧するはず。それでもダメなら401以外（origin/トンネル障害）を疑う。

関連: [[project-apollo-dashboard]]
