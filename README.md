# 概要

PowerShell によって Windows10 のアップデートを自動的に完了。

再起動が必要な場合も自動ログオンとタスクスケジューラ登録によって起動後も処理を継続可能です。

- 更新アシスタントをダウンロードして最新までアップグレード
- Windows Update を最新まで当てる
- 不要になったファイルのクリーンアップ

<br>

# 事前準備

## Config.json の設定

upgradeWindows...メージャーバージョンアップを実行する場合は`true`

setupUser...自動ログインに用いるユーザアカウント情報

notifier...slack/chatwork/teams/hangout のいずれかと WebHookURL をセット※ChatWork のみ token も必要

```json
[
  {
    "upgradeWindows": true,
    "setupUser": {
      "name": "setup",
      "pass": "Setup1234"
    },
    "notifier": {
      "chat": "slack",
      "url": "https://hooks.slack.com/services/xxxx/xxxx/xxxx",
      "token": ""
    }
  }
]
```

<br>

# 実行手順

**USB メモリから実行する場合**

1. USB メモリなどに AutoWinUpdate フォルダを作成して各ファイルを配置
2. 実行対象端末の Cドライブ直下に AutoWinUpdate フォルダをコピー
3. 「Run-PS.bat」を管理者権限で実行
4. 完了通知が来るまで放置
