#Requires -Version 5.1

<#
.SYNOPSIS
    
   Get / Set BBOX informations.
    
.DESCRIPTION
    
   GET/PUT/POST/DELETE/OPTION BBOX informations by Web request from ChromeDriver.
   Collect, Modify, Remove, BBOX information using Bytel API Web request, with PowerShell script.
    
.INPUTS
    
    .\BBOX-Aministration.ps1
    .\BBOX-Module.psm1
    .\SecuredPassword.txt
    .\Settings-Default-User.json
    .\Settings-Current-User.json
    .\Settings-Program.json
    Web url bbox content
    BBOX Rest API
    Hand User actions
    
.OUTPUTS
    
    Export-HTMLReport   -DataReported $FormatedData -ReportTitle "BBOX Configuration Report - $APIName" -ReportType $ReportType -ReportPath $ReportPath -ReportFileName $Exportfile -HTMLTitle "BBOX Configuration Report" -ReportPrecontent $APIName -Description $Description
    Out-GridviewDisplay -FormatedData $FormatedData -APIName $APIName -Description $Description
    Export-toCSV        -FormatedData $FormatedData -APIName $APIName -ExportCSVPath $ExportCSVPath -Exportfile $Exportfile
    Export-toJSON       -FormatedData $FormatedData -APIName $APIName -JsonBboxconfigPath $ExportJSONPath -Exportfile $Exportfile
    
