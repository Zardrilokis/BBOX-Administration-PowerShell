#Requires -Version 7.0

<#
.SYNOPSIS
   Get / Set / Add Box informations.
    
.DESCRIPTION
   GET/PUT/POST/DELETE/OPTION Box informations by Web request from ChromeDriver.
   Collect, Modify, Remove, Box information using Bytel API Web request, with PowerShell script.
    
.INPUTS
    .\Box-Aministration.ps1
    .\Box-Module.psm1
    .\Settings-Default-User.json
    .\Settings-Current-User.json
    .\Settings-Program.json
    Web url Box content
    Box Rest API
    Hand User actions
    Windows Credential Manager
    
.OUTPUTS
    Export-HTMLReport   -DataReported $FormatedData -ReportTitle "Box Configuration Report - $APIName" -ReportType $ReportType -ReportPath $ReportFolderNamePath -ReportFileName $Exportfile -HTMLTitle "Box Configuration Report" -ReportPrecontent $APIName -Description $Description
    Out-GridviewDisplay -FormatedData $FormatedData -APIName $APIName -Description $Description
    Export-toCSV        -FormatedData $FormatedData -APIName $APIName -ExportCSVPath $ExportCSVFolderNamePath -Exportfile $Exportfile
    Export-toJSON       -FormatedData $FormatedData -APIName $APIName -JsonBoxconfigPath $ExportJSONFolderNamePath -Exportfile $Exportfile
    Windows Dialog form Boxes
    PowerShell Host Console
    .\Logs\Box_Administration_Log-Date.csv
    .\Box-Administration-Transcript-Log-Date.log
    
.EXAMPLE
    cd "$Path" where $Path is the directory path where store the program
    .\Box-Administration.ps1

