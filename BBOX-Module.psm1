
#region GLOBAL

# All functions below are used only on powershell script : .\BBOX-Administration.ps1

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
    $log | Add-Member -Name ToString -MemberType ScriptMethod -value {$this.date + ' : ' + $this.type +' : ' +$this.name +' : ' + $this.Message} -Force 
    
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

# Create folder if not yet existing
Function Test-FolderPath {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$FolderRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$FolderPath,
        
        [Parameter(Mandatory=$True)]
        [String]$FolderName
    )
    
    Write-Log -Type INFO -Name "Programm initialisation" -Message "Start checks `"$FolderPath`" folder." -NotDisplay
    
    If(-not (Test-Path -Path $FolderPath)){
        
        Write-Log -Type INFONO -Name "Programm initialisation" -Message "Creating `"$FolderPath`" folder : " -NotDisplay
        Try{
            $Null = New-Item -Path "$FolderRoot" -Name "$FolderName" -ItemType Directory -Force
            Write-Log -Type VALUE -Name "Programm initialisation" -Message "Done." -NotDisplay
        }
        Catch{
            Write-Log -Type ERROR -Name "Programm initialisation" -Message "Failed. $FolderPath folder can't be created due to : $($_.ToString())"
            $global:TriggerExit = 1
        }
    }
    Else{Write-Log -Type INFONO -Name "Programm initialisation" -Message "`"$FolderPath`" folder state : " -NotDisplay
         Write-Log -Type VALUE -Name "Programm initialisation" -Message "Already exists." -NotDisplay
    }
    Write-Log -Type INFO -Name "Programm initialisation" -Message "End checks `"$FolderPath`" folder." -NotDisplay
}

# Create file if not yet existing
Function Test-FilePath {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$FileRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$FilePath,

        [Parameter(Mandatory=$True)]
        [String]$FileName
    )
    
    Write-Log -Type INFO -Name "Programm initialisation" -Message "Start checks `"$FilePath`" file." -NotDisplay
    
    If(-not (Test-Path -Path $FilePath)){
    
        Write-Log -Type INFONO -Name "Programm initialisation" -Message "Creating `"$FilePath`" file : " -NotDisplay
        Try{
            $Null = New-Item -Path "$FileRoot" -Name $FileName -ItemType File -Force
            Write-Log -Type VALUE -Name "Programm initialisation" -Message "Done." -NotDisplay
        }
        Catch{
            Write-Log -Type ERROR -Name "Programm initialisation" -Message "Failed. `"$FilePath`" file can't be created due to : $($_.ToString())" -NotDisplay
            $global:TriggerExit = 1
        }
    }
    Else{Write-Log -Type INFONO -Name "Programm initialisation" -Message "`"$FilePath`" file state : " -NotDisplay
         Write-Log -Type VALUE -Name "Programm initialisation" -Message "Already exists" -NotDisplay
    }
    Write-Log -Type INFO -Name "Programm initialisation" -Message "End checks `"$FilePath`" File." -NotDisplay
}

# Used only to chose the good ChromeDriver version
Function Get-ChromeDriverVersion {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$ChromeVersion
    )
    
    $ChromeMainVersion = $ChromeVersion.split(".")[0]
     Write-Log -Type INFONO -Name "Programm initialisation" -Message "ChromeDriver version selected : " -NotDisplay

    Switch($ChromeMainVersion){
        
        "87" {$ChromeDriverVersion = "87.0.4280.20"
                Write-Log -Type VALUE -Name "Programm initialisation" -Message "87.0.4280.20." -NotDisplay
               }
           
        "86" {$ChromeDriverVersion = "86.0.4240.22"
                Write-Log -Type VALUE -Name "Programm initialisation" -Message "86.0.4240.22." -NotDisplay
               }
           
        "85" {$ChromeDriverVersion = "85.0.4183.87"
                Write-Log -Type VALUE -Name "Programm initialisation" -Message "85.0.4183.87." -NotDisplay
               }
           
        Default{$ChromeDriverVersion = "Default"
                Write-Log -Type VALUE -Name "Programm initialisation" -Message "Default." -NotDisplay
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
    
        '1'        {Write-Log -Type INFO -Name "Connexion Type" -Message "(L) Localy / (R) Remotly / (Q) Quit the programm."
                    $ConnexionTypeChoice = "L|R|Q"
                   }
        
        '0'        {Write-Log -Type INFO -Name "Connexion Type" -Message "(R) Remotly / (Q) Quit the programm."
                    $ConnexionTypeChoice = "R|Q"
                   }
        
        Default    {Write-Log -Type INFO -Name "Connexion Type" -Message "(R) Remotly / (Q) Quit the programm."
                    $ConnexionTypeChoice = "R|Q"
                   }
    }
    
    $ConnexionType = ""
    While($ConnexionType -notmatch $ConnexionTypeChoice){
    
        $ConnexionType = Read-Host "Enter your choice"
         Write-Log -Type INFO -Name "Connexion Type" -Message "Connexion Type chosen by user : $ConnexionType." -NotDisplay
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
        
        $UrlRoot = Read-Host "Enter your external BBOX IP/DNS Address, Example => example.com "
        Write-Log -Type INFONO -Name "Checking Host" -Message "Host `"$UrlRoot`" status : "
        
        If(-not ([string]::IsNullOrEmpty($UrlRoot))){
            
            $BBoxDnsStatus = Test-Connection -ComputerName $UrlRoot -Quiet
            
            If($BBoxDnsStatus -like $true){
                
                Write-Log -Type VALUE -Name "Checking Host" -Message "Online."
                Break
            }
            Else{Write-Log -Type WARNING -Name "Checking Host" -Message "Offline."
                 Write-Host "Host $UrlRoot seems not Online, please make sure :" -ForegroundColor Yellow
                 Write-Host "- You enter a valid DNS address or IP address." -ForegroundColor Yellow
                 Write-Host "- `"PingResponder`" service is enabled (https://mabbox.bytel.fr/firewall.html)." -ForegroundColor Yellow
                 Write-Host "- `"DYNDNS`" service is enabled and properly configured (https://mabbox.bytel.fr/dyndns.html)." -ForegroundColor Yellow
                 Write-Host "- `"Remote`" service is enabled and properly configured (https://mabbox.bytel.fr/remote.html)." -ForegroundColor Yellow
                 $UrlRoot = ""
            }
        }
        Else{Write-Log -Type WARNING -Name "Checking Host" -Message "This field can't be empty or null."}
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
        
        [int]$Port = Read-Host "Enter your external remote BBOX port, Example => 80,443, default is 8560 "
        Write-Log -Type INFONO -Name "Checking Port" -Message "Port `"$Port`" status : "
        
        If(($Port -ge 1) -and ($Port -le 65535)){
            
            $PortStatus = Test-NetConnection -ComputerName $UrlRoot -Port $Port -InformationLevel Detailed
            
            If($PortStatus.TcpTestSucceeded -like $true){
                
                Write-Log -Type VALUE -Name "Checking Port" -Message "Opened."
                Break
            }
            Else{Write-Log -Type WARNING -Name "Checking Port" -Message "Closed."
                 Write-Host "Port $Port seems closed, please make sure :" -ForegroundColor Yellow
                 Write-host "- You enter a valid port number." -ForegroundColor Yellow
                 Write-Host "- None Firewall rule(s) block this port (https://mabbox.bytel.fr/firewall.html)." -ForegroundColor Yellow
                 Write-Host "- `"Remote`" service is enabled and properly configured (https://mabbox.bytel.fr/remote.html)." -ForegroundColor Yellow
                 $Port = ""
            }
        }
        Else{Write-Log -Type WARNING -Name "Checking Port" -Message "This field can't be empty or null or must be in the range between 1 and 65565."}
    }
    Return $Port
}

#region ChromeDriver 

# Used only to Start ChromeDriver
Function Start-ChromeDriver {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$ChromeDriverVersion,
        
        [Parameter(Mandatory=$True)]
        $DownloadPath
    )
    
    # Add path for ChromeDriver.exe to the environmental variable 
    $env:PATH += ";$PSScriptRoot\Ressources\ChromeDriver\$ChromeDriverVersion"
    # Adding Selenium's .NET assembly (dll) to access it's classes in this PowerShell session
    Add-Type -Path "$PSScriptRoot\Ressources\ChromeDriver\$ChromeDriverVersion\WebDriver.dll"
    # Create new Chrome Drive Service
    $ChromeDriverService = [OpenQA.Selenium.Chrome.ChromeDriverService]::CreateDefaultService()
    # Hide ChromeDriver Command Prompt Window
    $ChromeDriverService.HideCommandPromptWindow = $true
    # 
    $chromeoption = New-Object OpenQA.Selenium.Chrome.ChromeOptions
    # Bypass certificate control
    $chromeoption.AddArguments('ignore-certificate-errors')
    # Find Google Chrome Application
    $chromeoption.BinaryLocation = 'C:/Program Files/Google/Chrome/Application/chrome.exe'
    # Allow to download file without prompt
    $chromeoption.AddUserProfilePreference('download', @{'default_directory' = $DownloadPath;'prompt_for_download' = $False})
    # Hide ChromeDriver Application
    #$chromeoption.AddArguments('headless')
    # Start the ChromeDriver
    $global:ChromeDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($ChromeDriverService,$chromeoption)
}

# Used only to stop ChromeDriver
Function Stop-ChromeDriver {
    
    Param()
    
    # Close all ChromeDriver instances openned
    $global:ChromeDriver.Close()
    $global:ChromeDriver.Dispose()
    $global:ChromeDriver.Quit()
    Get-Process -Name chromedriver -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
}

# Used only to Refresh WIRELESS Frequency Neighborhood Scan
function Start-RefreshWIRELESSFrequencyNeighborhoodScan {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Page,
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot,
        [Parameter(Mandatory=$True)]
        [String]$Port
    )
    
    Write-Log -Type INFONO -Name "WIRELESS Frequency Neighborhood scan" -Message "Refreshing WIRELESS Frequency Neighborhood scan : "

    # Get information from BBOX API and last scan date
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    If([string]::IsNullOrEmpty($Port)){
        Switch($Page){
            
            wireless/24/neighborhood {$UrlNeighborhoodScan = "https://$UrlRoot/neighborhood.html#ssid24";Break}
            wireless/5/neighborhood  {$UrlNeighborhoodScan = "https://$UrlRoot/neighborhood.html#ssid5";Break}
        }
    }
    Else{
        Switch($Page){
            
            wireless/24/neighborhood {$UrlNeighborhoodScan = "https://$UrlRoot`:$Port/neighborhood.html#ssid24";Break}
            wireless/5/neighborhood  {$UrlNeighborhoodScan = "https://$UrlRoot`:$Port/neighborhood.html#ssid5";Break}
        }
    }
    
    $global:ChromeDriver.Navigate().GoToURL($UrlNeighborhoodScan)
    sleep -Seconds 2

    Try{
        Try{
            ($global:ChromeDriver.FindElementsByClassName("cta-2") | Where-Object -Property text -eq "OK").click()
        }
        Catch{
            ($global:ChromeDriver.FindElementsByClassName("cta-2") | Where-Object -Property text -eq "Annuler").click()
        }
    }
    Catch{
        ($global:ChromeDriver.FindElementsByClassName("cta-1") | Where-Object -Property text -eq "Rafraîchir").click()
        ($global:ChromeDriver.FindElementsByClassName("cta-2") | Where-Object -Property text -eq "OK").click()
    }
    sleep -Seconds 10
    Write-Log -Type VALUE -Name "WIRELESS Frequency Neighborhood scan" -Message "Ended"
}

#endregion ChromeDriver

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
    Sleep 2
    
    # Enter the password to connect (# Methods to find the input textbox for the password)
    $global:ChromeDriver.FindElementByName("password").SendKeys("$Password") 
    Sleep 1
    
    # Tic checkBox "Stay Connect" (# Methods to find the input checkbox for stay connect)
    $global:ChromeDriver.FindElementByClassName("cb").Click()
    Sleep 1
    
    # Click on the connect button
    $global:ChromeDriver.FindElementByClassName("cta-1").Submit()
    Sleep 1
}

# Used only to get information
Function Get-BBoxInformation {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    Write-Log -Type INFO -Name "Get Information" -Message "Start retrieving informations requested." -NotDisplay
    Write-Log -Type INFO -Name "Get Information" -Message "Get informations requested from url : $UrlToGo" -NotDisplay
    Try{
        # Go to the web page to get information we need
        $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
        Write-Log -Type INFO -Name "Get Information" -Message "Successsful" -NotDisplay
    }
    Catch{
        Write-Log -Type ERROR -Name "Get Information" -Message "Failed - Due to : $($_.ToString())"
        Write-Host "Please check your local/internet network connection." -ForegroundColor Yellow
        Return "0"
        Break
    }
    Write-Log -Type INFO -Name "Get Information" -Message "End retrieving informations requested." -NotDisplay

    Write-Log -Type INFO -Name "Convert HTML" -Message "Start converting data from Html to plaintxt format." -NotDisplay
    Write-Log -Type INFONO -Name "Convert HTML" -Message "HTML Conversion status : " -NotDisplay
    Try{
        # Get Web page Content
        $Html = $global:ChromeDriver.PageSource
        # Convert $Html To Text
        $Plaintxt = ConvertFrom-HtmlToText -Html $Html
        Write-Log -Type VALUE -Name "Convert HTML" -Message "Successsfull." -NotDisplay
    }
    Catch{
        Write-Log -Type ERROR -Name "Convert HTML" -Message "Failed to convert to HTML, due to : $($_.ToString())"
        Write-Log -Type INFO -Name "Convert HTML" -Message "End converting data from Html to plaintxt format." -NotDisplay
        Return "0"
        Break
    }
    Write-Log -Type INFO -Name "Convert HTML" -Message "End converting data from Html to plaintxt format." -NotDisplay
        
    Write-Log -Type INFO -Name "Convert JSON" -Message "Start convert data from plaintxt to Json format." -NotDisplay
    Write-Log -Type INFONO -Name "Convert JSON" -Message "HTML Conversion status : " -NotDisplay
    Try{
        # Convert $Plaintxt as JSON to array
        $Json = $Plaintxt | ConvertFrom-Json
        Write-Log -Type VALUE -Name "Convert JSON" -Message "Successsfull." -NotDisplay
    }
    Catch{
        Write-Log -Type ERROR -Name "Convert JSON" -Message "Failed - Due to : $($_.ToString())"
        Return "0"
    }
    Write-Log -Type INFO -Name "Convert JSON" -Message "End converting data from plaintxt to Json format." -NotDisplay
    
    If($Json.exception -and ($Json.exception.domain -ne "v1/device/log")){
        
        Write-Log -Type INFO -Name "Get API Error Code" -Message "Start getting API error code." -NotDisplay
        Write-Log -Type INFONO -Name "Get API Error Code" -Message "API error code : "
        Try{
            $ErrorCode = Get-ErrorCode -Json $Json -ErrorAction Stop
            Write-Log -Type WARNING -Name "Get API Error Code" -Message "$ErrorCode"
            Return $Json
        }
        Catch{
            Write-Log -Type ERROR -Name "Get API Error Code" -Message "Failed - Due to : $($_.ToString())"
        }

        Write-Log -Type INFO -Name "Get API Error Code" -Message "End getting API error code." -NotDisplay
    }
    Else{
        Return $Json
    }
}

# Used only to convert HTML page to TXT
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
    @('head', 'style', 'script', 'object', 'embed', 'applet', 'noframes', 'noscript', 'noembed') | % {
    $Html = $Html -replace "<$_[^>]*?>.*?</$_>", ""
    }
    # write-verbose "removed invisible blocks: `n`n$Html`n"
    
    # Condense extra whitespace
    $Html = $Html -replace "( )+", " "
    # write-verbose "condensed whitespace: `n`n$Html`n"
    
    # Add line breaks
    @('div','p','blockquote','h[1-9]') | % { $Html = $Html -replace "</?$_[^>]*?>.*?</$_>", ("`n" + '$0' )} 
    # Add line breaks for self-closing tags
    @('div','p','blockquote','h[1-9]','br') | % { $Html = $Html -replace "<$_[^>]*?/>", ('$0' + "`n")} 
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
    ) | % { $Html = $Html -replace $_[0], $_[1] }
    # write-verbose "replaced entities: `n`n$Html`n"
    
    Return $Html
}

