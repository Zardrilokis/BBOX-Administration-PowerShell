#Requires -Version 7.0

<#
.SYNOPSIS
    
   Get / Set / Add BBox informations.
    
.DESCRIPTION
    
   GET/PUT/POST/DELETE/OPTION BBox informations by Web request from ChromeDriver.
   Collect, Modify, Remove, BBox information using Bytel API Web request, with PowerShell script.
    
.INPUTS
    
    .\BBox-Aministration.ps1
    .\BBox-Module.psm1
    .\Settings-Default-User.json
    .\Settings-Current-User.json
    .\Settings-Program.json
    Web url BBox content
    BBox Rest API
    Hand User actions
    Windows Credential Manager
    
.OUTPUTS
    
    Export-HTMLReport   -DataReported $FormatedData -ReportTitle "BBox Configuration Report - $APIName" -ReportType $ReportType -ReportPath $ReportPath -ReportFileName $Exportfile -HTMLTitle "BBox Configuration Report" -ReportPrecontent $APIName -Description $Description
    Out-GridviewDisplay -FormatedData $FormatedData -APIName $APIName -Description $Description
    Export-toCSV        -FormatedData $FormatedData -APIName $APIName -ExportCSVPath $ExportCSVPath -Exportfile $Exportfile
    Export-toJSON       -FormatedData $FormatedData -APIName $APIName -JsonBBoxconfigPath $ExportJSONPath -Exportfile $Exportfile
    Windows Dialog form boxes
    PowerShell Host Console
    .\Logs\BBox_Administration_Log-Date.csv
    .\BBox-Administration-Transcript-Log-Date.log
    
.EXAMPLE

    cd "$Path" where $Path is the directory path where store the program
    .\BBox-Administration.ps1

