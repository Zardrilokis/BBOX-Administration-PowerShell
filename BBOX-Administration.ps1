#Requires -Version 7.0

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
    Update       : Add module : '.\BBOX-Module.psm1'
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
    Update       : Solved problem in function : 'Get-ConnexionType' when relaunch the script keep the old user selection
    Update       : Solved display title for HTML report and CSV file
    Update       : Add new Log type for device logs
    Update       : Correct functions to collect log informations
    Update       : Add new features available since version 19.2.12
    Update       : Correct properties in function 'Get-Airties'
    Update       : Add new function : 'Get-Nat' - Get Nat Configuration Information
    Update       : Correct wifi scan when use remote BBOX connexion, function 'Start-RefreshWIRELESSFrequencyNeighborhoodScan'
    Update       : Correct Active Host session by host, function 'Get-WANDAASH'
    Update       : Modify Display date format for HTML report
    Update       : Add new function : 'Get-HOSTSPAUTH' => Get HOSTS PAUTH Information
    Update       : Add new function : 'Format-Date' => To format the custom date to the standard one / Replace in functions in '.\BBOX-Module.psm1'
    Update       : Add new function : 'Remove-FolderContent' => To remove export folder content Add in BBOX-Module.psm1
    Update       : Add new requests in file : '.\Ressources\API-Summary.csv' => Remove-FCLogs / Remove-FCExportCSV / Remove-FCExportJSON / Remove-FCJournal / Remove-FCJBC / Remove-FCReport
    Update       : Add 3 last Chrome Drivers versions : 93.0.4577.15 / 92.0.4515.43 / 91.0.4472.101
    Update       : Modify function : 'Get-DeviceToken' in '.\BBOX-Module.psm1'
    Update       : Add new properties in existing functions
    
    Version 2.0
    Updated Date : 2022/01/13
    Updated By   : Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Add 2 new functions : 'Switch-DisplayFormat' and 'Switch-ExportFormat' in '.\BBOX-Module.psm1'
    Update       : Add new requests in file : '.\Ressources\API-Summary.csv' => Switch-DisplayFormat / Switch-ExportFormat
    Update       : Add new function : 'EmptyFormatedDATA' in '.\BBOX-Module.psm1'
    Update       : Add new logs informations
    Update       : Correct Syntaxt
    Update       : Correct Program Sequence order
    Update       : Add new functions : 'Format-DisplayResult' and 'Format-ExportResult'
    Update       : Add Varible : '$logFileName' and '$FormatedDataExclusion'
    Update       : Rename variable : '$Info' and function property '-Info' to '$Label' and 'Label' in '.\BBOX-Module.psm1' and '.\BBOX-Administration.ps1'
    Update       : Rename variable : '$Pages' and function property '-Pages' to '$APIsName' and 'APIsName' in '.\BBOX-Administration.ps1'
    Update       : Rename variable : '$Page' and function property '-Page' to '$APIName' and 'APIName'
    Update       : Add new function : 'Stop-Program' in '.\BBOX-Module.psm1'
    Update       : Update logs file content
    Update       : Add Chrome Driver Log Path in Chrome Driver Option in function : 'Start-ChromeDriver'
    Update       : Add Transcript logs file
    Update       : Change Google Chrome installation path detection
    Update       : Correct bug with HTML Report in function 'GET-DYNDNSPL' (Missing first line to display)
    Update       : Disable All Extentions at chrome Driver startup in function : 'Start-ChromeDriver'
    Update       : Change common footer in HTML Report
    Update       : Modify Header title from 'Record' to 'Record Type' in function : 'Get-DYNDNSClient'
    Update       : Correct bug in function 'Get-DYNDNS' (No data get after request)
    Update       : Modify remember check remote bbox connection only if remote instead of both.
    Update       : Modify comments if bbox dns not responding when program analyse your network connection.
    Update       : Modify comment when program quit (System / User)
    Update       : Change function's name from 'Get-WPS' to 'Get-WIRELESSWPS'
    Update       : Correct bug in function : 'Get-WIRELESSWPS' (Missing data to collect)
    Update       : Add date in file name export/report
    Update       : Add dynamic folder path in function : 'Export-BboxConfiguration' => modify also function : 'Switch-Info'
    Update       : Correct Log file Name display when program closing
    Update       : Modify functions : 'Test-FilePath' and 'Test-FolderPath'
    Update       : Change 'Get-BBoxJournal' function logic
    Update       : Add new function : 'Get-CPLDeviceList' in module : '.\BBOX-Module.psm1'
    Update       : Modify function : 'Get-CPL'
    Update       : Modify function : 'Get-BackupList'
    Update       : Update function 'Get-DeviceToken' with the date time format was changed
    Update       : Add new function : 'Get-AirtiesLANmode' and update function : 'Switch-Info'
    Update       : Modify logs and correct displayed comments
    Update       : Correct wrong parameters '.isDefault24' and '.isDefault5' in function : 'Get-WIRELESS'
    Update       : Correct function : 'Start-RefreshWIRELESSFrequencyNeighborhoodScan' to adapt for version : 20.6.8
    Update       : Update logs files
    Update       : New function : 'Format-Date1970' for specific format date
    Update       : Correct logs in function : 'Stop-Program'
    Update       : Update function : 'Get-CPLDeviceList' to get all CPL device instead of one only
    Update       : Add new comments to best understanding how script run
    Update       : Correct if there is no data to display/export in all function linked to the API needed to be modified
    Update       : Correct function : 'Get-HOSTSPAUTH'
    Update       : Update function : 'Get-BBoxJournal' change download files method
    Update       : Correct function : 'Stop-ChromeDriver' when chrome driver not yet started
    Update       : Correct the log name in function : 'Stop-Program'
    
    Version 2.1 - BBOX version 20.8.6
    Updated Date : 2022/02/16
    Updated By   : Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Update logs files / Correct missing information in functions from BBOX-Module.psm1
    Update       : Correct Switch $APIName for 'Default' way
    Update       : Correct Grammatical Syntaxe
    Update       : Change order code in function : 'Start-RefreshWIRELESSFrequencyNeighborhoodScan'
    Update       : Simplify paramerters in functions : 'Export-BBoxConfiguration', 'Export-BBoxConfigTestingProgram', 'Switch-Info', 'Get-WIRELESSFrequencyNeighborhoodScan'
    Update       : Correct data format in function : 'Get-WIRELESSFrequencyNeighborhoodScanID'
    Update       : Optimise code logic to manage Local / remote connection with web uri
    Update       : Remove function : 'Switch-ConnectionType' in module : '.\BBOX-Module.psm1'
    Update       : Add new function : 'Get-PasswordRecoveryVerify' in module : '.\BBOX-Module.psm1'
    Update       : Add new information in function : 'Get-FIREWALLPingResponder'
    Update       : Correct SolvedTime information in function : 'Get-LANAlerts'
    Update       : Rename function : 'Get-NOTIFICATION' to 'Get-NOTIFICATIONConfig'
    Update       : Add New informations (Events/Contacts) in function : 'Get-NOTIFICATIONConfig'
    Update       : Add 3 New functions : 'Get-NOTIFICATIONConfigAlerts', 'Get-NOTIFICATIONConfigContacts', 'Get-NOTIFICATIONConfigEvents' in module : '.\BBOX-Module.psm1'
    Update       : Correct some headers/values in fonctions in module : '.\BBOX-Module.psm1'
    Update       : Correct function 'Get-VOIPFullCallLogLineX' in module : '.\BBOX-Module.psm1'
    Update       : Add function 'Export-GlobalOutputData' in module : '.\BBOX-Module.psm1'
    Update       : BBOX in version 20.8.6
    Update       : Add function 'Get-WANSFF' in module : '.\BBOX-Module.psm1'
    Update       : Add function 'Get-WIRELESSVideoBridgeSetTopBoxes' and modify 'Get-Status' in module : '.\BBOX-Module.psm1'
    Update       : Add function 'Get-WIRELESSVideoBridgeRepeaters' in module : '.\BBOX-Module.psm1'

    Version 2.2 - BBOX version 20.8.8
    Updated Date : 2022/05/18
    Updated By   : Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Change display date format in functions : 'Get-DeviceLog', 'Get-DeviceFullLog', 'Get-DeviceFullTechnicalLog', 'Get-Device', 'Get-DeviceFullTechnicalLog', 'Get-DeviceToken', 'Get-DeviceSummary', 'Get-DYNDNSClient', 'Get-HOSTS', 'Get-HOSTSME', 'Get-IPTVDiags', 'Get-LANAlerts', 'GET-PARENTALCONTROL', 'Get-ParentalControlScheduler', 'Get-SUMMARY', 'Get-UPNPIGDRules', 'Get-VOIPScheduler', 'Get-WANAutowan', 'Get-WANDiagsSessions', 'et-WIRELESSScheduler'
    Update       : Replace variable $ID by $Index and $log by $Line in functions : 'Get-DeviceLog', 'Get-DeviceFullLog', 'Get-DeviceFullTechnicalLog'
    Update       : Remove function 'Format-Date'
    
    Version 2.3 - BBOX version 20.8.8
    Updated Date : 2022/08/20
    Updated By   : Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : New variable : $global:TranscriptFileName
    Update       : Create json system configuration file : '.\Settings-Program.json'
    Update       : Create json user file : '.\Settings-Default-User.json'
    Update       : Add function : 'Get-JSONSettingsCurrentUserContent' and 'Get-JSONSettingsDefaultUserContent'
    Update       : Create json user file : '.\Settings-Current-User.json' Duplication from '.\Settings-Default-User.json' if not already exists
    Update       : Import json user file : '.\Settings-Current-User.json' if already exists
    Update       : Update password management from Password.txt file to Settings-Current-User.json
    Update       : Update function : 'Get-HostStatus' and 'Get-PortStatus' to update json user file : '.\Settings-Current-User.json'
    Update       : Update function : 'Get-ErrorCode'
    Update       : Update powershell requirements from -Version 5.0 to 5.1
    Update       : Update function : 'Switch-ExportFormat' and 'Switch-DisplayFormat' and 'Switch-OpenHTMLReport' to manage trigger user settings configuration
    Update       : Update File configuration '.\Settings-Default-User.json', '.\Settings-Default-User.json', '.\Settings-Current-User.json'
    Update       : Change function organization for better loading/run program in file : '.\BBOX-Module.psm1'
    Update       : Optimise 'Switch' function with 'Break' in files : '.\BBOX-Aministration.ps1' and '.\BBOX-Module.psm1'
    Update       : Change order checks in file : '.\BBOX-Aministration.ps1'
    Update       : Create 'regions' ([region]/[endregion]) to structure the code in files : '.\BBOX-Aministration.ps1' and '.\BBOX-Module.psm1'
    Update       : Update syntaxe for logs file and user console display
    Update       : Correct function : 'Get-APIRessourcesMap', remove double 'API/V1' syntaxe
    Update       : Correct function : 'Export-GlobalOutputData' to manage when '$FormatedData' is null or empty
    Update       : Add new function : 'Show-WindowsFormDialogBox' to display user messsage as dialogbox
    Update       : Add new function : 'Show-WindowsFormDialogBoxInput' to get user messsage as dialogbox input
    Update       : Add new function : 'Show-WindowsFormDialogBox2Choices' to get user choice as dialogbox press button among 2 choices
    Update       : Add new function : 'Show-WindowsFormDialogBox2ChoicesCancel' to get user choice as dialogbox press button among 2 choices with 'Cancel' option
    Update       : Add new function : 'Show-WindowsFormDialogBox3Choices' to get user choice as dialogbox press button among 3 choices
    Update       : Add new function : 'Show-WindowsFormDialogBox3ChoicesCancel' to get user choice as dialogbox press button among 3 choices with 'Cancel' option
    Update       : Update functions : 'Start-RefreshWIRELESSFrequencyNeighborhoodScan' and 'Get-PortStatus' and 'Get-HostStatus' and 'Get-ConnexionType' and 'Get-PhoneLineID' and 'Switch-OpenHTMLReport' and 'Switch-ExportFormat' and 'Switch-DisplayFormat' with new functions
    Update       : Update function : 'Connect-BBOX' to manage if wrong password enter to connect to BBox web interface
    Update       : Change default value for : '$global:TriggerExit' from '0' to '$null'
    Update       : Optimise syntaxe code for string of characters
    Update       : New Varaiable : '$global:TriggerDialogBox'
    Update       : Update functions : 'Get-HostStatus' and 'Get-PortStatus' to integrate Windows Form Dialog Box
    Update       : Replace ALL 'Write-Host' by 'Write-Log' function
    Update       : Display warning action for end-user with function : 'Show-WindowsFormDialogBox'
    Update       : Change Start Chromedriver and bbox authentification only if not already launched and if it is not a local program action
    Update       : Change '.\Settings-Program.json' file structure
    Update       : Update function : 'Get-BBoxInformation' to catch better API errors
    Update       : Update function : 'Stop-Program' to manage better Google Chrome and ChromeDriver closing
    Update       : Optimise function : 'Switch-Info' to remove old value don't used
    Update       : Change Windows Form position and size
    
    Version 2.4 - BBOX version 20.8.8
    Updated Date : 2022/09/23
    Updated By   : Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : #Requires -Version 7.0
    Update       : Add new function 'Import-CredentialManager' to manage credential in 'Windows Credential Manager'
    Update       : Install / import new module : 'TUN.CredentialManager'
    Update       : Add new function : 'Import-TUNCredentialManager'
    Update       : Add new 'links' : https://www.powershellgallery.com/packages/TUN.CredentialManager
    Update       : Requires to use PowerShell Version 7.0
    Update       : Add new functions : 'Remove-BBoxCredential', 'Show-BBoxCredential', 'Add-BBoxCredential' to manage BBOX Credential in 'Windows Credential Manager'
    Update       : Add PowerShell Script Admin Execution control
    Update       : Add new block to install / Import Powershell module : 'TUN.CredentialManager'
    Update       : switch position block 'Presentation'
    Update       : Update function : 'Stop-Program'
    Update       : update credentials setting in user json configuration files : '.\Ressources\Settings-Current-User.json' and '.\Ressources\Settings-Default-User.json'
    Update       : Update functions : 'Export-GlobalOutputData' and 'EmptyFormatedDATA'
    Update       : Change Windows Form position and size
    Update       : Optimise functions : 'Show-WindowsFormDialogBoxInput','Show-WindowsFormDialogBox2Choices','Show-WindowsFormDialogBox2ChoicesCancel','Show-WindowsFormDialogBox3Choices','Show-WindowsFormDialogBox3ChoicesCancel' to better manage the position boxes
    Update       : Update ChromeDriver version to : 104.0.5112.79, 105.0.5195.52, 106.0.5249.21
    Update       : Update function 'Show-BBoxCredential' to manage error when no password has been set to 'Windows Credential Manager'
    Update       : Update function 'Add-BBoxCredential' to display the password set to 'Windows Credential Manager'
    Update       : Update function 'Get-BackupList', add WindowsFormDialogBox when no backup file found
    
    Version 2.5 - BBOX version 20.8.8
    Updated Date : 2022/09/23
    Updated By   : Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Update json program file : '.\Settings-Program.json'
    Update       : Add new function 'Update-ChromeDriver' to manage ChromeDriver update