# Used only to get BBOX LAN Switch 
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

# Select function to export data
Function Switch-Info {

    Param(
        [Parameter(Mandatory=$True)]
        [String]$Info,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$ConnexionType,
        
        [Parameter(Mandatory=$True)]
        [String]$APIVersion,
        
        [Parameter(Mandatory=$False)]
        [String]$Port,

        [Parameter(Mandatory=$True)]
        [String]$Mail
    )

        Switch($Info){
            
            # Error Code 
            Get-ErrorCode        {$FormatedData = Get-ErrorCode -UrlToGo $UrlToGo}
            
            Get-ErrorCodeTest    {$FormatedData = Get-ErrorCodeTest -UrlToGo $UrlToGo}
            
            # Airties
            Get-Airties          {$FormatedData = Get-Airties -UrlToGo $UrlToGo -Page $Page}
            
            # Backup
            GET-CONFIGSL         {$FormatedData = Get-BackupList -UrlToGo $UrlToGo -Page $Page}
            
            # DHCP
            GET-DHCP             {$FormatedData = Get-DHCP -UrlToGo $UrlToGo -Page $Page}
            
            GET-DHCPC            {$FormatedData = Get-DHCPClients -UrlToGo $UrlToGo}
            
            GET-DHCPCID          {$FormatedData = Get-DHCPClients -UrlToGo $UrlToGo
                                  $DeviceID = ""
                                  $DeviceID = $FormatedData | Select-Object ID,HostName | Out-GridView -Title "DHCP Client List" -OutputMode Single
                                  $FormatedData = $FormatedData | Where-Object {$_.ID -ilike $DeviceID.id}
                                 }
            
            GET-DHCPAO           {$FormatedData = Get-DHCPActiveOptions -UrlToGo $UrlToGo}
            
            GET-DHCPO            {$FormatedData = Get-DHCPCapabilitiesOptions -UrlToGo $UrlToGo}
            
            GET-DHCPOID          {$FormatedData = Get-DHCPCapabilitiesOptions -UrlToGo $UrlToGo
                                  $OptionID = ""
                                  $OptionID = $FormatedData | Select-Object ID,Description | Out-GridView -Title "DHCP Capabilities Options" -OutputMode Single
                                  $FormatedData = $FormatedData | Where-Object {$_.ID -ilike $OptionID.id}
                                 }
            
            Get-DHCPSTBO         {$FormatedData = Get-DHCPSTBOptions -UrlToGo $UrlToGo}
            
            Get-DHCPv6PFD        {$FormatedData = Get-DHCPv6PrefixDelegation -UrlToGo $UrlToGo}

            Get-DHCPv6O          {$FormatedData = Get-DHCPv6CapabilitiesOptions -UrlToGo $UrlToGo}
            
            # DNS
            GET-DNSS             {$FormatedData = Get-DNSStats -UrlToGo $UrlToGo}
            
            # DEVICE
            GET-DEVICE           {$FormatedData = Get-Device -UrlToGo $UrlToGo -Page $Page}
            
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
            GET-DYNDNS           {$FormatedData = Get-DYNDNS -UrlToGo $UrlToGo -Page $Page}
            
            GET-DYNDNSPL         {$FormatedData = Get-DYNDNSProviderList -UrlToGo $UrlToGo -Page $Page}
            
            GET-DYNDNSC          {$FormatedData = Get-DYNDNSClient -UrlToGo $UrlToGo -Page $Page}
            
            GET-DYNDNSCID        {$FormatedData = Get-DYNDNSClient -UrlToGo $UrlToGo -Page $Page
                                  $DyndnsID = ""
                                  $DyndnsID = $FormatedData | Select-Object ID,Provider,Host | Out-GridView -Title "DYNDNS Configuration List" -OutputMode Single
                                  $FormatedData = $FormatedData | Where-Object {$_.ID -ilike $DyndnsID.id}
                                 }

            # FIREWALL
            GET-FIREWALL         {$FormatedData = Get-FIREWALL -UrlToGo $UrlToGo -Page $Page}
            
            GET-FIREWALLR        {$FormatedData = Get-FIREWALLRules -UrlToGo $UrlToGo}
            
            GET-FIREWALLRID      {$FormatedData = Get-FIREWALLRules -UrlToGo $UrlToGo
                                  $RuleID = ""
                                  $RuleID = $FormatedData | Select-Object ID,Description | Out-GridView -Title "IPV4 FireWall List" -OutputMode Single
                                  $FormatedData = $FormatedData | Where-Object {$_.ID -ilike $RuleID.id}
                                 }
            
            GET-FIREWALLGM       {$FormatedData = Get-FIREWALLGamerMode -UrlToGo $UrlToGo}
            
            GET-FIREWALLPR       {$FormatedData = Get-FIREWALLPingResponder -UrlToGo $UrlToGo}
            
            Get-FIREWALLv6R      {$FormatedData = Get-FIREWALLv6Rules -UrlToGo $UrlToGo}
            
            GET-FIREWALLv6RID    {$FormatedData = Get-FIREWALLv6Rules -UrlToGo $UrlToGo
                                  $RuleID = ""
                                  $RuleID = $FormatedData | Select-Object ID,Description | Out-GridView -Title "IPV6 FireWall List" -OutputMode Single
                                  $FormatedData = $FormatedData | Where-Object {$_.ID -ilike $RuleID.id}
                                 }
            
            Get-FIREWALLv6L      {$FormatedData = Get-FIREWALLv6Level -UrlToGo $UrlToGo}
            
            # API
            GET-APIRM            {$FormatedData = Get-APIRessourcesMap -UrlToGo $UrlToGo -UrlRoot $UrlRoot}
            
            # HOST
            GET-HOSTS            {$FormatedData = Get-HOSTS -UrlToGo $UrlToGo -Page $Page}
            
            GET-HOSTSID          {$FormatedData = Get-HOSTS -UrlToGo $UrlToGo -Page $Page
                                  $HostID = ""
                                  $HostID = $FormatedData | Select-Object ID,Hostname | Out-GridView -Title "Hosts List" -OutputMode Single
                                  $FormatedData = $FormatedData | Where-Object {$_.ID -ilike $HostID.id}
                                 }
            
            GET-HOSTSME          {$FormatedData = Get-HOSTSME -UrlToGo $UrlToGo}
            
            Get-HOSTSL           {$FormatedData = Get-HOSTSLite -UrlToGo $UrlToGo}
            
            # LAN
            GET-LANIP            {$FormatedData = Get-LANIP -UrlToGo $UrlToGo -Page $Page}
            
            GET-LANS             {$FormatedData = Get-LANStats -UrlToGo $UrlToGo}
            
            GET-LANA             {$FormatedData = Get-LANAlerts -UrlToGo $UrlToGo -Page $Page}
            
            # NAT
            GET-NAT              {$FormatedData = Get-NAT -UrlToGo $UrlToGo}
            
            GET-NATDMZ           {$FormatedData = Get-NATDMZ -UrlToGo $UrlToGo}
            
            GET-NATR             {$FormatedData = Get-NATRules -UrlToGo $UrlToGo}
            
            GET-NATRID           {$FormatedData = Get-NATRules -UrlToGo $UrlToGo
                                  $RuleID = ""
                                  $RuleID = $FormatedData | Select-Object ID,Description | Out-GridView -Title "NAT Rules List" -OutputMode Single
                                  $FormatedData = $FormatedData | Where-Object {$_.ID -ilike $RuleID.id}
                                 }
            
            # Parental Control
            GET-PARENTALCONTROL  {$FormatedData = Get-ParentalControl -UrlToGo $UrlToGo -Page $Page}
            
            GET-PARENTALCONTROLS {$FormatedData = Get-ParentalControlScheduler -UrlToGo $UrlToGo}
            
            GET-PARENTALCONTROLSR{$FormatedData = Get-ParentalControlSchedulerRules -UrlToGo $UrlToGo}
            
            # PHONE PROFILE
            GET-PROFILEC         {$FormatedData = Get-PHONEProfileConsumption -UrlToGo $UrlToGo}
            
            # REMOTE
            GET-REMOTEPWOL       {$FormatedData = Get-REMOTEProxyWOL -UrlToGo $UrlToGo}
            
            # SERVICES
            GET-SERVICES         {$FormatedData = Get-SERVICES -UrlToGo $UrlToGo -Page $Page}
            
            GET-IPTV             {$FormatedData = Get-IPTV -UrlToGo $UrlToGo -Page $Page}
            
            GET-IPTVD            {$FormatedData = Get-IPTVDiags -UrlToGo $UrlToGo}
            
            GET-NOTIFICATION     {$FormatedData = Get-NOTIFICATION -UrlToGo $UrlToGo -Page $Page}
            
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
            GET-VOIP             {$FormatedData = Get-VOIP -UrlToGo $UrlToGo -Page $Page}
            
            GET-VOIPD            {$FormatedData = Get-VOIPDiag -UrlToGo $UrlToGo}
            
            GET-VOIPDU           {$FormatedData = Get-VOIPDiagUSB -UrlToGo $UrlToGo}
            
            GET-VOIPDH           {$FormatedData = Get-VOIPDiagHost -UrlToGo $UrlToGo}
            
            GET-VOIPS            {$FormatedData = Get-VOIPScheduler -UrlToGo $UrlToGo}
            
            GET-VOIPSR           {$FormatedData = Get-VOIPSchedulerRules -UrlToGo $UrlToGo}
            
            GET-VOIPCL           {Write-Host "`nWhich Phone line do you want to analyse ?"
                                  Write-Host "(1) Main line`n(2) Second line"
                                  $LineID = ""
                                  While($LineID -notmatch "1|2"){$LineID = Read-Host "Enter value"}
                                  $FormatedData = Get-VOIPCalllogLineX -UrlToGo "$UrlToGo/$LineID"
                                 }
            
            GET-VOIPFCL          {Write-Host "`nWhich Phone line do you want to analyse ?"
                                  Write-Host "(1) Main line`n(2) Second line"
                                  $LineID = ""
                                  While($LineID -notmatch "1|2"){$LineID = Read-Host "Enter value"}
                                  $FormatedData = Get-VOIPFullcalllogLineX -UrlToGo "$UrlToGo/$LineID"
                                 }
            
            GET-VOIPALN          {$FormatedData = Get-VOIPAllowedListNumber -UrlToGo $UrlToGo}
            
            # CPL
            GET-CPL              {$FormatedData = Get-CPL -UrlToGo $UrlToGo -Page $Page}
            
            # WAN
            GET-WANA             {$FormatedData = Get-WANAutowan -UrlToGo $UrlToGo}
            
            GET-WAND             {$FormatedData = Get-WANDiags -UrlToGo $UrlToGo}
            
            GET-WANDS            {$FormatedData = Get-WANDiagsSessions -UrlToGo $UrlToGo}

            GET-WANDSHAS         {$FormatedData = Get-WANDiagsSummaryHostsActiveSessions -UrlToGo $UrlToGo}
            
            Get-WANDAAS          {$FormatedData = Get-WANDiagsAllActiveSessions -UrlToGo $UrlToGo}

            Get-WANDAASH         {$HostID = Get-WANDiagsSummaryHostsActiveSessions -UrlToGo $UrlToGo | Select-Object "Host IP Address" | Out-GridView -Title "Active Session Hosts List" -OutputMode Single
                                  $FormatedData = Get-WANDiagsAllActiveSessions -UrlToGo $UrlToGo
                                  $FormatedData = $FormatedData | Where-Object {($_."Source IP Address" -ilike $HostID.'Host IP Address') -or ($_."Destination IP Address" -ilike $HostID.'Host IP Address')}
                                 }
            
            GET-WANFS            {$FormatedData = Get-WANFTTHStats -UrlToGo $UrlToGo}
            
            GET-WANIP            {$FormatedData = Get-WANIP -UrlToGo $UrlToGo}
            
            GET-WANIPS           {$FormatedData = Get-WANIPStats -UrlToGo $UrlToGo}
            
            Get-WANXDSL          {$FormatedData = Get-WANXDSL -UrlToGo $UrlToGo}

            Get-WANXDSLS         {$FormatedData = Get-WANXDSLStats -UrlToGo $UrlToGo}

            # WIRELESS
            Get-WIRELESS         {$FormatedData = Get-WIRELESS -UrlToGo $UrlToGo -Page $Page}
            
            GET-WIRELESS24       {$FormatedData = Get-WIRELESS24Ghz -UrlToGo $UrlToGo}
            
            GET-WIRELESS24S      {$FormatedData = Get-WIRELESSStats -UrlToGo $UrlToGo}
            
            GET-WIRELESS5        {$FormatedData = Get-WIRELESS5Ghz -UrlToGo $UrlToGo}
            
            GET-WIRELESS5S       {$FormatedData = Get-WIRELESSStats -UrlToGo $UrlToGo}
            
            GET-WIRELESSACL      {$FormatedData = Get-WIRELESSACL -UrlToGo $UrlToGo}
            
            GET-WIRELESSACLR     {$FormatedData = Get-WIRELESSACLRules -UrlToGo $UrlToGo}
            
            GET-WIRELESSACLRID   {$FormatedData = Get-WIRELESSACLRules -UrlToGo $UrlToGo
                                  $WIRELESSACLID = ""
                                  $WIRELESSACLID = $FormatedData | Select-Object ID,'Mac Address' | Out-GridView -Title "Wireless ACL Rules List" -OutputMode Single
                                  $FormatedData = $FormatedData | Where-Object {$_.ID -ilike $WIRELESSACLID.id}
                                 }
            
            GET-WIRELESSWPS      {$FormatedData = Get-WPS -UrlToGo $UrlToGo}
            
            GET-WIRELESSFBNH     {Start-RefreshWIRELESSFrequencyNeighborhoodScan -Page $Page -UrlToGo $UrlToGo -UrlRoot $UrlRoot -Port $Port
                                  $FormatedData = Get-WIRELESSFrequencyNeighborhoodScan -UrlToGo $UrlToGo
                                 }
            
            GET-WIRELESSS        {$FormatedData = Get-WIRELESSScheduler -UrlToGo $UrlToGo}
            
            GET-WIRELESSSR       {$FormatedData = Get-WIRELESSSchedulerRules -UrlToGo $UrlToGo}
            
            Get-WIRELESSR        {$FormatedData = Get-WIRELESSRepeater -UrlToGo $UrlToGo}
            
            # SUMMARY
            Get-SUMMARY          {$FormatedData = Get-SUMMARY -UrlToGo $UrlToGo}
            
            # USERSAVE
            Get-USERSAVE         {$FormatedData = Get-USERSAVE -UrlToGo $UrlToGo -Page $Page}
            
            # BboxConfig
            Export-BboxConfig    {$FormatedData = Export-BboxConfiguration -APISName $Page -ConnexionType $ConnexionType -UrlRoot $UrlRoot -APIVersion $APIVersion -Port $Port}
            
            # BBOXJournal
            Get-BBOXJournal      {$FormatedData = Get-BBOXJournal -UrlToGo $UrlToGo}
            
            # Exit
            Q                    {$global:TriggerExit = 1}
            
            # Default
            Default              {Write-Host "Action selected is not yet developed, please chose another one and contact me by mail to : $Mail for more information" -ForegroundColor Yellow
                                  $FormatedData = $Null
                                  Pause
                                 }
        }
    
        Return $FormatedData
}