.NOTES
    
    Creation Date : 2020/04/30
    Author : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    
    Version 1.0
    Updated Date : 2022/05/15
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Powershell script creation
    Update       : Add module : '.\BBox-Module.psm1'
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
    Update       : Reorganize BBox-Module.psm1 to more clarify
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
    Update       : Correct wifi scan when use remote BBox connexion, function 'Start-RefreshWIRELESSFrequencyNeighborhoodScan'
    Update       : Correct Active Host session by host, function 'Get-WANDAASH'
    Update       : Modify Display date format for HTML report
    Update       : Add new function : 'Get-HOSTSPAUTH' => Get HOSTS PAUTH Information
    Update       : Add new function : 'Format-Date' => To format the custom date to the standard one / Replace in functions in '.\BBox-Module.psm1'
    Update       : Add new function : 'Remove-FolderContent' => To remove export folder content Add in BBox-Module.psm1
    Update       : Add new requests in file : '.\Ressources\API-Summary.csv' => Remove-FCLogs / Remove-FCExportCSV / Remove-FCExportJSON / Remove-FCJournal / Remove-FCJBC / Remove-FCReport
    Update       : Add 3 last Chrome Drivers versions : 93.0.4577.15 / 92.0.4515.43 / 91.0.4472.101
    Update       : Modify function : 'Get-DeviceToken' in '.\BBox-Module.psm1'
    Update       : Add new properties in existing functions
    
    Version 2.0
    Updated Date : 2022/01/13
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Add 2 new functions : 'Switch-DisplayFormat' and 'Switch-ExportFormat' in '.\BBox-Module.psm1'
    Update       : Add new requests in file : '.\Ressources\API-Summary.csv' => Switch-DisplayFormat / Switch-ExportFormat
    Update       : Add new function : 'EmptyFormatedDATA' in '.\BBox-Module.psm1'
    Update       : Add new logs informations
    Update       : Correct Syntaxt
    Update       : Correct Program Sequence order
    Update       : Add new functions : 'Format-DisplayResult' and 'Format-ExportResult'
    Update       : Add Varible : '$logFileName' and '$FormatedDataExclusion'
    Update       : Rename variable : '$Info' and function property '-Info' to '$Label' and 'Label' in '.\BBox-Module.psm1' and '.\BBox-Administration.ps1'
    Update       : Rename variable : '$Pages' and function property '-Pages' to '$APIsName' and 'APIsName' in '.\BBox-Administration.ps1'
    Update       : Rename variable : '$Page' and function property '-Page' to '$APIName' and 'APIName'
    Update       : Add new function : 'Stop-Program' in '.\BBox-Module.psm1'
    Update       : Update logs file content
    Update       : Add Chrome Driver Log Path in Chrome Driver Option in function : 'Start-ChromeDriver'
    Update       : Add Transcript logs file
    Update       : Change Google Chrome installation path detection
    Update       : Correct bug with HTML Report in function 'GET-DYNDNSPL' (Missing first line to display)
    Update       : Disable All Extentions at chrome Driver startup in function : 'Start-ChromeDriver'
    Update       : Change common footer in HTML Report
    Update       : Modify Header title from 'Record' to 'Record Type' in function : 'Get-DYNDNSClient'
    Update       : Correct bug in function 'Get-DYNDNS' (No data get after request)
    Update       : Modify remember check remote BBox connection only if remote instead of both.
    Update       : Modify comments if BBox dns not responding when program analyse your network connection.
    Update       : Modify comment when program quit (System / User)
    Update       : Change function's name from 'Get-WPS' to 'Get-WIRELESSWPS'
    Update       : Correct bug in function : 'Get-WIRELESSWPS' (Missing data to collect)
    Update       : Add date in file name export/report
    Update       : Add dynamic folder path in function : 'Export-BBoxConfiguration' => modify also function : 'Switch-Info'
    Update       : Correct Log file Name display when program closing
    Update       : Modify functions : 'Test-FilePath' and 'Test-FolderPath'
    Update       : Change 'Get-BBoxJournal' function logic
    Update       : Add new function : 'Get-CPLDeviceList' in module : '.\BBox-Module.psm1'
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
    
    Version 2.1 - BBox version 20.8.6
    Updated Date : 2022/02/16
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Update logs files / Correct missing information in functions from BBox-Module.psm1
    Update       : Correct Switch $APIName for 'Default' way
    Update       : Correct Grammatical Syntaxe
    Update       : Change order code in function : 'Start-RefreshWIRELESSFrequencyNeighborhoodScan'
    Update       : Simplify paramerters in functions : 'Export-BBoxConfiguration', 'Export-BBoxConfigTestingProgram', 'Switch-Info', 'Get-WIRELESSFrequencyNeighborhoodScan'
    Update       : Correct data format in function : 'Get-WIRELESSFrequencyNeighborhoodScanID'
    Update       : Optimise code logic to manage Local / remote connection with web uri
    Update       : Remove function : 'Switch-ConnectionType' in module : '.\BBox-Module.psm1'
    Update       : Add new function : 'Get-PasswordRecoveryVerify' in module : '.\BBox-Module.psm1'
    Update       : Add new information in function : 'Get-FIREWALLPingResponder'
    Update       : Correct SolvedTime information in function : 'Get-LANAlerts'
    Update       : Rename function : 'Get-NOTIFICATION' to 'Get-NOTIFICATIONConfig'
    Update       : Add New informations (Events/Contacts) in function : 'Get-NOTIFICATIONConfig'
    Update       : Add 3 New functions : 'Get-NOTIFICATIONConfigAlerts', 'Get-NOTIFICATIONConfigContacts', 'Get-NOTIFICATIONConfigEvents' in module : '.\BBox-Module.psm1'
    Update       : Correct some headers/values in fonctions in module : '.\BBox-Module.psm1'
    Update       : Correct function 'Get-VOIPFullCallLogLineX' in module : '.\BBox-Module.psm1'
    Update       : Add function 'Export-GlobalOutputData' in module : '.\BBox-Module.psm1'
    Update       : BBox in version 20.8.6
    Update       : Add function 'Get-WANSFF' in module : '.\BBox-Module.psm1'
    Update       : Add function 'Get-WIRELESSVideoBridgeSetTopBoxes' and modify 'Get-Status' in module : '.\BBox-Module.psm1'
    Update       : Add function 'Get-WIRELESSVideoBridgeRepeaters' in module : '.\BBox-Module.psm1'

    Version 2.2 - BBox version 20.8.8
    Updated Date : 2022/05/18
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Change display date format in functions : 'Get-DeviceLog', 'Get-DeviceFullLog', 'Get-DeviceFullTechnicalLog', 'Get-Device', 'Get-DeviceFullTechnicalLog', 'Get-DeviceToken', 'Get-DeviceSummary', 'Get-DYNDNSClient', 'Get-HOSTS', 'Get-HOSTSME', 'Get-IPTVDiags', 'Get-LANAlerts', 'GET-PARENTALCONTROL', 'Get-ParentalControlScheduler', 'Get-SUMMARY', 'Get-UPNPIGDRules', 'Get-VOIPScheduler', 'Get-WANAutowan', 'Get-WANDiagsSessions', 'et-WIRELESSScheduler'
    Update       : Replace variable $ID by $Index and $log by $Line in functions : 'Get-DeviceLog', 'Get-DeviceFullLog', 'Get-DeviceFullTechnicalLog'
    Update       : Remove function 'Format-Date'
    
    Version 2.3 - BBox version 20.8.8
    Updated Date : 2022/08/20
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
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
    Update       : Change function organization for better loading/run program in file : '.\BBox-Module.psm1'
    Update       : Optimise 'Switch' function with 'Break' in files : '.\BBox-Aministration.ps1' and '.\BBox-Module.psm1'
    Update       : Change order checks in file : '.\BBox-Aministration.ps1'
    Update       : Create 'regions' ([region]/[endregion]) to structure the code in files : '.\BBox-Aministration.ps1' and '.\BBox-Module.psm1'
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
    Update       : Update function : 'Connect-BBox' to manage if wrong password enter to connect to BBox web interface
    Update       : Change default value for : '$global:TriggerExit' from '0' to '$null'
    Update       : Optimise syntaxe code for string of characters
    Update       : New Varaiable : '$global:TriggerDialogBox' to manage if DialogBox need to be display or not
    Update       : Update functions : 'Get-HostStatus' and 'Get-PortStatus' to integrate Windows Form Dialog Box
    Update       : Replace ALL 'Write-Host' by 'Write-Log' function
    Update       : Display warning action for end-user with function : 'Show-WindowsFormDialogBox'
    Update       : Change Start Chromedriver and BBox authentification only if not already launched and if it is not a local program action
    Update       : Change '.\Settings-Program.json' file structure
    Update       : Update function : 'Get-BBoxInformation' to catch better API errors
    Update       : Update function : 'Stop-Program' to manage better Google Chrome and ChromeDriver closing
    Update       : Optimise function : 'Switch-Info' to remove old value don't used
    Update       : Change Windows Form position and size
    
    Version 2.4 - BBox version 20.8.8
    Updated Date : 2022/09/23
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : #Requires -Version 7.0
    Update       : Add new function 'Import-CredentialManager' to manage credential in 'Windows Credential Manager'
    Update       : Install / import new module : 'TUN.CredentialManager'
    Update       : Add new function : 'Import-TUNCredentialManager'
    Update       : Add new 'links' : https://www.powershellgallery.com/packages/TUN.CredentialManager
    Update       : Requires to use PowerShell Version 7.0
    Update       : Add new functions : 'Remove-BBoxCredential', 'Show-BBoxCredential', 'Add-BBoxCredential' to manage BBox Credential in 'Windows Credential Manager'
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
    
    Version 2.5 - BBox version 20.8.8
    Updated Date : 2022/09/27
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Update json program file : '.\Settings-Program.json'
    Update       : Add new function 'Update-ChromeDriver' to manage ChromeDriver update
    Update       : Add new parameter in function : 'Get-ChromeDriverVersion' => -ChromeDriverPath
    Update       : Update defaut chrome driver to version : 106.0.5249.21
    
    Version 2.6 - BBox version 22.3.12
    Updated Date : 2023/02/20
    Update       : Update program to be conmpabible with : BBox version 22.3.12
    Update       : Add new function : 'Get-WIRELESSFastScanMe'
    Update       : Modify function : 'Get-APIRessourcesMap', correct field : 'API url' with the complete URL
    Update       : Update File configuration : '.\Settings-Default-User.json', '.\Settings-Default-User.json', '.\Settings-Current-User.json'
    Update       : Update File : '.\API-Summary.csv'
    Update       : Update propose to user to re-use or not the existing stored password or define a new one
    Update       : Add new function : 'Switch-OpenExportFolder'
    Update       : Update function : 'Switch-Info', 'Export-toCSV', 'Export-toJSON', 'Export-BBoxConfiguration', 'Export-BBoxConfigTestingProgram'
    Update       : Update 'Export-*' function to open the output folder where data were exported
    Update       : update setting in json configuration files : '.\Ressources\Settings-Current-User.json' and '.\Ressources\Settings-Default-User.json'
    Update       : Update File : '.\API-Summary.csv'
    Update       : Hide/Reduce chrome and chromedriver Window
    Update       : Update syntaxe in function : 'Get-BackupList'
    Update       : Use Resolve-DnsName function to resole HostName from IP address
    Update       : Correct some display bug in functions when data has been exported
    Update       : Manage if BBox authentification is needed or not, depending of BBox connection (Local/Remote)
    Update       : Add region to stop and update Google Chrome with winget cmlt
    Update       : Add new function : 'Reset-CurrentUserProgramConfiguration' to reset user configuration during program runnning
    Update       : Correct display syntaxe when output folders opened
    Update       : Change order 'Update Chrome Driver' and 'Update Google Chrome' and the control between the 2 versions
    Update       : Correct 'BBoxUrlFirewall' setting in function : 'Get-HostStatus' and 'Get-PortStatus'
    Update       : Debug function : 'Get-PortStatus'
    Update       : Debug function : Switch-OpenExportFolder

    Version 2.7 - BBox version 22.3.22
    Updated Date : 2023/05/30
    Update       : Update function : 'Get-WANIP' - Add Resolution IPV6 dns servers
    Update       : Create function : 'Get-WIRELESSSTANDARD' - Get Wireless standard available configuration
    Update       : Update function : 'Get-WIRELESSACL' - Add parameter 'Rules Count'
    Update       : Update functions : 'Get-WANAutowan' and 'Get-WIRELESSRepeater'
    Update       : Update functions : 'Get-HOSTS' and 'Get-HOSTSME' => correct IPV6 address format
    Update       : Create function : 'Get-LastSeenDate' - Modify $(Get-Date).AddSeconds(-X) where X is the time in seconds
    Update       : Create function : 'Edit-Date' - Add to rewrite date format to human readable
    Update       : Remove function : 'Get-Airties' -  Depreciated
    Update       : Update program to be compatible with : BBox version 22.3.16
    Update       : Update function : 'Export-BBoxConfiguration' - Add output in csv in // of Json
    Update       : Remove function : 'Get-WIRELESSFastScanMe' - Depreciated since BBox version 22.3.16
    Update       : Change/switch some command lines in block : 'Update Google Chrome version'
    Update       : Update function : 'Export-BBoxConfiguration' - Update Filter
    Update       : Update function : 'Write-Log' - Change Log disposition for better reading
    Update       : Update function : 'Get-HOSTSME' - Display message when no informations found
    Update       : Update 'Settings-Program.json' - Add 'Sleep' part
    Update       : Update function : 'Import-TUNCredentialManager' and 'Update-ChromeDriver' and 'Start-RefreshWIRELESSFrequencyNeighborhoodScan'
    Update       : Add function : 'Get-ChromeDriverVersionBeforeUpdate' to help to check existing chrome driver version
    Update       : Update defaut chrome driver to version : 112.0.5615.49
    Update       : Update functions : 'Get-DeviceLog' and 'Get-DeviceFullLog' and 'Get-DeviceFullTechnicalLog' - Add new entries not yet managed (LAN_BAD_SUBNET,LAN_DUPLICATE_IP)
    Update       : Update function : 'Get-NOTIFICATIONConfigEvents' - Add new headers : Index,Type,Scope,ShortName
    Update       : Update function : 'Get-NOTIFICATIONConfig' - Change Headers
    Update       : Rename functions : 'Get-NOTIFICATIONConfigAlerts' to 'Get-NOTIFICATIONAlerts' and 'Get-NOTIFICATIONConfigContacts' to 'Get-NOTIFICATIONContacts' and 'Get-NOTIFICATIONConfigEvents' to 'Get-NOTIFICATIONEvents'
    Update       : Remove functions : 'Get-NOTIFICATIONAlerts' and 'Get-NOTIFICATIONContacts' and 'Get-NOTIFICATIONEvents' - Due to duplicates functions
    Update       : Update function : 'Switch-Info' - Change Function name : 'Get-NOTIFICATIONConfigAlerts' to 'Get-NOTIFICATIONAlerts' and 'Get-NOTIFICATIONConfigContacts' to 'Get-NOTIFICATIONContacts' and 'Get-NOTIFICATIONConfigEvents' to 'Get-NOTIFICATIONEvents'
    Update       : Update File : '.\API-Summary.csv'
    Update       : Update function : 'Get-NOTIFICATIONAlerts' - Add Header 'Mail' to see at which email addresses was sent the alerts
    Update       : Update function : 'Get-USERSAVE' - Change date format
    Update       : Add new function : 'Get-DeviceConnectionHistoryLog' and  'Get-DeviceConnectionHistoryLogID' - Get Log connexion history for devices
    Update       : Update File : '.\API-Summary.csv'
    Update       : Update defaut chrome driver to version : 113.0.5672.24
    Update       : Update log file : 'BBox_Administration_Log-Date.csv' and 'BBox-Administration-Transcript-Log-Date.log'
    Update       : Update function : 'Update-ChromeDriver' - Correct Folder creation, Unzip issue, DLLs files copy
    Update       : Add foreach custom function in module : '.\BBox-Modules.psm1' A get-help based on comments
    Update       : Add foreach custom function their functions dependencies if exist in the header. Use 'get-help' for more details (https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.core/get-help)
    Update       : Update function : 'Get-PortStatus' - Add more help to diagnostize
    Update       : Update 'Site.CurrentLocalUrl' parameter in Json files : '.\Ressources\Settings-Default-User.json' and '.\Ressources\Settings-Current-User.json'
    Update       : Add 'BBox.UrlPrefixe' parameter in Json file : '.\Ressources\Settings-Program.json' and remplace 'https://' by '$global:UrlPrefixe'
    Update       : Update File : '.\API-Summary.csv' - Correct wrong function association and syntaxe
    Update       : Update function : 'Show-WindowsFormDialogBoxInuput' - Add new parameter : 'DefaultValue' - Define Default value in the input field
    Update       : Switch settings between in Json files : '.\Ressources\Settings-Default-User.json' and '.\Ressources\Settings-Current-User.json'
    Update       : Update variables linked to JSON files and convert it from 'Local:' to 'Global:'
    Update       : Correct some minor bugs
    Update       : Harmonize function : 'Start-sleep'
    Update       : Optimise and convert variables from 'Local:' to 'Global:' (Reduce repetition and single usage text value to centralise management to JSON files configuration)
    
