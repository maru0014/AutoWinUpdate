################################################
# �������O�I���L����
################################################
function Enable-AutoLogon($LogonUser, $LogonPass, $LogonDomain) {
    <#
    .SYNOPSIS
    Enable AutoLogon
    .DESCRIPTION

    #>
    $AutoAdminLogon = Get-Registry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "AutoAdminLogon"
    $DefaultUsername = Get-Registry "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "DefaultUsername"
    if (($AutoAdminLogon -ne 1) -Or ($DefaultUsername -ne $LogonUser)) {
        Write-Host "$(Get-Date -Format g) ���[�U�[$($LogonUser)�̎������O�I����L����"
        $RegLogonKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        Set-ItemProperty -path $RegLogonKey -name "AutoAdminLogon" -value 1
        Set-ItemProperty -path $RegLogonKey -name "DefaultUsername" -value $LogonUser
        Set-ItemProperty -path $RegLogonKey -name "DefaultPassword" -value $LogonPass
        if ($LogonDomain -ne "") {
            Set-ItemProperty -path $RegLogonKey -name "DefaultDomainName" -value $LogonDomain
        }
    }
}


################################################
# �������O�I��������
################################################
function Disable-AutoLogon() {
    <#
    .SYNOPSIS
    Disable AutoLogon
    .DESCRIPTION

    #>
    $RegLogonKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty -path $RegLogonKey -name "AutoAdminLogon" -value 0
    Set-ItemProperty -path $RegLogonKey -name "DefaultUsername" -value ""
    Set-ItemProperty -path $RegLogonKey -name "DefaultPassword" -value ""

}


################################################
# �^�X�N�̑��݃`�F�b�N
################################################
function Test-Task($TaskName) {
    <#
    .SYNOPSIS
    �^�X�N�̑��݃`�F�b�N

    .DESCRIPTION
    �^�X�N�����󂯎���ă^�X�N�X�P�W���[�����ɑ��݂��邩�`�F�b�N
    ���݂���ꍇ��%true�A���݂��Ȃ��ꍇ��$false��Ԃ��܂�

    .EXAMPLE
    Test-Task "�������O�I��"

    .PARAMETER TaskName
    String�^�Ń^�X�N�̖��O���w��

    #>

    $Task = $null
    if ((Get-WmiObject Win32_OperatingSystem).version -eq "6.1.7601") {
        $Task = schtasks /query /fo csv | ConvertFrom-Csv | Where-Object { $_."Taskname" -eq $TaskName }
    }
    else {
        $Task = Get-ScheduledTask | Where-Object { $_.TaskName -match $TaskName }
    }

    if ($Task) {
        return $true
    }
    else {
        return $false
    }

}


################################################
# �^�X�N�X�P�W���[���o�^
################################################
function Register-Task($TaskName, $exePath, $TaskExecuteUser, $TaskExecutePass, $visble) {
    if (-not (Test-Task $TaskName)) {
        Write-Host "$(Get-Date -Format g) �^�X�N�X�P�W���[���ɓo�^:$($TaskName)"
        $trigger = New-ScheduledTaskTrigger -AtLogon
        $action = New-ScheduledTaskAction -Execute $exePath
        $principal = New-ScheduledTaskPrincipal -UserID $TaskExecuteUser -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal
    }
}


################################################
# �^�X�N�X�P�W���[���폜
################################################
function Remove-Task($TaskName) {

    if ((Get-WmiObject Win32_OperatingSystem).version -eq "6.1.7601") {
        schtasks /delete /tn $TaskName
    }
    else {
        Get-ScheduledTask | Where-Object { $_.TaskName -match $TaskName } | Unregister-ScheduledTask -Confirm:$false
    }

    Write-Output "$(Get-Date -Format g) $($TaskName)���^�X�N�X�P�W���[������폜"

}


################################################
# �`���b�g���M
################################################
function Send-Chat($msg, $chat, $url, $token) {
    $enc = [System.Text.Encoding]::GetEncoding('ISO-8859-1')
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)

    if ($chat -eq "slack") {
        $notificationPayload = @{text = $enc.GetString($utf8Bytes) }
        Invoke-RestMethod -Uri $url -Method Post -Body (ConvertTo-Json $notificationPayload)
    }
    elseif ($chat -eq "chatwork") {
        $body = $enc.GetString($utf8Bytes)
        Invoke-RestMethod -Uri $url -Method POST -Headers @{"X-ChatWorkToken" = $token } -Body "body=$body"
    }
    elseif ($chat -eq "teams") {
        $body = ConvertTo-JSON @{text = $msg }
        $postBody = [Text.Encoding]::UTF8.GetBytes($body)
        Invoke-RestMethod -Uri $url -Method Post -ContentType 'application/json' -Body $postBody
    }
    elseif ($chat -eq "hangouts") {
        $notificationPayload = @{text = $msg }
        Invoke-RestMethod -Uri $url -Method Post -ContentType 'application/json; charset=UTF-8' -Body (ConvertTo-Json $notificationPayload)
    }
}


################################################
# ���W�X�g�����Q��
################################################
function Get-Registry( $RegPath, $RegKey ) {
    # ���W�X�g�����̂��̗̂L���m�F
    if ( -not (Test-Path $RegPath )) {
        Write-Host  "$RegPath not found."
        return $null
    }

    # Key�L���m�F
    $Result = Get-ItemProperty $RegPath -name $RegKey -ErrorAction SilentlyContinue

    # �L�[����������
    if ( $null -ne $Result ) {
        return $Result.$RegKey
    }
    # �L�[������������
    else {
        return $null
    }
}