# Used only to create HTML Report
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
    
    Switch($ReportPrecontent){
        
        "lan/ip"    {$LANIP     = $DataReported[0] | ConvertTo-Html -As List -PreContent "<h2> LAN Configuration </h2><br/>"
                     $LANSwitch = $DataReported[1] | ConvertTo-Html -As Table -PreContent "<h2> LAN Switch Configuration </h2><br/>"
                     $HTML      = ConvertTo-HTML -Body "$Title $PreContent $LANIP $LANSwitch" -Title $ReportTitle -Head $header -PostContent "<br/>Report Generated by $env:USERNAME form $env:COMPUTERNAME at : $(Get-Date)"
                    }
        
        "wan/diags" {$DNS  = $DataReported.DNS  | ConvertTo-Html -As Table -PreContent "<h2> WAN DNS Statistics </h2>"
                     $HTTP = $DataReported.HTTP | ConvertTo-Html -As Table -PreContent "<h2> WAN HTTP Statistics </h2>"
                     $PING = $DataReported.PING | ConvertTo-Html -As Table -PreContent "<h2> WAN PING Statistics </h2>"
                     $HTML = ConvertTo-HTML -Body "$Title $PreContent $DNS $HTTP $PING" -Title $ReportTitle -Head $header -PostContent "<br/>Report Generated by $env:USERNAME form $env:COMPUTERNAME at : $(Get-Date)"
                    }
        
        "wan/autowan"{$Config          = $DataReported[0] | ConvertTo-Html -As Table -PreContent "<h2> Auto WAN Configuration </h2>"
                     $Profiles         = $DataReported[1] | ConvertTo-Html -As Table -PreContent "<h2> WAN Profiles</h2>"
                     $ProfilesDetailed = $DataReported[2] | ConvertTo-Html -As Table -PreContent "<h2> WAN Profiles Détailled </h2>"
                     $Services         = $DataReported[3] | ConvertTo-Html -As Table -PreContent "<h2> WAN PING Statistics </h2>"
                     $HTML             = ConvertTo-HTML -Body "$Title $PreContent $Config $Services $Profiles $ProfilesDetailed" -Title $ReportTitle -Head $header -PostContent "<br/>Report Generated by $env:USERNAME form $env:COMPUTERNAME at : $(Get-Date)"
                    }
        
        Default     {$HTML = ConvertTo-Html -Body "$Title $PreContent $($DataReported | ConvertTo-Html -As "$ReportType")" -Title $ReportTitle -Head $header -PostContent "<br/>Report Generated by $env:USERNAME form $env:COMPUTERNAME at : $(Get-Date)"
                    }
    }
    
    $HTML | Out-File -FilePath "$ReportPath\$ReportFileName.html" -Force -Encoding utf8

    Write-Log -Type INFONO -Name "Export HTML Report" -Message "HTML Report has been exported to : "
    Write-Log -Type VALUE -Name "Export HTML Report" -Message "$ReportPath\$ReportFileName.html"

    Start "$ReportPath\$ReportFileName.html"
}

# Used only to Out-Gridview Display
Function Out-GridviewDisplay {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [String]$Page,
        
        [Parameter(Mandatory=$True)]
        [String]$Description
    )
    
    Switch($Page){
                
        "lan/ip"   {$FormatedData[0] | Out-GridView -Title "$Description - LAN Configuration"
                    $FormatedData[1] | Out-GridView -Title "$Description - Bbox Switch Port Configuration"
                   }
        
        "wan/diags"{$FormatedData.DNS  | Out-GridView -Title "$Description - DNS"
                    $FormatedData.HTTP | Out-GridView -Title "$Description - HTTP"
                    $FormatedData.Ping | Out-GridView -Title "$Description - PING"
                   }
                    
        Default    {$FormatedData | Out-GridView -Title $Description -Wait}
                
    }
}

#endregion GLOBAL


#region Features

# Functions used by functions in the PSM1 file : .\BBOX-Module.psm1

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

# Used only to get USB right
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

# Used only to know which call type
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

# Used by Function : Get-DeviceLED
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

# Used by Function : Get-DeviceLog
Function Get-PhoneLine {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Phoneline
    )
    
    Switch($Phoneline){
    
        1       {$Value = "Phone 1"}
        2       {$Value = "Phone 2"}
        Default {$Value = "Unknow"}
    }
    
    Return $Value
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
    Sleep 1
    
    # Click on the connect button
    $global:ChromeDriver.FindElementByClassName("cta-1").Submit()
    Sleep 2
    
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