.NOTES
    
    Creation Date : 2020/04/30
    Author : Zardrilokis => Tom78_91_45@yahoo.fr
    
    Version 1.0
    Updated Date : 2022/05/15
    Updated By   : Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Powershell script creation
    Update       : Add module : ".\BBOX-Module.psm1"
    Update       : Add checks / controls
    Update       : Add WIRELESS Frequency Neighborhood Scan before export result
    Update       : Add DHCP IPV6 and Firewall IPV6 functions
    Update       : Modify DHCP Client export (add new property dhcp.clients.ip6address)
    Update       : Force correct Network connexion
    Update       : Modify opened remote port checks
    Update       : Add HTML Report
    Update       : Correct syntaxe in Main Script and Functions
    Update       : Change logs folder
    Update       : Add Try/catch on function : Export-toCSV
    Update       : Add new function : Get-VoiceCallType used by Get-VOIPCalllogLineX and Get-VOIPFullcalllogLineX
    Update       : Modify HTML report for Get-VOIPCalllogLineX and Get-VOIPFullcalllogLineX
    Update       : Add Chrome Driver version in function chrome version installed on the device
    Update       : Add Test-FolderPath et Test-FilePath functions
    Update       : Add Get-UsbRight function
    Update       : Correct missing settings and syntaxe for HTML report
    Update       : Add function Get-ParentalControlScheduler
    Update       : Add missing IPV6 part on all page.
    Update       : Add missing elements in all functions
    Update       : Correct information put in logs files
    Update       : Reorganize BBOX-Module.psm1 to more clarify
    Update       : Hide ChromeDriver Service console and Chrome driver Application
    Update       : Add requirements
    Update       : Adjust remote connection port
    Update       : Force to create Logs Folder
    Update       : Solved problem in function : "Get-ConnexionType" when relaunch the script keep the old user selection
    Update       : Solved display title for HTML report and CSV file
    Update       : Add new Log type for device logs
    Update       : Correct functions to collect log informations
    Update       : Add new features available since version 19.2.12
    Update       : Correct properties in function "Get-Airties"
    Update       : Add new function : "Get-Nat" - Get Nat Configuration Information
    Update       : Correct wifi scan when use remote BBOX connexion, function "Start-RefreshWIRELESSFrequencyNeighborhoodScan"
    Update       : Correct Active Host session by host, function "Get-WANDAASH"
    Update       : Modify Display date format for HTML report
    Update       : Add new function : "Get-HOSTSPAUTH" => Get HOSTS PAUTH Information
    Update       : Add new function : "Format-Date" => To format the custom date to the standard one / Replace in functions in ".\BBOX-Module.psm1"
    Update       : Add new function : "Remove-FolderContent" => To remove export folder content Add in BBOX-Module.psm1
    Update       : Add new requests in file : ".\Ressources\API-Summary.csv" => Remove-FCLogs / Remove-FCExportCSV / Remove-FCExportJSON / Remove-FCJournal / Remove-FCJBC / Remove-FCReport
    Update       : Add 3 last Chrome Drivers versions : 93.0.4577.15 / 92.0.4515.43 / 91.0.4472.101
    Update       : Modify function : "Get-DeviceToken" in ".\BBOX-Module.psm1"
    Update       : Add new properties in existing functions
    
    Version 2.0
    Updated Date : 2022/01/13
    Updated By   : Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Add 2 new functions : "Switch-DisplayFormat" and "Switch-ExportFormat" in ".\BBOX-Module.psm1"
    Update       : Add new requests in file : ".\Ressources\API-Summary.csv" => Switch-DisplayFormat / Switch-ExportFormat
    Update       : Add new function : "EmptyFormatedDATA" in ".\BBOX-Module.psm1"
    Update       : Add new logs informations
    Update       : Correct Syntaxt
    Update       : Correct Program Sequence order
    Update       : Add new functions : "Format-DisplayResult" and "Format-ExportResult"
    Update       : Add Varible : "$logFileName" and "$FormatedDataExclusion"
    Update       : Rename variable : "$Info" and function property "-Info" to "$Label" and "Label" in ".\BBOX-Module.psm1" and ".\BBOX-Administration.ps1"
    Update       : Rename variable : "$Pages" and function property "-Pages" to "$APIsName" and "APIsName" in ".\BBOX-Administration.ps1"
    Update       : Rename variable : "$Page" and function property "-Page" to "$APIName" and "APIName"
    Update       : Add new function : "Stop-Program" in ".\BBOX-Module.psm1"
    Update       : Update logs file content
    Update       : Add Chrome Driver Log Path in Chrome Driver Option in function : "Start-ChromeDriver"
    Update       : Add Transcript logs file
    Update       : Change Google Chrome installation path detection
    Update       : Correct bug with HTML Report in function "GET-DYNDNSPL" (Missing first line to display)
    Update       : Disable All Extentions at chrome Driver startup in function : "Start-ChromeDriver"
    Update       : Change common footer in HTML Report
    Update       : Modify Header title from "Record" to "Record Type" in function : "Get-DYNDNSClient"
    Update       : Correct bug in function "Get-DYNDNS" (No data get after request)
    Update       : Modify remember check remote bbox connection only if remote instead of both.
    Update       : Modify comments if bbox dns not responding when program analyse your network connection.
    Update       : Modify comment when program quit (System / User)
    Update       : Change function's name from "Get-WPS" to "Get-WIRELESSWPS"
    Update       : Correct bug in function : "Get-WIRELESSWPS" (Missing data to collect)
    Update       : Add date in file name export/report
    Update       : Add dynamic folder path in function : "Export-BboxConfiguration" => modify also function : "Switch-Info"
    Update       : Correct Log file Name display when program closing
    Update       : Modify functions : "Test-FilePath" and "Test-FolderPath"
    Update       : Change "Get-BBoxJournal" function logic
    Update       : Add new function : "Get-CPLDeviceList" in module : ".\BBOX-Module.psm1"
    Update       : Modify function : "Get-CPL"
    Update       : Modify function : "Get-BackupList"
    Update       : Update function "Get-DeviceToken" with the date time format was changed
    Update       : Add new function : "Get-AirtiesLANmode" and update function : "Switch-Info"
    Update       : Modify logs and correct displayed comments
    Update       : Correct wrong parameters ".isDefault24" and ".isDefault5" in function : "Get-WIRELESS"
    Update       : Correct function : "Start-RefreshWIRELESSFrequencyNeighborhoodScan" to adapt for version : 20.6.8
    Update       : Update logs files
    Update       : New function : "Format-Date1970" for specific format date
    Update       : Correct logs in function : "Stop-Program"
    Update       : Update function : "Get-CPLDeviceList" to get all CPL device instead of one only
    Update       : Add new comments to best understanding how script run
    Update       : Correct if there is no data to display/export in all function linked to the API needed to be modified
    Update       : Correct function : "Get-HOSTSPAUTH"
    Update       : Update function : "Get-BBoxJournal" change download files method
    Update       : Correct function : "Stop-ChromeDriver" when chrome driver not yet started
    Update       : Correct the log name in function : "Stop-Program"
    
    Version 2.1 - BBOX version 20.8.6
    Updated Date : 2022/02/16
    Updated By   : Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Update logs files / Correct missing information in functions from BBOX-Module.psm1
    Update       : Correct Switch $APIName for "Default" way
    Update       : Correct Grammatical Syntaxe
    Update       : Change order code in function : "Start-RefreshWIRELESSFrequencyNeighborhoodScan"
    Update       : Simplify paramerters in functions : "Export-BBoxConfiguration", "Export-BBoxConfigTestingProgram", "Switch-Info", "Get-WIRELESSFrequencyNeighborhoodScan"
    Update       : Correct data format in function : "Get-WIRELESSFrequencyNeighborhoodScanID"
    Update       : Optimise code logic to manage Local / remote connection with web uri
    Update       : Remove function : "Switch-ConnectionType" in module : ".\BBOX-Module.psm1"
    Update       : Add new function : "Get-PasswordRecoveryVerify" in module : ".\BBOX-Module.psm1"
    Update       : Add new information in function : "Get-FIREWALLPingResponder"
    Update       : Correct SolvedTime information in function : "Get-LANAlerts"
    Update       : Rename function : "Get-NOTIFICATION" to "Get-NOTIFICATIONConfig"
    Update       : Add New informations (Events/Contacts) in function : "Get-NOTIFICATIONConfig"
    Update       : Add 3 New functions : "Get-NOTIFICATIONConfigAlerts", "Get-NOTIFICATIONConfigContacts", "Get-NOTIFICATIONConfigEvents" in module : ".\BBOX-Module.psm1"
    Update       : Correct some headers/values in fonctions in module : ".\BBOX-Module.psm1"
    Update       : Correct function "Get-VOIPFullCallLogLineX" in module : ".\BBOX-Module.psm1"
    Update       : Add function "Export-GlobalOutputData" in module : ".\BBOX-Module.psm1"
    Update       : BBOX in version 20.8.6
    Update       : Add function "Get-WANSFF" in module : ".\BBOX-Module.psm1"
    Update       : Add function "Get-WIRELESSVideoBridgeSetTopBoxes" and modify "Get-Status" in module : ".\BBOX-Module.psm1"
    Update       : Add function "Get-WIRELESSVideoBridgeRepeaters" in module : ".\BBOX-Module.psm1"

    Version 2.2 - BBOX version 20.8.8
    Updated Date : 2022/05/18
    Updated By   : Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Change display date format in functions : "Get-DeviceLog", "Get-DeviceFullLog", "Get-DeviceFullTechnicalLog", "Get-Device", "Get-DeviceFullTechnicalLog", "Get-DeviceToken", "Get-DeviceSummary", "Get-DYNDNSClient", "Get-HOSTS", "Get-HOSTSME", "Get-IPTVDiags", "Get-LANAlerts", "GET-PARENTALCONTROL", "Get-ParentalControlScheduler", "Get-SUMMARY", "Get-UPNPIGDRules", "Get-VOIPScheduler", "Get-WANAutowan", "Get-WANDiagsSessions", "et-WIRELESSScheduler"
    Update       : Replace variable $ID by $Index and $log by $Line in functions : "Get-DeviceLog", "Get-DeviceFullLog", "Get-DeviceFullTechnicalLog"
    Update       : Remove function "Format-Date"
    
    Version 2.3 - BBOX version 20.8.8
    Updated Date : 2022/08/05
    Updated By   : Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : New variable : $global:TranscriptFileName
    Update       : Create json system configuration file : ".\Settings-Program.json"
    Update       : Create json user file : ".\Settings-Default-User.json"
    Update       : Add function : "Get-JSONSettingsCurrentUserContent" and "Get-JSONSettingsDefaultUserContent"
    Update       : Create json user file : ".\Settings-Current-User.json" Duplication from ".\Settings-Default-User.json" if not already exists
    Update       : Import json user file : ".\Settings-Current-User.json" if already exists
    Update       : Update password management from Password.txt file to Settings-Current-User.json
    Update       : Update function : "Get-HostStatus" and "Get-PortStatus" to update json user file : ".\Settings-Current-User.json"
    Update       : Update function : "Get-ErrorCode"
    Update       : Update powershell requirements from -Version 5.0 to 5.1
    Update       : Update function : "Switch-ExportFormat" and "Switch-DisplayFormat" and "Switch-OpenHTMLReport" to manage trigger user settings configuration
    Update       : Update File configuration ".\Settings-Default-User.json", ".\Settings-Default-User.json", ".\Settings-Current-User.json"
    Update       : Change function organization for better loading/run program in file : ".\BBOX-Module.psm1"
    Update       : Optimise "Switch" function with "Break" in files : ".\BBOX-Aministration.ps1" and ".\BBOX-Module.psm1"
    Update       : Change order checks in file : ".\BBOX-Aministration.ps1"
    Update       : Create "regions" ([region]/[endregion]) to structure the code in files : ".\BBOX-Aministration.ps1" and ".\BBOX-Module.psm1"
    Update       : Update syntaxe for logs file and user console display
    Update       : Correct function : "Get-APIRessourcesMap", remove double "API/V1" syntaxe
    Update       : Correct function : "Export-GlobalOutputData" to manage when "$FormatedData" is null or empty