.NOTES
    Creation Date : 2020/04/30
    Author : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    
    Version 1.0
    Updated Date : 2022/05/15
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Powershell script creation
    Update       : Add module : '.\Box-Module.psm1'
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
    Update       : Add Chrome Driver version in function : chrome version installed on the device
    Update       : Add Test-FolderPath et Test-FilePath functions
    Update       : Add Get-UsbRight function
    Update       : Correct missing settings and syntaxe for HTML report
    Update       : Add function : Get-ParentalControlScheduler
    Update       : Add missing IPV6 part on all page.
    Update       : Add missing elements in all functions
    Update       : Correct information put in logs files
    Update       : Reorganize Box-Module.psm1 to more clarify
    Update       : Hide ChromeDriver Service console and Chrome driver Application
    Update       : Add requirements
    Update       : Adjust remote connection port
    Update       : Force to create Logs Folder
    Update       : Solved problem in function : 'Get-ConnexionType' when relaunch the script keep the old user selection
    Update       : Solved display title for HTML report and CSV file
    Update       : Add new Log type for device logs
    Update       : Correct functions to collect log informations
    Update       : Add new features available since version 19.2.12
    Update       : Correct properties in function : 'Get-Airties'
    Update       : Add new function : 'Get-Nat' - Get Nat Configuration Information
    Update       : Correct wifi scan when use remote Box connexion, function : 'Start-RefreshWIRELESSFrequencyNeighborhoodScan'
    Update       : Correct Active Host session by host, function : 'Get-WANDAASH'
    Update       : Modify Display date format for HTML report
    Update       : Add new function : 'Get-HOSTSPAUTH' => Get HOSTS PAUTH Information
    Update       : Add new function : 'Format-Date' => To format the custom date to the standard one / Replace in functions in '.\Box-Module.psm1'
    Update       : Add new function : 'Remove-FolderContent' => To remove export folder content Add in Box-Module.psm1
    Update       : Add new requests in file : '.\Ressources\API-Summary.csv' => Remove-FCLogs / Remove-FCExportCSV / Remove-FCExportJSON / Remove-FCJournal / Remove-FCJBC / Remove-FCReport
    Update       : Add 3 last Chrome Drivers versions : 93.0.4577.15 / 92.0.4515.43 / 91.0.4472.101
    Update       : Modify function : 'Get-DeviceToken' in '.\Box-Module.psm1'
    Update       : Add new properties in existing functions
    
    Version 2.0
    Updated Date : 2022/01/13
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Add 2 new functions : 'Switch-DisplayFormat' and 'Switch-ExportFormat' in '.\Box-Module.psm1'
    Update       : Add new requests in file : '.\Ressources\API-Summary.csv' => Switch-DisplayFormat / Switch-ExportFormat
    Update       : Add new function : 'EmptyFormatedDATA' in '.\Box-Module.psm1'
    Update       : Add new logs informations
    Update       : Correct Syntaxt
    Update       : Correct Program Sequence order
    Update       : Add new functions : 'Format-DisplayResult' and 'Format-ExportResult'
    Update       : Add Varible : '$logFileName' and '$FormatedDataExclusion'
    Update       : Rename variable : '$Info' and function property '-Info' to '$Label' and 'Label' in '.\Box-Module.psm1' and '.\Box-Administration.ps1'
    Update       : Rename variable : '$Pages' and function property '-Pages' to '$APIsName' and 'APIsName' in '.\Box-Administration.ps1'
    Update       : Rename variable : '$Page' and function property '-Page' to '$APIName' and 'APIName'
    Update       : Add new function : 'Stop-Program' in '.\Box-Module.psm1'
    Update       : Update logs file content
    Update       : Add Chrome Driver Log Path in Chrome Driver Option in function : 'Start-ChromeDriver'
    Update       : Add Transcript logs file
    Update       : Change Google Chrome installation path detection
    Update       : Correct bug with HTML Report in function : 'GET-DYNDNSPL' (Missing first line to display)
    Update       : Disable All Extentions at chrome Driver startup in function : 'Start-ChromeDriver'
    Update       : Change common footer in HTML Report
    Update       : Modify Header title from 'Record' to 'Record Type' in function : 'Get-DYNDNSClient'
    Update       : Correct bug in function : 'Get-DYNDNS' (No data get after request)
    Update       : Modify remember check remote Box connection only if remote instead of both.
    Update       : Modify comments if Box dns not responding when program analyse your network connection.
    Update       : Modify comment when program quit (System / User)
    Update       : Change function's name from 'Get-WPS' to 'Get-WIRELESSWPS'
    Update       : Correct bug in function : 'Get-WIRELESSWPS' (Missing data to collect)
    Update       : Add date in file name export/report
    Update       : Add dynamic folder path in function : 'Export-BoxConfiguration' => modify also function : 'Switch-Info'
    Update       : Correct Log file Name display when program closing
    Update       : Modify functions : 'Test-FilePath' and 'Test-FolderPath'
    Update       : Change 'Get-BoxJournal' function logic
    Update       : Add new function : 'Get-CPLDeviceList' in module : '.\Box-Module.psm1'
    Update       : Modify function : 'Get-CPL'
    Update       : Modify function : 'Get-BackupList'
    Update       : Update function : 'Get-DeviceToken' with the date time format was changed
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
    Update       : Update function : 'Get-BoxJournal' change download files method
    Update       : Correct function : 'Stop-ChromeDriver' when chrome driver not yet started
    Update       : Correct the log name in function : 'Stop-Program'
    
    Version 2.1 - Box version 20.8.6
    Updated Date : 2022/02/16
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Update logs files / Correct missing information in functions from Box-Module.psm1
    Update       : Correct Switch $APIName for 'Default' way
    Update       : Correct Grammatical Syntaxe
    Update       : Change order code in function : 'Start-RefreshWIRELESSFrequencyNeighborhoodScan'
    Update       : Simplify paramerters in functions : 'Export-BoxConfiguration', 'Export-BoxConfigTestingProgram', 'Switch-Info', 'Get-WIRELESSFrequencyNeighborhoodScan'
    Update       : Correct data format in function : 'Get-WIRELESSFrequencyNeighborhoodScanID'
    Update       : Optimise code logic to manage Local / remote connection with web uri
    Update       : Remove function : 'Switch-ConnectionType' in module : '.\Box-Module.psm1'
    Update       : Add new function : 'Get-PasswordRecoveryVerify' in module : '.\Box-Module.psm1'
    Update       : Add new information in function : 'Get-FIREWALLPingResponder'
    Update       : Correct SolvedTime information in function : 'Get-LANAlerts'
    Update       : Rename function : 'Get-NOTIFICATION' to 'Get-NOTIFICATIONConfig'
    Update       : Add New informations (Events/Contacts) in function : 'Get-NOTIFICATIONConfig'
    Update       : Add 3 New functions : 'Get-NOTIFICATIONConfigAlerts', 'Get-NOTIFICATIONConfigContacts', 'Get-NOTIFICATIONConfigEvents' in module : '.\Box-Module.psm1'
    Update       : Correct some headers/values in fonctions in module : '.\Box-Module.psm1'
    Update       : Correct function : 'Get-VOIPFullCallLogLineX' in module : '.\Box-Module.psm1'
    Update       : Add function : 'Export-GlobalOutputData' in module : '.\Box-Module.psm1'
    Update       : Box in version 20.8.6
    Update       : Add function : 'Get-WANSFF' in module : '.\Box-Module.psm1'
    Update       : Add function : 'Get-WIRELESSVideoBridgeSetTopBoxes' and modify 'Get-Status' in module : '.\Box-Module.psm1'
    Update       : Add function : 'Get-WIRELESSVideoBridgeRepeaters' in module : '.\Box-Module.psm1'

    Version 2.2 - Box version 20.8.8
    Updated Date : 2022/05/18
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Change display date format in functions : 'Get-DeviceLog', 'Get-DeviceFullLog', 'Get-DeviceFullTechnicalLog', 'Get-Device', 'Get-DeviceFullTechnicalLog', 'Get-DeviceToken', 'Get-DeviceSummary', 'Get-DYNDNSClient', 'Get-HOSTS', 'Get-HOSTSME', 'Get-IPTVDiags', 'Get-LANAlerts', 'GET-PARENTALCONTROL', 'Get-ParentalControlScheduler', 'Get-SUMMARY', 'Get-UPNPIGDRules', 'Get-VOIPScheduler', 'Get-WANAutowan', 'Get-WANDiagsSessions', 'et-WIRELESSScheduler'
    Update       : Replace variable $ID by $Index and $log by $Line in functions : 'Get-DeviceLog', 'Get-DeviceFullLog', 'Get-DeviceFullTechnicalLog'
    Update       : Remove function : 'Format-Date'
    
    Version 2.3 - Box version 20.8.8
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
    Update       : Change function organization for better loading/run program in file : '.\Box-Module.psm1'
    Update       : Optimise 'Switch' function with 'Break' in files : '.\Box-Aministration.ps1' and '.\Box-Module.psm1'
    Update       : Change order checks in file : '.\Box-Aministration.ps1'
    Update       : Create 'regions' ([region]/[endregion]) to structure the code in files : '.\Box-Aministration.ps1' and '.\Box-Module.psm1'
    Update       : Update syntaxe for logs file and user console display
    Update       : Correct function : 'Get-APIRessourcesMap', remove double 'API/V1' syntaxe
    Update       : Correct function : 'Export-GlobalOutputData' to manage when '$FormatedData' is null or empty
    Update       : Add new function : 'Show-WindowsFormDialogBox' to display user messsage as dialogBox
    Update       : Add new function : 'Show-WindowsFormDialogBoxInput' to get user messsage as dialogBox input
    Update       : Add new function : 'Show-WindowsFormDialogBox2Choices' to get user choice as dialogBox press button among 2 choices
    Update       : Add new function : 'Show-WindowsFormDialogBox2ChoicesCancel' to get user choice as dialogBox press button among 2 choices with 'Cancel' option
    Update       : Add new function : 'Show-WindowsFormDialogBox3Choices' to get user choice as dialogBox press button among 3 choices
    Update       : Add new function : 'Show-WindowsFormDialogBox3ChoicesCancel' to get user choice as dialogBox press button among 3 choices with 'Cancel' option
    Update       : Update functions : 'Start-RefreshWIRELESSFrequencyNeighborhoodScan' and 'Get-PortStatus' and 'Get-HostStatus' and 'Get-ConnexionType' and 'Get-PhoneLineID' and 'Switch-OpenHTMLReport' and 'Switch-ExportFormat' and 'Switch-DisplayFormat' with new functions
    Update       : Update function : 'Connect-Box' to manage if wrong password enter to connect to Box web interface
    Update       : Change default value for : '$global:TriggerExitSystem' from '0' to '$null'
    Update       : Optimise syntaxe code for string of characters
    Update       : New Varaiable : '$global:TriggerDialogBox' to manage if DialogBox need to be display or not
    Update       : Update functions : 'Get-HostStatus' and 'Get-PortStatus' to integrate Windows Form Dialog Box
    Update       : Replace ALL 'Write-Host' by 'Write-Log' function
    Update       : Display warning action for end-user with function : 'Show-WindowsFormDialogBox'
    Update       : Change Start Chromedriver and Box authentification only if not already launched and if it is not a local program action
    Update       : Change '.\Settings-Program.json' file structure
    Update       : Update function : 'Get-BoxInformation' to catch better API errors
    Update       : Update function : 'Stop-Program' to manage better Google Chrome and ChromeDriver closing
    Update       : Optimise function : 'Switch-Info' to remove old value don't used
    Update       : Change Windows Form position and size
    
    Version 2.4 - Box version 20.8.8
    Updated Date : 2022/09/23
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : #Requires -Version 7.0
    Update       : Add new function : 'Import-CredentialManager' to manage credential in 'Windows Credential Manager'
    Update       : Install / import new module : 'TUN.CredentialManager'
    Update       : Add new function : 'Import-TUNCredentialManager'
    Update       : Add new 'links' : https://www.powershellgallery.com/packages/TUN.CredentialManager
    Update       : Requires to use PowerShell Version 7.0
    Update       : Add new functions : 'Remove-BoxCredential', 'Show-BoxCredential', 'Add-BoxCredential' to manage Box Credential in 'Windows Credential Manager'
    Update       : Add PowerShell Script Admin Execution control
    Update       : Add new block to install / Import Powershell module : 'TUN.CredentialManager'
    Update       : switch position block 'Presentation'
    Update       : Update function : 'Stop-Program'
    Update       : update credentials setting in user json configuration files : '.\Ressources\Settings-Current-User.json' and '.\Ressources\Settings-Default-User.json'
    Update       : Update functions : 'Export-GlobalOutputData' and 'EmptyFormatedDATA'
    Update       : Change Windows Form position and size
    Update       : Optimise functions : 'Show-WindowsFormDialogBoxInput','Show-WindowsFormDialogBox2Choices','Show-WindowsFormDialogBox2ChoicesCancel','Show-WindowsFormDialogBox3Choices','Show-WindowsFormDialogBox3ChoicesCancel' to better manage the position Boxes
    Update       : Update ChromeDriver version to : 104.0.5112.79, 105.0.5195.52, 106.0.5249.21
    Update       : Update function : 'Show-BoxCredential' to manage error when no password has been set to 'Windows Credential Manager'
    Update       : Update function : 'Add-BoxCredential' to display the password set to 'Windows Credential Manager'
    Update       : Update function : 'Get-BackupList', add WindowsFormDialogBox when no backup file found
    
    Version 2.5 - Box version 20.8.8
    Updated Date : 2022/09/27
    Updated By   : Thomas LANDEL alias @Zardrilokis => Tom78_91_45@yahoo.fr
    Update       : Update json program file : '.\Settings-Program.json'
    Update       : Add new function : 'Update-ChromeDriver' to manage ChromeDriver update
    Update       : Add new parameter in function : 'Get-ChromeDriverVersion' => -ChromeDriverPath
    Update       : Update defaut chrome driver to version : 106.0.5249.21
    
    Version 2.6 - Box version 22.3.12
    Updated Date : 2023/02/20
    Update       : Update program to be conmpabible with : Box version 22.3.12
    Update       : Add new function : 'Get-WIRELESSFastScanMe'
    Update       : Modify function : 'Get-APIRessourcesMap', correct field : 'API url' with the complete URL
    Update       : Update File configuration : '.\Settings-Default-User.json', '.\Settings-Default-User.json', '.\Settings-Current-User.json'
    Update       : Update File : '.\API-Summary.csv'
    Update       : Update propose to user to re-use or not the existing stored password or define a new one
    Update       : Add new function : 'Switch-OpenExportFolder'
    Update       : Update function : 'Switch-Info', 'Export-toCSV', 'Export-toJSON', 'Export-BoxConfiguration', 'Export-BoxConfigTestingProgram'
    Update       : Update 'Export-*' function to open the output folder where data were exported
    Update       : update setting in json configuration files : '.\Ressources\Settings-Current-User.json' and '.\Ressources\Settings-Default-User.json'
    Update       : Update File : '.\API-Summary.csv'
    Update       : Hide/Reduce chrome and chromedriver Window
    Update       : Update syntaxe in function : 'Get-BackupList'
    Update       : Use Resolve-DnsName function to resole HostName from IP address
    Update       : Correct some display bug in functions when data has been exported
    Update       : Manage if Box authentification is needed or not, depending of Box connection (Local/Remote)
    Update       : Add region to stop and update Google Chrome with winget cmlt
    Update       : Add new function : 'Reset-CurrentUserProgramConfiguration' to reset user configuration during program runnning
    Update       : Correct display syntaxe when output folders opened
    Update       : Change order 'Update Chrome Driver' and 'Update Google Chrome' and the control between the 2 versions
    Update       : Correct 'BoxUrlFirewall' setting in function : 'Get-HostStatus' and 'Get-PortStatus'
    Update       : Debug function : 'Get-PortStatus'
    Update       : Debug function : Switch-OpenExportFolder

    Version 2.7 - Box version 23.7.12
    Updated Date : 2024/10/17
    Update       : Update function : 'Get-WANIP' - Add Resolution IPV6 dns servers
    Update       : Create function : 'Get-WIRELESSSTANDARD' - Get Wireless standard available configuration
    Update       : Update function : 'Get-WIRELESSACL' - Add parameter 'Rules Count'
    Update       : Update functions : 'Get-WANAutowan' and 'Get-WIRELESSRepeater'
    Update       : Update functions : 'Get-HOSTS' and 'Get-HOSTSME' => correct IPV6 address format
    Update       : Create function : 'Get-LastSeenDate' - Modify $(Get-Date).AddSeconds(-X) where X is the time in seconds
    Update       : Create function : 'Edit-Date' - Add to rewrite date format to human readable
    Update       : Remove function : 'Get-Airties' -  Depreciated
    Update       : Update program to be compatible with : Box version 22.3.16
    Update       : Update function : 'Export-BoxConfiguration' - Add output in csv in // of Json
    Update       : Remove function : 'Get-WIRELESSFastScanMe' - Depreciated since Box version 22.3.16
    Update       : Change/switch some command lines in block : 'Update Google Chrome version'
    Update       : Update function : 'Export-BoxConfiguration' - Update Filter
    Update       : Update function : 'Write-Log' - Change Log disposition for better reading
    Update       : Update function : 'Get-HOSTSME' - Display message when no informations found
    Update       : Update 'Settings-Program.json' - Add 'Sleep' part
    Update       : Update function : 'Import-TUNCredentialManager' and 'Update-ChromeDriver' and 'Start-RefreshWIRELESSFrequencyNeighborhoodScan'
    Update       : Add function : 'Get-ChromeDriverVersion' to help to check existing Chrome Driver version
    Update       : Update defaut chrome driver to version : 112.0.5615.49
    Update       : Update functions : 'Get-DeviceLog' and 'Get-DeviceFullLog' and 'Get-DeviceFullTechnicalLog' - Add new entries not yet managed (LAN_BAD_SUBNET,LAN_DUPLICATE_IP)
    Update       : Update function : 'Get-NOTIFICATIONConfigEvents' - Add new headers : Index,Type,Scope,ShortName
    Update       : Update function : 'Get-NOTIFICATIONConfig' - Change Headers
    Update       : Rename functions from : 'Get-NOTIFICATIONConfigAlerts' to : 'Get-NOTIFICATIONAlerts' and from : 'Get-NOTIFICATIONConfigContacts' to : 'Get-NOTIFICATIONContacts' and from : 'Get-NOTIFICATIONConfigEvents' to : 'Get-NOTIFICATIONEvents'
    Update       : Remove functions : 'Get-NOTIFICATIONAlerts' and 'Get-NOTIFICATIONContacts' and 'Get-NOTIFICATIONEvents' - Due to duplicates functions
    Update       : Update function : 'Switch-Info'
    Update       : Rename Function from : 'Get-NOTIFICATIONConfigAlerts' to : 'Get-NOTIFICATIONAlerts' and from : 'Get-NOTIFICATIONConfigContacts' to : 'Get-NOTIFICATIONContacts' and from : 'Get-NOTIFICATIONConfigEvents' to : 'Get-NOTIFICATIONEvents'
    Update       : Update File : '.\API-Summary.csv'
    Update       : Update function : 'Get-NOTIFICATIONAlerts' - Add Header 'Mail' to see at which email addresses was sent the alerts
    Update       : Update function : 'Get-USERSAVE' - Change date format
    Update       : Add new function : 'Get-DeviceConnectionHistoryLog' and  'Get-DeviceConnectionHistoryLogID' - Get Log connexion history for devices
    Update       : Update File : '.\API-Summary.csv'
    Update       : Update defaut chrome driver to version : 113.0.5672.24
    Update       : Update log file : 'Box_Administration_Log-Date.csv' and 'Box-Administration-Transcript-Log-Date.log'
    Update       : Update function : 'Update-ChromeDriver' - Correct Folder creation, Unzip issue, DLLs files copy
    Update       : Add foreach custom function in module : '.\Box-Module.psm1' A get-help based on comments
    Update       : Add foreach custom function their functions dependencies if exist in the header. Use 'get-help' for more details (https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.core/get-help)
    Update       : Update function : 'Get-PortStatus' - Add more help to diagnostize
    Update       : Update 'Site.CurrentLocalUrl' parameter in Json files : '.\Ressources\Settings-Default-User.json' and '.\Ressources\Settings-Current-User.json'
    Update       : Add 'Box.UrlPrefixe' parameter in Json file : '.\Ressources\Settings-Program.json' and remplace 'https://' by '$global:UrlPrefixe'
    Update       : Update File : '.\API-Summary.csv' - Correct wrong function association and syntaxe
    Update       : Update function : 'Show-WindowsFormDialogBoxInuput' - Add new parameter : 'DefaultValue' - Define Default value in the input field
    Update       : Switch settings between in Json files : '.\Ressources\Settings-Default-User.json' and '.\Ressources\Settings-Current-User.json'
    Update       : Update variables linked to JSON files and convert it from 'Local:' to 'Global:'
    Update       : Correct some minor bugs
    Update       : Harmonize function : 'Start-sleep'
    Update       : Optimise and convert variables from 'Local:' to 'Global:' (Reduce repetition and single usage text value to centralise management to JSON files configuration)
    Update       : Correct some minor bugs link to chromeDriver TimeOut
    Update       : Update function : 'Update-ChromeDriver' - Correct issue with chromedriver download not completed
    Update       : Update defaut chrome driver to version : 114.0.5735.91
    Update       : Update function : 'Get-BackupList' - Correct wrong return value if there is no data
    Update       : Update function : 'Get-HOSTSME' - Correct syntaxe property : 'ping.result' => 'ping.results'
    Update       : Update 'Credentials.*' parameters in Json files : '.\Ressources\Settings-Default-User.json' and '.\Ressources\Settings-Current-User.json'
    Update       : Add Box menu selection for end user
    Update       : Add 'Box.TypeList' and 'Box.Freebox' parameter in Json file : '.\Ressources\Settings-Program.json'
    Update       : Add New test files path ("Freebox-API-Summary.csv") from "Ressources" folder
    Update       : Update function : 'Show-WindowsFormDialogBox4ChoicesCancel' - New WindowsForm with 4 Choices (Last is Cancel)
    Update       : Update function : 'Export-HTMLReport' - Change Html Footer Report
    Update       : Switch from Google Chrome Setup Installation to Google Chrome Standalone Installation
    Update       : Add testing New folders and files path for Standalone Google Chrome
    Update       : Re-organize parameters in Json file : '.\Ressources\Settings-Program.json'
    Update       : Add new function : 'Open-ExportFolder' and 'Set-TriggerOpenExportFolder' - To Optimize and mutualize openning export folder or not (Code optimisation)
    Update       : Add new Log when a setting is Set/Modify in Json files : '.\Ressources\Settings-Default-User.json' and '.\Ressources\Settings-Current-User.json' and '.\Ressources\Settings-Program.json'
    Update       : Switch to Standalone Google Chrome version instead of Legacy (Local) installation
    Update       : Add new function : 'Set-ValueToJSONFile' - To set value(s) to JSON File (Code optimisation)
    Update       : Update functions : 'Stop-ChromeDriver' and 'Stop-Program' - Update new ChromeDriver and Google Chrome Standalone files location
    Update       : Remove parameter -ChromeDriverPath from 'GoogleChrome' and 'GoogleDriver' functions and replace variable from 'ChromeDriverPath' to 'global:ChromeDriverPath'
    Update       : Remove old functions that will be never used
    Update       : Change Google Driver and Google Chrome system update
    Update       : Add new comments in the log files
    Update       : Modify and Add nnew parameters in Json file : '.\Ressources\Settings-Program.json'
    Update       : Harmonize Variable Name in the script and the module for more understanding
    Update       : Correct Syntaxe error in function 'Get-HOSTSME' - error message : 'InvalidOperation: Index operation failed; the array index evaluated to null.'
    Update       : Update function : 'Update-ChromeDriver' - Due to logic change for the system update.
    Update       : Add function : 'Update-GoogleChrome' - To manage separately Chrome Driver and Google Chrome Update - Even if version are linked.
    Update       : Add New CSV file : '.\Ressources\CommonsFunctions' - To centralize in the same file location the commons actions linked to the program and dissociated from Box Api functions
    Update       : Add function : 'Import-Referential' - To import multi referential files function Box Type
    Update       : Add new links for freebox and api urls
    Update       : Update functions : 'Show-BoxCredential', 'Add-BoxCredential', 'Get-JSONSettingsCurrentUserContent', 'Get-JSONSettingsDefaultUserContent' - Add FreeBox password management
    Update       : Add New Folder in Export path to manage many box
    Update       : Add new settings in configuration json files and Freebox API Name referential CSV file
    Update       : Add new fonctions linked to Freebox management only
    Update       : Modify function : 'Get-ChromeDriverVersion' to help to check existing Chrome Driver version
    Update       : Add function : 'Get-GoogleChromeVersion' to help to check existing Google Chrome version
    Update       : Update function : 'Get-HostStatus'
    Update       : Add function : 'Get-LastestStableChromeVersionOnline', to get the Lastest Stable Version for Chrome Driver and Google Chrome
    Update       : Update function : 'Update-ChromeDriver' and 'Update-GoogleChrome' , due to a change with Chrome Driver and Google Chrome update management
    Update       : Update function : 'Get-Device', to add new settings
    Update       : Update function : 'Write-Log', Add new sub-folder to Hierachize log files
    Update       : Update function : Add some custom properties in function for more information in some export
    Update       : Add function : 'Get-HOSTSWireless' to get 'Wireless Hosts' Informations
    Update       : Add function : 'Get-HOSTSDownloadThreshold' to get Box Download Threshold
    Update       : Add function : 'Get-LANPortStats' to get LAN Port Stats
    Update       : Update defaut chrome driver to version : 123.0.6312.58
    Update       : Update defaut Google chrome to version : 123.0.6312.105
    Update       : Update functions linked to function : "Switch-Function"
    Update       : Rename function from : 'Get-VOIPDiag' to : 'Get-VOIPDiagLine'
    Update       : Add function : 'Get-VOIPDiagConfig', to have VOIP Diag Summary
    Update       : Update system config file : '.\Ressources\Settings-Program.json' parameter : 'ChromeDriverLastStableVersionUrl' to : 'https://getwebdriver.com/chromedriver/api/LATEST_RELEASE_STABLE'
    Update       : Update logs files : '.\Logs\*\*-Box_Administration_Log.csv' and '.\Logs\*\*-Box-Administration-Transcript-Log.log'
    Update       : Correct minor bugs and code syntaxe
    Update       : Split function 'Get-LANIP' in 2 new functions : 'Get-LANIPConfig' and 'Get-LANIPSwitchConfig'
    Update       : Split function 'Get-WANAutowan' in 2 new functions : 'Get-WANAutowanConfig' and 'Get-WANAutowanProfiles'
    Update       : Update functions : 'Export-HTMLReport' and 'Out-GridviewDisplay' and 'Export-BoxConfiguration'
    Update       : Correct function : 'Get-USBStorage' - Issue with Json parameter ($Json.file_info.count instead of : $Json.count)
    Update       : Update function : 'Get-WANDiagsAllActiveSessions' - Simplify Resolve-DnsName for IPV4 Address Only
    Update       : Add function : 'Get-DynDnsStatusErrorMessageDetail' and 'Get-DynDnsStatusValidMessageDetail' to clarify Error and Valid message based on DYNDNS Client from function : 'Get-DYNDNSClient'
    Update       : Add function : 'Get-DynDnsRecordDetail'to clarify DynDns Record Type
    Update       : Update function : 'Get-BoxInformation' - Clarify Box API error message or if data collected are empty or null
    Update       : Update function : 'Get-DeviceConnectionHistoryLog' Start log date corrected
    Update       : Add functions : 'Get-VOIPCallLogLineXPhoneNumber' and 'Get-VOIPFullCallLogLineXPhoneNumber' to get all call from a phone number and associated details
    Update       : Update function : 'Stop-Program' add new parameter '-Context' with 2 possible values : 'User' and 'System'
    Update       : Update function : 'Get-DHCPActiveOptions' - Add more informations/details for better understading
    Update       : Correct function :'Get-LANPortStats' - Correct JSON path
    Update       : Add function :'Remove-FolderContentAll' - to delete all files from all folders known by program
    Update       : Correct syntaxe error and ajust text for end user for better understanding
    Update       : Update function : 'Stop-Program' add 2 new parameter '-ErrorMessage' (To get error message) and '-Reason' (To add more explaintion for better Human understanding)
    Update       : Switch Chrome driver request to invoke web request to optimize the download for Chrome Driver and Google Chrome StandAlone version to local
    Update       : Update program to use 'Invoke-WebRequest' Powershell cmlet when no autentification is mandatory to get json data and optimize the run program
    Update       : Chrome driver is use only to get data if autentification is mandatory with (Local / Remote) access (Public / Private) permissions
    Update       : Add New function : 'Export-ProgramFilesCount'
    Update       : Add 2 New functions : 'Get-VOIPCallLogLineXSummary' and 'Get-VOIPFullCallLogLineXSummary' to manage and summary calls receive to the 2 phone lines and have a better look on it
    Update       : Update function : 'Stop-Program' for more clear information when user close the program - Add 4 new parameters : -Context (User/System) -ErrorMessage (System Error message) -Reason (Reason of the error message)
    Update       : Update Connexion to the box and the 2 functions : 'Get-HostStatus' and 'Get-PortStatus' to better error management when user input is on error
    Update       : Update function : 'Switch-Info' with new functions
    Update       : Update configuration files : ".\Ressources\Common-Functions.csv" and ".\Ressources\BBox-API-Summary.csv" with new functions created
    Update       : Add new function : 'Export-ModuleFunctions' - To export all details of function stored in the file module : '.\BOX-Module.psm1'
    Update       : Modify configuration file : '.\Ressources\Settings-Program.json' and new settings lincked to the new function
    Update       : Add details about Module : '.\BOX-Module.psm1'
    Update       : Add new function : 'Export-ModuleHelp' - to get information regarding the module details
    Update       : Rename function from : 'Get-LastestStableChromeVersion' to : 'Get-LastestStableChromeVersionOnline'
    Update       : Update functions : 'Update-ChromeDriver' and 'Update-GoogleChrome' - Adapt functions with 'Invoke-webRequest' instead of Chrome driver for better performance and
    Update       : Optimize code in the script : '.\BBOX-Administration.ps1'
    Update       : Add new function : 'Uninstall-TUNCredentialManager' to uninstall the module : 'TUNCredentialManager'
    Update       : Add new function : 'Uninstall-Program' to uninstall the program and all features
    Update       : Rename function from : 'Import-TUNCredentialManager' to : 'Install-TUNCredentialManager' for more understanding
    Update       : Cleaning old code lines that are only for devlopement and help to switch to the new web request type
    Update       : Add Help 'Template' for each function and Powershell file to use 'Get-help' with it - Functions that Export data from API web request are not documented because this is the same build
    Update       : Update log files for better understanding - Add parameter '-Category' for better filtering logs when trouble shooting
    Update       : Add new file configuration : '.\Ressources\Known-Phone-Number.csv' - This file can be manged manualy or by the program
    Update       : Update function : 'Import-Referential' - Add 2 new Parameters : 'LogCategory' and 'LogName'
    Update       : Update functions : 'Get-VOIPCallLogLineX', 'Get-VOIPCallLogLineXSummary', 'Get-VOIPFullCallLogLineX', 'Get-VOIPFullCallLogLineXSummary',  'Get-VOIPAllowedListNumber' - To have contact details based on CSV file for reference - To be completed manually or by the program it self
    Update       : Add new function : 'Show-WindowsFormDialogBox8Inuput' - To allow user to give 5 inputs information
    Update       : Add new function : 'Show-ReferentialContact' - To have a look the register contact for BBox
    Update       : Add new function : 'Add-NewReferentialContact' - To add a new contact to BBox Annuary
    Update       : Add new function : 'Remove-ReferentialContact' - To remove a contact from BBox Annuary
    Update       : Add new function : 'Show-WindowsFormDialogBox5ChoicesCancel' - New WindowsForm with 5 Choices (Last is Cancel)
    Update       : Rename All function to separate BOX's functions (BBox,FREEBox,ORANGEBox,SFRBox) for better understanding
    Update       : Add new function : 'Get-BoxCredential' - To get All Box password registred in Windows Credential Manager
    Update       : Modify configuration file : '.\Ressources\Settings-Program.json' - Reorganize schema for better understanding
    Update       : Restructure folder and sub-folder of : "Ressources"
    Update       : Update function : 'Export-ModuleFunctions' - Add new parameters for better export in CSV and txt format and separate level of details
    Update       : Update and correct 'Write-Log' function and add Logs 'Start/End' comments for better reading and understantding
    Update       : Add new function : 'Show-WindowsFormDialogBox6ChoicesCancel' - New WindowsForm with 6 Choices (Last is Cancel)
    Update       : Add new button 'Program' to have access only to 'program' actions without box action in the same toolbox
    Update       : Update wrong log syntaxe (Category and Name)
    
