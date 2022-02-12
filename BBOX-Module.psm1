﻿
#region GLOBAL (All functions below are used only on powershell script : ".\BBOX-Administration.ps1")

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
        $Logname = "$global:LogsPath\$global:LogsFileName"
    )
    
    $logpath = $Logname + $(get-date -UFormat %Y%m%d).toString() + ".csv"
    
    # Create log object 
    $log = [pscustomobject] @{Date=(Get-Date -UFormat %Y%m%d_%H%M%S) ; Type=$type ; Name=$name ; Message=$Message  ; user= $(whoami) ; PID=$PID} 
    $log | Add-member -Name ToString -MemberType ScriptMethod -value {$this.date + ' : ' + $this.type +' : ' +$this.name +' : ' + $this.Message} -Force 
    
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

# Clean folder content
Function Remove-FolderContent {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$FolderRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$FolderName
    )
    
    $FolderPath = "$FolderRoot\$FolderName"

    Write-Log -Type INFO -Name "Program run - Clean folder content" -Message "Start Clean `"$FolderPath`" folder" -NotDisplay
    
    If(Test-Path -Path $FolderPath){
        
        Write-Log -Type INFONO -Name "Program run - Clean folder content" -Message "Cleaning `"$FolderPath`" folder content Status : " -NotDisplay
        Try{
            $Null = Remove-Item -Path "$FolderPath\*" -Recurse
            Write-Log -Type VALUE -Name "Program run - Clean folder content" -Message "Successfully" -NotDisplay
        }
        Catch{
            Write-Log -Type ERROR -Name "Program run - Clean folder content" -Message "Failed. $FolderPath folder can't be cleaned due to : $($_.ToString())"
            $global:TriggerExit = 1
        }
    }
    Else{Write-Log -Type INFONO -Name "Program run - Clean folder content" -Message "`"$FolderPath`" folder state : " -NotDisplay
         Write-Log -Type VALUE -Name "Program run - Clean folder content" -Message "Not found" -NotDisplay
    }
    Write-Log -Type INFO -Name "Program run - Clean folder content" -Message "End Clean `"$FolderPath`" folder content" -NotDisplay
}

# Test and create folder if not yet existing
Function Test-FolderPath {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$FolderRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$FolderPath,
        
        [Parameter(Mandatory=$True)]
        [String]$FolderName
    )
    
    $FolderName = ($FolderName.Split('\'))[-1]
    
    Write-Log -Type INFO -Name "Program initialisation - Program Folders check" -Message "Start folder check : $FolderPath" -NotDisplay
    
    If(-not (Test-Path -Path $FolderPath)){
        
        Write-Log -Type INFONO -Name "Program initialisation - Program Folders check" -Message "Creating  folder : $FolderPath" -NotDisplay
        Try{
            $Null = New-Item -Path "$FolderRoot" -Name "$FolderName" -ItemType Directory -Force
            Write-Log -Type VALUE -Name "Program initialisation" -Message "Done" -NotDisplay
        }
        Catch{
            Write-Log -Type ERROR -Name "Program initialisation - Program Folders check" -Message "Failed, $FolderPath folder can't be created due to : $($_.ToString())"
            $global:TriggerExit = 1
        }
    }
    Else{Write-Log -Type INFONO -Name "Program initialisation - Program Folders check" -Message "Folder state : " -NotDisplay
         Write-Log -Type VALUE -Name "Program initialisation - Program Folders check" -Message "Already exists" -NotDisplay
    }
    Write-Log -Type INFO -Name "Program initialisation - Program Folders check" -Message "End folder check : $FolderPath" -NotDisplay
}

# Test and create file if not yet existing
Function Test-FilePath {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$FileRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$FilePath,

        [Parameter(Mandatory=$True)]
        [String]$FileName
    )
    
    $FileName = ($FileName.Split('\'))[-1]
    
    Write-Log -Type INFO -Name "Program initialisation - Program Files check" -Message "Start file check : $FilePath" -NotDisplay
    
    If(-not (Test-Path -Path $FilePath)){
    
        Write-Log -Type INFONO -Name "Program initialisation - Program Files check" -Message "Creating file $FilePath status : " -NotDisplay
        Try{
            $Null = New-Item -Path "$FileRoot" -Name $FileName -ItemType File -Force
            Write-Log -Type VALUE -Name "Program initialisation - Program Files check" -Message "Successfully" -NotDisplay
        }
        Catch{
            Write-Log -Type ERROR -Name "Program initialisation - Program Files check" -Message "Failed, $FilePath file can't be created due to : $($_.ToString())" -NotDisplay
            $global:TriggerExit = 1
        }
    }
    Else{Write-Log -Type INFONO -Name "Program initialisation - Program Files check" -Message "File state : " -NotDisplay
         Write-Log -Type VALUE -Name "Program initialisation - Program Files check" -Message "Already exists" -NotDisplay
    }
    Write-Log -Type INFO -Name "Program initialisation - Program Files check" -Message "End file check : $FilePath" -NotDisplay
}

# Used only to detect ChromeDriver version
Function Get-ChromeDriverVersion {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$ChromeVersion
    )
    
    $ChromeMainVersion = $ChromeVersion.split(".")[0]
    Write-Log -Type INFONO -Name "Program initialisation - Chrome Driver Version" -Message "ChromeDriver version selected : " -NotDisplay

    Switch($ChromeMainVersion){
        
        "93"{
                $ChromeDriverVersion = "93.0.4577.63"
                Write-Log -Type VALUE -Name "Program initialisation - Chrome Driver Version" -Message "93.0.4577.63" -NotDisplay
               }
        
        "94"{
                $ChromeDriverVersion = "94.0.4606.61"
                Write-Log -Type VALUE -Name "Program initialisation - Chrome Driver Version" -Message "94.0.4606.61" -NotDisplay
               }

        "95"{
                $ChromeDriverVersion = "95.0.4638.17"
                Write-Log -Type VALUE -Name "Program initialisation - Chrome Driver Version" -Message "95.0.4638.17" -NotDisplay
               }

        Default{
                $ChromeDriverVersion = "Default"
                Write-Log -Type VALUE -Name "Program initialisation - Chrome Driver Version" -Message "Default" -NotDisplay
               }
    }
    
    Return $ChromeDriverVersion
}

# Used only to define bbox connexion type
Function Get-ConnexionType {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$TriggerLANNetwork
    )
    
    Switch($TriggerLANNetwork){
    
        '1'        {Write-Log -Type INFO -Name "Program run - Connexion Type" -Message "(L) Localy / (R) Remotly / (Q) Quit the Program"
                    $ConnexionTypeChoice = "L|R|Q"
                   }
        
        '0'        {Write-Log -Type INFO -Name "Program run - Connexion Type" -Message "(R) Remotly / (Q) Quit the Program"
                    $ConnexionTypeChoice = "R|Q"
                   }
        
        Default    {Write-Log -Type INFO -Name "Program run - Connexion Type" -Message "(R) Remotly / (Q) Quit the Program"
                    $ConnexionTypeChoice = "R|Q"
                   }
    }
    
    $ConnexionType = ""
    While($ConnexionType -notmatch $ConnexionTypeChoice){
    
        $ConnexionType = Read-Host "Enter your choice"
         Write-Log -Type INFO -Name "Program run - Connexion Type" -Message "Connexion Type chosen by user : $ConnexionType" -NotDisplay
    }
    
    Return $ConnexionType
}

# Used only to check if external Bbox DNS is online
Function Get-HostStatus {
    
    Param(
        [Parameter(Mandatory=$False)]
        [String]$UrlRoot
    )
    
    $BBoxDnsStatus = ""
    While(([string]::IsNullOrEmpty($UrlRoot) -and ($BBoxDnsStatus -notlike $true))){
        
        $UrlRoot = Read-Host "Enter your external BBOX IP/DNS Address, Example : example.com "
        Write-Log -Type INFONO -Name "Program run - Check Host" -Message "Host `"$UrlRoot`" status : "
        
        If(-not ([string]::IsNullOrEmpty($UrlRoot))){
            
            $BBoxDnsStatus = Test-Connection -ComputerName $UrlRoot -Quiet
            
            If($BBoxDnsStatus -like $true){
                
                Write-Log -Type VALUE -Name "Program run - Check Host" -Message "Online"
                Break
            }
            Else{Write-Log -Type WARNING -Name "Program run - Check Host" -Message "Offline"
                 Write-Host "Host $UrlRoot seems not Online, please make sure :" -ForegroundColor Yellow
                 Write-Host "- You enter a valid DNS address or IP address" -ForegroundColor Yellow
                 Write-Host "- `"PingResponder`" service is enabled (https://mabbox.bytel.fr/firewall.html)" -ForegroundColor Yellow
                 Write-Host "- `"DYNDNS`" service is enabled and properly configured (https://mabbox.bytel.fr/dyndns.html)" -ForegroundColor Yellow
                 Write-Host "- `"Remote`" service is enabled and properly configured (https://mabbox.bytel.fr/remote.html)" -ForegroundColor Yellow
                 $UrlRoot = ""
            }
        }
        Else{Write-Log -Type WARNING -Name "Program run - Check Host" -Message "This field can't be empty or null"}
    }
    Return $UrlRoot
}

# Used only to check if external Bbox Port is open
Function Get-PortStatus {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot
    )
    
    $PortStatus = ""
    While(($PortStatus -notlike $true) -and (-not ([string]::IsNullOrEmpty($UrlRoot)))){
        
        [int]$Port = Read-Host "Enter your external remote BBOX port, Example : 80,443, default is 8560 "
        Write-Log -Type INFONO -Name "Program run - Check Port" -Message "Port `"$Port`" status : "
        
        If(($Port -ge 1) -and ($Port -le 65535)){
            
            $PortStatus = Test-NetConnection -ComputerName $UrlRoot -Port $Port -InformationLevel Detailed
            
            If($PortStatus.TcpTestSucceeded -like $true){
                
                Write-Log -Type VALUE -Name "Program run - Check Port" -Message "Opened"
                Break
            }
            Else{Write-Log -Type WARNING -Name "Program run - Check Port" -Message "Closed"
                 Write-Host "Port $Port seems closed, please make sure :" -ForegroundColor Yellow
                 Write-host "- You enter a valid port number" -ForegroundColor Yellow
                 Write-Host "- None Firewall rule(s) block this port (https://mabbox.bytel.fr/firewall.html)" -ForegroundColor Yellow
                 Write-Host "- `"Remote`" service is enabled and properly configured (https://mabbox.bytel.fr/remote.html)" -ForegroundColor Yellow
                 $Port = ""
            }
        }
        Else{Write-Log -Type WARNING -Name "Program run - Check Port" -Message "This field can't be empty or null or must be in the range between 1 and 65565"}
    }
    Return $Port
}

# Used Only to Build API Url Web Page
Function Switch-ConnexionType {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot,

        [Parameter(Mandatory=$False)]
        [String]$Port,

        [Parameter(Mandatory=$True)]
        [String]$APIVersion,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    Switch($ConnexionType){
        
        L  {$UrlToGo = "$UrlRoot/$APIVersion/$APIName"}
        R  {$UrlToGo = "$UrlRoot`:$Port/$APIVersion/$APIName"}
    }
    Return $UrlToGo
}

#region ChromeDriver 

# Used only to Start ChromeDriver
Function Start-ChromeDriver {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$ChromeDriverVersion,
        
        [Parameter(Mandatory=$True)]
        [String]$DownloadPath,
        
        [Parameter(Mandatory=$True)]
        [String]$LogsPath,
        
        [Parameter(Mandatory=$True)]
        [String]$ChromeDriverPath,
        
        [Parameter(Mandatory=$True)]
        [String]$ChromeBinaryPath,

        [Parameter(Mandatory=$True)]
        [String]$ChromeDriverDefaultProfile
    )
    
    # Add path for ChromeDriver.exe to the environmental variable 
    $env:PATH += ";$ChromeDriverPath\$ChromeDriverVersion"

    # Add path for GoogleChrome.exe to the environmental variable 
    #$Temp = $($ChromeBinaryPath.Replace("\$($ChromeBinaryPath.Split("\")[-1])",""))
    #$env:PATH += ";$Temp"

    # Adding Selenium's .NET assembly (dll) to access it's classes in this PowerShell session
    Add-Type -Path "$ChromeDriverPath\$ChromeDriverVersion\WebDriver.dll"
    
    # Create new Chrome Drive Service
    $ChromeDriverService = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService()
    
    # Hide ChromeDriver Command Prompt Window
    $ChromeDriverService.HideCommandPromptWindow = $True
    
    # Add Chrome Driver Option
    $chromeoption = New-Object OpenQA.Selenium.Chrome.ChromeOptions
    
    # Add path for Chrome Driver Log File
    $chromeoption.AddArgument("log-path='$LogsPath\ChromeDriver-Debug.log'")
    
    # Enable Verbose Logging
    $chromeoption.AddArgument('verbose')
    
    # Bypass certificate control
    $chromeoption.AddArgument('ignore-certificate-errors')
    
    # Use Profile Directory
    $chromeoption.AddArgument("profile-directory='$ChromeDriverDefaultProfile'")
    
    # Find Google Chrome Application
    $chromeoption.BinaryLocation = "$ChromeBinaryPath"
    
    # Allow to download file without prompt
    $chromeoption.AddUserProfilePreference("download", @{"default_directory" = $DownloadPath; "directory_upgrade" = $True;"prompt_for_download" = $False})
    #$Preferencies = @()
    #$Preferencies.put("download.default_directory", $DownloadPath)
    #$Preferencies.put("download.prompt_for_download", $False)
    #$chromeoption.setExperimentalOption("prefs", $Preferencies)

    # Disable All Extentions
    $chromeoption.AddArgument("disable-extensions")
    $chromeoption.AddArgument("disable-default-apps")
    $chromeoption.AddArgument("disable-popup-blocking")
    $chromeoption.AddArgument("disable-plugins")
    $chromeoption.AddArgument("no-sandbox")
    
    # Hide ChromeDriver Application
    #$chromeoption.AddArguments('headless')
    
    # Start the ChromeDriver
    $global:ChromeDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($ChromeDriverService,$chromeoption)
}

# Used only to stop ChromeDriver, linked to : "Stop-Program"
Function Stop-ChromeDriver {
    
    Param()
    
    # Close all ChromeDriver instances openned
    $global:ChromeDriver.Close()
    $global:ChromeDriver.Dispose()
    $global:ChromeDriver.Quit()
    Get-Process -Name chromedriver -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
}

# Used only to Refresh WIRELESS Frequency Neighborhood Scan, linked to : "Format-Date1970"
function Start-RefreshWIRELESSFrequencyNeighborhoodScan {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot,
        [Parameter(Mandatory=$False)]
        [String]$Port,
        [Parameter(Mandatory=$True)]
        [String]$APIVersion
    )
    
    Write-Log -Type INFO -Name "Program run - WIRELESS Frequency Neighborhood scan" -Message "Start WIRELESS Frequency Neighborhood scan" -NotDisplay
    
    # Get information from BBOX API and last scan date
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    Write-Log -Type INFONO -Name "Program run - WIRELESS Frequency Neighborhood scan" -Message "WIRELESS Frequency Neighborhood Lastscan : " -NotDisplay
    
    If($Json.lastscan -eq 0){
        
        Write-Log -Type VALUE -Name "Program run - WIRELESS Frequency Neighborhood scan" -Message "Never" -NotDisplay
        $global:ChromeDriver.Navigate().GoToURL($($UrlToGo.replace("$APIVersion/$APIName","diagnostic.html")))
        Start-Sleep -Seconds 1
        
        Switch($APIName){
            
            wireless/24/neighborhood {($global:ChromeDriver.FindElementsByClassName("scan24") | Where-Object -Property text -eq "Scanner").click()}
            
            wireless/5/neighborhood  {($global:ChromeDriver.FindElementsByClassName("scan5") | Where-Object -Property text -eq "Scanner").click()}
        }
        
        Write-Log -Type WARNING -Name "Program run - WIRELESS Frequency Neighborhood scan" -Message "Attention, le scan peut provoquer une coupure temporaire de votre réseau Wi-Fi."
        Write-Log -Type WARNING -Name "Program run - WIRELESS Frequency Neighborhood scan" -Message "Souhaitez-vous continuer? : " -NotDisplay
        
        
        While($ActionState -notmatch "Y|N"){
            
            $ActionState = Read-Host "Souhaitez-vous continuer ? (Y) Yes / (N) No"
            Write-Log -Type INFO -Name "Program run - WIRELESS Frequency Neighborhood scan" -Message "Action chosen by user : $ActionState" -NotDisplay
        }
        
        Switch($ActionState){
        
            Y       {($global:ChromeDriver.FindElementsByClassName("cta-2") | Where-Object -Property text -eq "OK").click()}
            N       {($global:ChromeDriver.FindElementsByClassName("cta-2") | Where-Object -Property text -eq "ANNULER").click()}
            Default {($global:ChromeDriver.FindElementsByClassName("cta-2") | Where-Object -Property text -eq "ANNULER").click()}
        }
    }
    Else{
        
        Write-Log -Type VALUE -Name "Program run - WIRELESS Frequency Neighborhood scan" -Message "$(Format-Date1970 -Seconds $Json.lastscan)" -NotDisplay
        
        If($Port){
            
            Switch($APIName){
                
                wireless/24/neighborhood {$UrlNeighborhoodScan = "https://$UrlRoot`:$Port/neighborhood.html#ssid24";Break}
                wireless/5/neighborhood  {$UrlNeighborhoodScan = "https://$UrlRoot`:$Port/neighborhood.html#ssid5";Break}
            }
        }
        Else{
            
            Switch($APIName){
                
                wireless/24/neighborhood {$UrlNeighborhoodScan = "https://$UrlRoot/neighborhood.html#ssid24";Break}
                wireless/5/neighborhood  {$UrlNeighborhoodScan = "https://$UrlRoot/neighborhood.html#ssid5";Break}
            }
        }
        
        $global:ChromeDriver.Navigate().GoToURL($UrlNeighborhoodScan)
        Start-Sleep -Seconds 1
        
        ($global:ChromeDriver.FindElementsByClassName("cta-1") | Where-Object -Property text -eq "Rafraîchir").click()
        ($global:ChromeDriver.FindElementsByClassName("cta-2") | Where-Object -Property text -eq "OK").click()
    }
    
    Write-Log -Type INFONO -Name "Program run - WIRELESS Frequency Neighborhood scan" -Message "Refresh WIRELESS Frequency Neighborhood scan : "
    Start-Sleep -Seconds 20
    Write-Log -Type VALUE -Name "Program run - WIRELESS Frequency Neighborhood scan" -Message "Ended"
    Write-Log -Type INFO -Name "Program run - WIRELESS Frequency Neighborhood scan" -Message "End WIRELESS Frequency Neighborhood scan" -NotDisplay
}

# Used only to Refresh WIRELESS Frequency Neighborhood Scan ID and linked to : "Start-RefreshWIRELESSFrequencyNeighborhoodScan" and "Get-WIRELESSFrequencyNeighborhoodScanID"
Function Get-WIRELESSFrequencyNeighborhoodScan {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$APIVersion,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$False)]
        [String]$Port
    )
    
    Start-RefreshWIRELESSFrequencyNeighborhoodScan -APIName $APIName -UrlToGo $UrlToGo -UrlRoot $UrlRoot -Port $Port -APIVersion $APIVersion
    $FormatedData = Get-WIRELESSFrequencyNeighborhoodScanID -UrlToGo $UrlToGo
    
    Return $FormatedData
}

#endregion ChromeDriver

# Used only to get BBOX LAN Switch Port State, linked to : "Get-DeviceFullLog"
Function Get-LanPortState {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$LanPortState
    )
    
    Switch($State){
    
        0          {$Value = "Disable"}
        1          {$Value = "Enable"}
        2          {$Value = "Enable"}
        3          {$Value = "Enable"}
        4          {$Value = "Enable"}
        Default    {$Value = "Unknow"}
    }
    
    Return $Value
}

# Used only to connect to BBox Web interface
Function Connect-BBOX {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlHome,
        
        [Parameter(Mandatory=$True)]
        [String]$Password
        
    )
    
    # Open Web Site Home Page 
    $global:ChromeDriver.Navigate().GoToURL($UrlHome)
    Start-Sleep 2
    
    # Enter the password to connect (# Methods to find the input textbox for the password)
    $global:ChromeDriver.FindElementByName("password").SendKeys("$Password") 
    Start-Sleep 1
    
    # Tic checkBox "Stay Connect" (# Methods to find the input checkbox for stay connect)
    $global:ChromeDriver.FindElementByClassName("cb").Click()
    Start-Sleep 1
    
    # Click on the connect button
    $global:ChromeDriver.FindElementByClassName("cta-1").Submit()
    Start-Sleep 1
}

# Used only to get information from API page content, linked to many functions
Function Get-BBoxInformation {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    Write-Log -Type INFO -Name "Program run - Get Information" -Message "Start retrieve informations requested" -NotDisplay
    Write-Log -Type INFO -Name "Program run - Get Information" -Message "Get informations requested from url : $UrlToGo" -NotDisplay
    Write-Log -Type INFO -Name "Program run - Get Information" -Message "Request status :" -NotDisplay
    
    Try{
        # Go to the web page to get information we need
        $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
        Write-Log -Type INFO -Name "Program run - Get Information" -Message "Successfully" -NotDisplay
    }
    Catch{
        Write-Log -Type ERROR -Name "Program run - Get Information" -Message "Failed - Due to : $($_.ToString())"
        Write-Host "Please check your local/internet network connection" -ForegroundColor Yellow
        Return "0"
        Break
    }
    
    Write-Log -Type INFO -Name "Program run - Get Information" -Message "End retrieve informations requested" -NotDisplay

    Write-Log -Type INFO -Name "Program run - Convert HTML" -Message "Start convert data from Html to plaintxt format" -NotDisplay
    Write-Log -Type INFONO -Name "Program run - Convert HTML" -Message "HTML Conversion status : " -NotDisplay
    
    Try{
        # Get Web page Content
        $Html = $global:ChromeDriver.PageSource
        # Convert $Html To Text
        $Plaintxt = ConvertFrom-HtmlToText -Html $Html
        Write-Log -Type VALUE -Name "Program run - Convert HTML" -Message "Successfully" -NotDisplay
    }
    Catch{
        Write-Log -Type ERROR -Name "Program run - Convert HTML" -Message "Failed to convert to HTML, due to : $($_.ToString())"
        Write-Log -Type INFO -Name "Program run - Convert HTML" -Message "End convert data from Html to plaintxt format" -NotDisplay
        Return "0"
        Break
    }
    Write-Log -Type INFO -Name "Program run - Convert HTML" -Message "End convert data from Html to plaintxt format" -NotDisplay
        
    Write-Log -Type INFO -Name "Program run - Convert JSON" -Message "Start convert data from plaintxt to Json format" -NotDisplay
    Write-Log -Type INFONO -Name "Program run - Convert JSON" -Message "JSON Conversion status : " -NotDisplay
    
    Try{
        # Convert $Plaintxt as JSON to array
        $Json = $Plaintxt | ConvertFrom-Json
        Write-Log -Type VALUE -Name "Program run - Convert JSON" -Message "Successfully" -NotDisplay
    }
    Catch{
        Write-Log -Type ERROR -Name "Program run - Convert JSON" -Message "Failed - Due to : $($_.ToString())"
        Return "0"
    }
    
    Write-Log -Type INFO -Name "Program run - Convert JSON" -Message "End convert data from plaintxt to Json format" -NotDisplay
    
    If($Json.exception.domain -and ($Json.exception.domain -ne "v1/device/log")){
        
        Write-Log -Type INFO -Name "Program run - Get API Error Code" -Message "Start get API error code" -NotDisplay
        Write-Log -Type INFONO -Name "Program run - Get API Error Code" -Message "API error code : "
        Try{
            $ErrorCode = Get-ErrorCode -Json $Json
            Write-Log -Type WARNING -Name "Program run - Get API Error Code" -Message "$($ErrorCode.ToString())" -NotDisplay
            Return $ErrorCode | Format-Table
        }
        Catch{
            Write-Log -Type ERROR -Name "Program run - Get API Error Code" -Message "Failed - Due to : $($_.ToString())"
        }

        Write-Log -Type INFO -Name "Program run - Get API Error Code" -Message "End get API error code" -NotDisplay
    }
    Else{
        Return $Json
    }
}

# Used only to convert HTML page to TXT, linked to : "Get-BBoxInformation"
Function ConvertFrom-HtmlToText {
    
    # Function get from internet : http://winstonfassett.com/blog/2010/09/21/html-to-text-conversion-in-powershell/
    
    Param(
        [Parameter(Mandatory=$True)]
        [System.String]$Html
    )
    
    # remove line breaks, replace with spaces
    $Html = $Html -replace "(`r|`n|`t)", " "
    # write-verbose "removed line breaks: `n`n$Html`n"
    
    # remove invisible content
    @('head', 'style', 'script', 'object', 'embed', 'applet', 'noframes', 'noscript', 'noembed') | Foreach-object {
    $Html = $Html -replace "<$_[^>]*?>.*?</$_>", ""
    }
    # write-verbose "removed invisible blocks: `n`n$Html`n"
    
    # Condense extra whitespace
    $Html = $Html -replace "( )+", " "
    # write-verbose "condensed whitespace: `n`n$Html`n"
    
    # Add line breaks
    @('div','p','blockquote','h[1-9]') | Foreach-object { $Html = $Html -replace "</?$_[^>]*?>.*?</$_>", ("`n" + '$0' )} 
    # Add line breaks for self-closing tags
    @('div','p','blockquote','h[1-9]','br') | Foreach-object { $Html = $Html -replace "<$_[^>]*?/>", ('$0' + "`n")} 
    # write-verbose "added line breaks: `n`n$Html`n"
    
    #strip tags 
    $Html = $Html -replace "<[^>]*?>", ""
    # write-verbose "removed tags: `n`n$Html`n"
    
    # replace common entities
    @( 
    @("&amp;bull;", " * "),
    @("&amp;lsaquo;", "<"),
    @("&amp;rsaquo;", ">"),
    @("&amp;(rsquo|lsquo);", "'"),
    @("&amp;(quot|ldquo|rdquo);", '"'),
    @("&amp;trade;", "(tm)"),
    @("&amp;frasl;", "/"),
    @("&amp;(quot|#34|#034|#x22);", '"'),
    @('&amp;(amp|#38|#038|#x26);', "&amp;"),
    @("&amp;(lt|#60|#060|#x3c);", "<"),
    @("&amp;(gt|#62|#062|#x3e);", ">"),
    @('&amp;(copy|#169);', "(c)"),
    @("&amp;(reg|#174);", "(r)"),
    @("&amp;nbsp;", " "),
    @("&amp;(.{2,6});", "")
    ) | Foreach-object { $Html = $Html -replace $_[0], $_[1] }
    # write-verbose "replaced entities: `n`n$Html`n"
    
    Return $Html
}