.LINKS
    
    https://api.bbox.fr/doc/
    https://api.bbox.fr/doc/apirouter/index.html
    https://chromedriver.chromium.org/
    https://mabbox.bytel.fr/
    https://mabbox.bytel.fr/api/v1
    http://winstonfassett.com/blog/2010/09/21/html-to-text-conversion-in-powershell/
    https://www.bbox-mag.fr/box/firmware/
    https://www.powershellgallery.com/packages/TUN.CredentialManager
    
#>

#region admin execution control

#$Script_Name = $MyInvocation.MyCommand.Name
#$Script = "$PSScriptRoot\$Script_Name"
#If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {Start-Process Pwsh " -ExecutionPolicy Bypass -File `"$Script`"" -Verb RunAs; Exit}

#endregion admin execution control

#region function

# Imported by module : '.\BBoxModule.psm1'

<#
    .SYNOPSIS
    Write-Log allow to written fonctional execution logs
    
    .DESCRIPTION
    Write log on the host console and a csv file
#>
function Write-Log {
    Param (
        [Parameter()]
        [ValidateSet('INFO','INFONO','VALUE','WARNING','ERROR','DEBUG')]
        $Type = 'INFO',
        [Parameter(Mandatory=$true)]
        $Message,
        [Parameter(Mandatory=$true)]
        $Name,
        [Parameter()]
        [switch]$NotDisplay,
        [Parameter()]
        $Logname = "$global:LogFolderPath\$global:LogFileName"
    )
    
    $logpath = $Logname + $(get-date -UFormat %Y%m%d).toString() + '.csv'
    
    # Create log object 
    $log = [pscustomobject] @{Date=(Get-Date -UFormat %Y%m%d_%H%M%S) ; Type=$type ; Name=$name ; Message=$Message  ; user= $(whoami) ; PID=$PID} 
    $log | Add-Member -Name ToString -MemberType ScriptMethod -value {$this.date + ' : ' + $this.type +' : ' +$this.name +' : ' + $this.Message} -Force 
    
    # Append to global journal
    [Object[]] $Global:journal += $log.toString()
    
    If (-not $NotDisplay) {
        
        Switch ($Type) {
            
            'INFO'    {Write-Host -Object "$Message" -ForegroundColor Cyan;Break}
            
            'INFONO'  {Write-Host -Object "$Message" -ForegroundColor Cyan -NoNewline;Break}
            
            'VALUE'   {Write-Host -Object "$Message" -ForegroundColor Green;Break}
            
            'WARNING' {Write-Host -Object "$Message" -ForegroundColor Yellow;Break}
            
            'ERROR'   {Write-Host -Object "$Message" -ForegroundColor Red;Break}
            
            'DEBUG'   {Write-Host -Object "$Message" -ForegroundColor Blue;Break}
        }
    }
    
    # Create or open Mutex
    Try {
        $mtx = [System.Threading.Mutex]::OpenExisting('Global\PegaseMutex')
    }
    Catch {
        $mtx = New-Object System.Threading.Mutex($false,'Global\PegaseMutex')
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
$global:LogFileName    = 'BBOX_Administration_Log-'
$global:LogFolderName  = 'Logs'
$global:LogFolderPath  = "$ScriptRootFolder\$global:LogFolderName"

# Transcript Logs
$global:TranscriptFileName = 'BBOX-Administration-Transcript-Log.txt'
$TranscriptFilePath = "$global:LogFolderPath\$global:TranscriptFileName"

# System Json Configuration files
$ProgramConfigurationFileSettings   = 'Settings-Program.json'
$RessourcesFolderName               = 'Ressources'
$RessourcesPath                     = "$ScriptRootFolder\$RessourcesFolderName"
$global:JSONSettingsProgramFilePath = "$RessourcesPath\$ProgramConfigurationFileSettings"

# Main Trigger
$global:TriggerExit = $Null
$global:TriggerDialogBox = $Null
$TriggerLANNetwork = $Null

# URL Settings for the ChromeDriver request
$UrlRoot    = $Null
$Port       = $Null
$UrlAuth    = $Null
$UrlHome    = $Null
$UrlToGo    = $Null


#endregion Main Variables

#region Start Program initialisation

Start-Transcript -Path $TranscriptFilePath -Append -Force -NoClobber
Write-Log -Type WARNING -Name 'Program initialisation - Start Program' -Message '#################################################### Initialisation #####################################################'
Write-Log -Type INFO -Name 'Program initialisation - Start Program' -Message 'Start Program initialisation'  -NotDisplay
Write-Log -Type INFONO -Name 'Program initialisation - Start Program' -Message 'Program loading ... : '

#endregion Start Program initialisation

#region Create logs folder

Write-Log -Type INFO -Name 'Program initialisation - Logs Folder Creation' -Message 'Start Logs Folder Creation'  -NotDisplay
$Null = New-Item -Path $ScriptRootFolder -Name $global:LogFolderName -ItemType Directory -Force -ErrorAction Stop
Write-Log -Type INFO -Name 'Program initialisation - Logs Folder Creation' -Message 'End Logs Folder Creation'  -NotDisplay

#endregion Create logs folder

#region Import System Json Configuration files

Write-Log -Type INFO -Name 'Program initialisation - Import JSON Settings Program' -Message 'Start Import JSON Settings Program' -NotDisplay
Write-Log -Type INFONO -Name 'Program initialisation - Import JSON Settings Program' -Message 'Import JSON Settings Program Status : ' -NotDisplay
Try {
    $global:JSONSettingsProgramContent = Get-Content -Path $global:JSONSettingsProgramFilePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    Write-Log -Type VALUE -Name 'Program initialisation - Import JSON Settings Program' -Message 'Success' -NotDisplay
}
Catch {
    Write-Log -Type WARNING -Name 'Program initialisation - Import JSON Settings Program' -Message "Failed, due to : $($_.ToString())"
    $global:JSONSettingsProgramContent = $Null
    $global:TriggerExit = 1
}
Write-Log -Type INFO -Name 'Program initialisation - Import JSON Settings Program' -Message 'End Import JSON Settings Program' -NotDisplay

#endregion Import System Json Configuration files

#region Load System Json Configuration files

Write-Log -Type INFO -Name 'Program initialisation - Load JSON Settings Program' -Message 'Start Load JSON Settings Program' -NotDisplay
Write-Log -Type INFO -Name 'Program initialisation - Load JSON Settings Program' -Message "JSON Settings Program file path : $global:JSONSettingsProgramFilePath" -NotDisplay
Write-Log -Type INFONO -Name 'Program initialisation - Load JSON Settings Program' -Message 'Load JSON Settings Program Status : ' -NotDisplay

If (($Null -eq $global:TriggerExit) -and ($Null -ne $global:JSONSettingsProgramContent)) {
    
    Try {
        $global:JSONSettingsDefaultUserFilePath = "$ScriptRootFolder\$RessourcesFolderName\" + $global:JSONSettingsProgramContent.UserConfigurationFile.DefaultFileName
        $global:JSONSettingsCurrentUserFilePath = "$ScriptRootFolder\$RessourcesFolderName\" + $global:JSONSettingsProgramContent.UserConfigurationFile.CurrentFileName

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
        $ChromeDownloadUrl                       = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDownloadUrl

        # APIName
        $APINameAvailable                      = $global:JSONSettingsProgramContent.APIName.Available
        $APINameExclusionsFull                 = $global:JSONSettingsProgramContent.APIName.Exclusions.Full
        $APINameExclusionsFull_Testing_Program = $global:JSONSettingsProgramContent.APIName.Exclusions.Full_Testing_Program
        $APINameScopeExclusionsFull            = $global:JSONSettingsProgramContent.APIName.Scope.Exclusions.Full
        
        # Actions
        $ActionsExclusionsScope   = $global:JSONSettingsProgramContent.Actions.Exclusions.Scope
        $ActionsExclusionsActions = $global:JSONSettingsProgramContent.Actions.Exclusions.Actions
        
        # BBox
        $APIVersion          = $global:JSONSettingsProgramContent.bbox.APIVersion
        $BBoxDns             = $global:JSONSettingsProgramContent.bbox.BBoxDns
        $BBoxUrlRemote       = $global:JSONSettingsProgramContent.bbox.BBoxUrlRemote
        $APIUrlDocumentation = $global:JSONSettingsProgramContent.bbox.APIUrlDocumentation
        
        # Various
        $Mail = $global:JSONSettingsProgramContent.various.mail        
        
        Write-Log -Type VALUE -Name 'Program initialisation - Load JSON Settings Program' -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Load JSON Settings Program' -Message "Failed, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
}
Else {
    Write-Log -Type WARNING -Name 'Program initialisation - Load JSON Settings Program' -Message "Failed, due to : $($_.ToString())"
    $global:TriggerExit = 1
}
Write-Log -Type INFO -Name 'Program initialisation - Load JSON Settings Program' -Message 'End Load JSON Settings Program' -NotDisplay

#endregion Load System Json Configuration files

#region Import Functions with Module : 'BBOX-Module.psm1'

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Powershell Module Importation' -Message 'Start Powershell Module Importation' -NotDisplay
    Write-Log -Type INFO -Name 'Program initialisation - Powershell Module Importation' -Message "Powershell Module Path : $BBOXModulePath" -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Powershell Module Importation' -Message 'Powershell Module Importation status : ' -NotDisplay
    
    Try {
        Remove-Module -Name BBOX-Module -ErrorAction SilentlyContinue
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program initialisation - Powershell Module Importation' -Message "Failed, Powershell Module $BBOXModulePath can't be removed, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Start-Sleep 1
    Try {
        Import-Module -Name $BBOXModulePath -ErrorAction Stop
        Write-Log -Type VALUE -Name 'Program initialisation - Powershell Module Importation' -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program initialisation - Powershell Module Importation' -Message "Failed, Powershell Module $BBOXModulePath can't be imported due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    
    Write-Log -Type INFO -Name 'Program initialisation - Powershell Module Importation' -Message 'End Powershell Module Importation' -NotDisplay
}

If ($Null -eq $global:TriggerExit) {

    $ModuleName = 'TUN.CredentialManager'
    Write-Log -Type INFO -Name 'Program initialisation - Powershell Module Importation' -Message 'Start Powershell Module Importation' -NotDisplay
    Write-Log -Type INFO -Name 'Program initialisation - Powershell Module Importation' -Message "Powershell Module Path : $ModuleName" -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Powershell Module Importation' -Message 'Powershell Module Importation status : ' -NotDisplay
    
    Try {
        Import-TUNCredentialManager -ModuleName $ModuleName -ErrorAction Stop
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program initialisation - Powershell Module Importation' -Message "Failed, Powershell Module $ModuleName can't be installed or imported, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name 'Program initialisation - Powershell Module Importation' -Message 'End Powershell Module Importation' -NotDisplay
}

#endregion Import Functions

#region Create folders/files if not yet existing

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Program Folders/Files check' -Message 'Start Program Folders/Files check' -NotDisplay
    
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
    
    Write-Log -Type INFO -Name 'Program initialisation - Program Folders/Files check' -Message 'End Program Folders/Files check' -NotDisplay
}

#endregion Create folders/files

#region Check if ressources folder exist

If ($Null -eq $global:TriggerExit) { 

    Write-Log -Type INFO -Name 'Program initialisation - Ressources Folder' -Message 'Start Folder Ressources Check' -NotDisplay
    Write-Log -Type INFO -Name 'Program initialisation - Ressources Folder' -Message "Ressources Folder Path : $RessourcesPath" -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Ressources Folder' -Message 'Ressources Folder State : ' -NotDisplay
    
    If (Test-Path -Path $RessourcesPath -ErrorAction Stop) {
    
        Write-Log -Type VALUE -Name 'Program initialisation - Ressources Folder' -Message 'Already Exist' -NotDisplay
    }
    Else {
        Write-Log -Type WARNING -Name 'Program initialisation - Ressources Folder' -Message 'Not found'
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name 'Program initialisation - Ressources Folder' -Message 'End Folder Ressources check' -NotDisplay
}

#endregion ressources folder

#region Import Actions available

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Referentiel Actions Availables Importation' -Message 'Start Referentiel Actions Availables Importation' -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Referentiel Actions Availables Importation' -Message "Importing Referentiel Actions Availables from : $APISummaryPath : " -NotDisplay
    
    Try {
        $Actions = Import-Csv -Path $APISummaryPath -Delimiter ';' -Encoding UTF8 -ErrorAction Stop
        Write-Log -Type VALUE -Name 'Program initialisation - Referentiel Actions Availables Importation' -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program initialisation - Referentiel Actions Availables Importation' -Message "Failed. Referentiel Actions can't be imported, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name 'Program initialisation - Referentiel Actions Availables Importation' -Message 'End Referentiel Actions Availables Importation' -NotDisplay
}

#endregion Import Actions

#region Check if Google Chrome is already install

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Google Chrome Installation' -Message 'Start Google Chrome Installation' -NotDisplay    
    Write-Log -Type INFONO -Name 'Program initialisation - Google Chrome Installation' -Message 'Google Chrome installation status : ' -NotDisplay
    
    Try {
        $ChromeVersion = (Get-ItemProperty $ChromeVersionRegistry -ErrorAction Stop).Version
        Write-Log -Type VALUE -Name 'Program initialisation - Google Chrome Installation' -Message 'Successful' -NotDisplay
        Write-Log -Type INFONO -Name 'Program initialisation - Google Chrome Version' -Message 'Current Google Chrome version : ' -NotDisplay
        Write-Log -Type VALUE -Name 'Program initialisation - Google Chrome Version' -Message $ChromeVersion -NotDisplay
        Write-Log -Type INFO -Name 'Program initialisation - Google Chrome Installation' -Message 'End Google Chrome Installation' -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Google Chrome Installation' -Message 'Not yet' -NotDisplay
        Write-Log -Type WARNING -Name 'Program initialisation - Google Chrome Installation' -Message 'Please install Google Chrome before to use this Program'
        Show-WindowsFormDialogBox -Title 'Program initialisation - Google Chrome Installation' -Message 'Please install Google Chrome before to use this Program' -WarnIcon
        Invoke-Item -Path $ChromeDownloadUrl  -ErrorAction Stop
        Write-Log -Type INFO -Name 'Program initialisation - Google Chrome Installation' -Message 'End Google Chrome Installation' -NotDisplay
        $global:TriggerExit = 1
    }
}

#endregion Google Chrome

#region Get Google Chrome binary Path

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Google Chrome Binaries' -Message 'Start Google Chrome Binaries' -NotDisplay    
    Write-Log -Type INFONO -Name 'Program initialisation - Google Chrome Binaries' -Message 'Google Chrome Binaries Path : ' -NotDisplay
    
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
        
        Write-Log -Type VALUE -Name 'Program initialisation - Google Chrome Binaries' -Message $ChromeBinaryPath -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Google Chrome Binaries' -Message "Failed, to find google chrome Binaries, due to $($_.Tostring())"
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name 'Program initialisation - Google Chrome Binaries' -Message 'End Google Chrome Installation' -NotDisplay    
}

#endregion Google Chrome binary Path

#region Chrome Version choice function chrome version installed

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Chrome Driver Version' -Message 'Start Chrome Driver version selection function Chrome Version installed on device' -NotDisplay   
    Try {
        $ChromeDriverVersion = Get-ChromeDriverVersion -ChromeVersion $ChromeVersion -ErrorAction Stop
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Chrome Driver Version' -Message "Failed, to define the correct ChromeDriverVersion, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name 'Program initialisation - Chrome Driver Version' -Message 'End Chrome Driver version selection function Chrome Version installed on device' -NotDisplay
}

#endregion Chrome Version choice

#region Update Chrome Driver version

If ($Null -eq $global:TriggerExit) {

    Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message 'Start update ChromeDriver' -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Update ChromeDriver' -Message 'ChromeDriver version Status : ' -NotDisplay
    
    If ($ChromeVersion -notmatch $ChromeDriverVersion) {
        
        Write-Log -Type WARNING -Name 'Program initialisation - Update ChromeDriver' -Message 'Need to be updated' -NotDisplay
        Start-ChromeDriver -ChromeBinaryPath $ChromeBinaryPath -ChromeDriverPath $ChromeDriverPath -ChromeDriverVersion $ChromeDriverVersion -LogsPath $global:LogFolderPath -ChromeDriverDefaultProfile $ChromeDriverDefaultProfile -ErrorAction Stop
        
        Write-Log -Type INFONO -Name 'Program initialisation - Update ChromeDriver' -Message 'ChromeDriver update version Status : ' -NotDisplay
        Update-ChromeDriver -ChromeDriverVersion $ChromeDriverVersion -ChromeDriverPath $ChromeDriverPath -ErrorAction Stop
    }
    Else {
        Write-Log -Type VALUE -Name 'Program initialisation - Update ChromeDriver' -Message 'Updated' -NotDisplay
    }
}

Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message 'End update ChromeDriver' -NotDisplay

#endregion Chrome Driver version

#region End Program Initialisation

If ($Null -eq $global:TriggerExit) {
    Write-Log -Type VALUE -Name 'Program initialisation - Start Program' -Message 'Finished without errors'
}
Else{
    Write-Log -Type WARNING -Name "Program initialisation - Start Program' -Message 'Finished with errors : $($_.ToString())"
    Stop-Program -ErrorAction Stop
}

Write-Log -Type INFO -Name 'Program initialisation - Start Program' -Message 'End Program initialisation' -NotDisplay
Write-Log -Type WARNING -Name 'Program initialisation - Start Program' -Message '#################################################### Initialisation #####################################################'

#endregion End Program Initialisation

#region Program Presentation

Write-Host '##################################################### Description ######################################################' -ForegroundColor Yellow
Write-Host 'This program is only available in English'
Write-Host 'It allows you to get, modify and delete information on Bouygues Telecoms BBOX'
Write-Host 'It displays advanced information that you will not see through the classic web interface of your BBOX'
Write-Host 'And this via a local or remote connection (Provided that you have activated the remote BBOX management => ' -NoNewline
Write-Host "$BBoxUrlRemote" -ForegroundColor Green -NoNewline
Write-Host ')'
Write-Host 'The result can be displayed in HTML format or in table form (Gridview)'
Write-Host "The result can be exported in `" .csv (.csv) `" or `" .JSON (.JSON) `" format"
Write-Host 'The only limitation of this program is related to the requests available via the API installed on the target BBOX according to the model and the firmware version of this one'
Write-Host 'When displaying the result, some information may not be displayed, or may be missing :'
Write-Host '- Either its an oversight on my part in the context of the development, and I apologize in advance'
Write-Host '- Either this one is still under development'
Write-Host '- Either this information is optional and only appears in the presence of certain bbox models :'
Write-Host '-- BBOX models'
Write-Host '-- Firmware version'
Write-Host '-- Available features'
Write-Host '-- Connection mode (Local / Remote)'
Write-Host 'This program requires the installation of PowerShell 5.1 minimum and Google Chrome'
Write-Host 'For more information, please consult : ' -NoNewline
Write-Host "$APIUrlDocumentation" -ForegroundColor Green
Write-Host 'Be carefull, this program is reserved for an advanced use of the BBOX settings and is aimed at an informed audience !' -ForegroundColor Yellow
Write-Host 'Any improper handling risks causing partial or even total malfunction of your BBOX, rendering it unusable. You are Warned !' -ForegroundColor Yellow
Write-Host 'Therefore, you use this program at your own risks, I cant be responsible if you dont use it in the correct environnement' -ForegroundColor Red
Write-Host 'For any questions or additional requests, contact me to this email address : ' -NoNewline
Write-Host "$Mail" -ForegroundColor Green
Write-Host "Tested environnement list : "
Write-Host "- $TestedEnvironnementPath" -ForegroundColor Green
Write-Host 'Logs files location : '
Write-Host "- $global:LogFolderPath\$global:LogFileName*.csv" -ForegroundColor Green
Write-Host "- $TranscriptFilePath" -ForegroundColor Green
Write-Host 'Please make sure logs files is closed before continue' -ForegroundColor Yellow

<#
Write-Host 'Last success tested environnement :'
Write-Log -Type INFO -Name 'Program presentation - Get tested environnements' -Message 'Start tested environnements' -NotDisplay
Write-Log -Type INFO -Name 'Program presentation - Get tested environnements' -Message 'Tested environnements importation status $TestedEnvironnementPath :' -NotDisplay
Try {
    $TestedEnvironnement = Import-Csv -Path $TestedEnvironnementPath -Delimiter ';' -ErrorAction Stop
    $TestedEnvironnement[0] | Format-List
    Write-Log -Type VALUE -Name 'Program presentation - Get tested environnements' -Message 'Success' -NotDisplay
}
Catch {
    Write-Log -Type ERROR -Name 'Program presentation - Get tested environnements' -Message "Failed, to get tested environnements, due to : $($_.ToString())"
    $global:TriggerExit = 1
}
Write-Host 'For others successful tested environnement, please consult : ' -NoNewline
Write-Host "$TestedEnvironnementPath" -ForegroundColor Green
Write-Log -Type INFO -Name 'Program presentation - Get tested environnements' -Message 'End tested environnements' -NotDisplay
#>
Write-Host '##################################################### Description ######################################################' -ForegroundColor Yellow
Pause

#endregion Program Presentation

#region Import User Json Configuration files

If (($Null -eq $global:TriggerExit) -and (Test-Path -Path $global:JSONSettingsCurrentUserFilePath)) {
    
    Get-JSONSettingsCurrentUserContent
}
Else {
    Write-Log -Type INFO -Name 'Program initialisation - Json Current User Settings Creation' -Message 'Start Json Current User Settings Creation' -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Json Current User Settings Creation' -Message 'Json Current User Settings Creation Status : ' -NotDisplay
    Try {
        Copy-Item -Path $global:JSONSettingsDefaultUserFilePath -Destination $global:JSONSettingsCurrentUserFilePath -Force
        Start-Sleep -Seconds 2
        Write-Log -Type VALUE -Name 'Program initialisation - Json Current User Settings Creation' -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Json Current User Settings Creation' -Message "Failed, to create Json Current User Settings file, due to : $($_.ToString())"
        Stop-Program -ErrorAction Stop
    }
    Write-Log -Type INFO -Name 'Program initialisation - Json Current User Settings Creation' -Message 'End Json Current User Settings Creation' -NotDisplay

    If (Test-Path -Path $global:JSONSettingsCurrentUserFilePath) {

        Get-JSONSettingsCurrentUserContent
    }
    Elseif (Test-Path -Path $global:JSONSettingsDefaultUserFilePath) {
        
        Get-JSONSettingsDefaultUserContent
    }
    Else {
        Write-Log -Type WARNING -Name 'Program initialisation - Json Current User Settings Importation' -Message "Failed, to find find any user settings configuration file, due to : $($_.ToString())"
        Write-Log -Type INFO -Name 'Program initialisation - Json Current User Settings Importation' -Message 'End Json Current User Settings Importation' -NotDisplay
        Stop-Program -ErrorAction Stop
    }
}
#endregion Import User Json Configuration files

#region Check if password already exist in Windows Credential Manager

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program run - Password Status' -Message 'Start Password Status' -NotDisplay
    Write-Log -Type INFONO -Name 'Program run - Password Status' -Message 'Password Status : ' -NotDisplay

    If ($null -eq ($(Get-StoredCredential -Target $global:Target -ErrorAction SilentlyContinue | Select-Object -Property Password -ErrorAction SilentlyContinue).password | ConvertFrom-SecureString -AsPlainText -ErrorAction SilentlyContinue)) {
        
        Write-Log -Type WARNING -Name 'Program run - Password Status' -Message 'Not yet set' -NotDisplay
        Try {
            Add-BBoxCredential -ErrorAction Stop
        }
        Catch {
            Write-Log -Type WARNING -Name 'Program run - Password Status' -Message "Password can't be set, du to : $($_.ToString())" -NotDisplay
            Stop-Program -ErrorAction Stop
        }
    }
    Else {
        Write-Log -Type VALUE -Name 'Program run - Password Status' -Message 'Already Set' -NotDisplay
    }
    Write-Log -Type INFO -Name 'Program run - Password Status' -Message 'End Password Status' -NotDisplay
}

#endregion Check if password already exist in Windows Credential Manager

#region Check if user connect on the correct LAN Network

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program run - Network connection' -Message 'Start Check BBOX LAN network' -NotDisplay
    Write-Log -Type INFONO -Name 'Program run - Network connection' -Message 'Checking BBOX LAN network : ' -NotDisplay
    
    Try {
        $DnsName = Resolve-DnsName -Name $BBoxDns -Type A -DnsOnly -ErrorAction Stop
        Write-Log -Type VALUE -Name 'Program run - Network connection' -Message 'Connected to your Local BBOX Network' -NotDisplay
        Write-Log -Type INFONO -Name 'Program run - Network connection' -Message 'BBOX IP Address : ' -NotDisplay
        Write-Log -Type VALUE -Name 'Program run - Network connection' -Message $($DnsName.Address) -NotDisplay
        Write-Log -Type INFONO -Name 'Program run - Network connection' -Message 'Recommanded connection : ' -NotDisplay
        Write-Log -Type VALUE -Name 'Program run - Network connection' -Message 'Localy' -NotDisplay
        $TriggerLANNetwork = 1
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program run - Network connection' -Message 'Failed' -NotDisplay
        Write-Log -Type ERROR -Name 'Program run - Network connection' -Message "Unable to resolve $BBoxDns, due to : $($_.ToString())" -NotDisplay
        Show-WindowsFormDialogBox -Title 'Program run - Network connection' -Message "It seems you are not connected to your Local BBOX Network`n`n- If you are connected on your local network, make sure you are connected on the BBOX's Wifi or ethernet network`n- If you use a intermediary router between your computer and the BBOX router, it will not working" -WarnIcon | Out-Null
        Write-Log -Type INFONO -Name 'Program run - Network connection' -Message 'Recommanded connection : ' -NotDisplay
        Write-Log -Type VALUE -Name 'Program run - Network connection' -Message 'Remotely' -NotDisplay
        $TriggerLANNetwork = 0
    }
    Write-Log -Type INFO -Name 'Program run - Network connection' -Message 'End Check BBOX LAN network' -NotDisplay
}

#endregion Check if user connect on the correct LAN Network

#region Ask to the user how he want to connect to the BBOX

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message 'Start Connexion Type' -NotDisplay
    $ConnexionType = Get-ConnexionType -TriggerLANNetwork $TriggerLANNetwork -ErrorAction Stop
    Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message 'End Connexion Type' -NotDisplay
}