.LINKS
    
    https://api.BBox.fr/doc/
    https://api.BBox.fr/doc/apirouter/index.html
    https://chromedriver.chromium.org/
    https://maBBox.bytel.fr/
    https://maBBox.bytel.fr/api/v1
    https://www.BBox-mag.fr/box/firmware/
    https://www.powershellgallery.com/packages/TUN.CredentialManager
    http://winstonfassett.com/blog/2010/09/21/html-to-text-conversion-in-powershell/
    https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.core/get-help
    
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
    $log = [pscustomobject] @{Date=(Get-Date -UFormat %Y%m%d_%H%M%S) ; PID=$PID ; user= $(whoami) ; Type=$type ; Name=$name ; Message=$Message} 
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
            Out-File -FilePath $logpath -Encoding UTF8 -Append -InputObject "date;pid;user;type;name;message" 
        }
        Out-File -FilePath $logpath -Encoding UTF8 -Append -InputObject "$($Log.date);$($Log.pid);$($Log.user);$($Log.type);$($Log.name);$($Log.Message)" 
    }
    Finally {
        $mtx.ReleaseMutex()
    }
}

#endregion function

#region Main Variables

# Logs file
$ScriptRootFolder      = $PSScriptRoot
$global:LogFileName    = 'BBox_Administration_Log-'
$global:LogFolderName  = 'Logs'
$global:LogFolderPath  = "$ScriptRootFolder\$global:LogFolderName"

# Transcript Logs
$Date = $(get-date -UFormat %Y%m%d).toString()
$global:TranscriptFileName = "BBox-Administration-Transcript-Log-$Date.log"
$TranscriptFilePath = "$global:LogFolderPath\$global:TranscriptFileName"

