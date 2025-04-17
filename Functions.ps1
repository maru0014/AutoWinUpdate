################################################
# 自動ログオン有効化
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
        Write-Host "$(Get-Date -Format g) ユーザー$($LogonUser)の自動ログオンを有効化"
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
# 自動ログオン無効化
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
# タスクの存在チェック
################################################
function Test-Task($TaskName) {
    <#
    .SYNOPSIS
    タスクの存在チェック

    .DESCRIPTION
    タスク名を受け取ってタスクスケジューラ内に存在するかチェック
    存在する場合は%true、存在しない場合は$falseを返します

    .EXAMPLE
    Test-Task "自動ログオン"

    .PARAMETER TaskName
    String型でタスクの名前を指定

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
# タスクスケジューラ登録
################################################
function Register-Task($TaskName, $exePath, $TaskExecuteUser, $TaskExecutePass, $visble) {
    if (-not (Test-Task $TaskName)) {
        Write-Host "$(Get-Date -Format g) タスクスケジューラに登録:$($TaskName)"
        $trigger = New-ScheduledTaskTrigger -AtLogon
        $action = New-ScheduledTaskAction -Execute $exePath
        $principal = New-ScheduledTaskPrincipal -UserID $TaskExecuteUser -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal
    }
}


################################################
# タスクスケジューラ削除
################################################
function Remove-Task($TaskName) {

    if ((Get-WmiObject Win32_OperatingSystem).version -eq "6.1.7601") {
        schtasks /delete /tn $TaskName
    }
    else {
        Get-ScheduledTask | Where-Object { $_.TaskName -match $TaskName } | Unregister-ScheduledTask -Confirm:$false
    }

    Write-Output "$(Get-Date -Format g) $($TaskName)をタスクスケジューラから削除"

}


################################################
# チャット送信
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
# レジストリを参照
################################################
function Get-Registry( $RegPath, $RegKey ) {
    # レジストリそのものの有無確認
    if ( -not (Test-Path $RegPath )) {
        Write-Host  "$RegPath not found."
        return $null
    }

    # Key有無確認
    $Result = Get-ItemProperty $RegPath -name $RegKey -ErrorAction SilentlyContinue

    # キーがあった時
    if ( $null -ne $Result ) {
        return $Result.$RegKey
    }
    # キーが無かった時
    else {
        return $null
    }
}