.LINKS
    
    https://maBBox.bytel.fr/
    https://maBBox.bytel.fr/api/v1
    https://www.BBox-mag.fr/Box/firmware/
    https://api.BBox.fr/doc/
    https://api.BBox.fr/doc/apirouter/index.html
    https://mafreebox.freebox.fr
    https://mafreebox.freebox.fr/api/v4
    https://dev.freebox.fr/sdk/os/
    https://chromedriver.chromium.org/
    https://www.powershellgallery.com/packages/TUN.CredentialManager
    http://winstonfassett.com/blog/2010/09/21/html-to-text-conversion-in-powershell/
    https://learn.microsoft.com/fr-fr/powershell/module/microsoft.powershell.core/get-help
    
#>

#region Initialisation

#region function

# Imported by module : '.\BoxModule.psm1'

function Write-Log {
    
<#
    .SYNOPSIS
    Write-Log allow to written fonctional execution logs

    .DESCRIPTION
    Write log on the host console and a csv file
#>
    Param (
        [Parameter(Mandatory=$True)]
        [ValidateSet('INFO','INFONO','VALUE','WARNING','ERROR','DEBUG')]
        [String]$Type,
        
        [Parameter(Mandatory=$True)]
        [ValidateSet('Program initialisation','Program Run','Program Stop')]
        [String]$Category,
        
        [Parameter(Mandatory=$True)]
        [String]$Name,
        
        [Parameter(Mandatory=$True)]
        [String]$Message,
        
        [Parameter()]
        [switch]$NotDisplay,
        
        [Parameter(Mandatory=$false)]
        [String]$LogName = "$global:LogDateFolderNamePath\$global:LogFileName"
    )
    
    $LogPath = $logName + '.csv'
    
    # Create log object 
    $log = [pscustomobject] @{Date=(Get-Date -UFormat %Y%m%d_%H%M%S) ; PID=$PID ; User= $(whoami) ; Type=$Yype ; Category=$Category ; Name=$Name ; Message=$Message} 
    $log | Add-Member -Name ToString -MemberType ScriptMethod -value {$this.Date + ' : ' + $this.Type + ' : ' + $this.Category + ' : ' +$this.Name + ' : ' + $this.Message} -Force 
    
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
        
        If (-not (Test-Path $LogPath)) {
            Out-File -FilePath $LogPath -Encoding unicode -Append -InputObject "Date;PID;User;Type;Category;Name;Message" 
        }
        Out-File -FilePath $LogPath -Encoding unicode -Append -InputObject "$($Log.Date);$($Log.PID);$($Log.User);$($Log.Type);$($Log.Category);$($Log.Name);$($Log.Message)" 
    }
    Finally {
        $mtx.ReleaseMutex()
    }
}

#endregion function

#region Main Variables

# Global Script Date
$Date = $(get-date -Format yyyyMMdd)

# Logs file
$ScriptRootFolderPath          = $PSScriptRoot
$global:LogFileName            = "$Date-Box_Administration_Log"
$global:LogFolderName          = 'Logs'
$global:LogFolderNamePath      = "$ScriptRootFolderPath\$global:LogFolderName"
$global:LogDateFolderNamePath  = "$global:LogFolderNamePath\$Date"

$Null = New-Item -Path $ScriptRootFolderPath -Name $global:LogFolderName -ItemType Directory -Force -ErrorAction Stop

# Transcript Logs
$global:TranscriptFileName = "$Date-Box-Administration-Transcript-Log.log"
$TranscriptFileNamePath    = "$global:LogDateFolderNamePath\$global:TranscriptFileName"

# System Json Configuration files
$global:RessourcesFolderName                 = 'Ressources'
$global:RessourcesFolderNamePath             = "$ScriptRootFolderPath\$global:RessourcesFolderName"
$ProgramFolderName                           = 'Program'
$ProgramRessourcesFolderNamePath             = "$global:RessourcesFolderNamePath\$ProgramFolderName"
$ProgramConfigurationSettingsFileName        = 'Settings-Program.json'
$global:ProgramConfigurationFileSettingsPath = "$ProgramRessourcesFolderNamePath\$ProgramConfigurationSettingsFileName"

# Main Trigger
$global:TriggerExitUser         = $Null
$global:TriggerExitSystem       = $Null
$global:TriggerDialogBox        = $Null
$global:TriggerExportConfig     = $Null
$TriggerLANNetwork              = $Null
$global:TriggerAuthentification = $Null
$global:TriggerDialogBox        = $Null

# URL Settings for the ChromeDriver request
$UrlRoot    = $Null
$Port       = $Null
$UrlAuth    = $Null
$UrlHome    = $Null
$UrlToGo    = $Null
$DYNDNS     = $Null

#endregion Main Variables

#region Start Program initialisation

Start-Transcript -Path $TranscriptFileNamePath -Append -Force -NoClobber
$Name     = 'Start Initialisation'
$Category = 'Program initialisation'
Write-Log -Type WARNING -Category $Category -Name $Name -Message '#################################################### Initialisation #####################################################'
Write-Log -Type INFO    -Category $Category -Name $Name -Message "Start $Category" -NotDisplay
Write-Log -Type INFO    -Category $Category -Name $Name -Message 'Program Initialisation takes times due to :'
Write-Log -Type INFO    -Category $Category -Name $Name -Message '- If Standalone Chrome Driver and Google Chrome version need to be updated or not'
Write-Log -Type INFO    -Category $Category -Name $Name -Message '- Your internet speed connexion'
Write-Log -Type INFO    -Category $Category -Name $Name -Message '- Your computer performance'
Write-Log -Type INFO    -Category $Category -Name $Name -Message 'Program loading ...'