# Used only to select function to get data from BBOX web API or do actions
Function Switch-Info {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Label,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$ConnexionType,
        
        [Parameter(Mandatory=$True)]
        [String]$APIVersion,
        
        [Parameter(Mandatory=$False)]
        [String]$Port,
        
        [Parameter(Mandatory=$True)]
        [String]$Mail,
        
        [Parameter(Mandatory=$True)]
        [String]$OutputFolder,

        [Parameter(Mandatory=$True)]
        [String]$JournalPath
    )

        Switch($Label){
            
            # Error Code 
            Get-ErrorCode        {$FormatedData = Get-ErrorCode -UrlToGo $UrlToGo}
            
            Get-ErrorCodeTest    {$FormatedData = Get-ErrorCodeTest -UrlToGo $UrlToGo}
            
            # Airties
            Get-Airties          {$FormatedData = Get-Airties -UrlToGo $UrlToGo -APIName $APIName}
            
            Get-AirtiesL         {$FormatedData = Get-AirtiesLANmode -UrlToGo $UrlToGo}
            
            # Backup
            GET-CONFIGSL         {$FormatedData = Get-BackupList -UrlToGo $UrlToGo -APIName $APIName}
            
            # DHCP
            GET-DHCP             {$FormatedData = Get-DHCP -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-DHCPC            {$FormatedData = Get-DHCPClients -UrlToGo $UrlToGo}
            
            GET-DHCPCID          {$FormatedData = Get-DHCPClientsID -UrlToGo $UrlToGo}
            
            GET-DHCPAO           {$FormatedData = Get-DHCPActiveOptions -UrlToGo $UrlToGo}
            
            GET-DHCPO            {$FormatedData = Get-DHCPOptions -UrlToGo $UrlToGo}
            
            GET-DHCPOID          {$FormatedData = Get-DHCPOptionsID -UrlToGo $UrlToGo}
            
            Get-DHCPSTBO         {$FormatedData = Get-DHCPSTBOptions -UrlToGo $UrlToGo}
            
            Get-DHCPv6PFD        {$FormatedData = Get-DHCPv6PrefixDelegation -UrlToGo $UrlToGo}

            Get-DHCPv6O          {$FormatedData = Get-DHCPv6Options -UrlToGo $UrlToGo}
            
            # DNS
            GET-DNSS             {$FormatedData = Get-DNSStats -UrlToGo $UrlToGo}
            
            # DEVICE
            GET-DEVICE           {$FormatedData = Get-Device -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-DEVICELOG        {$FormatedData = Get-DeviceLog -UrlToGo $UrlToGo}

            GET-DEVICEFLOG       {$FormatedData = Get-DeviceFullLog -UrlToGo $UrlToGo}
            
            GET-DEVICEFTLOG      {$FormatedData = Get-DeviceFullTechnicalLog -UrlToGo $UrlToGo}
            
            GET-DEVICEC          {$FormatedData = Get-DeviceCpu -UrlToGo $UrlToGo}
            
            GET-DEVICEM          {$FormatedData = Get-DeviceMemory -UrlToGo $UrlToGo}
            
            GET-DEVICELED        {$FormatedData = Get-DeviceLED -UrlToGo $UrlToGo}
            
            GET-DEVICES          {$FormatedData = Get-DeviceSummary -UrlToGo $UrlToGo}
            
            GET-DEVICET          {$FormatedData = Get-DeviceToken -UrlToGo $UrlToGo}
            
            SET-DEVICER          {$Token = Get-DeviceToken -UrlToGo $UrlToGo
                                  $Token = ($Token | Where-Object {$_.Description -like 'Token'}).value
                                  $UrlToGo = $UrlToGo.replace("token","reboot?btoken=")
                                  $UrlToGo = "$UrlToGo$Token"
                                  Write-Host "Send reboot command ..."
                                  #Set-BBoxInformation -UrlToGo $UrlToGo
                                 }
            
            SET-DEVICEFR         {$Token = Get-DeviceToken -UrlToGo $UrlToGo
                                  $Token = ($Token | Where-Object {$_.Description -like 'Token'}).value
                                  $UrlToGo = $UrlToGo.replace("token","factory?btoken=")
                                  $UrlToGo = "$UrlToGo$Token"
                                  Write-Host "Send Factory reset command ..."
                                  #Set-BBoxInformation -UrlToGo $UrlToGo
                                 }
            
            # DYNDNS
            GET-DYNDNS           {$FormatedData = Get-DYNDNS -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-DYNDNSPL         {$FormatedData = Get-DYNDNSProviderList -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-DYNDNSC          {$FormatedData = Get-DYNDNSClient -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-DYNDNSCID        {$FormatedData = Get-DYNDNSClientID -UrlToGo $UrlToGo}

            # FIREWALL
            GET-FIREWALL         {$FormatedData = Get-FIREWALL -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-FIREWALLR        {$FormatedData = Get-FIREWALLRules -UrlToGo $UrlToGo}
            
            GET-FIREWALLRID      {$FormatedData = Get-FIREWALLRulesID -UrlToGo $UrlToGo}
            
            GET-FIREWALLGM       {$FormatedData = Get-FIREWALLGamerMode -UrlToGo $UrlToGo}
            
            GET-FIREWALLPR       {$FormatedData = Get-FIREWALLPingResponder -UrlToGo $UrlToGo}
            
            Get-FIREWALLv6R      {$FormatedData = Get-FIREWALLv6Rules -UrlToGo $UrlToGo}
            
            GET-FIREWALLv6RID    {$FormatedData = Get-FIREWALLv6RulesID -UrlToGo $UrlToGo}
            
            Get-FIREWALLv6L      {$FormatedData = Get-FIREWALLv6Level -UrlToGo $UrlToGo}
            
            # API
            GET-APIRM            {$FormatedData = Get-APIRessourcesMap -UrlToGo $UrlToGo -UrlRoot $UrlRoot}
            
            # HOST
            GET-HOSTS            {$FormatedData = Get-HOSTS -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-HOSTSID          {$FormatedData = Get-HOSTSID -UrlToGo $UrlToGo}
            
            GET-HOSTSME          {$FormatedData = Get-HOSTSME -UrlToGo $UrlToGo}
            
            Get-HOSTSL           {$FormatedData = Get-HOSTSLite -UrlToGo $UrlToGo}
            
            Get-HOSTSP           {$FormatedData = Get-HOSTSPAUTH -UrlToGo $UrlToGo}
            
            # LAN
            GET-LANIP            {$FormatedData = Get-LANIP -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-LANS             {$FormatedData = Get-LANStats -UrlToGo $UrlToGo}
            
            GET-LANA             {$FormatedData = Get-LANAlerts -UrlToGo $UrlToGo -APIName $APIName}
            
            # NAT
            GET-NAT              {$FormatedData = Get-NAT -UrlToGo $UrlToGo}
            
            GET-NATDMZ           {$FormatedData = Get-NATDMZ -UrlToGo $UrlToGo}
            
            GET-NATR             {$FormatedData = Get-NATRules -UrlToGo $UrlToGo}
            
            GET-NATRID           {$FormatedData = Get-NATRulesID -UrlToGo $UrlToGo}
            
            # Parental Control
            GET-PARENTALCONTROL  {$FormatedData = Get-ParentalControl -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-PARENTALCONTROLS {$FormatedData = Get-ParentalControlScheduler -UrlToGo $UrlToGo}
            
            GET-PARENTALCONTROLSR{$FormatedData = Get-ParentalControlSchedulerRules -UrlToGo $UrlToGo}
            
            # PHONE PROFILE
            GET-PROFILEC         {$FormatedData = Get-PHONEProfileConsumption -UrlToGo $UrlToGo}
            
            # REMOTE
            GET-REMOTEPWOL       {$FormatedData = Get-REMOTEProxyWOL -UrlToGo $UrlToGo}
            
            # SERVICES
            GET-SERVICES         {$FormatedData = Get-SERVICES -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-IPTV             {$FormatedData = Get-IPTV -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-IPTVD            {$FormatedData = Get-IPTVDiags -UrlToGo $UrlToGo}
            
            GET-NOTIFICATION     {$FormatedData = Get-NOTIFICATION -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-NOTIFICATIONA    {$FormatedData = Get-NOTIFICATIONAlerts -UrlToGo $UrlToGo}
            
            GET-NOTIFICATIONC    {$FormatedData = Get-NOTIFICATIONContacts -UrlToGo $UrlToGo}
            
            GET-NOTIFICATIONE    {$FormatedData = Get-NOTIFICATIONEvents -UrlToGo $UrlToGo}
            
            # UPNP IGD
            GET-UPNPIGD          {$FormatedData = Get-UPNPIGD -UrlToGo $UrlToGo}
            
            GET-UPNPIGDR         {$FormatedData = Get-UPNPIGDRules -UrlToGo $UrlToGo}
            
            # USB
            GET-DEVICEUSBP       {$FormatedData = Get-DeviceUSBPrinter -UrlToGo $UrlToGo}
            
            GET-DEVICEUSBD       {$FormatedData = Get-DeviceUSBDevices -UrlToGo $UrlToGo}
            
            GET-USBS             {$FormatedData = Get-USBStorage -UrlToGo $UrlToGo}
            
            # VOIP
            GET-VOIP             {$FormatedData = Get-VOIP -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-VOIPD            {$FormatedData = Get-VOIPDiag -UrlToGo $UrlToGo}
            
            GET-VOIPDU           {$FormatedData = Get-VOIPDiagUSB -UrlToGo $UrlToGo}
            
            GET-VOIPDH           {$FormatedData = Get-VOIPDiagHost -UrlToGo $UrlToGo}
            
            GET-VOIPS            {$FormatedData = Get-VOIPScheduler -UrlToGo $UrlToGo}
            
            GET-VOIPSR           {$FormatedData = Get-VOIPSchedulerRules -UrlToGo $UrlToGo}
            
            GET-VOIPCL           {$FormatedData = Get-VOIPCallLogLine -UrlToGo $UrlToGo}
            
            GET-VOIPFCL          {$FormatedData = Get-VOIPFullCallLogLine -UrlToGo $UrlToGo}
            
            GET-VOIPALN          {$FormatedData = Get-VOIPAllowedListNumber -UrlToGo $UrlToGo}
            
            # CPL
            GET-CPL              {$FormatedData = Get-CPL -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-CPLDL            {$FormatedData = Get-CPLDeviceList -UrlToGo $UrlToGo -APIName $APIName}
            
            # WAN
            GET-WANA             {$FormatedData = Get-WANAutowan -UrlToGo $UrlToGo}
            
            GET-WAND             {$FormatedData = Get-WANDiags -UrlToGo $UrlToGo}
            
            GET-WANDS            {$FormatedData = Get-WANDiagsSessions -UrlToGo $UrlToGo}

            GET-WANDSHAS         {$FormatedData = Get-WANDiagsSummaryHostsActiveSessions -UrlToGo $UrlToGo}
            
            Get-WANDAAS          {$FormatedData = Get-WANDiagsAllActiveSessions -UrlToGo $UrlToGo}

            Get-WANDAASH         {$FormatedData = Get-WANDiagsAllActiveSessionsHost -UrlToGo $UrlToGo}
            
            GET-WANFS            {$FormatedData = Get-WANFTTHStats -UrlToGo $UrlToGo}
            
            GET-WANIP            {$FormatedData = Get-WANIP -UrlToGo $UrlToGo}
            
            GET-WANIPS           {$FormatedData = Get-WANIPStats -UrlToGo $UrlToGo}
            
            Get-WANXDSL          {$FormatedData = Get-WANXDSL -UrlToGo $UrlToGo}

            Get-WANXDSLS         {$FormatedData = Get-WANXDSLStats -UrlToGo $UrlToGo}

            # WIRELESS
            Get-WIRELESS         {$FormatedData = Get-WIRELESS -UrlToGo $UrlToGo -APIName $APIName}
            
            GET-WIRELESS24       {$FormatedData = Get-WIRELESS24Ghz -UrlToGo $UrlToGo}
            
            GET-WIRELESS24S      {$FormatedData = Get-WIRELESSStats -UrlToGo $UrlToGo}
            
            GET-WIRELESS5        {$FormatedData = Get-WIRELESS5Ghz -UrlToGo $UrlToGo}
            
            GET-WIRELESS5S       {$FormatedData = Get-WIRELESSStats -UrlToGo $UrlToGo}
            
            GET-WIRELESSACL      {$FormatedData = Get-WIRELESSACL -UrlToGo $UrlToGo}
            
            GET-WIRELESSACLR     {$FormatedData = Get-WIRELESSACLRules -UrlToGo $UrlToGo}
            
            GET-WIRELESSACLRID   {$FormatedData = Get-WIRELESSACLRulesID -UrlToGo $UrlToGo}
            
            GET-WIRELESSWPS      {$FormatedData = GET-WIRELESSWPS -UrlToGo $UrlToGo}
            
            GET-WIRELESSFBNH     {$FormatedData = Get-WIRELESSFrequencyNeighborhoodScan -UrlToGo $UrlToGo -UrlRoot $UrlRoot -APIVersion $APIVersion -APIName $APIName -Port $Port}
            
            GET-WIRELESSS        {$FormatedData = Get-WIRELESSScheduler -UrlToGo $UrlToGo}
            
            GET-WIRELESSSR       {$FormatedData = Get-WIRELESSSchedulerRules -UrlToGo $UrlToGo}
            
            Get-WIRELESSR        {$FormatedData = Get-WIRELESSRepeater -UrlToGo $UrlToGo}
            
            # SUMMARY
            Get-SUMMARY          {$FormatedData = Get-SUMMARY -UrlToGo $UrlToGo}
            
            # USERSAVE
            Get-USERSAVE         {$FormatedData = Get-USERSAVE -UrlToGo $UrlToGo -APIName $APIName}
            
            # BBOXJournal
            Get-BBoxJournal      {$FormatedData = Get-BBoxJournal -UrlToGo $UrlToGo -JournalPath $JournalPath}
            
            # Remove-FolderContent
            Remove-FCLogs        {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName}
            
            Remove-FCExportCSV   {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName}
            
            Remove-FCExportJSON  {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName}
            
            Remove-FCJournal     {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName}
            
            Remove-FCJBC         {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName}
            
            Remove-FCReport      {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName}
            
            # DisplayFormat
            Switch-DF            {$FormatedData = Switch-DisplayFormat}
            
            # ExportFormat
            Switch-EF            {$FormatedData = Switch-ExportFormat}
            
            # OpenHTMLReport
            Switch-OHR           {$FormatedData = Switch-OpenHTMLReport}
            
            # Exit
            Q                    {$global:TriggerExit = 1}
            
            # Default
            Default              {Write-Host "Selected Action is not yet developed, please chose another one and contact me by mail to : $Mail for more information" -ForegroundColor Yellow
                                  $FormatedData = "Program"
                                  Pause
                                 }
        }
    
        Return $FormatedData
}

# Used only to quit the Program
Function Stop-Program {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$LogsPath,
        
        [Parameter(Mandatory=$True)]
        [String]$LogsFileName
    )
    
    Write-Log -Type INFO -Name "Stop Program" -Message "Program exiting ..." -NotDisplay
    Write-Log -Type WARNING -Name "Stop Program" -Message "Please don't close this windows manually !"
    Write-Log -Type INFO -Name "Stop Program" -Message "We are closing background processes before quit the program"
    Write-Log -Type INFO -Name "ChromeDriver Stop" -Message "Start Stop Chrome Driver" -NotDisplay
    If($Null -ne $global:ChromeDriver){Stop-ChromeDriver}
    Write-Log -Type INFO -Name "ChromeDriver Stop" -Message "End Stop Chrome Driver" -NotDisplay
    Start-Sleep 5
    $Curent_Logs_File = (Get-ChildItem -Path "$LogsPath\$LogsFileName*.csv" | Select-Object FullName,LastWriteTime | Sort-Object LastWriteTime -Descending).Fullname[0]
    Write-Log -Type INFONO -Name "Stop Program" -Message "Log file is available here : "
    Write-Log -Type VALUE -Name "Stop Program" -Message "$Curent_Logs_File"
    Write-Log -Type INFO -Name "Stop Program" -Message "Program Closed" -NotDisplay 
}

#endregion GLOBAL


#region Export data (All functions below are used only on powershell script : ".\BBOX-Administration.ps1")

# Used only to export Full BBOX Configuration to JSON files
function Export-BboxConfiguration {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$APISName,
        
        [Parameter(Mandatory=$True)]
        [String]$ConnexionType,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$APIVersion,
        
        [Parameter(Mandatory=$False)]
        [String]$Port,
        
        [Parameter(Mandatory=$True)]
        [String]$OutputFolder
    ) 
    
    Foreach($APIName in $APISName){
        
        $UrlToGo = Switch-ConnexionType -UrlRoot $UrlRoot -Port $Port -APIVersion $APIVersion -APIName $APIName
        
        # Get information from BBOX API
        Write-Log -Type INFO -Name "Program run - Get Information" -Message "Get $APIName configuration ..."
        $Json = Get-BBoxInformation -UrlToGo $UrlToGo
        
        # Export result as JSON file
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $Exportfile = $APIName.replace("/","-")
        $FullPath = "$OutputFolder\$Date-$Exportfile.json"
        Write-Log -Type INFO -Name "Program run - Export Bbox Configuration To JSON" -Message "Start Export Bbox Configuration To JSON" -NotDisplay
        Write-Log -Type INFONO -Name "Program run - Export Bbox Configuration To JSON" -Message "Export configuration to : "
        Write-Log -Type VALUE -Name "Program run - Export Bbox Configuration To JSON" -Message "$FullPath"
        Write-Log -Type INFONO -Name "Program run - Export Bbox Configuration To JSON" -Message "Export Bbox Configuration To JSON status : " -NotDisplay
        Try{
            $Json | ConvertTo-Json | Out-File -FilePath $FullPath -Force
            Write-Log -Type VALUE -Name "Program run - Export Bbox Configuration To JSON" -Message "Successfull" -NotDisplay
        }
        Catch{
            Write-Log -Type WARNING -Name "Program run - Export Bbox Configuration To JSON" -Message "Failed, due to $($_.tostring())"
        }
        
        Write-Log -Type INFO -Name "Program run - Export Bbox Configuration To JSON" -Message "End Export Bbox Configuration To JSON" -NotDisplay
    }
    
    Return "Program"
}

# Used only to export Full BBOX Configuration to JSON files
function Export-BBoxConfigTestingProgram {
    
    Param(
        
        [Parameter(Mandatory=$True)]
        [Array]$APISName,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$ConnexionType,
        
        [Parameter(Mandatory=$True)]
        [String]$APIVersion,
        
        [Parameter(Mandatory=$False)]
        [String]$Port,
        
        [Parameter(Mandatory=$True)]
        [String]$Mail,
        
        [Parameter(Mandatory=$True)]
        [String]$JournalPath,
        
        [Parameter(Mandatory=$True)]
        [String]$OutputFolder
    )
    
    Write-Log -Type INFO -Name "Program run - Testing Program" -Message "Sart Testing Program"

    Foreach($APIName in $APISName){
            
        Write-Log -Type INFONO -Name "Program run - Action asked" -Message "Tested action : "
        Write-Log -Type VALUE -Name "Program run - Action asked" -Message "$($APIName.Label)"   
        
        $UrlToGo = Switch-ConnexionType -UrlRoot $UrlRoot -Port $Port -APIVersion $APIVersion -APIName $APIName.APIName
        
        # Get information from BBOX API
        $FormatedData = Switch-Info -Label $APIName.Label -UrlToGo $UrlToGo -APIName $APIName.APIName -UrlRoot $UrlRoot -ConnexionType $ConnexionType -APIVersion $APIVersion -Port $Port -Mail $Mail -JournalPath $JournalPath -OutputFolder $OutputFolder
        
        # Export result as CSV file
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $Exportfile = $APIName.ExportFile
        $FullPath = "$OutputFolder\$Date-$Exportfile.csv"
        Write-Log -Type INFO -Name "Program run - Testing Program" -Message "Start Export Bbox Configuration To CSV" -NotDisplay
        Write-Log -Type INFONO -Name "Program run - Testing Program" -Message "Export configuration to : "
        Write-Log -Type VALUE -Name "Program run - Testing Program" -Message "$FullPath"
        Write-Log -Type INFONO -Name "Program run - Testing Program" -Message "Export Bbox Configuration To CSV status : " -NotDisplay
        Try{
            $FormatedData | Export-Csv -Path $FullPath -Encoding UTF8 -Force -NoTypeInformation -Delimiter ";" 
            Write-Log -Type VALUE -Name "Program run - Testing Program" -Message "Successfull" -NotDisplay
        }
        Catch{
            Write-Log -Type WARNING -Name "Program run - Testing Program" -Message "Failed, due to $($_.tostring())"
        }
        
        Write-Log -Type INFO -Name "Program run - Testing Program" -Message "End Export Bbox Configuration To CSV" -NotDisplay
    }
    
    Write-Log -Type INFO -Name "Program run - Testing Program" -Message "End Testing Program"
    
    Return "Program"
}

# Used only to export BBOX Journal
Function Get-BBoxJournal {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,

        [Parameter(Mandatory=$True)]
        [String]$JournalPath
    )
        
    # Loading Journal Home Page
    $UrlToGo = $UrlToGo -replace "/api/v1"
    $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
    Start-Sleep 2
    
    # Download Journal file from BBOX
    Write-Log -Type INFO -Name "Program run - Download Bbox Journal to export" -Message "Start download Bbox Journal" -NotDisplay
    $global:ChromeDriver.FindElementByClassName("download").click()
    Write-Log -Type INFO -Name "Program run - Download Bbox Journal to export" -Message "Download in progress ..."
    Start-Sleep 5
    
    # Waiting end of journal's download
    $JournalName = "journal-124235808489747*.csv"
    $UserDownloadFolderDefault =  Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"
    $UserDownloadFolderDefaultFileName = $(Get-ChildItem -Path $UserDownloadFolderDefault -Name $JournalName | Sort-Object LastWriteTime -Descending )[-1]
    $UserDownloadFileFullPath = "$UserDownloadFolderDefault\$UserDownloadFolderDefaultFileName"
    
    If(Test-Path -Path $UserDownloadFileFullPath){
        
        # Move Journal file from Download folder to journal folder : "$PSScriptRoot\Journal"
        $DownloadedJournalDestination = "$JournalPath\$UserDownloadFolderDefaultFileName"
        Move-Item -Path $UserDownloadFileFullPath -Destination $DownloadedJournalDestination -Force
        
        # Getting last Journal file version
        Write-Log -Type VALUE -Name "Program run - Download Bbox Journal to export" -Message "Download ended"
        Write-Log -Type INFONO -Name "Program run - Download Bbox Journal to export" -Message "Bbox Journal has been saved to : "
        Write-Log -Type VALUE -Name "Program run - Download Bbox Journal to export" -Message $DownloadedJournalDestination
        Write-Log -Type INFO -Name "Program run - Download Bbox Journal to export" -Message "End download Bbox Journal" -NotDisplay
        
        # Export Journal data as CSV file to to correct folder
        $FormatedData = Import-Csv -Path $DownloadedJournalDestination -Delimiter ';' -Encoding UTF8
        
        Return $FormatedData
    }
    Else{
        Write-Host "Failed to download Journal due to time out." -ForegroundColor Yellow
        Write-Log -Type WARNING -Name "Program run - Download Bbox Journal to export" -Message "Failed to download Journal" -NotDisplay
        Write-Log -Type INFO -Name "Program run - Download Bbox Journal to export" -Message "End download Bbox Journal" -NotDisplay
        Return "Program"
    }
}

# Used only to change Export Format, linked to : "Format-ExportResult"
Function Switch-ExportFormat {
    
    # Choose Export Format : CSV or JSON
    $global:ExportFormat = ""
    Write-Log -Type INFO -Name "Program run - Choose Export Result" -Message "Start data export format" -NotDisplay
    Write-Log -Type INFO -Name "Program run - Choose Export Result" -Message "Please choose an export format : (C) CSV or (J) JSON"
    
    While($global:ExportFormat[0] -notmatch "C|J"){
        
        $Temp = Read-Host "Enter your choice"
            
        Switch($Temp){
                
            C    {$global:ExportFormat = "C"}
            J    {$global:ExportFormat = "J"}
        }
    }
    
    Write-Log -Type INFO -Name "Program run - Choose Export Result" -Message "Value Choosen  : $global:ExportFormat" -NotDisplay
    Write-Log -Type INFO -Name "Program run - Choose Export Result" -Message "End data export format" -NotDisplay
    Return "Program"
}

# Used only to format export result function user choice, linked to : "Export-toCSV" and "Export-toJSON"
Function Format-ExportResult {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$ExportCSVPath,
        
        [Parameter(Mandatory=$True)]
        [String]$ExportJSONPath,
        
        [Parameter(Mandatory=$True)]
        [String]$Exportfile
    )
    
    Switch($global:ExportFormat){
        
        'C' {# Export result to CSV
             Export-toCSV -FormatedData $FormatedData -APIName $APIName -ExportCSVPath $ExportCSVPath -Exportfile $Exportfile
            }
        'J' {# Export result to JSON
             Export-toJSON -FormatedData $FormatedData -APIName $APIName -JsonBboxconfigPath $ExportJSONPath -Exportfile $Exportfile
            }
    }
}

# Used only to export result to CSV File, linked to : "Format-ExportResult"
Function Export-toCSV {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$ExportCSVPath,
        
        [Parameter(Mandatory=$True)]
        [String]$Exportfile
    )
    
    Write-Log -Type INFO -Name "Program run - Export Result CSV" -Message "Start export result as CSV" -NotDisplay
    
    Try{
        # Define Export file path
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $ExportPath = "$ExportCSVPath\$Date-$Exportfile.csv"
        $FormatedData | Export-Csv -Path $ExportPath -Encoding UTF8 -Delimiter ";" -NoTypeInformation -Force
        Write-Log -Type INFONO -Name "Program run - Export Result CSV" -Message "CSV Data have been exported to : " -NotDisplay
        Write-Log -Type VALUE -Name "Program run - Export Result CSV" -Message "$ExportPath" -NotDisplay
    }
    Catch{
        Write-Log -Type ERROR -Name "Program run - Export Result CSV" -Message "Failed to export data to : $ExportPath due to : $($_.ToString())"
    }
    
    Write-Log -Type INFO -Name "Program run - Export Result CSV" -Message "End export result as CSV" -NotDisplay
}

# Used only to export result to JSON File, linked to : "Format-ExportResult"
Function Export-toJSON {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$JsonBboxconfigPath,
        
        [Parameter(Mandatory=$True)]
        [String]$Exportfile
    )
    
     Write-Log -Type INFO -Name "Program run - Export Result JSON" -Message "Start export result as JSON" -NotDisplay
     
     Try{
        # Define Export file path
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $FullPath = "$JsonBboxconfigPath\$Date-$Exportfile.json"
        $FormatedData | ConvertTo-Json | Out-File -FilePath $FullPath -Force
        Write-Log -Type INFONO -Name "Program run - Export Result JSON" -Message "JSON Data have been exported to : " -NotDisplay
        Write-Log -Type VALUE -Name "Program run - Export Result JSON" -Message "$FullPath" -NotDisplay
    }
    Catch{
        Write-Log -Type ERROR -Name "Program run - Export Result JSON" -Message "Failed to export data to : $FullPath due to : $($_.ToString())"
    }
    
    Write-Log -Type INFO -Name "Program run - Export Result JSON" -Message "End export result as JSON" -NotDisplay
}

# Used only to change Display Format, linked to : "Format-DisplayResult"
Function Switch-DisplayFormat {

    # Choose Display Format : HTML or Table
    $global:DisplayFormat = ""
    Write-Log -Type INFO -Name "Program run - Choose Display Format" -Message "Start data display format" -NotDisplay
    Write-Log -Type INFO -Name "Program run - Choose Display Format" -Message "Please choose a display format : (H) HTML or (T) Table/Gridview"
        
    While($global:DisplayFormat[0] -notmatch "H|T"){
            
        $Temp = Read-Host "Enter your choice"
            
        Switch($Temp){
                
            H    {$global:DisplayFormat = "H"}
            T    {$global:DisplayFormat = "T"}
        }
    }
        
    Write-Log -Type VALUE -Name "Program run - Choose Display Format" -Message "Value Choosen : $global:DisplayFormat" -NotDisplay
    Write-Log -Type INFO -Name "Program run - Choose Display Format" -Message "End data display format" -NotDisplay
    Return "Program"
}

# Used only to format display result function user choice, linked to : "Export-HTMLReport" and "Out-GridviewDisplay" and "Open-HTMLReport"
Function Format-DisplayResult {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$Description,
        
        [Parameter(Mandatory=$True)]
        [String]$ReportType,
        
        [Parameter(Mandatory=$True)]
        [String]$ReportPath,
        
        [Parameter(Mandatory=$True)]
        [String]$Exportfile
    )
    
    Switch($global:DisplayFormat){
        
        'H' {# Display result by HTML Report
             Export-HTMLReport -DataReported $FormatedData -ReportTitle "BBOX Configuration Report - $APIName" -ReportType $ReportType -ReportPath $ReportPath -ReportFileName $Exportfile -HTMLTitle "BBOX Configuration Report" -ReportPrecontent $APIName -Description $Description
            }
        
        'T' {# Display result by Out-Gridview
             Out-GridviewDisplay -FormatedData $FormatedData -APIName $APIName -Description $Description
            }
    }
    Write-Log -Type INFO -Name "Program run - Display Result" -Message "End display result" -NotDisplay

}

# Used only to create HTML Report, linked to : "Format-DisplayResult"
function Export-HTMLReport {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$DataReported,
        
        [Parameter(Mandatory=$True)]
        [ValidateSet("List", "Table")]
        [String]$ReportType,
        
        [Parameter(Mandatory=$True)]
        [String]$ReportTitle,
        
        [Parameter(Mandatory=$True)]
        [String]$ReportPath,

        [Parameter(Mandatory=$True)]
        [String]$ReportFileName,

        [Parameter(Mandatory=$True)]
        [String]$HTMLTitle,

        [Parameter(Mandatory=$True)]
        [String]$ReportPrecontent,
        
        [Parameter(Mandatory=$True)]
        [String]$Description
    )
    
    $HTML = $null
    $Title = "<h1>$HTMLTitle</h1>"
    $PreContent = "<h2> API Name : $ReportPrecontent </h2> Description : $Description<br/><br/>"
    $header = @("<style>
                    h1 {
                        font-family: Arial, Helvetica, sans-serif;
                        color: #e68a00;
                        font-size: 28px;
                    }

                    h2 {
                        font-family: Arial, Helvetica, sans-serif;
                        color: #000099;
                        font-size: 16px;
                    }

                    table {
		                font-size: 12px;
		                border: 0px; 
		                font-family: Arial, Helvetica, sans-serif;
	                }
	                
                    td {
		                padding: 4px;
		                margin: 0px;
		                border: 0;
	                }
	                
                    th {
                        background: #395870;
                        background: linear-gradient(#49708f, #293f50);
                        color: #fff;
                        font-size: 11px;
                        text-transform: uppercase;
                        padding: 10px 15px;
                        vertical-align: middle;
	                }

                    tbody tr:nth-child(even) {
                        background: #f0f0f2;
                    }

                    CreationDate {
                        font-family: Arial, Helvetica, sans-serif;
                        color: #ff3300;
                        font-size: 12px;
                    }
                </style>
            ")
    
    $ReportAuthor = "Report generated by : $env:USERNAME, from : $env:COMPUTERNAME, at : $(Get-Date) (Local Time)."
    $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
    
    Switch($ReportPrecontent){
        
        "lan/ip"    {$LANIP     = $DataReported[0] | ConvertTo-Html -As List -PreContent "<h2> LAN Configuration </h2><br/>"
                     $LANSwitch = $DataReported[1] | ConvertTo-Html -As Table -PreContent "<h2> LAN Switch Configuration </h2><br/>"
                     $HTML      = ConvertTo-HTML -Body "$Title $PreContent $LANIP $LANSwitch" -Title $ReportTitle -Head $header -PostContent "<br/>$ReportAuthor"
                    }
        
        "wan/diags" {$DNS  = $DataReported.DNS  | ConvertTo-Html -As Table -PreContent "<h2> WAN DNS Statistics </h2>"
                     $HTTP = $DataReported.HTTP | ConvertTo-Html -As Table -PreContent "<h2> WAN HTTP Statistics </h2>"
                     $PING = $DataReported.PING | ConvertTo-Html -As Table -PreContent "<h2> WAN PING Statistics </h2>"
                     $HTML = ConvertTo-HTML -Body "$Title $PreContent $DNS $HTTP $PING" -Title $ReportTitle -Head $header -PostContent "<br/>$ReportAuthor"
                    }
        
        "wan/autowan"{$Config          = $DataReported[0] | ConvertTo-Html -As Table -PreContent "<h2> Auto WAN Configuration </h2>"
                     $Profiles         = $DataReported[1] | ConvertTo-Html -As Table -PreContent "<h2> WAN Profiles</h2>"
                     $ProfilesDetailed = $DataReported[2] | ConvertTo-Html -As Table -PreContent "<h2> WAN Profiles Détailled </h2>"
                     $Services         = $DataReported[3] | ConvertTo-Html -As Table -PreContent "<h2> WAN PING Statistics </h2>"
                     $HTML             = ConvertTo-HTML -Body "$Title $PreContent $Config $Services $Profiles $ProfilesDetailed" -Title $ReportTitle -Head $header -PostContent "<br/>$ReportAuthor"
                    }
        
        Default     {$HTML = ConvertTo-Html -Body "$Title $PreContent $($DataReported | ConvertTo-Html -As "$ReportType")" -Title $ReportTitle -Head $header -PostContent "<br/>$ReportAuthor"
                    }
    }
    
    $FullReportPath = "$ReportPath\$Date-$ReportFileName.html"
    
    Write-Log -Type INFO -Name "Program run - Export HTML Report" -Message "Start export HTML report" -NotDisplay
    Write-Log -Type INFONO -Name "Program run - Export HTML Report" -Message "Export HTML report status : " -NotDisplay
    
    Try{
        $HTML | Out-File -FilePath $FullReportPath -Force -Encoding utf8
        Write-Log -Type VALUE -Name "Program run - Export HTML Report" -Message "Successfull" -NotDisplay
        Write-Log -Type INFONO -Name "Program run - Export HTML Report" -Message "HTML Report has been exported to : " -NotDisplay
        Write-Log -Type VALUE -Name "Program run - Export HTML Report" -Message "$FullReportPath" -NotDisplay
    }
    Catch{
        Write-Log -Type WARNING -Name "Program run - Export HTML Report" -Message "Failed, to export HTML report : $FullReportPath , due to $($_.tostring())" -NotDisplay
    }
    
    Write-Log -Type INFO -Name "Program run - Export HTML Report" -Message "End export HTML report" -NotDisplay
    
    If($global:TriggerOpenHTMLReport -eq 0){
        
        $global:TriggerOpenHTMLReport = Switch-OpenHTMLReport
    }

    Open-HTMLReport -Path $FullReportPath
}

# Used only to Out-Gridview Display, linked to : "Format-DisplayResult"
Function Out-GridviewDisplay {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$Description
    )
    
    Write-Log -Type INFO -Name "Program run - Out-Gridview Display" -Message "Start Out-Gridview Display" -NotDisplay
    
    Switch($APIName){
                
        "lan/ip"   {$FormatedData[0] | Out-GridView -Title "$Description - LAN Configuration"
                    $FormatedData[1] | Out-GridView -Title "$Description - Bbox Switch Port Configuration"
                   }
        
        "wan/diags"{$FormatedData.DNS  | Out-GridView -Title "$Description - DNS"
                    $FormatedData.HTTP | Out-GridView -Title "$Description - HTTP"
                    $FormatedData.Ping | Out-GridView -Title "$Description - PING"
                   }
                    
        Default    {$FormatedData | Out-GridView -Title $Description -Wait}
                
    }
    
    Write-Log -Type INFO -Name "Program run - Out-Gridview Display" -Message "End Out-Gridview Display" -NotDisplay
}

# Used only to open or not HTML Report, linked to : "Open-HTMLReport"
Function Switch-OpenHTMLReport {
    
    $global:OpenHTMLReport = ""
    Write-Log -Type INFO -Name "Program run - Switch Open HTML Report" -Message "Start Switch Open HTML Report" -NotDisplay
    Write-Log -Type INFO -Name "Program run - Switch Open HTML Report" -Message "Please choose if want to open HTML Report at each time or not : (Y) Yes or (N) No"
    
    While($global:OpenHTMLReport[0] -notmatch "Y|N"){
        
        $Temp = Read-Host "Enter your choice"
        
        Switch($Temp){
                
            Y    {$global:OpenHTMLReport = "Y"}
            N    {$global:OpenHTMLReport = "N"}
        }
    }
    
    Write-Log -Type INFO -Name "Program run - Switch Open HTML Report" -Message "Value Choosen : $global:OpenHTMLReport" -NotDisplay
    Write-Log -Type INFO -Name "Program run - Switch Open HTML Report" -Message "End Switch Open HTML Report" -NotDisplay
    Return "Program"
}

# Used only to open HTML Report, linked to : "Export-HTMLReport" and "Switch-OpenHTMLReport"
Function Open-HTMLReport {
    
    Param([Parameter(Mandatory=$True)]
        [String]$Path
    )
    
    Write-Log -Type INFO -Name "Program run - Open HTML Report" -Message "Start Open HTML Report" -NotDisplay
    Write-Log -Type INFONO -Name "Program run - Open HTML Report" -Message "Open HTML Report Status : " -NotDisplay
    
    If($global:OpenHTMLReport -eq "y"){
        
        Try{
            Start-Process $Path
            Write-Log -Type VALUE -Name "Program run - Open HTML Report" -Message "Successfull" -NotDisplay
        }
        Catch{
            Write-Log -Type WARNING -Name "Program run - Open HTML Report" -Message "Failed to open HTML report : $Path, due to $($_.tostring())" -NotDisplay
        }
    }
    Else{
        Write-Log -Type VALUE -Name "Program run - Open HTML Report" -Message "User don't want to open HTML report" -NotDisplay
    }
    
    Write-Log -Type INFO -Name "Program run - Open HTML Report" -Message "Start Open HTML Report" -NotDisplay
}

# Used only to manage errors when there is no data to Export/Display, linked to many functions
Function EmptyFormatedDATA {
    
    Param(
        [Parameter(Mandatory=$False)]
        [Array]$FormatedData
    )
    
    Write-Log -Type INFO -Name "Program run - Display Result" -Message "Start display result" -NotDisplay
    Write-Log -Type INFO -Name "Program run - Export Result" -Message "Start export result" -NotDisplay
    
    Switch($FormatedData){
        
        $Null   {Write-Log -Type INFO -Name "Program run - Display / Export Result" -Message "No data were found, no need to Export/Display" -NotDisplay;break}
        
        Domain  {Write-Log -Type WARNING -Name "Program run - Display / Export Result" -Message "Due to error, the result can't be displayed / exported" -NotDisplay;break}
                
        Program {Write-Log -Type INFO -Name "Program run - Display / Export Result" -Message "No data need to be exported or displayed" -NotDisplay;break}
        
        Default {Write-Log -Type WARNING -Name "Program run - Display / Export Result" -Message "Unknow Error, seems dev missing, result : $($FormatedData.tostring())"}
    }

    Write-Log -Type INFO -Name "Program run - Export Result" -Message "End export result" -NotDisplay
    Write-Log -Type INFO -Name "Program run - Display Result" -Message "End display result" -NotDisplay
}

#endregion Export data


#region Features (Functions used by functions in the PSM1 file : ".\BBOX-Module.psm1")

Function Get-State {
    
    Param(
        [Parameter(Mandatory=$False)]
        [String]$State
    )
    
    Switch($State){
    
        ""         {$Value = "Dev Error"}
        .          {$Value = "Not available with your device"}
        -1         {$Value = "Error"}
        0          {$Value = "Disable"}
        1          {$Value = "Enable"}
        2          {$Value = "Enable"}
        3          {$Value = "Enable"}
        4          {$Value = "Enable"}
        55         {$Value = "Enable"}
        on         {$Value = "Enable"}
        off        {$Value = "Disable"}
        Up         {$Value = "Enable"}
        Down       {$Value = "Disable"}
        None       {$Value = "None"}
        True       {$Value = "Yes"}
        False      {$Value = "No"}
        Idle       {$Value = "Idle"}
        Configured {$Value = "Configured"}
        Connected  {$Value = "Connected"}
        Discover   {$Value = "Discover"}
        Disabled   {$Value = "Disabled"}
        Disable    {$Value = "Disable"}
        Enabled    {$Value = "Enabled"}
        Enable     {$Value = "Enable"}
        Empty      {$Value = "Empty"}
        Error      {$Value = "Error"}
        running    {$Value = "running"}
        Default    {$Value = "Unknow / Dev Error"}
    }
    
    Return $Value
}

Function Get-Status {
    
    Param(
        [Parameter(Mandatory=$False)]
        [String]$Status
    )
    
    Switch($Status){
    
        ""         {$Value = "Can't be define because service is disabled"}
        .          {$Value = "Not available with your device"}
        -1         {$Value = "Error"}
        0          {$Value = "Disable"}
        1          {$Value = "Enable"}
        2          {$Value = "Enable"}
        3          {$Value = "Enable"}
        4          {$Value = "Enable"}
        55         {$Value = "Enable"}
        on         {$Value = "Enable"}
        off        {$Value = "Disable"}
        Up         {$Value = "Enable"}
        Down       {$Value = "Disable"}
        None       {$Value = "None"}
        True       {$Value = "Yes"}
        False      {$Value = "No"}
        Idle       {$Value = "Idle"}
        Configured {$Value = "Configured"}
        Connected  {$Value = "Connected"}
        Discover   {$Value = "Discover"}
        Disabled   {$Value = "Disabled"}
        Disable    {$Value = "Disable"}
        Enabled    {$Value = "Enabled"}
        Enable     {$Value = "Enable"}
        Empty      {$Value = "Empty"}
        Error      {$Value = "Error"}
        Ready      {$Value = "Ready"}
        Default    {$Value = "Unknow / Dev Error"}
    }
    
    Return $Value
}

Function Get-YesNoAsk {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$YesNoAsk
    )
    
    Switch($YesNoAsk){
    
        0       {$Value = "No"}
        1       {$Value = "Yes"}
        Default {$Value = "Unknow / Dev Error"}
    }
    
    Return $Value
}

# Used only to get USB folder type, linked to : "Get-USBStorage"
Function Get-USBFolderType {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$USBFolderType
    )
    
    Switch($USBFolderType){
    
        0       {$Value = "Directory"}
        1       {$Value = "Photo"}
        2       {$Value = "Video"}
        3       {$Value = "Music"}
        4       {$Value = "Document"}
        10      {$Value = "Other"}
        Default {$Value = "Unknow / Dev Error"}
    }
    
    Return $Value
}

# Format Custom Date/Time, linked to many functions
function Format-Date {
    
    Param(
        [Parameter(Mandatory=$False)]
        [String]$String
    )
    
    If(-not ([string]::IsNullOrEmpty($String))){
        
        $Date = $($String.Split("T"))[0]
        $TimeExtend = $($String.Split("T"))[1]
        
        If($TimeExtend[-1] -contains 'Z'){
            
            $Time = $TimeExtend.Replace('Z','')
            $TimeZone = "GDMT"
        }
        Else{
        
            $Time = $($TimeExtend.Split("+"))[0]
            $TimeZone = $($TimeExtend.Split("+"))[1]
            
            Switch($TimeZone){
                
                0100    {$TimeZone = "GDMT+1"}
                0200    {$TimeZone = "GDMT+2"}
                Default {$TimeZone = "GDMT"}
            }
        }
        Return "$Date - $Time - $TimeZone"    
    }
    Else{Return "Dev Error"}
}

# Format Custom Date/Time, linked to : "Start-RefreshWIRELESSFrequencyNeighborhoodScan" and "Get-VOIPCallLogLineX" and "Get-VOIPFullCallLogLineX"
function Format-Date1970 {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Seconds
    )
    
    $Date = (Get-Date -Date "01/01/1970").addseconds($Seconds)
    
    Return $Date
}

# Used only to get USB right, linked to : "Get-DeviceUSBDevices"
Function Get-USBRight {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$USBRight
    )
    
    Switch($USBRight){
    
        0       {$Value = "Read Only"}
        1       {$Value = "Read/Right"}
        Default {$Value = "Unknow / Dev Error"}
    }
    
    Return $Value
}

# Used only to know which call type, linked to : "Get-VOIPCallLogLineX"
Function Get-VoiceCallType {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$VoiceCallType
    )
    
    Switch($VoiceCallType){
    
        in        {$Value = "Incoming"}
        in_reject {$Value = "Incoming Rejected (`"Unknow`" active rule)"}
        in_barred {$Value = "Incoming Out Range Call (Active rule)"}
        out       {$Value = "Outgoing"}
        Default   {$Value = "Unknow / Dev Error - $VoiceCallType"}
    }
    
    Return $Value
}

# Used only to get Powersatus for leds, linked to : "Get-DeviceLED"
Function Get-PowerStatus {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$PowerStatus
    )
    
    Switch($PowerStatus){
        
        on      {$Value = "Light up"}
        off     {$Value = "Light down"}
        Up      {$Value = "Light up"}
        Down    {$Value = "Light down"}
        blink   {$Value = "Light blinking"}
        Default {$Value = "Unknow / Dev Error"}
    }
    
    Return $Value
}

# Used only to get phone line linked to : Get-DeviceLog
Function Get-PhoneLine {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Phoneline
    )
    
    Switch($Phoneline){
    
        1       {$Value = "Line 1"}
        2       {$Value = "Line 2"}
        Default {$Value = "Unknow"}
    }
    
    Return $Value
}

# Used only to select by user the phone line to check, linked to : Get-VOIPCallLogLine / Get-VOIPFullCallLogLine
Function Get-PhoneLineID {
    
    Write-Host "`nWhich Phone line do you want to select ?"
    Write-Host "(1) Main line`n(2) Second line"
    
    While($LineID -notmatch "1|2"){
        
        $LineID = Read-Host "Enter value"
    }
    
    Return $LineID
}

# Used by Function : Switch-Info, linked to "Get-PhoneLineID" and "Get-VOIPCalllogLineX"
Function Get-VOIPCallLogLine {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )

    $LineID = Get-PhoneLineID
    $FormatedData = Get-VOIPCalllogLineX -UrlToGo "$UrlToGo/$LineID"
    
    Return $FormatedData
}

# Used by Function : Switch-Info, linked to "Get-PhoneLineID" and "Get-VOIPFullcalllogLineX"
Function Get-VOIPFullCallLogLine {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $LineID = Get-PhoneLineID
    $FormatedData = Get-VOIPFullcalllogLineX -UrlToGo "$UrlToGo/$LineID"
    
    Return $FormatedData
}

# Used only to set (PUT/POST) information
Function Set-BBoxInformation {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlHome,
        
        [Parameter(Mandatory=$True)]
        [String]$Password,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    Write-host "`nConnexion à la BBOX : " -NoNewline
    
    # Add path for ChromeDriver.exe to the environmental variable 
    $env:PATH += "$PSScriptRoot"
    
    # Adding Selenium's .NET assembly (dll) to access it's classes in this PowerShell session
    Add-Type -Path "$PSScriptRoot\ChromeDriver\WebDriver.dll"
    
    # Hide the ChromeDriver
    #$chromeoption = New-Object OpenQA.Selenium.Chrome.ChromeOptions
    #$chromeoption.AddArguments('headless')
    
    # Start the ChromeDriver
    $global:ChromeDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver #($chromeoption)
    
    # Open Web Site Home Page 
    $global:ChromeDriver.Navigate().GoToURL($UrlHome)
    
    # Enter the password to connect (# Methods to find the input textbox for the password)
    $global:ChromeDriver.FindElementByName("password").SendKeys("$Password") 
    Start-Sleep 1
    
    # Click on the connect button
    $global:ChromeDriver.FindElementByClassName("cta-1").Submit()
    Start-Sleep 2
    
    Write-host "OK" -ForegroundColor Green
    Write-Host "Application des modifications souhaitées : " -NoNewline
    
    # Go to the web page to get information we need
    $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
    
    # Get Web page Content
    $Html = $global:ChromeDriver.PageSource
    
    # Close all ChromeDriver instances openned
    $global:ChromeDriver.Close()
    $global:ChromeDriver.Dispose()
    $global:ChromeDriver.Quit()
    
    Get-Process -Name chromedriver -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
    
    Write-host "OK" -ForegroundColor Green
    
    Return $Html
}

#endregion Features


#region Switch-Info (Functions used only in the PSM1 file : ".\BBOX-Module.psm1")

#region Errors code

Function Get-ErrorCode {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$Json
    )
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.exception

    # Create New PSObject and add values to array
    $ErrorLine = New-Object -TypeName PSObject
    $ErrorLine | Add-Member -Name "Domain"      -MemberType Noteproperty -Value $Json.domain
    $ErrorLine | Add-Member -Name "Code"        -MemberType Noteproperty -Value $Json.code
    $ErrorLine | Add-Member -Name "ErrorName"   -MemberType Noteproperty -Value $Json.errors.name
    $ErrorLine | Add-Member -Name "ErrorReason" -MemberType Noteproperty -Value $Json.errors.reason
    
    # Add lines to $Array
    $Array += $ErrorLine
    
    Return $Array
}

Function Get-ErrorCodeTest {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    #$Json = $Json.exception
    
    # Create New PSObject and add values to array
    $ErrorLine = New-Object -TypeName PSObject
    $ErrorLine | Add-Member -Name "Domain"      -MemberType Noteproperty -Value $Json.exception.domain
    $ErrorLine | Add-Member -Name "Code"        -MemberType Noteproperty -Value $Json.exception.code
    $ErrorLine | Add-Member -Name "ErrorName"   -MemberType Noteproperty -Value $Json.exception.errors.name
    $ErrorLine | Add-Member -Name "ErrorReason" -MemberType Noteproperty -Value $Json.exception.errors.reason
    
    # Add lines to $Array
    $Array += $ErrorLine
    
    Return $Array
}

#endregion Errors code

#region Airties

# Depreciated
function Get-Airties {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $Airties = New-Object -TypeName PSObject
    $Airties | Add-Member -Name "Agent Status"                    -MemberType Noteproperty -Value $(Get-Status -Status $Json.agent.enable)
    $Airties | Add-Member -Name "Band Steering Status"            -MemberType Noteproperty -Value $(Get-Status -Status $Json.bandsteering.enable)
    $Airties | Add-Member -Name "Mesh Steering Status"            -MemberType Noteproperty -Value $(Get-Status -Status $Json.meshsteering.enable)
    $Airties | Add-Member -Name "Remote Manager Status"           -MemberType Noteproperty -Value $(Get-Status -Status $Json.remotemanager.enable)
    $Airties | Add-Member -Name "CACS Status"                     -MemberType Noteproperty -Value $(Get-Status -Status $Json.cacs.enable)
    $Airties | Add-Member -Name "Live View Status"                -MemberType Noteproperty -Value $(Get-Status -Status $Json.liveview.enable)
    $Airties | Add-Member -Name "Zero Touch Status"               -MemberType Noteproperty -Value $(Get-Status -Status $Json.zerotouch.enable) # New Since version : 20.2.16
    $Airties | Add-Member -Name "Device Serial Number"            -MemberType Noteproperty -Value $Json.device.serialnumber
    $Airties | Add-Member -Name "Device Firmware Main Version"    -MemberType Noteproperty -Value $Json.device.main.version
    $Airties | Add-Member -Name "Device Firmware Main Date"       -MemberType Noteproperty -Value $(Format-Date -String $Json.device.main.date)
    $Airties | Add-Member -Name "Device Firmware Running Version" -MemberType Noteproperty -Value $Json.device.running.version
    $Airties | Add-Member -Name "Device Firmware Running date"    -MemberType Noteproperty -Value $(Format-Date -String $Json.device.running.date)
    $Airties | Add-Member -Name "IP Address"                      -MemberType Noteproperty -Value $Json.lanmode.ip
    $Airties | Add-Member -Name "IP Lan Address"                  -MemberType Noteproperty -Value $Json.lanmode.iplan

    # Add lines to $Array
    $Array += $Airties
    
    Return $Array
}

function Get-AirtiesLANmode {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.airties.lanmode
    
    # Create New PSObject and add values to array
    $LANMode = New-Object -TypeName PSObject
    $LANMode | Add-Member -Name "Service" -MemberType Noteproperty -Value "Airties - LAN Mode"
    $LANMode | Add-Member -Name "State"   -MemberType Noteproperty -Value $(Get-Status -Status $Json.enable)

    # Add lines to $Array
    $Array += $LANMode
    
    Return $Array
}

#endregion Airties

#region API Ressources Map

Function Get-APIRessourcesMap {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.apis
    
    $API = 0
    
    While($API -lt ($Json.Count)){
        
        # If Method is only PUT (Set) or POST (Modify)
        If($Json[$API].method -notlike "GET"){             
                
            $Params = 0
            
            While($Params -lt $Json[$API].params.count){
                
                # Create New PSObject and add values to array    
                $APILine = New-Object -TypeName PSObject
                $APILine | Add-Member -Name "API name"           -MemberType Noteproperty -Value "api/$(($Json[$API]).api)"
                $APILine | Add-Member -Name "API url"            -MemberType Noteproperty -Value "$UrlRoot/api/$(($Json[$API]).api)"
                $APILine | Add-Member -Name "Action"             -MemberType Noteproperty -Value ($Json[$API]).method
                $APILine | Add-Member -Name "Local permissions"  -MemberType Noteproperty -Value ($Json[$API]).permission.local
                $APILine | Add-Member -Name "Remote permissions" -MemberType Noteproperty -Value ($Json[$API]).permission.remote
                $APILine | Add-Member -Name "CSRFP"              -MemberType Noteproperty -Value (Get-Status -Status $(($Json[$API]).permission.csrfp))
                $APILine | Add-Member -Name "CDC"                -MemberType Noteproperty -Value (Get-Status -Status $(($Json[$API]).permission.cdc))
                $APILine | Add-Member -Name "Scope"              -MemberType Noteproperty -Value ($Json[$API]).permission.scope
                
                # Add new colomns for settings
                $APILine | Add-Member -Name "Settings"           -MemberType Noteproperty -Value "Yes"
                $APILine | Add-Member -Name "Name"               -MemberType Noteproperty -Value ($Json[$API]).params[$Params].name
                $APILine | Add-Member -Name "Is optionnal ?"     -MemberType Noteproperty -Value (Get-Status -Status $(($Json[$API]).params[$Params].optional))
                $APILine | Add-Member -Name "Type"               -MemberType Noteproperty -Value ($Json[$API]).params[$Params].type
                $APILine | Add-Member -Name "Minimal value"      -MemberType Noteproperty -Value ($Json[$API]).params[$Params].range.min
                $APILine | Add-Member -Name "Maximal value"      -MemberType Noteproperty -Value ($Json[$API]).params[$Params].range.max
                
                # Add lines to $Array
                $Array += $APILine
                    
                # Go to next line
                $Params ++
            }
        }
        
        # If Method is only GET (read)
        Else{
            $APILine = New-Object -TypeName PSObject
            $APILine | Add-Member -Name "API name"           -MemberType Noteproperty -Value "api/$(($Json[$API]).api)"
            $APILine | Add-Member -Name "API url"            -MemberType Noteproperty -Value "$UrlRoot/api/$(($Json[$API]).api)"
            $APILine | Add-Member -Name "Action"             -MemberType Noteproperty -Value ($Json[$API]).method
            $APILine | Add-Member -Name "Local permissions"  -MemberType Noteproperty -Value ($Json[$API]).permission.local
            $APILine | Add-Member -Name "Remote permissions" -MemberType Noteproperty -Value ($Json[$API]).permission.remote
            $APILine | Add-Member -Name "CSRFP"              -MemberType Noteproperty -Value (Get-Status -Status $(($Json[$API]).permission.csrfp))
            $APILine | Add-Member -Name "CDC"                -MemberType Noteproperty -Value (Get-Status -Status $(($Json[$API]).permission.cdc))
            $APILine | Add-Member -Name "Scope"              -MemberType Noteproperty -Value ($Json[$API]).permission.scope
            
            # Add new colomns for settings and set them to ""
            $APILine | Add-Member -Name "Settings"           -MemberType Noteproperty -Value "No"
            $APILine | Add-Member -Name "Name"               -MemberType Noteproperty -Value ""
            $APILine | Add-Member -Name "Is optionnal ?"     -MemberType Noteproperty -Value ""
            $APILine | Add-Member -Name "Type"               -MemberType Noteproperty -Value ""
            $APILine | Add-Member -Name "Minimal value"      -MemberType Noteproperty -Value ""
            $APILine | Add-Member -Name "Maximal value"      -MemberType Noteproperty -Value ""
            
            # Add lines to $Array
            $Array += $APILine
        }
        
        # Go to next line
        $API ++
    }
    
    Return $Array
}

#endregion API Ressources Map

#region BACKUP

Function Get-BackupList {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
        
    # Check if there local BBox configurations save
    If($Json.Count -ne "0"){
        
        $Config = 0
        
        While($Config -lt $Json.count){
            
            # Create New PSObject and add values to array
            $ConfigLine = New-Object -TypeName PSObject
            $ConfigLine | Add-Member -Name "ID"                      -MemberType Noteproperty -Value $Json[$Config].id
            $ConfigLine | Add-Member -Name "Backup Name"             -MemberType Noteproperty -Value $Json[$Config].name
            $ConfigLine | Add-Member -Name "Backup Creation Date"    -MemberType Noteproperty -Value $(Format-Date -String $Json[$Config].date)
            $ConfigLine | Add-Member -Name "Backup Firmware Version" -MemberType Noteproperty -Value $Json[$Config].firmware
            
            # Add lines to $Array
            $Array += $ConfigLine
            
            # Go to next line
            $Config ++
        }
        
        Return $Array
    }
    # Check if BBox Cloud Synchronisation Service is Active and if user allow it
    Else{
        Write-Log -Type WARNING -Name "Program run - Get BBOX Configuration Save" -Message "No local backups of the BBox configuration were found."
        $APIName = "usersave"
        $UrlToGo = $UrlToGo.Replace("configs","$APIName")
        $CloudSynchronisationState = Get-BBoxInformation -UrlToGo $UrlToGo
        
        Write-Log -Type INFONO -Name "Program run - Get BBOX Configuration Save" -Message "Checking BBox cloud save synchronisation state : "
        Write-Log -Type VALUE -Name "Program run - Get BBOX Configuration Save" -Message "$(Get-State -State $CloudSynchronisationState.$APIName.enable)"
        
        Write-Log -Type INFONO -Name "Program run - Get BBOX Configuration Save" -Message "Checking BBox cloud save synchronisation status : "
        Write-Log -Type VALUE -Name "Program run - Get BBOX Configuration Save" -Message "$(Get-Status -Status $CloudSynchronisationState.$APIName.status)"
        
        Write-Log -Type INFONO -Name "Program run - Get BBOX Configuration Save" -Message "Checking BBox cloud save synchronisation User authorization : "
        Write-Log -Type VALUE -Name "Program run - Get BBOX Configuration Save" -Message "$(Get-YesNoAsk -YesNoAsk $CloudSynchronisationState.$APIName.authorized)"
        
        Write-Log -Type INFONO -Name "Program run - Get BBOX Configuration Save" -Message "Last Time BBox Configuration save to the cloud : "
        Write-Log -Type VALUE -Name "Program run - Get BBOX Configuration Save" -Message "$($CloudSynchronisationState.$APIName.datelastsave)"
        
        Return $null
    }
}

#endregion BACKUP

#region USERSAVE

Function Get-USERSAVE {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $UsersaveLine = New-Object -TypeName PSObject
    $UsersaveLine | Add-Member -Name "Service"              -MemberType Noteproperty -Value $APIName
    $UsersaveLine | Add-Member -Name "State"                -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $UsersaveLine | Add-Member -Name "Status"               -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $UsersaveLine | Add-Member -Name "Boots's Number"       -MemberType Noteproperty -Value $Json.numberofboots # Since Version : 19.2.12
    $UsersaveLine | Add-Member -Name "Last Restore date"    -MemberType Noteproperty -Value $Json.datelastrestore
    $UsersaveLine | Add-Member -Name "Last Date Save"       -MemberType Noteproperty -Value $Json.datelastsave
    $UsersaveLine | Add-Member -Name "Restore From Factory" -MemberType Noteproperty -Value $Json.restorefromfactory
    $UsersaveLine | Add-Member -Name "Delay"                -MemberType Noteproperty -Value $Json.delay
    $UsersaveLine | Add-Member -Name "Allow Cloud Sync ?"   -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.authorized) # Since Version : 19.2.12
    $UsersaveLine | Add-Member -Name "Never Synced ?"       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.neversynced) # Since Version : 19.2.12
    
    # Add lines to $Array
    $Array += $UsersaveLine
    
    Return $Array
}