# System Json Configuration files
$ProgramConfigurationFileSettings   = 'Settings-Program.json'
$RessourcesFolderName               = 'Ressources'
$RessourcesPath                     = "$ScriptRootFolder\$RessourcesFolderName"
$global:JSONSettingsProgramFilePath = "$RessourcesPath\$ProgramConfigurationFileSettings"

# Main Trigger
$global:TriggerExit = $Null
$global:TriggerDialogBox = $Null
$global:TriggerExportConfig = $Null
$TriggerLANNetwork = $Null
$TriggerAuthentification = $Null

# URL Settings for the ChromeDriver request
$UrlRoot    = $Null
$Port       = $Null
$UrlAuth    = $Null
$UrlHome    = $Null
$UrlToGo    = $Null
$DYNDNS     = ""

#endregion Main Variables

#region Start Program initialisation

Start-Transcript -Path $TranscriptFilePath -Append -Force -NoClobber
Write-Log -Type WARNING -Name 'Program initialisation - Start Program' -Message '#################################################### Initialisation #####################################################'
Write-Log -Type INFO -Name 'Program initialisation - Start Program' -Message 'Start Program initialisation' -NotDisplay
Write-Log -Type INFONO -Name 'Program initialisation - Start Program' -Message 'Program loading ... : '

#endregion Start Program initialisation

#region Create logs folder

Write-Log -Type INFO -Name 'Program initialisation - Logs Folder Creation' -Message 'Start Logs Folder Creation' -NotDisplay
Write-Log -Type INFONO -Name 'Program initialisation - Logs Folder Creation' -Message 'Start Logs Folder Creation status : ' -NotDisplay
If (-not (Test-Path -Path $ScriptRootFolder)) {
    
    Try {
        $Null = New-Item -Path $ScriptRootFolder -Name $global:LogFolderName -ItemType Directory -Force -ErrorAction Stop
        Write-Log -Type VALUE -Name 'Program initialisation - Logs Folder Creation' -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program initialisation - Logs Folder Creation' -Message "Failed, due to :$($_.string())" -NotDisplay
    }
}
Else {
    Write-Log -Type VALUE -Name 'Program initialisation - Logs Folder Creation' -Message 'Already exist' -NotDisplay
}
Write-Log -Type INFO -Name 'Program initialisation - Logs Folder Creation' -Message 'End Logs Folder Creation' -NotDisplay

#endregion Create logs folder

#region Import System Json Configuration files

If ($Null -eq $global:TriggerExit) {

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
}

#endregion Import System Json Configuration files

#region Load System Json Configuration files

Write-Log -Type INFO -Name 'Program initialisation - Load JSON Settings Program' -Message 'Start Load JSON Settings Program' -NotDisplay