#endregion Start Program initialisation

#region Create logs folder

$Name     = 'Logs Folder Creation'
$Category = 'Program initialisation'
Write-Log -Type VALUE -Category $Category -Name $Name -Message "Step 1/10) : $Name"

If (-not (Test-Path -Path $ScriptRootFolderPath)) {
    
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name status : " -NotDisplay

    Try {
        $Null = New-Item -Path $ScriptRootFolderPath -Name $global:LogFolderName -ItemType Directory -Force -ErrorAction Stop
        Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Successful' -NotDisplay
        Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category $Category -Name $Name -Message "Failed, due to :$($_.string())" -NotDisplay
        Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
    }
}
Else {
    Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Already exist' -NotDisplay
    Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
}

#endregion Create logs folder

#region Import System Json Configuration files

If ($Null -eq $global:TriggerExitSystem) {

    $Category = 'Program initialisation'
    $Name  = 'Import JSON Settings Program'
    
    Write-Log -Type VALUE  -Category $Category -Name $Name -Message 'Step 2/10) : JSON Settings Program Importation'
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name Status : " -NotDisplay
    Try {
        $global:JSONSettingsProgramContent = Get-Content -Path $global:ProgramConfigurationFileSettingsPath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Successful' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category $Category -Name $Name -Message "Failed, due to : $($_.ToString())"
        $global:JSONSettingsProgramContent = $Null
        $global:TriggerExitSystem = 1
    }
    Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
}

#endregion Import System Json Configuration files

#region Load System Json Configuration files

If (($Null -eq $global:TriggerExitSystem) -and ($Null -ne $global:JSONSettingsProgramContent)) {
    
    $Category = 'Program initialisation'
    $Name  = 'Load JSON Settings Program'
    
    Write-Log -Type VALUE  -Category $Category -Name $Name -Message 'Step 3/10) : JSON Settings Program Loading'
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "$Name file path : $global:ProgramConfigurationFileSettingsPath" -NotDisplay
    Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name Status : " -NotDisplay

    Try {        
        # Paths
        $global:JournalName                        = $global:JSONSettingsProgramContent.Path.JournalName
        $global:HelpFolderNamePath                 = "$ScriptRootFolderPath\" + $global:JSONSettingsProgramContent.Path.HelpFolderName
        $BoxModuleFileNamePath                     = "$ScriptRootFolderPath\" + $global:JSONSettingsProgramContent.Path.BoxModuleFileName + $global:JSONSettingsProgramContent.Values.PowershellModuleFileExtention
        $TUNCredentialManagerModuleFileName        = $global:JSONSettingsProgramContent.Path.TUNCredentialManagerModuleFileName
        $JournalFolderNamePath                     = "$ScriptRootFolderPath\" + $global:JSONSettingsProgramContent.Path.JournalFolderName
        $BBOXJournalFolderNamePath                 = "$JournalFolderNamePath\" + $global:JSONSettingsProgramContent.Box.BBox.Name
        $FREEBOXJournalFolderNamePath              = "$JournalFolderNamePath\" + $global:JSONSettingsProgramContent.Box.Freebox.Name
        $JsonBoxconfigFolderNamePath               = "$ScriptRootFolderPath\" + $global:JSONSettingsProgramContent.Path.JsonBoxconfigFolderName
        $BBOXJsonBoxconfigFolderNamePath           = "$JsonBoxconfigFolderNamePath\" + $global:JSONSettingsProgramContent.Box.BBox.Name
        $FREEBOXJsonBoxconfigFolderNamePath        = "$JsonBoxconfigFolderNamePath\" + $global:JSONSettingsProgramContent.Box.Freebox.Name
        $ReportFolderNamePath                      = "$ScriptRootFolderPath\" + $global:JSONSettingsProgramContent.Path.ReportFolderName
        $BBOXReportFolderNamePath                  = "$ReportFolderNamePath\" + $global:JSONSettingsProgramContent.Box.BBox.Name
        $FREEBOXReportFolderNamePath               = "$ReportFolderNamePath\" + $global:JSONSettingsProgramContent.Box.Freebox.Name
        $global:RessourcesFolderNamePath           = "$ScriptRootFolderPath\" + $global:JSONSettingsProgramContent.Path.RessourcesFolderName
        $ProgramRessourcesFolderNamePath           = "$global:RessourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Ressources.ProgramFolderName
        $TestedEnvironnementFileNamePath           = "$ProgramRessourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Ressources.Program.TestedEnvironnementFileName
        $CommonFunctionsFileNamePath               = "$ProgramRessourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Ressources.Program.CommonFunctionsFileName
        $BoxRessourcesFolderNamePath               = "$global:RessourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Path.BoxFolderName
        $FREEBOXResssourcesFolderNamePath          = "$BoxRessourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Box.Freebox.Name
        $BBoxResssourcesFolderNamePath             = "$BoxRessourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Box.BBox.Name
        $BBoxAPISummaryFileNamePath                = "$BBoxResssourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Box.BBox.APISummaryFileName
        $global:PhoneNumberReferentialFileNamePath = "$BBoxResssourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Box.BBox.PhoneNumberReferentialFileName
        $FREEBOXAPISummaryFileNamePath             = "$FREEBOXResssourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Box.Freebox.APISummaryFileName
        $ExportFolderNamePath                      = "$ScriptRootFolderPath\" + $global:JSONSettingsProgramContent.Path.ExportFolderName
        $ExportJSONFolderNamePath                  = "$ExportFolderNamePath\" + $global:JSONSettingsProgramContent.Path.ExportJSONFolderName
        $BBOXExportJSONFolderNamePath              = "$ExportJSONFolderNamePath\" + $global:JSONSettingsProgramContent.Box.BBox.Name
        $FREEBOXExportJSONFolderNamePath           = "$ExportJSONFolderNamePath\" + $global:JSONSettingsProgramContent.Box.Freebox.Name
        $ExportCSVFolderNamePath                   = "$ExportFolderNamePath\" + $global:JSONSettingsProgramContent.Path.ExportCSVFolderName
        $BBOXExportCSVFolderNamePath               = "$ExportCSVFolderNamePath\" + $global:JSONSettingsProgramContent.Box.BBox.Name
        $FREEBOXExportCSVFolderNamePath            = "$ExportCSVFolderNamePath\" + $global:JSONSettingsProgramContent.Box.Freebox.Name
        $global:DownloadShellRegistryFolder        = $global:JSONSettingsProgramContent.Path.DownloadShellRegistryFolder
        $global:DownloadShellRegistryFolderName    = $global:JSONSettingsProgramContent.Path.DownloadShellRegistryFolderName
        
        # JSON User Configuration File Paths
        $global:JSONSettingsDefaultUserFileNamePath = "$ProgramRessourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Ressources.Program.UserConfigurationFile.DefaultFileName
        $global:JSONSettingsCurrentUserFileNamePath = "$ProgramRessourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Ressources.Program.UserConfigurationFile.CurrentFileName
                
        # Chrome Driver Paths
        $global:ChromeDriver                                    = $Null
        $global:ChromeDriverLastStableVersion                   = $Null
        $ApplicationsFolderNamePath                             = "$global:RessourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Ressources.ApplicationsFolderName
        $global:ChromeDriverRessourcesFolderNamePath            = "$ApplicationsFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Ressources.Applications.ChromeDriver.ChromeDriverRessourcesFolderName
        $global:ChromeDriverDefaultFolderName                   = $global:JSONSettingsProgramContent.Path.Ressources.Applications.ChromeDriver.ChromeDriverDefaultFolderName
        $global:ChromeDriverDefaultFolderNamePath               = "$global:ChromeDriverRessourcesFolderNamePath\$global:ChromeDriverDefaultFolderName"
        $global:ChromeDriverDefaultSetupFileName                = $global:JSONSettingsProgramContent.Path.Ressources.Applications.ChromeDriver.ChromeDriverDefaultSetupFileName
        $global:ChromeDriverDefaultSetupFileNamePath            = "$global:ChromeDriverDefaultFolderNamePath\$global:ChromeDriverDefaultSetupFileName"
        $ChromeDriverDLLFolderNamePath                          = "$global:RessourcesFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Ressources.ChromeDriverDLLFolderName
        $global:ChromeDriverDefaultWebDriverDLLFileName         = $global:JSONSettingsProgramContent.Path.Ressources.Applications.ChromeDriver.ChromeDriverDefaultWebDriverDLLFileName
        $global:ChromeDriverDefaultWebDriverDLLFileNamePath     = "$ChromeDriverDLLFolderNamePath\$global:ChromeDriverDefaultWebDriverDLLFileName"
        $global:ChromeDriverDefaultWebDriverSupportFileName     = $global:JSONSettingsProgramContent.Path.Ressources.Applications.ChromeDriver.ChromeDriverDefaultWebDriverSupportFileName
        $global:ChromeDriverDefaultWebDriverSupportFileNamePath = "$ChromeDriverDLLFolderNamePath\$global:ChromeDriverDefaultWebDriverSupportFileName"
        $global:ChromeDriverLastStableVersionUrl                = $global:JSONSettingsProgramContent.Path.Ressources.Applications.ChromeDriver.ChromeDriverLastStableVersionUrl
        $global:ChromeDriverDownloadHomeUrl                     = $global:JSONSettingsProgramContent.Path.Ressources.Applications.ChromeDriver.ChromeDriverDownloadHomeUrl
        $global:ChromeDriverDownloadPathUrl                     = $global:JSONSettingsProgramContent.Path.Ressources.Applications.ChromeDriver.ChromeDriverDownloadPathUrl
        $global:ChromeDriverDownloadFileName                    = $global:JSONSettingsProgramContent.Path.Ressources.Applications.ChromeDriver.ChromeDriverDownloadFileName
        
        # Google Chrome Paths
        $global:GoogleChromeRessourcesFolderNamePath  = "$ApplicationsFolderNamePath\" + $global:JSONSettingsProgramContent.Path.Ressources.Applications.GoogleChrome.GoogleChromeRessourcesFolderName
        $global:GoogleChromeDefaultFolderName         = $global:JSONSettingsProgramContent.Path.Ressources.Applications.GoogleChrome.GoogleChromeDefaultFolderName
        $global:GoogleChromeDefaultFolderNamePath     = "$global:GoogleChromeRessourcesFolderNamePath\$global:GoogleChromeDefaultFolderName"
        $GoogleChromeDefaultSetupFileName             = $global:JSONSettingsProgramContent.Path.Ressources.Applications.GoogleChrome.GoogleChromeDefaultSetupFileName
        $Global:GoogleChromeDefaultSetupFileNamePath  = "$global:GoogleChromeDefaultFolderNamePath\$GoogleChromeDefaultSetupFileName"
        $GoogleChromeDefaultProfileName               = $global:JSONSettingsProgramContent.Path.Ressources.Applications.GoogleChrome.GoogleChromeDefaultProfileName
        $global:GoogleChromeDownloadHomeUrl           = $global:JSONSettingsProgramContent.Path.Ressources.Applications.GoogleChrome.GoogleChromeDownloadHomeUrl
        $global:GoogleChromeDownloadPathUrl           = $global:JSONSettingsProgramContent.Path.Ressources.Applications.GoogleChrome.GoogleChromeDownloadPathUrl
        $global:GoogleChromeDownloadFileName          = $global:JSONSettingsProgramContent.Path.Ressources.Applications.GoogleChrome.GoogleChromeDownloadFileName
        $global:GoogleChromeDownloadFileNameExtention = $global:JSONSettingsProgramContent.Path.Ressources.Applications.GoogleChrome.GoogleChromeDownloadFileNameExtention
        
        # APIName
        $APINameAvailable                   = $global:JSONSettingsProgramContent.APIName.Available
        $global:APINameExclusionsChrome     = $global:JSONSettingsProgramContent.APIName.Exclusions.Chrome
        $APINameExclusionsFull              = $global:JSONSettingsProgramContent.APIName.Exclusions.Full
        
        #Scope
        $ScopeExclusionsFull                = $global:JSONSettingsProgramContent.Scope.Exclusions.Full
        
        # Actions
        $ActionExclusionsFullTestingProgram = $global:JSONSettingsProgramContent.Action.Exclusions.FullTestingProgram
        
        # Box
        $BoxTypeList                        = $global:JSONSettingsProgramContent.Box.TypeList
        $global:UrlPrefixe                  = $global:JSONSettingsProgramContent.Box.UrlPrefixe
        
        # Various
        $Mail                               = $global:JSONSettingsProgramContent.various.mail
        $GitHubUrlSite                      = $global:JSONSettingsProgramContent.various.GitHubUrlSite
        
        # Notification Events
        $global:NotificationEventType       = $global:JSONSettingsProgramContent.Notification.Event.Type
        
        # FormatedData
        $global:FormatedDataExcludedValues  = $global:JSONSettingsProgramContent.FormatedData.ExcludedValues
        $global:FormatedDataGlobalOutputDataExclusion = $global:JSONSettingsProgramContent.FormatedData.GlobalOutputDataExclusion
        
        # Start-Sleep
        $global:SleepDefault                                  = $global:JSONSettingsProgramContent.Sleep.Default
        $global:SleepTUNCredentialManagerModuleinstallation   = $global:JSONSettingsProgramContent.Sleep.TUNCredentialManagerModuleinstallation
        $global:SleepRefreshWIRELESSFrequencyNeighborhoodScan = $global:JSONSettingsProgramContent.Sleep.RefreshWIRELESSFrequencyNeighborhoodScan
        $global:SleepChromeDriverDownload                     = $global:JSONSettingsProgramContent.Sleep.ChromeDriverDownload
        $global:SleepChromeDriverUnzip                        = $global:JSONSettingsProgramContent.Sleep.ChromeDriverUnzip
        $global:SleepChromeDriverNavigation                   = $global:JSONSettingsProgramContent.Sleep.ChromeDriverNavigation
        $global:SleepChromeDriverLoading                      = $global:JSONSettingsProgramContent.Sleep.ChromeDriverLoading
        $global:SleepBoxJournalDownload                       = $global:JSONSettingsProgramContent.Sleep.BoxJournalDownload
        
        # Values
        $global:ValuesLANNetworkLocal               = $global:JSONSettingsProgramContent.Values.LANNetworkLocal
        $global:ValuesLANNetworkRemote              = $global:JSONSettingsProgramContent.Values.LANNetworkRemote
        $global:ValuesOpenExportFolder              = $global:JSONSettingsProgramContent.Values.OpenExportFolder
        $global:ValuesDisplayFormat                 = $global:JSONSettingsProgramContent.Values.DisplayFormat
        $global:ValuesExportFormat                  = $global:JSONSettingsProgramContent.Values.ExportFormat
        $global:ValuesOpenHTMLReport                = $global:JSONSettingsProgramContent.Values.OpenHTMLReport
        $global:ValuesResolveDnsName                = $global:JSONSettingsProgramContent.Values.ResolveDnsName
        $global:ValuesLineNumber                    = $global:JSONSettingsProgramContent.Values.LineNumber
        $global:ValuesPowershellModuleFileExtention = $global:JSONSettingsProgramContent.Values.PowershellModuleFileExtention
        
        # Error
        $global:ErrorResolveDNSMessage = $global:JSONSettingsProgramContent.Error.ResolveDNS.Message
        $global:ErrorExceptiondomain   = $global:JSONSettingsProgramContent.Error.Exception.domain
        
        Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Successful' -NotDisplay
        Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category $Category -Name $Name -Message "Failed, due to : $($_.ToString())"
        Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        $global:TriggerExitSystem = 1
    }
}
Else {
    Write-Log -Type ERROR -Category $Category -Name $Name -Message "Failed, to : $Name"
    Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay

    $global:TriggerExitSystem = 1
}
#endregion Load System Json Configuration files

