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
    Web url bbox content
    BBOX Rest API
    Hand User actions
    
.OUTPUTS
    
    Export-HTMLReport   -DataReported $FormatedData -ReportTitle "BBOX Configuration Report - $Page" -ReportType $ReportType -ReportPath $ReportPath -ReportFileName $Exportfile -HTMLTitle "BBOX Configuration Report" -ReportPrecontent $Page -Description $Description
    Out-GridviewDisplay -FormatedData $FormatedData -Page $Page -Description $Description
    Export-toCSV        -FormatedData $FormatedData -Page $Page -ExportCSVPath $ExportCSVPath -Exportfile $Exportfile
    Export-toJSON       -FormatedData $FormatedData -Page $Page -JsonBboxconfigPath $ExportJSONPath -Exportfile $Exportfile
    
.NOTES
    
    Creation Date : 2020/04/30
    Author : Zardrilokis => landel.thomas@yahoo.fr
    
    Version 1.0
    Updated Date : 2020/11/20
    Updated By   : landel.thomas@yahoo.fr
    Update       : Powershell script creation
    Update       : Add module - BBOX-Module.psm1
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
    
.LINKS
    
    https://api.bbox.fr/doc/
    https://api.bbox.fr/doc/apirouter/index.html
    https://chromedriver.chromium.org/
    https://mabbox.bytel.fr/
    https://mabbox.bytel.fr/api/v1
    http://winstonfassett.com/blog/2010/09/21/html-to-text-conversion-in-powershell/
    
#>

#region variables

# URL Settings for the ChromeDriver request
$UrlRoot = ""
$Port = ""
$APIVersion = "api/v1"
$UrlSettings = ""
$UrlToGo = ""
$UrlHome = ""
$Mail = "landel.thomas@yahoo.fr"
$BBoxDns = "mabbox.bytel.fr"
$global:ChromeDriver = $Null
$Password = $Null

# Paths
$LogsPath = "$PSScriptRoot\Logs"
$ExportPath = "$PSScriptRoot\Export"
$ExportCSVPath = "$ExportPath\CSV"
$ExportJSONPath = "$ExportPath\JSON"
$DownloadPath = "$PSScriptRoot\Journal"
$JsonBboxconfigPath = "$PSScriptRoot\Json_Bbox_config"
$RessourcesPath = "$PSScriptRoot\Ressources"
$ReportPath = "$PSScriptRoot\Report"
$BBOXModulePath = "$PSScriptRoot\BBOX-Module.psm1"
$PasswordPath = "$RessourcesPath\SecuredPassword.txt"
$APISummaryPath = "$RessourcesPath\API-Summary.csv"
$TestedEnvironnementPath = "$RessourcesPath\TestedEnvironnement.csv"

# For switch Page/function selection 
$Info = ""

# Trigger
$global:TriggerExit = 0
$TriggerLANNetwork = $Null
$TriggerExportFormat = 0
$TriggerDisplayFormat = 0

#endregion

#region function

# Imported by module : .\BBoxModule.psm1

<#
    .SYNOPSIS
    Write-Log permet d'écrire les logs fonctionnels d'exécution.
    
    .DESCRIPTION
    Ecrit un log sur la console et sur fichier.