.LINKS
    
    https://api.bbox.fr/doc/
    https://api.bbox.fr/doc/apirouter/index.html
    https://chromedriver.chromium.org/
    https://mabbox.bytel.fr/
    https://mabbox.bytel.fr/api/v1
    http://winstonfassett.com/blog/2010/09/21/html-to-text-conversion-in-powershell/
    https://www.bbox-mag.fr/box/firmware/
    
#>

#region function

# Imported by module : ".\BBoxModule.psm1"

<#
    .SYNOPSIS
    Write-Log permet d'écrire les logs fonctionnels d'exécution.
    
    .DESCRIPTION
    Ecrit un log sur la console et sur fichier.
#>
function Write-Log {
    Param (
        [Parameter()]
        [ValidateSet("INFO","INFONO","VALUE","WARNING","ERROR","DEBUG")]
        $Type = "INFO",
        [Parameter(Mandatory=$true)]
        $Message,
        [Parameter(Mandatory=$true)]
        $Name,
        [Parameter()]
        [switch]$NotDisplay,
        [Parameter()]
        $Logname = "$global:LogFolderPath\$global:LogFileName"
    )
    
    $logpath = $Logname + $(get-date -UFormat %Y%m%d).toString() + ".csv"
    
    # Create log object 
    $log = [pscustomobject] @{Date=(Get-Date -UFormat %Y%m%d_%H%M%S) ; Type=$type ; Name=$name ; Message=$Message  ; user= $(whoami) ; PID=$PID} 
    $log | Add-Member -Name ToString -MemberType ScriptMethod -value {$this.date + ' : ' + $this.type +' : ' +$this.name +' : ' + $this.Message} -Force 
    
    # Append to global journal
    [Object[]] $Global:journal += $log.toString()
    
    If (-not $NotDisplay) {
        
        Switch ($Type) {
            
            "INFO"    {Write-Host -Object "$Message" -ForegroundColor Cyan;Break}
            
            "INFONO"  {Write-Host -Object "$Message" -ForegroundColor Cyan -NoNewline;Break}
            
            "VALUE"   {Write-Host -Object "$Message" -ForegroundColor Green;Break}
            
            "WARNING" {Write-Host -Object "$Message" -ForegroundColor Yellow;Break}
            
            "ERROR"   {Write-Host -Object "$Message" -ForegroundColor Red;Break}
            
            "DEBUG"   {Write-Host -Object "$Message" -ForegroundColor Blue;Break}
        }
    }
    
    # Create or open Mutex
    Try {
        $mtx = [System.Threading.Mutex]::OpenExisting("Global\PegaseMutex")
    }
    Catch {
        $mtx = New-Object System.Threading.Mutex($false, "Global\PegaseMutex")
    }
    
    Try {
        $mtx.WaitOne() | Out-Null
	    # Write Header if file don't exists yet
        
        If (-not (Test-Path $logpath)) {
            Out-File -FilePath $logpath -Encoding UTF8 -Append -InputObject "date;type;name;message;user;pid" 
        }
        Out-File -FilePath $logpath -Encoding UTF8 -Append -InputObject "$($Log.date);$($Log.type);$($Log.name);$($Log.Message);$($Log.user);$($Log.pid)" 
    }
    Finally {
        $mtx.ReleaseMutex()
    }
}

#endregion function

#region Main Variables

# Logs file
$ScriptRootFolder      = $PSScriptRoot
$global:LogFileName    = "BBOX_Administration_Log-"
$global:LogFolderName  = "Logs"
$global:LogFolderPath  = "$ScriptRootFolder\$global:LogFolderName"

# Transcript Logs
$global:TranscriptFileName = "BBOX-Administration-Transcript-Log.txt"
$TranscriptFilePath = "$global:LogFolderPath\$global:TranscriptFileName"

# System Json Configuration files
$ProgramConfigurationFileSettings   = "Settings-Program.json"
$RessourcesFolderName               = "Ressources"
$RessourcesPath                     = "$ScriptRootFolder\$RessourcesFolderName"
$global:JSONSettingsProgramFilePath = "$RessourcesPath\$ProgramConfigurationFileSettings"

# Main Trigger
$global:TriggerExit = 0
$TriggerLANNetwork = $Null

# URL Settings for the ChromeDriver request
$UrlRoot    = $Null
$Port       = $Null
$UrlHome    = $Null
$UrlToGo    = $Null

#endregion Main Variables

#region Start Program initialisation

Start-Transcript -Path $TranscriptFilePath -Append -Force -NoClobber
Write-Log -Type WARNING -Name "Program initialisation - Start Program" -Message "#################################################### Initialisation #####################################################"
Write-Log -Type INFO -Name "Program initialisation - Start Program" -Message "Start Program initialisation" -NotDisplay
Write-Log -Type INFONO -Name "Program initialisation - Start Program" -Message "Program loading ... : "

#endregion Start Program initialisation

#region Create logs folder

Write-Log -Type INFO -Name "Program initialisation - Logs Folder Creation" -Message "Start Logs Folder Creation" -NotDisplay
$Null = New-Item -Path "$ScriptRootFolder" -Name $global:LogFolderName -ItemType Directory -Force -ErrorAction Stop
Write-Log -Type INFO -Name "Program initialisation - Logs Folder Creation" -Message "End Logs Folder Creation" -NotDisplay

#endregion Create logs folder

#region Import System Json Configuration files

