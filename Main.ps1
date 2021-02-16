# ���O�o�͊J�n
Start-Transcript "$PSScriptRoot/AutoWinUpdate.log" -append

Write-Host @"
*********************************************************
*
* Windows10 Auto Updating Script / Main.ps1
* �o�[�W���� : 1.21
* �ŏI�X�V�� : 2021/02/16
*
"@ -ForeGroundColor green

Write-Host "$(Get-Date -Format g) ���s���̃��[�U : " $env:USERNAME

# �ݒ�t�@�C���̓ǂݍ���
Write-Host "$(Get-Date -Format g) �ݒ�t�@�C���ǂݍ��� : $($PSScriptRoot)/Config.json"
$config = Get-Content "$PSScriptRoot/Config.json" -Encoding UTF8 | ConvertFrom-Json

# �֐��̓ǂݍ���
Write-Host "$(Get-Date -Format g) �֐��t�@�C���ǂݍ��� : $($PSScriptRoot)/Functions.ps1"
. $PSScriptRoot/Functions.ps1

# �������O�I���ݒ�
Enable-AutoLogon $config.setupuser.name $config.setupuser.pass

# �X�P�W���[���Ƀ��O�I���X�N���v�g�o�^
Register-Task "AutoWinUpdate" "$PSScriptRoot\Run-PS.bat" $config.setupuser.name $config.setupuser.pass

if ($config.upgradeWindows.flag) {
  $winver = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId
  if ($config.upgradeWindows.ver -gt $winver) {
    Write-Host "`r`n***************** Windows 10 �X�V�A�V�X�^���g���s *****************" -ForeGroundColor green
    $dir = 'C:\AutoWinUpdate\_Windows_FU\packages'
    if (-not (Test-Path $dir)) {
      # ��Ɨp�t�H���_�쐬
      mkdir $dir

      # Window10�X�V�A�V�X�^���g���_�E�����[�h
      $webClient = New-Object System.Net.WebClient
      $url = 'https://go.microsoft.com/fwlink/?LinkID=799445'
      $file = "$($dir)\Win10Upgrade.exe"
      $webClient.DownloadFile($url, $file)

      # �T�C�����g�C���X�g�[��
      Start-Process -FilePath $file -ArgumentList '/skipeula /auto upgrade /UninstallUponUpgrade' -Wait
      Exit
    }
  }
}

Write-Host "`r`n***************** �ŐV�܂�Windows Update *****************" -ForeGroundColor green
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
  # PSWindowsUpdate���W���[�����Ȃ���΃C���X�g�[��
  Install-PackageProvider -Name NuGet -Force
  Install-Module -Name PSWindowsUpdate -Force
}

# PSWindowsUpdate�����s
Import-Module -Name PSWindowsUpdate
Install-WindowsUpdate -AcceptAll -IgnoreRestart

# �ċN�����K�v���m�F
if (Get-WURebootStatus -Silent) {
  Write-Host "$(Get-Date -Format g) �ċN�����K�v�ȍX�V�v���O���������邽�ߍċN�����܂��B"
  Restart-Computer -Force
  Exit
}

# Task���폜
if (Test-Task "AutoWinUpdate") {
  Remove-Task "AutoWinUpdate"
  Write-Host "$(Get-Date -Format g) ���O�I���X�N���v�g������"
}

# �������O�I��������
Disable-AutoLogon

# AutoWinUpdate.log �ȊO�� AutoWinUpdate�t�H���_�z�����폜
Remove-Item C:\AutoWinUpdate\* -Exclude AutoWinUpdate.log -Recurse
Write-Host "$(Get-Date -Format g) C:\AutoWinUpdate\�t�H���_���폜"

$compliteMsg = @"
[$($env:COMPUTERNAME)] Windows Update ����
�ڍ׃��O�͑Ώ�PC�� C:\AutoWinUpdate\AutoWinUpdate.log �����m�F��������
"@

# �L�b�e�B���O�������`���b�g�ɒʒm
Send-Chat $compliteMsg $config.notifier.chat $config.notifier.url $config.notifier.token

# ���O�o�͏I��
Stop-Transcript
Send-Chat $compliteMsg $config.notifier.chat $config.notifier.url $config.notifier.token