#endregion Ask to the user how he want to connect to the BBOX

#region Set Bbox connexion settings regarding user selection

If ($Null -eq $global:TriggerExit) {
    
    Switch ($ConnexionType[0]) {
        
        L   {$UrlRoot = "https://$BBoxDns/$APIVersion"
             $UrlAuth = "https://$BBoxDns/login.html"
             $UrlHome = "https://$BBoxDns/index.html"
             Break
            }
        
        R   {Write-Log -Type INFO -Name 'Program run - Check Host' -Message 'Start Check Host' -NotDisplay
             $DYNDNS = Get-HostStatus
             Write-Log -Type INFO -Name 'Program run - Check Host' -Message 'End Check Host' -NotDisplay
             Write-Log -Type INFO -Name 'Program run - Check Port' -Message 'Start Check Port' -NotDisplay
             $Port = Get-PortStatus -UrlRoot $DYNDNS
             Write-Log -Type INFO -Name 'Program run - Check Port' -Message 'End Check Port' -NotDisplay
             $UrlRoot = "https://$DYNDNS`:$Port/$APIVersion"
             $UrlAuth = "https://$DYNDNS`:$Port/login.html"
             $UrlHome = "https://$DYNDNS`:$Port/index.html"
             Break
            }
        
        Q   {$global:TriggerExit = 1;Break}
    }
    
    If ($ConnexionType[0] -ne 'Q') {
        
        Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message "Root BBox Url : $UrlRoot"-NotDisplay
        Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message "Login BBox Url : $UrlAuth" -NotDisplay
        Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message "Home BBox Url : $UrlHome" -NotDisplay

        If ($Port) {
            Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message "Remote BBox Port : $Port" -NotDisplay
        }
        Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message 'End Connexion Type' -NotDisplay
    }
}