#region Export data

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
        [String]$Port
    )
    
    Switch($ConnexionType) {
        
        L  {$UrlToGo = "$UrlRoot/$APIVersion"}
        R  {$UrlToGo = "$UrlRoot`:$Port/$APIVersion"}
    }
    
    $ExportPath = "$PSScriptRoot\Json_Bbox_config"
    $APISName = $APISName.split(";")
    $i = 0
    
    Foreach($APIName in $APISName){
        
        If($APIName -notmatch "log.html|wireless/acl/rules"){
            
            # Get information from BBOX API
            Write-Log -Type INFO -Name "Export Bbox Configuration To JSON" -Message "Get $APIName configuration ..."
            $Json = Get-BBoxInformation -UrlToGo "$UrlToGo/$APIName"
        
            # Export result as JSON file
            $Exportfile = $APIName.replace("/","-")
            $FullPath = "$ExportPath\$Exportfile.json"
            Write-Log -Type INFONO -Name "Export Bbox Configuration To JSON" -Message "Export configuration to : "
            Write-Log -Type VALUE -Name "Export Bbox Configuration To JSON" -Message "$FullPath"
            $Json | ConvertTo-Json -ErrorAction Stop | Out-File -FilePath $FullPath -Force -ErrorAction Stop
            $i++
        }
    }
    Return $null
}

# Used only to export BBOX Journal
Function Get-BBOXJournal {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $UrlToGo = $UrlToGo -replace "/api/v1"
    $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
    Sleep 2
    Write-Log -Type INFO -Name "Download Bbox Journal to export" -Message "Start download Bbox Journal" -NotDisplay
    $global:ChromeDriver.FindElementByClassName("download").click()
    Sleep 15
    $Journal = ((Get-ChildItem -Path ".\Journal\Journal*.csv" -ErrorAction Stop | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1).FullName)
    Write-Log -Type INFONO -Name "Download Bbox Journal to export" -Message "Download Bbox Journal to : "
    Write-Log -Type VALUE -Name "Download Bbox Journal to export" -Message "$Journal"
    Write-Log -Type INFO -Name "Download Bbox Journal to export" -Message "End download Bbox Journal" -NotDisplay
    $FormatedData = Import-Csv -Path $Journal -Delimiter ';' -Encoding UTF8 -ErrorAction Stop

    Return $FormatedData
}

# To export DATA to different format

# Used only to export result to CSV File
Function Export-toCSV {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [String]$Page,
        
        [Parameter(Mandatory=$True)]
        [String]$ExportCSVPath,
        
        [Parameter(Mandatory=$True)]
        [String]$Exportfile
    )
    
    Try{
        # Calulate Export file path
        $ExportPath = "$ExportCSVPath\$Exportfile.csv"
        $FormatedData | Export-Csv -Path $ExportPath -Encoding UTF8 -Delimiter ";" -NoTypeInformation -Force -ErrorAction Stop
        Write-Log -Type INFONO -Name "Export Result CSV" -Message "Export Data : $Page to : "
        Write-Log -Type VALUE -Name "Export Result CSV" -Message "$ExportPath"
    }
    Catch{
        Write-Log -Type ERROR -Name "Export Result CSV" -Message "Failed to export data to : $ExportPath due to : $($_.ToString())"
    }
}

# Used only to export result to JSON File
Function Export-toJSON {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
    
        [Parameter(Mandatory=$True)]
        [String]$Page,

        [Parameter(Mandatory=$True)]
        [String]$JsonBboxconfigPath,
        
        [Parameter(Mandatory=$True)]
        [String]$Exportfile
    )
    
     Try{
        # Calulate Export file path
        $FullPath = "$JsonBboxconfigPath\$Exportfile.json"
        $FormatedData | ConvertTo-Json -ErrorAction Stop | Out-File -FilePath $FullPath -Force -ErrorAction Stop
        Write-Log -Type INFONO -Name "Export Result JSON" -Message "Export configuration : $Page to => "
        Write-Log -Type VALUE -Name "Export Result JSON" -Message "$FullPath"
    }
    Catch{
        Write-Log -Type ERROR -Name "Export Result JSON" -Message "Failed to export data to : $FullPath due to : $($_.ToString())"
    }
}

#endregion Export data


#region Switch-Info

# Functions used only in the PSM1 file : .\BBOX-Module.psm1

#region Errors code

Function Get-ErrorCode {
    
    Param(
        [Parameter(Mandatory=$True)]
        [Array]$Json
    )
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].exception

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
    #$Json = $Json[0].exception
    
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

function Get-Airties {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page
    
    # Create New PSObject and add values to array
    $Airties = New-Object -TypeName PSObject
    $Airties | Add-Member -Name "Agent Status"                    -MemberType Noteproperty -Value $(Get-Status -Status $Json.agent.enable)
    $Airties | Add-Member -Name "Band Steering Status"            -MemberType Noteproperty -Value $(Get-Status -Status $Json.bandsteering.enable)
    $Airties | Add-Member -Name "Mesh Steering Status"            -MemberType Noteproperty -Value $(Get-Status -Status $Json.meshsteering.enable)
    $Airties | Add-Member -Name "Remote Manager Status"           -MemberType Noteproperty -Value $(Get-Status -Status $Json.remotemanager.enable)
    $Airties | Add-Member -Name "CACS Status"                     -MemberType Noteproperty -Value $(Get-Status -Status $Json.cacs.enable)
    $Airties | Add-Member -Name "Live View Status"                -MemberType Noteproperty -Value $(Get-Status -Status $Json.liveview.enable)
    $Airties | Add-Member -Name "Device Serial Number"            -MemberType Noteproperty -Value $Json.device.serialnumber
    $Airties | Add-Member -Name "Device Firmware Main Version"    -MemberType Noteproperty -Value $Json.device.main.version
    $Airties | Add-Member -Name "Device Firmware Main Date"       -MemberType Noteproperty -Value ($Json.device.main.date.replace("T"," ")).replace("Z","")
    $Airties | Add-Member -Name "Device Firmware Running Version" -MemberType Noteproperty -Value $Json.device.running.version
    $Airties | Add-Member -Name "Device Firmware Running date"    -MemberType Noteproperty -Value $Json.device.running.date.replace("T"," ")
    $Airties | Add-Member -Name "IP Address"                      -MemberType Noteproperty -Value $Json.lanmode.ip
    $Airties | Add-Member -Name "IP Lan Address"                  -MemberType Noteproperty -Value $Json.lanmode.iplan

    # Add lines to $Array
    $Array += $Airties
    
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
    $Json = $Json[0].apis
    
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
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    If($Json[0].$Page.Count -ne "0"){
    
        # Create array
        $Array = @()
        
        # Select $JSON header
        $Json = $Json[0].$Page
        $Config = 0
        
        While($Config -lt $Json.count){
            
            # Create New PSObject and add values to array
            $ConfigLine = New-Object -TypeName PSObject
            $ConfigLine | Add-Member -Name "ID"               -MemberType Noteproperty -Value $Json[$Config].id
            $ConfigLine | Add-Member -Name "Name"             -MemberType Noteproperty -Value $Json[$Config].name
            $ConfigLine | Add-Member -Name "Creation Date"    -MemberType Noteproperty -Value ($Json[$Config].date.replace("T"," ")).replace("+0100","")
            $ConfigLine | Add-Member -Name "Time Zone"        -MemberType Noteproperty -Value "+ 1"
            $ConfigLine | Add-Member -Name "Firmware Version" -MemberType Noteproperty -Value $Json[$Config].firmware
            
            # Add lines to $Array
            $Array += $ConfigLine
            $Config ++
        }
    }
    Else{$Array = "0"}
    
    Return $Array
}

#endregion BACKUP

#region CPL

Function Get-CPL {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page
    
    # Create New PSObject and add values to array
    $CPLLine = New-Object -TypeName PSObject
    $CPLLine | Add-Member -Name "Service"                  -MemberType Noteproperty -Value $Page
    $CPLLine | Add-Member -Name "Is detected ?"            -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.running)
    $CPLLine | Add-Member -Name "Master ID"                -MemberType Noteproperty -Value $Json.list.id
    $CPLLine | Add-Member -Name "Master MACAddress"        -MemberType Noteproperty -Value $Json.list.macaddress
    $CPLLine | Add-Member -Name "Master Manufacturer"      -MemberType Noteproperty -Value $Json.list.manufacturer
    $CPLLine | Add-Member -Name "Master Speed"             -MemberType Noteproperty -Value $Json.list.speed
    $CPLLine | Add-Member -Name "Master Chipset"           -MemberType Noteproperty -Value $Json.list.chipset
    $CPLLine | Add-Member -Name "Master Version"           -MemberType Noteproperty -Value $Json.list.version
    $CPLLine | Add-Member -Name "Master Port"              -MemberType Noteproperty -Value $Json.list.port
    If(-not ([string]::IsNullOrEmpty($Json.list.active))){
        $CPLLine | Add-Member -Name "Master State"         -MemberType Noteproperty -Value (Get-State -State $Json.list.active)
        $CPLLine | Add-Member -Name "Plug State"           -MemberType Noteproperty -Value (Get-State -State $Json.list.associateddevice.active)
    }
    Else{$CPLLine | Add-Member -Name "Master State"        -MemberType Noteproperty -Value ""
         $CPLLine | Add-Member -Name "Plug State"          -MemberType Noteproperty -Value ""
    }
    $CPLLine | Add-Member -Name "Plug MAC Address"         -MemberType Noteproperty -Value $Json.list.associateddevice.macaddress
    $CPLLine | Add-Member -Name "Plug Manufacturer"        -MemberType Noteproperty -Value $Json.list.associateddevice.manufacturer
    $CPLLine | Add-Member -Name "Plug Chipset"             -MemberType Noteproperty -Value $Json.list.associateddevice.chipset
    $CPLLine | Add-Member -Name "Plug Speed"               -MemberType Noteproperty -Value $Json.list.associateddevice.speed
    $CPLLine | Add-Member -Name "Plug Version"             -MemberType Noteproperty -Value $Json.list.associateddevice.version
    $CPLLine | Add-Member -Name "End Stations MAC Address" -MemberType Noteproperty -Value $Json.list.endstations.macaddress
    
    # Add lines to $Array
    $Array += $CPLLine
    
    Return $Array
}

#endregion CPL

#region DEVICE

