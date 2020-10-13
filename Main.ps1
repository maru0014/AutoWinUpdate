# ���O�o�͊J�n
Start-Transcript "$PSScriptRoot/AutoWinUpdate.log" -append

Write-Host @"
*********************************************************
*
* Windows10 Auto Updating Script / Main.ps1
* �o�[�W���� : 1.20
* �ŏI�X�V�� : 2020/10/13
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

if ($config.upgradeWindows) {
  $winver = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId
  if (1909 -gt $winver) {
    # 1909�����̃o�[�W�����̏ꍇ1909���C���X�g�[��
    Write-Host "$(Get-Date -Format g) Windows10 $($winver) �� 1909�A�b�v�O���[�h���s"
    Start-Process -FilePath ($PSScriptRoot + "/1909/setup.exe") -argumentList "/Auto Upgrade" -Wait
  }
}

Write-Host "`r`n***************** �ŐV�܂�Windows Update *****************" -ForeGroundColor green
Install-Module -Name PSWindowsUpdate -Force
Import-Module -Name PSWindowsUpdate
Install-WindowsUpdate -AcceptAll -AutoReboot

# Run-LegacyWindowsUpdate "Full"
# Run-WindowsUpdate


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

# ���O�o�͏I��
Stop-Transcript