#endregion Set Bbox connexion settings regarding user selection

#region Get Already Active Google Chrome Process

If ($Null -eq $global:TriggerExit) {
    $Global:ActiveChromeBefore = @(Get-Process [c]hrome -ErrorAction SilentlyContinue | ForEach-Object {$_.Id})
}

#endregion Get Already Active Google Chrome Process

#region process

$global:ChromeDriver = $Null
While ($Null -eq $global:TriggerExit) {
    
    # Ask user action he wants to do (Get/PUT/POST/REMOVE)
    Write-Log -Type INFO -Name 'Program run - Action asked' -Message 'Please select an action in the list'
    $Action = $Actions | Where-Object {$_.Available -eq 'Yes'} | Out-GridView -Title 'Please select an action in the list :' -OutputMode Single -ErrorAction Stop
    
    If ($Null -ne $Action) {
        
        # Set value to variables
        $Label = $Action.label
        $APIName = $Action.APIName
        $Description = $Action.Description
        $ReportType = $Action.ReportType
        $ExportFile = $Action.ExportFile
        #$Scope = $Action.Scope
        $ActionProgram = $Action.Action
        
        Write-Log -Type INFONO -Name 'Program run - Action asked' -Message 'Selected action : '
        Write-Log -Type VALUE -Name 'Program run - Action asked' -Message $Description

        If ((-not $global:ChromeDriver) -and ($ActionProgram -notmatch $ActionsExclusionsActions)) {
            
            #region Start in Background chromeDriver
            
            Write-Log -Type INFO -Name 'Program run - ChromeDriver Launch' -Message 'Start ChromeDriver as backgroung process' -NotDisplay
            Write-Log -Type INFONO -Name 'Program run - ChromeDriver Launch' -Message 'Starting ChromeDriver as backgroung process : ' -NotDisplay
            
            Try {
                Start-ChromeDriver -ChromeBinaryPath $ChromeBinaryPath -ChromeDriverPath $ChromeDriverPath -ChromeDriverVersion $ChromeDriverVersion -DownloadPath $JournalPath -LogsPath $global:LogFolderPath -ChromeDriverDefaultProfile $ChromeDriverDefaultProfile -ErrorAction Stop
                Write-Log -Type VALUE -Name 'Program run - ChromeDriver Launch' -Message 'Started' -NotDisplay
            }
            Catch {
                Write-Log -Type ERROR -Name 'Program run - ChromeDriver Launch' -Message "Failed. ChromeDriver can't be started, due to : $($_.ToString())"
                Stop-Program -ErrorAction Stop
            }
            Write-Log -Type INFO -Name 'Program run - ChromeDriver Launch' -Message 'End ChromeDriver as backgroung process' -NotDisplay
            
            #endregion Start in Background chromeDriver
            
            #region Start BBox Authentification
            
            Write-Log -Type INFONO -Name 'Program run - ChromeDriver Authentification' -Message 'Start BBOX Authentification' -NotDisplay
            Write-Log -Type INFONO -Name 'Program run - ChromeDriver Authentification' -Message 'Starting BBOX Authentification : ' -NotDisplay
            
            Try {
                $Password = $(Get-StoredCredential -Target $global:Target | Select-Object -Property Password).password | ConvertFrom-SecureString -AsPlainText
                Connect-BBOX -UrlAuth $UrlAuth -UrlHome $UrlHome -Password $Password -ErrorAction Stop
                Write-Log -Type VALUE -Name 'Program run - ChromeDriver Authentification' -Message 'Authentificated' -NotDisplay
                Clear-Variable -Name Password
            }
            Catch {
                Write-Log -Type ERROR -Name 'Program run - ChromeDriver Authentification' -Message "Failed, Authentification can't be done, due to : $($_.ToString())"
                Stop-Program -ErrorAction Stop
            }
            Write-Log -Type INFONO -Name 'Program run - ChromeDriver Authentification' -Message 'End BBOX Authentification' -NotDisplay

            #endregion Start BBox Authentification
        }
        
        # Get data
        Switch ($APIName) {
            
            'Full'                 {$APISName = ($Actions | Where-Object {(($_.Available -eq $APINameAvailable) -and ($_.APIName -notmatch $APINameExclusionsFull) -and ($_.Scope -notmatch $ActionsExclusionsScope) -and ($_.Action -notmatch $APINameScopeExclusionsFull))}).APIName | Select-Object -Unique
                                    $FormatedData = Export-BBoxConfiguration -APISName $APISName -UrlRoot $UrlRoot -OutputFolder $JsonBboxconfigPath
                                    Break
                                   }
            
            'Full_Testing_Program' {$APISName = $Actions | Where-Object {(($_.Available -eq $APINameAvailable) -and ($_.APIName -notmatch $APINameExclusionsFull_Testing_Program))} | Select-Object *
                                    $FormatedData = Export-BBoxConfigTestingProgram -APISName $APISName -UrlRoot $UrlRoot -OutputFolder $JsonBboxconfigPath -Mail $Mail -JournalPath $JournalPath
                                    Break
                                   }
            
            Default                {$UrlToGo = "$UrlRoot/$APIName"
                                    $FormatedData =  Switch-Info -Label $Label -UrlToGo $UrlToGo -APIName $APIName -Mail $Mail -JournalPath $JournalPath -ErrorAction Continue -WarningAction Continue
                                    Export-GlobalOutputData -FormatedData $FormatedData -APIName $APIName -ExportCSVPath $ExportCSVPath -ExportJSONPath $ExportJSONPath -ExportFile $ExportFile -Description $Description -ReportType $ReportType -ReportPath $ReportPath
                                    Break
                                   }
        }
    }
    
    Else {
        Write-Log -Type INFONO -Name 'Program run - Action asked' -Message 'Action chosen : '
        Write-Log -Type VALUE -Name 'Program run - Action asked' -Message 'Cancelled by user'
        $global:TriggerExit = 1
        Stop-Program -ErrorAction Stop
    }
}

#endregion process

#region Close Program

Stop-Program -ErrorAction Stop

#endregion Close Programm