Function Get-Device {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page
    
    If(-not ([string]::IsNullOrEmpty($Json.temperature.status))){$TemperatureStatus = Get-Status -Status $Json.temperature.status}
    Else{$TemperatureStatus = ""}
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name "Date"                      -MemberType Noteproperty -Value $Json.now.replace("T"," ")
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
    $DeviceLine | Add-Member -Name "MAIN Firmware Date"        -MemberType Noteproperty -Value ($Json.main.date.replace("T"," ")).replace("Z","")
    $DeviceLine | Add-Member -Name "RECOVERY Firmware Version" -MemberType Noteproperty -Value $Json.reco.version
    $DeviceLine | Add-Member -Name "RECOVERY Firmware Date"    -MemberType Noteproperty -Value ($Json.reco.date.replace("T"," ")).replace("Z","")
    $DeviceLine | Add-Member -Name "RUNNING Firmware Version"  -MemberType Noteproperty -Value $Json.running.version                                 # Missing in online documentation : https://api.bbox.fr/doc/apirouter/index.html
    $DeviceLine | Add-Member -Name "RUNNING Firmware Date"     -MemberType Noteproperty -Value ($Json.running.date.replace("T"," ")).replace("Z","") # Missing in online documentation : https://api.bbox.fr/doc/apirouter/index.html
    $DeviceLine | Add-Member -Name "BACKUP Version"            -MemberType Noteproperty -Value $Json.bcck.version
    $DeviceLine | Add-Member -Name "BOOTLOADER 1 Version"      -MemberType Noteproperty -Value $Json.ldr1.version
    $DeviceLine | Add-Member -Name "BOOTLOADER 2 Version"      -MemberType Noteproperty -Value $Json.ldr2.version
    $DeviceLine | Add-Member -Name "First use date"            -MemberType Noteproperty -Value ($Json.firstusedate.replace("T"," ")).replace("Z","")
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
    $Json = $Json[0].log
    
    $log = 0
    $ID = 1
    
    While($log -lt $Json.count){
        
        $Date = ($Json[$log].date).replace("T"," ")
        
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
    $ID = 1
    
    While($Json.exception.code -ne "404"){
        
        # Select $JSON header
        $Json = $Json[0].log
        
        $log = 0
        
        While($log -lt $Json.count){
            
            $Date = ($Json[$log].date).replace("T"," ")
            
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
    $ID = 1
    
    While($Json.exception.code -ne "404"){
        
        # Select $JSON header
        $Json = $Json[0].log
        
        $log = 0
        
        While($log -lt $Json.count){
            
            $Date = ($Json[$log].date).replace("T"," ")
            
            If ((-not (([string]::IsNullOrEmpty($Json[$log].param)))) -and ($Json[$log].param -match ";" )){
                
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
    $Json = $Json[0].device.mem
    
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
    $Json = $Json[0].device
    
    # Create New PSObject and add values to array
    $SummaryLine = New-Object -TypeName PSObject
    $SummaryLine | Add-Member -Name "Date"          -MemberType Noteproperty -Value ($Json.now.replace("T"," ")).replace("+0200","")
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
    $Json = $Json[0].device
    
    # Create New PSObject and add values to array
    $TokenLine = New-Object -TypeName PSObject
    $TokenLine | Add-Member -Name "Token"                 -MemberType Noteproperty -Value $Json.token
    $TokenLine | Add-Member -Name "Date"                  -MemberType Noteproperty -Value ($Json.now.replace("T"," ")).replace("Z","")
    $TokenLine | Add-Member -Name "Token Expiration Date" -MemberType Noteproperty -Value ($Json.expires.replace("T"," ")).replace("Z","")
    $TokenLine | Add-Member -Name "Token Valid Time Left" -MemberType Noteproperty -Value ($($Json.expires.replace("T"," ")).replace("Z","")) - $(($Json.now.replace("T"," ")).replace("Z",""))

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
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page
    
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
    $Json = $Json[0].dhcp.clients
            
    $Client = 0
    
    While($Client -lt $Json.Count){
        
        $ClientName = New-Object -TypeName PSObject
        $ClientName | Add-Member -Name "ID"           -MemberType Noteproperty -Value $Json[$Client].ID
        $ClientName | Add-Member -Name "HostName"     -MemberType Noteproperty -Value $Json[$Client].HostName
        $ClientName | Add-Member -Name "IPV4 Address" -MemberType Noteproperty -Value $Json[$Client].IPAddress
        $ClientName | Add-Member -Name "IPV6 Address" -MemberType Noteproperty -Value $Json[$Client].IP6Address
        $ClientName | Add-Member -Name "MACAddress"   -MemberType Noteproperty -Value $Json[$Client].MACAddress
        $ClientName | Add-Member -Name "State"        -MemberType Noteproperty -Value (Get-State -State $Json[$Client].enable)
        
        # Add lines to $Array
        $Array += $ClientName
        
        $Client ++
    }
    
    Return $Array
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
    $Json = $Json[0].dhcp
    
    # Add Static DHCP Options
    # Create New PSObject and add values to array 
    $OptionLine = New-Object -TypeName PSObject
    $OptionLine | Add-Member -Name "ID"     -MemberType Noteproperty -Value $Json.optionsstatic.id
    $OptionLine | Add-Member -Name "Option" -MemberType Noteproperty -Value $Json.optionsstatic.option
    $OptionLine | Add-Member -Name "Value"  -MemberType Noteproperty -Value $Json.optionsstatic.value
    $OptionLine | Add-Member -Name "Type"   -MemberType Noteproperty -Value "Static"
    
    $Array += $OptionLine
    
    # Add DYnamic DHCP Options
    
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
        
        $Option ++
    }
    
    Return $Array
}

Function Get-DHCPCapabilitiesOptions {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].dhcp.optionscapabilities
    
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
        
        $Option ++
    }
    
    Return $Array
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
    $Json = $Json[0].dhcp.options
    
    $Option = 1
    
    While($Option -lt $Json.count){
        
        # Create New PSObject and add values to array
        $OptionLine = New-Object -TypeName PSObject
        $OptionLine | Add-Member -Name "ID"     -MemberType Noteproperty -Value $Json[$Option].id
        $OptionLine | Add-Member -Name "Option" -MemberType Noteproperty -Value $Json[$Option].option
        
        # Add lines to $Array
        $Array += $OptionLine
        
        $Option ++
    }
    
    Return $Array
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
        
        $PrefixID ++
    }
    
    Return $Array
}

Function Get-DHCPv6CapabilitiesOptions {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].dhcp.optionscapabilities
    
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
        
        $Option ++
    }
    
    Return $Array
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
    $Json = $Json[0].dns
    
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
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page
    
    # Create New PSObject and add values to array
    $DyndnsLine = New-Object -TypeName PSObject
    $DyndnsLine | Add-Member -Name "Service"              -MemberType Noteproperty -Value "DYNDNS"
    $DyndnsLine | Add-Member -Name "State"                -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $DyndnsLine | Add-Member -Name "Status"               -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $DyndnsLine | Add-Member -Name "Nb Configured domain" -MemberType Noteproperty -Value ($Json.domaincount)
    
    $Array += $DyndnsLine
    
    Return $Array
}

Function Get-DYNDNSProviderList {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page.servercapabilities
    
    $Providers = 0
    
    While($Providers -lt $Json.count){
        
        # Create New PSObject and add values to array
        $ProviderLine = New-Object -TypeName PSObject
        $ProviderLine | Add-Member -Name "Provider"                        -MemberType Noteproperty -Value $Json[$Providers].name
        $ProviderLine | Add-Member -Name "Supported Protocols (IPv4/IPv6)" -MemberType Noteproperty -Value ($($Json[$Providers].Support) -join "/")
        $ProviderLine | Add-Member -Name "Web Site"                        -MemberType Noteproperty -Value $Json[$Providers].Site
        
        # Add lines to $Array
        $Array += $ProviderLine
        
        $Providers ++
    }
    
    Return $Array
}

Function Get-DYNDNSClient {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page.domain
    
    $Provider = 1
    
    While($Provider -lt $Json.count){
        
        # Create New PSObject and add values to array
        $ProviderLine = New-Object -TypeName PSObject
        $ProviderLine | Add-Member -Name "ID"                  -MemberType Noteproperty -Value $Json[$Provider].id
        $ProviderLine | Add-Member -Name "Provider"            -MemberType Noteproperty -Value $Json[$Provider].server
        $ProviderLine | Add-Member -Name "State"               -MemberType Noteproperty -Value (Get-State -State $Json[$Provider].enable)
        $ProviderLine | Add-Member -Name "Username"            -MemberType Noteproperty -Value $Json[$Provider].username
        $ProviderLine | Add-Member -Name "Password"            -MemberType Noteproperty -Value $Json[$Provider].password
        $ProviderLine | Add-Member -Name "Host"                -MemberType Noteproperty -Value $Json[$Provider].host
        $ProviderLine | Add-Member -Name "Record"              -MemberType Noteproperty -Value $Json[$Provider].record
        $ProviderLine | Add-Member -Name "MAC Address"         -MemberType Noteproperty -Value $Json[$Provider].device
        $ProviderLine | Add-Member -Name "Date"                -MemberType Noteproperty -Value $Json[$Provider].status.date.replace("T"," ")
        $ProviderLine | Add-Member -Name "Status"              -MemberType Noteproperty -Value $Json[$Provider].status.status
        $ProviderLine | Add-Member -Name "Message"             -MemberType Noteproperty -Value $Json[$Provider].status.message
        $ProviderLine | Add-Member -Name "IP Address"          -MemberType Noteproperty -Value $Json[$Provider].status.ip
        $ProviderLine | Add-Member -Name "Cache Date"          -MemberType Noteproperty -Value $Json[$Provider].status.cache_date.replace("T"," ")
        $ProviderLine | Add-Member -Name "Periodic Update (H)" -MemberType Noteproperty -Value $Json[$Provider].periodicupdate
        
        $Array += $ProviderLine
        
        $Provider ++
    }
    
    Return $Array
}

#endregion DNS

#region FIREWALL

Function Get-FIREWALL {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page
    
    $Firewall = New-Object -TypeName PSObject
    $Firewall | Add-Member -Name "Service"             -MemberType Noteproperty -Value $Page
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
    
    $Rule = 0
    
    While($Rule -lt $Json.Count){
        
        $RuleLine = New-Object -TypeName PSObject
        $RuleLine | Add-Member -Name "ID"                            -MemberType Noteproperty -Value $Json[$Rule].ID
        $RuleLine | Add-Member -Name "Status"                        -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].enable)
        $RuleLine | Add-Member -Name "Description"                   -MemberType Noteproperty -Value $Json[$Rule].description
        $RuleLine | Add-Member -Name "Action"                        -MemberType Noteproperty -Value $Json[$Rule].action
        $RuleLine | Add-Member -Name "IP source (Range/IP)"          -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcipnot)
        $RuleLine | Add-Member -Name "IP source"                     -MemberType Noteproperty -Value $Json[$Rule].srcip
        $RuleLine | Add-Member -Name "IP destination (Range/IP)"     -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstipnot)
        $RuleLine | Add-Member -Name "IP destination"                -MemberType Noteproperty -Value $Json[$Rule].dstip
        $RuleLine | Add-Member -Name "Port source (Range/Port)"      -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcportnot)
        $RuleLine | Add-Member -Name "Port source"                   -MemberType Noteproperty -Value $Json[$Rule].srcports
        $RuleLine | Add-Member -Name "Port destination (Range/Port)" -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstportnot)
        $RuleLine | Add-Member -Name "Port destination"              -MemberType Noteproperty -Value $Json[$Rule].dstports
        $RuleLine | Add-Member -Name "Priority"                      -MemberType Noteproperty -Value $Json[$Rule].order
        $RuleLine | Add-Member -Name "TCP/UDP Protocols"             -MemberType Noteproperty -Value $Json[$Rule].protocols
        $RuleLine | Add-Member -Name "IP Protocols"                  -MemberType Noteproperty -Value $Json[$Rule].ipprotocol
        $RuleLine | Add-Member -Name "Is used ?"                     -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].utilisation)
        
        # Add lines to $Array
        $Array += $RuleLine
        
        $Rule ++
    }
    
    Return $Array
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
    $PingResponderLine | Add-Member -Name "Service"         -MemberType Noteproperty -Value "Ping Responder"
    $PingResponderLine | Add-Member -Name "Status"          -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $PingResponderLine | Add-Member -Name "IP Addess/Range" -MemberType Noteproperty -Value $Json.ip
    
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
    
    $Rule = 0
    
    While($Rule -lt $Json.Count){
        
        $RuleLine = New-Object -TypeName PSObject
        $RuleLine | Add-Member -Name "ID"                            -MemberType Noteproperty -Value $Json[$Rule].ID
        $RuleLine | Add-Member -Name "Status"                        -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].enable)
        $RuleLine | Add-Member -Name "Description"                   -MemberType Noteproperty -Value $Json[$Rule].description
        $RuleLine | Add-Member -Name "Action"                        -MemberType Noteproperty -Value $Json[$Rule].action
        $RuleLine | Add-Member -Name "IP source (Range/IP)"          -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcipnot)
        $RuleLine | Add-Member -Name "IP source"                     -MemberType Noteproperty -Value $Json[$Rule].srcip
        $RuleLine | Add-Member -Name "IP destination (Range/IP)"     -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstipnot)
        $RuleLine | Add-Member -Name "IP destination"                -MemberType Noteproperty -Value $Json[$Rule].dstip
        $RuleLine | Add-Member -Name "Port source (Range/Port)"      -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcportnot)
        $RuleLine | Add-Member -Name "Port source"                   -MemberType Noteproperty -Value $Json[$Rule].srcports
        $RuleLine | Add-Member -Name "Port destination (Range/Port)" -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstportnot)
        $RuleLine | Add-Member -Name "Port destination"              -MemberType Noteproperty -Value $Json[$Rule].dstports
        $RuleLine | Add-Member -Name "Priority"                      -MemberType Noteproperty -Value $Json[$Rule].order
        $RuleLine | Add-Member -Name "TCP/UDP Protocols"             -MemberType Noteproperty -Value $Json[$Rule].protocols
        $RuleLine | Add-Member -Name "IP Protocols"                  -MemberType Noteproperty -Value $Json[$Rule].ipprotocol
        $RuleLine | Add-Member -Name "Is used ?"                     -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].utilisation)
        
        # Add lines to $Array
        $Array += $RuleLine
        
        $Rule ++
    }
    
    Return $Array
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
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page.list
    
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
        
        $Device ++
    }
    
    Return $Array
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
    $Json = $Json[0].host
    
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
    $Json = $Json[0].hosts.list
    
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
        
        $Device ++
    }
    
    Return $Array
}

