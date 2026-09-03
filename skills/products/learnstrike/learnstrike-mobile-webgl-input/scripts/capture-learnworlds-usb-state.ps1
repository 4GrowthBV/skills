[CmdletBinding()]
param(
    [string]$AndroidSerial,
    [string]$AndroidPackage,
    [int]$IosDeviceListPort = 9401,
    [int]$IosPagesPort = 0,
    [switch]$IncludeDeviceIdentifiers,
    [switch]$IncludePageMetadata,
    [switch]$IncludeMemory
)

$ErrorActionPreference = 'Stop'

function Get-FirstRegexGroup {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Group = 'value'
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    $match = [regex]::Match($Text, $Pattern)
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups[$Group].Value.Trim()
}

function Invoke-LearnWorldsAdbText {
    param(
        [string[]]$CommandArguments,
        [switch]$WithoutDevice,
        [switch]$AllowNonZero
    )

    $arguments = @()
    if (-not $WithoutDevice.IsPresent) {
        if ([string]::IsNullOrWhiteSpace($script:LearnWorldsAndroidSerial)) {
            throw 'No Android device was selected for the adb probe.'
        }

        $arguments += @('-s', $script:LearnWorldsAndroidSerial)
    }

    $arguments += $CommandArguments
    $result = @(& $script:LearnWorldsAdbPath @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $text = (($result | Out-String).Trim())

    if ($exitCode -ne 0) {
        if ($AllowNonZero.IsPresent) {
            return $null
        }

        $safeCommand = 'adb ' + ($CommandArguments -join ' ')
        throw ('{0} failed with exit code {1}. Native output was suppressed because it may contain device identifiers.' -f $safeCommand, $exitCode)
    }

    return $text
}

function Get-LearnWorldsMemorySnapshot {
    param([string]$Target)

    if ([string]::IsNullOrWhiteSpace($Target)) {
        return $null
    }

    try {
        $memoryText = Invoke-LearnWorldsAdbText -CommandArguments @('shell', 'dumpsys', 'meminfo', $Target)
        $totalPssKb = Get-FirstRegexGroup -Text $memoryText -Pattern 'TOTAL PSS:\s*(?<value>\d+)'
        $totalRssKb = Get-FirstRegexGroup -Text $memoryText -Pattern 'TOTAL RSS:\s*(?<value>\d+)'

        return [pscustomobject]@{
            Target = $Target
            TotalPssKb = if ($totalPssKb) { [long]$totalPssKb } else { $null }
            TotalRssKb = if ($totalRssKb) { [long]$totalRssKb } else { $null }
        }
    }
    catch {
        return [pscustomobject]@{
            Target = $Target
            Error = $_.Exception.Message
        }
    }
}

$android = [ordered]@{
    AdbAvailable = $false
    Status = 'adb not found'
}

$adbCommand = Get-Command adb -ErrorAction SilentlyContinue
if ($null -ne $adbCommand) {
    $android.AdbAvailable = $true
    $script:LearnWorldsAdbPath = $adbCommand.Source

    try {
        $rawDeviceText = Invoke-LearnWorldsAdbText -WithoutDevice -CommandArguments @('devices', '-l')
        $rawDeviceLines = @($rawDeviceText -split '\r?\n')
        $deviceIndex = 0
        $deviceRows = @(
            foreach ($line in $rawDeviceLines) {
                if ($line -match '^(?<serial>\S+)\s+(?<state>device|offline|unauthorized)(?:\s+(?<details>.*))?$') {
                    $deviceIndex += 1
                    [pscustomobject]@{
                        Index = $deviceIndex
                        Serial = $Matches.serial
                        State = $Matches.state
                        Details = $Matches.details
                        Model = Get-FirstRegexGroup -Text $Matches.details -Pattern '(?:^|\s)model:(?<value>\S+)'
                    }
                }
            }
        )

        if ($IncludeDeviceIdentifiers.IsPresent) {
            $android.Devices = @($deviceRows | Select-Object Index, Serial, State, Details)
        }
        else {
            $android.Devices = @($deviceRows | Select-Object Index, State, Model)
        }

        $connectedDevices = @($deviceRows | Where-Object State -eq 'device')
        $selectedDevice = $null

        if (-not [string]::IsNullOrWhiteSpace($AndroidSerial)) {
            $selectedDevice = $connectedDevices | Where-Object Serial -eq $AndroidSerial | Select-Object -First 1
            if ($null -eq $selectedDevice) {
                if ($IncludeDeviceIdentifiers.IsPresent) {
                    $android.Status = "requested Android serial is not connected: $AndroidSerial"
                }
                else {
                    $android.Status = 'requested Android device is not connected; pass -IncludeDeviceIdentifiers for identifier-level diagnostics'
                }
            }
        }
        elseif ($connectedDevices.Count -eq 1) {
            $selectedDevice = $connectedDevices[0]
        }
        elseif ($connectedDevices.Count -eq 0) {
            $android.Status = 'no connected Android device'
        }
        else {
            $android.Status = 'multiple Android devices connected; pass -AndroidSerial'
        }

        if ($null -ne $selectedDevice) {
            $script:LearnWorldsAndroidSerial = $selectedDevice.Serial
            $android.SelectedDeviceIndex = $selectedDevice.Index
            if ($IncludeDeviceIdentifiers.IsPresent) {
                $android.SelectedSerial = $selectedDevice.Serial
            }

            try {
                $hasAndroidPackage = -not [string]::IsNullOrWhiteSpace($AndroidPackage)
                $manufacturer = Invoke-LearnWorldsAdbText -CommandArguments @('shell', 'getprop', 'ro.product.manufacturer')
                $model = Invoke-LearnWorldsAdbText -CommandArguments @('shell', 'getprop', 'ro.product.model')
                $osVersion = Invoke-LearnWorldsAdbText -CommandArguments @('shell', 'getprop', 'ro.build.version.release')
                $sdk = Invoke-LearnWorldsAdbText -CommandArguments @('shell', 'getprop', 'ro.build.version.sdk')
                $activityText = Invoke-LearnWorldsAdbText -CommandArguments @('shell', 'dumpsys', 'activity', 'activities')
                $webViewText = Invoke-LearnWorldsAdbText -CommandArguments @('shell', 'dumpsys', 'webviewupdate')
                $inputMethodText = Invoke-LearnWorldsAdbText -CommandArguments @('shell', 'dumpsys', 'input_method')
                $socketText = Invoke-LearnWorldsAdbText -CommandArguments @('shell', 'cat', '/proc/net/unix')

                $foreground = Get-FirstRegexGroup -Text $activityText -Pattern '(?:mResumedActivity|topResumedActivity)[^\r\n]*?\s(?<value>[A-Za-z0-9._]+/[A-Za-z0-9._$]+)\s'
                $foregroundPackage = Get-FirstRegexGroup -Text $foreground -Pattern '^(?<value>[^/]+)'
                $webViewPackage = Get-FirstRegexGroup -Text $webViewText -Pattern 'Current WebView package \(name, version\): \((?<value>[^,]+),'
                $webViewVersion = Get-FirstRegexGroup -Text $webViewText -Pattern 'Current WebView package \(name, version\): \([^,]+,\s*(?<value>[^)]+)\)'
                $servedViewClass = Get-FirstRegexGroup -Text $inputMethodText -Pattern '(?m)^\s*mServedView=(?<value>[^{\r\n]+)'
                $isInputViewShown = Get-FirstRegexGroup -Text $inputMethodText -Pattern '\bmIsInputViewShown=(?<value>true|false)'
                $inputShown = Get-FirstRegexGroup -Text $inputMethodText -Pattern '\bmInputShown=(?<value>true|false)'
                $softInputAdjustment = Get-FirstRegexGroup -Text $activityText -Pattern '\b(?<value>ADJUST_(?:NOTHING|PAN|RESIZE|UNSPECIFIED))\b'

                $devToolsSockets = @(
                    [regex]::Matches($socketText, '(?m)@?(?<name>(?:webview|chrome)_devtools_remote[^\s]*)') |
                        ForEach-Object { $_.Groups['name'].Value } |
                        Sort-Object -Unique
                )

                $versionName = $null
                $versionCode = $null
                $mainPid = $null
                $appOwnerUid = $null
                $rendererRows = @()

                if ($hasAndroidPackage) {
                    $packageText = Invoke-LearnWorldsAdbText -CommandArguments @('shell', 'dumpsys', 'package', $AndroidPackage)
                    $processText = Invoke-LearnWorldsAdbText -CommandArguments @('shell', 'dumpsys', 'activity', 'processes')
                    $mainPid = Invoke-LearnWorldsAdbText -AllowNonZero -CommandArguments @('shell', 'pidof', '-s', $AndroidPackage)
                    $versionName = Get-FirstRegexGroup -Text $packageText -Pattern '(?m)^\s*versionName=(?<value>[^\r\n]+)'
                    $versionCode = Get-FirstRegexGroup -Text $packageText -Pattern '(?m)^\s*versionCode=(?<value>\d+)'
                    $appOwnerUid = Get-FirstRegexGroup -Text $processText -Pattern (
                        '(?m)ProcessRecord\{[^\r\n]*?\s\d+:' +
                        [regex]::Escape($AndroidPackage) +
                        '/u0a(?<value>\d+)\}'
                    )

                    $rendererMatches = [regex]::Matches(
                        $processText,
                        '(?m)ProcessRecord\{[^\r\n]*?\s(?<pid>\d+):(?<name>[^\s/]*sandboxed_process[^\s/]*)/u0a(?<owner>\d+)i-?\d+[^\r\n]*'
                    )

                    foreach ($rendererMatch in $rendererMatches) {
                        $rendererOwnerUid = $rendererMatch.Groups['owner'].Value
                        if ($appOwnerUid -and $rendererOwnerUid -eq $appOwnerUid) {
                            $rendererRows += [pscustomobject]@{
                                Pid = [int]$rendererMatch.Groups['pid'].Value
                                ProcessName = $rendererMatch.Groups['name'].Value
                                Attribution = "isolated WebView UID maps to requested app UID u0a$appOwnerUid"
                            }
                        }
                    }
                }

                $rendererRows = @($rendererRows | Sort-Object Pid -Unique)

                $android.Status = 'connected'
                $android.Manufacturer = $manufacturer
                $android.Model = $model
                $android.OsVersion = $osVersion
                $android.Sdk = $sdk
                $android.CurrentWebViewPackage = $webViewPackage
                $android.CurrentWebViewVersion = $webViewVersion
                $android.InputMethod = [pscustomobject]@{
                    ServedViewClass = $servedViewClass
                    IsInputViewShown = if ($isInputViewShown) { [bool]::Parse($isInputViewShown) } else { $null }
                    InputShown = if ($inputShown) { [bool]::Parse($inputShown) } else { $null }
                    SoftInputAdjustment = $softInputAdjustment
                    Interpretation = 'Use the served view, visibility flags, focused UI, and visible device state together.'
                }
                $android.DevToolsSockets = $devToolsSockets
                if ($IncludeMemory.IsPresent) {
                    if ($hasAndroidPackage) {
                        $android.MemoryCollection = 'included by -IncludeMemory'
                        $android.AppMemory = Get-LearnWorldsMemorySnapshot -Target $AndroidPackage
                        foreach ($rendererRow in $rendererRows) {
                            $rendererRow | Add-Member -NotePropertyName Memory -NotePropertyValue (
                                Get-LearnWorldsMemorySnapshot -Target ([string]$rendererRow.Pid)
                            )
                        }
                    }
                    else {
                        $android.MemoryCollection = 'skipped; pass -AndroidPackage with -IncludeMemory'
                    }
                }
                else {
                    $android.MemoryCollection = 'skipped; pass -IncludeMemory for a deliberate measured run'
                }

                if ($hasAndroidPackage) {
                    $android.PackageProbe = 'included by -AndroidPackage'
                    $android.Package = $AndroidPackage
                    $android.ForegroundMatchesRequestedPackage = if ($foregroundPackage) {
                        $foregroundPackage -eq $AndroidPackage
                    }
                    else {
                        $null
                    }
                    $android.VersionName = $versionName
                    $android.VersionCode = if ($versionCode) { [long]$versionCode } else { $null }
                    $android.MainProcessPid = if ($mainPid -match '^\d+$') { [int]$mainPid } else { $null }
                    $android.HostAppUid = if ($appOwnerUid) { "u0a$appOwnerUid" } else { $null }
                    $android.AssociatedRendererProcesses = $rendererRows
                }
                else {
                    $android.PackageProbe = 'skipped; pass -AndroidPackage for app-specific evidence'
                }
            }
            catch {
                $android.Status = 'probe failed'
                $android.Error = $_.Exception.Message
            }
        }
    }
    catch {
        $android.Status = 'adb query failed'
        $android.Error = $_.Exception.Message
    }
}

$ios = [ordered]@{
    DeviceListPort = $IosDeviceListPort
    DeviceEndpoint = "http://127.0.0.1:$IosDeviceListPort/json"
    Status = 'proxy unavailable'
}

$adbForwardedLocalPorts = @()
if ($null -ne $adbCommand) {
    try {
        $forwardText = Invoke-LearnWorldsAdbText -WithoutDevice -CommandArguments @('forward', '--list')
        $adbForwardedLocalPorts = @(
            [regex]::Matches($forwardText, '(?m)\btcp:(?<port>\d+)\b') |
                ForEach-Object { [int]$_.Groups['port'].Value } |
                Sort-Object -Unique
        )
        $ios.AdbForwardCheck = 'completed'
    }
    catch {
        $ios.AdbForwardCheck = 'unavailable; endpoint fingerprinting will still be attempted'
    }
}

try {
    $iosDeviceResponse = Invoke-RestMethod -Uri $ios.DeviceEndpoint -TimeoutSec 3
    $iosDevices = @(
        @($iosDeviceResponse) | Where-Object {
            $null -ne $_.PSObject.Properties['deviceId'] -and
            $null -ne $_.PSObject.Properties['url']
        }
    )

    if ($iosDevices.Count -eq 0) {
        throw 'The endpoint responded, but it was not an ios_webkit_debug_proxy device list.'
    }

    $ios.Status = 'device endpoint reachable'
    $ios.DeviceCount = $iosDevices.Count
    $ios.Devices = @(
        for ($index = 0; $index -lt $iosDevices.Count; $index += 1) {
            $iosDevice = $iosDevices[$index]
            $summary = [ordered]@{
                Index = $index + 1
                OsVersion = $iosDevice.deviceOSVersion
            }
            if ($IncludeDeviceIdentifiers.IsPresent) {
                $summary.DeviceId = $iosDevice.deviceId
                $summary.Name = $iosDevice.deviceName
            }
            [pscustomobject]$summary
        }
    )

    $resolvedPagesPort = $IosPagesPort
    if ($resolvedPagesPort -le 0 -and $iosDevices.Count -gt 0) {
        $advertisedUrl = [string]$iosDevices[0].url
        $advertisedPort = Get-FirstRegexGroup -Text $advertisedUrl -Pattern ':(?<value>\d+)(?:/json)?/?$'
        if ($advertisedPort) {
            $resolvedPagesPort = [int]$advertisedPort
        }
    }

    if ($resolvedPagesPort -gt 0) {
        $ios.PagesPort = $resolvedPagesPort
        $ios.PagesEndpoint = "http://127.0.0.1:$resolvedPagesPort/json"

        $ownershipError = $null
        if ($adbForwardedLocalPorts -contains $resolvedPagesPort) {
            $ownershipError = "Port $resolvedPagesPort is owned by an adb forward, so it cannot be trusted as the iOS pages endpoint. Use a separate iOS proxy port range."
        }

        if ($null -eq $ownershipError) {
            try {
                $versionResponse = Invoke-RestMethod -Uri "http://127.0.0.1:$resolvedPagesPort/json/version" -TimeoutSec 3
                $androidPackageProperty = $versionResponse.PSObject.Properties['Android-Package']
                if ($null -ne $androidPackageProperty -and -not [string]::IsNullOrWhiteSpace([string]$androidPackageProperty.Value)) {
                    $ownershipError = "Port $resolvedPagesPort identifies itself as an Android DevTools endpoint, not an iOS page endpoint. Use a separate iOS proxy port range."
                }
            }
            catch {
                # ios_webkit_debug_proxy versions do not consistently expose /json/version.
            }
        }

        if ($null -ne $ownershipError) {
            $ios.PagesEndpointOwnership = 'rejected'
            $ios.PageError = $ownershipError
        }
        else {
            $ios.PagesEndpointOwnership = 'validated against known Android ownership signals'
            try {
                $iosPageResponse = Invoke-RestMethod -Uri $ios.PagesEndpoint -TimeoutSec 3
                $iosPages = @($iosPageResponse)
                $ios.InspectablePageCount = $iosPages.Count
                $ios.PageMetadataSuppressed = -not $IncludePageMetadata.IsPresent
                $ios.TargetIdentities = @(
                    for ($index = 0; $index -lt $iosPages.Count; $index += 1) {
                        $iosPage = $iosPages[$index]
                        [pscustomobject]@{
                            Index = $index + 1
                            AppId = if ($null -ne $iosPage.PSObject.Properties['appId']) { [string]$iosPage.appId } else { $null }
                            Type = $iosPage.type
                        }
                    }
                )

                if ($IncludePageMetadata.IsPresent) {
                    $ios.PageMetadata = @(
                        foreach ($iosPage in $iosPages) {
                            [pscustomobject]@{
                                Id = $iosPage.id
                                AppId = $iosPage.appId
                                Type = $iosPage.type
                                Title = $iosPage.title
                                Url = $iosPage.url
                            }
                        }
                    )
                }
            }
            catch {
                $ios.PageError = $_.Exception.Message
            }
        }
    }
    else {
        $ios.PageError = 'No page port was supplied or advertised by the device endpoint.'
    }
}
catch {
    $ios.Error = $_.Exception.Message
}

[pscustomobject]@{
    CapturedAtUtc = [DateTime]::UtcNow.ToString('o')
    Android = [pscustomobject]$android
    Ios = [pscustomobject]$ios
} | ConvertTo-Json -Depth 9
