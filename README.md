# 概要

PowerShell によって Windows10 のアップデートを自動的に完了。

再起動が必要な場合も自動ログオンとタスクスケジューラ登録によって起動後も処理を継続可能です。

- Windows 10 1909 の自動インストール
- Windows Update を最新まで当てる
- 設定用ユーザプロファイルのクリーンアップ
- 設定用ファイルのクリーンアップ

<br>

# 事前準備

## 1909 フォルダに 1909 インストーラを配置

https://www.microsoft.com/ja-jp/software-download/windows10

でブラウザのユーザーエージェントを Safari などに変えればダウンロード可能。

7-Zip などで iso ファイルの中身を展開しておく。

<br>

## Config.json の設定

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

1. USB メモリに各種ファイルを配置
2. C ドライブ直下に AutoWinUpdate フォルダをコピー
3. 「Run-PS.bat」を管理者権限で実行
4. 放置