#endregion HOSTS

#region IPTV

Function Get-IPTV {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page
    
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
        $IPTVLine | Add-Member -Name "EGIP Channel ID"        -MemberType Noteproperty -Value $Json[$IPTV].epgid
        
        # Add lines to $Array
        $Array += $IPTVLine
        
        $IPTV ++
    }
    Return $Array
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
    $IPTVDiagsLine | Add-Member -Name "Date"                 -MemberType Noteproperty -Value $Json.now.replace("T"," ") # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name "IGMP State"           -MemberType Noteproperty -Value (Get-State -State $Json.igmp.state) # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name "IGMP Status"          -MemberType Noteproperty -Value (Get-Status -Status $Json.igmp.enable) # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name "IPTV Multicast State" -MemberType Noteproperty -Value "Unknow" #(Get-State -State $Json.iptv.multicast.state)
    $IPTVDiagsLine | Add-Member -Name "IPTV Multicast Date"  -MemberType Noteproperty -Value $Json.iptv.multicast.date.replace("T"," ")
    $IPTVDiagsLine | Add-Member -Name "IPTV Platform State"  -MemberType Noteproperty -Value $Json.iptv.platform.state
    $IPTVDiagsLine | Add-Member -Name "IPTV Platform Date"   -MemberType Noteproperty -Value $Json.iptv.platform.date.replace("T"," ")
    
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
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create arrays
    $IP = @()
    $Switch = @()
    
    # Select $JSON 's head
    $Page = $Page.Split("/")[0]
    $Json = $Json[0].$Page
    
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
        $IPV6Line ++
    }
    $IPLine | Add-Member -Name "IPV6 Address"                    -MemberType Noteproperty -Value $IPV6Params
    $IPLine | Add-Member -Name "IPV6 Prefix"                     -MemberType Noteproperty -Value $Json.ip.ip6prefix.prefix
    $IPLine | Add-Member -Name "IPV6 Prefix Status"              -MemberType Noteproperty -Value $Json.ip.ip6prefix.status
    If(-not ([string]::IsNullOrEmpty($Json.ip.ip6prefix.valid))){
        $IPLine | Add-Member -Name "IPV6 Prefix Valid"               -MemberType Noteproperty -Value ($Json.ip.ip6prefix.valid).Replace("T"," ")
    }
    If(-not ([string]::IsNullOrEmpty($Json.ip.ip6prefix.preferred))){
        $IPLine | Add-Member -Name "IPV6 Prefix Preferred"           -MemberType Noteproperty -Value ($Json.ip.ip6prefix.preferred).Replace("T"," ")
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
        $Port ++
    }
    
    #Return $Array
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
    $Json = $Json[0].lan.stats
    
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
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page.list
    
    $Alert = 0
    
    While($Alert -lt $Json.count){
        
        # $RecoveryDate formatting
        If(-not ([string]::IsNullOrEmpty($Json[$Alert].param))){
            
            $RecoveryDate = ($Json[$Alert].recovery_date).replace("T"," ")
        }
        Else{$RecoveryDate = $Json[$Alert].recovery_date}
        
        # $SolvedTime formatting
        If($Json[$Alert].total_duration -ne 0){
            
            $SolvedTime = ((Get-Date).AddMinutes(- $Json[$Alert].total_duration))
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
            
            ALERT_LAN_PORT_UP                {$Details = "Bbox Switch Port : $($Json[$Alert].param)"}
            
            ALERT_LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Associated Hostname : $($Params[2]), IP Address in conflit : $($Params[1])"}
            
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
        $AlertLine | Add-Member -Name "Details"            -MemberType Noteproperty -Value $Details
        $AlertLine | Add-Member -Name "First Date"         -MemberType Noteproperty -Value ($Json[$Alert].first_date).replace("T"," ")
        $AlertLine | Add-Member -Name "Last Date"          -MemberType Noteproperty -Value ($Json[$Alert].last_date).replace("T"," ")
        $AlertLine | Add-Member -Name "Recovery Date"      -MemberType Noteproperty -Value $RecoveryDate
        $AlertLine | Add-Member -Name "Nb Occurences"      -MemberType Noteproperty -Value $Json[$Alert].count
        $AlertLine | Add-Member -Name "Solved Time"        -MemberType Noteproperty -Value $SolvedTime
        $AlertLine | Add-Member -Name "Notification Level" -MemberType Noteproperty -Value $Json[$Alert].level
        
        # Add lines to $Array
        $Array += $AlertLine
        
        $Alert ++
    }
    
    Return $Array
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
    $Json = $Json[0].nat.dmz
    
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
    $Json = $Json[0].nat.rules
    
    $NAT = 0
    
    While($NAT -lt $Json.count){
        
        # Create New PSObject and add values to array
        $NATLine = New-Object -TypeName PSObject
        $NATLine | Add-Member -Name "ID"                          -MemberType Noteproperty -Value $Json[$NAT].id
        $NATLine | Add-Member -Name "Status"                      -MemberType Noteproperty -Value (Get-Status -Status $Json[$NAT].enable)
        $NATLine | Add-Member -Name "Description"                 -MemberType Noteproperty -Value "$($Json[$NAT].description)"
        $NATLine | Add-Member -Name "Allowed External IP Address" -MemberType Noteproperty -Value $Json[$NAT].externalip
        $NATLine | Add-Member -Name "External Port"               -MemberType Noteproperty -Value $Json[$NAT].externalport
        $NATLine | Add-Member -Name "Internal Port"               -MemberType Noteproperty -Value $Json[$NAT].internalport
        $NATLine | Add-Member -Name "INternal IP Address"         -MemberType Noteproperty -Value $Json[$NAT].internalip
        $NATLine | Add-Member -Name "Protocol"                    -MemberType Noteproperty -Value $Json[$NAT].protocol
        
        # Add lines to $Array
        $Array += $NATLine
        
        $NAT ++
    }
    
    Return $Array
}

#endregion NAT

#region Notification

Function Get-NOTIFICATION {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page
    
    # Create New PSObject and add values to array
    $NOTIFICATIONLine = New-Object -TypeName PSObject
    $NOTIFICATIONLine | Add-Member -Name "Service"              -MemberType Noteproperty -Value $Page
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
    $Json = $Json[0].notification.Alerts
    
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
        
        $NOTIFICATION ++
    }
    
    Return $Array
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
    $Json = $Json[0].notification.contacts
    
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
        
        $Contacts ++
    }
    
    Return $Array
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
    $Json = $Json[0].notification.events
    
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
        
        $Events ++
    }
    
    Return $Array
}

#endregion Notification

#region PARENTAL CONTROL