#region Import Functions with Module : 'Box-Module.psm1'

If ($Null -eq $global:TriggerExitSystem) {
    
    $Name     = 'Powershell Module Importation'
    $Category = 'Program initialisation'
    
    Write-Log -Type VALUE  -Category $Category -Name $Name -Message "Step 4/10) : $Name"
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Powershell Module Path : $BoxModuleFileNamePath" -NotDisplay
    Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name status : " -NotDisplay
    
    Try {
        Remove-Module -Name Box-Module -ErrorAction SilentlyContinue
    }
    Catch {
        Write-Log -Type ERROR -Category $Category -Name $Name -Message "Failed, Powershell Module $BoxModuleFileNamePath can't be removed, due to : $($_.ToString())"
        $global:TriggerExitSystem = 1
    }
    
    Start-Sleep $global:SleepDefault
    
    Try {
        Import-Module -Name $BoxModuleFileNamePath -ErrorAction Stop
        Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Successful' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category $Category -Name $Name -Message "Failed, Powershell Module $BoxModuleFileNamePath can't be imported due to : $($_.ToString())"
        $global:TriggerExitSystem = 1
    }
    
    Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
}

If ($Null -eq $global:TriggerExitSystem) {

    $ModuleName = $TUNCredentialManagerModuleFileName
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Powershell Module Path : $ModuleName" -NotDisplay
    Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name status : " -NotDisplay
    
    Try {
        Install-TUNCredentialManager -ModuleName $ModuleName -ErrorAction Stop
        Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Successful' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category $Category -Name $Name -Message "Failed, Powershell Module $ModuleName can't be installed or imported, due to : $($_.ToString())"
        $global:TriggerExitSystem = 1
    }
    Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
}

#endregion Import Functions with Module : 'Box-Module.psm1'

#region Check if ressources folder exist

If ($Null -eq $global:TriggerExitSystem) { 
    
    $Category = 'Program initialisation'
    $Name  = 'Ressources Folder Check'
    
    Write-Log -Type VALUE  -Category $Category -Name $Name -Message 'Step 5/10) : Folder Ressources Checking'
    Write-Log -Type INFO   -Category $Category -Name $Name -Message 'Start Folder Ressources Check' -NotDisplay
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Ressources Folder Path : $global:RessourcesFolderNamePath" -NotDisplay
    Write-Log -Type INFONO -Category $Category -Name $Name -Message 'Ressources Folder State : ' -NotDisplay
    
    If (Test-Path -Path $global:RessourcesFolderNamePath -ErrorAction Stop) {
    
        Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Already Exist' -NotDisplay
    }
    Else {
        Write-Log -Type ERROR -Category $Category -Name $Name -Message 'Not found'
        $global:TriggerExitSystem = 1
    }
    Write-Log -Type INFO -Category $Category -Name $Name -Message 'End Folder Ressources check' -NotDisplay
}

#endregion Check if ressources folder exist

#region Create folders/files if not yet existing

If ($Null -eq $global:TriggerExitSystem) {
    
    $Category = 'Program initialisation'
    $Name  = 'Program Folders/Files check'
    
    Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Step 6/10) : Program Folders/Files checking'
    Write-Log -Type INFO  -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    
    # Folders test
    Test-FolderPath -FolderRoot $ScriptRootFolderPath                        -FolderPath $ExportFolderNamePath                        -FolderName $ExportFolderNamePath                        -ErrorAction Stop
    Test-FolderPath -FolderRoot $ExportFolderNamePath                        -FolderPath $ExportCSVFolderNamePath                     -FolderName $ExportCSVFolderNamePath                     -ErrorAction Stop
    Test-FolderPath -FolderRoot $ExportFolderNamePath                        -FolderPath $ExportJSONFolderNamePath                    -FolderName $ExportJSONFolderNamePath                    -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolderPath                        -FolderPath $JournalFolderNamePath                       -FolderName $JournalFolderNamePath                       -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolderPath                        -FolderPath $ReportFolderNamePath                        -FolderName $ReportFolderNamePath                        -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolderPath                        -FolderPath $JsonBoxconfigFolderNamePath                 -FolderName $JsonBoxconfigFolderNamePath                 -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolderPath                        -FolderPath $global:HelpFolderNamePath                   -FolderName $global:HelpFolderNamePath                   -ErrorAction Stop
    Test-FolderPath -FolderRoot $ScriptRootFolderPath                        -FolderPath $global:RessourcesFolderNamePath             -FolderName $global:RessourcesFolderNamePath             -ErrorAction Stop
    Test-FolderPath -FolderRoot $global:RessourcesFolderNamePath             -FolderPath $ApplicationsFolderNamePath                  -FolderName $ApplicationsFolderNamePath                  -ErrorAction Stop
    Test-FolderPath -FolderRoot $global:RessourcesFolderNamePath             -FolderPath $BoxRessourcesFolderNamePath                 -FolderName $BoxRessourcesFolderNamePath                 -ErrorAction Stop
    Test-FolderPath -FolderRoot $global:RessourcesFolderNamePath             -FolderPath $ApplicationsFolderNamePath                  -FolderName $ApplicationsFolderNamePath                  -ErrorAction Stop
    Test-FolderPath -FolderRoot $global:RessourcesFolderNamePath             -FolderPath $ChromeDriverDLLFolderNamePath               -FolderName $ChromeDriverDLLFolderNamePath               -ErrorAction Stop
    Test-FolderPath -FolderRoot $global:RessourcesFolderNamePath             -FolderPath $ProgramRessourcesFolderNamePath             -FolderName $ProgramRessourcesFolderNamePath             -ErrorAction Stop
    Test-FolderPath -FolderRoot $ApplicationsFolderNamePath                  -FolderPath $global:ChromeDriverRessourcesFolderNamePath -FolderName $global:ChromeDriverRessourcesFolderNamePath -ErrorAction Stop
    Test-FolderPath -FolderRoot $ApplicationsFolderNamePath                  -FolderPath $global:GoogleChromeRessourcesFolderNamePath -FolderName $global:GoogleChromeRessourcesFolderNamePath -ErrorAction Stop
    Test-FolderPath -FolderRoot $global:ChromeDriverRessourcesFolderNamePath -FolderPath $global:ChromeDriverDefaultFolderNamePath    -FolderName $global:ChromeDriverDefaultFolderNamePath    -ErrorAction Stop
    Test-FolderPath -FolderRoot $global:GoogleChromeRessourcesFolderNamePath -FolderPath $global:GoogleChromeDefaultFolderNamePath    -FolderName $global:GoogleChromeDefaultFolderNamePath    -ErrorAction Stop
    
    # Export folder by Box Type
    Test-FolderPath -FolderRoot $JsonBoxconfigFolderNamePath     -FolderPath $BBOXJsonBoxconfigFolderNamePath    -FolderName $BBOXJsonBoxconfigFolderNamePath    -ErrorAction Stop
    Test-FolderPath -FolderRoot $JsonBoxconfigFolderNamePath     -FolderPath $FREEBOXJsonBoxconfigFolderNamePath -FolderName $FREEBOXJsonBoxconfigFolderNamePath -ErrorAction Stop
    Test-FolderPath -FolderRoot $ReportFolderNamePath            -FolderPath $BBOXReportFolderNamePath           -FolderName $BBOXReportFolderNamePath           -ErrorAction Stop
    Test-FolderPath -FolderRoot $ReportFolderNamePath            -FolderPath $FREEBOXReportFolderNamePath        -FolderName $FREEBOXReportFolderNamePath        -ErrorAction Stop
    Test-FolderPath -FolderRoot $ExportCSVFolderNamePath         -FolderPath $BBOXExportCSVFolderNamePath        -FolderName $BBOXExportCSVFolderNamePath        -ErrorAction Stop
    Test-FolderPath -FolderRoot $ExportCSVFolderNamePath         -FolderPath $FREEBOXExportCSVFolderNamePath     -FolderName $FREEBOXExportCSVFolderNamePath     -ErrorAction Stop
    Test-FolderPath -FolderRoot $ExportJSONFolderNamePath        -FolderPath $BBOXExportJSONFolderNamePath       -FolderName $BBOXExportJSONFolderNamePath       -ErrorAction Stop
    Test-FolderPath -FolderRoot $ExportJSONFolderNamePath        -FolderPath $FREEBOXExportJSONFolderNamePath    -FolderName $FREEBOXExportJSONFolderNamePath    -ErrorAction Stop
    Test-FolderPath -FolderRoot $JournalFolderNamePath           -FolderPath $BBOXJournalFolderNamePath          -FolderName $BBOXJournalFolderNamePath          -ErrorAction Stop
    Test-FolderPath -FolderRoot $JournalFolderNamePath           -FolderPath $FREEBOXJournalFolderNamePath       -FolderName $FREEBOXJournalFolderNamePath       -ErrorAction Stop
    
    # Files test
    Test-FilePath   -FileRoot $ProgramRessourcesFolderNamePath -FilePath $TestedEnvironnementFileNamePath                        -FileName $TestedEnvironnementFileNamePath                        -ErrorAction Stop
    Test-FilePath   -FileRoot $ProgramRessourcesFolderNamePath -FilePath $CommonFunctionsFileNamePath                            -FileName $CommonFunctionsFileNamePath                            -ErrorAction Stop
    Test-FilePath   -FileRoot $ProgramRessourcesFolderNamePath -FilePath $global:JSONSettingsDefaultUserFileNamePath             -FileName $global:JSONSettingsDefaultUserFileNamePath             -ErrorAction Stop
    Test-FilePath   -FileRoot $ProgramRessourcesFolderNamePath -FilePath $global:ProgramConfigurationFileSettingsPath            -FileName $global:ProgramConfigurationFileSettingsPath            -ErrorAction Stop
    Test-FilePath   -FileRoot $BBoxResssourcesFolderNamePath   -FilePath $BBoxAPISummaryFileNamePath                             -FileName $BBoxAPISummaryFileNamePath                             -ErrorAction Stop
    Test-FilePath   -FileRoot $BBoxResssourcesFolderNamePath   -FilePath $global:PhoneNumberReferentialFileNamePath              -FileName $global:PhoneNumberReferentialFileNamePath              -ErrorAction Stop
    Test-FilePath   -FileRoot $FREEBOXAPISummaryFileNamePath   -FilePath $FreeboxAPISummaryFileNamePath                          -FileName $FreeboxAPISummaryFileNamePath                          -ErrorAction Stop
    Test-FilePath   -FileRoot $ChromeDriverDLLFolderNamePath   -FilePath $global:ChromeDriverDefaultWebDriverDLLFileNamePath     -FileName $global:ChromeDriverDefaultWebDriverDLLFileNamePath     -ErrorAction Stop
    Test-FilePath   -FileRoot $ChromeDriverDLLFolderNamePath   -FilePath $global:ChromeDriverDefaultWebDriverSupportFileNamePath -FileName $global:ChromeDriverDefaultWebDriverSupportFileNamePath -ErrorAction Stop    
    
    Write-Log -Type INFO -Category $Category -Name $Name -Message 'End Program Folders/Files check' -NotDisplay
}