#endregion USERSAVE

#region CPL

Function Get-CPL {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $CPLLine = New-Object -TypeName PSObject
    $CPLLine | Add-Member -Name "Service"       -MemberType Noteproperty -Value $APIName
    $CPLLine | Add-Member -Name "Is detected ?" -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.running)
    
    # Add lines to $Array
    $Array += $CPLLine
    
    Return $Array
}

Function Get-CPLDeviceList {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    If($Json.$APIName.count -ne 0){
        
        $Id = 0
        While($Id -ne $Json.$APIName.count){
            # Create New PSObject and add values to array
            $CPLLine = New-Object -TypeName PSObject
            $CPLLine | Add-Member -Name "Master ID"                -MemberType Noteproperty -Value $Json[$Id].list.id
            $CPLLine | Add-Member -Name "Master MACAddress"        -MemberType Noteproperty -Value $Json[$Id].list.macaddress
            $CPLLine | Add-Member -Name "Master Manufacturer"      -MemberType Noteproperty -Value $Json[$Id].list.manufacturer
            $CPLLine | Add-Member -Name "Master Speed"             -MemberType Noteproperty -Value $Json[$Id].list.speed
            $CPLLine | Add-Member -Name "Master Chipset"           -MemberType Noteproperty -Value $Json[$Id].list.chipset
            $CPLLine | Add-Member -Name "Master Version"           -MemberType Noteproperty -Value $Json[$Id].list.version
            $CPLLine | Add-Member -Name "Master Port"              -MemberType Noteproperty -Value $Json[$Id].list.port
            
            If(-not ([string]::IsNullOrEmpty($Json[$Id].list.active))){
                $CPLLine | Add-Member -Name "Master State"         -MemberType Noteproperty -Value (Get-State -State $Json[$Id].list.active)
                $CPLLine | Add-Member -Name "Plug State"           -MemberType Noteproperty -Value (Get-State -State $Json[$Id].list.associateddevice.active)
            }
            Else{$CPLLine | Add-Member -Name "Master State"        -MemberType Noteproperty -Value ""
                 $CPLLine | Add-Member -Name "Plug State"          -MemberType Noteproperty -Value ""
            }
            
            $CPLLine | Add-Member -Name "Plug MAC Address"         -MemberType Noteproperty -Value $Json[$Id].list.associateddevice.macaddress
            $CPLLine | Add-Member -Name "Plug Manufacturer"        -MemberType Noteproperty -Value $Json[$Id].list.associateddevice.manufacturer
            $CPLLine | Add-Member -Name "Plug Chipset"             -MemberType Noteproperty -Value $Json[$Id].list.associateddevice.chipset
            $CPLLine | Add-Member -Name "Plug Speed"               -MemberType Noteproperty -Value $Json[$Id].list.associateddevice.speed
            $CPLLine | Add-Member -Name "Plug Version"             -MemberType Noteproperty -Value $Json[$Id].list.associateddevice.version
            $CPLLine | Add-Member -Name "End Stations MAC Address" -MemberType Noteproperty -Value $Json[$Id].list.endstations.macaddress
            
            # Add lines to $Array
            $Array += $CPLLine
                
            # Go to next line
            $Id++
        }
        Return $Array
    }
    Else{
        Return $null
    }
}

#endregion CPL

#region DEVICE

Function Get-Device {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    If(-not ([string]::IsNullOrEmpty($Json.temperature.status))){$TemperatureStatus = Get-Status -Status $Json.temperature.status}
    Else{$TemperatureStatus = ""}
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name "Date"                      -MemberType Noteproperty -Value $(Format-Date -String $Json.now)
    $DeviceLine | Add-Member -Name "Status"                    -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $DeviceLine | Add-Member -Name "Nb Boots since 1st use"    -MemberType Noteproperty -Value $Json.numberofboots
    $DeviceLine | Add-Member -Name "Bbox Model"                -MemberType Noteproperty -Value $Json.modelname
    $DeviceLine | Add-Member -Name "Is GUI password is set ?"  -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.user_configured)
    $DeviceLine | Add-Member -Name "Wifi Optimisation Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.optimisation)
    $DeviceLine | Add-Member -Name "Serial Number"             -MemberType Noteproperty -Value $Json.serialnumber
    $DeviceLine | Add-Member -Name "Current Temperature (°C)"  -MemberType Noteproperty -Value $Json.temperature.current
    $DeviceLine | Add-Member -Name "Temperature Status"        -MemberType Noteproperty -Value $TemperatureStatus
    $DeviceLine | Add-Member -Name "Display Orientation (°)"   -MemberType Noteproperty -Value $Json.display.orientation
    $DeviceLine | Add-Member -Name "Luminosity Grade (%) "     -MemberType Noteproperty -Value $Json.display.luminosity
    $DeviceLine | Add-Member -Name "Front Screen Displayed"    -MemberType Noteproperty -Value $Json.display.state
    $DeviceLine | Add-Member -Name "MAIN Firmware Version"     -MemberType Noteproperty -Value $Json.main.version
    $DeviceLine | Add-Member -Name "MAIN Firmware Date"        -MemberType Noteproperty -Value $(Format-Date -String $Json.main.date)
    $DeviceLine | Add-Member -Name "RECOVERY Firmware Version" -MemberType Noteproperty -Value $Json.reco.version
    $DeviceLine | Add-Member -Name "RECOVERY Firmware Date"    -MemberType Noteproperty -Value $(Format-Date -String $Json.reco.date)
    $DeviceLine | Add-Member -Name "RUNNING Firmware Version"  -MemberType Noteproperty -Value $Json.running.version                     # Missing in online documentation : https://api.bbox.fr/doc/apirouter/index.html
    $DeviceLine | Add-Member -Name "RUNNING Firmware Date"     -MemberType Noteproperty -Value $(Format-Date -String $Json.running.date) # Missing in online documentation : https://api.bbox.fr/doc/apirouter/index.html
    $DeviceLine | Add-Member -Name "BACKUP Version"            -MemberType Noteproperty -Value $Json.bcck.version
    $DeviceLine | Add-Member -Name "BOOTLOADER 1 Version"      -MemberType Noteproperty -Value $Json.ldr1.version
    $DeviceLine | Add-Member -Name "BOOTLOADER 2 Version"      -MemberType Noteproperty -Value $Json.ldr2.version
    $DeviceLine | Add-Member -Name "First use date"            -MemberType Noteproperty -Value $(Format-Date -String $Json.firstusedate)
    $DeviceLine | Add-Member -Name "Last boot Time"            -MemberType Noteproperty -Value (Get-Date).AddSeconds(- $Json.uptime)
    $DeviceLine | Add-Member -Name "IPV4 Status"               -MemberType Noteproperty -Value (Get-Status -Status $Json.using.ipv4)
    $DeviceLine | Add-Member -Name "IPV6 Status"               -MemberType Noteproperty -Value (Get-Status -Status $Json.using.ipv6)
    $DeviceLine | Add-Member -Name "FTTH Status"               -MemberType Noteproperty -Value (Get-Status -Status $Json.using.ftth)
    $DeviceLine | Add-Member -Name "ADSL Status"               -MemberType Noteproperty -Value (Get-Status -Status $Json.using.adsl)
    $DeviceLine | Add-Member -Name "VDSL Status"               -MemberType Noteproperty -Value (Get-Status -Status $Json.using.vdsl)
    
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