Write-Log -Type INFO -Name "Program initialisation - Import JSON Settings Program" -Message "Start Import JSON Settings Program" -NotDisplay
Write-Log -Type INFONO -Name "Program initialisation - Import JSON Settings Program" -Message "Import JSON Settings Program Status : " -NotDisplay
Try {
    $global:JSONSettingsProgramContent = Get-Content -Path $global:JSONSettingsProgramFilePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    Write-Log -Type VALUE -Name "Program initialisation - Import JSON Settings Program" -Message "Success" -NotDisplay
}
Catch {
    Write-Log -Type WARNING -Name "Program initialisation - Import JSON Settings Program" -Message "Failed, due to : $($_.ToString())"
    $global:JSONSettingsProgramContent = $Null
    $global:TriggerExit = 1
}
Write-Log -Type INFO -Name "Program initialisation - Import JSON Settings Program" -Message "End Import JSON Settings Program" -NotDisplay

#endregion Import System Json Configuration files

#region Load System Json Configuration files

Write-Log -Type INFO -Name "Program initialisation - Load JSON Settings Program" -Message "Start Load JSON Settings Program" -NotDisplay
Write-Log -Type INFONO -Name "Program initialisation - Load JSON Settings Program" -Message "Load JSON Settings Program Status : " -NotDisplay