#endregion Create folders/files if not yet existing

#region Check Internet connection
Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Check Internet connection' -Message 'Step 7/10) : Check Internet connection'
#endregion Check Internet connection

#region Get Lastest Stable Chrome Version Online

If ($Null -eq $global:TriggerExitSystem) {
    
    $Name     = 'Get Lastest Stable Chrome Version Online'
    $Category = 'Program initialisation'
        
    Write-Log -Type VALUE -Category $Category -Name $Name -Message "Step 8/10) : $Name"
    Write-Log -Type INFO  -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    Get-LastestStableChromeVersionOnline -ChromeDriverLastStableVersionUrl $global:ChromeDriverLastStableVersionUrl -ErrorAction Stop
    Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
}

#endregion Get Lastest Stable Chrome Version Online

#region Check if Default Chrome Driver Standalone is already install else download and install it

If ($Null -eq $global:TriggerExitSystem) {
    
    $Name     = 'Default Chrome Driver Standalone Installation Version Check'
    $Category = 'Program initialisation'

    Write-Log -Type VALUE  -Category $Category -Name $Name -Message "Step 9/10) : $Name"
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay    
    Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name status : " -NotDisplay
    
    If ($(Test-Path -Path $global:ChromeDriverDefaultSetupFileNamePath) -eq $true) {
        
        Try {
            $ChromeDriverVersion = & $global:ChromeDriverDefaultSetupFileNamePath --version
            $ChromeDriverVersion = $($ChromeDriverVersion -split " ")[1]
            Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Successful' -NotDisplay
        }
        Catch {
            Write-Log -Type WARNING -Category $Category -Name $Name -Message 'To be download and install' -NotDisplay
            $ChromeDriverVersion = 'To be download and install'
        }
        
        Write-Log -Type INFO   -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        Write-Log -Type INFONO -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
        Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name :" -NotDisplay
        Write-Log -Type VALUE  -Category $Category -Name $Name -Message $ChromeDriverVersion -NotDisplay
        Write-Log -Type INFONO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        $Name = 'Control maching version Chrome Driver Standalone'
        Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
        Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name Status : " -NotDisplay
            
        If ($global:ChromeDriverLastStableVersion -notmatch $ChromeDriverVersion) {
            
            Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Failed' -NotDisplay
            Write-Log -Type INFO  -Category $Category -Name $Name -Message 'Updating Chrome Driver from version :' -NotDisplay
            Write-Log -Type VALUE -Category $Category -Name $Name -Message $ChromeDriverVersion -NotDisplay
            Write-Log -Type INFO  -Category $Category -Name $Name -Message ' to version :' -NotDisplay
            Write-Log -Type VALUE -Category $Category -Name $Name -Message $global:ChromeDriverLastStableVersion -NotDisplay
            Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
            $Name = 'Update Chrome Driver'
            Write-Log -Type INFO  -Category $Category -Name $Name -Message 'Start stop Chrome Driver' -NotDisplay
            
            Stop-ChromeDriver
            
            Write-Log -Type INFO -Category $Category -Name $Name -Message 'End stop Chrome Driver' -NotDisplay
            Write-Log -Type INFO -Category $Category -Name $Name -Message 'Start Remove Old Chrome Driver Version' -NotDisplay
            Remove-FolderContent -FolderRoot $global:ChromeDriverRessourcesFolderNamePath -FolderName $global:ChromeDriverDefaultFolderName
            Write-Log -Type INFO -Category $Category -Name $Name -Message 'End Remove Old Chrome Driver Version' -NotDisplay
            Write-Log -Type INFO -Category $Category -Name $Name -Message 'Start update Chrome Driver' -NotDisplay
            
            Update-ChromeDriver
            
            Write-Log -Type INFO -Category $Category -Name $Name -Message 'End update Chrome Driver' -NotDisplay
            Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        }
        Else {
            $Name = 'Control maching version Chrome Driver Standalone'
            Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Up to date' -NotDisplay
            Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
            Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        }
    }
    Else {
        $Name = 'Default Chrome Driver Standalone Installation Version Check'
        Write-Log -Type WARNING -Category $Category -Name $Name -Message 'To be download and install' -NotDisplay
        Write-Log -Type INFO    -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        $Name = 'Update Chrome Driver'
        Write-Log -Type INFO    -Category $Category -Name $Name -Message 'Start stop Chrome Driver' -NotDisplay
        
        Stop-ChromeDriver
        
        Write-Log -Type INFO -Category $Category -Name $Name -Message 'End stop Chrome Driver' -NotDisplay
        Write-Log -Type INFO -Category $Category -Name $Name -Message 'Start Remove Old Chrome Driver Version' -NotDisplay
        
        Remove-FolderContent -FolderRoot $global:ChromeDriverRessourcesFolderNamePath -FolderName $global:ChromeDriverDefaultFolderName
        
        Write-Log -Type INFO -Category $Category -Name $Name -Message 'End Remove Old Chrome Driver Version' -NotDisplay
        Write-Log -Type INFO -Category $Category -Name $Name -Message 'Start update Chrome Driver' -NotDisplay
        
        Update-ChromeDriver
        
        Write-Log -Type INFO -Category $Category -Name $Name -Message 'End update Chrome Driver' -NotDisplay
        $Name = 'Default Chrome Driver Standalone Installation Version Check'
        Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
    }
}

#endregion Check if Default Chrome Driver Standalone is already install else download and install it

#region Check if Default Google Chrome Standalone is already install else download and install it

If ($Null -eq $global:TriggerExitSystem) {
    
    $Category = 'Program initialisation'
    $Name  = 'Default Google Chrome Standalone Installation Version Check'
    
    Write-Log -Type VALUE  -Category $Category -Name $Name -Message "Step 10/10) : $Name"
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay    
    Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name status : " -NotDisplay
    
    If ($(Test-Path -Path $global:GoogleChromeDefaultSetupFileNamePath) -eq $true) {
        
        Try {
            $GoogleChromeVersion = $(Get-ItemProperty $Global:GoogleChromeDefaultSetupFileNamePath -ErrorAction Stop).VersionInfo.FileVersion
            Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Successful' -NotDisplay
        }
        Catch {
            #$GoogleChromeVersion = 'To be download and install'
            Write-Log -Type WARNING -Category $Category -Name $Name -Message 'To be download and install' -NotDisplay
        }
        
        Write-Log -Type INFO   -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        Write-Log -Type INFONO -Category $Category -Name $Name -Message "Start $Name Check" -NotDisplay
        Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name Check :" -NotDisplay
        Write-Log -Type VALUE  -Category $Category -Name $Name -Message $GoogleChromeVersion -NotDisplay
        Write-Log -Type INFONO -Category $Category -Name $Name -Message "End $Name Check" -NotDisplay
        $Name = 'Control maching version Google Chrome Standalone'
        Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
        Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name Status : " -NotDisplay
            
        If ($($global:GoogleChromeLastStableVersion -split('.')[0]) -gt $($GoogleChromeVersion.split('.')[0])) {
            
            Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Failed' -NotDisplay
            Write-Log -Type INFO  -Category $Category -Name $Name -Message 'Updating Google Chrome from version :' -NotDisplay
            Write-Log -Type VALUE -Category $Category -Name $Name -Message $GoogleChromeVersion -NotDisplay
            Write-Log -Type INFO  -Category $Category -Name $Name -Message ' to version :' -NotDisplay
            Write-Log -Type VALUE -Category $Category -Name $Name -Message $global:ChromeDriverLastStableVersion -NotDisplay
            Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
            $Name = 'Update Google Chrome'
            Write-Log -Type INFO  -Category $Category -Name $Name -Message 'Start stop Google Chrome' -NotDisplay
            
            Stop-ChromeDriver
            
            Write-Log -Type INFO -Category $Category -Name $Name -Message 'End stop Google Chrome' -NotDisplay
            Write-Log -Type INFO -Category $Category -Name $Name -Message 'Start Remove Old Google Chrome Version' -NotDisplay
            
            Remove-FolderContent -FolderRoot $global:GoogleChromeRessourcesFolderNamePath -FolderName $global:GoogleChromeDefaultFolderName
            
            Write-Log -Type INFO -Category $Category -Name $Name -Message 'End Remove Old Google Chrome Version' -NotDisplay
            
            Write-Log -Type INFO -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
            Update-GoogleChrome
            
            Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        }
        Else {
            $Name = 'Control maching version Google Chrome Standalone'
            Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Up to date' -NotDisplay
            Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
            $Name = 'Default Google Chrome Standalone Installation Version Check'
            Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        }
    }
    Else {
        Write-Log -Type WARNING -Category $Category -Name $Name -Message 'To be download and install' -NotDisplay
        Write-Log -Type INFO    -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        $Name = 'Update Google Chrome'
        Write-Log -Type INFO    -Category $Category -Name $Name -Message 'Start stop Google Chrome' -NotDisplay
        
        Stop-ChromeDriver
        
        Write-Log -Type INFO -Category $Category -Name $Name -Message 'End stop Google Chrome' -NotDisplay
        Write-Log -Type INFO -Category $Category -Name $Name -Message 'Start Remove Old Google Chrome Version' -NotDisplay
        
        Remove-FolderContent -FolderRoot $global:GoogleChromeRessourcesFolderNamePath -FolderName $global:GoogleChromeDefaultFolderName
        
        Write-Log -Type INFO -Category $Category -Name $Name -Message 'End Remove Old Google Chrome Version' -NotDisplay
        Write-Log -Type INFO -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
        
        Update-GoogleChrome
        
        Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        $Name = 'Default Google Chrome Standalone Installation Version Check'
        Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
    }
}

#endregion Check if Default Google Chrome Standalone is already install else download and install it

#region End Program Initialisation

$Name = 'End Initialisation'

Write-Log -Type INFONO -Category $Category -Name $Name -Message 'Status : '

If ($Null -eq $global:TriggerExitSystem) {
    
    Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Finished without errors'
}
Else {
    Write-Log -Type WARNING -Category $Category -Name $Name -Message 'Finished with errors'
    Stop-Program -Context System -ErrorMessage 'Finished with errors'  -Reason 'All Program prerequisites were not satisfyed' -ErrorAction Stop 
}

Write-Log -Type INFO    -Category $Category -Name $Name -Message 'End Program initialisation' -NotDisplay
Write-Log -Type WARNING -Category $Category -Name $Name -Message '#################################################### Initialisation #####################################################'

#endregion End Program Initialisation

#endregion Initialisation

#region User Actions

#region Box user selection

$Name = 'User Box Selection'

Write-Log -Type WARNING -Category $Category -Name $Name -Message '################################################## User Box Selection ###################################################'
Write-Log -Type INFO    -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
Write-Log -Type INFONO  -Category $Category -Name $Name -Message "$Name : "
$global:BoxType = Show-WindowsFormDialogBox6ChoicesCancel -MainFormTitle "$Name" -LabelMessageText "Please select your box below :" -FirstOptionButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.Bbox -SecondOptionButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.Freebox -ThirdOptionButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.OrangeBox -FourOptionButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.SFRBox -FiveOptionButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.Program -SixOptionButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.Cancel -ErrorAction Stop
Write-Log -Type VALUE   -Category $Category -Name $Name -Message "$global:BoxType"
Write-Log -Type INFO    -Category $Category -Name $Name -Message "End $Name" -NotDisplay
Write-Log -Type WARNING -Category $Category -Name $Name -Message '################################################## User Box Selection ###################################################'

#endregion Box user selection

#region Import User Json Configuration files

$Category = 'Program initialisation'
$Name     = 'Json Current User Settings Creation'

If (($Null -eq $global:TriggerExitSystem) -and (Test-Path -Path $global:JSONSettingsCurrentUserFileNamePath)) {
    
    Get-JSONSettingsCurrentUserContent -ErrorAction Stop
}
Else {
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name Status : " -NotDisplay
    Try {
        Copy-Item -Path $global:JSONSettingsDefaultUserFileNamePath -Destination $global:JSONSettingsCurrentUserFileNamePath -Force  -ErrorAction Stop
        Start-Sleep -Seconds $global:SleepChromeDriverNavigation
        Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Successful' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category $Category -Name $Name -Message "Failed, to create Json Current User Settings file, due to : $($_.ToString())"
        Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason 'Json Current User Settings file was not be created' -ErrorAction Stop
    }
    Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
    $Name = 'Json Current/Default User Settings Importation'
    Write-Log -Type INFO -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    
    If (Test-Path -Path $global:JSONSettingsCurrentUserFileNamePath) {
    
        Get-JSONSettingsCurrentUserContent -ErrorAction Stop
    }
    Elseif (Test-Path -Path $global:JSONSettingsDefaultUserFileNamePath) {
        
        Get-JSONSettingsDefaultUserContent -ErrorAction Stop
    }
    Else {
        Write-Log -Type ERROR -Category $Category -Name $Name -Message "Failed, to find any user settings configuration file, due to : $($_.ToString())"
        Write-Log -Type INFO  -Category $Category -Name $Name -Message "End $Name" -NotDisplay
        Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason 'User settings configuration file can not be found' -ErrorAction Stop
    }
    Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
}
#endregion Import User Json Configuration files

#region Load User Json Configuration files

$Name = 'User Box Selection'
Write-Log -Type INFO   -Category $Category -Name $Name -Message 'Start box is take in charge' -NotDisplay
Write-Log -Type INFONO -Category $Category -Name $Name -Message 'Is box is take in charge ? : ' -NotDisplay