Function Get-DeviceLog {

    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.log
    
    $log = 0
    $ID = 0
    
    While($log -lt $Json.count){
        
        $Date = $(Format-Date -String $Json[$log].date)
        
        If ((-not (([string]::IsNullOrEmpty($Json[$log].param)))) -and ($Json[$log].param -match ";" )){
            
            $Params = ($Json[$log].param).split(";")
        }
        
        Switch($Json[$log].log){
            
            CONNTRACK_ERROR            {$Details = "Le nombre de sessions IP est trop élevé : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            CONNTRACK_OK               {$Details = "Le nombre de sessions IP est redevenu normal : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DHCP_POOL_OK               {$Details = "Le dimensionnement de plage DHCP est redevenu suffisant : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            DHCP_POOL_TOO_SMALL        {$Details = "Le dimensionnement de plage DHCP est trop petit : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            MEMORY_ERROR               {$Details = "Le taux d'utilisation de la mémoire est trop élevé : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            MEMORY_OK                  {$Details = "Le taux d'utilisation de la mémoire est redevenu normal : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }            
            
            DEVICE_NEW                 {$Details = "Un nouveau périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) à été ajouté sur le réseau"
                                        $LogType = "Périphérique"
                                       }
            
            DEVICE_UP                  {$Details = "Connexion du périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) sur le réseau"
                                        $LogType = "Périphérique"
                                       }
            
            DEVICE_DOWN                {$Details = "Déconnexion du périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) sur le réseau"
                                        $LogType = "Périphérique"
                                       }
            
            DHCLIENT_ACK               {$Details = "Assignation d'une adresse IP : $($Json[$log].param)"
                                        $LogType = "Réseau"
                                       }
            
            DHCLIENT_REQUEST           {$Details = "Réception d'une requête de la part d'un client : $($Json[$log].param)"
                                        $LogType = "Réseau"
                                       }
            
            DHCLIENT_DISCOVER          {$Details = "Envoie d'une requête en brodcast : $($Json[$log].param)"
                                        $LogType = "Réseau"
                                       }
            
            DIAG_DNS_FAILURE           {$Details = "Echec des tests d'autodiagnostic DNS : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DIAG_DNS_SUCCESS           {$Details = "Tests d'autodiagnostic DNS réussis : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DIAG_HTTP_FAILURE          {$Details = "Echec des tests d'autodiagnostic HTTP : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DIAG_HTTP_SUCCESS          {$Details = "Tests d'autodiagnostic HTTP réussis : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DIAG_PING_FAILURE          {$Details = "Echec des tests d'autodiagnostic PING : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DIAG_PING_SUCCESS          {$Details = "Tests d'autodiagnostic PING réussis : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DIAG_TIMEOUT               {$Details = "Tests d'autodiagnostic d'accès Internet expirés : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DIAG_FAILURE               {$Details = "Echec des tests d'autodiagnostic d'accès Internet : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DIAG_SUCCESS               {$Details = "Diagnostic réalisé avec succès : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DISPLAY_STATE              {$Details = "Changement d'Ã©tat de la Bbox : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            DSL_DOWN                   {$Details = "Ligne DSL désynchronisée : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DSL_EXCHANGE               {$Details = "Synchronisation DSL en cours : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            DSL_UP                     {$Details = "Signal DSL acquis. EN Attente d'obtention de l'adresse IP publique : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            LAN_OFFLINE_IP             {$Details = "IP Address Source : $($Params[0]), Hostaname : $($Params[2]), IP Address destination : $($Params[1])"
                                        $LogType = "Réseau"
                                       }
            
            LAN_PORT_UP                {$Details = "Un ou plusieurs équipements ont été connecté sur le port : $($Json[$log].param) du switch de la box"
                                        $LogType = "Réseau"
                                       }
            
            LAN_PORT_DOWN              {$Details = "Plus aucun équipement n'est connecté sur le port : $($Json[$log].param) du switch de la box"
                                        $LogType = "Réseau"
                                       }
            
            LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Hostname : $($Params[2]), IP Address in conflit : $($Params[1])"
                                        $LogType = "Réseau"
                                       }
            
            LOGIN_LOCAL                {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0])"
                                        $LogType = "Administration"
                                       }
            
            LOGIN_LOCAL_FAILED         {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a échoué"
                                        $LogType = "Administration"
                                       }
            
            LOGIN_LOCAL_LOCKED         {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a été bloqué"
                                        $LogType = "Administration"
                                       }
            
            LOGIN_REMOTE               {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0])"
                                        $LogType = "Administration"
                                       }
            
            LOGIN_REMOTE_FAILED        {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a échoué"
                                        $LogType = "Administration"
                                       }
            
            LOGIN_REMOTE_LOCKED        {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a été bloqué"
                                        $LogType = "Administration"
                                       }
            
            LOGIN_CDC                  {$Details = "Accès distant à l'interface d'administration par le service client Bouygues Telecom depuis l'adresse IP : $($Params[0])"
                                        $LogType = "Administration"
                                       }
            
            USER_CHANGEPWD             {$Details = "Changement du mot de passe d'administration de la BBOX : $($Json[$log].param))"
                                        $LogType = "Réseau local"
                                       }
            
            MAIL_ERROR                 {$Details = "Erreur lors de l'envoi d'un e-mail de notification à l'adresse mail : $($Json[$log].param)"
                                        $LogType = "Notification"
                                       }
            
            MAIL_SENT                  {$Details = "Envoi d'un e-mail de notification à l'adresse mail : $($Json[$log].param)"
                                        $LogType = "Notification"
                                       }
            
            NTP_SYNCHRONIZATION        {$Details = "L'heure et la date ont été obtenues - Synchronisation du temps : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            VOIP_DIAG_ECHOTEST_OFF     {$Details = "Test d'écho arrêté : $($Json[$log].param)"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_DIAG_ECHOTEST_ON      {$Details = "Test d'écho démarré : $($Json[$log].param)"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_DIAG_RINGTEST_OFF     {$Details = "Test de sonnerie arrêté : $($Json[$log].param)"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_DIAG_RINGTEST_ON      {$Details = "Test de sonnerie démarré : $($Json[$log].param)"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_INCOMING_CALL_RINGING {$Details = "Appel en cours du $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_INCOMING_CALL_MISSED  {$Details = "Appel entrant manqué du $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_INCOMING_CALL_START   {$Details = "Communication entrante en cours avec le $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_INCOMING_CALL_END     {$Details = "Communication entrante terminée avec le $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_OUTGOING_CALL_START   {$Details = "Communication sortante en cours avec le $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_OUTGOING_CALL_END     {$Details = "Communication entrante terminée avec le $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_MWI                   {$Details = "Il y a : $($Params[1]) message(s) vocal/aux sur la ligne : $($Params[0])"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_ONHOOK                {$Details = "Téléphone raccroché sur la ligne $(Get-Phoneline -Phoneline $Json[$log].param)"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_OFFHOOK               {$Details = "Téléphone décroché sur la ligne $(Get-Phoneline -Phoneline $Json[$log].param)"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_REGISTERED            {$Details = "La ligne téléphonique est active : $($Json[$log].param)"
                                        $LogType = "Téléphonie"
                                       }
            
            VOIP_UNREGISTERED          {$Details = "La ligne téléphonique n'est pas active : $($Json[$log].param)"
                                        $LogType = "Téléphonie"
                                       }
            
            WAN_DOWN                   {$Details = "Accès Internet indisponible : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            WAN_UP                     {$Details = "Accès Internet disponible : $($Json[$log].param)"
                                        $LogType = "Internet"
                                       }
            
            WAN_ROUTE_ADDED            {$Details = "Ajout nouvelle règle de routage sur l'adresse MAC : $($Params[0])"
                                        $LogType = "Internet"
                                       }
            
            WAN_ROUTE_REMOVED          {$Details = "Suppression règle de routage sur l'adresse MAC : $($Params[0])"
                                        $LogType = "Internet"
                                       }
            
            WAN_UPNP_ADD               {$Details = "Ajout d'une règle NAT sur le port externe : $($Params[2]) vers l'adresse IP : $($Params[0]) sur le port local : $($Params[1]) via UPnPIP "
                                        $LogType = "Utilisation du réseau"
                                       }
            
            WAN_UPNP_REMOVE            {$Details = "Suppression de la règle NAT du port externe $($Params[1]) vers l'adresse IP : $($Params[0]) via UPnPIP"
                                        $LogType = "Utilisation du réseau"
                                       }
            
            WIFI_UP                    {$Details = "Wifi activé : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            WIFI_DOWN                  {$Details = "Wifi désactivé : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            WIFI_SSID_24               {$Details = "Changement de nom du réseau Wi-Fi 2.4 GHz : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            WIFI_SSID_5                {$Details = "Changement de nom du réseau Wi-Fi 5 GHz : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            WIFI_PWD_24                {$Details = "Changement du mot de passe Wi-Fi 2.4 GHz : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            WIFI_PWD_5                 {$Details = "Changement du mot de passe Wi-Fi 5 GHz : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            PPP_BOUND                  {$Details = "Obtention d'adresse IP via PPP : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            SCHEDULER_PARENTAL_DISABLE{$Details = "Contrôle d'accès désactivé : $($Json[$log].param)"
                                        $LogType = "Utilisation du réseau"
                                       }
            
            SCHEDULER_PARENTAL_ENABLE  {$Details = "Contrôle d'accès activé : $($Json[$log].param)"
                                        $LogType = "Utilisation du réseau"
                                       }
            
            SCHEDULER_PARENTAL_RUNNING {$Details = "Contrôle d'accès e cours : $($Json[$log].param)"
                                        $LogType = "Utilisation du réseau"
                                       }
            
            SCHEDULER_PARENTAL_STOPPING{$Details = "Contrôle d'accès arrêté : $($Json[$log].param)"
                                        $LogType = "Utilisation du réseau"
                                       }
            
            SCHEDULER_WIFI_DISABLE     {$Details = "Gestion des plages horaires Wi-Fi désactivé : $($Json[$log].param)"
                                        $LogType = "Utilisation du réseau"
                                       }
            
            SCHEDULER_WIFI_ENABLE      {$Details = "Gestion des plages horaires Wi-Fi activée : $($Json[$log].param)"
                                        $LogType = "Utilisation du réseau"
                                       }
            
            UPGRADE_MAIN_FINISH        {$Details = "Mise à jour du logiciel de la Bbox réussie (firmware opérationnel) : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            UPGRADE_MAIN_FINISH_FAILED {$Details = "Echec de la mise à jour du logiciel de la Bbox (firmware opérationnel) : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            UPGRADE_START              {$Details = "Mise à jour du logiciel de la Bbox en cours (firmware opérationnel) : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            USB_PRINTER_PLUG           {$Details = "Connexion d'une imprimante USB : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            USB_PRINTER_UNPLUG         {$Details = "Déconnexion d'une imprimante USB : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            USB_STORAGE_MOUNT          {$Details = "Partition d'une clé ou d'un disque USB montée : $($Params[0]) sur le port USB : $($Params[1])"
                                        $LogType = "Système"
                                       }
            
            USB_STORAGE_MOUNT_RW       {$Details = "Droits de lecture et écriture sur la partition : $($Params[0]) sur le port USB : $($Params[1])"
                                        $LogType = "Système"
                                       }
            
            USB_STORAGE_PLUG           {$Details = "Branchement d'un périphérique de stockage USB : $($Params[0]) ayant pour désignation : $($Params[1])"
                                        $LogType = "Système"
                                       }
            
            USB_STORAGE_UMOUNT         {$Details = "Partition d'une clé ou d'un disque USB démontée : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            USB_STORAGE_UNPLUG         {$Details = "Déconnexion d'un périphérique de stockage USB : $($Json[$log].param)"
                                        $LogType = "Système"
                                       }
            
            Default                    {$Details = $Json[$log].param
                                        $LogType = "Unknow / Dev error"
                                       }
        }
        
        # Create New PSObject and add values to array
        $LogLine = New-Object -TypeName PSObject
        $LogLine | Add-Member -Name "ID"           -MemberType Noteproperty -Value $ID
        $LogLine | Add-Member -Name "Date"         -MemberType Noteproperty -Value $Date
        $LogLine | Add-Member -Name "Log type"     -MemberType Noteproperty -Value $LogType
        $LogLine | Add-Member -Name "Log Category" -MemberType Noteproperty -Value $Json[$log].log
        $LogLine | Add-Member -Name "Details"      -MemberType Noteproperty -Value $Details
        
        # Add lines to $Array
        $Array += $LogLine
        
        # Go to next line
        $log ++
        $ID ++
    }
    
    Return $Array
}

Function Get-DeviceFullLog {

    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    $Pageid = 1
    $ID = 0
    
    While($Json.exception.code -ne "404"){
        
        # Select $JSON header
        $Json = $Json.log
        
        $log = 0
        
        While($log -lt $Json.count){
            
            $Date = $(Format-Date -String $Json[$log].date)
            
            If ((-not (([string]::IsNullOrEmpty($Json[$log].param)))) -and ($Json[$log].param -match ";")){
                
                $Params = ($Json[$log].param).split(";")
            }
            
            Switch($Json[$log].log){
            
                CONNTRACK_ERROR            {$Details = "Le nombre de sessions IP est trop élevé : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                CONNTRACK_OK               {$Details = "Le nombre de sessions IP est redevenu normal : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DHCP_POOL_OK               {$Details = "Le dimensionnement de plage DHCP est redevenu suffisant : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                DHCP_POOL_TOO_SMALL        {$Details = "Le dimensionnement de plage DHCP est trop petit : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                MEMORY_ERROR               {$Details = "Le taux d'utilisation de la mémoire est trop élevé : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                MEMORY_OK                  {$Details = "Le taux d'utilisation de la mémoire est redevenu normal : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }            
            
                DEVICE_NEW                 {$Details = "Un nouveau périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) à été ajouté sur le réseau"
                                            $LogType = "Périphérique"
                                           }
            
                DEVICE_UP                  {$Details = "Connexion du périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) sur le réseau"
                                            $LogType = "Périphérique"
                                           }
            
                DEVICE_DOWN                {$Details = "Déconnexion du périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) sur le réseau"
                                            $LogType = "Périphérique"
                                           }
            
                DHCLIENT_ACK               {$Details = "Assignation d'une adresse IP : $($Json[$log].param)"
                                            $LogType = "Réseau"
                                           }
            
                DHCLIENT_REQUEST           {$Details = "Réception d'une requête de la part d'un client : $($Json[$log].param)"
                                            $LogType = "Réseau"
                                           }
            
                DHCLIENT_DISCOVER          {$Details = "Envoie d'une requête en brodcast : $($Json[$log].param)"
                                            $LogType = "Réseau"
                                           }
            
                DIAG_DNS_FAILURE           {$Details = "Echec des tests d'autodiagnostic DNS : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DIAG_DNS_SUCCESS           {$Details = "Tests d'autodiagnostic DNS réussis : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DIAG_HTTP_FAILURE          {$Details = "Echec des tests d'autodiagnostic HTTP : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DIAG_HTTP_SUCCESS          {$Details = "Tests d'autodiagnostic HTTP réussis : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DIAG_PING_FAILURE          {$Details = "Echec des tests d'autodiagnostic PING : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DIAG_PING_SUCCESS          {$Details = "Tests d'autodiagnostic PING réussis : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DIAG_TIMEOUT               {$Details = "Tests d'autodiagnostic d'accès Internet expirés : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DIAG_FAILURE               {$Details = "Echec des tests d'autodiagnostic d'accès Internet : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DIAG_SUCCESS               {$Details = "Diagnostic réalisé avec succès : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DISPLAY_STATE              {$Details = "Changement d'Ã©tat de la Bbox : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                DSL_DOWN                   {$Details = "Ligne DSL désynchronisée : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DSL_EXCHANGE               {$Details = "Synchronisation DSL en cours : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                DSL_UP                     {$Details = "Signal DSL acquis. EN Attente d'obtention de l'adresse IP publique : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                LAN_OFFLINE_IP             {$Details = "IP Address Source : $($Params[0]), Hostaname : $($Params[2]), IP Address destination : $($Params[1])"
                                            $LogType = "Réseau"
                                           }
            
                LAN_PORT_UP                {$Details = "Un ou plusieurs équipements ont été connecté sur l'un des ports du switch de la box. Status : $($Json[$log].param) $(Get-LanPortState -LanPortState $Json[$log].param)"
                                            $LogType = "Réseau"
                                           }
            
                LAN_PORT_DOWN              {$Details = "Un ou plusieurs équipements ont été déconnecté sur l'un des ports du switch de la box. Status : $($Json[$log].param) $(Get-LanPortState -LanPortState $Json[$log].param)"
                                            $LogType = "Réseau"
                                           }
            
                LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Hostname : $($Params[2]), IP Address in conflit : $($Params[1])"
                                            $LogType = "Réseau"
                                           }
            
                LOGIN_LOCAL                {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0])"
                                            $LogType = "Administration"
                                           }
            
                LOGIN_LOCAL_FAILED         {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a échoué"
                                            $LogType = "Administration"
                                           }
            
                LOGIN_LOCAL_LOCKED         {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a été bloqué"
                                            $LogType = "Administration"
                                           }
            
                LOGIN_REMOTE               {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0])"
                                            $LogType = "Administration"
                                           }
            
                LOGIN_REMOTE_FAILED        {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a échoué"
                                            $LogType = "Administration"
                                           }
            
                LOGIN_REMOTE_LOCKED        {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a été bloqué"
                                            $LogType = "Administration"
                                           }
            
                LOGIN_CDC                  {$Details = "Accès distant à l'interface d'administration par le service client Bouygues Telecom depuis l'adresse IP : $($Params[0])"
                                            $LogType = "Administration"
                                           }
            
                USER_CHANGEPWD             {$Details = "Changement du mot de passe d'administration de la BBOX : $($Json[$log].param))"
                                            $LogType = "Réseau local"
                                           }
            
                MAIL_ERROR                 {$Details = "Erreur lors de l'envoi d'un e-mail de notification à l'adresse mail : $($Json[$log].param)"
                                            $LogType = "Notification"
                                           }
            
                MAIL_SENT                  {$Details = "Envoi d'un e-mail de notification à l'adresse mail : $($Json[$log].param)"
                                            $LogType = "Notification"
                                           }
            
                NTP_SYNCHRONIZATION        {$Details = "L'heure et la date ont été obtenues - Synchronisation du temps : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                VOIP_DIAG_ECHOTEST_OFF     {$Details = "Test d'écho arrêté : $($Json[$log].param)"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_DIAG_ECHOTEST_ON      {$Details = "Test d'écho démarré : $($Json[$log].param)"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_DIAG_RINGTEST_OFF     {$Details = "Test de sonnerie arrêté : $($Json[$log].param)"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_DIAG_RINGTEST_ON      {$Details = "Test de sonnerie démarré : $($Json[$log].param)"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_INCOMING_CALL_RINGING {$Details = "Appel en cours du $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_INCOMING_CALL_MISSED  {$Details = "Appel entrant manqué du $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_INCOMING_CALL_START   {$Details = "Communication entrante en cours avec le $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_INCOMING_CALL_END     {$Details = "Communication entrante terminée avec le $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_OUTGOING_CALL_START   {$Details = "Communication sortante en cours avec le $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_OUTGOING_CALL_END     {$Details = "Communication entrante terminée avec le $($Params[1]) sur la ligne $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_MWI                   {$Details = "Il y a : $($Params[1]) message(s) vocal/aux sur la ligne : $($Params[0])"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_ONHOOK                {$Details = "Téléphone raccroché sur la ligne $(Get-Phoneline -Phoneline $Json[$log].param)"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_OFFHOOK               {$Details = "Téléphone décroché sur la ligne $(Get-Phoneline -Phoneline $Json[$log].param)"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_REGISTERED            {$Details = "La ligne téléphonique est active : $($Json[$log].param)"
                                            $LogType = "Téléphonie"
                                           }
            
                VOIP_UNREGISTERED          {$Details = "La ligne téléphonique n'est pas active : $($Json[$log].param)"
                                            $LogType = "Téléphonie"
                                           }
            
                WAN_DOWN                   {$Details = "Accès Internet indisponible : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                WAN_UP                     {$Details = "Accès Internet disponible : $($Json[$log].param)"
                                            $LogType = "Internet"
                                           }
            
                WAN_ROUTE_ADDED            {$Details = "Une nouvelle règle de routage a été ajouté sur l'adresse MAC : $($Params[0])"
                                            $LogType = "Internet"
                                           }
            
                WAN_ROUTE_REMOVED          {$Details = "Suppression de la règle de routage a été ajouté sur l'adresse MAC : $($Params[0])"
                                            $LogType = "Internet"
                                           }
            
                WAN_UPNP_ADD               {$Details = "Ajout d'une règle NAT sur le port externe : $($Params[2]) vers l'adresse IP : $($Params[0]) sur le port local : $($Params[1]) via UPnPIP "
                                            $LogType = "Utilisation du réseau"
                                           }
            
                WAN_UPNP_REMOVE            {$Details = "Suppression de la règle NAT du port externe $($Params[1]) vers l'adresse IP : $($Params[0]) via UPnPIP"
                                            $LogType = "Utilisation du réseau"
                                           }
            
                WIFI_UP                    {$Details = "Wifi activé : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                WIFI_DOWN                  {$Details = "Wifi désactivé : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                WIFI_SSID_24               {$Details = "Changement de nom du réseau Wi-Fi 2.4 GHz : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                WIFI_SSID_5                {$Details = "Changement de nom du réseau Wi-Fi 5 GHz : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                WIFI_PWD_24                {$Details = "Changement du mot de passe Wi-Fi 2.4 GHz : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                WIFI_PWD_5                 {$Details = "Changement du mot de passe Wi-Fi 5 GHz : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                PPP_BOUND                  {$Details = "Obtention d'adresse IP via PPP : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                SCHEDULER_PARENTAL_DISABLE{$Details = "Contrôle d'accès désactivé : $($Json[$log].param)"
                                            $LogType = "Utilisation du réseau"
                                           }
            
                SCHEDULER_PARENTAL_ENABLE  {$Details = "Contrôle d'accès activé : $($Json[$log].param)"
                                            $LogType = "Utilisation du réseau"
                                           }
            
                SCHEDULER_PARENTAL_RUNNING {$Details = "Contrôle d'accès e cours : $($Json[$log].param)"
                                            $LogType = "Utilisation du réseau"
                                           }
            
                SCHEDULER_PARENTAL_STOPPING{$Details = "Contrôle d'accès arrêté : $($Json[$log].param)"
                                            $LogType = "Utilisation du réseau"
                                           }
            
                SCHEDULER_WIFI_DISABLE     {$Details = "Gestion des plages horaires Wi-Fi désactivé : $($Json[$log].param)"
                                            $LogType = "Utilisation du réseau"
                                           }
            
                SCHEDULER_WIFI_ENABLE      {$Details = "Gestion des plages horaires Wi-Fi activée : $($Json[$log].param)"
                                            $LogType = "Utilisation du réseau"
                                           }
            
                UPGRADE_MAIN_FINISH        {$Details = "Mise à jour du logiciel de la Bbox réussie (firmware opérationnel) : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                UPGRADE_MAIN_FINISH_FAILED {$Details = "Echec de la mise à jour du logiciel de la Bbox (firmware opérationnel) : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                UPGRADE_START              {$Details = "Mise à jour du logiciel de la Bbox en cours (firmware opérationnel) : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                USB_PRINTER_PLUG           {$Details = "Connexion d'une imprimante USB : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                USB_PRINTER_UNPLUG         {$Details = "Déconnexion d'une imprimante USB : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                USB_STORAGE_MOUNT          {$Details = "Partition d'une clé ou d'un disque USB montée : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                USB_STORAGE_PLUG           {$Details = "Branchement d'un périphérique de stockage USB : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                USB_STORAGE_UMOUNT         {$Details = "Partition d'une clé ou d'un disque USB démontée : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                USB_STORAGE_UNPLUG         {$Details = "Déconnexion d'un périphérique de stockage USB : $($Json[$log].param)"
                                            $LogType = "Système"
                                           }
            
                Default                    {$Details = $Json[$log].param
                                            $LogType = "Unknow / Dev error"
                                           }
            }
            
            # Create New PSObject and add values to array
            $LogLine = New-Object -TypeName PSObject
            $LogLine | Add-Member -Name "ID"           -MemberType Noteproperty -Value $ID
            $LogLine | Add-Member -Name "Date"         -MemberType Noteproperty -Value $Date
            $LogLine | Add-Member -Name "Log type"     -MemberType Noteproperty -Value $LogType
            $LogLine | Add-Member -Name "Log Category" -MemberType Noteproperty -Value $Json[$log].log
            $LogLine | Add-Member -Name "Details"      -MemberType Noteproperty -Value $Details
            
            # Add lines to $Array
            $Array += $LogLine
            
            # Go to next line
            $log ++
            $ID ++
        }
        
        # Get the next page
        $Pageid ++
        
        # Get information from BBOX API
        $Json = Get-BBoxInformation -UrlToGo $UrlToGo/$Pageid
    }
    
    Return $Array
}

Function Get-DeviceFullTechnicalLog {

    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    $Pageid = 1
    $ID = 0
    
    While($Json.exception.code -ne "404"){
        
        # Select $JSON header
        $Json = $Json.log
        
        $log = 1
        
        While($log -lt $Json.count){
            
            $Date = $(Format-Date -String $Json[$log].date)
            
            If ((-not (([string]::IsNullOrEmpty($Json[$log].param)))) -and ($Json[$log].param -match ";")){
                
                $Params = ($Json[$log].param).split(";")
            }
            
            Switch($Json[$log].log){
                
                DEVICE_NEW                 {$Details = "Hostname : $($Params[2]), IP Address : $($Params[1]), MAC Address : $($Params[0])"}
                
                DEVICE_UP                  {$Details = "Hostname : $($Params[2]), IP Address : $($Params[1]), MAC Address : $($Params[0])"}
                
                DEVICE_DOWN                {$Details = "Hostname : $($Params[2]), IP Address : $($Params[1]), MAC Address : $($Params[0])"}
                
                DHCLIENT_ACK               {$Details = $Json[$log].param}
                
                DHCLIENT_REQUEST           {$Details = $Json[$log].param}
                
                DHCLIENT_DISCOVER          {$Details = $Json[$log].param}
                
                DIAG_FAILURE               {$Details = $Json[$log].param}
                
                DIAG_SUCCESS               {$Details = $Json[$log].param}
                
                DISPLAY_STATE              {$Details = $Json[$log].param}
                
                LAN_OFFLINE_IP             {$Details = "IP Address Source : $($Params[0]), Hostaname : $($Params[2]), IP Address destination : $($Params[1])"}
                
                LAN_PORT_UP                {$Details = "Bbox Switch Port : $($Json[$log].param)"}
                
                LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Hostname : $($Params[2]), IP Address in conflit : $($Params[1])"}
                
                LOGIN_LOCAL                {$Details = "Hostname : $($Params[1]), IP Address : $($Params[0])"}
                
                LOGIN_REMOTE               {$Details = "Hostname : $($Params[1]), IP Address : $($Params[0])"}
                
                LOGIN_CDC                  {$Details = "IP Address : $($Params[0])"}
                
                MAIL_ERROR                 {$Details = "Mail Address : $($Json[$log].param)"}
                
                MAIL_SENT                  {$Details = "Mail Address : $($Json[$log].param)"}
                
                NTP_SYNCHRONIZATION        {$Details = $Json[$log].param}
                
                VOIP_INCOMING_CALL_RINGING {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])"}
                
                VOIP_INCOMING_CALL_MISSED  {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])"}
                
                VOIP_INCOMING_CALL_START   {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])"}
                
                VOIP_INCOMING_CALL_END     {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])"}
                
                VOIP_OUTGOING_CALL_START   {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])"}
                
                VOIP_OUTGOING_CALL_END     {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])"}
                
                VOIP_MWI                   {$Details = "Voice Message on line : $($Params[1]), Unread Voice Message Number : $($Params[0])"}
                
                VOIP_ONHOOK                {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$log].param) is available"}
                
                VOIP_OFFHOOK               {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$log].param) is busy"}
                
                VOIP_REGISTERED            {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$log].param)"}
                
                VOIP_UNREGISTERED          {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$log].param)"}
                
                WAN_ROUTE_ADDED            {$Details = "MAC Address : $($Params[0])"}
                
                WAN_ROUTE_REMOVED          {$Details = "MAC Address : $($Params[0])"}
                
                WAN_UPNP_ADD               {$Details = "IP Address : $($Params[0]), Local Port : $($Params[1]), External Port : $($Params[2])"}
                
                WAN_UPNP_REMOVE            {$Details = "IP Address : $($Params[0]), External Port : $($Params[1])"}
                
                WIFI_UP                    {$Details = $Json[$log].param}
                
                WIFI_DOWN                  {$Details = $Json[$log].param}
                
                Default                    {$Details = $Json[$log].param}
                
            }
            
            # Create New PSObject and add values to array
            $LogLine = New-Object -TypeName PSObject
            $LogLine | Add-Member -Name "ID"           -MemberType Noteproperty -Value $ID
            $LogLine | Add-Member -Name "Date"         -MemberType Noteproperty -Value $Date
            $LogLine | Add-Member -Name "Log Category" -MemberType Noteproperty -Value $Json[$log].log
            $LogLine | Add-Member -Name "Details"      -MemberType Noteproperty -Value $Details
            
            # Add lines to $Array
            $Array += $LogLine
            
            # Go to next line
            $log ++
            $ID ++
        }
        
        # Get the next page
        $Pageid ++
        
        # Get information from BBOX API
        $Json = Get-BBoxInformation -UrlToGo $UrlToGo/$Pageid
    }
    
    Return $Array
}

Function Get-DeviceCpu {
    
    Param(
       [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].device.cpu
    
    # Create New PSObject and add values to array
    $LedLine = New-Object -TypeName PSObject
    $LedLine | Add-Member -Name "Total Time"        -MemberType Noteproperty -Value $Json.time.total
    $LedLine | Add-Member -Name "User Time"         -MemberType Noteproperty -Value $Json.time.user
    $LedLine | Add-Member -Name "Nice Time"         -MemberType Noteproperty -Value $Json.time.nice
    $LedLine | Add-Member -Name "System Time"       -MemberType Noteproperty -Value $Json.time.system
    $LedLine | Add-Member -Name "IO Time"           -MemberType Noteproperty -Value $Json.time.io
    $LedLine | Add-Member -Name "Idle Time"         -MemberType Noteproperty -Value $Json.time.idle
    $LedLine | Add-Member -Name "Irq Time"          -MemberType Noteproperty -Value $Json.time.irq
    $LedLine | Add-Member -Name "Created processus" -MemberType Noteproperty -Value $Json.process.created
    $LedLine | Add-Member -Name "Running processus" -MemberType Noteproperty -Value $Json.process.running
    $LedLine | Add-Member -Name "Blocked processus" -MemberType Noteproperty -Value $Json.process.blocked
    
    # Add lines to $Array
    $Array += $LedLine
    
    Return $Array
}

Function Get-DeviceMemory {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.device.mem
    
    # Create New PSObject and add values to array
    $MemoryLine = New-Object -TypeName PSObject
    $MemoryLine | Add-Member -Name "Total Memory"     -MemberType Noteproperty -Value $Json.total
    $MemoryLine | Add-Member -Name "Free Memory"      -MemberType Noteproperty -Value $Json.free
    $MemoryLine | Add-Member -Name "Cached Memory"    -MemberType Noteproperty -Value $Json.cached
    $MemoryLine | Add-Member -Name "Committed Memory" -MemberType Noteproperty -Value $Json.committedas
    
    # Add lines to $Array
    $Array += $MemoryLine
    
    Return $Array
}

Function Get-DeviceLED {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0]
    
    # Create New PSObject and add values to array
    
    # Led
    $LedLine = New-Object -TypeName PSObject
    $LedLine | Add-Member -Name "State Power Led"           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.power)
    $LedLine | Add-Member -Name "State Power Red Led"       -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.power_red)
    $LedLine | Add-Member -Name "State Power Green Led"     -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.power_green)
    $LedLine | Add-Member -Name "State Wifi Led"            -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.wifi)
    $LedLine | Add-Member -Name "State Wifi red Led"        -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.wifi_red)
    $LedLine | Add-Member -Name "State Phone 1 Led"         -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phone1)
    $LedLine | Add-Member -Name "State Phone 1 Red Led"     -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phone1_red)
    $LedLine | Add-Member -Name "State Phone 2 Led"         -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phone2)
    $LedLine | Add-Member -Name "State Phone 2 Red Led"     -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phone2_red)
    $LedLine | Add-Member -Name "State WAN Led"             -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.wan)
    $LedLine | Add-Member -Name "State WAN Red Led"         -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.wan_red)
    
    # Ethernet Switch Port LED State
    $LedLine | Add-Member -Name "State sw1_1 Led"           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw1_1)
    $LedLine | Add-Member -Name "State sw1_2 Led"           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw1_2)
    $LedLine | Add-Member -Name "State sw2_1 Led"           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw2_1)
    $LedLine | Add-Member -Name "State sw2_2 Led"           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw2_2)
    $LedLine | Add-Member -Name "State sw3_1 Led"           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw3_1)
    $LedLine | Add-Member -Name "State sw3_2 Led"           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw3_2)
    $LedLine | Add-Member -Name "State sw4_1 Led"           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw4_1)
    $LedLine | Add-Member -Name "State sw4_2 Led"           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw4_2)
    $LedLine | Add-Member -Name "State phy_1 Led"           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phy_1)
    $LedLine | Add-Member -Name "State phy_2 Led"           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phy_2)
    
    # Ethernet Switch LED State
    $LedLine | Add-Member -Name "State Ethernet port 1 Led" -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.ethernetPort[0].state)
    $LedLine | Add-Member -Name "State Ethernet port 2 Led" -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.ethernetPort[1].state)
    $LedLine | Add-Member -Name "State Ethernet port 3 Led" -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.ethernetPort[2].state)
    $LedLine | Add-Member -Name "State Ethernet port 4 Led" -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.ethernetPort[3].state)
    $LedLine | Add-Member -Name "State Ethernet port 5 Led" -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.ethernetPort[4].state)
    
    # Add lines to $Array
    $Array += $LedLine
    
    Return $Array
}

Function Get-DeviceSummary {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.device
    
    # Create New PSObject and add values to array
    $SummaryLine = New-Object -TypeName PSObject
    $SummaryLine | Add-Member -Name "Date"          -MemberType Noteproperty -Value $(Format-Date -String $Json.now)
    $SummaryLine | Add-Member -Name "Status"        -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $SummaryLine | Add-Member -Name "Default"       -MemberType Noteproperty -Value (Get-Status -Status $Json.default)
    $SummaryLine | Add-Member -Name "Model"         -MemberType Noteproperty -Value $Json.modelname
    $SummaryLine | Add-Member -Name "Serial Number" -MemberType Noteproperty -Value $Json.serialnumber
    
    # Add lines to $Array
    $Array += $SummaryLine
    
    Return $Array
}

Function Get-DeviceToken {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.device
    
    # Convert string value to date time 
    $Date = ((($Json.now.replace("T"," "))).replace("-","/")).replace("+0100","")
    $Date = [Datetime]::ParseExact($Date, 'yyyy/MM/dd HH:mm:ss', $null)
    $ExpirationDate = ((($Json.expires.replace("T"," "))).replace("-","/")).replace("+0100","")
    $ExpirationDate = [Datetime]::ParseExact($ExpirationDate, 'yyyy/MM/dd HH:mm:ss', $null)
    $TimeLeft = New-TimeSpan -Start $Date -End $ExpirationDate
    
    # Create New PSObject and add values to array
    $TokenLine = New-Object -TypeName PSObject
    $TokenLine | Add-Member -Name "Token"                 -MemberType Noteproperty -Value $Json.token
    $TokenLine | Add-Member -Name "Date"                  -MemberType Noteproperty -Value $Date
    $TokenLine | Add-Member -Name "Token Expiration Date" -MemberType Noteproperty -Value $ExpirationDate
    $TokenLine | Add-Member -Name "Token Valid Time Left" -MemberType Noteproperty -Value $TimeLeft

    # Add lines to $Array
    $Array += $TokenLine
    
    Return $Array
}

#endregion DEVICE

#region DHCP

Function Get-DHCP {
        
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $DHCP = New-Object -TypeName PSObject
    $DHCP | Add-Member -Name "State"                  -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $DHCP | Add-Member -Name "Status"                 -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $DHCP | Add-Member -Name "First Range IP Address" -MemberType Noteproperty -Value $Json.minaddress
    $DHCP | Add-Member -Name "Last Last IP Address"   -MemberType Noteproperty -Value $Json.maxaddress
    $DHCP | Add-Member -Name "Bail (Secondes)"        -MemberType Noteproperty -Value $Json.leasetime
    $DHCP | Add-Member -Name "Bail (Minutes)"         -MemberType Noteproperty -Value ($Json.leasetime / 60)
    $DHCP | Add-Member -Name "Bail (Hours)"           -MemberType Noteproperty -Value ($Json.leasetime / 3600)
    
    # Add lines to $Array
    $Array += $DHCP
    
    Return $Array
}

