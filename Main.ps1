# ログ出力開始
Start-Transcript "$PSScriptRoot/AutoWinUpdate.log" -append

Write-Host @"
*********************************************************
*
* Windows10 Auto Updating Script / Main.ps1
* バージョン : 1.20
* 最終更新日 : 2020/10/13
*
"@ -ForeGroundColor green

Write-Host "$(Get-Date -Format g) 実行中のユーザ : " $env:USERNAME

# 設定ファイルの読み込み
Write-Host "$(Get-Date -Format g) 設定ファイル読み込み : $($PSScriptRoot)/Config.json"
$config = Get-Content "$PSScriptRoot/Config.json" -Encoding UTF8 | ConvertFrom-Json

# 関数の読み込み
Write-Host "$(Get-Date -Format g) 関数ファイル読み込み : $($PSScriptRoot)/Functions.ps1"
. $PSScriptRoot/Functions.ps1

# 自動ログオン設定
Enable-AutoLogon $config.setupuser.name $config.setupuser.pass

# スケジューラにログオンスクリプト登録
Register-Task "AutoWinUpdate" "$PSScriptRoot\Run-PS.bat" $config.setupuser.name $config.setupuser.pass

if ($config.upgradeWindows) {
  $dir = 'C:\AutoWinUpdate\_Windows_FU\packages'
  if (-not (Test-Path $dir)) {
    # 作業用フォルダ作成
    mkdir $dir

    # Window10更新アシスタントをダウンロード
    $webClient = New-Object System.Net.WebClient
    $url = 'https://go.microsoft.com/fwlink/?LinkID=799445'
    $file = "$($dir)\Win10Upgrade.exe"
    $webClient.DownloadFile($url,$file)

    # サイレントインストール
    Start-Process -FilePath $file -ArgumentList '/skipeula /auto upgrade /UninstallUponUpgrade' -Wait
    Exit
  }
}

Write-Host "`r`n***************** 最新までWindows Update *****************" -ForeGroundColor green
Install-Module -Name PSWindowsUpdate -Force
Import-Module -Name PSWindowsUpdate
Install-WindowsUpdate -AcceptAll -AutoReboot

# Run-LegacyWindowsUpdate "Full"
# Run-WindowsUpdate


# Taskを削除
if (Test-Task "AutoWinUpdate") {
  Remove-Task "AutoWinUpdate"
  Write-Host "$(Get-Date -Format g) ログオンスクリプトを解除"
}

# 自動ログオン無効化
Disable-AutoLogon

# AutoWinUpdate.log 以外の AutoWinUpdateフォルダ配下を削除
Remove-Item C:\AutoWinUpdate\* -Exclude AutoWinUpdate.log -Recurse
Write-Host "$(Get-Date -Format g) C:\AutoWinUpdate\フォルダを削除"

$compliteMsg = @"
[$($env:COMPUTERNAME)] Windows Update 完了
詳細ログは対象PCの C:\AutoWinUpdate\AutoWinUpdate.log をご確認ください
"@

# キッティング完了をチャットに通知
Send-Chat $compliteMsg $config.notifier.chat $config.notifier.url $config.notifier.token

# ログ出力終了
Stop-Transcript
Send-Chat $compliteMsg $config.notifier.chat $config.notifier.url $config.notifier.token

# ログ出力終了
Stop-Transcript