Function Get-ParentalControl {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page.scheduler
    
    # Create New PSObject and add values to array
    $ParentalControlLine = New-Object -TypeName PSObject
    $ParentalControlLine | Add-Member -Name "Service"        -MemberType Noteproperty -Value "Parental Control"
    $ParentalControlLine | Add-Member -Name "Date"           -MemberType Noteproperty -Value $Json.now.replace("T"," ")
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
    $Json = $Json[0].parentalcontrol.scheduler
    
    $Scheduler = 0
    
    # Create New PSObject and add values to array
    $SchedulerLine = New-Object -TypeName PSObject
    $SchedulerLine | Add-Member -Name "Service"     -MemberType Noteproperty -Value "Parental Control Scheduler"
    $SchedulerLine | Add-Member -Name "Date"        -MemberType Noteproperty -Value $($Json.now).replace("T"," ")
    $SchedulerLine | Add-Member -Name "State"       -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $SchedulerLine | Add-Member -Name "Rules count" -MemberType Noteproperty -Value $Json.rules.count
    
    # Add lines to $Array
    $Array += $SchedulerLine
    
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
    $Json = $Json[0].parentalcontrol.scheduler.rules
    
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
        
        $Scheduler ++
    }
    
    Return $Array
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
    $Json = $Json[0].profile
    
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
    $Json = $Json[0].Proxywol
    
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
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page[0]
    
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
    
    # DHCPV6
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
        $I++
    }
    $IPTV = $IPTV -join " ; "
    
    # USB Printers list
    $J = 0
    $Printer = @()
    While($J -lt $Json.usb.printer.count){
        $Printer += "Name : $($Json.usb.printer[$J].product),  State : $($Json.usb.printer[$J].state)"
        $J++
    }
    $Printer = $Printer -join " ; "
    
    # USB Samba Storage
    $K = 0
    $Storage = @()
    While($k -lt $Json.usb.storage.count){
        $Storage += "Label : $($Json.usb.storage[$K].label), State : $($Json.usb.storage[$K].state)"
        $K++
    }
    $Storage = $Storage -join " ; "

    # Hosts List
    $L = 0
    $Hosts = @()
    While($L -lt $Json.hosts.count){
        $Hosts += "Hostname : $($Json.hosts[$L].hostname), IP address : $($Json.hosts[$L].ipaddress)"
        $L++
    }
    $Hosts = $Hosts -join " ; "

    # StatusRemaning
    $ParentalControlStatusRemaining = New-TimeSpan -Seconds $Json.services.parentalcontrol.statusRemaining
    $WifiSchedulerStatusRemaining   = New-TimeSpan -Seconds $Json.services.wifischeduler.statusRemaining
    $VOIPSchedulerStatusRemaining   = New-TimeSpan -Seconds $Json.services.voipscheduler.statusRemaining

    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name "Date"                              -MemberType Noteproperty -Value $Json.now.Replace("T"," ")
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
    $DeviceLine | Add-Member -Name "Wireless Change Date"              -MemberType Noteproperty -Value ($Json.wireless.changedate.Replace("T"," ")).replace("Z","")
    $DeviceLine | Add-Member -Name "WPS 2,4Ghz "                       -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps."24".available)
    $DeviceLine | Add-Member -Name "WPS 5,2Ghz"                        -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps."5".available)
    $DeviceLine | Add-Member -Name "WPS State"                         -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps.enable)
    $DeviceLine | Add-Member -Name "WPS Status"                        -MemberType Noteproperty -Value $Json.wireless.wps.status
    $DeviceLine | Add-Member -Name "WPS Timeout"                       -MemberType Noteproperty -Value $Json.wireless.wps.timeout
    $DeviceLine | Add-Member -Name "Wifi State"                        -MemberType Noteproperty -Value (Get-State -State $Json.services.hotspot.enable)
    $DeviceLine | Add-Member -Name "Firewall State"                    -MemberType Noteproperty -Value (Get-State -State $Json.services.firewall.enable)
    $DeviceLine | Add-Member -Name "DYNDNS State"                      -MemberType Noteproperty -Value (Get-State -State $Json.services.dyndns.enable)
    $DeviceLine | Add-Member -Name "DHCP State"                        -MemberType Noteproperty -Value (Get-State -State $Json.services.dhcp.enable)
    $DeviceLine | Add-Member -Name "NAT State"                         -MemberType Noteproperty -Value (Get-State -State $Json.services.nat.enable) -SecondValue "Active Rules : $($Json.services.nat.enable)"
    $DeviceLine | Add-Member -Name "DMZ State"                         -MemberType Noteproperty -Value (Get-State -State $Json.services.dmz.enable)
    $DeviceLine | Add-Member -Name "NATPAT State"                      -MemberType Noteproperty -Value (Get-State -State $Json.services.natpat.enable)
    $DeviceLine | Add-Member -Name "UPNP/IGD State"                    -MemberType Noteproperty -Value (Get-State -State $Json.services.upnp.igd.enable)
    $DeviceLine | Add-Member -Name "Notification State"                -MemberType Noteproperty -Value (Get-State -State $Json.services.notification.enable)  -SecondValue "Active Notifications Rules : $($Json.services.notification.enable)"
    $DeviceLine | Add-Member -Name "ProxyWOL State"                    -MemberType Noteproperty -Value (Get-State -State $Json.services.proxywol.enable)
    $DeviceLine | Add-Member -Name "Web Remote State"                  -MemberType Noteproperty -Value (Get-State -State $Json.services.remoteweb.enable)
    $DeviceLine | Add-Member -Name "Parental Control State"            -MemberType Noteproperty -Value (Get-State -State $Json.services.parentalcontrol.enable)
    $DeviceLine | Add-Member -Name "Parental Control Status"           -MemberType Noteproperty -Value (Get-Status -Status $Json.services.parentalcontrol.status)
    $DeviceLine | Add-Member -Name "Parental Control Status Until"     -MemberType Noteproperty -Value $(($Json.services.parentalcontrol.statusUntil).replace("T"," "))
    $DeviceLine | Add-Member -Name "Parental Control Status Remaining" -MemberType Noteproperty -Value "$($ParentalControlStatusRemaining.Hours)h$($ParentalControlStatusRemaining.Minutes)m$($ParentalControlStatusRemaining.Seconds)s"
    $DeviceLine | Add-Member -Name "WIFI Scheduler State"              -MemberType Noteproperty -Value (Get-State -State $Json.services.wifischeduler.enable)
    $DeviceLine | Add-Member -Name "WIFI Scheduler Status"             -MemberType Noteproperty -Value (Get-Status -Status $Json.services.wifischeduler.status)
    $DeviceLine | Add-Member -Name "WIFI Scheduler Status Until"       -MemberType Noteproperty -Value $(($Json.services.wifischeduler.statusUntil).replace("T"," "))
    $DeviceLine | Add-Member -Name "WIFI Scheduler Status Remaining"   -MemberType Noteproperty -Value "$($WifiSchedulerStatusRemaining.Hours)h$($WifiSchedulerStatusRemaining.Minutes)m$($WifiSchedulerStatusRemaining.Seconds)s"
    $DeviceLine | Add-Member -Name "VOIP Scheduler State"              -MemberType Noteproperty -Value (Get-State -State $Json.services.voipscheduler.enable)
    $DeviceLine | Add-Member -Name "VOIP Scheduler Status"             -MemberType Noteproperty -Value (Get-Status -Status $Json.services.voipscheduler.status)
    $DeviceLine | Add-Member -Name "VOIP Scheduler Status Until"       -MemberType Noteproperty -Value $(($Json.services.voipscheduler.statusUntil).replace("T"," "))
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
    $Json = $Json[0].upnp.igd
    
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
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].upnp.igd.rules
    
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
        $RuleLine | Add-Member -Name "Expiration Date"     -MemberType Noteproperty -Value $Json[$Rule].expire.replace("T"," ")
        
        # Add lines to $Array
        $Array += $RuleLine
        
        $Rule ++
    }
    
    Return $Array
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
    
    If($Json[0].usb.count -ne "0"){
        
        # Create array
        $Array = @()
        
        # Select $JSON header
        $Json = $Json[0].usb
        $USBDevice = 0
        
        While($USBDevice -lt $Json.parent.Count){
            
            # Create New PSObject and add values to array
            
            # Parent
            $USBDeviceLine = New-Object -TypeName PSObject
            $USBDeviceLine | Add-Member -Name "Index"              -MemberType Noteproperty -Value $Json.child[$USBDevice].index
            $USBDeviceLine | Add-Member -Name "Parent Identity"    -MemberType Noteproperty -Value $Json.parent[$USBDevice].ident
            $USBDeviceLine | Add-Member -Name "Parent Description" -MemberType Noteproperty -Value $Json.parent[$USBDevice].description

            # Children
            $USBDeviceLine | Add-Member -Name "Identity"           -MemberType Noteproperty -Value $Json.child[$USBDevice].ident
            $USBDeviceLine | Add-Member -Name "Parent"             -MemberType Noteproperty -Value $Json.child[$USBDevice].parent
            $USBDeviceLine | Add-Member -Name "UUID"               -MemberType Noteproperty -Value $Json.child[$USBDevice].uuid
            $USBDeviceLine | Add-Member -Name "Label"              -MemberType Noteproperty -Value $Json.child[$USBDevice].label
            $USBDeviceLine | Add-Member -Name "Description  "      -MemberType Noteproperty -Value $Json.child[$USBDevice].description
            $USBDeviceLine | Add-Member -Name "System Format"      -MemberType Noteproperty -Value $Json.child[$USBDevice].fs
            $USBDeviceLine | Add-Member -Name "Name"               -MemberType Noteproperty -Value $Json.child[$USBDevice].name
            $USBDeviceLine | Add-Member -Name "Right"              -MemberType Noteproperty -Value $(Get-USBRight -USBRight $($Json.child[$USBDevice].writable))
            $USBDeviceLine | Add-Member -Name "USB Port number"    -MemberType Noteproperty -Value $Json.child[$USBDevice].host
            $USBDeviceLine | Add-Member -Name "State"              -MemberType Noteproperty -Value $Json.child[$USBDevice].state
            $USBDeviceLine | Add-Member -Name "Space Used (Octet)" -MemberType Noteproperty -Value $Json.child[$USBDevice].used
            $USBDeviceLine | Add-Member -Name "Space Total (Octet)"-MemberType Noteproperty -Value $Json.child[$USBDevice].total
            $USBDeviceLine | Add-Member -Name "Space Free (Octet)" -MemberType Noteproperty -Value $($Json.child[$USBDevice].total - $Json.child[$USBDevice].used)
            
            # Add lines to $Array
            $Array += $USBDeviceLine
            
            $USBDevice ++
        }
    }
    Else{$Array = "0"}
    
    Return $Array
}

Function Get-DeviceUSBPrinter {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    if($Json[0].printer.count -ne "0"){    
    
        # Create array
        $Array = @()
        
        # Select $JSON header
        $Json = $Json[0].printer
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
            $USBPrinter ++
        }
    }
    Else{$Array = "0"}
    
    Return $Array
}

Function Get-USBStorage {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    If($Json[0].file_info.count -ne "0"){

        # Create array
        $Array = @()
        
        # Select $JSON header
        $Json = $Json[0].file_info
        $USBStorage = 0
        
        While($USBStorage -lt $Json.Count){
            
            # Create New PSObject and add values to array
            $USBStorageLine = New-Object -TypeName PSObject
            $USBStorageLine | Add-Member -Name "Path"         -MemberType Noteproperty -Value $Json[$USBStorage].path
            $USBStorageLine | Add-Member -Name "Size"         -MemberType Noteproperty -Value $Json[$USBStorage].size
            $USBStorageLine | Add-Member -Name "Preview Type" -MemberType Noteproperty -Value $Json[$USBStorage].preview_type
            $USBStorageLine | Add-Member -Name "Hash"         -MemberType Noteproperty -Value $Json[$USBStorage].hash
            $USBStorageLine | Add-Member -Name "Type"         -MemberType Noteproperty -Value $Json[$USBStorage].type
            $USBStorageLine | Add-Member -Name "Icon"         -MemberType Noteproperty -Value $Json[$USBStorage].icon
            $USBStorageLine | Add-Member -Name "Bytes"        -MemberType Noteproperty -Value $Json[$USBStorage].bytes
            
            # Add lines to $Array
            $Array += $USBStorageLine
            $USBStorage ++
        }
    }
    Else{$Array = "0"}
    
    Return $Array
}

#endregion USB

#region USERSAVE

Function Get-USERSAVE {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page
    
    # Create New PSObject and add values to array
    $UsersaveLine = New-Object -TypeName PSObject
    $UsersaveLine | Add-Member -Name "Service"              -MemberType Noteproperty -Value $Page
    $UsersaveLine | Add-Member -Name "State"                -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $UsersaveLine | Add-Member -Name "Status"               -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $UsersaveLine | Add-Member -Name "Boots's Number"       -MemberType Noteproperty -Value $Json.numberofboots # Since Version : 19.2.12
    $UsersaveLine | Add-Member -Name "Last Restore date"    -MemberType Noteproperty -Value $Json.datelastrestore
    $UsersaveLine | Add-Member -Name "Last Date Save"       -MemberType Noteproperty -Value $Json.datelastsave
    $UsersaveLine | Add-Member -Name "Restore From Factory" -MemberType Noteproperty -Value $Json.restorefromfactory
    $UsersaveLine | Add-Member -Name "Delay"                -MemberType Noteproperty -Value $Json.delay
    $UsersaveLine | Add-Member -Name "Authorized ?"         -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.authorized)
    
    # Add lines to $Array
    $Array += $UsersaveLine
    
    Return $Array
}

#endregion USERSAVE

#region VOIP