If ($global:BoxType -match $BoxTypeList) {
    
    Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Yes' -NotDisplay
    $global:JSONSettingsCurrentUserContent.Box.OldType = $global:JSONSettingsCurrentUserContent.Box.CurrentType
    $global:JSONSettingsCurrentUserContent.Box.CurrentType = $global:BoxType
    Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath -ErrorAction Stop

    # Box
    $global:APIVersion            = $global:JSONSettingsProgramContent.Box.$global:BoxType.APIVersion
    $global:DefaultRemotePort     = $global:JSONSettingsProgramContent.Box.$global:BoxType.DefaultRemotePort
    $global:DefaultLocalUrl       = $global:JSONSettingsProgramContent.Box.$global:BoxType.DefaultLocalUrl
    $DefaultLocalIPAddress        = $global:JSONSettingsProgramContent.Box.$global:BoxType.DefaultLocalIPAddress
    $BoxDns                       = $global:JSONSettingsProgramContent.Box.$global:BoxType.BoxDns
    $global:BoxUrlRemote          = $global:JSONSettingsProgramContent.Box.$global:BoxType.BoxUrlRemote
    $global:BoxUrlFirewall        = $global:JSONSettingsProgramContent.Box.$global:BoxType.BoxUrlFirewall
    $global:BoxUrlDynDns          = $global:JSONSettingsProgramContent.Box.$global:BoxType.BoxUrlDynDns
    $BoxAPIUrlDocumentation       = $global:JSONSettingsProgramContent.Box.$global:BoxType.APIUrlDocumentation
    
    # User Credentials
    $global:CredentialsTarget     = $global:JSONSettingsProgramContent.Credentials.$global:BoxType.Target
    $global:CredentialsUserName   = $global:JSONSettingsProgramContent.Credentials.$global:BoxType.UserName
    $global:CredentialsComment    = $global:JSONSettingsProgramContent.Credentials.$global:BoxType.Comment
    
    # APIName
    $APINameExclusionsBoxTypeFull = $global:JSONSettingsProgramContent.APIName.Exclusions.$global:BoxType.Full
    
    # Paths
    $APISummaryFileNamePath       = "$BoxRessourcesFolderNamePath\$global:BoxType\" + $global:JSONSettingsProgramContent.Path.Box.$global:BoxType.APISummaryFileName
}
Else {
    Write-Log -Type ERROR -Category $Category -Name $Name -Message 'No' -NotDisplay
    Write-Log -Type ERROR -Category $Category -Name $Name -Message "The Box : $global:BoxType is not take in charge by the program."
    $Null = Show-WindowsFormDialogBox -Title "Box selection result" -Message "The Box : $global:BoxType is not take in charge by the program." -WarnIcon
    $global:JSONSettingsCurrentUserContent.Box.OldType     = $global:JSONSettingsCurrentUserContent.Box.CurrentType
    $global:JSONSettingsCurrentUserContent.Box.CurrentType = "Box Type not found in the referential"
    Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath -ErrorAction Stop
    Stop-Program -Context User -ErrorMessage 'Box Type not found in the referential' -Reason 'This Box Type was not found in the referential' -ErrorAction Stop
}
Write-Log -Type INFO -Category $Category -Name $Name -Message 'End box is take in charge' -NotDisplay

#endregion Load User Json Configuration files

#region Import Actions available

If ($Null -eq $global:TriggerExitSystem) {
    
    $Actions     = @()
    $Name        = 'Referentiel Actions Availables Importation'
    $LogCategory = 'Program initialisation'
    
    $Actions += Import-Referential -ReferentialPath $CommonFunctionsFileNamePath -LogCategory $LogCategory -LogName $Name -ErrorAction Stop
    
    If ($global:BoxType -notmatch 'Program') {
        $Actions += Import-Referential -ReferentialPath $APISummaryFileNamePath -LogCategory $LogCategory -LogName $Name -ErrorAction Stop
    }
}

#endregion Import Actions available

#region Import Phone Number referential

If ($Null -eq $global:TriggerExitSystem) {
    
    $Category = 'Program initialisation'
    $Name  = 'Referentiel Phone Number Importation'
    
    Write-Log INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    Write-Log INFONO -Category $Category -Name $Name -Message "$Name Status : " -NotDisplay

    Try {
        $global:PhoneNumberReferential = Import-Referential -ReferentialPath $global:PhoneNumberReferentialFileNamePath -LogCategory $Category -LogName $Name -ErrorAction Stop
        Write-Log VALUE -Category $Category -Name $Name -Message "Successful" -NotDisplay
    }
    Catch {
        Write-Log ERROR -Category $Category -Name $Name -Message "Failed, to import Referentiel Phone Number due to : $($_.ToString())"
    }
    Write-Log INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
}

#endregion Import Phone Number referential

#region Program Presentation

Write-Host '###################################################### Description ######################################################' -ForegroundColor Yellow
Write-Host 'This program is only available in English'
Write-Host 'This program requires the installation of PowerShell 7.0'
Write-Host 'It allows you to get, modify and delete information on :'$global:BoxType
Write-Host 'It displays advanced information that you will not see through the classic web interface of your :'$global:BoxType
Write-Host 'And this via a local or remote connection (Provided that you have activated the remote Box management => ' -NoNewline
Write-Host "$global:BoxUrlRemote)" -ForegroundColor Green
Write-Host 'The result can be displayed in HTML format or in table form (Gridview)'
Write-Host "The result can be exported in `" .csv (.csv) `" or `" .JSON (.JSON) `" format"
Write-Host 'The only limitation of this program is related to the requests available via the API installed on the target Box according to the model and the firmware version of this one'
Write-Host 'When displaying the result, some information may not be displayed, or may be missing :'
Write-Host '- Either its an oversight on my part in the context of the development, and I apologize in advance'
Write-Host '- Either this one is still under development'
Write-Host '- Either this information is optional and only appears in the presence of certain Box models :'
Write-Host '-- Box models'
Write-Host '-- Firmware version'
Write-Host '-- Available features'
Write-Host '-- Connection mode (Local / Remote)'
Write-Host 'For more information, please consult : ' -NoNewline
Write-Host "$BoxAPIUrlDocumentation" -ForegroundColor Green
Write-Host "Be carefull, this program is reserved for an advanced use of your : $global:BoxType settings and is aimed at an informed audience !" -ForegroundColor Yellow
Write-Host "Any improper handling risks causing partial or even total malfunction of your : $global:BoxType, rendering it unusable. You are Warned !" -ForegroundColor Yellow
Write-Host "Therefore, you use this program at your own risks, I can`'t be responsible if you dont use it in the correct environnement" -ForegroundColor Red
Write-Host "For any questions or additionals requests, contact me to this email address : " -NoNewline
Write-Host "$Mail" -ForegroundColor Green
Write-Host "Tested environnement list : "
Write-Host "- $TestedEnvironnementFileNamePath" -ForegroundColor Green
Write-Host 'Logs files location : '
Write-Host "- $global:LogDateFolderNamePath\$global:LogFileName*.csv" -ForegroundColor Green
Write-Host "- $TranscriptFileNamePath" -ForegroundColor Green

<#
Write-Host 'Last Successful tested environnement :'
Write-Log -Type INFO -Name 'Program presentation - Get tested environnements' -Message 'Start tested environnements' -NotDisplay
Write-Log -Type INFO -Name 'Program presentation - Get tested environnements' -Message 'Tested environnements importation status $TestedEnvironnementFileNamePath :' -NotDisplay
Try {
    $TestedEnvironnement = Import-Csv -Path $TestedEnvironnementFileNamePath -Delimiter ';' -ErrorAction Stop
    $TestedEnvironnement[0] | Format-List
    Write-Log -Type VALUE -Name 'Program presentation - Get tested environnements' -Message 'Successful' -NotDisplay
}
Catch {
    Write-Log -Type ERROR -Name 'Program presentation - Get tested environnements' -Message "Failed, to get tested environnements, due to : $($_.ToString())"
    $global:TriggerExitSystem = 1
}
Write-Host 'For others Successful tested environnement, please consult : ' -NoNewline
Write-Host "$TestedEnvironnementFileNamePath" -ForegroundColor Green
Write-Log -Type INFO -Name 'Program presentation - Get tested environnements' -Message 'End tested environnements' -NotDisplay
#>
Write-Host '##################################################### Description ######################################################' -ForegroundColor Yellow
#Pause

#endregion Program Presentation

#region Check if password already exist in Windows Credential Manager

If (($Null -eq $global:TriggerExitSystem) -and ($global:BoxType -notmatch 'Program')) {
    
    $Category = 'Program run'
    $Name     = 'Password Status'
    Write-Log -Type WARNING -Category $Category -Name 'User Password Action' -Message '################################################ User Password Action ##################################################'
    Write-Log -Type INFO    -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    Write-Log -Type INFONO  -Category $Category -Name $Name -Message "$Name : " -NotDisplay

    If ($null -eq ($(Get-StoredCredential -Target $global:CredentialsTarget -ErrorAction SilentlyContinue | Select-Object -Property Password -ErrorAction SilentlyContinue).password | ConvertFrom-SecureString -AsPlainText -ErrorAction SilentlyContinue)) {
        
        Write-Log -Type WARNING -Category $Category -Name $Name -Message 'Not yet set' -NotDisplay
        Try {
            Add-BoxCredential -ErrorAction Stop
            $UserPasswordAction = 'Define new password'
        }
        Catch {
            Write-Log -Type WARNING -Category $Category -Name $Name -Message "Password can't be set, du to : $($_.ToString())" -NotDisplay
            Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
            Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason 'Password can not be set' -ErrorAction Stop
        }
    }
    Else {
        Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Already Set' -NotDisplay
        $Answer = Show-WindowsFormDialogBox3ChoicesCancel -MainFormTitle $Name -LabelMessageText "$global:BoxType password is already set.`nWhat do you want to do ? :`n- (U) Use existing Password`n- (D) Define new password`n- (Q) Quit the program" -FirstOptionButtonText 'U' -SecondOptionButtonText 'D' -ThirdOptionButtonText 'Q'
        
        Switch ($Answer) {
            
            U       {$UserPasswordAction = 'Use existing password'
                     $Password = $(Get-StoredCredential -Target $global:CredentialsTarget | Select-Object -Property Password).password | ConvertFrom-SecureString -AsPlainText
                     
                     Break
                    }
            D       {$UserPasswordAction = 'Define new password (Replace Existing)'
                     Add-BoxCredential -ErrorAction Stop
                     Break
                    }
            Q       {$UserPasswordAction = 'Quit the program'
                     Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop
                     Break
                    }
            Default {$UserPasswordAction = 'Default - Use existing password'
                     $Password = $(Get-StoredCredential -Target $global:CredentialsTarget | Select-Object -Property Password).password | ConvertFrom-SecureString -AsPlainText
                     Break
                    }
        }
    }
    
    $Name = 'User Password Action'
    Write-Log -Type INFONO  -Category $Category -Name $Name -Message "User $Name : "
    Write-Log -Type VALUE   -Category $Category -Name $Name -Message $UserPasswordAction
    Write-Log -Type INFO    -Category $Category -Name $Name -Message "End $Name" -NotDisplay
    Write-Log -Type WARNING -Category $Category -Name $Name -Message '################################################ User Password Action ##################################################'
}

#endregion Check if password already exist in Windows Credential Manager

#region Check if user connect on the correct LAN Network

If (($Null -eq $global:TriggerExitSystem) -and ($global:BoxType -notmatch 'Program')) {
    
    $Category = 'Program run'
    $Name  = 'Network connection'

    Write-Log -Type INFO   -Category $Category -Name $Name -Message 'Start Check Box LAN network' -NotDisplay
    Write-Log -Type INFONO -Category $Category -Name $Name -Message 'Checking Box LAN network : ' -NotDisplay
    
    Try {
        $DnsName = Resolve-DnsName -Name $BoxDns -Type A -DnsOnly -ErrorAction Stop
        Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Successful' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category $Category -Name $Name -Message 'Failed' -NotDisplay
        Write-Log -Type ERROR -Category $Category -Name $Name -Message "Unable to resolve $BoxDns, due to : $($_.ToString())" -NotDisplay
    }
    If ($DnsName.IPAddress -eq $DefaultLocalIPAddress) {
        
        Write-Log -Type VALUE  -Category $Category -Name $Name -Message 'Connected to your Local Box Network' -NotDisplay
        Write-Log -Type INFONO -Category $Category -Name $Name -Message "$global:BoxType IP Address : " -NotDisplay
        Write-Log -Type VALUE  -Category $Category -Name $Name -Message $($DnsName.Address) -NotDisplay
        Write-Log -Type INFONO -Category $Category -Name $Name -Message 'Recommanded connection : ' -NotDisplay
        Write-Log -Type VALUE  -Category $Category -Name $Name -Message 'Localy' -NotDisplay
        $global:JSONSettingsCurrentUserContent.Site.$global:BoxType.CurrentLocalUrl = $BoxDns
        $TriggerLANNetwork = 1
    }
    Else {
        $null = Show-WindowsFormDialogBox -Title 'Program run - Network connection' -Message "It seems you are not connected to your Local $global:BoxType Network`n`n- If you are connected on your local network, make sure you are connected on the $global:BoxType's Wifi or ethernet network`n- If you use a intermediary router between your computer and the $global:BoxType router, it will not working" -InfoIcon
        Write-Log -Type INFONO -Category $Category -Name $Name -Message 'Recommanded connection : ' -NotDisplay
        Write-Log -Type VALUE  -Category $Category -Name $Name -Message 'Remotely' -NotDisplay
        $global:JSONSettingsCurrentUserContent.Site.$global:BoxType.CurrentLocalUrl = $global:ErrorResolveDNSMessage
        $TriggerLANNetwork = 0
    }
    
    Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath
    Write-Log -Type INFO -Category $Category -Name $Name -Message 'End Check Box LAN network' -NotDisplay
}