#>
function Write-Log {
    Param(
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
        $Logname = "$PSScriptRoot\Logs\Log_BBOX_Administration"
    )
    
    $logpath = $Logname + $(get-date -UFormat %Y%m%d).toString() + ".csv"
    
    # Create log object 
    $log = [pscustomobject] @{Date=(Get-Date -UFormat %Y%m%d_%H%M%S) ; Type=$type ; Name=$name ; Message=$Message  ; user= $(whoami) ; PID=$PID} 
    $log | add-member -Name ToString -MemberType ScriptMethod -value {$this.date + ' : ' + $this.type +' : ' +$this.name +' : ' + $this.Message} -Force 
    
    # Append to global journal
    [Object[]] $Global:journal += $log.toString()
    
    If(-not $NotDisplay){
        
        Switch ($Type) {
            
            "INFO"    {Write-Host -Object "$Message" -ForegroundColor Cyan}
            
            "INFONO"  {Write-Host -Object "$Message" -ForegroundColor Cyan -NoNewline}
            
            "VALUE"   {Write-Host -Object "$Message" -ForegroundColor Green}
            
            "WARNING" {Write-Host -Object "$Message" -ForegroundColor Yellow}
            
            "ERROR"   {Write-Host -Object "$Message" -ForegroundColor Red}
            
            "DEBUG"   {Write-Host -Object "$Message" -ForegroundColor Blue}
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

#endregion

#region Script

cls

#region Presentation

Write-Host "##################################################### Description ######################################################`n" -ForegroundColor Yellow
Write-Host "This program is only available in French."
Write-Host "It allows you to retrieve, modify and delete information on Bouygues Télécom's BBOX."
Write-Host "It displays advanced information that you will not see through the classic web interface of your BBOX."
Write-Host "And this via a local or remote connection (Provided that you have activated the remote BBOX management => https://mabbox.bytel.fr/remote.html)."
Write-Host "The result can be displayed in HTML format or in table form (Gridview)."
Write-Host "The result can be exported in `" .csv (.csv) `" or `" .JSON (.JSON) `" format"
Write-Host "The only limitation of this program is related to the requests available via the API installed on the target BBOX according to the model and the firmware version of this one."
Write-Host "When displaying the result, some information may not be displayed, or may be missing :"
Write-Host "- Either it's an oversight on my part in the context of the development, and I apologize in advance."
Write-Host "- Either this one is still under development."
Write-Host "- Either this information is optional and only appears in the presence of certain bbox models :"
Write-Host "-- BBOX models"
Write-Host "-- Firmware version"
Write-Host "-- Available features"
Write-Host "-- Connection mode (Local / Remote)"
Write-Host "This program requires the installation of PowerShell 5.0 minimum and Google Chrome."
Write-Host "For more information, I invite you to consult this website : " -NoNewline
Write-Host "https://api.bbox.fr/doc/apirouter/index.html" -ForegroundColor Green
Write-Host "`nAttention, this program is reserved for an advanced use of the BBOX settings and is aimed at an informed audience !" -ForegroundColor Yellow
Write-Host "Any improper handling risks causing partial or even total malfunction of your BBOX, rendering it unusable. You are Warned !" -ForegroundColor Yellow
Write-Host "Therefore, I accept no responsibility for the use of this program." -ForegroundColor Red
Write-Host "For any questions or additional requests, you can contact me at this email address :" -NoNewline
Write-Host "$Mail" -ForegroundColor Green
Write-Host "Please make sure log file is closed before continue." -ForegroundColor Yellow
Write-Host "Logs location : $PSScriptRoot\Logs\Log_BBOX_Administration*.csv" -ForegroundColor Green
Write-Host "Successful tested environnements : "
Write-Log -Type INFO -Name "Get tested environnements" -Message "Importation tested environnements Status :" -NotDisplay
Try{
    $TestedEnvironnement = Import-Csv -Path $TestedEnvironnementPath -Delimiter ","
    $TestedEnvironnement | Format-Table
    Write-Log -Type VALUE -Name "Get tested environnements" -Message "Success" -NotDisplay
}
Catch{
    Write-Log -Type ERROR -Name "Get tested environnements" -Message "Failed to get successful tested environnements - Due to : $($_.ToString())"
    $global:TriggerExit = 1
}

Write-Host "##################################################### Description ######################################################`n" -ForegroundColor Yellow
Write-Host "Press any key to continue ..."
$Pause = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")

#endregion Presentation

#region Programm initialisation
#cls
Write-Log -Type INFO -Name "Programm initialisation" -Message "Programm initialisation started." -NotDisplay
Write-Host "Programm Initialisation in progress : " -NoNewline -ForegroundColor Cyan

If((-not (Test-Path -Path $RessourcesPath)) -and ($global:TriggerExit -eq 0)){
    
    Write-Log -Type WARNING -Name "Programm initialisation" -Message "$RessourcesPath do not exist"
    $global:TriggerExit = 1
}

# Import Functions with Module "BBOX-Module.psm1"
If($global:TriggerExit -eq 0){
    Write-Log -Type INFONO -Name "Programm initialisation" -Message "Importing Powershell Module : " -NotDisplay
    
    Try{
        Remove-Module -Name BBOX-Module -ErrorAction SilentlyContinue
    }
    Catch{
        Write-Log -Type ERROR -Name "Programm initialisation" -Message "Failed. Powershell Module $BBOXModulePath can't be removed due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
    Start-Sleep 1
    Try{
        Import-Module -Name $BBOXModulePath -ErrorAction Stop
        Write-Log -Type VALUE -Name "Programm initialisation" -Message "Done" -NotDisplay
    }
    Catch{
        Write-Log -Type ERROR -Name "Programm initialisation" -Message "Failed. Powershell Module $BBOXModulePath can't be imported due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
}

# Create folders/files if not yet existing
If($global:TriggerExit -eq 0){
    
    Write-Log -Type INFO -Name "Programm initialisation" -Message "Start Checks programm Folders/Files" -NotDisplay
    Test-FolderPath -FolderRoot $PSScriptRoot -FolderPath $ExportPath -FolderName ($ExportPath.Split('\'))[-1]
    Test-FolderPath -FolderRoot $ExportPath -FolderPath $ExportCSVPath -FolderName ($ExportCSVPath.Split('\'))[-1]
    Test-FolderPath -FolderRoot $ExportPath -FolderPath $ExportJSONPath -FolderName ($ExportJSONPath.Split('\'))[-1]
    Test-FolderPath -FolderRoot $PSScriptRoot -FolderPath $DownloadPath -FolderName ($DownloadPath.Split('\'))[-1]
    Test-FolderPath -FolderRoot $PSScriptRoot -FolderPath $ReportPath -FolderName ($ReportPath.Split('\'))[-1]
    Test-FolderPath -FolderRoot $PSScriptRoot -FolderPath $JsonBboxconfigPath -FolderName ($JsonBboxconfigPath.Split('\'))[-1]
    Test-FilePath -FileRoot $RessourcesPath -FilePath $PasswordPath -FileName ($PasswordPath.Split('\'))[-1]
    Write-Log -Type INFO -Name "Programm initialisation" -Message "End Checks programm Folders/Files" -NotDisplay
}

# Import Actions available
If($global:TriggerExit -eq 0){
    Write-Log -Type INFONO -Name "Programm initialisation" -Message "Importing Referentiel Actions availables ($APISummaryPath) : " -NotDisplay
    
    Try{
        $Pages = Import-Csv -Path $APISummaryPath -Delimiter "," -Encoding UTF8 -ErrorAction Stop
        Write-Log -Type VALUE -Name "Programm initialisation" -Message "Done." -NotDisplay
    }
    Catch{
        Write-Log -Type ERROR -Name "Programm initialisation" -Message "Failed. Referentiel Actions can't be imported due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
}

# Check if Google Chrome is already install
If($global:TriggerExit -eq 0){
    
    Write-Log -Type INFONO -Name "Programm initialisation" -Message "Is Google Chrome already install : " -NotDisplay
    
    Try{
        $ChromeVersion = ((Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)').VersionInfo).ProductVersion
        Write-Log -Type VALUE -Name "Programm initialisation" -Message "Yes." -NotDisplay
        Write-Log -Type INFONO -Name "Programm initialisation" -Message "Current Google Chrome version : " -NotDisplay
        Write-Log -Type VALUE -Name "Programm initialisation" -Message "$ChromeVersion" -NotDisplay
    }
    Catch{
        Write-Log -Type WARNING -Name "Programm initialisation" -Message "Not yet." -NotDisplay
        Write-Log -Type WARNING -Name "Programm initialisation" -Message "Please install Google Chrome before to use this programm." -NotDisplay
        $global:TriggerExit = 1
    }
}

# Chrome Version choice function chrome version installed.
If($global:TriggerExit -eq 0){
    
    Write-Log -Type INFO -Name "Programm initialisation" -Message "Start Chrome Driver version selection function Chrome Version installed on device." -NotDisplay
    
    Try{
        $ChromeDriverVersion = Get-ChromeDriverVersion -ChromeVersion $ChromeVersion
    }
    Catch{
        Write-Log -Type WARNING -Name "Programm initialisation" -Message "Impossible to define the correct ChromeDriverVersion."
        $global:TriggerExit = 1
    }
    Write-Log -Type INFO -Name "Programm initialisation" -Message "End Chrome Driver version selection function Chrome Version installed on device." -NotDisplay
    Write-Log -Type INFO -Name "Programm initialisation" -Message "Programm initialisation ended" -NotDisplay
}

If($global:TriggerExit -ne 1){
    Write-Host "Finished without errors" -ForegroundColor Green
}

# Check if user connect on the correct LAN Network
If($global:TriggerExit -eq 0){
    
    $TriggerLANNetwork = ""
    Write-Log -Type INFONO -Name "Programm initialisation" -Message "Checking BBOX LAN network : "
    
    Try{
        $DnsName = Resolve-DnsName -Name $BBoxDns -Type A -DnsOnly -ErrorAction Stop
        Write-Log -Type VALUE -Name "Programm initialisation" -Message "Connected to your Local BBOX Network"
        Write-Log -Type INFONO -Name "Programm initialisation" -Message "BBOX IP Address : "
        Write-Log -Type VALUE -Name "Programm initialisation" -Message "$($DnsName.Address)"
        Write-Log -Type INFONO -Name "Programm initialisation" -Message "Recommanded connection : "
        Write-Log -Type VALUE -Name "Programm initialisation" -Message "Localy."
        $TriggerLANNetwork = 1
    }
    Catch{
        Write-Log -Type ERROR -Name "Programm initialisation" -Message "Failed. Unable to resolve $BBoxDns due to : $($_.ToString())"
        Write-Host "It seems you are not connected to your Local BBOX Network." -ForegroundColor Yellow
        Write-Log -Type INFONO -Name "Programm initialisation" -Message "Recommanded connection : "
        Write-Log -Type VALUE -Name "Programm initialisation" -Message "Remotely."
        $TriggerLANNetwork = 0
    }
}

#endregion Programm initialisation

#region Programm

# Check if password already exist in the file $$PasswordPath
If($global:TriggerExit -eq 0){

    While([string]::IsNullOrEmpty($Password)){
        
        Write-Log -Type INFONO -Name "Password Status" -Message "Password Status : "
        
        Try{
            $Password = (Get-Content -Path $PasswordPath -Tail 1 -ErrorAction SilentlyContinue).Trim()
            Write-Log -Type VALUE -Name "Password Status" -Message "Set."
            Write-Log -Type INFO -Name "Password Status" -Message "Password file : $PasswordPath" -NotDisplay
        }
        Catch{
            # Ask user to provide BBOX interface password
            Write-Log -Type WARNING -Name "Password Status" -Message "Not set."
            Write-Host "Please enter your bbox password in the txt file available here : " -NoNewline
            Write-Host "$PasswordPath" -ForegroundColor Green
            Invoke-Item -Path $PasswordPath
            Write-Host "Be careful this file do not :" -ForegroundColor Yellow
            Write-Host "- Contains `"space`" characters." -ForegroundColor Yellow
            Write-Host "- Begin or end by an empty line." -ForegroundColor Yellow
            Write-Host "Please edit and save the password file before continue." -ForegroundColor Cyan
            Pause
        }
    }
}

# Ask to the user how he want to connect to the BBOX
If($global:TriggerExit -eq 0){
    
    Write-Log -Type INFO -Name "Connexion Type" -Message "How do you want to connect to the BBOX ?"
    Write-Host "Please make sure remote connexion is opened before continue." -ForegroundColor Cyan
    $ConnexionType = Get-ConnexionType -TriggerLANNetwork $TriggerLANNetwork
}

# Set Bbox connexion settings regarding user selection
If($global:TriggerExit -eq 0){

    $UrlRoot = ""
    $Port = $Null
    $UrlHome = ""
    Switch($ConnexionType[0]){
        
        L   {$UrlRoot = "https://$BBoxDns"
             $UrlHome = "https://$BBoxDns/login.html"
            }
        
        R   {$UrlRoot = Get-HostStatus -UrlRoot $UrlRoot
             $Port =    Get-PortStatus -UrlRoot $UrlRoot -Port $Port
             $UrlHome = "https://$UrlRoot`:$Port/login.html"
            }
        
        Q   {$global:TriggerExit = 1}
    }
    Write-Log -Type INFO -Name "Connexion Type" -Message "Root Bbox Url : $UrlRoot" -NotDisplay
    Write-Log -Type INFO -Name "Connexion Type" -Message "Login Bbox page address : $UrlHome" -NotDisplay
    Write-Log -Type INFO -Name "Connexion Type" -Message "Remote Bbox page : $Port" -NotDisplay
}

# Start in Background chromeDriver
If($global:TriggerExit -eq 0){
    
    Write-Log -Type INFONO -Name "ChromeDriver Start" -Message "Starting ChromeDriver as backgroung process : "
    
    Try{
        Start-ChromeDriver -ChromeDriverVersion $ChromeDriverVersion -DownloadPath $DownloadPath
        Write-Log -Type VALUE -Name "ChromeDriver Start" -Message "Started."
    }
    Catch{
        Write-Log -Type ERROR -Name "ChromeDriver Start" -Message "Failed. ChromeDriver can't be started due to : $($_.ToString())"
        $global:TriggerExit = 1
    }
}

# Start BBox Authentification
If($global:TriggerExit -eq 0){
    
    Write-Log -Type INFONO -Name "ChromeDriver Authentification" -Message "Starting BBOX Authentification : "
    
    Try{
        Connect-BBOX -UrlHome $UrlHome -Password $Password -ErrorAction Stop
        Write-Log -Type VALUE -Name "ChromeDriver Authentification" -Message "Authentificated."
    }
    Catch{
        Write-Log -Type ERROR -Name "ChromeDriver Authentification" -Message "Failed. Atuthentification can't be done due to $($_.ToString())"
        $global:TriggerExit = 1
    }
}

While($global:TriggerExit -eq 0){
    
    $Action = ""
    $Info = ""
    $Page = ""
    $Description = ""
    $ReportType = ""
    $ExportFile = ""
    
    # Ask user action he wants to do (Get/PUT/POST/REMOVE)
    Write-Log -Type INFO -Name "Action asked" -Message "Please select in the list action you want to do :"
    $Action = $Pages | Where-Object {$_.Available -eq "Yes"} | Out-GridView -Title "Please select in the list action you want to do :" -OutputMode Single
    
    # Set value to variables
    $Info = $Action.label
    $Page = $Action.APIName
    $Description = $Action.Description
    $ReportType = $Action.ReportType
    $ExportFile = $Action.ExportFile
    
    Write-Log -Type INFONO -Name "Action asked" -Message "Action chosen : "
    Write-Host "$Description" -ForegroundColor Green
    Write-Log -Type VALUE -Name "Action asked" -Message "$Description" -NotDisplay
    
    If($Action -ne $Null){
        
        # Build API Web Page Url
        Switch($ConnexionType){
            
            L  {$UrlToGo = "$UrlRoot/$APIVersion/$Page"}
            R  {$UrlToGo = "https://$UrlRoot`:$Port/$APIVersion/$Page"}
        }
        
        If($Page -match "all"){
            
            $Page = ((Import-Csv -Path $APISummaryPath -Delimiter "," -Encoding UTF8 | Where-Object {(($_.Available -eq "Yes") -and ($_.APIName -notmatch "All"))}).APIName | Select-Object -Unique) -join ";"
        }
        
        # Get and Format data for output
        $FormatedData = @()
        $FormatedData =  Switch-Info -Info $Info -UrlToGo $UrlToGo -Page $Page -ConnexionType $ConnexionType -UrlRoot $UrlRoot -APIVersion $APIVersion -Port $Port -Mail $Mail
                
        If((-not ([string]::IsNullOrEmpty($FormatedData))) -and ($FormatedData -ne 0) -and ($FormatedData -ne "") -and ($FormatedData -ne " ") -and (-not ($FormatedData -match "Domain"))){
            
            # Choose Export format => HTML or Table
            If($TriggerDisplayFormat -eq 0){
                
                # Choose Display Format => HTML or Table
                $DisplayFormat = ""
                Write-Log -Type INFO -Name "Choose Display Format" -Message "Start data display format." -NotDisplay
                Write-Log -Type INFO -Name "Choose Display Format" -Message "Please choose a display format : (H) HTML or (T) Table/Gridview."
                While($DisplayFormat[0] -notmatch "H|T"){
                    
                    $DisplayFormat = Read-Host "Enter your choice"
                    Write-Log -Type VALUE -Name "Choose Display Format" -Message "Value Choosen : $DisplayFormat." -NotDisplay
                }
                
                $TriggerDisplayFormat = 1
                Write-Log -Type INFO -Name "Choose Display Format" -Message "End data display format." -NotDisplay
            }
            
            # Choose Export format => CSV or JSON
            If($TriggerExportFormat -eq 0){
                
                $ExportFormat = ""
                Write-Log -Type INFO -Name "Export Result" -Message "Start data export format." -NotDisplay
                Write-Log -Type INFO -Name "Export Result" -Message "Please choose an export format : (C) CSV or (J) JSON."
                
                While($ExportFormat[0] -notmatch "C|J"){
                    
                    $ExportFormat = Read-Host "Enter your choice"
                    Write-Log -Type INFO -Name "Export Result" -Message "Value Choosen  : $ExportFormat." -NotDisplay
                }
                
                $TriggerExportFormat = 1
                Write-Log -Type INFO -Name "Export Result" -Message "End data export format." -NotDisplay
            }
            
            # Apply display Format
            Write-Log -Type INFO -Name "Display Result" -Message "Start display result." -NotDisplay
            Switch($DisplayFormat){
                
                'H' {# Display result by HTML Report
                     Export-HTMLReport -DataReported $FormatedData -ReportTitle "BBOX Configuration Report - $Page" -ReportType $ReportType -ReportPath $ReportPath -ReportFileName $Exportfile -HTMLTitle "BBOX Configuration Report" -ReportPrecontent $Page -Description $Description
                    }
                
                'T' {# Display result by Out-Gridview
                     Out-GridviewDisplay -FormatedData $FormatedData -Page $Page -Description $Description
                    }
            }
            Write-Log -Type INFO -Name "Display Result" -Message "End display result." -NotDisplay
            
            # Apply Export Format
            Write-Log -Type INFO -Name "Export Result" -Message "Start export result." -NotDisplay
            Switch($ExportFormat){
                    
                'C' {# Export result to CSV
                     Export-toCSV -FormatedData $FormatedData -Page $Page -ExportCSVPath $ExportCSVPath -Exportfile $Exportfile
                    }
                'J' {# Export result to JSON
                     Export-toJSON -FormatedData $FormatedData -Page $Page -JsonBboxconfigPath $ExportJSONPath -Exportfile $Exportfile
                    }
            }
            Write-Log -Type INFO -Name "Export Result" -Message "End export result." -NotDisplay
        }
        Else{Write-Log -Type WARNING -Name "Display Result" -Message "No data were found ! The result can't be exported."
             Write-Log -Type INFO -Name "Display Result" -Message "End display result." -NotDisplay
        }
    }
    
    Else{$global:TriggerExit = 1}
}

# Close all ChromeDriver instances openned
Write-Log -Type INFO -Name "Exit Programm" -Message "Programm exiting ..." -NotDisplay
Write-Log -Type INFO -Name "Exit Programm" -Message "Please don't close manually this windows ... we are closing background processes before close the program."
Write-Log -Type INFO -Name "ChromeDriver Stop" -Message "Start Stop Chrome Driver." -NotDisplay
If($global:ChromeDriver -ne $Null){Stop-ChromeDriver}
Write-Log -Type INFO -Name "ChromeDriver Stop" -Message "End Stop Chrome Driver." -NotDisplay
sleep 3
$Curent_Logs_File = (Get-ChildItem -Path $LogsPath -Name "Log_BBOX_Administration*" -ErrorAction Stop | Sort-Object LastWriteTime)[-1]
Write-Log -Type INFONO -Name "Exit Programm" -Message "Log file is available here : "
Write-Log -Type VALUE -Name "Exit Programm" -Message "$LogsPath\$Curent_Logs_File"
Write-Log -Type INFO -Name "Exit Programm" -Message "Programm Close." -NotDisplay
Write-Host "Press any key to quit ..."
$Pause = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")

#endregion Programm

#endregion Script