Function Get-VOIP {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].$Page
    
    # Create New PSObject and add values to array
    $VOIPLine = New-Object -TypeName PSObject
    $VOIPLine | Add-Member -Name "Phone line index"       -MemberType Noteproperty -Value $Json.id
    $VOIPLine | Add-Member -Name "Status"                 -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $VOIPLine | Add-Member -Name "Call State"             -MemberType Noteproperty -Value $Json.callstate
    $VOIPLine | Add-Member -Name "SIP Phone Number"       -MemberType Noteproperty -Value $Json.uri
    $VOIPLine | Add-Member -Name "Anonymous call Blocked" -MemberType Noteproperty -Value $Json.blockstate
    $VOIPLine | Add-Member -Name "Anonymous Call State"   -MemberType Noteproperty -Value (Get-State -State $Json.anoncallstate)
    $VOIPLine | Add-Member -Name "Voice Mail ?"           -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.mwi)
    $VOIPLine | Add-Member -Name "Voice Mail Count"       -MemberType Noteproperty -Value $Json.message_count
    $VOIPLine | Add-Member -Name "Missed call"            -MemberType Noteproperty -Value $Json.notanswered
    
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
    $Json = $Json[0].phy_interface
    
    $VOIPID = 0
    
    While($VOIPID -lt $Json.Count){
        
        # Create New PSObject and add values to array
        $VOIPLine = New-Object -TypeName PSObject
        $VOIPLine | Add-Member -Name "Phone Line ID"    -MemberType Noteproperty -Value $Json[$VOIPID].ring_test.id
        $VOIPLine | Add-Member -Name "Ring Test Status" -MemberType Noteproperty -Value $Json[$VOIPID].ring_test.status
        $VOIPLine | Add-Member -Name "Echo Test Status" -MemberType Noteproperty -Value $Json[$VOIPID].echo_test.status
        
        # Add lines to $Array
        $Array += $VOIPLine
        
        $VOIPID ++
    }
    
    Return $Array
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
    $Json = $Json[0].usb
    
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
        
        $USB ++
    }
    
    Return $Array
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
    $Json = $Json[0].host
    
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
        
        $Device ++
    }
    
    Return $Array
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
    $Json = $Json[0].voip.scheduler
    
    # Create New PSObject and add values to array
    $SchedulerLine = New-Object -TypeName PSObject
    $SchedulerLine | Add-Member -Name "Date"           -MemberType Noteproperty -Value $Json.now.Replace("T"," ")
    $SchedulerLine | Add-Member -Name "State"          -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $SchedulerLine | Add-Member -Name "Unbloked ?"     -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.unblock)
    $SchedulerLine | Add-Member -Name "Status"         -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $SchedulerLine | Add-Member -Name "Status Until"   -MemberType Noteproperty -Value $Json.statusuntil.Replace("T"," ")
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
    $Json = $Json[0].voip.scheduler.rules
    
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
        
        $Rule ++
    }
    
    Return $Array
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
    $Json = $Json[0].calllog
    
    $Call = 0
    
    While($Call -lt $Json.Count){
        
        # Calculate call time
        $CallTime = New-TimeSpan -Seconds $($Json[$Call].duree)
        
        # Create New PSObject and add values to array
        $CallLine = New-Object -TypeName PSObject
        $CallLine | Add-Member -Name "ID"             -MemberType Noteproperty -Value $Json[$Call].id
        $CallLine | Add-Member -Name "Number"         -MemberType Noteproperty -Value $Json[$Call].number
        $CallLine | Add-Member -Name "Date"           -MemberType Noteproperty -Value ((Get-Date -Date "01/01/1970").addseconds($Json[$Call].date))
        $CallLine | Add-Member -Name "Call Type"      -MemberType Noteproperty -Value (Get-VoiceCallType -VoiceCallType $Json[$Call].type)
        $CallLine | Add-Member -Name "Was Answered ?" -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Call].answered)
        $CallLine | Add-Member -Name "Call Time"      -MemberType Noteproperty -Value "$($CallTime.Hours)h$($CallTime.Minutes)m$($CallTime.Seconds)s"
        
        # Add lines to $Array
        $Array += $CallLine
        
        $Call ++
    }
    
    Return $Array
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
    $Json = $Json[0].calllog
    
    $Call = 0
    
    While($Call -lt $Json.Count){
        
        # Calculate call time
        $CallTime = New-TimeSpan -Seconds $($Json[$Call].duree)
        
        # Create New PSObject and add values to array
        $CallLine = New-Object -TypeName PSObject
        $CallLine | Add-Member -Name "ID"             -MemberType Noteproperty -Value $Json[$Call].id
        $CallLine | Add-Member -Name "Number"         -MemberType Noteproperty -Value $Json[$Call].number
        $CallLine | Add-Member -Name "Date"           -MemberType Noteproperty -Value ((Get-Date -Date "01/01/1970").addseconds($Json[$Call].date))
        $CallLine | Add-Member -Name "Call Type"      -MemberType Noteproperty -Value (Get-VoiceCallType -VoiceCallType $Json[$Call].type)
        $CallLine | Add-Member -Name "Was Answered ?" -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Call].answered)
        $CallLine | Add-Member -Name "Call Time"      -MemberType Noteproperty -Value "$($CallTime.Hours)h$($CallTime.Minutes)m$($CallTime.Seconds)s"
        
        # Add lines to $Array
        $Array += $CallLine
        
        $Call ++
    }
    
    Return $Array
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
    $Json = $Json[0].voip.scheduler
    
    $Number = 0
    
    While($Number -lt $Json.Count){
        
        # Create New PSObject and add values to array
        $NumberLine = New-Object -TypeName PSObject
        $NumberLine | Add-Member -Name "ID"     -MemberType Noteproperty -Value $Json[$Number].id
        $NumberLine | Add-Member -Name "Number" -MemberType Noteproperty -Value $Json[$Number].number
        
        # Add lines to $Array
        $Array += $NumberLine
        
        $Number ++
    }
    
    Return $Array
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
    $Profile = @()
    $Profiles = @()
    $Services = @()
    
    # Select $JSON header
    $Json = $Json[0].autowan
    
    # Device part
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name "Model"            -MemberType Noteproperty -Value $Json.device.model
    $DeviceLine | Add-Member -Name "Firmware Version" -MemberType Noteproperty -Value $Json.device.firmware.main
    $DeviceLine | Add-Member -Name "Firmware Date"    -MemberType Noteproperty -Value $Json.device.firmware.date
    $DeviceLine | Add-Member -Name "WAN IP Address"   -MemberType Noteproperty -Value $Json.ip.address
    
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
    $Profile += $ProfileLine
    
    
    # Profiles part
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
        
        $Line ++
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
    $Json = $Json[0].diags
    
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
    
    $TCP_Sessions = $null
    $UDP_Sessions = $null
    $Line = 0
    
    While($Line -lt $Json.hosts.Count){
        
        $TCP_Sessions += $Json.hosts[$Line].currenttcp
        $UDP_Sessions += $Json.hosts[$Line].currentudp
        $Line ++
    }
    
    # Create New PSObject and add values to array
    $SessionsLine = New-Object -TypeName PSObject
    $SessionsLine | Add-Member -Name "Nb Hosts With Opened Sessions" -MemberType Noteproperty -Value $Json.hosts.Count
    $SessionsLine | Add-Member -Name "Total current IP sessions"     -MemberType Noteproperty -Value $Json.currentip
    $SessionsLine | Add-Member -Name "Total TCP IP sessions"         -MemberType Noteproperty -Value $TCP_Sessions
    $SessionsLine | Add-Member -Name "Total UDP IP sessions"         -MemberType Noteproperty -Value $UDP_Sessions
    $SessionsLine | Add-Member -Name "Total ICMP IP sessions"        -MemberType Noteproperty -Value $($Json.currentip - ($TCP_Sessions + $UDP_Sessions))
    $SessionsLine | Add-Member -Name "TCP Timeout"                   -MemberType Noteproperty -Value $Json.tcptimeout
    $SessionsLine | Add-Member -Name "High Threshold"                -MemberType Noteproperty -Value $Json.highthreshold
    $SessionsLine | Add-Member -Name "Low Threshold"                 -MemberType Noteproperty -Value $Json.lowthreshold
    $SessionsLine | Add-Member -Name "Update Date"                   -MemberType Noteproperty -Value ($Json.updatedate.Replace("T"," ")).replace("+0200","")
    $SessionsLine | Add-Member -Name "Nb Page"                       -MemberType Noteproperty -Value $Json.pages
    $SessionsLine | Add-Member -Name "Nb Result Per Page"            -MemberType Noteproperty -Value $Json.resultperpage
    
    # Add lines to $Array
    $Array += $SessionsLine
    
    Return $Array
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
        
        $Line ++
    }
    
    Return $Array
}

Function Get-WANDiagsAllActiveSessions {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    $NbPages = ($Json.pages) + 1
    $Page = 1
    
    While($Page -lt $NbPages){
        
        $SessionPage = "$UrlToGo/$Page"
        $Date = Get-Date
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
            
            $Line ++
        }
        $Page ++
    }
    
    Return $Array
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
    $Json = $Json[0].wan.ftth
    
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
    $Json = $Json[0].wan
    
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
        $IPLine | Add-Member -Name "WAN IPV6 Valid"                -MemberType Noteproperty -Value $Json.ip.ip6address.valid.replace("T"," ")
        $IPLine | Add-Member -Name "WAN IPV6 Preferred"            -MemberType Noteproperty -Value $Json.ip.ip6address.preferred.replace("T"," ")
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
        $IPLine | Add-Member -Name "WAN IPV6 Prefix Valid"         -MemberType Noteproperty -Value $Json.ip.ip6prefix.valid.replace("T"," ")
        $IPLine | Add-Member -Name "WAN IPV6 Prefix Preferred"     -MemberType Noteproperty -Value $Json.ip.ip6prefix.preferred.replace("T"," ")
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
    $Json = $Json[0].wan.ip.stats
    
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
    $DeviceLine | Add-Member -Name "Service" -MemberType Noteproperty -Value "XDSL"
    $DeviceLine | Add-Member -Name "State"  -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $DeviceLine | Add-Member -Name "Modulation" -MemberType Noteproperty -Value $Json.modulation
    $DeviceLine | Add-Member -Name "Show Time" -MemberType Noteproperty -Value $Json.showtime
    $DeviceLine | Add-Member -Name "ATUR Provider" -MemberType Noteproperty -Value $Json.atur_provider
    $DeviceLine | Add-Member -Name "ATUC Provider" -MemberType Noteproperty -Value $Json.atuc_provider
    $DeviceLine | Add-Member -Name "Synchronisation Count" -MemberType Noteproperty -Value $Json.sync_count
    $DeviceLine | Add-Member -Name "Down Bitrates" -MemberType Noteproperty -Value $Json.down.bitrates
    $DeviceLine | Add-Member -Name "Down Noise" -MemberType Noteproperty -Value $Json.down.noise
    $DeviceLine | Add-Member -Name "Down Attenuation" -MemberType Noteproperty -Value $Json.down.attenuation
    $DeviceLine | Add-Member -Name "Down Power" -MemberType Noteproperty -Value $Json.down.power
    $DeviceLine | Add-Member -Name "Down Phyr" -MemberType Noteproperty -Value $Json.down.phyr
    $DeviceLine | Add-Member -Name "Down GINP" -MemberType Noteproperty -Value $Json.down.ginp
    $DeviceLine | Add-Member -Name "Down Nitro" -MemberType Noteproperty -Value $Json.down.nitro
    $DeviceLine | Add-Member -Name "Down Interleave Delay" -MemberType Noteproperty -Value $Json.down.interleave_delay
    $DeviceLine | Add-Member -Name "Up Bitrates" -MemberType Noteproperty -Value $Json.up.bitrates
    $DeviceLine | Add-Member -Name "Up Noise" -MemberType Noteproperty -Value $Json.up.noise
    $DeviceLine | Add-Member -Name "Up Attenuation" -MemberType Noteproperty -Value $Json.up.attenuation
    $DeviceLine | Add-Member -Name "Up Power" -MemberType Noteproperty -Value $Json.up.power
    $DeviceLine | Add-Member -Name "Up Phyr" -MemberType Noteproperty -Value $Json.up.phyr
    $DeviceLine | Add-Member -Name "Up GINP" -MemberType Noteproperty -Value $Json.up.ginp
    $DeviceLine | Add-Member -Name "Up Nitro" -MemberType Noteproperty -Value $Json.up.nitro
    $DeviceLine | Add-Member -Name "Up Interleave Delay" -MemberType Noteproperty -Value $Json.up.interleave_delay

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
        [String]$Page
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$Page
    
    # Create New PSObject and add values to array
    $WIRELESSLine = New-Object -TypeName PSObject
    $WIRELESSLine | Add-Member -Name "Service"                      -MemberType Noteproperty -Value $Page
    $WIRELESSLine | Add-Member -Name "Status"                       -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $WIRELESSLine | Add-Member -Name "WIFI unified Active ?"        -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.unified)
    $WIRELESSLine | Add-Member -Name "WIFI unify available ?"       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.unified_available)
    $WIRELESSLine | Add-Member -Name "Is default 24Ghz Config"      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Page.isDefault24) # Since Version : 19.2.12
    $WIRELESSLine | Add-Member -Name "Is default 5Ghz Config"       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Page.isDefault5) # Since Version : 19.2.12
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
    $Json = $Json[0].wireless
    
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
    $Json = $Json[0].wireless
    
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
    $Array = ""
    
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
    $Json = $Json[0].wireless.ssid
    
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
    $Json = $Json[0].acl
    
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
    $Json = $Json[0].acl
    
    $Rule = 0
    
    While($Rule -lt $Json.rules.Count){
        
        # Create New PSObject and add values to array
        $RuleLine = New-Object -TypeName PSObject
        $RuleLine | Add-Member -Name "ID"          -MemberType Noteproperty -Value $Json.rules[$Rule].id
        $RuleLine | Add-Member -Name "Status"      -MemberType Noteproperty -Value (Get-Status -Status $Json.rules[$Rule].enable)
        $RuleLine | Add-Member -Name "Mac Address" -MemberType Noteproperty -Value $Json.rules[$Rule].macaddress
        
        # Add lines to $Array
        $Array += $RuleLine
        
        $Rule ++
    }
    
    Return $Array
}

Function Get-WIRELESSFrequencyNeighborhoodScan {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].scan
    
    $Wifi = 0
    If($Json -ne 0){
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
            
            $Wifi ++
        }
    }
    Return $Array
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
    $Json = $Json[0].wireless.scheduler
    
    # Create New PSObject and add values to array
    $SchedulerLine = New-Object -TypeName PSObject
    $SchedulerLine | Add-Member -Name "Date"           -MemberType Noteproperty -Value $Json.now.Replace("T"," ")
    $SchedulerLine | Add-Member -Name "State"          -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $SchedulerLine | Add-Member -Name "Status"         -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $SchedulerLine | Add-Member -Name "Status Until"   -MemberType Noteproperty -Value $Json.statusuntil.Replace("T"," ")
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
    $Json = $Json[0].wireless.scheduler.rules
    
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
        
        $Rule ++
    }
    
    Return $Array
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

Function Get-WPS {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].wps
    
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