If (($Null -eq $global:TriggerExit) -and ($Null -ne $global:JSONSettingsProgramContent)) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Load JSON Settings Program' -Message "JSON Settings Program file path : $global:JSONSettingsProgramFilePath" -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Load JSON Settings Program' -Message 'Load JSON Settings Program Status : ' -NotDisplay

    Try {
        $global:JSONSettingsDefaultUserFilePath = "$RessourcesPath\" + $global:JSONSettingsProgramContent.UserConfigurationFile.DefaultFileName
        $global:JSONSettingsCurrentUserFilePath = "$RessourcesPath\" + $global:JSONSettingsProgramContent.UserConfigurationFile.CurrentFileName
        
        # Paths
        $ExportPath                              = "$ScriptRootFolder\"  + $global:JSONSettingsProgramContent.path.ExportFolderName
        $JournalPath                             = "$ScriptRootFolder\" + $global:JSONSettingsProgramContent.path.JournalFolderName
        $global:JournalName                      = $global:JSONSettingsProgramContent.Path.JournalName
        $JsonBBoxconfigPath                      = "$ScriptRootFolder\" + $global:JSONSettingsProgramContent.path.JsonBBoxconfigFolderName
        $RessourcesPath                          = "$ScriptRootFolder\" + $global:JSONSettingsProgramContent.path.RessourcesFolderName
        $ReportPath                              = "$ScriptRootFolder\" + $global:JSONSettingsProgramContent.path.ReportFolderName
        $BBoxModulePath                          = "$ScriptRootFolder\" + $global:JSONSettingsProgramContent.path.BBoxModuleFileName
        $APISummaryPath                          = "$RessourcesPath\" + $global:JSONSettingsProgramContent.path.APISummaryFileName
        $TestedEnvironnementPath                 = "$RessourcesPath\" + $global:JSONSettingsProgramContent.path.TestedEnvironnementFileName
        $ExportCSVPath                           = "$ExportPath\" + $global:JSONSettingsProgramContent.path.ExportCSVFolderName
        $ExportJSONPath                          = "$ExportPath\" + $global:JSONSettingsProgramContent.path.ExportJSONFolderName
        $global:DownloadShellRegistryFolder      = $global:JSONSettingsProgramContent.Path.DownloadShellRegistryFolder
        $global:DownloadShellRegistryFolderName  = $global:JSONSettingsProgramContent.Path.DownloadShellRegistryFolderName
        
        # Google Chrome / Chrome Driver Paths
        $global:ChromeDriver                     = $Null
        $ChromeVersionRegistry                   = $global:JSONSettingsProgramContent.GoogleChrome.ChromeVersionRegistry
        $ChromeDriverPath                        = "$RessourcesPath\" + $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverRessourcesFolderName
        $global:ChromeDriverDefaultFolderName    = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultFolderName
        $ChromeDriverDefaultPath                 = "$ChromeDriverPath\" + $global:ChromeDriverDefaultFolderName
        $global:ChromeDriverDefaultSetupFileName = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultSetupFileName
        $ChromeDriverDefaultSetupPath            = "$ChromeDriverDefaultPath\" + $global:ChromeDriverDefaultSetupFileName
        $global:ChromeDriverDefaultWebDriverDLLFileName  = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultWebDriverDLLFileName
        $ChromeDriverDefaultWebDriverDLLPath     = "$ChromeDriverDefaultPath\" + $global:ChromeDriverDefaultWebDriverDLLFileName
        $global:ChromeDriverDefaultWebDriverSupportFileName = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultWebDriverSupportFileName
        $ChromeDriverDefaultWebDriverSupportPath = "$ChromeDriverDefaultPath\" + $global:ChromeDriverDefaultWebDriverSupportFileName
        $ChromeDriverDefaultProfile              = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultProfileName
        $ChromeProgramFilesInstallation          = $global:JSONSettingsProgramContent.GoogleChrome.ChromeProgramFilesInstallationPath
        $ChromeProgramFilesX86Installation       = $global:JSONSettingsProgramContent.GoogleChrome.ChromeProgramFilesX86InstallationPath
        $ChromeDownloadUrl                       = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDownloadUrl
        $global:ChromeDriverDownloadHomeUrl      = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDownloadHomeUrl
        $global:ChromeDriverDownloadPathUrl      = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDownloadPathUrl
        $global:ChromeDriverDownloadFileName     = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDownloadFileName

        # APIName
        $APINameAvailable                      = $global:JSONSettingsProgramContent.APIName.Available
        $APINameExclusionsFull                 = $global:JSONSettingsProgramContent.APIName.Exclusions.Full
        $APINameExclusionsFull_Testing_Program = $global:JSONSettingsProgramContent.APIName.Exclusions.Full_Testing_Program
        $APINameScopeExclusionsFull            = $global:JSONSettingsProgramContent.APIName.Scope.Exclusions.Full
        
        # Actions
        $ActionsExclusionsScope   = $global:JSONSettingsProgramContent.Actions.Exclusions.Scope
        $ActionsExclusionsActions = $global:JSONSettingsProgramContent.Actions.Exclusions.Actions
        
        # BBox
        $global:APIVersion        = $global:JSONSettingsProgramContent.BBox.APIVersion
        $global:UrlPrefixe        = $global:JSONSettingsProgramContent.BBox.UrlPrefixe
        $global:DefaultRemotePort = $global:JSONSettingsProgramContent.BBox.DefaultRemotePort
        $global:DefaultLocalUrl   = $global:JSONSettingsProgramContent.BBox.DefaultLocalUrl
        $BBoxDns                  = $global:JSONSettingsProgramContent.BBox.BBoxDns
        $global:BBoxUrlRemote     = $global:JSONSettingsProgramContent.BBox.BBoxUrlRemote
        $global:BBoxUrlFirewall   = $global:JSONSettingsProgramContent.BBox.BBoxUrlFirewall
        $global:BBoxUrlDynDns     = $global:JSONSettingsProgramContent.bbox.BBoxUrlDynDns
        $BBoxAPIUrlDocumentation  = $global:JSONSettingsProgramContent.BBox.APIUrlDocumentation
        
        # Various
        $Mail = $global:JSONSettingsProgramContent.various.mail
        $GitHubUrlSite = $global:JSONSettingsProgramContent.various.GitHubUrlSite
        
        # Notification Events
        $global:NotificationEventType = $global:JSONSettingsProgramContent.Notification.Event.Type
        
        # Start-Sleep
        $global:SleepDefault                                  = $global:JSONSettingsProgramContent.Sleep.Default
        $global:SleepTUNCredentialManagerModuleinstallation   = $global:JSONSettingsProgramContent.Sleep.TUNCredentialManagerModuleinstallation
        $global:SleepRefreshWIRELESSFrequencyNeighborhoodScan = $global:JSONSettingsProgramContent.Sleep.RefreshWIRELESSFrequencyNeighborhoodScan
        $global:SleepChromeDriverDownload                     = $global:JSONSettingsProgramContent.Sleep.ChromeDriverDownload
        $global:SleepChromeDriverUnzip                        = $global:JSONSettingsProgramContent.Sleep.ChromeDriverUnzip
        $global:SleepChromeDriverNavigation                   = $global:JSONSettingsProgramContent.Sleep.ChromeDriverNavigation
        $global:SleepChromeDriverLoading                      = $global:JSONSettingsProgramContent.Sleep.ChromeDriverLoading
        $global:SleepBboxJournalDownload                      = $global:JSONSettingsProgramContent.Sleep.BboxJournalDownload
        
        # Values
        $global:ValuesLANNetworkLocal  = $global:JSONSettingsProgramContent.Values.LANNetworkLocal
        $global:ValuesLANNetworkRemote = $global:JSONSettingsProgramContent.Values.LANNetworkRemote
        $global:ValuesOpenExportFolder = $global:JSONSettingsProgramContent.Values.OpenExportFolder
        $global:ValuesDisplayFormat    = $global:JSONSettingsProgramContent.Values.DisplayFormat
        $global:ValuesExportFormat     = $global:JSONSettingsProgramContent.Values.ExportFormat
        $global:ValuesOpenHTMLReport   = $global:JSONSettingsProgramContent.Values.OpenHTMLReport
        $global:ValuesLineNumber       = $global:JSONSettingsProgramContent.Values.LineNumber
        
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

#region Import Functions with Module : 'BBox-Module.psm1'

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Powershell Module Importation' -Message 'Start Powershell Module Importation' -NotDisplay
    Write-Log -Type INFO -Name 'Program initialisation - Powershell Module Importation' -Message "Powershell Module Path : $BBoxModulePath" -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Powershell Module Importation' -Message 'Powershell Module Importation status : ' -NotDisplay
    
    Try {
        Remove-Module -Name BBox-Module -ErrorAction SilentlyContinue
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program initialisation - Powershell Module Importation' -Message "Failed, Powershell Module $BBoxModulePath can't be removed, due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Start-Sleep $global:SleepDefault
    Try {
        Import-Module -Name $BBoxModulePath -ErrorAction Stop
        Write-Log -Type VALUE -Name 'Program initialisation - Powershell Module Importation' -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program initialisation - Powershell Module Importation' -Message "Failed, Powershell Module $BBoxModulePath can't be imported due to : $($_.ToString())"
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

#endregion Import Functions with Module : 'BBox-Module.psm1'

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

#endregion Check if ressources folder exist

#region Create folders/files if not yet existing

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Program Folders/Files check' -Message 'Start Program Folders/Files check' -NotDisplay
    
    # Folders test
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $ExportPath              -FolderName $ExportPath              -ErrorAction Stop
    Test-FolderPath -FolderRoot $ExportPath       -FolderPath $ExportCSVPath           -FolderName $ExportCSVPath           -ErrorAction Stop
    Test-FolderPath -FolderRoot $ExportPath       -FolderPath $ExportJSONPath          -FolderName $ExportJSONPath          -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $JournalPath             -FolderName $JournalPath             -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $ReportPath              -FolderName $ReportPath              -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $JsonBBoxconfigPath      -FolderName $JsonBBoxconfigPath      -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $ChromeDriverPath        -FolderName $ChromeDriverPath        -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolder -FolderPath $ChromeDriverDefaultPath -FolderName $ChromeDriverDefaultPath -ErrorAction Stop
    
    # Files test
    Test-FilePath   -FileRoot $ChromeDriverDefaultPath -FilePath $ChromeDriverDefaultSetupPath            -FileName $ChromeDriverDefaultSetupPath -ErrorAction Stop
    Test-FilePath   -FileRoot $ChromeDriverDefaultPath -FilePath $ChromeDriverDefaultWebDriverDLLPath     -FileName $ChromeDriverDefaultWebDriverDLLPath -ErrorAction Stop
    Test-FilePath   -FileRoot $ChromeDriverDefaultPath -FilePath $ChromeDriverDefaultWebDriverSupportPath -FileName $ChromeDriverDefaultWebDriverSupportPath -ErrorAction Stop
    
    Write-Log -Type INFO -Name 'Program initialisation - Program Folders/Files check' -Message 'End Program Folders/Files check' -NotDisplay
}

#endregion Create folders/files if not yet existing

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

#endregion Import Actions available

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
        $ChromeVersion = "Undefine"
        $global:TriggerExit = 1
    }
}

