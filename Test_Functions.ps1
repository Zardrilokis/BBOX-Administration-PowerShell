<#

function Get- {
    
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
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name "" -MemberType Noteproperty -Value
    $DeviceLine | Add-Member -Name "" -MemberType Noteproperty -Value 
    $DeviceLine | Add-Member -Name "" -MemberType Noteproperty -Value 
    
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

#>

#region Click button

# For change page to 5Ghz
$global:ChromeDriver.FindElementByClassName("tous ").click()

# For change page to 2,4Ghz
$global:ChromeDriver.FindElementByClassName("ouvert ").click()

# Click on the refresh button
$global:ChromeDriver.FindElementsByClassName("cta-1")[-1].click()
$global:ChromeDriver.FindElementsByClassName("cta-2")[-1].click()

Try{
    If(($global:ChromeDriver.FindElementById("jBox3").Displayed) -eq $True){
        $global:ChromeDriver.FindElementsByClassName("cta-2")[-1].click()
    }
}
Catch{$global:ChromeDriver.FindElementsByClassName("cta-1")[-1].click()
      $global:ChromeDriver.FindElementsByClassName("cta-2")[-1].click()
}

$global:ChromeDriver.FindElementsByClassName("cta-2")[-1].click()

$global:ChromeDriver.FindElementsByClassName("cta-1")["Rafraîchir"].click()
$global:ChromeDriver.FindElementsByClassName("cta-2")[-1].click()

($global:ChromeDriver.FindElementsByClassName("cta-1") | Where-Object -Property text).click()
 
($global:ChromeDriver.FindElementsByClassName("cta-1") | Where-Object -Property text -eq "Rafraîchir").click()
($global:ChromeDriver.FindElementsByClassName("cta-2") | Where-Object -Property text -eq "OK").click()

($global:ChromeDriver.FindElementsByClassName("cta-2") | Where-Object -Property text -eq "Annuler").click()

Try{Remove-Module -Name BBOX-Module -ErrorAction SilentlyContinue}
Catch{}
Start-Sleep -Seconds 1
Try{Import-Module -Name "C:\Users\ThomasLandel\Desktop\BBOX-Administration\Version2\BBOX-Module.psm1" -ErrorAction Stop}
Catch{Write-Host "Une erreur est survenue, le module n'a pu être chargé car : $($_.ToString())" -ForegroundColor Red}
#endregion

#region Manage errors
If($Plaintxt -match "exception"){

    Switch($Plaintxt){
        
        "Operation requires authentication" {Connect-BBOX -UrlHome $UrlHome -Password $Password -ErrorAction Stop
                                             Get-BBoxInformation -UrlToGo $UrlToGo -ErrorAction Stop
                                            }
        
        "Object does not exist"             {Write-Log -Type ERROR -Name "Get Information" -Message "Fatal error, the API page : $UrlToGo don't exist"
                                             Return "0"
                                             Break
                                            }
        
        "Unauthorized"                      {Write-Log -Type ERROR -Name "Get Information" -Message "Fatal error, the API page : $UrlToGo  - is Unauthorized for your BBOX version"
                                             Return "0"
                                             Break
                                            }
        
        "Graph not found"                   {Write-Log -Type ERROR -Name "Get Information" -Message "Fatal error, the API page : $UrlToGo - Graph not found for your BBOX version"
                                             Return "0"
                                             Break
                                            }
        
        "Operation not found"               {Write-Log -Type ERROR -Name "Get Information" -Message "Fatal error, the API page : $UrlToGo - Operation not found for your BBOX version"
                                             Return "0"
                                             Break
                                            }
        
        "Default"                           {Write-Log -Type ERROR -Name "Get Information" -Message "Fatal error, the API page : $UrlToGo - Unknow or unmanaged error"
                                            }
    }
}
#endregion

Remove-Module -Name BBOX-Module
$BBOXModulePath = "C:\Users\ThomasLandel\OneDrive - AZEO\Personnel\BBOX-Administration\Version2\BBOX-Module.psm1"
Import-Module -Name $BBOXModulePath -ErrorAction Stop

$Function= @()
$Page     = "404" # device/log/11
$UrlHome  = "https://mabbox.bytel.fr/index.html"
$Password = "Tom@78_91_45@2013"
$UrlToGo  = "https://mabbox.bytel.fr/api/v1/$Page"

cd "C:\Users\ThomasLandel\OneDrive - AZEO\Personnel\BBOX-Administration\Version2"

Start-ChromeDriver -ChromeDriverVersion 'Default' -DownloadPath "C:\Users\ThomasLandel\OneDrive - AZEO\Personnel\BBOX-Administration\Version2\Journal"

Connect-BBOX -UrlHome $UrlHome -Password $Password

$Function = Get-BBoxInformation -UrlToGo $UrlToGo
$Function

#Export-HTMLReport -DataReported $Function -ReportType List -ReportTitle "BBOX Configuration Report - $Page" -ReportPath ".\Report" -ReportFileName "$Page" -HTMLTitle "BBOX Configuration Report" -ReportPrecontent "<h2> $Page </h2>$Description" -Description "Get DEVICE Global Information"

#$Function | Out-GridView
#$Function | Export-Csv -Path "C:\Users\ThomasLandel\OneDrive - AZEO\Personnel\BBOX-Administration\Version2\Export\$Page.csv" -Encoding UTF8 -NoTypeInformation -Delimiter ';' -Force

#Stop-ChromeDriver