Function Get-DHCPClients {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.clients
            
    If($Json.Count -ne 0){
        
        $Client = 0
        
        While($Client -lt $Json.Count){
            
            $ClientName = New-Object -TypeName PSObject
            $ClientName | Add-Member -Name "ID"              -MemberType Noteproperty -Value $Json[$Client].ID
            $ClientName | Add-Member -Name "Device HostName" -MemberType Noteproperty -Value $Json[$Client].HostName
            $ClientName | Add-Member -Name "IPV4 Address"    -MemberType Noteproperty -Value $Json[$Client].IPAddress
            $ClientName | Add-Member -Name "IPV6 Address"    -MemberType Noteproperty -Value $Json[$Client].IP6Address
            $ClientName | Add-Member -Name "MACAddress"      -MemberType Noteproperty -Value $Json[$Client].MACAddress
            $ClientName | Add-Member -Name "State"           -MemberType Noteproperty -Value (Get-State -State $Json[$Client].enable)
            
            # Add lines to $Array
            $Array += $ClientName
            
            # Go to next line
            $Client ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-DHCPClientsID {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $DeviceIDs = Get-DHCPClients -UrlToGo $UrlToGo
    $DeviceID = $DeviceIDs | Select-Object ID,"Device HostName" | Out-GridView -Title "DHCP Client List" -OutputMode Single
    $Device = $DeviceIDs | Where-Object {$_.ID -ilike $DeviceID.id}
    
    Return $Device
}

Function Get-DHCPActiveOptions {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp
    
    # Add Static DHCP Options
    # Create New PSObject and add values to array 
    $OptionLine = New-Object -TypeName PSObject
    $OptionLine | Add-Member -Name "ID"     -MemberType Noteproperty -Value $Json.optionsstatic.id
    $OptionLine | Add-Member -Name "Option" -MemberType Noteproperty -Value $Json.optionsstatic.option
    $OptionLine | Add-Member -Name "Value"  -MemberType Noteproperty -Value $Json.optionsstatic.value
    $OptionLine | Add-Member -Name "Type"   -MemberType Noteproperty -Value "Static"
    
    $Array += $OptionLine
    
    # Add DYnamic DHCP Options
    
    If($Json.options.Count -ne 0){
        
        $Option = 0
        
        While($Option -lt $Json.options.Count){
            
            # Create New PSObject and add values to array
            $OptionLine = New-Object -TypeName PSObject
            $OptionLine | Add-Member -Name "ID"     -MemberType Noteproperty -Value $Json.options[$Option].id
            $OptionLine | Add-Member -Name "Option" -MemberType Noteproperty -Value $Json.options[$Option].option
            $OptionLine | Add-Member -Name "Value"  -MemberType Noteproperty -Value $Json.options[$Option].value
            $OptionLine | Add-Member -Name "Type"   -MemberType Noteproperty -Value "Dynamic"
            
            # Add lines to $Array
            $Array += $OptionLine
            
            # Go to next line
            $Option ++
        }
    }
    
    Return $Array
}

Function Get-DHCPOptions {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.optionscapabilities
    
    If($Json.Count -ne 0){
        
        $Option = 0
        
        While($Option -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $OptionLine = New-Object -TypeName PSObject
            $OptionLine | Add-Member -Name "ID"          -MemberType Noteproperty -Value $Json[$Option].ID
            $OptionLine | Add-Member -Name "Type"        -MemberType Noteproperty -Value $Json[$Option].Type
            $OptionLine | Add-Member -Name "Description" -MemberType Noteproperty -Value $Json[$Option].Description
            $OptionLine | Add-Member -Name "RFC"         -MemberType Noteproperty -Value $Json[$Option].RFC
            
            # Add lines to $Array
            $Array += $OptionLine
            
            # Go to next line
            $Option ++
        }
    
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-DHCPOptionsID {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $OptionIDs = Get-DHCPOptions -UrlToGo $UrlToGo
    $OptionID = $OptionIDs | Select-Object ID,Description | Out-GridView -Title "DHCP Capabilities Options" -OutputMode Single
    $Option = $OptionIDs | Where-Object {$_.ID -ilike $OptionID.id}
    
    Return $Option
}

Function Get-DHCPSTBOptions {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.options
    
    If($Json.count -ne 0){
        
        $Option = 0
        
        While($Option -lt $Json.count){
            
            # Create New PSObject and add values to array
            $OptionLine = New-Object -TypeName PSObject
            $OptionLine | Add-Member -Name "ID"     -MemberType Noteproperty -Value $Json[$Option].id
            $OptionLine | Add-Member -Name "Option" -MemberType Noteproperty -Value $Json[$Option].option
            
            # Add lines to $Array
            $Array += $OptionLine
            
            # Go to next line
            $Option ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

function Get-DHCPv6PrefixDelegation {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.prefixdelegation
    
    If($Json.Count -ne 0){
        
        $PrefixID = 0
        
        While($PrefixID -lt $Json.Count){
            
            $PrefixDelegationLine = New-Object -TypeName PSObject
            $PrefixDelegationLine | Add-Member -Name "ID"             -MemberType Noteproperty -Value $Json[$PrefixID].ID
            $PrefixDelegationLine | Add-Member -Name "State"          -MemberType Noteproperty -Value $(Get-Status -Status $Json[$PrefixID].enable)
            $PrefixDelegationLine | Add-Member -Name "Prefix Start"   -MemberType Noteproperty -Value $Json[$PrefixID].prefixstart
            $PrefixDelegationLine | Add-Member -Name "Prefix End"     -MemberType Noteproperty -Value $Json[$PrefixID].prefixend
            $PrefixDelegationLine | Add-Member -Name "Security Level" -MemberType Noteproperty -Value $Json[$PrefixID].securitylevel
            $PrefixDelegationLine | Add-Member -Name "MAC Address "   -MemberType Noteproperty -Value $Json[$PrefixID].macaddress
            $PrefixDelegationLine | Add-Member -Name "Type"           -MemberType Noteproperty -Value $Json[$PrefixID].type
            
            # Add lines to $Array
            $Array += $PrefixDelegationLine
            
            # Go to next line
            $PrefixID ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-DHCPv6Options {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.optionscapabilities
    
    If($Json.Count -ne 0){
        
        $Option = 0
        
        While($Option -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $OptionLine = New-Object -TypeName PSObject
            $OptionLine | Add-Member -Name "ID"          -MemberType Noteproperty -Value $Json[$Option].ID
            $OptionLine | Add-Member -Name "Type"        -MemberType Noteproperty -Value $Json[$Option].Type
            $OptionLine | Add-Member -Name "Description" -MemberType Noteproperty -Value $Json[$Option].Description
            $OptionLine | Add-Member -Name "RFC"         -MemberType Noteproperty -Value $Json[$Option].RFC
            
            # Add lines to $Array
            $Array += $OptionLine
            
            # Go to next line
            $Option ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

#endregion DHCP

#region DNS

Function Get-DNSStats {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dns
    
    # Create New PSObject and add values to array
    $NbQueriesTitle = "Nb Query between $((Get-Date).AddDays(-14)) and $(Get-Date)"
    
    $DnsStats = New-Object -TypeName PSObject
    $DnsStats | Add-Member -Name $NbQueriesTitle             -MemberType Noteproperty -Value $Json.nbqueries
    $DnsStats | Add-Member -Name "Answer Min Time (ms)"      -MemberType Noteproperty -Value $Json.min
    $DnsStats | Add-Member -Name "Answer Max Time (ms)"      -MemberType Noteproperty -Value $Json.max
    $DnsStats | Add-Member -Name "Answer Averrage Time (ms)" -MemberType Noteproperty -Value $Json.avg
    
    # Add lines to $Array
    $Array += $DnsStats
    
    Return $Array
}

#endregion DNS

#region DYNDNS

Function Get-DYNDNS {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $DyndnsLine = New-Object -TypeName PSObject
    $DyndnsLine | Add-Member -Name "Service"              -MemberType Noteproperty -Value 'DYNDNS'
    $DyndnsLine | Add-Member -Name "State"                -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $DyndnsLine | Add-Member -Name "Status"               -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $DyndnsLine | Add-Member -Name "Nb Configured domain" -MemberType Noteproperty -Value ($Json.domaincount)
    
    # Add lines to $Array
    $Array += $DyndnsLine
    
    Return $Array
}

Function Get-DYNDNSProviderList {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName.servercapabilities
    
    If($Json.count -ne 0){
    
    $Providers = 0
    
    While($Providers -lt $Json.count){
        
        # Create New PSObject and add values to array
        $ProviderLine = New-Object -TypeName PSObject
        $ProviderLine | Add-Member -Name "Provider"                        -MemberType Noteproperty -Value $Json[$Providers].name
        $ProviderLine | Add-Member -Name "Supported Protocols (IPv4/IPv6)" -MemberType Noteproperty -Value ($($Json[$Providers].Support) -join "/")
        $ProviderLine | Add-Member -Name "Web Site"                        -MemberType Noteproperty -Value $Json[$Providers].Site
        
        # Add lines to $Array
        $Array += $ProviderLine
        
        # Go to next line
        $Providers ++
    }
    
    Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-DYNDNSClient {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName.domain
    
    If($Json.count -ne "0"){
        
        $Provider = 0
        
        While($Provider -lt $Json.count){
            
            # Create New PSObject and add values to array
            $ProviderLine = New-Object -TypeName PSObject
            $ProviderLine | Add-Member -Name "ID"                  -MemberType Noteproperty -Value $Json[$Provider].id
            $ProviderLine | Add-Member -Name "Provider"            -MemberType Noteproperty -Value $Json[$Provider].server
            $ProviderLine | Add-Member -Name "State"               -MemberType Noteproperty -Value (Get-State -State $Json[$Provider].enable)
            $ProviderLine | Add-Member -Name "Username"            -MemberType Noteproperty -Value $Json[$Provider].username
            $ProviderLine | Add-Member -Name "Password"            -MemberType Noteproperty -Value $Json[$Provider].password
            $ProviderLine | Add-Member -Name "Host"                -MemberType Noteproperty -Value $Json[$Provider].host
            $ProviderLine | Add-Member -Name "Record Type"         -MemberType Noteproperty -Value $Json[$Provider].record
            $ProviderLine | Add-Member -Name "MAC Address"         -MemberType Noteproperty -Value $Json[$Provider].device
            $ProviderLine | Add-Member -Name "Date"                -MemberType Noteproperty -Value $(Format-Date -String $Json[$Provider].status.date)
            $ProviderLine | Add-Member -Name "Status"              -MemberType Noteproperty -Value $Json[$Provider].status.status
            $ProviderLine | Add-Member -Name "Message"             -MemberType Noteproperty -Value $Json[$Provider].status.message
            $ProviderLine | Add-Member -Name "IP Address"          -MemberType Noteproperty -Value $Json[$Provider].status.ip
            $ProviderLine | Add-Member -Name "Cache Date"          -MemberType Noteproperty -Value $(Format-Date -String $Json[$Provider].status.cache_date)
            $ProviderLine | Add-Member -Name "Periodic Update (H)" -MemberType Noteproperty -Value $Json[$Provider].periodicupdate
            
            $Array += $ProviderLine
            
            # Go to next line
            $Provider ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-DYNDNSClientID {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    $DyndnsIDs = Get-DYNDNSClient -UrlToGo $UrlToGo -APIName $APIName
    $DyndnsID = $DyndnsIDs | Select-Object ID,Provider,Host | Out-GridView -Title "DYNDNS Configuration List" -OutputMode Single
    $Dyndns = $DyndnsIDs | Where-Object {$_.ID -ilike $DyndnsID.id}
    
    Return $Dyndns
}

#endregion DNS

#region FIREWALL

Function Get-FIREWALL {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    $Firewall = New-Object -TypeName PSObject
    $Firewall | Add-Member -Name "Service"             -MemberType Noteproperty -Value $APIName
    $Firewall | Add-Member -Name "State"               -MemberType Noteproperty -Value $Json.state
    $Firewall | Add-Member -Name "Status"              -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $Firewall | Add-Member -Name "Supported Protocols" -MemberType Noteproperty -Value ($($Json.protoscapabilities) -join " , ")
    
    # Add lines to $Array
    $Array += $Firewall
    
    Return $Array
}

Function Get-FIREWALLRules {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.firewall.rules
    
    If($Json.Count -ne 0){
        
        $Rule = 0
        
        While($Rule -lt $Json.Count){
            
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name "ID"                             -MemberType Noteproperty -Value $Json[$Rule].ID
            $RuleLine | Add-Member -Name "Status"                         -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].enable)
            $RuleLine | Add-Member -Name "Description"                    -MemberType Noteproperty -Value $Json[$Rule].description
            $RuleLine | Add-Member -Name "Action"                         -MemberType Noteproperty -Value $Json[$Rule].action
            $RuleLine | Add-Member -Name "IP source is excluded ?"        -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcipnot)
            $RuleLine | Add-Member -Name "IP source (Range/IP)"           -MemberType Noteproperty -Value $Json[$Rule].srcip
            $RuleLine | Add-Member -Name "IP destination is excluded ?"   -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstipnot)
            $RuleLine | Add-Member -Name "IP destination (Range/IP)"      -MemberType Noteproperty -Value $Json[$Rule].dstip
            $RuleLine | Add-Member -Name "Port source is excluded ?"      -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcportnot)
            $RuleLine | Add-Member -Name "Port source (Range/Port)"       -MemberType Noteproperty -Value $Json[$Rule].srcports
            $RuleLine | Add-Member -Name "Port destination is excluded ?" -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstportnot)
            $RuleLine | Add-Member -Name "Port destination (Range/Port)"  -MemberType Noteproperty -Value $Json[$Rule].dstports
            $RuleLine | Add-Member -Name "Priority"                       -MemberType Noteproperty -Value $Json[$Rule].order
            $RuleLine | Add-Member -Name "TCP/UDP Protocols"              -MemberType Noteproperty -Value $Json[$Rule].protocols
            $RuleLine | Add-Member -Name "IP Protocols"                   -MemberType Noteproperty -Value $Json[$Rule].ipprotocol
            $RuleLine | Add-Member -Name "Nb time used ?"                 -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].utilisation)
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-FIREWALLRulesID {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )

    $RuleIDs = Get-FIREWALLRules -UrlToGo $UrlToGo
    $RuleID = $RuleIDs | Select-Object ID,Description | Out-GridView -Title "IPV4 FireWall List" -OutputMode Single
    $Rule = $RuleIDs | Where-Object {$_.ID -ilike $RuleID.id}
    
    Return $Rule
}

Function Get-FIREWALLPingResponder {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.firewall.pingresponder
    
    # Create new PSObject
    $PingResponderLine = New-Object -TypeName PSObject
    $PingResponderLine | Add-Member -Name "Service"                 -MemberType Noteproperty -Value "Ping Responder"
    $PingResponderLine | Add-Member -Name "Status"                  -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $PingResponderLine | Add-Member -Name "IP Addess/Range Allowed" -MemberType Noteproperty -Value $Json.ip
    
    # Add lines to $Array
    $Array += $PingResponderLine
    
    Return $Array
}

Function Get-FIREWALLGamerMode {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.firewall.gamermode
    
    # Create new PSObject
    $GamerModeLine = New-Object -TypeName PSObject
    $GamerModeLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "Gamer Mode"
    $GamerModeLine | Add-Member -Name "Status" -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    
    # Add lines to $Array
    $Array += $GamerModeLine
    
    Return $Array
}

Function Get-FIREWALLv6Rules {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.firewall.rules
    
    IF($Json.Count -ne 0){
        
        $Rule = 0
        
        While($Rule -lt $Json.Count){
            
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name "ID"                             -MemberType Noteproperty -Value $Json[$Rule].ID
            $RuleLine | Add-Member -Name "Status"                         -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].enable)
            $RuleLine | Add-Member -Name "Description"                    -MemberType Noteproperty -Value $Json[$Rule].description
            $RuleLine | Add-Member -Name "Action"                         -MemberType Noteproperty -Value $Json[$Rule].action
            $RuleLine | Add-Member -Name "IP Source is excluded ?"        -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcipnot)
            $RuleLine | Add-Member -Name "IP Source (Range/IP)"           -MemberType Noteproperty -Value $Json[$Rule].srcip
            $RuleLine | Add-Member -Name "IP Destination is excluded ?"   -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstipnot)
            $RuleLine | Add-Member -Name "IP Destination (Range/IP)"      -MemberType Noteproperty -Value $Json[$Rule].dstip
            $RuleLine | Add-Member -Name "MACs Source is excluded ?"      -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcmacnot) # Since version : 20.2.32
            $RuleLine | Add-Member -Name "MACs Source list"               -MemberType Noteproperty -Value $Json[$Rule].srcmac                         # Since version : 20.2.32
            $RuleLine | Add-Member -Name "MACs Destination is excluded ?" -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstmacnot) # Since version : 20.2.32
            $RuleLine | Add-Member -Name "MACs Destination list"          -MemberType Noteproperty -Value $Json[$Rule].dstmac                         # Since version : 20.2.32
            $RuleLine | Add-Member -Name "Port Source is excluded ?"      -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcportnot)
            $RuleLine | Add-Member -Name "Port Source (Range/Port)"       -MemberType Noteproperty -Value $Json[$Rule].srcports
            $RuleLine | Add-Member -Name "Port Destination is excluded ?" -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstportnot)
            $RuleLine | Add-Member -Name "Port Destination (Range/Port)"  -MemberType Noteproperty -Value $Json[$Rule].dstports
            $RuleLine | Add-Member -Name "Priority"                       -MemberType Noteproperty -Value $Json[$Rule].order
            $RuleLine | Add-Member -Name "TCP/UDP Protocols"              -MemberType Noteproperty -Value $Json[$Rule].protocols
            $RuleLine | Add-Member -Name "IP Protocols"                   -MemberType Noteproperty -Value $Json[$Rule].ipprotocol
            $RuleLine | Add-Member -Name "Number time used ?"             -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].utilisation)
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-FIREWALLv6RulesID {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $RuleIDs = Get-FIREWALLv6Rules -UrlToGo $UrlToGo
    $RuleID = $RuleIDs | Select-Object ID,Description | Out-GridView -Title "IPV6 FireWall Rules List : " -OutputMode Single
    $Rule = $RuleIDs | Where-Object {$_.ID -ilike $RuleID.id}
    
    Return $Rule
}

function Get-FIREWALLv6Level {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.firewall
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "FireWall IPV6"
    $DeviceLine | Add-Member -Name "Level"   -MemberType Noteproperty -Value $Json.level
    
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

#endregion FIREWALL

#region HOSTS

Function Get-HOSTS {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName.list
    
    If($Json.Count -ne 0){
        
        $Device = 0
        
        While($Device -lt ($Json.Count)){
            
            # Create New PSObject and add values to array
            $DeviceLine = New-Object -TypeName PSObject
            $DeviceLine | Add-Member -Name "ID"                               -MemberType Noteproperty -Value $Json[$Device].id
            $DeviceLine | Add-Member -Name "Hostname"                         -MemberType Noteproperty -Value $Json[$Device].hostname
            $DeviceLine | Add-Member -Name "MAC Address"                      -MemberType Noteproperty -Value $Json[$Device].macaddress
            $DeviceLine | Add-Member -Name "DUID"                             -MemberType Noteproperty -Value $Json[$Device].duid
            $DeviceLine | Add-Member -Name "IPV4 Adress"                      -MemberType Noteproperty -Value $Json[$Device].ipaddress
            $DeviceLine | Add-Member -Name "DHCP Mode"                        -MemberType Noteproperty -Value $Json[$Device].type
            $DeviceLine | Add-Member -Name "Link Type"                        -MemberType Noteproperty -Value $Json[$Device].link
            $DeviceLine | Add-Member -Name "Device Type"                      -MemberType Noteproperty -Value $Json[$Device].devicetype
            
            # If STB part
            If($Json[$Device].devicetype -like "STB"){
                
                $DeviceLine | Add-Member -Name "STB - Product"                -MemberType Noteproperty -Value $Json[$Device].stb.product
                $DeviceLine | Add-Member -Name "STB - Serial"                 -MemberType Noteproperty -Value $Json[$Device].stb.serial
            }
            Else{
                $DeviceLine | Add-Member -Name "STB - Product"                -MemberType Noteproperty -Value ""
                $DeviceLine | Add-Member -Name "STB - Serial"                 -MemberType Noteproperty -Value ""
            }
            
            $DeviceLine | Add-Member -Name "IPV4 Date first connexion"        -MemberType Noteproperty -Value ($Json[$Device].firstseen).Replace("T"," ")
            $DeviceLine | Add-Member -Name "IPV4 Date last connexion"         -MemberType Noteproperty -Value (Get-Date).AddSeconds(-($Json[$Device].lastseen))
            
            # If IPV6 part
            If(-not ([string]::IsNullOrEmpty($Json[$Device].ip6address))){
                
                $DeviceLine | Add-Member -Name "IPV6 Address"                 -MemberType Noteproperty -Value $($Json[$Device].ip6address.ipaddress -join ",")
                $DeviceLine | Add-Member -Name "IPV6 Statut"                  -MemberType Noteproperty -Value $($Json[$Device].ip6address.status -join ",")
                $DeviceLine | Add-Member -Name "IPV6 First Connexion Date"    -MemberType Noteproperty -Value $($Json[$Device].ip6address.lastseen -join ",")
                $DeviceLine | Add-Member -Name "IPV6 Last Connexion Date"     -MemberType Noteproperty -Value $($Json[$Device].ip6address.lastscan -join ",")
            }
            Else{
                $DeviceLine | Add-Member -Name "IPV6 Address"                 -MemberType Noteproperty -Value ""
                $DeviceLine | Add-Member -Name "IPV6 Statut"                  -MemberType Noteproperty -Value ""
                $DeviceLine | Add-Member -Name "IPV6 First Connexion Date"    -MemberType Noteproperty -Value ""
                $DeviceLine | Add-Member -Name "IPV6 Last Connexion Date"     -MemberType Noteproperty -Value ""
            }
            
            $DeviceLine | Add-Member -Name "Physical Port"                    -MemberType Noteproperty -Value $Json[$Device].ethernet.physicalport
            $DeviceLine | Add-Member -Name "Logical Port"                     -MemberType Noteproperty -Value $Json[$Device].ethernet.logicalport
            $DeviceLine | Add-Member -Name "Speed connexion"                  -MemberType Noteproperty -Value $Json[$Device].ethernet.speed
            $DeviceLine | Add-Member -Name "Mode"                             -MemberType Noteproperty -Value $Json[$Device].ethernet.mode
            $DeviceLine | Add-Member -Name "Band"                             -MemberType Noteproperty -Value $Json[$Device].wireless.band
            $DeviceLine | Add-Member -Name "RSSIO"                            -MemberType Noteproperty -Value $Json[$Device].wireless.rssi0
            $DeviceLine | Add-Member -Name "RSSI1"                            -MemberType Noteproperty -Value $Json[$Device].wireless.rssi1
            $DeviceLine | Add-Member -Name "RSSI2"                            -MemberType Noteproperty -Value $Json[$Device].wireless.rssi2
            $DeviceLine | Add-Member -Name "MSC"                              -MemberType Noteproperty -Value $Json[$Device].wireless.mcs
            $DeviceLine | Add-Member -Name "Rate"                             -MemberType Noteproperty -Value $Json[$Device].wireless.rate
            $DeviceLine | Add-Member -Name "Idle"                             -MemberType Noteproperty -Value $Json[$Device].wireless.idle
            $DeviceLine | Add-Member -Name "WexIndex"                         -MemberType Noteproperty -Value $Json[$Device].wireless.wexindex
            $DeviceLine | Add-Member -Name "Starealmac"                       -MemberType Noteproperty -Value $Json[$Device].wireless.starealmac
            $DeviceLine | Add-Member -Name "RXPhyrate"                        -MemberType Noteproperty -Value $Json[$Device].plc.rxphyrate
            $DeviceLine | Add-Member -Name "TXPhyrate"                        -MemberType Noteproperty -Value $Json[$Device].plc.txphyrate
            $DeviceLine | Add-Member -Name "Associated Device"                -MemberType Noteproperty -Value $Json[$Device].plc.associateddevice
            $DeviceLine | Add-Member -Name "Interface"                        -MemberType Noteproperty -Value $Json[$Device].plc.interface
            $DeviceLine | Add-Member -Name "Ethernet Speed"                   -MemberType Noteproperty -Value $Json[$Device].plc.ethernetspeed
            $DeviceLine | Add-Member -Name "Lease"                            -MemberType Noteproperty -Value $Json[$Device].lease
            $DeviceLine | Add-Member -Name "Active"                           -MemberType Noteproperty -Value $Json[$Device].active
            $DeviceLine | Add-Member -Name "Parental Control - State"         -MemberType Noteproperty -Value $Json[$Device].parentalcontrol.enable
            $DeviceLine | Add-Member -Name "Parental Control - Actual Status" -MemberType Noteproperty -Value $Json[$Device].parentalcontrol.status
            $DeviceLine | Add-Member -Name "Parental Control - Last Status"   -MemberType Noteproperty -Value $Json[$Device].parentalcontrol.statusRemaining
            $DeviceLine | Add-Member -Name "Parental Control - Next Status"   -MemberType Noteproperty -Value $Json[$Device].parentalcontrol.statusUntil
            $DeviceLine | Add-Member -Name "Average Ping"                     -MemberType Noteproperty -Value $Json[$Device].ping.average
            $DeviceLine | Add-Member -Name "Detected Active Services"         -MemberType Noteproperty -Value $($Json[$Device].scan.services -join ",")
            
            <# If Services part
            If(-not ([string]::IsNullOrEmpty($Json[$Device].scan.services))){
                
                $DeviceLine | Add-Member -Name "Detected Protocol"            -MemberType Noteproperty -Value $Json[$Device].scan.services.protocol
                $DeviceLine | Add-Member -Name "Detected Port"                -MemberType Noteproperty -Value $Json[$Device].scan.services.port
                $DeviceLine | Add-Member -Name "Port State"                   -MemberType Noteproperty -Value $Json[$Device].scan.services.state
                $DeviceLine | Add-Member -Name "Reason"                       -MemberType Noteproperty -Value $Json[$Device].scan.services.reason
            }
            Else{
                $DeviceLine | Add-Member -Name "Detected Protocol"            -MemberType Noteproperty -Value ""
                $DeviceLine | Add-Member -Name "Detected Port"                -MemberType Noteproperty -Value ""
                $DeviceLine | Add-Member -Name "Port State"                   -MemberType Noteproperty -Value ""
                $DeviceLine | Add-Member -Name "Reason"                       -MemberType Noteproperty -Value ""
            }
            #>
            
            # Add lines to $Array
            $Array += $DeviceLine
            
            # Go to next line
            $Device ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-HOSTSID {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $HostIDs = Get-HOSTS -UrlToGo $UrlToGo -APIName $APIName
    $HostID = $HostIDs | Select-Object ID,Hostname | Out-GridView -Title "Hosts List" -OutputMode Single
    $MachineID = $HostIDs | Where-Object {$_.ID -ilike $HostID.id}
    
    Return $MachineID
}

Function Get-HOSTSME {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.host
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name "ID"                               -MemberType Noteproperty -Value $Json.id
    $DeviceLine | Add-Member -Name "Hostname"                         -MemberType Noteproperty -Value $Json.hostname
    $DeviceLine | Add-Member -Name "MAC Address"                      -MemberType Noteproperty -Value $Json.macaddress
    $DeviceLine | Add-Member -Name "DUID"                             -MemberType Noteproperty -Value $Json.duid
    $DeviceLine | Add-Member -Name "IPV4 Adress"                      -MemberType Noteproperty -Value $Json.ipaddress
    $DeviceLine | Add-Member -Name "DHCP Mode"                        -MemberType Noteproperty -Value $Json.type
    $DeviceLine | Add-Member -Name "Link Type"                        -MemberType Noteproperty -Value $Json.link
    $DeviceLine | Add-Member -Name "Device Type"                      -MemberType Noteproperty -Value $Json.devicetype
    
    # If STB part
    If($Json.devicetype -like "STB"){
            
        $DeviceLine | Add-Member -Name "STB - Product"                -MemberType Noteproperty -Value $Json.stb.product
        $DeviceLine | Add-Member -Name "STB - Serial"                 -MemberType Noteproperty -Value $Json.stb.serial
    }
    Else{
        $DeviceLine | Add-Member -Name "STB - Product"                -MemberType Noteproperty -Value ""
        $DeviceLine | Add-Member -Name "STB - Serial"                 -MemberType Noteproperty -Value ""
    }
    
    $DeviceLine | Add-Member -Name "IPV4 Date first connexion"        -MemberType Noteproperty -Value ($Json.firstseen).Replace("T"," ")
    $DeviceLine | Add-Member -Name "IPV4 Date last connexion"         -MemberType Noteproperty -Value (Get-Date).AddSeconds(-($Json.lastseen))
        
    # If IPV6 part
    If(-not ([string]::IsNullOrEmpty($Json.ip6address))){
        
        $IPV6Line = 0
        $IPAddress = ""
        $Lastseen = ""
        $Lastscan = ""
        $Status = ""
        While($IPV6Line -ne $Json.ip6address.count){
            
            $IPAddress += "$($Json.ip6address[$IPV6Line].ipaddress);"
            $Status    += "$($Json.ip6address[$IPV6Line].status);"
            $Lastseen  += "$(($Json.ip6address[$IPV6Line].lastseen).Replace("T"," "));"
            $Lastscan  += "$(($Json.ip6address[$IPV6Line].lastscan).Replace("T"," "));"
            
            # Go to next line
            $IPV6Line ++
        }
        
        $DeviceLine | Add-Member -Name "IPV6 Address"                 -MemberType Noteproperty -Value $IPAddress
        $DeviceLine | Add-Member -Name "IPV6 Statut"                  -MemberType Noteproperty -Value $Status
        $DeviceLine | Add-Member -Name "IPV6 First Connexion Date"    -MemberType Noteproperty -Value $Lastseen
        $DeviceLine | Add-Member -Name "IPV6 Last Connexion Date"     -MemberType Noteproperty -Value $Lastscan
    }
    Else{
        $DeviceLine | Add-Member -Name "IPV6 Address"                 -MemberType Noteproperty -Value ""
        $DeviceLine | Add-Member -Name "IPV6 Statut"                  -MemberType Noteproperty -Value ""
        $DeviceLine | Add-Member -Name "IPV6 First Connexion Date"    -MemberType Noteproperty -Value ""
        $DeviceLine | Add-Member -Name "IPV6 Last Connexion Date"     -MemberType Noteproperty -Value ""
    }
    
    $DeviceLine | Add-Member -Name "Physical Port"                    -MemberType Noteproperty -Value $Json.ethernet.physicalport
    $DeviceLine | Add-Member -Name "Logical Port"                     -MemberType Noteproperty -Value $Json.ethernet.logicalport
    $DeviceLine | Add-Member -Name "Speed connexion"                  -MemberType Noteproperty -Value $Json.ethernet.speed
    $DeviceLine | Add-Member -Name "Mode"                             -MemberType Noteproperty -Value $Json.ethernet.mode
    $DeviceLine | Add-Member -Name "Band"                             -MemberType Noteproperty -Value $Json.wireless.band
    $DeviceLine | Add-Member -Name "RSSIO"                            -MemberType Noteproperty -Value $Json.wireless.rssi0
    $DeviceLine | Add-Member -Name "RSSI1"                            -MemberType Noteproperty -Value $Json.wireless.rssi1
    $DeviceLine | Add-Member -Name "RSSI2"                            -MemberType Noteproperty -Value $Json.wireless.rssi2
    $DeviceLine | Add-Member -Name "MSC"                              -MemberType Noteproperty -Value $Json.wireless.mcs
    $DeviceLine | Add-Member -Name "Rate"                             -MemberType Noteproperty -Value $Json.wireless.rate
    $DeviceLine | Add-Member -Name "Idle"                             -MemberType Noteproperty -Value $Json.wireless.idle
    $DeviceLine | Add-Member -Name "RXPhyrate"                        -MemberType Noteproperty -Value $Json.plc.rxphyrate
    $DeviceLine | Add-Member -Name "TXPhyrate"                        -MemberType Noteproperty -Value $Json.plc.txphyrate
    $DeviceLine | Add-Member -Name "Associated Device"                -MemberType Noteproperty -Value $Json.plc.associateddevice
    $DeviceLine | Add-Member -Name "Interface"                        -MemberType Noteproperty -Value $Json.plc.interface
    $DeviceLine | Add-Member -Name "Ethernet Speed"                   -MemberType Noteproperty -Value $Json.plc.ethernetspeed
    $DeviceLine | Add-Member -Name "Parental Control - State"         -MemberType Noteproperty -Value (Get-State -State $Json.parentalcontrol.enable)
    $DeviceLine | Add-Member -Name "Parental Control - Actual Status" -MemberType Noteproperty -Value $Json.parentalcontrol.status
    $DeviceLine | Add-Member -Name "Parental Control - Last Status"   -MemberType Noteproperty -Value $Json.parentalcontrol.statusRemaining
    $DeviceLine | Add-Member -Name "Parental Control - Next Status"   -MemberType Noteproperty -Value $Json.parentalcontrol.statusUntil
    $DeviceLine | Add-Member -Name "Lease"                            -MemberType Noteproperty -Value $Json.lease
    $DeviceLine | Add-Member -Name "First Connexion Date"             -MemberType Noteproperty -Value $Json.firstSeen.Replace("T"," ")
    $DeviceLine | Add-Member -Name "Last Connexion Date"              -MemberType Noteproperty -Value $Json.lastSeen
    $DeviceLine | Add-Member -Name "Is Active ?"                      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.active)
    $DeviceLine | Add-Member -Name "Ping Min"                         -MemberType Noteproperty -Value $Json.ping.min
    $DeviceLine | Add-Member -Name "Ping Max"                         -MemberType Noteproperty -Value $Json.ping.max
    $DeviceLine | Add-Member -Name "Ping Average"                     -MemberType Noteproperty -Value $Json.ping.average
    $DeviceLine | Add-Member -Name "Ping Success"                     -MemberType Noteproperty -Value $Json.ping.success
    $DeviceLine | Add-Member -Name "Ping Error"                       -MemberType Noteproperty -Value $Json.ping.error
    $DeviceLine | Add-Member -Name "Ping Tries"                       -MemberType Noteproperty -Value $Json.ping.tries
    If($Json.ping.status){
        $DeviceLine | Add-Member -Name "Ping status"                  -MemberType Noteproperty -Value (Get-Status -Status $Json.ping.status)
    }
    Else{$DeviceLine | Add-Member -Name "Ping status"                 -MemberType Noteproperty -Value $Json.ping.status}
    $DeviceLine | Add-Member -Name "Ping Result"                      -MemberType Noteproperty -Value $Json.ping.result
    If($Json.scan.status){
        $DeviceLine | Add-Member -Name "Scan Status"                  -MemberType Noteproperty -Value (Get-Status -Status $Json.scan.status)
    }
    Else{$DeviceLine |Add-Member -Name "Scan Status"                  -MemberType Noteproperty -Value $Json.scan.status}
    $DeviceLine | Add-Member -Name "Is Automatic Services Scan ?"     -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.scan.enable)
    $DeviceLine | Add-Member -Name "Services Detected"                -MemberType Noteproperty -Value $($Json.scan.services) #$Services
    
    <# Get Services open for devices
    $Services = @()
    $Service = 1
    
    While($Service -lt $Json.scan.services.count){
        
        # Create New PSObject and add values to array
        $ServiceLine = New-Object -TypeName PSObject
        $ServiceLine | Add-Member -Name "Detected Protocol"           -MemberType Noteproperty -Value $Json.scan.services.protocol
        $ServiceLine | Add-Member -Name "Detected Port"               -MemberType Noteproperty -Value $Json.scan.services.port
        $ServiceLine | Add-Member -Name "Port State"                  -MemberType Noteproperty -Value $Json.scan.services.state
        $ServiceLine | Add-Member -Name "Reason"                      -MemberType Noteproperty -Value $Json.scan.services.reason 
        
        $Services += $ServiceLine
        $Service ++
    }
    #>
    
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

Function Get-HOSTSLite {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.hosts.list
    
    If($Json.count -ne 0){
        
        $Device = 0
        
        While($Device -lt $Json.count){
            
            # Create New PSObject and add values to array
            $DeviceLine = New-Object -TypeName PSObject
            $DeviceLine | Add-Member -Name "ID"          -MemberType Noteproperty -Value $Json[$Device].id
            $DeviceLine | Add-Member -Name "Hostname"    -MemberType Noteproperty -Value $Json[$Device].hostname
            $DeviceLine | Add-Member -Name "IP Address"  -MemberType Noteproperty -Value $Json[$Device].ipaddress
            $DeviceLine | Add-Member -Name "MAC Address" -MemberType Noteproperty -Value $Json[$Device].macaddress
            $DeviceLine | Add-Member -Name "Link"        -MemberType Noteproperty -Value $Json[$Device].link
            
            # Add lines to $Array
            $Array += $DeviceLine
            
            # Go to next line
            $Device ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-HOSTSPAUTH {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.hosts.list
    
    If($Json.Count -ne 0){
    
        $Device = 0
    
        While($Device -lt ($Json.Count)){
        
            # Create New PSObject and add values to array
            $DeviceLine = New-Object -TypeName PSObject
            $DeviceLine | Add-Member -Name "ID"                -MemberType Noteproperty -Value $Json[$Device].id
            $DeviceLine | Add-Member -Name "Is my host"        -MemberType Noteproperty -Value $Json[$Device].me
            $DeviceLine | Add-Member -Name "DUID"              -MemberType Noteproperty -Value $Json[$Device].duid
            $DeviceLine | Add-Member -Name "DHCP Mode"         -MemberType Noteproperty -Value $Json[$Device].type
            $DeviceLine | Add-Member -Name "Link Type"         -MemberType Noteproperty -Value $Json[$Device].link
            $DeviceLine | Add-Member -Name "Device Type"       -MemberType Noteproperty -Value $Json[$Device].devicetype
            $DeviceLine | Add-Member -Name "Physical Port"     -MemberType Noteproperty -Value $Json[$Device].ethernet.physicalport
            $DeviceLine | Add-Member -Name "Logical Port"      -MemberType Noteproperty -Value $Json[$Device].ethernet.logicalport
            $DeviceLine | Add-Member -Name "Speed connexion"   -MemberType Noteproperty -Value $Json[$Device].ethernet.speed
            $DeviceLine | Add-Member -Name "Mode"              -MemberType Noteproperty -Value $Json[$Device].ethernet.mode
            $DeviceLine | Add-Member -Name "Band"              -MemberType Noteproperty -Value $Json[$Device].wireless.band
            $DeviceLine | Add-Member -Name "RSSIO"             -MemberType Noteproperty -Value $Json[$Device].wireless.rssi0
            $DeviceLine | Add-Member -Name "RSSI1"             -MemberType Noteproperty -Value $Json[$Device].wireless.rssi1
            $DeviceLine | Add-Member -Name "RSSI2"             -MemberType Noteproperty -Value $Json[$Device].wireless.rssi2
            $DeviceLine | Add-Member -Name "MSC"               -MemberType Noteproperty -Value $Json[$Device].wireless.mcs
            $DeviceLine | Add-Member -Name "Rate"              -MemberType Noteproperty -Value $Json[$Device].wireless.rate
            $DeviceLine | Add-Member -Name "Idle"              -MemberType Noteproperty -Value $Json[$Device].wireless.idle
            $DeviceLine | Add-Member -Name "WexIndex"          -MemberType Noteproperty -Value $Json[$Device].wireless.wexindex
            $DeviceLine | Add-Member -Name "Starealmac"        -MemberType Noteproperty -Value $Json[$Device].wireless.starealmac
            $DeviceLine | Add-Member -Name "RXPhyrate"         -MemberType Noteproperty -Value $Json[$Device].plc.rxphyrate
            $DeviceLine | Add-Member -Name "TXPhyrate"         -MemberType Noteproperty -Value $Json[$Device].plc.txphyrate
            $DeviceLine | Add-Member -Name "Associated Device" -MemberType Noteproperty -Value $Json[$Device].plc.associateddevice
            $DeviceLine | Add-Member -Name "Interface"         -MemberType Noteproperty -Value $Json[$Device].plc.interface
            $DeviceLine | Add-Member -Name "Ethernet Speed"    -MemberType Noteproperty -Value $Json[$Device].plc.ethernetspeed
            $DeviceLine | Add-Member -Name "Lease"             -MemberType Noteproperty -Value $Json[$Device].lease
            $DeviceLine | Add-Member -Name "Active"            -MemberType Noteproperty -Value $Json[$Device].active
            $DeviceLine | Add-Member -Name "Ping Average"      -MemberType Noteproperty -Value $Json[$Device].ping.average
            $DeviceLine | Add-Member -Name "Active Services"   -MemberType Noteproperty -Value $($Json[$Device].scan.services -join ",")

            # Add lines to $Array
            $Array += $DeviceLine
            
            # Go to next line
            $Device ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

#endregion HOSTS

#region IPTV

Function Get-IPTV {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    If($Json.Count -ne 0){
        
        $IPTV = 0
        
        While($IPTV -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $IPTVLine = New-Object -TypeName PSObject
            $IPTVLine | Add-Member -Name "Multicast IP Address"   -MemberType Noteproperty -Value $Json[$IPTV].address
            $IPTVLine | Add-Member -Name "Destination IP Address" -MemberType Noteproperty -Value $Json[$IPTV].ipaddress
            $IPTVLine | Add-Member -Name "Image Logo Name"        -MemberType Noteproperty -Value $Json[$IPTV].logo
            $IPTVLine | Add-Member -Name "Offset Logo"            -MemberType Noteproperty -Value $Json[$IPTV].logooffset
            $IPTVLine | Add-Member -Name "Channel Name"           -MemberType Noteproperty -Value $Json[$IPTV].name
            $IPTVLine | Add-Member -Name "Channel Number"         -MemberType Noteproperty -Value $Json[$IPTV].number
            $IPTVLine | Add-Member -Name "Channel Status"         -MemberType Noteproperty -Value (Get-Status -Status $Json[$IPTV].receipt)
            $IPTVLine | Add-Member -Name "EPG Channel ID"        -MemberType Noteproperty -Value $Json[$IPTV].epgid
            
            # Add lines to $Array
            $Array += $IPTVLine
            
            # Go to next line
            $IPTV ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-IPTVDiags {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0]
    
    # Create New PSObject and add values to array
    $IPTVDiagsLine = New-Object -TypeName PSObject
    $IPTVDiagsLine | Add-Member -Name "Date"                 -MemberType Noteproperty -Value $(Format-Date -String $Json.now) # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name "IGMP State"           -MemberType Noteproperty -Value (Get-State -State $Json.igmp.state) # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name "IGMP Status"          -MemberType Noteproperty -Value (Get-Status -Status $Json.igmp.enable) # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name "IPTV Multicast State" -MemberType Noteproperty -Value (Get-State -State $Json.iptv.multicast.state)
    $IPTVDiagsLine | Add-Member -Name "IPTV Multicast Date"  -MemberType Noteproperty -Value $(Format-Date -String $Json.iptv.multicast.date)
    $IPTVDiagsLine | Add-Member -Name "IPTV Platform State"  -MemberType Noteproperty -Value (Get-State -State $Json.iptv.platform.state)
    $IPTVDiagsLine | Add-Member -Name "IPTV Platform Date"   -MemberType Noteproperty -Value $(Format-Date -String $Json.iptv.platform.date)
    
    # Add lines to $Array
    $Array += $IPTVDiagsLine
    
    Return $Array
}

#endregion IPTV

#region LAN

Function Get-LANIP {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create arrays
    $IP = @()
    $Switch = @()
    
    # Select $JSON 's head
    $Json = $Json.lan
    
    # IP part
    # Create New PSObject and add values to array
    $IPLine = New-Object -TypeName PSObject
    $IPLine | Add-Member -Name "State"                           -MemberType Noteproperty -Value (Get-State -State $Json.ip.state)
    $IPLine | Add-Member -Name "MTU (Maximum transmission unit)" -MemberType Noteproperty -Value $Json.ip.mtu
    $IPLine | Add-Member -Name "IPV4 Address"                    -MemberType Noteproperty -Value $Json.ip.ipaddress
    $IPLine | Add-Member -Name "IPV4 NetMask"                    -MemberType Noteproperty -Value $Json.ip.netmask
    $IPLine | Add-Member -Name "IPV6 Statut"                     -MemberType Noteproperty -Value (Get-Status -Status $Json.ip.ip6enable)
    $IPLine | Add-Member -Name "IPV6 State"                      -MemberType Noteproperty -Value (Get-State -State $Json.ip.ip6state)
    $IPV6Line = 0
    $IPV6Params = ""
    While($IPV6Line -lt $json.ip.ip6address.Count){
        
        $IPV6Params += "$($Json.ip.ip6address[$IPV6Line].ipaddress),$($Json.ip.ip6address[$IPV6Line].status),$($Json.ip.ip6address[$IPV6Line].valid),$($Json.ip.ip6address[$IPV6Line].preferred);"
        
        # Go to next line
        $IPV6Line ++
    }
    $IPLine | Add-Member -Name "IPV6 Address"                    -MemberType Noteproperty -Value $IPV6Params
    $IPLine | Add-Member -Name "IPV6 Prefix"                     -MemberType Noteproperty -Value $Json.ip.ip6prefix.prefix
    $IPLine | Add-Member -Name "IPV6 Prefix Status"              -MemberType Noteproperty -Value $Json.ip.ip6prefix.status
    If(-not ([string]::IsNullOrEmpty($Json.ip.ip6prefix.valid))){
        $IPLine | Add-Member -Name "IPV6 Prefix Valid"               -MemberType Noteproperty -Value $(Format-Date -String $Json.ip.ip6prefix.valid)
    }
    If(-not ([string]::IsNullOrEmpty($Json.ip.ip6prefix.preferred))){
        $IPLine | Add-Member -Name "IPV6 Prefix Preferred"           -MemberType Noteproperty -Value $(Format-Date -String $Json.ip.ip6prefix.preferred)
    }
    $IPLine | Add-Member -Name "MAC Address"                     -MemberType Noteproperty -Value $Json.ip.mac
    $IPLine | Add-Member -Name "BBOX Hostname"                   -MemberType Noteproperty -Value $Json.ip.hostname
    $IPLine | Add-Member -Name "BBOX Domain"                     -MemberType Noteproperty -Value $Json.ip.domain
    $IPLine | Add-Member -Name "BBOX Alias (DNS)"                -MemberType Noteproperty -Value $Json.ip.aliases.replace(" ",",")
    
    $IP += $IPLine
    
    # Switch Part
    $Port = 0
    
    While($Port -lt $json.switch.ports.Count){
        
        # Create New PSObject and add values to array
        $PortLine = New-Object -TypeName PSObject
        $PortLine | Add-Member -Name "Port number"  -MemberType Noteproperty -Value $Json.switch.ports[$Port].id
        $PortLine | Add-Member -Name "State"        -MemberType Noteproperty -Value $Json.switch.ports[$Port].state
        $PortLine | Add-Member -Name "Link Mode"    -MemberType Noteproperty -Value $Json.switch.ports[$Port].link_mode
        $PortLine | Add-Member -Name "Is Blocked ?" -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.switch.ports[$Port].blocked)
        $PortLine | Add-Member -Name "Flickering ?" -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.switch.ports[$Port].flickering)
        
        $Switch += $PortLine
        
        # Go to next line
        $Port ++
    }
    
    Return $IP, $Switch
}

Function Get-LANStats {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.lan.stats
    
    # Create New PSObject and add values to array

    # RX
    $LanStatsLine = New-Object -TypeName PSObject
    $LanStatsLine | Add-Member -Name "RX Bytes"            -MemberType Noteproperty -Value $Json.rx.bytes
    $LanStatsLine | Add-Member -Name "RX Packets"          -MemberType Noteproperty -Value $Json.rx.packets
    $LanStatsLine | Add-Member -Name "RX Packets Errors"   -MemberType Noteproperty -Value $Json.rx.packetserrors
    $LanStatsLine | Add-Member -Name "RX Packets Discards" -MemberType Noteproperty -Value $Json.rx.packetsdiscards
    
    # TX
    $LanStatsLine | Add-Member -Name "TX Bytes"            -MemberType Noteproperty -Value $Json.tx.bytes
    $LanStatsLine | Add-Member -Name "TX Packets"          -MemberType Noteproperty -Value $Json.tx.packets
    $LanStatsLine | Add-Member -Name "TX Packets Errors"   -MemberType Noteproperty -Value $Json.tx.packetserrors
    $LanStatsLine | Add-Member -Name "TX Packets Discards" -MemberType Noteproperty -Value $Json.tx.packetsdiscards
    
    # Add lines to $Array
    $Array += $LanStatsLine
    
    Return $Array
}

Function Get-LANAlerts {

    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName.list
    
    If($Json.count -ne 0){
        
        $Alert = 0
        
        While($Alert -lt $Json.count){
            
            # $RecoveryDate formatting
            If(-not ([string]::IsNullOrEmpty($Json[$Alert].param))){
                
                $RecoveryDate = $(Format-Date -String $Json[$Alert].recovery_date)
            }
            Else{$RecoveryDate = $Json[$Alert].recovery_date}
            
            # $SolvedTime formatting
            If($Json[$Alert].total_duration -ne 0){
                
                $SolvedTime = ((Get-Date).AddMinutes(- $($Json[$Alert].total_duration)))
            }
            Else{$SolvedTime = "0"}
            
            # $Params formatting
            If ((-not (([string]::IsNullOrEmpty($Json[$Alert].param)))) -and ($Json[$Alert].param -match ";" )){
                
                $Params = ($Json[$Alert].param).split(";")
            }
            
            # $Details formatting
            Switch($Json[$Alert].ident){
                
                ALERT_DEVICE_UP                  {$Details = "Hostname : $($Params[2]), IP Address : $($Params[1]), MAC Address : $($Params[0])"}
                
                ALERT_DEVICE_DOWN                {$Details = "Hostname : $($Params[2]), IP Address : $($Params[1]), MAC Address : $($Params[0])"}
                
                ALERT_DHCLIENT_ACK               {$Details = $Json[$Alert].param}
                
                ALERT_DHCLIENT_REQUEST           {$Details = $Json[$Alert].param}
                
                ALERT_DHCLIENT_DISCOVER          {$Details = $Json[$Alert].param}
                
                ALERT_DIAG_SUCCESS               {$Details = $Json[$Alert].param}
                
                ALERT_DISPLAY_STATE              {$Details = $Json[$Alert].param}
                
                ALERT_LAN_API_LOCKED             {$Details = "IP Address Source : $($Params[0]), Hostaname : $($Params[3]), Failed Attempt Time : $($Params[1]), Block Time : $($Params[2]) min"}
                
                ALERT_LAN_OFFLINE_IP             {$Details = "IP Address Source : $($Params[0]), Hostaname : $($Params[2]), IP Address destination : $($Params[1])"}
                
                ALERT_LAN_PORT_UP                {$Details = "BBox Switch Port : $($Json[$Alert].param)"}
                
                ALERT_LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Associated Hostname : $($Params[2]), IP Address in conflit : $($Params[1])"}
                
                ALERT_LAN_DUP_IP                 {$Details = "IP Address conflict between : $($Json[$Alert].param)"}
                
                ALERT_LOGIN_LOCAL                {$Details = "Hostname : $($Params[1]), IP Address : $($Params[0])"}
                
                ALERT_MAIL_ERROR                 {$Details = "Error to send alert to the Mail Address : $($Json[$Alert].param)"}
                
                ALERT_NTP_SYNCHRONIZATION        {$Details = $Json[$Alert].param}
                
                ALERT_VOIP_INCOMING_CALL_END     {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])"}
                
                ALERT_VOIP_INCOMING_CALL_RINGING {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])"}
                
                ALERT_VOIP_INCOMING_CALL_START   {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])"}
                
                ALERT_VOIP_ONHOOK                {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$Alert].param)"}
                
                ALERT_VOIP_OFFHOOK               {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$Alert].param)"}
                
                ALERT_VOIP_REGISTERED            {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$Alert].param)"}
                
                ALERT_WAN_ROUTE_ADDED            {$Details = "IP Address : $($Params[0])"}
                
                ALERT_WAN_UPNP_ADD               {$Details = "IP Address : $($Params[0]), Local Port : $($Params[1]), External Port : $($Params[2])"}
                
                ALERT_WAN_UPNP_REMOVE            {$Details = "IP Address : $($Params[0]), Port : $($Params[1])"}
                
                ALERT_WIFI_UP                    {$Details = $Json[$Alert].param}
                
                Default                          {$Details = $Json[$Alert].param}
            }
            
            # Create New PSObject and add values to array
            $AlertLine = New-Object -TypeName PSObject
            $AlertLine | Add-Member -Name "ID"                 -MemberType Noteproperty -Value $Json[$Alert].id
            $AlertLine | Add-Member -Name "Alert type"         -MemberType Noteproperty -Value $Json[$Alert].ident
            $AlertLine | Add-Member -Name "Details"            -MemberType Noteproperty -Value $Details # Calculate field not inclued in API
            $AlertLine | Add-Member -Name "First Date seen"    -MemberType Noteproperty -Value $(Format-Date -String $Json[$Alert].first_date)
            $AlertLine | Add-Member -Name "Last Date seen"     -MemberType Noteproperty -Value $(Format-Date -String $Json[$Alert].last_date)
            $AlertLine | Add-Member -Name "Recovery Date"      -MemberType Noteproperty -Value $RecoveryDate
            $AlertLine | Add-Member -Name "Nb Occurences"      -MemberType Noteproperty -Value $Json[$Alert].count
            $AlertLine | Add-Member -Name "Solved Time"        -MemberType Noteproperty -Value $SolvedTime # Calculate filed not inclued in API
            $AlertLine | Add-Member -Name "Notification Level" -MemberType Noteproperty -Value $Json[$Alert].level
            
            # Add lines to $Array
            $Array += $AlertLine
            
            # Go to next line
            $Alert ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

#endregion LAN

#region NAT

Function Get-NAT {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].nat
    
    # Create New PSObject and add values to array
    $NATLine = New-Object -TypeName PSObject
    $NATLine | Add-Member -Name "Service"              -MemberType Noteproperty -Value "NAT/PAT"
    $NATLine | Add-Member -Name "Status"               -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $NATLine | Add-Member -Name "Nb configured Rules"  -MemberType Noteproperty -Value $Json.rules.count
    
    # Add lines to $Array
    $Array += $NATLine
    
    Return $Array
}

Function Get-NATDMZ {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.nat.dmz
    
    # Create New PSObject and add values to array
    $NATDMZLine = New-Object -TypeName PSObject
    $NATDMZLine | Add-Member -Name "Service"            -MemberType Noteproperty -Value "DMZ"
    $NATDMZLine | Add-Member -Name "State"              -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $NATDMZLine | Add-Member -Name "Status"             -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $NATDMZLine | Add-Member -Name "IP Address"         -MemberType Noteproperty -Value $Json.ipaddress
    $NATDMZLine | Add-Member -Name "DNS Protect Status" -MemberType Noteproperty -Value (Get-State -State $Json.dnsprotect)
    
    # Add lines to $Array
    $Array += $NATDMZLine
    
    Return $Array
}

Function Get-NATRules {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.nat.rules
    
    If($Json.count -ne 0){
        
        $NAT = 0
        
        While($NAT -lt $Json.count){
            
            # Create New PSObject and add values to array
            $NATLine = New-Object -TypeName PSObject
            $NATLine | Add-Member -Name "ID"                  -MemberType Noteproperty -Value $Json[$NAT].id
            $NATLine | Add-Member -Name "Status"              -MemberType Noteproperty -Value $(Get-Status -Status $Json[$NAT].enable)
            $NATLine | Add-Member -Name "Description"         -MemberType Noteproperty -Value $Json[$NAT].description
            $NATLine | Add-Member -Name "External IP Address" -MemberType Noteproperty -Value $Json[$NAT].externalip
            $NATLine | Add-Member -Name "External Port"       -MemberType Noteproperty -Value $Json[$NAT].externalport
            $NATLine | Add-Member -Name "Internal Port"       -MemberType Noteproperty -Value $Json[$NAT].internalport
            $NATLine | Add-Member -Name "Internal IP Address" -MemberType Noteproperty -Value $Json[$NAT].internalip
            $NATLine | Add-Member -Name "Protocol"            -MemberType Noteproperty -Value $Json[$NAT].protocol
            
            # Add lines to $Array
            $Array += $NATLine
            
            # Go to next line
            $NAT ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-NATRulesID {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $RuleIDs = Get-NATRules -UrlToGo $UrlToGo
    $RuleID = $RuleIDs | Select-Object ID,Description | Out-GridView -Title "NAT Rules List" -OutputMode Single
    $HostRules = $RuleIDs | Where-Object {$_.ID -ilike $RuleID.id}
    
    Return $HostRules
}

#endregion NAT

#region Notification

Function Get-NOTIFICATION {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $NOTIFICATIONLine = New-Object -TypeName PSObject
    $NOTIFICATIONLine | Add-Member -Name "Service"              -MemberType Noteproperty -Value $APIName
    $NOTIFICATIONLine | Add-Member -Name "State"                -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $NOTIFICATIONLine | Add-Member -Name "Nb configured Alerts" -MemberType Noteproperty -Value $Json.alerts.count
    
    # Add lines to $Array
    $Array += $NOTIFICATIONLine
    
    Return $Array
}

Function Get-NOTIFICATIONAlerts {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.notification.Alerts
    
    If($Json.Count -ne 0){
        
        $NOTIFICATION = 0
        
        While($NOTIFICATION -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $NOTIFICATIONLine = New-Object -TypeName PSObject
            $NOTIFICATIONLine | Add-Member -Name "ID"              -MemberType Noteproperty -Value $Json[$NOTIFICATION].id
            $NOTIFICATIONLine | Add-Member -Name "State"           -MemberType Noteproperty -Value (Get-State -State $Json[$NOTIFICATION].enable)
            $NOTIFICATIONLine | Add-Member -Name "Name"            -MemberType Noteproperty -Value $Json[$NOTIFICATION].name # To be review due to syntaxe
            $NOTIFICATIONLine | Add-Member -Name "Events"          -MemberType Noteproperty -Value $Json[$NOTIFICATION].events
            $NOTIFICATIONLine | Add-Member -Name "Action Type"     -MemberType Noteproperty -Value $Json[$NOTIFICATION].action.type
            $NOTIFICATIONLine | Add-Member -Name "Send Mail Delay" -MemberType Noteproperty -Value $Json[$NOTIFICATION].action.delay
            $NOTIFICATIONLine | Add-Member -Name "Contact ID"      -MemberType Noteproperty -Value $Json[$NOTIFICATION].action.mail.dests
            
            # Add lines to $Array
            $Array += $NOTIFICATIONLine
            
            # Go to next line
            $NOTIFICATION ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-NOTIFICATIONContacts {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.notification.contacts
    
    If($Json.Count -ne 0){
        
        $Contacts = 0
        
        While($Contacts -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $ContactsLine = New-Object -TypeName PSObject
            $ContactsLine | Add-Member -Name "ID"          -MemberType Noteproperty -Value $Json[$Contacts].id
            $ContactsLine | Add-Member -Name "State"       -MemberType Noteproperty -Value (Get-Status -Status $Json[$Contacts].enable)
            $ContactsLine | Add-Member -Name "Mail"        -MemberType Noteproperty -Value $Json[$Contacts].mail
            $ContactsLine | Add-Member -Name "Description" -MemberType Noteproperty -Value $Json[$Contacts].name
            
            # Add lines to $Array
            $Array += $ContactsLine
            
            # Go to next line
            $Contacts ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-NOTIFICATIONEvents {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.notification.events
    
    If($Json.Count -ne 0){
        
        $Events = 0
        
        While($Events -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $EventsLine = New-Object -TypeName PSObject
            $EventsLine | Add-Member -Name "Name"       -MemberType Noteproperty -Value "$($Json[$Events].name)"
            $EventsLine | Add-Member -Name "Category"   -MemberType Noteproperty -Value "$($Json[$Events].category)" # Syntaxe to be reviewed
            $EventsLine | Add-Member -Name "Descrition" -MemberType Noteproperty -Value "$($Json[$Events].description)" # Syntaxe to be reviewed
            $EventsLine | Add-Member -Name "Message"    -MemberType Noteproperty -Value "$($Json[$Events].humanReadable)" # Syntaxe to be reviewed
            
            # Add lines to $Array
            $Array += $EventsLine
            
            # Go to next line
            $Events ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

#endregion Notification

#region PARENTAL CONTROL

Function Get-ParentalControl {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName.scheduler
    
    # Create New PSObject and add values to array
    $ParentalControlLine = New-Object -TypeName PSObject
    $ParentalControlLine | Add-Member -Name "Service"        -MemberType Noteproperty -Value "Parental Control"
    $ParentalControlLine | Add-Member -Name "Date"           -MemberType Noteproperty -Value $(Format-Date -String $Json.now)
    $ParentalControlLine | Add-Member -Name "State"          -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $ParentalControlLine | Add-Member -Name "Default Policy" -MemberType Noteproperty -Value $Json.defaultpolicy
    
    # Add lines to $Array
    $Array += $ParentalControlLine
    
    Return $Array
}

Function Get-ParentalControlScheduler {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.parentalcontrol.scheduler
    
    $Scheduler = 0
    
    # Create New PSObject and add values to array
    $SchedulerLine = New-Object -TypeName PSObject
    $SchedulerLine | Add-Member -Name "Service"     -MemberType Noteproperty -Value "Parental Control Scheduler"
    $SchedulerLine | Add-Member -Name "Date"        -MemberType Noteproperty -Value $(Format-Date -String $Json.now)
    $SchedulerLine | Add-Member -Name "State"       -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $SchedulerLine | Add-Member -Name "Rules count" -MemberType Noteproperty -Value $Json.rules.count
    
    # Add lines to $Array
    $Array += $SchedulerLine
    
    # Go to next line
    $Scheduler ++
    
    Return $Array
}

Function Get-ParentalControlSchedulerRules {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.parentalcontrol.scheduler.rules
    
    If($Json.Count -ne 0){
        
        $Scheduler = 0
        
        While($Scheduler -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $SchedulerLine = New-Object -TypeName PSObject
            $SchedulerLine | Add-Member -Name "ID"         -MemberType Noteproperty -Value "$($Json[$Scheduler].id)"
            $SchedulerLine | Add-Member -Name "State"      -MemberType Noteproperty -Value (Get-State -State $Json[$Scheduler].enable)
            $SchedulerLine | Add-Member -Name "Name"       -MemberType Noteproperty -Value $Json[$Scheduler].name
            $SchedulerLine | Add-Member -Name "Start Time" -MemberType Noteproperty -Value "From : $($Json[$Scheduler].start.day), $($Json[$Scheduler].start.hour)h0$($Json[$Scheduler].start.minute)"
            $SchedulerLine | Add-Member -Name "End Time"   -MemberType Noteproperty -Value "To : $($Json[$Scheduler].end.day), $($Json[$Scheduler].end.hour)h0$($Json[$Scheduler].end.minute)"
            
            # Add lines to $Array
            $Array += $SchedulerLine
            
            # Go to next line
            $Scheduler ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

#endregion PARENTAL CONTROL

#region PHONE PROFILE

Function Get-PHONEProfileConsumption {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.profile
    
    # Create New PSObject and add values to array
    $ProfileLine = New-Object -TypeName PSObject
    $ProfileLine | Add-Member -Name "Profile"  -MemberType Noteproperty -Value $($Json.login)
    $ProfileLine | Add-Member -Name "Password" -MemberType Noteproperty -Value "*************"
    
    # Add lines to $Array
    $Array += $ProfileLine
    
    Return $Array
}

#endregion PHONE PROFILE

#region REMOTE

Function Get-REMOTEProxyWOL {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.Proxywol
    
    # Create New PSObject and add values to array
    $ProfileLine = New-Object -TypeName PSObject
    $ProfileLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "Remote Proxy WOL"
    $ProfileLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $ProfileLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    
    # Add lines to $Array
    $Array += $ProfileLine
    
    Return $Array
}

#endregion REMOTE

#region SERVICES

Function Get-SERVICES {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # FIREWALL
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "FIREWALL"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.firewall.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.firewall.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value "$($Json.firewall.nbrules) rule(s)"
    $Array += $ServiceLine
    
    # DYNDNS
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "DYNDNS"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.dyndns.state)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.dyndns.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value "$($Json.dyndns.nbrules) configuration(s)"
    $Array += $ServiceLine
    
    # DHCPV4
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "DHCPv4"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.dhcp.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.dhcp.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value "$($Json.dhcp.nbrules) host(s)"
    $Array += $ServiceLine
    
    # DHCPV6 New Since Version 19.2.12
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "DHCPv6"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.dhcp6.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.dhcp6.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value "$($Json.dhcp6.nbrules) host(s)"
    $Array += $ServiceLine
    
    # NAT/PAT
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "NAT/PAT"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.nat.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.nat.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value "$($Json.nat.nbrules) rule(s)"
    $Array += $ServiceLine
    
    # GAMER MODE
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "GAMER MODE"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.gamermode.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.gamermode.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value ""
    $Array += $ServiceLine
    
    # UPNP/IGD
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "UPNP/IGD"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.upnp.igd.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.upnp.igd.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value "$($Json.upnp.igd.nbrules) rule(s)"
    $Array += $ServiceLine
    
    # WOL PROXY
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "WOL PROXY"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.remote.proxywol.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.remote.proxywol.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value "IP address : $($Json.remote.proxywol.ip)"
    $Array += $ServiceLine
    
    # ADMIN / BBOX REMOTE ACCESS
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "REMOTE ACCESS"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.remote.admin.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.remote.admin.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value "Activable : $(Get-YesNoAsk -YesNoAsk $Json.remote.admin.activable), Allowed IPV4 : $($Json.remote.admin.ip), Allowed IPV6 : $($Json.remote.admin.ip6address), External port : $($Json.remote.admin.port), Delay : $($Json.remote.admin.duration)"
    $Array += $ServiceLine
    
    # PARENTAL CONTROL
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "PARENTAL CONTROL"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value ""
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.parentalcontrol.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value ""
    $Array += $ServiceLine
    
    # WIFI SCHEDULER
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "WIFI SCHEDULER"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value ""
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.wifischeduler.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value ""
    $Array += $ServiceLine
    
    # VOIP SCHEDULER
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "VOIP SCHEDULER"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value ""
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.voipscheduler.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value ""
    $Array += $ServiceLine
    
    # NOTIFICATION
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "NOTIFICATION"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value ""
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value ""
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value "$($Json.notification.enable) active rules"
    $Array += $ServiceLine
    
    # WIFI HOTSPOT
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "WIFI HOTSPOT"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.hotspot.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.hotspot.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value ""
    $Array += $ServiceLine
    
    # SAMBA
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "USB SAMBA STORAGE"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.usb.samba.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.usb.samba.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value ""
    $Array += $ServiceLine
    
    # PRINTER
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "USB PRINTER"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.usb.printer.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.usb.printer.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value ""
    $Array += $ServiceLine
    
    # DLNA
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "DLNA"
    $ServiceLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.usb.dlna.status)
    $ServiceLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.upnp.igd.enable)
    $ServiceLine | Add-Member -Name "Params"  -MemberType Noteproperty -Value ""
    $Array += $ServiceLine

    Return $Array
}

#endregion SERVICES

#region SUMMARY

Function Get-SUMMARY {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Calculate Intermediary values
    
    #IPTV Devices list
    $I = 0
    $IPTV = @()
    While($I -lt $Json.iptv.count){
        $IPTV += "Source IP Address : $($Json.iptv[$I].address), Destination IP Address : $($Json.iptv[$I].ipaddress), Reception en cours : $($Json.iptv[$I].receipt), Channel Number : $($Json.iptv[$I].number)"
        
        # Go to next line
        $I++
    }
    $IPTV = $IPTV -join " ; "
    
    # USB Printers list
    $J = 0
    $Printer = @()
    While($J -lt $Json.usb.printer.count){
        $Printer += "Name : $($Json.usb.printer[$J].product), State : $($Json.usb.printer[$J].state)"
        
        # Go to next line
        $J++
    }
    $Printer = $Printer -join " ; "
    
    # USB Samba Storage
    $K = 0
    $Storage = @()
    While($k -lt $Json.usb.storage.count){
        $Storage += "Label : $($Json.usb.storage[$K].label), State : $($Json.usb.storage[$K].state)"
        
        # Go to next line
        $K++
    }
    $Storage = $Storage -join " ; "
    
    # Hosts List
    $L = 0
    $Hosts = @()
    While($L -lt $Json.hosts.count){
        $Hosts += "Hostname : $($Json.hosts[$L].hostname), IP address : $($Json.hosts[$L].ipaddress)"
        
        # Go to next line
        $L++
    }
    $Hosts = $Hosts -join " ; "
    
    # StatusRemaning
    $ParentalControlStatusRemaining = New-TimeSpan -Seconds $Json.services.parentalcontrol.statusRemaining
    $WifiSchedulerStatusRemaining   = New-TimeSpan -Seconds $Json.services.wifischeduler.statusRemaining
    $VOIPSchedulerStatusRemaining   = New-TimeSpan -Seconds $Json.services.voipscheduler.statusRemaining
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name "Date"                              -MemberType Noteproperty -Value $(Format-Date -String $Json.now)
    $DeviceLine | Add-Member -Name "User Authenticated State"          -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.authenticated)
    $DeviceLine | Add-Member -Name "Luminosity State"                  -MemberType Noteproperty -Value (Get-State -State $Json.display.state)
    $DeviceLine | Add-Member -Name "Luminosity Power (%)"              -MemberType Noteproperty -Value $Json.display.luminosity
    $DeviceLine | Add-Member -Name "Internet State"                    -MemberType Noteproperty -Value (Get-State -State $Json.internet.state)
    $DeviceLine | Add-Member -Name "VOIP Status"                       -MemberType Noteproperty -Value (Get-Status -Status $Json.voip[0].status)
    $DeviceLine | Add-Member -Name "VOIP Call State"                   -MemberType Noteproperty -Value $Json.voip[0].callstate
    $DeviceLine | Add-Member -Name "VOIP Message count"                -MemberType Noteproperty -Value $Json.voip[0].message
    $DeviceLine | Add-Member -Name "VOIP Call failed"                  -MemberType Noteproperty -Value $Json.voip[0].notanswered
    $DeviceLine | Add-Member -Name "IPTV Device List"                  -MemberType Noteproperty -Value $iptv
    $DeviceLine | Add-Member -Name "USB Printer"                       -MemberType Noteproperty -Value $Printer
    $DeviceLine | Add-Member -Name "USB Storage"                       -MemberType Noteproperty -Value $Storage
    $DeviceLine | Add-Member -Name "Wireless Status"                   -MemberType Noteproperty -Value $Json.wireless.status
    $DeviceLine | Add-Member -Name "Wireless Channel"                  -MemberType Noteproperty -Value $Json.wireless.radio
    $DeviceLine | Add-Member -Name "Wireless Change Date"              -MemberType Noteproperty -Value $(Format-Date -String $Json.wireless.changedate)
    $DeviceLine | Add-Member -Name "WPS 2,4Ghz "                       -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps."24".available)
    $DeviceLine | Add-Member -Name "WPS 5,2Ghz"                        -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps."5".available)
    $DeviceLine | Add-Member -Name "WPS State"                         -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps.enable)
    $DeviceLine | Add-Member -Name "WPS Status"                        -MemberType Noteproperty -Value $Json.wireless.wps.status
    $DeviceLine | Add-Member -Name "WPS Timeout"                       -MemberType Noteproperty -Value $Json.wireless.wps.timeout
    $DeviceLine | Add-Member -Name "Wifi State"                        -MemberType Noteproperty -Value (Get-State -State $Json.services.hotspot.enable)
    $DeviceLine | Add-Member -Name "Firewall State"                    -MemberType Noteproperty -Value (Get-State -State $Json.services.firewall.enable)
    $DeviceLine | Add-Member -Name "DYNDNS State"                      -MemberType Noteproperty -Value (Get-State -State $Json.services.dyndns.enable)
    $DeviceLine | Add-Member -Name "DHCP State"                        -MemberType Noteproperty -Value (Get-State -State $Json.services.dhcp.enable)
    $DeviceLine | Add-Member -Name "NAT State"                         -MemberType Noteproperty -Value "$(Get-State -State $Json.services.nat.enable), Active Rules : $($Json.services.nat.enable)"
    $DeviceLine | Add-Member -Name "DMZ State"                         -MemberType Noteproperty -Value (Get-State -State $Json.services.dmz.enable)
    $DeviceLine | Add-Member -Name "NATPAT State"                      -MemberType Noteproperty -Value (Get-State -State $Json.services.natpat.enable)
    $DeviceLine | Add-Member -Name "UPNP/IGD State"                    -MemberType Noteproperty -Value (Get-State -State $Json.services.upnp.igd.enable)
    $DeviceLine | Add-Member -Name "Notification State"                -MemberType Noteproperty -Value "$(Get-State -State $Json.services.notification.enable), Active Notifications Rules : $($Json.services.notification.enable)"
    $DeviceLine | Add-Member -Name "ProxyWOL State"                    -MemberType Noteproperty -Value (Get-State -State $Json.services.proxywol.enable)
    $DeviceLine | Add-Member -Name "Web Remote State"                  -MemberType Noteproperty -Value (Get-State -State $Json.services.remoteweb.enable)
    $DeviceLine | Add-Member -Name "Parental Control State"            -MemberType Noteproperty -Value (Get-State -State $Json.services.parentalcontrol.enable)
    $DeviceLine | Add-Member -Name "Parental Control Status"           -MemberType Noteproperty -Value (Get-Status -Status $Json.services.parentalcontrol.status)
    $DeviceLine | Add-Member -Name "Parental Control Status Until"     -MemberType Noteproperty -Value $(Format-Date -String $Json.services.parentalcontrol.statusUntil)
    $DeviceLine | Add-Member -Name "Parental Control Status Remaining" -MemberType Noteproperty -Value "$($ParentalControlStatusRemaining.Hours)h$($ParentalControlStatusRemaining.Minutes)m$($ParentalControlStatusRemaining.Seconds)s"
    $DeviceLine | Add-Member -Name "WIFI Scheduler State"              -MemberType Noteproperty -Value (Get-State -State $Json.services.wifischeduler.enable)
    $DeviceLine | Add-Member -Name "WIFI Scheduler Status"             -MemberType Noteproperty -Value (Get-Status -Status $Json.services.wifischeduler.status)
    $DeviceLine | Add-Member -Name "WIFI Scheduler Status Until"       -MemberType Noteproperty -Value $(Format-Date -String $Json.services.wifischeduler.statusUntil)
    $DeviceLine | Add-Member -Name "WIFI Scheduler Status Remaining"   -MemberType Noteproperty -Value "$($WifiSchedulerStatusRemaining.Hours)h$($WifiSchedulerStatusRemaining.Minutes)m$($WifiSchedulerStatusRemaining.Seconds)s"
    $DeviceLine | Add-Member -Name "VOIP Scheduler State"              -MemberType Noteproperty -Value (Get-State -State $Json.services.voipscheduler.enable)
    $DeviceLine | Add-Member -Name "VOIP Scheduler Status"             -MemberType Noteproperty -Value (Get-Status -Status $Json.services.voipscheduler.status)
    $DeviceLine | Add-Member -Name "VOIP Scheduler Status Until"       -MemberType Noteproperty -Value $(Format-Date -String $Json.services.voipscheduler.statusUntil)
    $DeviceLine | Add-Member -Name "VOIP Scheduler Status Remaining"   -MemberType Noteproperty -Value "$($VOIPSchedulerStatusRemaining.Hours)h$($VOIPSchedulerStatusRemaining.Minutes)m$($VOIPSchedulerStatusRemaining.Seconds)s"
    $DeviceLine | Add-Member -Name "GamerMode State"                   -MemberType Noteproperty -Value (Get-State -State $Json.services.gamermode.enable)
    $DeviceLine | Add-Member -Name "DHCP V6 State"                     -MemberType Noteproperty -Value (Get-State -State $Json.services.dhcp6.enable) # Since version : 19.2.12
    $DeviceLine | Add-Member -Name "USB Samba State"                   -MemberType Noteproperty -Value (Get-State -State $Json.services.samba.enable)
    $DeviceLine | Add-Member -Name "USB Samba Status"                  -MemberType Noteproperty -Value (Get-Status -Status $Json.services.samba.status)
    $DeviceLine | Add-Member -Name "USB Printer State"                 -MemberType Noteproperty -Value (Get-State -State $Json.services.printer.enable)
    $DeviceLine | Add-Member -Name "USB Printer Status"                -MemberType Noteproperty -Value (Get-Status -Status $Json.services.printer.status)
    $DeviceLine | Add-Member -Name "DLNA State"                        -MemberType Noteproperty -Value (Get-State -State $Json.services.dlna.enable)
    $DeviceLine | Add-Member -Name "DLNA Status"                       -MemberType Noteproperty -Value (Get-Status -Status $Json.services.dlna.status)
    $DeviceLine | Add-Member -Name "Phone Line 1 Echo Test Status"     -MemberType Noteproperty -Value (Get-Status -Status $Json.diags[0].echo_test.status)
    $DeviceLine | Add-Member -Name "Phone Line 1 Ring Test Status"     -MemberType Noteproperty -Value (Get-Status -Status $Json.diags[0].ring_test.status)
    $DeviceLine | Add-Member -Name "Phone Line 2 Echo Test Status"     -MemberType Noteproperty -Value (Get-Status -Status $Json.diags[1].echo_test.status)
    $DeviceLine | Add-Member -Name "Phone Line 2 Ring Test Status"     -MemberType Noteproperty -Value (Get-Status -Status $Json.diags[1].ring_test.status)
    $DeviceLine | Add-Member -Name "Hosts List"                        -MemberType Noteproperty -Value $Hosts
    $DeviceLine | Add-Member -Name "WAN IPV4"                          -MemberType Noteproperty -Value (Get-State -State $Json.wan.ip.state.ip)
    $DeviceLine | Add-Member -Name "WAN IPV6"                          -MemberType Noteproperty -Value (Get-State -State $Json.wan.ip.state.ipv6)
    $DeviceLine | Add-Member -Name "WAN IP stats Tx Occupation"        -MemberType Noteproperty -Value $Json.wan.ip.stats.tx.occupation
    $DeviceLine | Add-Member -Name "WAN IP stats Rx Occupation"        -MemberType Noteproperty -Value $Json.wan.ip.stats.rx.occupation
    $DeviceLine | Add-Member -Name "Nb Alerts"                         -MemberType Noteproperty -Value $Json.alerts.count
    $DeviceLine | Add-Member -Name "Nb CPL"                            -MemberType Noteproperty -Value $Json.cpl.count

    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

#endregion SUMMARY

#region UPNP/IGD

Function Get-UPNPIGD {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.upnp.igd
    
    # Create New PSObject and add values to array
    $EventsLine = New-Object -TypeName PSObject
    $EventsLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "UPNP/IGD"
    $EventsLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $EventsLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $EventsLine | Add-Member -Name "UUID"    -MemberType Noteproperty -Value $Json.uuid
    $EventsLine | Add-Member -Name "Name"    -MemberType Noteproperty -Value $Json.friendlyname
    
    # Add lines to $Array
    $Array += $EventsLine
    
    Return $Array
}

Function Get-UPNPIGDRules {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    If($Json.Count -ne 0){
    
        # Create array
        $Array = @()
        
        # Select $JSON header
        $Json = $Json.upnp.igd.rules
        
        $Rule = 0
        
        While($Rule -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name "ID"                  -MemberType Noteproperty -Value $Json[$Rule].id
            $RuleLine | Add-Member -Name "Status"              -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].enable)
            $RuleLine | Add-Member -Name "Description"         -MemberType Noteproperty -Value $Json[$Rule].description
            $RuleLine | Add-Member -Name "Internal IP Address" -MemberType Noteproperty -Value $Json[$Rule].internalip
            $RuleLine | Add-Member -Name "Internal Port"       -MemberType Noteproperty -Value $Json[$Rule].internalport
            $RuleLine | Add-Member -Name "External Port"       -MemberType Noteproperty -Value $Json[$Rule].externalport
            $RuleLine | Add-Member -Name "Protocol"            -MemberType Noteproperty -Value $Json[$Rule].protocol
            $RuleLine | Add-Member -Name "Expiration Date"     -MemberType Noteproperty -Value $(Format-Date -String $Json[$Rule].expire)
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

#endregion UPNP/IGD

#region USB

Function Get-DeviceUSBDevices {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    If($Json.usb.count -ne "0"){
        
        # Create array
        $Array = @()
        
        # Select $JSON header
        $Json = $Json.usb
        $USBDevice = 0
        
        While($USBDevice -lt $Json.parent.Count){
            
            # Create New PSObject and add values to array
            
            # Parent
            $USBDeviceLine = New-Object -TypeName PSObject
            $USBDeviceLine | Add-Member -Name "Index"              -MemberType Noteproperty -Value $Json.child[$USBDevice].index
            $USBDeviceLine | Add-Member -Name "Parent Identity"    -MemberType Noteproperty -Value $Json.parent[$USBDevice].ident
            $USBDeviceLine | Add-Member -Name "Parent Description" -MemberType Noteproperty -Value $Json.parent[$USBDevice].description
            
            # Children
            $USBDeviceLine | Add-Member -Name "File System type"   -MemberType Noteproperty -Value $Json.child[$USBDevice].ident
            $USBDeviceLine | Add-Member -Name "Parent"             -MemberType Noteproperty -Value $Json.child[$USBDevice].parent
            $USBDeviceLine | Add-Member -Name "UUID"               -MemberType Noteproperty -Value $Json.child[$USBDevice].uuid
            $USBDeviceLine | Add-Member -Name "Label Partition"    -MemberType Noteproperty -Value $Json.child[$USBDevice].label
            $USBDeviceLine | Add-Member -Name "Description"        -MemberType Noteproperty -Value $Json.child[$USBDevice].description
            $USBDeviceLine | Add-Member -Name "File System"        -MemberType Noteproperty -Value $Json.child[$USBDevice].fs
            $USBDeviceLine | Add-Member -Name "Samba Name"         -MemberType Noteproperty -Value $Json.child[$USBDevice].name
            $USBDeviceLine | Add-Member -Name "Is writable ?"      -MemberType Noteproperty -Value $(Get-USBRight -USBRight $($Json.child[$USBDevice].writable))
            $USBDeviceLine | Add-Member -Name "USB Port number"    -MemberType Noteproperty -Value $Json.child[$USBDevice].host
            $USBDeviceLine | Add-Member -Name "Partition State"    -MemberType Noteproperty -Value $Json.child[$USBDevice].state
            $USBDeviceLine | Add-Member -Name "Space Used (Octet)" -MemberType Noteproperty -Value $Json.child[$USBDevice].used
            $USBDeviceLine | Add-Member -Name "Space Total (Octet)"-MemberType Noteproperty -Value $Json.child[$USBDevice].total
            $USBDeviceLine | Add-Member -Name "Space Free (Octet)" -MemberType Noteproperty -Value $($Json.child[$USBDevice].total - $Json.child[$USBDevice].used)
            
            # Add lines to $Array
            $Array += $USBDeviceLine
            
            # Go to next line
            $USBDevice ++
        }
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-DeviceUSBPrinter {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.printer
        
    If($Json.printer.count -ne "0"){  
        
        $USBPrinter = 0
        
        While($USBPrinter -lt ($Json.Count)){
            
            # Create New PSObject and add values to array
            $PrinterLine = New-Object -TypeName PSObject
            $PrinterLine | Add-Member -Name "Index"        -MemberType Noteproperty -Value $Json[$USBPrinter].index
            $PrinterLine | Add-Member -Name "Name"         -MemberType Noteproperty -Value $Json[$USBPrinter].name
            $PrinterLine | Add-Member -Name "Description"  -MemberType Noteproperty -Value $Json[$USBPrinter].description
            $PrinterLine | Add-Member -Name "Manufacturer" -MemberType Noteproperty -Value $Json[$USBPrinter].manufacturer
            $PrinterLine | Add-Member -Name "Product"      -MemberType Noteproperty -Value $Json[$USBPrinter].product
            $PrinterLine | Add-Member -Name "State"        -MemberType Noteproperty -Value (Get-state -State $Json[$USBPrinter].state)
            
            # Add lines to $Array
            $Array += $PrinterLine
            
            # Go to next line
            $USBPrinter ++
        }
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-USBStorage {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.file_info
    
    If($Json.file_info.count -ne "0"){
    
        $USBStorage = 0
        
        While($USBStorage -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $USBStorageLine = New-Object -TypeName PSObject
            $USBStorageLine | Add-Member -Name "Path"         -MemberType Noteproperty -Value $Json[$USBStorage].path
            $USBStorageLine | Add-Member -Name "Size"         -MemberType Noteproperty -Value $Json[$USBStorage].size
            $USBStorageLine | Add-Member -Name "Preview Type" -MemberType Noteproperty -Value $Json[$USBStorage].preview_type
            $USBStorageLine | Add-Member -Name "Hash"         -MemberType Noteproperty -Value $Json[$USBStorage].hash
            $USBStorageLine | Add-Member -Name "Type"         -MemberType Noteproperty -Value (Get-USBFolderType -USBFolderType $($Json[$USBStorage].type))
            $USBStorageLine | Add-Member -Name "Icon"         -MemberType Noteproperty -Value $Json[$USBStorage].icon
            $USBStorageLine | Add-Member -Name "Bytes"        -MemberType Noteproperty -Value $Json[$USBStorage].bytes
            
            # Add lines to $Array
            $Array += $USBStorageLine
            
            # Go to next line
            $USBStorage ++
        }
        Return $Array
    }
    Else{
        Return $null
    }
}

#endregion USB

#region VOIP

Function Get-VOIP {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $VOIPLine = New-Object -TypeName PSObject
    $VOIPLine | Add-Member -Name "Phone line index"             -MemberType Noteproperty -Value $Json.id
    $VOIPLine | Add-Member -Name "Status"                       -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $VOIPLine | Add-Member -Name "Call State"                   -MemberType Noteproperty -Value $Json.callstate
    $VOIPLine | Add-Member -Name "SIP Phone Number"             -MemberType Noteproperty -Value $Json.uri
    $VOIPLine | Add-Member -Name "Anonymous call Blocked State" -MemberType Noteproperty -Value $Json.blockstate
    $VOIPLine | Add-Member -Name "Anonymous Call State"         -MemberType Noteproperty -Value (Get-State -State $Json.anoncallstate)
    $VOIPLine | Add-Member -Name "Is Voice Mail waiting ?"      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.mwi)
    $VOIPLine | Add-Member -Name "Voice Mail Count waiting"     -MemberType Noteproperty -Value $Json.message_count
    $VOIPLine | Add-Member -Name "Missed call"                  -MemberType Noteproperty -Value $Json.notanswered
    
    # Add lines to $Array
    $Array += $VOIPLine
    
    Return $Array
}

Function Get-VOIPDiag {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.phy_interface
    
    If($Json.Count -ne 0){
        
        $VOIPID = 0
        
        While($VOIPID -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $VOIPLine = New-Object -TypeName PSObject
            $VOIPLine | Add-Member -Name "Phone Line ID"    -MemberType Noteproperty -Value $Json[$VOIPID].ring_test.id
            $VOIPLine | Add-Member -Name "Ring Test Status" -MemberType Noteproperty -Value $Json[$VOIPID].ring_test.status
            $VOIPLine | Add-Member -Name "Echo Test Status" -MemberType Noteproperty -Value $Json[$VOIPID].echo_test.status
            
            # Add lines to $Array
            $Array += $VOIPLine
            
            # Go to next line
            $VOIPID ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-VOIPDiagHost {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.host
    
    If($Json.Count -ne 0){
        
        $Device = 0
        
        While($Device -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $DeviceLine = New-Object -TypeName PSObject
            $DeviceLine | Add-Member -Name "ID"          -MemberType Noteproperty -Value $Json[$Device].id
            $DeviceLine | Add-Member -Name "Hostname"    -MemberType Noteproperty -Value $Json[$Device].hostname
            $DeviceLine | Add-Member -Name "IP Address"  -MemberType Noteproperty -Value $Json[$Device].ipaddress
            $DeviceLine | Add-Member -Name "MAC Address" -MemberType Noteproperty -Value $Json[$Device].macaddress
            $DeviceLine | Add-Member -Name "State"       -MemberType Noteproperty -Value (Get-State -State $Json[$Device].active)
            
            # Add lines to $Array
            $Array += $DeviceLine
            
            # Go to next line
            $Device ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-VOIPDiagUSB {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.usb
    
    If($Json.Count -ne 0){
        
        $USB = 0
        
        While($USB -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $USBLine = New-Object -TypeName PSObject
            $USBLine | Add-Member -Name "ID"          -MemberType Noteproperty -Value $Json[$USB].index
            $USBLine | Add-Member -Name "Identify "   -MemberType Noteproperty -Value $Json[$USB].ident
            $USBLine | Add-Member -Name "UUID"        -MemberType Noteproperty -Value $Json[$USB].uuid
            $USBLine | Add-Member -Name "Label"       -MemberType Noteproperty -Value $Json[$USB].label
            $USBLine | Add-Member -Name "Name"        -MemberType Noteproperty -Value $Json[$USB].name
            $USBLine | Add-Member -Name "Description" -MemberType Noteproperty -Value $Json[$USB].description
            
            # Add lines to $Array
            $Array += $USBLine
            
            # Go to next line
            $USB ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-VOIPScheduler {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.voip.scheduler
    
    # Create New PSObject and add values to array
    $SchedulerLine = New-Object -TypeName PSObject
    $SchedulerLine | Add-Member -Name "Date"           -MemberType Noteproperty -Value $(Format-Date -String $Json.now)
    $SchedulerLine | Add-Member -Name "State"          -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $SchedulerLine | Add-Member -Name "Unbloked ?"     -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.unblock)
    $SchedulerLine | Add-Member -Name "Status"         -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $SchedulerLine | Add-Member -Name "Status Until"   -MemberType Noteproperty -Value $(Format-Date -String $Json.statusuntil)
    $SchedulerLine | Add-Member -Name "Time Remaining" -MemberType Noteproperty -Value "$([Math]::Floor($Json.statusremaining/3600))h$([Math]::Ceiling($Json.statusremaining/3600))s"
    $SchedulerLine | Add-Member -Name "Rules"          -MemberType Noteproperty -Value $Json.rules.count # Since Version 19.2.12

    # Add lines to $Array
    $Array += $SchedulerLine
    
    Return $Array
}

Function Get-VOIPSchedulerRules {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.voip.scheduler.rules
    
    If($Json.Count -ne 0){
        
        $Rule = 0
        
        While($Rule -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name "ID"    -MemberType Noteproperty -Value $Json[$Rule].id
            $RuleLine | Add-Member -Name "State" -MemberType Noteproperty -Value (Get-State -State $Json[$Rule].enable)
            $RuleLine | Add-Member -Name "Start" -MemberType Noteproperty -Value "$($Json[$Rule].start.day) at $($Json[$Rule].start.hour):$($Json[$Rule].start.minute)"
            $RuleLine | Add-Member -Name "End"   -MemberType Noteproperty -Value "$($Json[$Rule].end.day) at $($Json[$Rule].end.hour):$($Json[$Rule].end.minute)"
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-VOIPCallLogLineX {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.calllog
    
    If($Json.Count -ne 0){
        
        $Call = 0
        
        While($Call -lt $Json.Count){
            
            # Calculate call time
            $CallTime = New-TimeSpan -Seconds $($Json[$Call].duree)
            
            # Create New PSObject and add values to array
            $CallLine = New-Object -TypeName PSObject
            $CallLine | Add-Member -Name "ID"             -MemberType Noteproperty -Value $Json[$Call].id
            $CallLine | Add-Member -Name "Number"         -MemberType Noteproperty -Value $Json[$Call].number
            $CallLine | Add-Member -Name "Date"           -MemberType Noteproperty -Value (Format-Date1970 -Seconds $Json[$Call].date)
            $CallLine | Add-Member -Name "Call Type"      -MemberType Noteproperty -Value (Get-VoiceCallType -VoiceCallType $Json[$Call].type)
            $CallLine | Add-Member -Name "Was Answered ?" -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Call].answered)
            $CallLine | Add-Member -Name "Call Time"      -MemberType Noteproperty -Value "$($CallTime.Hours)h$($CallTime.Minutes)m$($CallTime.Seconds)s"
            
            # Add lines to $Array
            $Array += $CallLine
            
            # Go to next line
            $Call ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-VOIPFullCallLogLineX {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.fullcalllog
    
    If($Json.Count -ne 0){
        
        $Call = 0
        
        While($Call -lt $Json.Count){
            
            # Calculate call time
            $CallTime = New-TimeSpan -Seconds $($Json[$Call].duree)
            
            # Create New PSObject and add values to array
            $CallLine = New-Object -TypeName PSObject
            $CallLine | Add-Member -Name "ID"             -MemberType Noteproperty -Value $Json[$Call].id
            $CallLine | Add-Member -Name "Number"         -MemberType Noteproperty -Value $Json[$Call].number
            $CallLine | Add-Member -Name "Date"           -MemberType Noteproperty -Value (Format-Date1970 -Seconds $Json[$Call].date)
            $CallLine | Add-Member -Name "Call Type"      -MemberType Noteproperty -Value (Get-VoiceCallType -VoiceCallType $Json[$Call].type)
            $CallLine | Add-Member -Name "Was Answered ?" -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Call].answered)
            $CallLine | Add-Member -Name "Call Time"      -MemberType Noteproperty -Value "$($CallTime.Hours)h$($CallTime.Minutes)m$($CallTime.Seconds)s"
            
            # Add lines to $Array
            $Array += $CallLine
            
            # Go to next line
            $Call ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-VOIPAllowedListNumber {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.voip.scheduler
    
    If($Json.Count -ne 0){
        
        $Number = 0
        
        While($Number -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $NumberLine = New-Object -TypeName PSObject
            $NumberLine | Add-Member -Name "ID"     -MemberType Noteproperty -Value $Json[$Number].id
            $NumberLine | Add-Member -Name "Number" -MemberType Noteproperty -Value $Json[$Number].number
            
            # Add lines to $Array
            $Array += $NumberLine
            
            # Go to next line
            $Number ++
        }
        
        Return $Array
    }
    Else{
        Return $null
    }
}

#endregion VOIP

#region WAN

Function Get-WANAutowan {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create arrays
    $Device = @()
    $ProfileWan = @()
    $Profiles = @()
    $Services = @()
    
    # Select $JSON header
    $Json = $Json.autowan
    
    # Device part
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name "Model"            -MemberType Noteproperty -Value $Json.device.model
    $DeviceLine | Add-Member -Name "Firmware Version" -MemberType Noteproperty -Value $Json.device.firmware.main
    $DeviceLine | Add-Member -Name "Firmware Date"    -MemberType Noteproperty -Value (Format-Date -String $Json.device.firmware.date)
    $DeviceLine | Add-Member -Name "WAN IP Address"   -MemberType Noteproperty -Value $Json.ip.address
    $DeviceLine | Add-Member -Name "WAN Bytel DNS"    -MemberType Noteproperty -Value "static-$(($Json.ip.address).replace("-","-")).ftth.abo.bbox.fr" # Not included in API
    
    # Add lines to $Array
    $Device += $DeviceLine
    
    
    # Profile part
    # Create New PSObject and add values to array
    $ProfileLine = New-Object -TypeName PSObject
    $ProfileLine | Add-Member -Name "Profile Name"          -MemberType Noteproperty -Value $Json.Profile.device
    $ProfileActive = $Json.Profile.active -split ","
    $ProfileLine | Add-Member -Name "Active Profile Chanel" -MemberType Noteproperty -Value $ProfileActive[0]
    $ProfileLine | Add-Member -Name "Active Profile Name"   -MemberType Noteproperty -Value $ProfileActive[1]
    
    # Add lines to $Array
    $ProfileWan += $ProfileLine
    
    
    # Profiles part
    If($Json.Profiles.Count -ne 0){
        
        $Line = 0
        
        While($Line -lt  $Json.Profiles.Count){
            
            # Create New PSObject and add values to array
            $ProfilesLine = New-Object -TypeName PSObject
            $ProfilesLine | Add-Member -Name "Index"     -MemberType Noteproperty -Value $Json.Profiles[$Line].index
            $ProfilesLine | Add-Member -Name "Name"      -MemberType Noteproperty -Value $Json.Profiles[$Line].name
            $ProfilesLine | Add-Member -Name "Flags"     -MemberType Noteproperty -Value $Json.Profiles[$Line].flags
            $ProfilesLine | Add-Member -Name "State"     -MemberType Noteproperty -Value (Get-State -State $Json.Profiles[$Line].state)
            $ProfilesLine | Add-Member -Name "Success"   -MemberType Noteproperty -Value $Json.Profiles[$Line].success
            $ProfilesLine | Add-Member -Name "Failure"   -MemberType Noteproperty -Value $Json.Profiles[$Line].failure
            $ProfilesLine | Add-Member -Name "Timeout"   -MemberType Noteproperty -Value $Json.Profiles[$Line].timeout
            $ProfilesLine | Add-Member -Name "Fallback"  -MemberType Noteproperty -Value $Json.Profiles[$Line].fallback
            $ProfilesLine | Add-Member -Name "Starttime" -MemberType Noteproperty -Value $Json.Profiles[$Line].starttime
            $ProfilesLine | Add-Member -Name "Tostart"   -MemberType Noteproperty -Value $Json.Profiles[$Line].tostart
            $ProfilesLine | Add-Member -Name "Toip"      -MemberType Noteproperty -Value $Json.Profiles[$Line].toip
            $ProfilesLine | Add-Member -Name "Todns"     -MemberType Noteproperty -Value $Json.Profiles[$Line].todns
            $ProfilesLine | Add-Member -Name "Totr069"   -MemberType Noteproperty -Value $Json.Profiles[$Line].totr069
            $ProfilesLine | Add-Member -Name "Torunning" -MemberType Noteproperty -Value $Json.Profiles[$Line].torunning
            $ProfilesLine | Add-Member -Name "Laststop"  -MemberType Noteproperty -Value $Json.Profiles[$Line].laststop
            
            # Add lines to $Array
            $Profiles += $ProfilesLine
            
            # Go to next line
            $Line ++
        }
    }
    Else{
        $Profiles = $null
    }
    
    # Services part
    # Create New PSObject and add values to array
    $ServicesLine = New-Object -TypeName PSObject
    $ServicesLine | Add-Member -Name "IGMP" -MemberType Noteproperty -Value (Get-State -State $Json.Services.igmp)
    $ServicesLine | Add-Member -Name "VOIP" -MemberType Noteproperty -Value (Get-State -State $Json.Services.voip)
    
    # Add lines to $Array
    $Services += $ServicesLine
    
    Return $Device, $Profile, $Profiles, $Services
}

Function Get-WANDiags {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create arrays
    $Array = @()
    $DNSArray = @()
    $HTTPArray = @()
    $PingArray = @()
    
    # Select $JSON header
    $Json = $Json.diags
    
    # DNS Diags Part
    $DNS = 0
    While($DNS -lt $Json.dns.Count){
        
        # Create New PSObject and add values to array
        $DNSLine = New-Object -TypeName PSObject
        $DNSLine | Add-Member -Name "DNS Min"      -MemberType Noteproperty -Value $Json.dns[$DNS].min
        $DNSLine | Add-Member -Name "DNS Max"      -MemberType Noteproperty -Value $Json.dns[$DNS].max
        $DNSLine | Add-Member -Name "DNS Average"  -MemberType Noteproperty -Value $Json.dns[$DNS].average
        $DNSLine | Add-Member -Name "DNS Success"  -MemberType Noteproperty -Value $Json.dns[$DNS].success
        $DNSLine | Add-Member -Name "DNS Error"    -MemberType Noteproperty -Value $Json.dns[$DNS].error
        $DNSLine | Add-Member -Name "DNS Tries"    -MemberType Noteproperty -Value $Json.dns[$DNS].tries
        $DNSLine | Add-Member -Name "DNS Status"   -MemberType Noteproperty -Value $Json.dns[$DNS].status
        $DNSLine | Add-Member -Name "DNS Protocol" -MemberType Noteproperty -Value $Json.dns[$DNS].protocol
        
        # Add lines to $Array
        $DNSArray += $DNSLine
        
        # Go to next line
        $DNS ++
    }
    
    # HTTP Diags Part
    $HTTP = 0
    While($HTTP -lt $Json.HTTP.Count){
        
        # Create New PSObject and add values to array
        $HTTPLine = New-Object -TypeName PSObject
        $HTTPLine | Add-Member -Name "HTTP Min"      -MemberType Noteproperty -Value $Json.HTTP[$HTTP].min
        $HTTPLine | Add-Member -Name "HTTP Max"      -MemberType Noteproperty -Value $Json.HTTP[$HTTP].max
        $HTTPLine | Add-Member -Name "HTTP Average"  -MemberType Noteproperty -Value $Json.HTTP[$HTTP].average
        $HTTPLine | Add-Member -Name "HTTP Success"  -MemberType Noteproperty -Value $Json.HTTP[$HTTP].success
        $HTTPLine | Add-Member -Name "HTTP Error"    -MemberType Noteproperty -Value $Json.HTTP[$HTTP].error
        $HTTPLine | Add-Member -Name "HTTP Tries"    -MemberType Noteproperty -Value $Json.HTTP[$HTTP].tries
        $HTTPLine | Add-Member -Name "HTTP Status"   -MemberType Noteproperty -Value $Json.HTTP[$HTTP].status
        $HTTPLine | Add-Member -Name "HTTP Protocol" -MemberType Noteproperty -Value $Json.HTTP[$HTTP].protocol
        
        # Add lines to $Array
        $HTTPArray += $HTTPLine
        
        # Go to next line
        $HTTP ++
    }
    
    # Ping Diags Part
        $Ping = 0
    While($Ping -lt $Json.Ping.Count){
        
        # Create New PSObject and add values to array
        $PingLine = New-Object -TypeName PSObject
        $PingLine | Add-Member -Name "Ping Min"      -MemberType Noteproperty -Value $Json.Ping[$Ping].min
        $PingLine | Add-Member -Name "Ping Max"      -MemberType Noteproperty -Value $Json.Ping[$Ping].max
        $PingLine | Add-Member -Name "Ping Average"  -MemberType Noteproperty -Value $Json.Ping[$Ping].average
        $PingLine | Add-Member -Name "Ping Success"  -MemberType Noteproperty -Value $Json.Ping[$Ping].success
        $PingLine | Add-Member -Name "Ping Error"    -MemberType Noteproperty -Value $Json.Ping[$Ping].error
        $PingLine | Add-Member -Name "Ping Tries"    -MemberType Noteproperty -Value $Json.Ping[$Ping].tries
        $PingLine | Add-Member -Name "Ping Status"   -MemberType Noteproperty -Value $Json.Ping[$Ping].status
        $PingLine | Add-Member -Name "Ping Protocol" -MemberType Noteproperty -Value $Json.Ping[$Ping].protocol
        
        # Add lines to $Array
        $PingArray += $PingLine
        
        # Go to next line
        $Ping ++
    }
    
    $Temp = New-Object -TypeName PSObject
    $Temp | Add-Member -Name "DNS"  -MemberType Noteproperty -Value $DNSArray
    $Temp | Add-Member -Name "HTTP" -MemberType Noteproperty -Value $HTTPArray
    $Temp | Add-Member -Name "PING" -MemberType Noteproperty -Value $PingArray
    $Array = $Temp
    
    Return $Array
}

Function Get-WANDiagsSessions {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Calculate Nb current TCP/UDP IP Sessions
    If($Json.hosts.Count){
        
        $TCP_Sessions = $null
        $UDP_Sessions = $null
        $Line = 0
        
        While($Line -lt $Json.hosts.Count){
            
            $TCP_Sessions += $Json.hosts[$Line].currenttcp
            $UDP_Sessions += $Json.hosts[$Line].currentudp
            
            # Go to next line
            $Line ++
        }
        
        # Create New PSObject and add values to array
        $SessionsLine = New-Object -TypeName PSObject
        $SessionsLine | Add-Member -Name "Nb Hosts With Opened Sessions"       -MemberType Noteproperty -Value $Json.hosts.Count
        $SessionsLine | Add-Member -Name "Total current IP sessions"           -MemberType Noteproperty -Value $Json.currentip
        $SessionsLine | Add-Member -Name "Average current IP sessions by host" -MemberType Noteproperty -Value $($Json.currentip / $Json.hosts.Count) # Not included vith API
        $SessionsLine | Add-Member -Name "Total TCP IP sessions"               -MemberType Noteproperty -Value $TCP_Sessions
        $SessionsLine | Add-Member -Name "Total UDP IP sessions"               -MemberType Noteproperty -Value $UDP_Sessions
        $SessionsLine | Add-Member -Name "Total ICMP IP sessions"              -MemberType Noteproperty -Value $($Json.currentip - ($TCP_Sessions + $UDP_Sessions))
        $SessionsLine | Add-Member -Name "TCP Timeout"                         -MemberType Noteproperty -Value $Json.tcptimeout
        $SessionsLine | Add-Member -Name "High Threshold"                      -MemberType Noteproperty -Value $Json.highthreshold
        $SessionsLine | Add-Member -Name "Low Threshold"                       -MemberType Noteproperty -Value $Json.lowthreshold
        $SessionsLine | Add-Member -Name "Update Date"                         -MemberType Noteproperty -Value $(Format-Date -String $Json.updatedate)
        $SessionsLine | Add-Member -Name "Nb Page"                             -MemberType Noteproperty -Value $Json.pages
        $SessionsLine | Add-Member -Name "Nb Result Per Page"                  -MemberType Noteproperty -Value $Json.resultperpage
        
        # Add lines to $Array
        $Array += $SessionsLine
        
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-WANDiagsSummaryHostsActiveSessions {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    If($Json.Count -ne 0){
        
        $Line = 0
        
        While($Line -lt $Json.hosts.Count){
            
            # Create New PSObject and add values to array
            $SessionsLine = New-Object -TypeName PSObject
            $SessionsLine | Add-Member -Name "Host IP Address"             -MemberType Noteproperty -Value $Json.hosts[$Line].ip
            $SessionsLine | Add-Member -Name "All Current Opened Sessions" -MemberType Noteproperty -Value $Json.hosts[$Line].currentip
            $SessionsLine | Add-Member -Name "TCP Current Opened Sessions" -MemberType Noteproperty -Value $Json.hosts[$Line].currenttcp
            $SessionsLine | Add-Member -Name "UDP Current Opened Sessions" -MemberType Noteproperty -Value $Json.hosts[$Line].currentudp
            
            # Add lines to $Array
            $Array += $SessionsLine
            
            # Go to next line
            $Line ++
        }
        
        Return $Array
	}
    Else{
        Return $null
    }
}

Function Get-WANDiagsAllActiveSessions {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Create array
    $Array = @()
    
    $NbPages = $(Get-BBoxInformation -UrlToGo $UrlToGo).pages + 1
    $Currentpage = 1
    
    While($Currentpage -ne $NbPages){
        
        $SessionPage = "$UrlToGo/$Currentpage"
        $Date = Get-Date
        # Get information from BBOX API
        $Json = Get-BBoxInformation -UrlToGo $SessionPage
        $Line = 0
        
        While($Line -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $SessionLine = New-Object -TypeName PSObject
            $SessionLine | Add-Member -Name "Source IP Address"      -MemberType Noteproperty -Value $Json[$Line].srcip
            $SessionLine | Add-Member -Name "Source Port"            -MemberType Noteproperty -Value $Json[$Line].srcport
            $SessionLine | Add-Member -Name "Destination IP Address" -MemberType Noteproperty -Value $Json[$Line].dstip
            $SessionLine | Add-Member -Name "Destination Port"       -MemberType Noteproperty -Value $Json[$Line].dstport
            $SessionLine | Add-Member -Name "Protocol"               -MemberType Noteproperty -Value $Json[$Line].proto
            $SessionLine | Add-Member -Name "Expire at"              -MemberType Noteproperty -Value ($Date.AddSeconds($Json[$Line].expirein))
            $SessionLine | Add-Member -Name "Action Type"            -MemberType Noteproperty -Value $Json[$Line].type
            
            # Add lines to $Array
            $Array += $SessionLine
            
            # Go to next line
            $Line ++
        }
        
        # Go to next line
        $Currentpage ++
    }
    
    Return $Array
}

Function Get-WANDiagsAllActiveSessionsHost {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $AllActiveSessions = Get-WANDiagsAllActiveSessions -UrlToGo $UrlToGo
    $HostID = $AllActiveSessions | Select-Object "Source IP Address" -Unique | Out-GridView -Title "Active Session Hosts List" -OutputMode Single
    $HostAllActiveSessions = $AllActiveSessions | Where-Object {($_."Source IP Address" -ilike $HostID.'Source IP Address') -or ($_."Destination IP Address" -ilike $HostID.'Source IP Address')}
    
    Return $HostAllActiveSessions
}

Function Get-WANFTTHStats {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wan.ftth
    
    # Create New PSObject and add values to array
    $FTTHLine = New-Object -TypeName PSObject
    $FTTHLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "FTTH"
    $FTTHLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $FTTHLine | Add-Member -Name "Mode"    -MemberType Noteproperty -Value $Json.mode
    
    # Add lines to $Array
    $Array += $FTTHLine
    
    Return $Array
}

Function Get-WANIP {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wan
    
    # Create New PSObject and add values to array
    $IPLine = New-Object -TypeName PSObject
    $IPLine | Add-Member -Name "Internet State"                    -MemberType Noteproperty -Value (Get-State -State $Json.internet.state)
    $IPLine | Add-Member -Name "Interface ID"                      -MemberType Noteproperty -Value $Json.interface.id
    $IPLine | Add-Member -Name "Interface Default configuration ?" -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.interface.default)
    $IPLine | Add-Member -Name "Interface State"                   -MemberType Noteproperty -Value (Get-State -State $Json.interface.state)
    $IPLine | Add-Member -Name "Carrier-grade NAT Enable ?"        -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ip.cgnatenable)
    $IPLine | Add-Member -Name "WAN State"                         -MemberType Noteproperty -Value (Get-State -State $Json.ip.state)
    $IPLine | Add-Member -Name "WAN IP Address Assigned"           -MemberType Noteproperty -Value $Json.ip.address
    $IPLine | Add-Member -Name "WAN Subnet"                        -MemberType Noteproperty -Value $Json.ip.subnet
    $IPLine | Add-Member -Name "WAN Gateway"                       -MemberType Noteproperty -Value $Json.ip.gateway
    $IPLine | Add-Member -Name "WAN DNS Servers"                   -MemberType Noteproperty -Value $Json.ip.dnsservers
    $IPLine | Add-Member -Name "WAN MAC Address"                   -MemberType Noteproperty -Value $Json.ip.mac
    $IPLine | Add-Member -Name "WAN MTU"                           -MemberType Noteproperty -Value $Json.ip.mtu
    $IPLine | Add-Member -Name "WAN IPV6 State"                    -MemberType Noteproperty -Value (Get-State -State $Json.ip.ip6state)
    
    If($Json.ip.ip6address){
        $IPLine | Add-Member -Name "WAN IPV6 Address"              -MemberType Noteproperty -Value $Json.ip.ip6address.ipaddress
        $IPLine | Add-Member -Name "WAN IPV6 Status"               -MemberType Noteproperty -Value (Get-Status -Status $Json.ip.ip6address.status)
        $IPLine | Add-Member -Name "WAN IPV6 Valid"                -MemberType Noteproperty -Value $(Format-Date -String $Json.ip.ip6address.valid)
        $IPLine | Add-Member -Name "WAN IPV6 Preferred"            -MemberType Noteproperty -Value $(Format-Date -String $Json.ip.ip6address.preferred)
    }
    Else{
        $IPLine | Add-Member -Name "WAN IPV6 Address"              -MemberType Noteproperty -Value ""
        $IPLine | Add-Member -Name "WAN IPV6 Status"               -MemberType Noteproperty -Value ""
        $IPLine | Add-Member -Name "WAN IPV6 Valid"                -MemberType Noteproperty -Value ""
        $IPLine | Add-Member -Name "WAN IPV6 Preferred"            -MemberType Noteproperty -Value ""
    }
    If($Json.ip.ip6prefix){
        $IPLine | Add-Member -Name "WAN IPV6 Prefix"               -MemberType Noteproperty -Value $Json.ip.ip6prefix.prefix
        $IPLine | Add-Member -Name "WAN IPV6 Prefix Status"        -MemberType Noteproperty -Value (Get-Status -Status $Json.ip.ip6prefix.status)
        $IPLine | Add-Member -Name "WAN IPV6 Prefix Valid"         -MemberType Noteproperty -Value $(Format-Date -String $Json.ip.ip6prefix.valid)
        $IPLine | Add-Member -Name "WAN IPV6 Prefix Preferred"     -MemberType Noteproperty -Value $(Format-Date -String $Json.ip.ip6prefix.preferred)
    }
    Else{
        $IPLine | Add-Member -Name "WAN IPV6 Prefix"               -MemberType Noteproperty -Value ""
        $IPLine | Add-Member -Name "WAN IPV6 Prefix Status"        -MemberType Noteproperty -Value ""
        $IPLine | Add-Member -Name "WAN IPV6 Prefix Valid"         -MemberType Noteproperty -Value ""
        $IPLine | Add-Member -Name "WAN IPV6 Prefix Preferred"     -MemberType Noteproperty -Value ""
    }

    $IPLine | Add-Member -Name "Link State"                        -MemberType Noteproperty -Value (Get-State -State $Json.link.state)
    $IPLine | Add-Member -Name "Link Type"                         -MemberType Noteproperty -Value $Json.link.type
    
    # Add lines to $Array
    $Array += $IPLine
    
    Return $Array
}

Function Get-WANIPStats {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wan.ip.stats
    
    # Create New PSObject and add values to array
    $StatsLine = New-Object -TypeName PSObject
    
    # RX
    $StatsLine | Add-Member -Name "RX-Bytes"           -MemberType Noteproperty -Value $Json.rx.bytes
    $StatsLine | Add-Member -Name "RX-Packets"         -MemberType Noteproperty -Value $Json.rx.packets
    $StatsLine | Add-Member -Name "RX-PacketsErrors"   -MemberType Noteproperty -Value $Json.rx.packetserrors
    $StatsLine | Add-Member -Name "RX-PacketsDiscards" -MemberType Noteproperty -Value $Json.rx.packetsdiscards
    $StatsLine | Add-Member -Name "RX-Occupation"      -MemberType Noteproperty -Value $Json.rx.occupation
    $StatsLine | Add-Member -Name "RX-Bandwidth"       -MemberType Noteproperty -Value $Json.rx.bandwidth
    $StatsLine | Add-Member -Name "RX-MaxBandwidth"    -MemberType Noteproperty -Value $Json.rx.maxBandwidth
    
    # TX
    $StatsLine | Add-Member -Name "TX-Bytes"           -MemberType Noteproperty -Value $Json.tx.bytes
    $StatsLine | Add-Member -Name "TX-Packets"         -MemberType Noteproperty -Value $Json.tx.packets
    $StatsLine | Add-Member -Name "TX-PacketsErrors"   -MemberType Noteproperty -Value $Json.tx.packetserrors
    $StatsLine | Add-Member -Name "TX-PacketsDiscards" -MemberType Noteproperty -Value $Json.tx.packetsdiscards
    $StatsLine | Add-Member -Name "TX-Occupation"      -MemberType Noteproperty -Value $Json.tx.occupation
    $StatsLine | Add-Member -Name "TX-Bandwidth"       -MemberType Noteproperty -Value $Json.tx.bandwidth
    $StatsLine | Add-Member -Name "TX-MaxBandwidth"    -MemberType Noteproperty -Value $Json.tx.maxBandwidth    
    
    # Add lines to $Array
    $Array += $StatsLine
    
    Return $Array
}

Function Get-WANXDSL {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wan.xdsl
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name "Service"               -MemberType Noteproperty -Value "XDSL"
    $DeviceLine | Add-Member -Name "State"                 -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $DeviceLine | Add-Member -Name "Modulation"            -MemberType Noteproperty -Value $Json.modulation
    $DeviceLine | Add-Member -Name "Show Time"             -MemberType Noteproperty -Value $Json.showtime
    $DeviceLine | Add-Member -Name "ATUR Provider"         -MemberType Noteproperty -Value $Json.atur_provider
    $DeviceLine | Add-Member -Name "ATUC Provider"         -MemberType Noteproperty -Value $Json.atuc_provider
    $DeviceLine | Add-Member -Name "Synchronisation Count" -MemberType Noteproperty -Value $Json.sync_count
    $DeviceLine | Add-Member -Name "Up Bitrates"           -MemberType Noteproperty -Value $Json.up.bitrates
    $DeviceLine | Add-Member -Name "Up Noise"              -MemberType Noteproperty -Value $Json.up.noise
    $DeviceLine | Add-Member -Name "Up Attenuation"        -MemberType Noteproperty -Value $Json.up.attenuation
    $DeviceLine | Add-Member -Name "Up Power"              -MemberType Noteproperty -Value $Json.up.power
    $DeviceLine | Add-Member -Name "Up Phyr"               -MemberType Noteproperty -Value $Json.up.phyr
    $DeviceLine | Add-Member -Name "Up GINP"               -MemberType Noteproperty -Value $Json.up.ginp
    $DeviceLine | Add-Member -Name "Up Nitro"              -MemberType Noteproperty -Value $Json.up.nitro
    $DeviceLine | Add-Member -Name "Up Interleave Delay"   -MemberType Noteproperty -Value $Json.up.interleave_delay
    $DeviceLine | Add-Member -Name "Down Bitrates"         -MemberType Noteproperty -Value $Json.down.bitrates
    $DeviceLine | Add-Member -Name "Down Noise"            -MemberType Noteproperty -Value $Json.down.noise
    $DeviceLine | Add-Member -Name "Down Attenuation"      -MemberType Noteproperty -Value $Json.down.attenuation
    $DeviceLine | Add-Member -Name "Down Power"            -MemberType Noteproperty -Value $Json.down.power
    $DeviceLine | Add-Member -Name "Down Phyr"             -MemberType Noteproperty -Value $Json.down.phyr
    $DeviceLine | Add-Member -Name "Down GINP"             -MemberType Noteproperty -Value $Json.down.ginp
    $DeviceLine | Add-Member -Name "Down Nitro"            -MemberType Noteproperty -Value $Json.down.nitro
    $DeviceLine | Add-Member -Name "Down Interleave Delay" -MemberType Noteproperty -Value $Json.down.interleave_delay
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

Function Get-WANXDSLStats {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wan.xdsl.stats
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name "Local CRC"  -MemberType Noteproperty -Value $Json.local_crc
    $DeviceLine | Add-Member -Name "Local FEC"  -MemberType Noteproperty -Value $Json.local_fec
    $DeviceLine | Add-Member -Name "Local HEC"  -MemberType Noteproperty -Value $Json.local_hec
    $DeviceLine | Add-Member -Name "Remote CRC" -MemberType Noteproperty -Value $Json.remote_crc
    $DeviceLine | Add-Member -Name "Remote FEC" -MemberType Noteproperty -Value $Json.remote_fec
    $DeviceLine | Add-Member -Name "Remote HEC" -MemberType Noteproperty -Value $Json.remote_hec
    
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

#endregion WAN

#region WIRELESS

Function Get-WIRELESS {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $WIRELESSLine = New-Object -TypeName PSObject
    $WIRELESSLine | Add-Member -Name "Service"                      -MemberType Noteproperty -Value $APIName
    $WIRELESSLine | Add-Member -Name "Status"                       -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $WIRELESSLine | Add-Member -Name "Extended Character SSID"      -MemberType Noteproperty -Value $Json.extended_character_ssid # Since Version : 20.2.32
    $WIRELESSLine | Add-Member -Name "Driver Busy"                  -MemberType Noteproperty -Value $Json.driverbusy # Since Version : 20.2.32
    $WIRELESSLine | Add-Member -Name "WIFI Unified Active ?"        -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.unified)
    $WIRELESSLine | Add-Member -Name "WIFI Unify Available ?"       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.unified_available)
    $WIRELESSLine | Add-Member -Name "Is Default 24Ghz Config"      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.isDefault24) # Since Version : 19.2.12
    $WIRELESSLine | Add-Member -Name "Is Default 5Ghz Config"       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.isDefault5) # Since Version : 19.2.12
    $WIRELESSLine | Add-Member -Name "WIFI Scheduled Status"        -MemberType Noteproperty -Value "$(Get-State -State $Json.scheduler.enable) at date $($Json.scheduler.now)"
    
    # 2,4 Ghz
    $WIRELESSLine | Add-Member -Name "2,4Ghz Status"                -MemberType Noteproperty -Value (Get-State -State  $Json.radio."24".enable)
    $WIRELESSLine | Add-Member -Name "2,4Ghz State"                 -MemberType Noteproperty -Value (Get-State -State $Json.radio."24".state)
    $WIRELESSLine | Add-Member -Name "2,4Ghz Radio Type List"       -MemberType Noteproperty -Value $($Json.standard."24".value -join ",")
    $WIRELESSLine | Add-Member -Name "2,4Ghz Type"                  -MemberType Noteproperty -Value $Json.radio."24".standard
    $WIRELESSLine | Add-Member -Name "2,4Ghz Current Channel"       -MemberType Noteproperty -Value $Json.radio."24".current_channel
    $WIRELESSLine | Add-Member -Name "2,4Ghz Channel"               -MemberType Noteproperty -Value $Json.radio."24".channel
    $WIRELESSLine | Add-Member -Name "2,4Ghz Channel Width"         -MemberType Noteproperty -Value $Json.radio."24".htbw
    
    $WIRELESSLine | Add-Member -Name "2,4Ghz SSID State"            -MemberType Noteproperty -Value (Get-State -State $Json.ssid."24".enable)
    $WIRELESSLine | Add-Member -Name "2,4Ghz SSID Name"             -MemberType Noteproperty -Value $Json.ssid."24".id
    $WIRELESSLine | Add-Member -Name "2,4Ghz SSID Hidden ?"         -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid."24".hidden)
    $WIRELESSLine | Add-Member -Name "2,4Ghz DSSID"                 -MemberType Noteproperty -Value $Json.ssid."24".bssid
    $WIRELESSLine | Add-Member -Name "2,4Ghz Default Security ?"    -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid."24".security.isdefault)
    $WIRELESSLine | Add-Member -Name "2,4Ghz Encryption method"     -MemberType Noteproperty -Value $Json.ssid."24".security.encryption
    $WIRELESSLine | Add-Member -Name "2,4Ghz Password"              -MemberType Noteproperty -Value $Json.ssid."24".security.passphrase
    $WIRELESSLine | Add-Member -Name "2,4Ghz Protocol"              -MemberType Noteproperty -Value $Json.ssid."24".security.protocol
    $WIRELESSLine | Add-Member -Name "2,4Ghz Multimedia QoS Status" -MemberType Noteproperty -Value (Get-State -State $Json.ssid."24".wmmenable)
    $WIRELESSLine | Add-Member -Name "2,4Ghz WPS State"             -MemberType Noteproperty -Value (Get-State -State $Json.ssid."24".wps.enable)
    $WIRELESSLine | Add-Member -Name "2,4Ghz WPS Avalability"       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid."24".wps.available)
    $WIRELESSLine | Add-Member -Name "2,4Ghz WPS Status"            -MemberType Noteproperty -Value (Get-Status -Status $Json.ssid."24".wps.status)
    
    # 5,2 Ghz
    $WIRELESSLine | Add-Member -Name "5,2Ghz Status"                -MemberType Noteproperty -Value (Get-State -State $Json.radio."24".enable)
    $WIRELESSLine | Add-Member -Name "5,2Ghz State"                 -MemberType Noteproperty -Value (Get-State -State $Json.radio."24".state)
    $WIRELESSLine | Add-Member -Name "5,2Ghz Radio Type List"       -MemberType Noteproperty -Value $($Json.standard."5".value -join ",")
    $WIRELESSLine | Add-Member -Name "5,2Ghz Type"                  -MemberType Noteproperty -Value $Json.radio."5".standard
    $WIRELESSLine | Add-Member -Name "5,2Ghz Current Channel"       -MemberType Noteproperty -Value $Json.radio."5".current_channel
    $WIRELESSLine | Add-Member -Name "5,2Ghz Channel"               -MemberType Noteproperty -Value $Json.radio."5".channel
    $WIRELESSLine | Add-Member -Name "5,2Ghz Channel Width"         -MemberType Noteproperty -Value $Json.radio."5".htbw
    $WIRELESSLine | Add-Member -Name "5,2Ghz DFS"                   -MemberType Noteproperty -Value $Json.radio."5".dfs
    $WIRELESSLine | Add-Member -Name "5,2Ghz GreenAP"               -MemberType Noteproperty -Value $Json.radio."5".greenap
    
    $WIRELESSLine | Add-Member -Name "5,2Ghz SSID State"            -MemberType Noteproperty -Value (Get-State -State $Json.ssid."5".enable)
    $WIRELESSLine | Add-Member -Name "5,2Ghz SSID Name"             -MemberType Noteproperty -Value $Json.ssid."5".id
    $WIRELESSLine | Add-Member -Name "5,2Ghz SSID Hidden ?"         -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid."5".hidden)
    $WIRELESSLine | Add-Member -Name "5,2Ghz DSSID"                 -MemberType Noteproperty -Value $Json.ssid."5".bssid
    $WIRELESSLine | Add-Member -Name "5,2Ghz Default Security ?"    -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid."5".security.isdefault)
    $WIRELESSLine | Add-Member -Name "5,2Ghz Encryption method"     -MemberType Noteproperty -Value $Json.ssid."5".security.encryption
    $WIRELESSLine | Add-Member -Name "5,2Ghz Password"              -MemberType Noteproperty -Value $Json.ssid."5".security.passphrase
    $WIRELESSLine | Add-Member -Name "5,2Ghz Protocol"              -MemberType Noteproperty -Value $Json.ssid."5".security.protocol
    $WIRELESSLine | Add-Member -Name "5,2Ghz Multimedia QoS Status" -MemberType Noteproperty -Value (Get-State -State $Json.ssid."5".wmmenable)
    $WIRELESSLine | Add-Member -Name "5,2Ghz WPS State"             -MemberType Noteproperty -Value (Get-State -State $Json.ssid."5".wps.enable)
    $WIRELESSLine | Add-Member -Name "5,2Ghz WPS Avalability"       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid."5".wps.available)
    $WIRELESSLine | Add-Member -Name "5,2Ghz WPS Status"            -MemberType Noteproperty -Value (Get-Status -Status $Json.ssid."5".wps.status)
    
    $WIRELESSLine | Add-Member -Name "5,2Ghz Capabilities"          -MemberType Noteproperty -Value $(Get-WIRELESS5GHCAPABILITIES -Capabilities $Json.capabilities."5")
    
    # Add lines to $Array
    $Array += $WIRELESSLine
    
    Return $Array
}

Function Get-WIRELESS24Ghz {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wireless
    
    # Create New PSObject and add values to array
    $WIRELESSLine = New-Object -TypeName PSObject
    $WIRELESSLine | Add-Member -Name "Status"                -MemberType Noteproperty -Value $Json.status
    $WIRELESSLine | Add-Member -Name "WIFI N"                -MemberType Noteproperty -Value (Get-Status -Status $Json.wifiN)
    $WIRELESSLine | Add-Member -Name "Country"               -MemberType Noteproperty -Value $Json.Country
    $WIRELESSLine | Add-Member -Name "Vendor"                -MemberType Noteproperty -Value $Json.ChipVendor
    $WIRELESSLine | Add-Member -Name "Reference"             -MemberType Noteproperty -Value $Json.ChipReference
    $WIRELESSLine | Add-Member -Name "Radio State"           -MemberType Noteproperty -Value (Get-Status -Status $Json.radio.state)
    $WIRELESSLine | Add-Member -Name "Radio Status"          -MemberType Noteproperty -Value (Get-State -State $Json.radio.enable)
    $WIRELESSLine | Add-Member -Name "Radio Profile"         -MemberType Noteproperty -Value $Json.radio.standard
    $WIRELESSLine | Add-Member -Name "Radio Channel"         -MemberType Noteproperty -Value $Json.radio.channel
    $WIRELESSLine | Add-Member -Name "Radio Current Channel" -MemberType Noteproperty -Value $Json.radio.current_channel
    $WIRELESSLine | Add-Member -Name "Scheduler Status"      -MemberType Noteproperty -Value (Get-State -State $Json.scheduler.enable)
    $WIRELESSLine | Add-Member -Name "SSID ID"               -MemberType Noteproperty -Value $Json.ssid."24".id
    $WIRELESSLine | Add-Member -Name "SSID Status"           -MemberType Noteproperty -Value (Get-State -State $Json.ssid."24".enable)
    $WIRELESSLine | Add-Member -Name "SSID is hidden ?"      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid."24".hidden)
    $WIRELESSLine | Add-Member -Name "BSSID"                 -MemberType Noteproperty -Value $Json.ssid."24".bssid
    $WIRELESSLine | Add-Member -Name "WMM is enable ?"       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid."24".wmmenable)
    $WIRELESSLine | Add-Member -Name "HTBW"                  -MemberType Noteproperty -Value $Json.ssid."24".htbw
    $WIRELESSLine | Add-Member -Name "WPS State"             -MemberType Noteproperty -Value (Get-State -State $Json.ssid."24".wps.enable)
    $WIRELESSLine | Add-Member -Name "WPS Status"            -MemberType Noteproperty -Value (Get-Status -Status $Json.ssid."24".wps.status)
    $WIRELESSLine | Add-Member -Name "Security Protocol"     -MemberType Noteproperty -Value $Json.ssid."24".security.protocol
    $WIRELESSLine | Add-Member -Name "Encryption"            -MemberType Noteproperty -Value $Json.ssid."24".security.encryption
    $WIRELESSLine | Add-Member -Name "Passphrase"            -MemberType Noteproperty -Value $Json.ssid."24".security.passphrase
    $WIRELESSLine | Add-Member -Name "Available Channel"     -MemberType Noteproperty -Value $($Json.capabilities."24".channel -join ",")
        
    # Add lines to $Array
    $Array += $WIRELESSLine
    
    Return $Array
}

Function Get-WIRELESS5Ghz {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wireless
    
    # Create New PSObject and add values to array
    $WIRELESSLine = New-Object -TypeName PSObject
    $WIRELESSLine | Add-Member -Name "Status"                -MemberType Noteproperty -Value $Json.status
    $WIRELESSLine | Add-Member -Name "WIFI N"                -MemberType Noteproperty -Value (Get-Status -Status $Json.wifiN)
    $WIRELESSLine | Add-Member -Name "Country"               -MemberType Noteproperty -Value $Json.Country
    $WIRELESSLine | Add-Member -Name "Vendor"                -MemberType Noteproperty -Value $Json.ChipVendor
    $WIRELESSLine | Add-Member -Name "Reference"             -MemberType Noteproperty -Value $Json.ChipReference
    $WIRELESSLine | Add-Member -Name "Radio State"           -MemberType Noteproperty -Value (Get-Status -Status $Json.radio.state)
    $WIRELESSLine | Add-Member -Name "Radio Status"          -MemberType Noteproperty -Value (Get-State -State $Json.radio.enable)
    $WIRELESSLine | Add-Member -Name "Radio Profile"         -MemberType Noteproperty -Value $Json.radio.standard
    $WIRELESSLine | Add-Member -Name "Radio Channel"         -MemberType Noteproperty -Value $Json.radio.channel
    $WIRELESSLine | Add-Member -Name "Radio Current Channel" -MemberType Noteproperty -Value $Json.radio.current_channel
    $WIRELESSLine | Add-Member -Name "Scheduler Status"      -MemberType Noteproperty -Value (Get-State -State $Json.scheduler.enable)
    $WIRELESSLine | Add-Member -Name "SSID ID"               -MemberType Noteproperty -Value $Json.ssid."5".id
    $WIRELESSLine | Add-Member -Name "SSID Status"           -MemberType Noteproperty -Value (Get-State -State $Json.ssid."5".enable)
    $WIRELESSLine | Add-Member -Name "SSID is hidden ?"      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid."5".hidden)
    $WIRELESSLine | Add-Member -Name "BSSID"                 -MemberType Noteproperty -Value $Json.ssid."5".bssid
    $WIRELESSLine | Add-Member -Name "WMM is enable ?"       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid."5".wmmenable)
    $WIRELESSLine | Add-Member -Name "HTBW"                  -MemberType Noteproperty -Value $Json.ssid."5".htbw
    $WIRELESSLine | Add-Member -Name "WPS State"             -MemberType Noteproperty -Value (Get-State -State $Json.ssid."5".wps.enable)
    If($Json.ssid."5".wps.status){
        $WIRELESSLine | Add-Member -Name "WPS Status"        -MemberType Noteproperty -Value (Get-Status -Status $Json.ssid."5".wps.status)
    }
    Else{$WIRELESSLine | Add-Member -Name "WPS Status"       -MemberType Noteproperty -Value "Unknow"}
    $WIRELESSLine | Add-Member -Name "Security Protocol"     -MemberType Noteproperty -Value $Json.ssid."5".security.protocol
    $WIRELESSLine | Add-Member -Name "Encryption"            -MemberType Noteproperty -Value $Json.ssid."5".security.encryption
    $WIRELESSLine | Add-Member -Name "Passphrase"            -MemberType Noteproperty -Value $Json.ssid."5".security.passphrase
    $WIRELESSLine | Add-Member -Name "Capabilities"          -MemberType Noteproperty -Value $(Get-WIRELESS5GHCAPABILITIES -Capabilities $Json.capabilities."5")
    $WIRELESSLine | Add-Member -Name "Advanced"              -MemberType Noteproperty -Value $Json.Advanced
    
    # Add lines to $Array
    $Array += $WIRELESSLine
    
    Return $Array
}

Function Get-WIRELESS5GHCAPABILITIES {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$Capabilities
    )
    
    # Create array
    $Array = @()
    
    $Capabilitie = 0
    
    While($Capabilitie -lt $Capabilities.Count){
        
        # Create New PSObject and add values to array
        $CapabilitieLine = New-Object -TypeName PSObject
        $CapabilitieLine | Add-Member -Name "Channel"   -MemberType Noteproperty -Value $Capabilities[$Capabilitie].channel
        $CapabilitieLine | Add-Member -Name "HT-20"     -MemberType Noteproperty -Value $Capabilities[$Capabilitie].ht."20"
        $CapabilitieLine | Add-Member -Name "HT-40"     -MemberType Noteproperty -Value $Capabilities[$Capabilitie].ht."40"
        $CapabilitieLine | Add-Member -Name "HT-80"     -MemberType Noteproperty -Value $Capabilities[$Capabilitie].ht."80"
        $CapabilitieLine | Add-Member -Name "NODFS"     -MemberType Noteproperty -Value $Capabilities[$Capabilitie].nodfs
        $CapabilitieLine | Add-Member -Name "cactime"   -MemberType Noteproperty -Value $Capabilities[$Capabilitie].cactime
        $CapabilitieLine | Add-Member -Name "cactime40" -MemberType Noteproperty -Value $Capabilities[$Capabilitie].cactime40
        
        # Add lines to $Array
        $Array += "$($CapabilitieLine -join ',')"
        
        # Go to next line
        $Capabilitie ++
    }
    
    Return $Array
}

Function Get-WIRELESSStats {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wireless.ssid
    
    # Create New PSObject and add values to array
    $StatsLine = New-Object -TypeName PSObject
    $StatsLine | Add-Member -Name "Frequency"          -MemberType Noteproperty -Value $Json.id
    $StatsLine | Add-Member -Name "RX-Bytes"           -MemberType Noteproperty -Value $Json.stats.rx.bytes
    $StatsLine | Add-Member -Name "RX-Packets"         -MemberType Noteproperty -Value $Json.stats.rx.packets
    $StatsLine | Add-Member -Name "RX-PacketsErrors"   -MemberType Noteproperty -Value $Json.stats.rx.packetserrors
    $StatsLine | Add-Member -Name "RX-PacketsDiscards" -MemberType Noteproperty -Value $Json.stats.rx.packetsdiscards
    $StatsLine | Add-Member -Name "TX-Bytes"           -MemberType Noteproperty -Value $Json.stats.tx.bytes
    $StatsLine | Add-Member -Name "TX-Packets"         -MemberType Noteproperty -Value $Json.stats.tx.packets
    $StatsLine | Add-Member -Name "TX-PacketsErrors"   -MemberType Noteproperty -Value $Json.stats.tx.packetserrors
    $StatsLine | Add-Member -Name "TX-PacketsDiscards" -MemberType Noteproperty -Value $Json.stats.tx.packetsdiscards  
    
    # Add lines to $Array
    $Array += $StatsLine
    
    Return $Array
}

Function Get-WIRELESSACL {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.acl
    
    # Create New PSObject and add values to array
    $RuleLine = New-Object -TypeName PSObject
    $RuleLine | Add-Member -Name "Service"     -MemberType Noteproperty -Value "Mac Address Filtering"
    $RuleLine | Add-Member -Name "Status"      -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    
    # Add lines to $Array
    $Array += $RuleLine
    
    Return $Array
}

Function Get-WIRELESSACLRules {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.acl
    
    If($Json.rules.Count -ne 0){
        
        $Rule = 0
        
        While($Rule -lt $Json.rules.Count){
            
            # Create New PSObject and add values to array
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name "ID"          -MemberType Noteproperty -Value $Json.rules[$Rule].id
            $RuleLine | Add-Member -Name "Status"      -MemberType Noteproperty -Value (Get-Status -Status $Json.rules[$Rule].enable)
            $RuleLine | Add-Member -Name "Mac Address" -MemberType Noteproperty -Value $Json.rules[$Rule].macaddress
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
	}
    Else{
        Return $null
    }
}

Function Get-WIRELESSACLRulesID {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $WIRELESSACLIDs = Get-WIRELESSACLRules -UrlToGo $UrlToGo
    $WIRELESSACLID = $WIRELESSACLIDs | Select-Object ID,'Mac Address' | Out-GridView -Title "Wireless ACL Rules List" -OutputMode Single
    $WIRELESSACLHost = $WIRELESSACLIDs | Where-Object {$_.ID -ilike $WIRELESSACLID.id}
    
    Return $WIRELESSACLHost
}

Function Get-WIRELESSFrequencyNeighborhoodScanID {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.scan
    
    $Wifi = 0
    
    If($Json.Count -ne 0){
        
        While($Wifi -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $WifiLine = New-Object -TypeName PSObject
            $WifiLine | Add-Member -Name "Band"       -MemberType Noteproperty -Value $Json[$Wifi].band
            $WifiLine | Add-Member -Name "SSID"       -MemberType Noteproperty -Value $Json[$Wifi].ssid
            $WifiLine | Add-Member -Name "MACAddress" -MemberType Noteproperty -Value $Json[$Wifi].macaddress
            $WifiLine | Add-Member -Name "Channel"    -MemberType Noteproperty -Value $Json[$Wifi].channel
            $WifiLine | Add-Member -Name "Security"   -MemberType Noteproperty -Value $Json[$Wifi].security
            $WifiLine | Add-Member -Name "RSSI"       -MemberType Noteproperty -Value "$($Json[$Wifi].rssi)$($Json[$Wifi].rssiunit)"
            $WifiLine | Add-Member -Name "Mode"       -MemberType Noteproperty -Value $Json[$Wifi].mode
            
            # Add lines to $Array
            $Array += $WifiLine
            
            # Go to next line
            $Wifi ++
        }
        Return $Array
    }
    Else{
        Return $null
    }
}

Function Get-WIRELESSScheduler {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wireless.scheduler
    
    # Create New PSObject and add values to array
    $SchedulerLine = New-Object -TypeName PSObject
    $SchedulerLine | Add-Member -Name "Date"           -MemberType Noteproperty -Value $(Format-Date -String $Json.now)
    $SchedulerLine | Add-Member -Name "State"          -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $SchedulerLine | Add-Member -Name "Status"         -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $SchedulerLine | Add-Member -Name "Status Until"   -MemberType Noteproperty -Value $(Format-Date -String $Json.statusuntil)
    $SchedulerLine | Add-Member -Name "Time Remaining" -MemberType Noteproperty -Value "$([Math]::Floor($Json.statusremaining/3600))h$([Math]::Ceiling($Json.statusremaining/3600))s"
    $SchedulerLine | Add-Member -Name "Rules Count"    -MemberType Noteproperty -Value $Json.rules.count
    
    # Add lines to $Array
    $Array += $SchedulerLine
    
    Return $Array
}

Function Get-WIRELESSSchedulerRules {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wireless.scheduler.rules
    
    If($Json.Count -ne 0){
        
        $Rule = 0
        
        While($Rule -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name "ID"    -MemberType Noteproperty -Value $Json[$Rule].id
            $RuleLine | Add-Member -Name "Name"  -MemberType Noteproperty -Value $Json[$Rule].name
            $RuleLine | Add-Member -Name "State" -MemberType Noteproperty -Value (Get-State -State $Json[$Rule].enable)
            $RuleLine | Add-Member -Name "Start" -MemberType Noteproperty -Value "$($Json[$Rule].start.day) at $($Json[$Rule].start.hour):$($Json[$Rule].start.minute)"
            $RuleLine | Add-Member -Name "End"   -MemberType Noteproperty -Value "$($Json[$Rule].end.day) at $($Json[$Rule].end.hour):$($Json[$Rule].end.minute)"
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
	}
    Else{
        Return $null
    }
}

Function Get-WIRELESSRepeater {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Create New PSObject and add values to array
    $RepeaterLine = New-Object -TypeName PSObject
    $RepeaterLine | Add-Member -Name "Station Count" -MemberType Noteproperty -Value $Json.stationscount
    $RepeaterLine | Add-Member -Name "Station List"  -MemberType Noteproperty -Value $($Json.list -join ",")
    
    # Add lines to $Array
    $Array += $RepeaterLine
    
    Return $Array
}

#endregion WIRELESS

#region WPS

Function Get-WIRELESSWPS {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wps
    
    # Create New PSObject and add values to array
    $WPSLine = New-Object -TypeName PSObject
    $WPSLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "WPS"
    $WPSLine | Add-Member -Name "State"   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $WPSLine | Add-Member -Name "Status"  -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $WPSLine | Add-Member -Name "Timeout" -MemberType Noteproperty -Value $json.timeout
    
    # Add lines to $Array
    $Array += $WPSLine
    
    Return $Array
}

#endregion WPS

#endregion