#endregion Check if Google Chrome is already install

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
    Write-Log -Type INFO -Name 'Program initialisation - Google Chrome Binaries' -Message 'End Google Chrome Binaries' -NotDisplay    
}

#endregion Google Chrome binary Path

#region Check Chrome Driver Version installed

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Chrome Driver Version' -Message 'Start Chrome Driver version selection function Chrome Version installed on device' -NotDisplay   
    Try {
        $ChromeDriverVersion = Get-ChromeDriverVersionBeforeUpdate -ChromeVersion $ChromeVersion -ChromeDriverPath $ChromeDriverPath -ErrorAction Stop
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Chrome Driver Version' -Message "Failed, to define the correct ChromeDriverVersion, due to : $($_.ToString())"
        $ChromeDriverVersion = "Undefine"
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name 'Program initialisation - Chrome Driver Version' -Message 'End Chrome Driver version selection function Chrome Version installed on device' -NotDisplay
}

#endregion Check Chrome Driver Version installed

#region Update Chrome Driver version

If ($Null -eq $global:TriggerExit) {

    Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message 'Start update ChromeDriver' -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Update ChromeDriver' -Message 'ChromeDriver version Status : ' -NotDisplay
    
    If ($ChromeVersion -notmatch $ChromeDriverVersion[0]) {
        
        Write-Log -Type WARNING -Name 'Program initialisation - Update ChromeDriver' -Message 'Need to be updated' -NotDisplay
        Start-ChromeDriver -ChromeBinaryPath $ChromeBinaryPath -ChromeDriverPath $ChromeDriverPath -ChromeDriverVersion $ChromeDriverVersion[1] -LogsPath $global:LogFolderPath -ChromeDriverDefaultProfile $ChromeDriverDefaultProfile -ErrorAction Stop
        
        Write-Log -Type INFONO -Name 'Program initialisation - Update ChromeDriver' -Message 'ChromeDriver update version Status : ' -NotDisplay
        Update-ChromeDriver -ChromeDriverVersion $ChromeDriverVersion[1] -ChromeDriverPath $ChromeDriverPath -ErrorAction Stop
        Stop-ChromeDriver -ErrorAction Stop
    }
    Else {
        Write-Log -Type VALUE -Name 'Program initialisation - Update ChromeDriver' -Message 'Updated / Up to date' -NotDisplay
    }
    Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message 'End update ChromeDriver' -NotDisplay
}

#endregion Update Chrome Driver version

#region Update Google Chrome version

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Update Google Chrome' -Message 'Start update Google Chrome' -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Update Google Chrome' -Message 'Check if Google Chrome runs status :' -NotDisplay
    Try {
        $ChromeProcess = Get-Process -Name chrome -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        Write-Log -Type WARNING -Name 'Program initialisation - Update Google Chrome' -Message 'Running' -NotDisplay
    }
    Catch {
        Write-Log -Type VALUE -Name 'Program initialisation - Update Google Chrome' -Message 'Not Running' -NotDisplay
    }
    
    If ($ChromeProcess) {
        
        While ($null -ne $ChromeProcess) {
            $null = Show-WindowsFormDialogBox -Title "Program initialisation - Update Google Chrome" -Message "Google Chrome is running.`nPlease save your data, then close it." -WarnIcon
            $ChromeProcess = Get-Process -Name chrome -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
        Write-Log -Type INFO -Name 'Program initialisation - Stop Google Chrome' -Message 'Start stop Google Chrome' -NotDisplay
        Write-Log -Type INFONO -Name 'Program initialisation - Stop Google Chrome' -Message 'Google Chrome stop process status :' -NotDisplay
        Try {
            Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Write-Log -Type VALUE -Name 'Program initialisation - Stop Google Chrome' -Message 'Stopped' -NotDisplay
        }
        Catch {
            Write-Log -Type VALUE -Name 'Program initialisation - Stop Google Chrome' -Message "Failed, to stop running Google Chrome, due to $($_.ToString())" -NotDisplay
        }
        Write-Log -Type INFO -Name 'Program initialisation - Stop Google Chrome' -Message 'Stop stop Google Chrome' -NotDisplay
    }
    
    Write-Log -Type INFONO -Name 'Program initialisation - Update Google Chrome' -Message 'Google Chrome update version Status : ' -NotDisplay
    Try{
        winget upgrade Google.Chrome
        Write-Log -Type VALUE -Name 'Program initialisation - Update Google Chrome' -Message 'Updated' -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Update Google Chrome' -Message "Failed, to update Google Chrome Version, due to : $($_.ToString())"
    }
    
    Write-Log -Type INFONO -Name 'Program initialisation - Restore Google Chrome' -Message 'Google Chrome restore last session Status : ' -NotDisplay
    
    If ($ChromeProcess) {
        
        Try {
            Start-Process -FilePath $ChromeBinaryPath -ArgumentList "-restore-last-session" -WindowStyle Minimized
            Write-Log -Type VALUE -Name 'Program initialisation - Restore Google Chrome' -Message 'Success' -NotDisplay
        }
        Catch {
            Write-Log -Type WARNING -Name 'Program initialisation - Restore Google Chrome' -Message "Failed, to restore last session for Google Chrome, due to : $($_.ToString())"
        }
    }
    Else {
        Write-Log -Type INFO -Name 'Program initialisation - Restore Google Chrome' -Message 'Not necessary' -NotDisplay
    }
    
    Write-Log -Type INFO -Name 'Program initialisation - Update Google Chrome' -Message 'End update Google Chrome' -NotDisplay
}

#endregion Update Google Chrome version

#region Get Google Chrome installed version

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Google Chrome installed version' -Message 'Start Google Chrome installed version' -NotDisplay    
    Write-Log -Type INFONO -Name 'Program initialisation - Google Chrome installed version' -Message 'Google Chrome installed version status : ' -NotDisplay
    
    Try {
        $ChromeVersion = (Get-ItemProperty $ChromeVersionRegistry -ErrorAction Stop).Version
        Write-Log -Type VALUE -Name 'Program initialisation - Google Chrome installed version' -Message 'Successful' -NotDisplay
        Write-Log -Type INFONO -Name 'Program initialisation - Google Chrome Version' -Message 'Current Google Chrome version : ' -NotDisplay
        Write-Log -Type VALUE -Name 'Program initialisation - Google Chrome Version' -Message $ChromeVersion -NotDisplay
        Write-Log -Type INFO -Name 'Program initialisation - Google Chrome installed version' -Message 'End Google Chrome installed version' -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Google Chrome installed version' -Message 'Failed, not found' -NotDisplay
        Write-Log -Type INFO -Name 'Program initialisation - Google Chrome installed version' -Message 'End Google Chrome installed version' -NotDisplay
        $ChromeVersion = $Null
        $global:TriggerExit = 1
    }
}

#endregion Get Google Chrome installed version