#endregion Check if user connect on the correct LAN Network

#region Ask to the user how he want to connect to the Box

If (($Null -eq $global:TriggerExitSystem) -and ($global:BoxType -notmatch 'Program')) {
    
    $Category = 'Program run'
    $Name     = 'Connexion Type'
    
    Write-Log -Type INFO -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    $ConnexionType = Get-ConnexionType -TriggerLANNetwork $TriggerLANNetwork -ErrorAction Stop
    Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
}

#endregion Ask to the user how he want to connect to the Box

#region Set Box connexion settings regarding user selection

If (($Null -eq $global:TriggerExitSystem) -and ($global:BoxType -notmatch 'Program')) {
    
    $Category = 'Program run'
    
    Write-Log -Type WARNING -Category $Category -Name 'User Connexion Type' -Message '############################################# User Connexion Type Choice ###############################################'
    
    Switch ($ConnexionType[0]) {
        
        L   {$UserConnexionTypeChosen = 'Localy'
             $UrlRoot = "$global:UrlPrefixe$BoxDns/$global:APIVersion"
             
             Switch ($global:BoxType) {
            
                BBOX    {$UrlAuth = "$global:UrlPrefixe$BoxDns" + $global:JSONSettingsProgramContent.Box.Bbox.BoxUrlLogin
                         $UrlHome = "$global:UrlPrefixe$BoxDns" + $global:JSONSettingsProgramContent.Box.Bbox.BoxUrlHomePage
                         Break
                        }
                FREEBOX {$UrlAuth = "$global:UrlPrefixe$BoxDns" + $global:JSONSettingsProgramContent.Box.freebox.BoxUrlLogin
                         $UrlHome = "$global:UrlPrefixe$BoxDns" + $global:JSONSettingsProgramContent.Box.freebox.BoxUrlHomePage
                         Break
                        }
             }
             Break
            }
        
        R   {$UserConnexionTypeChosen = 'Remotly'
             $Name = 'Check Host'
             Write-Log -Type INFO -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
             $DYNDNS = $($(Get-HostStatus) -split(" "))[-1]
             Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
             
             $Name = 'Check Port'
             Write-Log -Type INFO -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
             $Port = $($(Get-PortStatus -UrlRoot $DYNDNS) -split(" "))[-1]
             Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
             $UrlRoot = "$global:UrlPrefixe$DYNDNS`:$Port/$global:APIVersion"
            
                Switch ($global:BoxType) {
                
                    BBOX    {$UrlAuth = "$global:UrlPrefixe$DYNDNS`:$Port/login.html"
                             $UrlHome = "$global:UrlPrefixe$DYNDNS`:$Port/index.html"
                             Break
                            }
                    FREEBOX {$UrlAuth = "$global:UrlPrefixe$DYNDNS`:$Port/login.php"
                             $UrlHome = "$global:UrlPrefixe$DYNDNS`:$Port"
                             Break
                            }
                }
            }
        
        Q   {$UserConnexionTypeChosen = 'Quit the program'
             $global:TriggerExitSystem = 1
             Stop-Program -Context User -ErrorMessage '' -Reason 'User want to quit the program' -ErrorAction SilentlyContinue
             Break
            }
    }
    
    $Name = 'User Connexion Type'
    
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name Chosen : "
    Write-Log -Type VALUE  -Category $Category -Name $Name -Message "$UserConnexionTypeChosen"
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "End $Name" -NotDisplay
    
    $Name = 'Remote User Url Connexion choice'
    
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
    Write-Log -Type INFONO -Category $Category -Name $Name -Message "$Name : "
    Write-Log -Type VALUE  -Category $Category -Name $Name -Message "$UrlHome"
    Write-Log -Type INFO   -Category $Category -Name $Name -Message "End $Name" -NotDisplay
    
    If ($ConnexionType[0] -ne 'Q') {
        
        $Name = 'Connexion Type'
        Write-Log -Type INFO -Category $Category -Name $Name -Message "Root $global:BoxType Url : $UrlRoot"-NotDisplay
        Write-Log -Type INFO -Category $Category -Name $Name -Message "Login $global:BoxType Url : $UrlAuth" -NotDisplay
        Write-Log -Type INFO -Category $Category -Name $Name -Message "Home $global:BoxType Url : $UrlHome" -NotDisplay

        If ($Port) {
            Write-Log -Type INFO -Category $Category -Name $Name -Message "Remote $global:BoxType - Port : $Port" -NotDisplay
        }

        Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
    }

    Write-Log -Type WARNING -Category $Category -Name 'User Connexion Type' -Message '############################################# User Connexion Type Choice ###############################################'
}

#endregion Set Box connexion settings regarding user selection

#endregion User Actions

#region Program

#region process

$global:ChromeDriver = $Null
#$global:WebRequest = $Null

Write-Log -Type WARNING -Category $Category -Name 'Program Run' -Message '####################################################### Program ########################################################'

While ($Null -eq $global:TriggerExitSystem) {
    
    # Ask user action he wants to do (Get/PUT/POST/REMOVE)
    $Name = 'Action asked'
    Write-Log -Type INFO -Category $Category -Name $Name -Message 'Please select an action in the list'
    $Action = $Actions | Where-Object {$_.Available -eq 'Yes'} | Out-GridView -Title 'Please select an action in the list :' -OutputMode Single -ErrorAction Stop
    Write-Log -Type INFONO -Category $Category -Name $Name -Message 'Selected action : '
    
    If ($Null -ne $Action) {
        
        # Set value to variables
        $Label             = $Action.label
        $APIName           = $Action.APIName
        $Description       = $Action.Description
        $ReportType        = $Action.ReportType
        $ExportFile        = $Action.ExportFile
        $LocalPermissions  = $Action.LocalPermissions
        $RemotePermissions = $Action.RemotePermissions
        $Scope             = $Action.Scope
                
        Write-Log -Type VALUE -Category $Category -Name $Name -Message $Description
        Write-Log -Type INFO  -Category $Category -Name $Name -Message 'Start Is `"Program`" action chosen by user ?' -NotDisplay
        Write-Log -Type INFO  -Category $Category -Name $Name -Message 'Is `"Program`" action chosen by user ?' -NotDisplay
        
        If (($APIName -match $APINameExclusionsFull) -or ($Scope -notmatch $ScopeExclusionsFull)) {
            
            Write-Log -Type VALUE -Category $Category -Name $Name -Message 'No' -NotDisplay
            Write-Log -Type INFO  -Category $Category -Name $Name -Message 'End Is `"Program`" action chosen by user ?' -NotDisplay
            
            #region Start in Background chromeDriver
            $name = 'ChromeDriver Launch'
            Write-Log -Type INFO -Category $Category -Name $Name -Message 'Start ChromeDriver as backgroung process' -NotDisplay
                
            If (-not $global:ChromeDriver) {
                
                Write-Log -Type INFONO -Category $Category -Name $Name -Message 'Starting ChromeDriver as backgroung process ... : '
                
                Try {
                    Start-ChromeDriver -ChromeBinaryPath $Global:GoogleChromeDefaultSetupFileNamePath -DownloadPath $JournalFolderNamePath -LogsPath $global:LogDateFolderNamePath -ChromeDriverDefaultProfile $GoogleChromeDefaultProfileName -ErrorAction Stop
                    Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Started'
                }
                Catch {
                    Write-Log -Type ERROR -Category $Category -Name $Name -Message "Failed, ChromeDriver can't be started, due to : $($_.ToString())"
                    Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason 'ChromeDriver can not be started' -ErrorAction Stop
                }
                
                Write-Log -Type INFO -Category $Category -Name $Name -Message 'End ChromeDriver as backgroung process' -NotDisplay
            }
            Else {
                Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Not needed' -NotDisplay
                Write-Log -Type INFO  -Category $Category -Name $Name -Message 'End ChromeDriver as backgroung process' -NotDisplay
            }
            
            Write-Log -Type INFO -Category $Category -Name $Name -Message 'End ChromeDriver as backgroung process' -NotDisplay
            #endregion Start in Background chromeDriver
            
            $Name = 'Action asked'
            Write-Log -Type INFO -Category $Category -Name $Name -Message 'Is `"Private`" permissions need to access to data ?' -NotDisplay
            
            If (($RemotePermissions -eq 'private') -or ($LocalPermissions -eq 'private') -or ($RemotePermissions -eq 'computer') -or ($RemotePermissions -eq 'computer')) {
                
                Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Yes' -NotDisplay
                
                #region Start Box Authentification
                $Name = 'Box Authentification'
                Write-Log -Type INFONO -Category $Category -Name $Name -Message "Is $Name need ? :" -NotDisplay
                
                If ($Null -eq $global:TriggerAuthentification) {
                    
                    Write-Log -Type VALUE  -Category $Category -Name $Name -Message 'Required' -NotDisplay
                    Write-Log -Type INFO   -Category $Category -Name $Name -Message "Start $Name" -NotDisplay
                    Write-Log -Type INFONO -Category $Category -Name $Name -Message "Starting $Name : "
                    
                    Try {
                        $Password = $(Get-StoredCredential -Target $global:CredentialsTarget -ErrorAction Stop | Select-Object -Property Password -ErrorAction Stop).password | ConvertFrom-SecureString -AsPlainText -ErrorAction Stop
                        
                        Switch ($global:BoxType) {
                            
                            Bbox    {Connect-BBox -UrlAuth $UrlAuth -UrlHome $UrlHome -Password $Password -ErrorAction Stop;Break}
                            Freebox {Connect-FREEBOX -UrlAuth $UrlAuth -UrlHome $UrlHome -Password $Password -ErrorAction Stop;Break}
                        }
                        
                        Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Authentificated'
                        Clear-Variable -Name Password
                        $global:TriggerAuthentification = 1
                    }
                    Catch {
                        Write-Log -Type ERROR -Category $Category -Name $Name -Message "Failed, Authentification can't be done, due to : $($_.ToString())"
                        Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason "$Name can not be done" -ErrorAction Stop
                    }
                    Write-Log -Type INFO -Category $Category -Name $Name -Message "End $Name" -NotDisplay
                }
                Else {
                    Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Already done' -NotDisplay
                }
                #endregion Start Box Authentification
            }
            Else {
                $Name = 'Action asked'
                Write-Log -Type VALUE -Category $Category -Name $Name -Message 'No' -NotDisplay
            }
        }
        Else {
            $Name = 'Action asked'
            Write-Log -Type VALUE -Category $Category -Name $Name -Message 'Yes' -NotDisplay
            Write-Log -Type INFO  -Category $Category -Name $Name -Message 'End Is `"Program`" action chosen by user ?' -NotDisplay
        }
        
        #region Get data
        Switch ($APIName) {
            
            Full                   {$APISName = $Actions | Where-Object {(($_.Available -eq $APINameAvailable) -and ($_.Scope -notmatch $ScopeExclusionsFull) -and ($_.APIName -notmatch $APINameExclusionsBoxTypeFull) -and ($_.Label -match "Get-") -and ($_.APIUrl -notmatch "`{id`}"))} | Select-Object Label,APIName,Exportfile,ReportType,Description
                                    $global:TriggerExportConfig = $true
                                    Export-BoxConfiguration -APISName $APISName -UrlRoot $UrlRoot -JSONFolder $JsonBoxconfigFolderNamePath -CSVFolder $ExportCSVFolderNamePath -ReportPath $ReportFolderNamePath -GitHubUrlSite $GitHubUrlSite -JournalPath $JournalFolderNamePath -Mail $Mail
                                    Break
                                   }
            
            Full_Testing_Program   {$APISName = $Actions | Where-Object {(($_.Available -eq $APINameAvailable) -and ($_.Action -notmatch $ActionExclusionsFullTestingProgram))} | Select-Object *
                                    $global:TriggerExportConfig = $false
                                    Export-BoxConfigTestingProgram -APISName $APISName -UrlRoot $UrlRoot -OutputFolder $ExportCSVFolderNamePath -Mail $Mail -JournalPath $JournalFolderNamePath -GitHubUrlSite $GitHubUrlSite
                                    Break
                                   }
            
            Default                {$UrlToGo = "$UrlRoot/$APIName"
                                    $global:TriggerExportConfig = $false
                                    $FormatedData = Switch-Info -Label $Label -UrlToGo $UrlToGo -APIName $APIName -Mail $Mail -JournalPath $JournalFolderNamePath -GitHubUrlSite $GitHubUrlSite -ErrorAction Continue -WarningAction Continue
                                    Export-GlobalOutputData -FormatedData $FormatedData -APIName $APIName -ExportCSVPath $ExportCSVFolderNamePath -ExportJSONPath $ExportJSONFolderNamePath -ExportFile $ExportFile -Description $Description -ReportType $ReportType -ReportPath $ReportFolderNamePath
                                    Break
                                   }
        }
        #endregion Get data
    }
    Else {
        $global:TriggerExitUser = 1
        Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop
    }
}

Write-Log -Type WARNING -Category $Category -Name 'Program Run' -Message '####################################################### Program ########################################################'

#endregion process

#region Close Program

Stop-Program -Context System -ErrorMessage '' -Reason '' -ErrorAction SilentlyContinue

#endregion Close Program

#endregion Program