If (($global:TriggerExit -eq 0) -and ($Null -ne $global:JSONSettingsProgramContent)) {
    
    Try {
        $global:JSONSettingsDefaultUserFilePath = "$ScriptRootFolder\$RessourcesFolderName\" + $global:JSONSettingsProgramContent.UserConfigurationFile.DefaultUserConfigurationFileName
        $global:JSONSettingsCurrentUserFilePath = "$ScriptRootFolder\$RessourcesFolderName\" + $global:JSONSettingsProgramContent.UserConfigurationFile.CurrentUserConfigurationFileName

        # Paths
        $ExportPath              = "$ScriptRootFolder\"  + $global:JSONSettingsProgramContent.path.ExportFolderName
        $ExportCSVPath           = "$ExportPath\" + $global:JSONSettingsProgramContent.path.ExportCSVFolderName
        $ExportJSONPath          = "$ExportPath\" + $global:JSONSettingsProgramContent.path.ExportJSONFolderName
        $JournalPath             = "$ScriptRootFolder\" + $global:JSONSettingsProgramContent.path.JournalFolderName
        $JsonBboxconfigPath      = "$ScriptRootFolder\" + $global:JSONSettingsProgramContent.path.JsonBboxconfigFolderName
        $RessourcesPath          = "$ScriptRootFolder\" + $global:JSONSettingsProgramContent.path.RessourcesFolderName
        $ReportPath              = "$ScriptRootFolder\" + $global:JSONSettingsProgramContent.path.ReportFolderName
        $BBOXModulePath          = "$ScriptRootFolder\" + $global:JSONSettingsProgramContent.path.BBOXModuleFileName
        $APISummaryPath          = "$RessourcesPath\" + $global:JSONSettingsProgramContent.path.APISummaryFileName
        $TestedEnvironnementPath = "$RessourcesPath\" + $global:JSONSettingsProgramContent.path.TestedEnvironnementFileName

        # Google Chrome / Chrome Driver Paths
        $global:ChromeDriver                     = $Null
        $ChromeVersionRegistry                   = $global:JSONSettingsProgramContent.GoogleChrome.ChromeVersionRegistry
        $ChromeDriverPath                        = "$RessourcesPath\" + $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverRessourcesFolderName
        $ChromeDriverDefaultPath                 = "$ChromeDriverPath\" + $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultFolderName
        $ChromeDriverDefaultSetupPath            = "$ChromeDriverDefaultPath\" + $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultSetupFileName
        $ChromeDriverDefaultWebDriverDLLPath     = "$ChromeDriverDefaultPath\" + $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultWebDriverDLLFileName
        $ChromeDriverDefaultWebDriverSupportPath = "$ChromeDriverDefaultPath\" + $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultWebDriverSupportFileName
        $ChromeDriverDefaultProfile              = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultProfileName
        $ChromeProgramFilesInstallation          = $global:JSONSettingsProgramContent.GoogleChrome.ChromeProgramFilesInstallationPath
        $ChromeProgramFilesX86Installation       = $global:JSONSettingsProgramContent.GoogleChrome.ChromeProgramFilesX86InstallationPath

        # APIName
        $APINameExclusionFull                 = $global:JSONSettingsProgramContent.APIName.APINameExclusionFull
        $APINameExclusionFull_Testing_Program = $global:JSONSettingsProgramContent.APIName.APINameExclusionFull_Testing_Program

        # BBox
        $APIVersion          = $global:JSONSettingsProgramContent.bbox.APIVersion
        $BBoxDns             = $global:JSONSettingsProgramContent.bbox.BBoxDns
        $BBoxUrlRemote       = $global:JSONSettingsProgramContent.bbox.BBoxUrlRemote
        $APIUrlDocumentation = $global:JSONSettingsProgramContent.bbox.APIUrlDocumentation
        
        # Various
        $Mail = $global:JSONSettingsProgramContent.various.mail        
        
        Write-Log -Type VALUE -Name "Program initialisation - Load JSON Settings Program" -Message "Success" -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name "Program initialisation - Load JSON Settings Program" -Message "Failed, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
}
Else {
    Write-Log -Type WARNING -Name "Program initialisation - Load JSON Settings Program" -Message "Failed, due to : $($_.ToString())"
    $global:TriggerExit = 1
}
Write-Log -Type INFO -Name "Program initialisation - Load JSON Settings Program" -Message "End Load JSON Settings Program" -NotDisplay

#endregion Load System Json Configuration files

#region Import Functions with Module : "BBOX-Module.psm1"

If ($global:TriggerExit -eq 0) {
    
    Write-Log -Type INFO -Name "Program initialisation - Powershell Module Importation" -Message "Start Powershell Module Importation : $BBOXModulePath" -NotDisplay
    Write-Log -Type INFONO -Name "Program initialisation - Powershell Module Importation" -Message "Powershell Module Importation status : " -NotDisplay
    
    Try {
        Remove-Module -Name BBOX-Module -ErrorAction SilentlyContinue
    }
    Catch {
        Write-Log -Type ERROR -Name "Program initialisation - Powershell Module Importation" -Message "Failed. Powershell Module $BBOXModulePath can't be removed, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Start-Sleep 1
    Try {
        Import-Module -Name $BBOXModulePath -ErrorAction Stop
        Write-Log -Type VALUE -Name "Program initialisation - Powershell Module Importation" -Message "Success" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name "Program initialisation - Powershell Module Importation" -Message "Failed. Powershell Module $BBOXModulePath can't be imported due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    
    Write-Log -Type INFO -Name "Program initialisation - Powershell Module Importation" -Message "End Powershell Module Importation" -NotDisplay
}

#endregion Import Functions

#region Create folders/files if not yet existing

If ($global:TriggerExit -eq 0) {
    
    Write-Log -Type INFO -Name "Program initialisation - Program Folders/Files check" -Message "Start Program Folders/Files check" -NotDisplay
    
    # Folders test
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $ExportPath              -FolderName $ExportPath              -ErrorAction Stop
    Test-FolderPath -FolderRoot $ExportPath       -FolderPath $ExportCSVPath           -FolderName $ExportCSVPath           -ErrorAction Stop
    Test-FolderPath -FolderRoot $ExportPath       -FolderPath $ExportJSONPath          -FolderName $ExportJSONPath          -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $JournalPath             -FolderName $JournalPath             -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $ReportPath              -FolderName $ReportPath              -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $JsonBboxconfigPath      -FolderName $JsonBboxconfigPath      -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $ChromeDriverPath        -FolderName $ChromeDriverPath        -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $ChromeDriverDefaultPath -FolderName $ChromeDriverDefaultPath -ErrorAction Stop
    
    # Files test
    Test-FilePath   -FileRoot $ChromeDriverDefaultPath -FilePath $ChromeDriverDefaultSetupPath            -FileName $ChromeDriverDefaultSetupPath -ErrorAction Stop
    Test-FilePath   -FileRoot $ChromeDriverDefaultPath -FilePath $ChromeDriverDefaultWebDriverDLLPath     -FileName $ChromeDriverDefaultWebDriverDLLPath -ErrorAction Stop
    Test-FilePath   -FileRoot $ChromeDriverDefaultPath -FilePath $ChromeDriverDefaultWebDriverSupportPath -FileName $ChromeDriverDefaultWebDriverSupportPath -ErrorAction Stop
    
    Write-Log -Type INFO -Name "Program initialisation - Program Folders/Files check" -Message "End Program Folders/Files check" -NotDisplay
}

#endregion Create folders/files

#region Check if ressources folder exist

If ($global:TriggerExit -eq 0) { 

    Write-Log -Type INFO -Name "Program initialisation - Ressources Folder" -Message "Start Folder Ressources check : $RessourcesPath" -NotDisplay
    Write-Log -Type INFONO -Name "Program initialisation - Ressources Folder" -Message "Ressources Folder State : " -NotDisplay
    
    If (Test-Path -Path $RessourcesPath -ErrorAction Stop) {
    
        Write-Log -Type VALUE -Name "Program initialisation - Ressources Folder" -Message "Already Exist" -NotDisplay
    }
    Else {
        Write-Log -Type WARNING -Name "Program initialisation - Ressources Folder" -Message "Not found"
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name "Program initialisation - Ressources Folder" -Message "End Folder Ressources check" -NotDisplay
}

#endregion ressources folder

#region Import Actions available

If ($global:TriggerExit -eq 0) {
    
    Write-Log -Type INFO -Name "Program initialisation - Referentiel Actions Availables Importation" -Message "Start Referentiel Actions Availables Importation" -NotDisplay
    Write-Log -Type INFONO -Name "Program initialisation - Referentiel Actions Availables Importation" -Message "Importing Referentiel Actions Availables from : $APISummaryPath : " -NotDisplay
    
    Try {
        $Actions = Import-Csv -Path $APISummaryPath -Delimiter ";" -Encoding UTF8 -ErrorAction Stop
        Write-Log -Type VALUE -Name "Program initialisation - Referentiel Actions Availables Importation" -Message "Success" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name "Program initialisation - Referentiel Actions Availables Importation" -Message "Failed. Referentiel Actions can't be imported, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name "Program initialisation - Referentiel Actions Availables Importation" -Message "End Referentiel Actions Availables Importation" -NotDisplay
}

#endregion Import Actions

#region Check if Google Chrome is already install

If ($global:TriggerExit -eq 0) {
    
    Write-Log -Type INFO -Name "Program initialisation - Google Chrome Installation" -Message "Start Google Chrome Installation" -NotDisplay    
    Write-Log -Type INFONO -Name "Program initialisation - Google Chrome Installation" -Message "Google Chrome installation status : " -NotDisplay
    
    Try {
        $ChromeVersion = (Get-ItemProperty $ChromeVersionRegistry -ErrorAction Stop).Version
        Write-Log -Type VALUE -Name "Program initialisation - Google Chrome Installation" -Message "Successful" -NotDisplay
        Write-Log -Type INFONO -Name "Program initialisation - Google Chrome Version" -Message "Current Google Chrome version : " -NotDisplay
        Write-Log -Type VALUE -Name "Program initialisation - Google Chrome Version" -Message "$ChromeVersion" -NotDisplay
        Write-Log -Type INFO -Name "Program initialisation - Google Chrome Installation" -Message "End Google Chrome Installation" -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name "Program initialisation - Google Chrome Installation" -Message "Not yet" -NotDisplay
        Write-Log -Type WARNING -Name "Program initialisation - Google Chrome Installation" -Message "Please install Google Chrome before to use this Program"
        Write-Log -Type INFO -Name "Program initialisation - Google Chrome Installation" -Message "End Google Chrome Installation" -NotDisplay
        $global:TriggerExit = 1
    }
}

#endregion Google Chrome

#region Get Google Chrome binary Path

If ($global:TriggerExit -eq 0) {
    
    Write-Log -Type INFO -Name "Program initialisation - Google Chrome Binaries" -Message "Start Google Chrome Binaries" -NotDisplay    
    Write-Log -Type INFONO -Name "Program initialisation - Google Chrome Binaries" -Message "Google Chrome Binaries Path : " -NotDisplay
    
    Try {
        If ((Test-Path -Path $ChromeProgramFilesInstallation -ErrorAction Continue) -eq $true) {
            $ChromeBinaryPath = $ChromeProgramFilesInstallation
        }
        Elseif ((Test-Path -Path $ChromeProgramFilesX86Installation -ErrorAction Continue) -eq $true) {
            $ChromeBinaryPath = $ChromeProgramFilesX86Installation
        }
        Else {
            $global:TriggerExit = 1
        }
        
        Write-Log -Type VALUE -Name "Program initialisation - Google Chrome Binaries" -Message "$ChromeBinaryPath" -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name "Program initialisation - Google Chrome Binaries" -Message "Unable to find google chrome Binaries"
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name "Program initialisation - Google Chrome Binaries" -Message "End Google Chrome Installation" -NotDisplay    
}

#endregion Google Chrome binary Path

#region Chrome Version choice function chrome version installed

If ($global:TriggerExit -eq 0) {
    
    Write-Log -Type INFO -Name "Program initialisation - Chrome Driver Version" -Message "Start Chrome Driver version selection function Chrome Version installed on device" -NotDisplay   
    Try {
        $ChromeDriverVersion = Get-ChromeDriverVersion -ChromeVersion $ChromeVersion -ErrorAction Stop
    }
    Catch {
        Write-Log -Type WARNING -Name "Program initialisation - Chrome Driver Version" -Message "Impossible to define the correct ChromeDriverVersion, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name "Program initialisation - Chrome Driver Version" -Message "End Chrome Driver version selection function Chrome Version installed on device" -NotDisplay
}

#endregion Chrome Version choice

#region End Program Initialisation

If ($global:TriggerExit -eq 0) {
    Write-Log -Type VALUE -Name "Program initialisation - Start Program" -Message "Finished without errors"
}
Else{
    Write-Log -Type WARNING -Name "Program initialisation - Start Program" -Message "Finished with errors"
}

Write-Log -Type INFO -Name "Program initialisation - Start Program" -Message "End Program initialisation" -NotDisplay
Write-Log -Type WARNING -Name "Program initialisation - Start Program" -Message "#################################################### Initialisation #####################################################"

#endregion End Program Initialisation

#region Program Presentation

If ($global:TriggerExit -eq 0) {
    
    Write-Host "##################################################### Description ######################################################" -ForegroundColor Yellow
    Write-Host "This program is only available in English"
    Write-Host "It allows you to get, modify and delete information on Bouygues Telecom's BBOX"
    Write-Host "It displays advanced information that you will not see through the classic web interface of your BBOX"
    Write-Host "And this via a local or remote connection (Provided that you have activated the remote BBOX management => " -NoNewline
    Write-Host "$BBoxUrlRemote" -ForegroundColor Green -NoNewline
    Write-Host ")"
    Write-Host "The result can be displayed in HTML format or in table form (Gridview)"
    Write-Host "The result can be exported in `" .csv (.csv) `" or `" .JSON (.JSON) `" format"
    Write-Host "The only limitation of this program is related to the requests available via the API installed on the target BBOX according to the model and the firmware version of this one"
    Write-Host "When displaying the result, some information may not be displayed, or may be missing :"
    Write-Host "- Either it's an oversight on my part in the context of the development, and I apologize in advance"
    Write-Host "- Either this one is still under development"
    Write-Host "- Either this information is optional and only appears in the presence of certain bbox models :"
    Write-Host "-- BBOX models"
    Write-Host "-- Firmware version"
    Write-Host "-- Available features"
    Write-Host "-- Connection mode (Local / Remote)"
    Write-Host "This program requires the installation of PowerShell 5.1 minimum and Google Chrome"
    Write-Host "For more information, please consult : " -NoNewline
    Write-Host "$APIUrlDocumentation" -ForegroundColor Green
    Write-Host "Be carefull, this program is reserved for an advanced use of the BBOX settings and is aimed at an informed audience !" -ForegroundColor Yellow
    Write-Host "Any improper handling risks causing partial or even total malfunction of your BBOX, rendering it unusable. You are Warned !" -ForegroundColor Yellow
    Write-Host "Therefore, you use this program at your own risks, I can't be responsible if you don't use it in the correct environnement" -ForegroundColor Red
    Write-Host "For any questions or additional requests, contact me to this email address : " -NoNewline
    Write-Host "$Mail" -ForegroundColor Green
    Write-Host "Please make sure log file is closed before continue" -ForegroundColor Yellow
    Write-Host "Logs files location : "
    Write-Host "- $global:LogFolderPath\$global:LogFileName*.csv" -ForegroundColor Green
    Write-Host "- $TranscriptFilePath" -ForegroundColor Green
    Write-Host "Last success tested environnement :"
    Write-Log -Type INFO -Name "Program presentation - Get tested environnements" -Message "Start tested environnements" -NotDisplay
    Write-Log -Type INFO -Name "Program presentation - Get tested environnements" -Message "Tested environnements importation status $TestedEnvironnementPath :" -NotDisplay
    Try {
        $TestedEnvironnement = Import-Csv -Path $TestedEnvironnementPath -Delimiter ";" -ErrorAction Stop
        $TestedEnvironnement[0] | Format-List
        Write-Log -Type VALUE -Name "Program presentation - Get tested environnements" -Message "Success" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name "Program presentation - Get tested environnements" -Message "Failed to get tested environnements, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Write-Host "For others successful tested environnement, please consult : " -NoNewline
    Write-Host "$TestedEnvironnementPath" -ForegroundColor Green
    Write-Log -Type INFO -Name "Program presentation - Get tested environnements" -Message "End tested environnements" -NotDisplay

    Write-Host "##################################################### Description ######################################################" -ForegroundColor Yellow
    Pause
}

#endregion Program Presentation

#region Import User Json Configuration files

If (($global:TriggerExit -eq 0) -and (Test-Path -Path $global:JSONSettingsCurrentUserFilePath)) {
    
    Get-JSONSettingsCurrentUserContent
}
Else {
    Write-Log -Type INFO -Name "Program initialisation - Json Current User Settings Creation" -Message "Start Json Current User Settings Creation" -NotDisplay
    Write-Log -Type INFONO -Name "Program initialisation - Json Current User Settings Creation" -Message "Json Current User Settings Creation Status : "
    Try {
        Copy-Item -Path $global:JSONSettingsDefaultUserFilePath -Destination $global:JSONSettingsCurrentUserFilePath -Force
        Start-Sleep -Seconds 2
        Write-Log -Type VALUE -Name "Program initialisation - Json Current User Settings Creation" -Message "Success"
    }
    Catch {
        Write-Log -Type WARNING -Name "Program initialisation - Json Current User Settings Creation" -Message "Failed, due to : $($_.ToString())"
    }
    Write-Log -Type INFO -Name "Program initialisation - Json Current User Settings Creation" -Message "End Json Current User Settings Creation" -NotDisplay

    If (Test-Path -Path $global:JSONSettingsCurrentUserFilePath) {

        Get-JSONSettingsCurrentUserContent
    }
    Elseif (Test-Path -Path $global:JSONSettingsDefaultUserFilePath) {
        
        Get-JSONSettingsDefaultUserContent
    }
    Else {
        Write-Log -Type WARNING -Name "Program initialisation - Json Current User Settings Importation" -Message "Unable to find find any user settings configuration file, due to : $($_.ToString())"
        Write-Log -Type INFO -Name "Program initialisation - Json Current User Settings Importation" -Message "End Json Current User Settings Importation" -NotDisplay
        $global:TriggerExit = 1
    }
}

#endregion Import User Json Configuration files

#region Check if password already exist in Current json file

If ($global:TriggerExit -eq 0) {
    
    Write-Log -Type INFO -Name "Program run - Password Status" -Message "Start Password Status" -NotDisplay
    Write-Log -Type INFONO -Name "Program run - Password Status" -Message "Password Status : "
    
    If (-not [string]::IsNullOrEmpty($global:JSONSettingsCurrentUserContent.Credentials.NewPassword)) {
        
        $global:Password = $global:JSONSettingsCurrentUserContent.Credentials.NewPassword
    }
    Else{
        While ([string]::IsNullOrEmpty($global:Password)) {
            
            # Ask user to provide BBOX Web Interface Password
            Write-Log -Type WARNING -Name "Program run - Password Status" -Message "Not set"
            $global:Password = Read-Host -Prompt "Please enter your bbox Admin web portal interface password "
        }
    }
    
    $global:JSONSettingsCurrentUserContent.Credentials.OldPassword = $global:JSONSettingsCurrentUserContent.Credentials.NewPassword
    $global:JSONSettingsCurrentUserContent.Credentials.NewPassword = $global:Password
    $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
    Write-Log -Type VALUE -Name "Program run - Password Status" -Message "Set"
    Write-Log -Type INFO -Name "Program run - Password Status" -Message "End Password Status" -NotDisplay
}

#endregion Check if password already exist in Current json file

#region Check if user connect on the correct LAN Network

If ($global:TriggerExit -eq 0) {
    
    Write-Log -Type INFO -Name "Program run - Network connection" -Message "Start Check BBOX LAN network" -NotDisplay
    Write-Log -Type INFONO -Name "Program run - Network connection" -Message "Checking BBOX LAN network : " -NotDisplay
    
    Try {
        $DnsName = Resolve-DnsName -Name $BBoxDns -Type A -DnsOnly -ErrorAction Stop
        Write-Log -Type VALUE -Name "Program run - Network connection" -Message "Connected to your Local BBOX Network" -NotDisplay
        Write-Log -Type INFONO -Name "Program run - Network connection" -Message "BBOX IP Address : " -NotDisplay
        Write-Log -Type VALUE -Name "Program run - Network connection" -Message "$($DnsName.Address)" -NotDisplay
        Write-Log -Type INFONO -Name "Program run - Network connection" -Message "Recommanded connection : " -NotDisplay
        Write-Log -Type VALUE -Name "Program run - Network connection" -Message "Localy" -NotDisplay
        $TriggerLANNetwork = 1
    }
    Catch {
        Write-Log -Type ERROR -Name "Program run - Network connection" -Message "Failed" -NotDisplay
        Write-Log -Type ERROR -Name "Program run - Network connection" -Message "Unable to resolve $BBoxDns, due to : $($_.ToString())" -NotDisplay
        Write-Host "It seems you are not connected to your Local BBOX Network" -ForegroundColor Yellow
        Write-Host "If you are connected on your local network, make sure you are connected on the BBOX's Wifi or ethernet network" -ForegroundColor Yellow
        Write-Host "If you use a intermediary router between your computer and the BBOX router, it will not working" -ForegroundColor Yellow
        Write-Log -Type INFONO -Name "Program run - Network connection" -Message "Recommanded connection : " -NotDisplay
        Write-Log -Type VALUE -Name "Program run - Network connection" -Message "Remotely" -NotDisplay
        $TriggerLANNetwork = 0
    }
    Write-Log -Type INFO -Name "Program run - Network connection" -Message "End Check BBOX LAN network" -NotDisplay
}

#endregion Check if user connect on the correct LAN Network

#region Ask to the user how he want to connect to the BBOX

If ($global:TriggerExit -eq 0) {
    
    Write-Log -Type INFO -Name "Program run - Connexion Type" -Message "Start Connexion Type" -NotDisplay
    Write-Log -Type INFO -Name "Program run - Connexion Type" -Message "How do you want to connect to the BBOX ?"
    $ConnexionType = Get-ConnexionType -TriggerLANNetwork $TriggerLANNetwork -ErrorAction Stop
}

#endregion Ask to the user how he want to connect to the BBOX

#region Set Bbox connexion settings regarding user selection

If ($global:TriggerExit -eq 0) {
    
    Switch ($ConnexionType[0]) {
        
        L   {$UrlRoot = "https://$BBoxDns/$APIVersion"
             $UrlHome = "https://$BBoxDns/login.html"
             Break
            }
        
        R   {Write-Log -Type INFO -Name "Program run - Check Host" -Message "Start Check Host" -NotDisplay
             $DYNDNS = Get-HostStatus
             Write-Log -Type INFO -Name "Program run - Check Host" -Message "End Check Host" -NotDisplay
             Write-Log -Type INFO -Name "Program run - Check Port" -Message "Start Check Port" -NotDisplay
             $Port = Get-PortStatus -UrlRoot $DYNDNS
             Write-Log -Type INFO -Name "Program run - Check Port" -Message "End Check Port" -NotDisplay
             $UrlRoot = "https://$DYNDNS`:$Port/$APIVersion"
             $UrlHome = "https://$DYNDNS`:$Port/login.html"
             Break
            }
        
        Q   {$global:TriggerExit = 1;Break}
    }
    
    If ($ConnexionType[0] -ne "Q") {
        Write-Log -Type INFO -Name "Program run - Connexion Type" -Message "Root BBox Url : $UrlRoot" -NotDisplay
        Write-Log -Type INFO -Name "Program run - Connexion Type" -Message "Login BBox Url : $UrlHome" -NotDisplay
        If ($Port) {
            Write-Log -Type INFO -Name "Program run - Connexion Type" -Message "Remote Bbox Url : $Port" -NotDisplay
        }
        Write-Log -Type INFO -Name "Program run - Connexion Type" -Message "End Connexion Type" -NotDisplay
    }
}

#endregion Set Bbox connexion settings regarding user selection

#region Get Already Active Google Chrome Process

If ($global:TriggerExit -eq 0) {
    $Global:ActiveChromeBefore = @(Get-Process [c]hrome -ErrorAction SilentlyContinue| ForEach-Object {$_.Id})
}

#endregion Get Already Active Google Chrome Process

#region Start in Background chromeDriver

If ($global:TriggerExit -eq 0) {
    
    Write-Log -Type INFO -Name "Program run - ChromeDriver Launch" -Message "Start ChromeDriver as backgroung process" -NotDisplay
    Write-Log -Type INFONO -Name "Program run - ChromeDriver Launch" -Message "Starting ChromeDriver as backgroung process : " -NotDisplay
    
    Try {
        Start-ChromeDriver -ChromeBinaryPath $ChromeBinaryPath -ChromeDriverPath $ChromeDriverPath -ChromeDriverVersion "$ChromeDriverVersion" -DownloadPath $JournalPath -LogsPath $global:LogFolderPath -ChromeDriverDefaultProfile $ChromeDriverDefaultProfile -ErrorAction Stop
        Write-Log -Type VALUE -Name "Program run - ChromeDriver Launch" -Message "Started" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name "Program run - ChromeDriver Launch" -Message "Failed. ChromeDriver can't be started, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name "Program run - ChromeDriver Launch" -Message "End ChromeDriver as backgroung process" -NotDisplay
}

#endregion Start in Background chromeDriver

#region Start BBox Authentification

If ($global:TriggerExit -eq 0) {
    
    Write-Log -Type INFONO -Name "Program run - ChromeDriver Authentification" -Message "Start BBOX Authentification" -NotDisplay
    Write-Log -Type INFONO -Name "Program run - ChromeDriver Authentification" -Message "Starting BBOX Authentification : " -NotDisplay
    
    Try {
        Connect-BBOX -UrlHome $UrlHome -Password $global:Password -ErrorAction Stop
        Write-Log -Type VALUE -Name "Program run - ChromeDriver Authentification" -Message "Authentificated" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name "Program run - ChromeDriver Authentification" -Message "Failed. Authentification can't be done, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Write-Log -Type INFONO -Name "Program run - ChromeDriver Authentification" -Message "End BBOX Authentification" -NotDisplay
}

#endregion Start BBox Authentification

#region process

While ($global:TriggerExit -eq 0) {
    
    # Ask user action he wants to do (Get/PUT/POST/REMOVE)
    Write-Log -Type INFO -Name "Program run - Action asked" -Message "Please select an action in the list"
    $Action = $Actions | Where-Object {$_.Available -eq "Yes"} | Out-GridView -Title "Please select an action in the list :" -OutputMode Single -ErrorAction Stop
    
    If ($Null -ne $Action) {
        
        # Set value to variables
        $Label = $Action.label
        $APIName = $Action.APIName
        $Description = $Action.Description
        $ReportType = $Action.ReportType
        $ExportFile = $Action.ExportFile
        
        Write-Log -Type INFONO -Name "Program run - Action asked" -Message "Selected action : "
        Write-Log -Type VALUE -Name "Program run - Action asked" -Message "$Description"
        
        # Get data
        Switch ($APIName) {
            
            "Full"                 {$APISName = ($Actions | Where-Object {(($_.Available -eq "Yes") -and ($_.APIName -notmatch $APINameExclusionFull) -and ($_.Scope -notmatch "Computer") -and ($_.Action -notmatch "Export"))}).APIName | Select-Object -Unique
                                    $FormatedData = Export-BBoxConfiguration -APISName $APISName -UrlRoot $UrlRoot -OutputFolder $JsonBboxconfigPath
                                    Break
                                   }
            
            "Full_Testing_Program" {$APISName = $Actions | Where-Object {(($_.Available -eq "Yes") -and ($_.APIName -notmatch $APINameExclusionFull_Testing_Program))} | Select-Object *
                                    $FormatedData = Export-BBoxConfigTestingProgram -APISName $APISName -UrlRoot $UrlRoot -OutputFolder $JsonBboxconfigPath -Mail $Mail -JournalPath $JournalPath
                                    Break
                                   }
            
            Default                {$UrlToGo = "$UrlRoot/$APIName"
                                    $FormatedData =  Switch-Info -Label $Label -UrlToGo $UrlToGo -APIName $APIName -UrlRoot $UrlRoot -Mail $Mail -JournalPath $JournalPath -ErrorAction Continue -WarningAction Continue
                                    Export-GlobalOutputData -FormatedData $FormatedData -APIName $APIName -ExportCSVPath $ExportCSVPath -ExportJSONPath $ExportJSONPath -ExportFile $ExportFile -Description $Description -ReportType $ReportType -ReportPath $ReportPath
                                    Break
                                   }
        }
    }
    
    Else {
        Write-Log -Type INFONO -Name "Program run - Action asked" -Message "Action chosen : "
        Write-Host "Cancelled by user / Quit program" -ForegroundColor Green
        Write-Log -Type VALUE -Name "Program run - Action asked" -Message "Cancelled by user" -NotDisplay
        $global:TriggerExit = 1
    }
}

#endregion process

#region Close all ChromeDriver instances openned

Stop-Program -LogFolderPath $global:LogFolderPath -LogFileName $global:LogFileName -ErrorAction Stop
$Global:ActiveChromeAfter = Get-Process Chrome -ErrorAction SilentlyContinue | ForEach-Object {$_.Id} | Where-Object {$Global:ActiveChromeBefore -notcontains $_} -ErrorAction SilentlyContinue
If ($null -ne $Global:ActiveChromeAfter) {
    Stop-Process -Id $Global:ActiveChromeAfter -Force -ErrorAction SilentlyContinue
}
Stop-Transcript -ErrorAction Stop

#endregion Close all ChromeDriver instances openned