#region Chrome Driver Version choice function chrome version installed

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program initialisation - Chrome Driver Version' -Message 'Start Chrome Driver version selection function Chrome Version installed on device' -NotDisplay   
    Try {
        $ChromeDriverVersion = Get-ChromeDriverVersion -ChromeVersion $ChromeVersion -ChromeDriverPath $ChromeDriverPath -ErrorAction Stop
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Chrome Driver Version' -Message "Failed, to define the correct ChromeDriverVersion, due to : $($_.ToString())"
        $ChromeDriverVersion = $Null
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name 'Program initialisation - Chrome Driver Version' -Message 'End Chrome Driver version selection function Chrome Version installed on device' -NotDisplay
}

#endregion Chrome Driver Version choice function chrome version installed

#region End Program Initialisation

If ($Null -eq $global:TriggerExit) {
    Write-Log -Type VALUE -Name 'Program initialisation - Start Program' -Message 'Finished without errors'
}
Else {
    Write-Log -Type WARNING -Name 'Program initialisation - Start Program' -Message 'Finished with errors'
    Stop-Program -ErrorAction Stop
}

Write-Log -Type INFO -Name 'Program initialisation - Start Program' -Message 'End Program initialisation' -NotDisplay
Write-Log -Type WARNING -Name 'Program initialisation - Start Program' -Message '#################################################### Initialisation #####################################################'

#endregion End Program Initialisation

#region Program Presentation

Write-Host '##################################################### Description ######################################################' -ForegroundColor Yellow
Write-Host 'This program is only available in English'
Write-Host 'It allows you to get, modify and delete information on Bouygues Telecoms BBox'
Write-Host 'It displays advanced information that you will not see through the classic web interface of your BBox'
Write-Host 'And this via a local or remote connection (Provided that you have activated the remote BBox management => ' -NoNewline
Write-Host "$global:BBoxUrlRemote" -ForegroundColor Green -NoNewline
Write-Host ')'
Write-Host 'The result can be displayed in HTML format or in table form (Gridview)'
Write-Host "The result can be exported in `" .csv (.csv) `" or `" .JSON (.JSON) `" format"
Write-Host 'The only limitation of this program is related to the requests available via the API installed on the target BBox according to the model and the firmware version of this one'
Write-Host 'When displaying the result, some information may not be displayed, or may be missing :'
Write-Host '- Either its an oversight on my part in the context of the development, and I apologize in advance'
Write-Host '- Either this one is still under development'
Write-Host '- Either this information is optional and only appears in the presence of certain BBox models :'
Write-Host '-- BBox models'
Write-Host '-- Firmware version'
Write-Host '-- Available features'
Write-Host '-- Connection mode (Local / Remote)'
Write-Host 'This program requires the installation of PowerShell 7.0 minimum and Google Chrome (MSI Install)'
Write-Host 'For more information, please consult : ' -NoNewline
Write-Host "$BBoxAPIUrlDocumentation" -ForegroundColor Green
Write-Host 'Be carefull, this program is reserved for an advanced use of the BBox settings and is aimed at an informed audience !' -ForegroundColor Yellow
Write-Host 'Any improper handling risks causing partial or even total malfunction of your BBox, rendering it unusable. You are Warned !' -ForegroundColor Yellow
Write-Host 'Therefore, you use this program at your own risks, I cant be responsible if you dont use it in the correct environnement' -ForegroundColor Red
Write-Host 'For any questions or additionals requests, contact me to this email address : ' -NoNewline
Write-Host "$Mail" -ForegroundColor Green
Write-Host "Tested environnement list : "
Write-Host "- $TestedEnvironnementPath" -ForegroundColor Green
Write-Host 'Logs files location : '
Write-Host "- $global:LogFolderPath\$global:LogFileName*.csv" -ForegroundColor Green
Write-Host "- $TranscriptFilePath" -ForegroundColor Green
#Write-Host 'Please make sure logs files are closed before continue' -ForegroundColor Yellow

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
        Start-Sleep -Seconds $global:SleepChromeDriverNavigation
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

    If ($null -eq ($(Get-StoredCredential -Target $global:CredentialsTarget -ErrorAction SilentlyContinue | Select-Object -Property Password -ErrorAction SilentlyContinue).password | ConvertFrom-SecureString -AsPlainText -ErrorAction SilentlyContinue)) {
        
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
        $Answer = Show-WindowsFormDialogBox3ChoicesCancel -MainFormTitle 'Program run - Password Status' -LabelMessageText "BBox password is already set.`nWhat do you want to do ? :`n- (U) Use existing Password`n- (D) Define new password`n- (Q) Quit the program" -FirstOptionButtonText 'U' -SecondOptionButtonText 'D' -ThirdOptionButtonText 'Q'
        switch ($Answer) {
            'U'   {$Password = $(Get-StoredCredential -Target $global:CredentialsTarget | Select-Object -Property Password).password | ConvertFrom-SecureString -AsPlainText;Break}
            'D'   {Add-BBoxCredential -ErrorAction Stop;Break}
            'Q'  {Stop-Program -ErrorAction Stop;Break}
            Default {$Password = $(Get-StoredCredential -Target $global:CredentialsTarget | Select-Object -Property Password).password | ConvertFrom-SecureString -AsPlainText;Break}
        }
    }
    Write-Log -Type INFO -Name 'Program run - Password Status' -Message 'End Password Status' -NotDisplay
}

#endregion Check if password already exist in Windows Credential Manager

#region Check if user connect on the correct LAN Network

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program run - Network connection' -Message 'Start Check BBox LAN network' -NotDisplay
    Write-Log -Type INFONO -Name 'Program run - Network connection' -Message 'Checking BBox LAN network : ' -NotDisplay
    
    Try {
        $DnsName = Resolve-DnsName -Name $BBoxDns -Type A -DnsOnly -ErrorAction Stop
        Write-Log -Type VALUE -Name 'Program run - Network connection' -Message 'Connected to your Local BBox Network' -NotDisplay
        Write-Log -Type INFONO -Name 'Program run - Network connection' -Message 'BBox IP Address : ' -NotDisplay
        Write-Log -Type VALUE -Name 'Program run - Network connection' -Message $($DnsName.Address) -NotDisplay
        Write-Log -Type INFONO -Name 'Program run - Network connection' -Message 'Recommanded connection : ' -NotDisplay
        Write-Log -Type VALUE -Name 'Program run - Network connection' -Message 'Localy' -NotDisplay
        $global:JSONSettingsCurrentUserContent.Site.CurrentLocalUrl = $BBoxDns
        $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
        $TriggerLANNetwork = 1
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program run - Network connection' -Message 'Failed' -NotDisplay
        Write-Log -Type ERROR -Name 'Program run - Network connection' -Message "Unable to resolve $BBoxDns, due to : $($_.ToString())" -NotDisplay
        Show-WindowsFormDialogBox -Title 'Program run - Network connection' -Message "It seems you are not connected to your Local BBox Network`n`n- If you are connected on your local network, make sure you are connected on the BBox's Wifi or ethernet network`n- If you use a intermediary router between your computer and the BBox router, it will not working" -WarnIcon | Out-Null
        Write-Log -Type INFONO -Name 'Program run - Network connection' -Message 'Recommanded connection : ' -NotDisplay
        Write-Log -Type VALUE -Name 'Program run - Network connection' -Message 'Remotely' -NotDisplay
        $global:JSONSettingsCurrentUserContent.Site.CurrentLocalUrl = "Unknow / Can't be Define / Resolve"
        $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
        $TriggerLANNetwork = 0
    }
    Write-Log -Type INFO -Name 'Program run - Network connection' -Message 'End Check BBox LAN network' -NotDisplay
}

#endregion Check if user connect on the correct LAN Network

#region Ask to the user how he want to connect to the BBox

If ($Null -eq $global:TriggerExit) {
    
    Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message 'Start Connexion Type' -NotDisplay
    $ConnexionType = Get-ConnexionType -TriggerLANNetwork $TriggerLANNetwork -ErrorAction Stop
    Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message 'End Connexion Type' -NotDisplay
}

#endregion Ask to the user how he want to connect to the BBox

#region Set BBox connexion settings regarding user selection

If ($Null -eq $global:TriggerExit) {
    
    Switch ($ConnexionType[0]) {
        
        L   {$UrlRoot = "$global:UrlPrefixe$BBoxDns/$global:APIVersion"
             $UrlAuth = "$global:UrlPrefixe$BBoxDns/login.html"
             $UrlHome = "$global:UrlPrefixe$BBoxDns/index.html"
             Break
            }
        
        R   {Write-Log -Type INFO -Name 'Program run - Check Host' -Message 'Start Check Host' -NotDisplay
             $DYNDNS = Get-HostStatus
             Write-Log -Type INFO -Name 'Program run - Check Host' -Message 'End Check Host' -NotDisplay
             Write-Log -Type INFO -Name 'Program run - Check Port' -Message 'Start Check Port' -NotDisplay
             $Port = Get-PortStatus -UrlRoot $DYNDNS
             Write-Log -Type INFO -Name 'Program run - Check Port' -Message 'End Check Port' -NotDisplay
             $UrlRoot = "$global:UrlPrefixe$DYNDNS`:$Port/$global:APIVersion"
             $UrlAuth = "$global:UrlPrefixe$DYNDNS`:$Port/login.html"
             $UrlHome = "$global:UrlPrefixe$DYNDNS`:$Port/index.html"
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

#endregion Set BBox connexion settings regarding user selection

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
        $LocalPermissions = $Action.LocalPermissions
        $RemotePermissions = $Action.RemotePermissions
        #$Scope = $Action.Scope
        $ActionProgram = $Action.Action
        
        Write-Log -Type INFONO -Name 'Program run - Action asked' -Message 'Selected action : '
        Write-Log -Type VALUE -Name 'Program run - Action asked' -Message $Description
        
        If ($ActionProgram -notmatch $ActionsExclusionsActions) {
            #region Start in Background chromeDriver
            If (-not $global:ChromeDriver) {
                
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
            }
            #endregion Start in Background chromeDriver
        
            #region Start BBox Authentification
            If ((($RemotePermissions -eq 'private') -and ($ConnexionType -eq 'R')) -or (($LocalPermissions -eq 'private') -and ($ConnexionType -eq 'L')) -or ($APIName -eq 'Full_Testing_Program')  -or ($APIName -eq 'Full')) {
                
                Write-Log -Type INFO -Name 'Program run - BBox Authentification' -Message 'BBox Authentification needed' -NotDisplay
                
                If ($Null -eq $TriggerAuthentification) {
                    
                    Write-Log -Type INFO -Name 'Program run - ChromeDriver Authentification' -Message 'Start BBox Authentification' -NotDisplay
                    Write-Log -Type INFONO -Name 'Program run - ChromeDriver Authentification' -Message 'Starting BBox Authentification : ' -NotDisplay
                    
                    Try {
                        $Password = $(Get-StoredCredential -Target $global:CredentialsTarget | Select-Object -Property Password).password | ConvertFrom-SecureString -AsPlainText
                        Connect-BBox -UrlAuth $UrlAuth -UrlHome $UrlHome -Password $Password -ErrorAction Stop
                        Write-Log -Type VALUE -Name 'Program run - ChromeDriver Authentification' -Message 'Authentificated' -NotDisplay
                        Clear-Variable -Name Password
                        $TriggerAuthentification = 1
                    }
                    Catch {
                        Write-Log -Type ERROR -Name 'Program run - ChromeDriver Authentification' -Message "Failed, Authentification can't be done, due to : $($_.ToString())"
                        Stop-Program -ErrorAction Stop
                    }
                    Write-Log -Type INFO -Name 'Program run - ChromeDriver Authentification' -Message 'End BBox Authentification' -NotDisplay
                }
                Else {
                    Write-Log -Type INFO -Name 'Program run - BBox Authentification' -Message 'BBox Authentification already set' -NotDisplay
                }
            }
            Else {
                Write-Log -Type INFO -Name 'Program run - BBox Authentification' -Message 'BBox Authentification not needed' -NotDisplay
            }
            #endregion Start BBox Authentification
        }
        
        # Get data
        Switch ($APIName) {
            
            'Full'                 {$APISName = $Actions | Where-Object {(($_.Available -eq $APINameAvailable) -and ($_.Scope -notmatch $ActionsExclusionsScope) -and ($_.APIName -notmatch $APINameExclusionsFull) -and ($_.Action -notmatch $APINameScopeExclusionsFull) -and ($_.Label -match "Get-") -and ($_.APIUrl -notmatch "`{id`}"))} | Select-Object Label,APIName,Exportfile
                                    $global:TriggerExportConfig = $true
                                    Export-BBoxConfiguration -APISName $APISName -UrlRoot $UrlRoot -JSONFolder $JsonBBoxconfigPath -CSVFolder $ExportCSVPath -GitHubUrlSite $GitHubUrlSite -JournalPath $JournalPath -Mail $Mail
                                    Break
                                   }
            
            'Full_Testing_Program' {$APISName = $Actions | Where-Object {(($_.Available -eq $APINameAvailable) -and ($_.Scope -notmatch $ActionsExclusionsScope) -and ($_.APIName -notmatch $APINameExclusionsFull_Testing_Program))} | Select-Object *
                                    $global:TriggerExportConfig = $false
                                    Export-BBoxConfigTestingProgram -APISName $APISName -UrlRoot $UrlRoot -OutputFolder $ExportCSVPath -Mail $Mail -JournalPath $JournalPath -GitHubUrlSite $GitHubUrlSite
                                    Break
                                   }
            
            Default                {$UrlToGo = "$UrlRoot/$APIName"
                                    $global:TriggerExportConfig = $false
                                    $FormatedData =  Switch-Info -Label $Label -UrlToGo $UrlToGo -APIName $APIName -Mail $Mail -JournalPath $JournalPath -GitHubUrlSite $GitHubUrlSite -ErrorAction Continue -WarningAction Continue
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

#endregion Close Program
