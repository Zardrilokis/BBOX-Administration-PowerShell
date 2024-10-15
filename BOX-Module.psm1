<#
.SYNOPSIS
    Powershell module that contains all function used.

.DESCRIPTION
    Powershell module that contains all function used.
    This module is lincked to script file : .\BBOX-Administration.ps1
    Be carefull some variables are linked from main script Box-Administration.ps1 to :
    - $global:JSONSettingsProgramContent
    - $global:JSONSettingsCurrentUserContent
    - $global:JSONSettingsDefaultUserContent
    - ...
    
    Also be carefull some Global variables are not as a parameter from functions but directly consume in functions
    Examples :
    - $global:BoxType
    - $global:TriggerExitSystem

.EXAMPLE
    To import this module :
    Import-Module '.\BOX-Module.psm1'
    
    To get all information from this module
    Get-module -Name 'BOX-Module'

.INPUTS
    Functions with parameters or not

.OUTPUTS
    Data that transformed by functions
    Windows Forms interraction

.NOTES
    Version : 2.7
    Creation Date : 2020/04/30
    Updated Date  : 2024/10/06
    Updated By    : @Zardrilokis => Tom78_91_45@yahoo.fr
    Author        : @Zardrilokis => Tom78_91_45@yahoo.fr

#>

#region GLOBAL Functions

#region Add AssemblyName Classies

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#endregion Add AssemblyName Classies

#region Logs Files

function Write-Log {

<#
.SYNOPSIS
    Write-Log allow to write fonctionnal execution logs

.DESCRIPTION
    Write a log in the host console and to a csv file.

.PARAMETER Type
    Indicate which type of log
    Valid values : 'INFO','INFONO','VALUE','WARNING','ERROR','DEBUG'
    Defaut value : 'INFO'

.PARAMETER Message
    Write the message you want to display

.PARAMETER Name
    Use to structure the log by categories

.PARAMETER NotDisplay
    Use if you don't want to display the 'message' parameter to the Host Console

.PARAMETER Logname
    This is the full path of the log file

.EXAMPLE
    Message will be displayed in the PowerShell Host Console and in the log file :
    Write-Log -Type INFO -Name "Test Message" -Message "This is a test message" -Logname "C:\Logs\Test.log"

    Message will be displayed only in the log file :
    Write-Log -Type INFO -Name "Test Message" -Message "This is a test message" -Logname "C:\Logs\Test.log" -NotDisplay

.INPUTS
    String

.OUTPUTS
    Files with '.log' extention

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to: All customs functions and the entire scripts

#>

    Param (
        [Parameter(Mandatory=$True)]
        [ValidateSet('INFO','INFONO','VALUE','WARNING','ERROR','DEBUG')]
        $Type = 'INFO',
        
        [Parameter(Mandatory=$True)]
        [ValidateSet('Program initialisation','Program Run','Program Stop')]
        $Category = 'Program Run',
        
        [Parameter(Mandatory=$True)]
        $Name,
        
        [Parameter(Mandatory=$True)]
        $Message,
        
        [Parameter(Mandatory=$False)]
        [switch]$NotDisplay,
        
        [Parameter(Mandatory=$False)]
        $Logname = "$global:LogDateFolderNamePath\$global:LogFileName"
    )
    
    $LogPath = $Logname + '.csv'
    
    # Create log object 
    $log = [pscustomobject] @{Date=(Get-Date -UFormat %Y%m%d_%H%M%S) ; PID=$PID ; user= $(whoami) ; Type=$Type ; Category=$Category ; Name=$Name ; Message=$Message} 
    $log | Add-Member -Name ToString -MemberType ScriptMethod -value {$this.Date + ' : ' + $this.Type + ' : ' + $this.Category + ' : ' + $this.Name + ' : ' + $this.Message} -Force 
    
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
            Out-File -FilePath $LogPath -Encoding unicode -Append -InputObject "Date;PID;Computer-User;Type;Category;Name;Message" 
        }
        Out-File -FilePath $LogPath -Encoding unicode -Append -InputObject "$($Log.date);$($Log.pid);$($Log.user);$($Log.type);$($Log.Category);$($Log.name);$($Log.Message)" 
    }
    Finally {
        $mtx.ReleaseMutex()
    }
}

#endregion Logs Files

#region Windows Credential Manager

# Install module TUN.CredentialManager
Function Install-TUNCredentialManager {

<#
.SYNOPSIS
    To Install 'TUNCredentialManager' Module

.DESCRIPTION
    To Install 'TUNCredentialManager' Module

.PARAMETER ModuleName
    Use the Module Name without the version

.EXAMPLE
    Install-TUNCredentialManager -ModuleName TUNCredentialManager

.INPUTS
    'TUNCredentialManager' module from: https://www.powershellgallery.com

.OUTPUTS
    Null

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Stop-Program'
    Linked to script(s): '.\Box-Administration.ps1'
    Web Link: https://www.powershellgallery.com/packages/TUN.CredentialManager

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$ModuleName
    )
    
    Write-Log -Type INFONO -Category 'Program initialisation' -Name "Powershell $ModuleName Module installation" -Message "Powershell $ModuleName Module installation status : " -NotDisplay
    
    If ($null -eq (Get-InstalledModule -name $ModuleName -ErrorAction SilentlyContinue)) {
        
        Write-Log -Type WARNING -Category 'Program initialisation' -Name "Powershell $ModuleName Module installation" -Message 'Not yet' -NotDisplay
        Write-Log -Type INFO -Category 'Program initialisation' -Name "Powershell $ModuleName Module installation" -Message "Try to install Powershell $ModuleName Module in user context" -NotDisplay
        Write-Log -Type INFO -Category 'Program initialisation' -Name "Powershell $ModuleName Module installation" -Message "Powershell $ModuleName Module installation status : " -NotDisplay
        
        Try {
            Start-Process -FilePath Pwsh -Verb RunAs -WindowStyle Normal -Wait -ArgumentList {-ExecutionPolicy bypass -command "Install-Module -Name TUN.CredentialManager -Scope Allusers -verbose -Force -ErrorAction Stop;Pause"} -ErrorAction Stop
            Start-Sleep -Seconds $global:SleepTUNCredentialManagerModuleinstallation
            Write-Log -Type VALUE -Category 'Program initialisation' -Name "Powershell $ModuleName Module installation" -Message 'Successful' -NotDisplay
        }
        Catch {
            Write-Log -Type WARNING -Category 'Program initialisation' -Name "Powershell $ModuleName Module installation" -Message "Failed, due to $($_.ToString())" -NotDisplay
            Stop-Program -Context System -ErrorAction Stop
        }

        If (($null -eq $global:TriggerExitSystem) -and (Get-InstalledModule -name $ModuleName)) {
        
            Write-Log -Type VALUE -Category 'Program initialisation' -Name "Powershell $ModuleName Module installation" -Message 'Successful' -NotDisplay
            Write-Log -Type INFONO -Category 'Program initialisation' -Name "Powershell $ModuleName Module Importation" -Message "Powershell $ModuleName Module Importation status : " -NotDisplay
            
            Try {
                Import-Module $ModuleName -Global -Force -ErrorAction Stop
                Write-Log -Type VALUE -Category 'Program initialisation' -Name "Powershell $ModuleName Module Importation" -Message 'Successful' -NotDisplay
            }
            Catch {
                Write-Log -Type WARNING -Category 'Program initialisation' -Name "Powershell $ModuleName Module Importation" -Message "Failed, due to $($_.ToString())" -NotDisplay
                Stop-Program -Context System -ErrorAction Stop
            }
        }
        Else {
            Write-Log -Type WARNING -Category 'Program initialisation' -Name "Powershell $ModuleName Module installation" -Message "Failed, due to $($_.ToString())" -NotDisplay
        }
    }
    Else {
        Write-Log -Type VALUE -Category 'Program initialisation' -Name "Powershell $ModuleName Module installation" -Message 'Already installed' -NotDisplay
    }
}

# Unistall module TUN.CredentialManager
Function Uninstall-TUNCredentialManager {

    <#
    .SYNOPSIS
        To Uninstall 'TUNCredentialManager' Module
    
    .DESCRIPTION
        To Uninstall 'TUNCredentialManager' Module
    
    .PARAMETER ModuleName
        Use the Module Name without the version
    
    .EXAMPLE
        Uninstall-TUNCredentialManager -ModuleName TUNCredentialManager
    
    .INPUTS
        'TUNCredentialManager' module from: https://www.powershellgallery.com
    
    .OUTPUTS
        Null
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to function(s): 'Stop-Program'
        Linked to script(s): '.\Box-Administration.ps1'
        Web Link: https://www.powershellgallery.com/packages/TUN.CredentialManager
    
    #>
    
        Param (
            [Parameter(Mandatory=$True)]
            [String]$ModuleName
        )
        
        Write-Log -Type INFONO -Category 'Program initialisation' -Name "Powershell $ModuleName Module uninstallation" -Message "Powershell $ModuleName Module uninstallation status : " -NotDisplay
        
        If ($null -eq (Get-InstalledModule -name $ModuleName -ErrorAction SilentlyContinue)) {
            
            Write-Log -Type WARNING -Category 'Program initialisation' -Name "Powershell $ModuleName Module uninstallation" -Message 'Not yet' -NotDisplay
            Write-Log -Type INFO -Category 'Program initialisation' -Name "Powershell $ModuleName Module uninstallation" -Message "Try to install Powershell $ModuleName Module in user context" -NotDisplay
            Write-Log -Type INFO -Category 'Program initialisation' -Name "Powershell $ModuleName Module uninstallation" -Message "Powershell $ModuleName Module uninstallation status : " -NotDisplay
            
            Try {
                Start-Process -FilePath Pwsh -Verb RunAs -WindowStyle Normal -Wait -ArgumentList {-ExecutionPolicy bypass -command "Uninstall-Module -Name TUN.CredentialManager -confirm:$false -verbose -Force -ErrorAction Stop;Pause"} -ErrorAction Stop
                Start-Sleep -Seconds $global:SleepTUNCredentialManagerModuleinstallation
                Write-Log -Type VALUE -Category 'Program initialisation' -Name "Powershell $ModuleName Module uninstallation" -Message 'Successful' -NotDisplay
            }
            Catch {
                Write-Log -Type WARNING -Category 'Program initialisation' -Name "Powershell $ModuleName Module uninstallation" -Message "Failed, due to $($_.ToString())" -NotDisplay
                Stop-Program -Context System -ErrorAction Stop
            }
            
            If (($null -eq $global:TriggerExitSystem) -and ($null -eq $(Get-InstalledModule -name $ModuleName))) {
                
                Write-Log -Type VALUE -Category 'Program initialisation' -Name "Powershell $ModuleName Module uninstallation" -Message 'Successful' -NotDisplay
            }
            Else {
                Write-Log -Type WARNING -Category 'Program initialisation' -Name "Powershell $ModuleName Module uninstallation" -Message "Failed, due to $($_.ToString())" -NotDisplay
            }
        }
        Else {
            Write-Log -Type VALUE -Category 'Program initialisation' -Name "Powershell $ModuleName Module uninstallation" -Message 'Already uninstalled' -NotDisplay
        }
}

# Remove Box Credential stored in Windows Credential Manager
Function Remove-BoxCredential {

<#
.SYNOPSIS
    To remove Box Credential set to the Windows Credential Manager

.DESCRIPTION
    To remove Box Credential set to the Windows Credential Manager

.PARAMETER 
    

.EXAMPLE
    Remove-BoxCredential

.INPUTS
    Null

.OUTPUTS
    Null

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Remove-StoredCredential'

#>

    Param ()
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Remove Box Credential' -Message 'Start Remove Box Credential' -NotDisplay
    Write-Log -Type INFONO -Category 'Program run' -Name 'Remove Box Credential' -Message 'Remove Box Credential status : ' -NotDisplay
    
    Try {
        $null = Remove-StoredCredential -Target $global:CredentialsTarget -ErrorAction Stop
        Write-Log -Type VALUE -Category 'Program run' -Name 'Remove Box Credential' -Message 'Successful' -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Category 'Program run' -Name 'Remove Box Credential' -Message "Failed, due to : $($_.ToString())" -NotDisplay
    }
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Remove Box Credential' -Message 'End Remove Box Credential' -NotDisplay
}

# Show Box Credential stored in Windows Credential Manager
Function Show-BoxCredential {

<#
.SYNOPSIS
    To display Box Credential stored in the Windows Credential Manager to Standard System Windows Forms MessageBox

.DESCRIPTION
    To display Box Credential stored in the Windows Credential Manager to Standard System Windows Forms MessageBox

.PARAMETER 
    

.EXAMPLE
    Show-BoxCredential

.INPUTS
    Credentials from Windows Credential Manager

.OUTPUTS
    Standard System Windows Forms MessageBox

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-StoredCredential', 'Show-WindowsFormDialogBox'

#>

    Param ()

    Write-Log -Type INFO -Category 'Program run' -Name 'Show Box Credential' -Message 'Start Show Box Credential' -NotDisplay
    Write-Log -Type INFONO -Category 'Program run' -Name 'Show Box Credential' -Message 'Show Box Credential status : ' -NotDisplay

    Try {
        $Password = $(Get-StoredCredential -Target $global:CredentialsTarget | Select-Object -Property Password).password
        
        If ($Password) {
            
            $Password = $Password | ConvertFrom-SecureString -AsPlainText
            Write-Log -Type VALUE -Category 'Program run' -Name 'Show Box Credential' -Message 'Successful' -NotDisplay
            Write-Log -Type INFONO -Category 'Program run' -Name 'Show Box Credential' -Message "Actual $global:BoxType Stored Password : **********" -NotDisplay
        }
        Else {
            $Password = 'None password was found, please set it, before to show it'
            Write-Log -Type VALUE -Category 'Program run' -Name 'Show Box Credential' -Message $Password -NotDisplay
        }
        
        $null = Show-WindowsFormDialogBox -Title 'Program run - Show Box Credential' -Message "Actual $global:BoxType Password stored in Windows Credential Manager : $Password" -InfoIcon
        Clear-Variable -Name Password
    }
    Catch {
        Write-Log -Type WARNING -Category 'Program run' -Name 'Show Box Credential' -Message "Failed, due to : $($_.ToString())" -NotDisplay
    }

    Write-Log -Type INFO -Category 'Program run' -Name 'Show Box Credential' -Message 'Start Show Box Credential' -NotDisplay
}

# Add Box Credential in Windows Credential Manager
function Add-BoxCredential {

<#
.SYNOPSIS
    Add Box Credential in Windows Credential Manager

.DESCRIPTION
    Add Box Credential in Windows Credential Manager

.PARAMETER 
    

.EXAMPLE
    Add-BoxCredential

.INPUTS
    $Credential

.OUTPUTS
    Standard System Windows Forms MessageBox
    Credentials stored in Windows Credential Manager

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Show-BoxCredential'

#>

    Param ()
    
    $Credential = $null
    $Credentialbuild = $null
    Write-Log -Type INFO -Category 'Program run' -Name 'Password Status' -Message 'Asking password to the user ...' -NotDisplay
    
    While ([string]::IsNullOrEmpty($Credential.Password) -or [string]::IsNullOrEmpty($Credential.UserName)) {
        
        # Ask user to provide Box Web Interface Password
        $Credential = Get-Credential -Message "Please enter your $global:BoxType Admin password use for the web portal interface. It will store securly in Windows Credential Manager to be used in future" -UserName $global:CredentialsTarget
    }
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Password Status' -Message 'Set new password to Windows Credential Manager in progress ...' -NotDisplay
    Write-Log -Type INFONO -Category 'Program run' -Name 'Password Status' -Message 'Windows Credential Manager status : ' -NotDisplay

    Try {
        $Comment = $global:CredentialsComment + " - Last modification : $(Get-Date -Format yyyyMMdd-HHmmss) - By : $(whoami)"
        $Password = $Credential.Password | ConvertFrom-SecureString -AsPlainText
        $Credentialbuild = New-StoredCredential -Target $global:CredentialsTarget -UserName $global:CredentialsUserName -Password $Password -Comment $Comment -Type Generic -Persist Session | Out-Null
        Write-Log -Type VALUE -Category 'Program run' -Name 'Password Status' -Message 'Set - $Comment' -NotDisplay
        Clear-Variable -Name Password
    }
    Catch {
        Write-Log -Type WARNING -Category 'Program run' -Name 'Password Status' -Message "Failed, due to : $($_.ToString())" -NotDisplay
    }
    
    Show-BoxCredential
    
    Return $Credentialbuild
    Clear-Variable -Name Credentialbuild
}

# Get Box Credential stored in Windows Credential Manager
Function Get-BoxCredential {

    <#
    .SYNOPSIS
        To display Box Credential stored in the Windows Credential Manager to Standard System Windows Forms MessageBox
    
    .DESCRIPTION
        To display Box Credential stored in the Windows Credential Manager to Standard System Windows Forms MessageBox
    
    .PARAMETER 
        
    
    .EXAMPLE
        Get-BoxCredential
    
    .INPUTS
        Credentials from Windows Credential Manager
    
    .OUTPUTS
        Standard System Windows Forms MessageBox
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to function(s): 'Get-StoredCredential'
    
    #>
    
        Param ()
    
        Write-Log -Type INFO -Category 'Program run' -Name 'Get Box Credential' -Message 'Start Get Box Credential' -NotDisplay
        Write-Log -Type INFONO -Category 'Program run' -Name 'Get Box Credential' -Message 'Get Box Credential status : ' -NotDisplay
    
        Try {
            $Password = Get-StoredCredential -Type 'Generic' -AsCredentialObject
            $Password = $Password | Where-Object {($_.UserName -match "Admin") -and ($null -eq $_.SecurePassword) -and ($_.persist -eq 'session')}
            
            If ($Password) {
                Write-Log -Type VALUE -Category 'Program run' -Name 'Get Box Credential' -Message 'Successful' -NotDisplay
                $Password | Select-Object -Property UserName,TargetName,Comment,LastWritten,Persist,Password | Out-GridView -Title "Admin Box Password Stored in Windows Credantial Management :" -Wait
            }
            Else {
                $Password = 'None password was found, please set it, before to Get it'
                Write-Log -Type VALUE -Category 'Program run' -Name 'Get Box Credential' -Message $Password
                $null = Show-WindowsFormDialogBox -Title 'Program run - Get Box Credential' -Message "Actual box Password stored in Windows Credential Manager : $Password" -InfoIcon
            }
        }
        Catch {
            Write-Log -Type WARNING -Category 'Program run' -Name 'Get Box Credential' -Message "Failed, due to : $($_.ToString())"
        }
    
        Write-Log -Type INFO -Category 'Program run' -Name 'Get Box Credential' -Message 'Start Get Box Credential' -NotDisplay
}

#endregion Windows Credential Manager

#region Windows Form Dialog Box

#region User Input Box

# Used only to get user's 1 input
function Show-WindowsFormDialogBoxInuput {

    <#
    .SYNOPSIS
        To display a Standard System Windows Forms MessageBox with user input
    
    .DESCRIPTION
        To display a Standard System Windows Forms MessageBox with user input
    
    .PARAMETER LabelMessageText
        Text to display in the System Windows Forms MessageBox before user input field
    
    .PARAMETER MainFormTitle
        This is the text display in the header of the message box
    
    .PARAMETER OkButtonText
        Text to display to validate user input
    
    .PARAMETER CancelButtonText
        Text to display to cancel user input
    
    .PARAMETER DefaultValue
        Value set by default in the input field
    
    .EXAMPLE
        Show-WindowsFormDialogBoxInuput -MainFormTitle "This is my Window Header text" -LabelMessageText "This is the body text " -OkButtonText "OK" -CancelButtonText "Cancel"
    
    .INPUTS
        $MainFormTitle
        $LabelMessageText
        $OkButtonText
        $CancelButtonText
    
    .OUTPUTS
        Standard System Windows Forms MessageBox with user input
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to function(s): 'Get-HostStatus', 'Get-PortStatus'
    
    #>
    
        Param (
            [Parameter(Mandatory=$True)]
            [string]$MainFormTitle,
    
            [Parameter(Mandatory=$True)]
            [string]$LabelMessageText,
    
            [Parameter(Mandatory=$True)]
            [string]$OkButtonText,
    
            [Parameter(Mandatory=$True)]
            [string]$CancelButtonText,
    
            [Parameter(Mandatory=$False)]
            [string]$DefaultValue
        )
        
        $MainFormSizeX = 330
        $MainFormSizeY = 250
        
        $LabelMessageSizeX = 300
        $LabelMessageSizeY = 80
        
        $TextBoxSizeX = 100
        $TextBoxSizeY = 40
        
        $OkButtonSizeX = 75
        $OkButtonSizeY = 25
        
        $CancelButtonSizeX = 75
        $CancelButtonSizeY = 25
        
        $LabelMessageLocationX = 20
        $LabelMessageLocationY = 40
        
        $TextBoxLocationX = 20
        $TextBoxLocationY = $LabelMessageLocationY + $LabelMessageSizeY
        
        $OkButtonLocationX = 85
        $OkButtonLocationY = $TextBoxLocationY + $TextBoxSizeY
        
        $CancelButtonLocationX = $OkButtonLocationX + $OkButtonSizeX + 10
        $CancelButtonLocationY = $TextBoxLocationY + $TextBoxSizeY
        
        $MainForm = New-Object System.Windows.Forms.Form
        $MainForm.Text = $MainFormTitle
        $MainForm.Size = New-Object System.Drawing.Size($MainFormSizeX,$MainFormSizeY)
        $MainForm.StartPosition = 'CenterScreen'
        
        $LabelMessage = New-Object System.Windows.Forms.Label
        $LabelMessage.Location = New-Object System.Drawing.Point($LabelMessageLocationX,$LabelMessageLocationY)
        $LabelMessage.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
        $LabelMessage.Text = $LabelMessageText
        $MainForm.Controls.Add($LabelMessage)
        
        $TextBox = New-Object System.Windows.Forms.TextBox
        $TextBox.Location = New-Object System.Drawing.Point($TextBoxLocationX,$TextBoxLocationY)
        $TextBox.Size = New-Object System.Drawing.Size($TextBoxSizeX,$TextBoxSizeY)
        $TextBox.Text = $DefaultValue # Prefield value
        $MainForm.Controls.Add($TextBox)
        
        $OkButton = New-Object System.Windows.Forms.Button
        $OkButton.Location = New-Object System.Drawing.Point($OkButtonLocationX,$OkButtonLocationY)
        $OkButton.Size = New-Object System.Drawing.Size($OkButtonSizeX,$OkButtonSizeY)
        $OkButton.Text = $OkButtonText
        $OkButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $MainForm.AcceptButton = $OkButton
        $MainForm.Controls.Add($OkButton)
        
        $CancelButton = New-Object System.Windows.Forms.Button
        $CancelButton.Location = New-Object System.Drawing.Point($CancelButtonLocationX,$CancelButtonLocationY)
        $CancelButton.Size = New-Object System.Drawing.Size($CancelButtonSizeX,$CancelButtonSizeY)
        $CancelButton.Text = $CancelButtonText
        $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $MainForm.CancelButton = $CancelButton
        $MainForm.Controls.Add($CancelButton)
        
        $MainForm.Topmost = $true
        $MainForm.Add_Shown({$TextBox.Select()})
        
        If ($MainForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            Return $TextBox.Text
        }
        Else {
            $global:TriggerDialogBox = 1
        }
}

# Used only to get user's 5 inputs
function Show-WindowsFormDialogBox8Inuput {

    <#
    .SYNOPSIS
        To display a Standard System Windows Forms MessageBox with user inputs
    
    .DESCRIPTION
        To display a Standard System Windows Forms MessageBox with user inputs
    
    .PARAMETER LabelMessageTextx
        Text to display in the System Windows Forms MessageBox before user input field
    
    .PARAMETER DefaultValuex
        Value set by default in the input field
    
        .PARAMETER MainFormTitle
        This is the text display in the header of the message box
    
    .PARAMETER OkButtonText
        Text to display to validate user input
    
    .PARAMETER CancelButtonText
        Text to display to cancel user input
    
    .EXAMPLE
        Show-WindowsFormDialogBox8Inuput -MainFormTitle "Please complete this form :" -LabelMessageText0 "PhoneNumber :" -DefaultValue0 "+33102030405" -LabelMessageText1 "Prefixe :" -DefaultValue1 "+33" -LabelMessageText2 "Number :" -DefaultValue2 "0102030405" -LabelMessageText3 "Name :" -DefaultValue3 "DUPONT" -LabelMessageText4 "SurName :" -DefaultValue4 "Dupont" -LabelMessageText5 "Description :" -DefaultValue5 "This is the desciption of the contact" -LabelMessageText6 "Category :" -DefaultValue6 "Family / Friend / Others" -LabelMessageText7 "Type :" -DefaultValue7 "Mobile / Fixe" -OkButtonText "OK" -CancelButtonText "Cancel"
    
    .INPUTS
        $MainFormTitle
        $LabelMessageText0
        $LabelMessageText1
        $LabelMessageText2
        $LabelMessageText3
        $LabelMessageText4
        $LabelMessageText5
        $LabelMessageText6
        $LabelMessageText7
        $DefaultValue0
        $DefaultValue1
        $DefaultValue2
        $DefaultValue3
        $DefaultValue4
        $DefaultValue5
        $DefaultValue6
        $DefaultValue7
        $OkButtonText
        $CancelButtonText
    
    .OUTPUTS
        Standard System Windows Forms MessageBox with user inputs
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to function(s): 'Add-NewReferentialContact'
    
    #>
    
        Param (
            [Parameter(Mandatory=$True)]
            [string]$MainFormTitle,

            [Parameter(Mandatory=$True)]
            [string]$LabelMessageText0,
            
            [Parameter(Mandatory=$False)]
            [string]$DefaultValue0,
            
            [Parameter(Mandatory=$True)]
            [string]$LabelMessageText1,
            
            [Parameter(Mandatory=$False)]
            [string]$DefaultValue1,
            
            [Parameter(Mandatory=$True)]
            [string]$LabelMessageText2,
            
            [Parameter(Mandatory=$False)]
            [string]$DefaultValue2,
            
            [Parameter(Mandatory=$True)]
            [string]$LabelMessageText3,
            
            [Parameter(Mandatory=$False)]
            [string]$DefaultValue3,
            
            [Parameter(Mandatory=$True)]
            [string]$LabelMessageText4,
            
            [Parameter(Mandatory=$False)]
            [string]$DefaultValue4,
            
            [Parameter(Mandatory=$True)]
            [string]$LabelMessageText5,
            
            [Parameter(Mandatory=$False)]
            [string]$DefaultValue5,
            
            [Parameter(Mandatory=$True)]
            [string]$LabelMessageText6,
            
            [Parameter(Mandatory=$False)]
            [string]$DefaultValue6,
            
            [Parameter(Mandatory=$True)]
            [string]$LabelMessageText7,
            
            [Parameter(Mandatory=$False)]
            [string]$DefaultValue7,
            
            [Parameter(Mandatory=$True)]
            [string]$OkButtonText,
            
            [Parameter(Mandatory=$True)]
            [string]$CancelButtonText
        )
        
        $MainFormSizeX = 260
        $MainFormSizeY = 600
        
        $LabelMessageSizeX = 300
        $LabelMessageSizeY = 30
        
        $TextBoxSizeX = 200
        $TextBoxSizeY = 40
        
        $OkButtonSizeX = 75
        $OkButtonSizeY = 25
        
        $CancelButtonSizeX = 75
        $CancelButtonSizeY = 25
        
        $LabelMessage0LocationX = 20
        $LabelMessage0LocationY = 20
        
        $TextBox0LocationX = $LabelMessage0LocationX
        $TextBox0LocationY = $LabelMessage0LocationY + $LabelMessageSizeY
        
        $LabelMessage1LocationX = $LabelMessage0LocationX
        $LabelMessage1LocationY = $TextBox0LocationY + $LabelMessageSizeY
        
        $TextBox1LocationX = $LabelMessage0LocationX
        $TextBox1LocationY = $LabelMessage1LocationY + $LabelMessageSizeY
        
        $LabelMessage2LocationX = $LabelMessage0LocationX
        $LabelMessage2LocationY = $TextBox1LocationY + $LabelMessageSizeY
        
        $TextBox2LocationX = $LabelMessage0LocationX
        $TextBox2LocationY = $LabelMessage2LocationY + $LabelMessageSizeY
        
        $LabelMessage3LocationX = $LabelMessage0LocationX
        $LabelMessage3LocationY = $TextBox2LocationY + $LabelMessageSizeY
        
        $TextBox3LocationX = $LabelMessage0LocationX
        $TextBox3LocationY = $LabelMessage3LocationY + $LabelMessageSizeY
        
        $LabelMessage4LocationX = $LabelMessage0LocationX
        $LabelMessage4LocationY = $TextBox3LocationY + $LabelMessageSizeY
        
        $TextBox4LocationX = $LabelMessage0LocationX
        $TextBox4LocationY = $LabelMessage4LocationY + $LabelMessageSizeY
        
        $LabelMessage5LocationX = $LabelMessage0LocationX
        $LabelMessage5LocationY = $TextBox4LocationY + $LabelMessageSizeY
        
        $TextBox5LocationX = $LabelMessage0LocationX
        $TextBox5LocationY = $LabelMessage5LocationY + $LabelMessageSizeY
        
        $LabelMessage6LocationX = $LabelMessage0LocationX
        $LabelMessage6LocationY = $TextBox5LocationY + $LabelMessageSizeY
        
        $TextBox6LocationX = $LabelMessage0LocationX
        $TextBox6LocationY = $LabelMessage6LocationY + $LabelMessageSizeY
        
        $LabelMessage7LocationX = $LabelMessage0LocationX
        $LabelMessage7LocationY = $TextBox6LocationY + $LabelMessageSizeY
        
        $TextBox7LocationX = $LabelMessage0LocationX
        $TextBox7LocationY = $LabelMessage7LocationY + $LabelMessageSizeY
        
        $OkButtonLocationX = $LabelMessage0LocationX
        $OkButtonLocationY = $TextBox7LocationY + $TextBoxSizeY
        
        $CancelButtonLocationX = $OkButtonLocationX + $OkButtonSizeX + 10
        $CancelButtonLocationY = $TextBox7LocationY + $TextBoxSizeY
        
        $MainForm = New-Object System.Windows.Forms.Form
        $MainForm.Text = $MainFormTitle
        $MainForm.Size = New-Object System.Drawing.Size($MainFormSizeX,$MainFormSizeY)
        $MainForm.StartPosition = 'CenterScreen'
        
        $LabelMessage0 = New-Object System.Windows.Forms.Label
        $LabelMessage0.Location = New-Object System.Drawing.Point($LabelMessage0LocationX,$LabelMessage0LocationY)
        $LabelMessage0.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
        $LabelMessage0.Text = $LabelMessageText0
        $MainForm.Controls.Add($LabelMessage0)
        
        $TextBox0 = New-Object System.Windows.Forms.TextBox
        $TextBox0.Location = New-Object System.Drawing.Point($TextBox0LocationX,$TextBox0LocationY)
        $TextBox0.Size = New-Object System.Drawing.Size($TextBoxSizeX,$TextBoxSizeY)
        $TextBox0.Text = $DefaultValue0 # Prefield value
        $MainForm.Controls.Add($TextBox0)
        
        $LabelMessage1 = New-Object System.Windows.Forms.Label
        $LabelMessage1.Location = New-Object System.Drawing.Point($LabelMessage1LocationX,$LabelMessage1LocationY)
        $LabelMessage1.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
        $LabelMessage1.Text = $LabelMessageText1
        $MainForm.Controls.Add($LabelMessage1)
        
        $TextBox1 = New-Object System.Windows.Forms.TextBox
        $TextBox1.Location = New-Object System.Drawing.Point($TextBox1LocationX,$TextBox1LocationY)
        $TextBox1.Size = New-Object System.Drawing.Size($TextBoxSizeX,$TextBoxSizeY)
        $TextBox1.Text = $DefaultValue1 # Prefield value
        $MainForm.Controls.Add($TextBox1)
        
        $LabelMessage2 = New-Object System.Windows.Forms.Label
        $LabelMessage2.Location = New-Object System.Drawing.Point($LabelMessage2LocationX,$LabelMessage2LocationY)
        $LabelMessage2.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
        $LabelMessage2.Text = $LabelMessageText2
        $MainForm.Controls.Add($LabelMessage2)
        
        $TextBox2 = New-Object System.Windows.Forms.TextBox
        $TextBox2.Location = New-Object System.Drawing.Point($TextBox2LocationX,$TextBox2LocationY)
        $TextBox2.Size = New-Object System.Drawing.Size($TextBoxSizeX,$TextBoxSizeY)
        $TextBox2.Text = $DefaultValue2 # Prefield value
        $MainForm.Controls.Add($TextBox2)
        
        $LabelMessage3 = New-Object System.Windows.Forms.Label
        $LabelMessage3.Location = New-Object System.Drawing.Point($LabelMessage3LocationX,$LabelMessage3LocationY)
        $LabelMessage3.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
        $LabelMessage3.Text = $LabelMessageText3
        $MainForm.Controls.Add($LabelMessage3)
        
        $TextBox3 = New-Object System.Windows.Forms.TextBox
        $TextBox3.Location = New-Object System.Drawing.Point($TextBox3LocationX,$TextBox3LocationY)
        $TextBox3.Size = New-Object System.Drawing.Size($TextBoxSizeX,$TextBoxSizeY)
        $TextBox3.Text = $DefaultValue3 # Prefield value
        $MainForm.Controls.Add($TextBox3)
        
        $LabelMessage4 = New-Object System.Windows.Forms.Label
        $LabelMessage4.Location = New-Object System.Drawing.Point($LabelMessage4LocationX,$LabelMessage4LocationY)
        $LabelMessage4.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
        $LabelMessage4.Text = $LabelMessageText4
        $MainForm.Controls.Add($LabelMessage4)
        
        $TextBox4 = New-Object System.Windows.Forms.TextBox
        $TextBox4.Location = New-Object System.Drawing.Point($TextBox4LocationX,$TextBox4LocationY)
        $TextBox4.Size = New-Object System.Drawing.Size($TextBoxSizeX,$TextBoxSizeY)
        $TextBox4.Text = $DefaultValue4 # Prefield value
        $MainForm.Controls.Add($TextBox4)
        
        $LabelMessage5 = New-Object System.Windows.Forms.Label
        $LabelMessage5.Location = New-Object System.Drawing.Point($LabelMessage5LocationX,$LabelMessage5LocationY)
        $LabelMessage5.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
        $LabelMessage5.Text = $LabelMessageText5
        $MainForm.Controls.Add($LabelMessage5)
        
        $TextBox5 = New-Object System.Windows.Forms.TextBox
        $TextBox5.Location = New-Object System.Drawing.Point($TextBox5LocationX,$TextBox5LocationY)
        $TextBox5.Size = New-Object System.Drawing.Size($TextBoxSizeX,$TextBoxSizeY)
        $TextBox5.Text = $DefaultValue5 # Prefield value
        $MainForm.Controls.Add($TextBox5)
        
        $LabelMessage6 = New-Object System.Windows.Forms.Label
        $LabelMessage6.Location = New-Object System.Drawing.Point($LabelMessage6LocationX,$LabelMessage6LocationY)
        $LabelMessage6.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
        $LabelMessage6.Text = $LabelMessageText6
        $MainForm.Controls.Add($LabelMessage6)
        
        $TextBox6 = New-Object System.Windows.Forms.TextBox
        $TextBox6.Location = New-Object System.Drawing.Point($TextBox6LocationX,$TextBox6LocationY)
        $TextBox6.Size = New-Object System.Drawing.Size($TextBoxSizeX,$TextBoxSizeY)
        $TextBox6.Text = $DefaultValue6 # Prefield value
        $MainForm.Controls.Add($TextBox6)
        
        $LabelMessage7 = New-Object System.Windows.Forms.Label
        $LabelMessage7.Location = New-Object System.Drawing.Point($LabelMessage7LocationX,$LabelMessage7LocationY)
        $LabelMessage7.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
        $LabelMessage7.Text = $LabelMessageText7
        $MainForm.Controls.Add($LabelMessage7)
        
        $TextBox7 = New-Object System.Windows.Forms.TextBox
        $TextBox7.Location = New-Object System.Drawing.Point($TextBox7LocationX,$TextBox7LocationY)
        $TextBox7.Size = New-Object System.Drawing.Size($TextBoxSizeX,$TextBoxSizeY)
        $TextBox7.Text = $DefaultValue7 # Prefield value
        $MainForm.Controls.Add($TextBox7)
        
        $OkButton = New-Object System.Windows.Forms.Button
        $OkButton.Location = New-Object System.Drawing.Point($OkButtonLocationX,$OkButtonLocationY)
        $OkButton.Size = New-Object System.Drawing.Size($OkButtonSizeX,$OkButtonSizeY)
        $OkButton.Text = $OkButtonText
        $OkButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $MainForm.AcceptButton = $OkButton
        $MainForm.Controls.Add($OkButton)
        
        $CancelButton = New-Object System.Windows.Forms.Button
        $CancelButton.Location = New-Object System.Drawing.Point($CancelButtonLocationX,$CancelButtonLocationY)
        $CancelButton.Size = New-Object System.Drawing.Size($CancelButtonSizeX,$CancelButtonSizeY)
        $CancelButton.Text = $CancelButtonText
        $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $MainForm.CancelButton = $CancelButton
        $MainForm.Controls.Add($CancelButton)
        
        $MainForm.Topmost = $true
        $MainForm.Add_Shown({$TextBox0.Select()})
        $MainForm.Add_Shown({$TextBox1.Select()})
        $MainForm.Add_Shown({$TextBox2.Select()})
        $MainForm.Add_Shown({$TextBox3.Select()})
        $MainForm.Add_Shown({$TextBox4.Select()})
        $MainForm.Add_Shown({$TextBox5.Select()})
        $MainForm.Add_Shown({$TextBox6.Select()})
        $MainForm.Add_Shown({$TextBox7.Select()})
        
        If ($MainForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            Return [PSCustomObject]@{
                PhoneNumber = $TextBox0.Text
                Prefixe     = $TextBox1.Text
                Number      = $TextBox2.Text
                Name        = $TextBox3.Text
                Surname     = $TextBox4.Text
                Description = $TextBox5.Text
                Category    = $TextBox6.Text
                Type        = $TextBox7.Text
            }
        }
        Else {
            $global:TriggerDialogBox = 1
        }
}

#endregion User Input Box

#region User Display Box

# Used only to display default Windows Form Dialog Box
function Show-WindowsFormDialogBox {

<#
.SYNOPSIS
    To display a Standard System Windows Forms MessageBox

.DESCRIPTION
    To display a Standard System Windows Forms MessageBox

.PARAMETER Message
    Text to display in the System Windows Forms MessageBox

.PARAMETER Title
    This is the text display in the header of the message box

.PARAMETER OKCancel,AbortRetryIgnore,YesNoCancel,YesNo,RetryCancel,ErrorIcon,QuestionIcon,WarnIcon,InfoIcon
    This is the type of Standard System Windows Forms MessageBox you want

.EXAMPLE
    Show-WindowsFormDialogBox -Message "This is the body text " -Title "This is my Window Header text" -OKCancel
    Show-WindowsFormDialogBox -Message "This is the body text " -Title "This is my Window Header text" -AbortRetryIgnore
    Show-WindowsFormDialogBox -Message "This is the body text " -Title "This is my Window Header text" -YesNoCancel
    Show-WindowsFormDialogBox -Message "This is the body text " -Title "This is my Window Header text" -YesNo
    Show-WindowsFormDialogBox -Message "This is the body text " -Title "This is my Window Header text" -RetryCancel
    Show-WindowsFormDialogBox -Message "This is the body text " -Title "This is my Window Header text" -ErrorIcon
    Show-WindowsFormDialogBox -Message "This is the body text " -Title "This is my Window Header text" -QuestionIcon
    Show-WindowsFormDialogBox -Message "This is the body text " -Title "This is my Window Header text" -WarnIcon
    Show-WindowsFormDialogBox -Message "This is the body text " -Title "This is my Window Header text" -InfoIcon

.INPUTS
    String

.OUTPUTS
    PSCustomObject

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Show-BoxCredential', 'Get-HostStatus', 'Get-PortStatus', 'Switch-Info', 'Stop-Program', 'Start-RefreshBBOXWIRELESSFrequencyNeighborhoodScan', 'Get-BBOXBackupList'

#>

    Param (
        [string]$Message = 'Fill in the message',
        [string]$Title = 'WindowTitle',
        [switch]$OKCancel,
        [switch]$AbortRetryIgnore,
        [switch]$YesNoCancel,
        [switch]$YesNo,
        [switch]$RetryCancel,
        [switch]$ErrorIcon,
        [switch]$QuestionIcon,
        [switch]$WarnIcon,
        [switch]$InfoIcon
    )
     
    # Set the value function of the option
    if ($OKCancel) { $Btn = 1 }
    elseif ($AbortRetryIgnore) { $Btn = 2 }
    elseif ($YesNoCancel) { $Btn = 3 }
    elseif ($YesNo) { $Btn = 4 }
    elseif ($RetryCancel) { $Btn = 5 }
    else { $Btn = 0 }
     
    # Affect value for the associated icon
    if ($ErrorIcon) {$Icon = 16 }
    elseif ($QuestionIcon) {$Icon = 32 }
    elseif ($WarnIcon) {$Icon = 48 }
    elseif ($InfoIcon) {$Icon = 64 }
    else {$Icon = 0 }
        
     
    # Call Windows Forms library
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
     
    # Run the messagebox and return the value
    $Answer = [System.Windows.Forms.MessageBox]::Show($Message, $Title , $Btn, $Icon)
    
    Return $Answer
}

# Used only to force user to make a choice between two options none is "Cancel"
function Show-WindowsFormDialogBox2Choices {

<#
.SYNOPSIS
    To display a Standard System Windows Forms MessageBox to force user to make a choice between two options none is "Cancel"

.DESCRIPTION
    To display a Standard System Windows Forms MessageBox to force user to make a choice between two options none is "Cancel"

.PARAMETER LabelMessageText
    Text to display in the System Windows Forms MessageBox

.PARAMETER MainFormTitle
    This is the text display in the header of the message box

.PARAMETER FirstOptionButtonText
    Text to display to get choice 1

.PARAMETER SecondOptionButtonText
    Text to display to get choice 2

.EXAMPLE
    Show-WindowsFormDialogBox2Choices -MainFormTitle "This is my Window Header text" -LabelMessageText "This is the body text " -FirstOptionButtonText "Choice 1" -SecondOptionButtonText "Choice 2"

.INPUTS
    $MainFormTitle
    $LabelMessageText
    $FirstOptionButtonText
    $SecondOptionButtonText

.OUTPUTS
    Standard System Windows Forms MessageBox with bouton user choice

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Switch-OpenExportFolder', 'Switch-DisplayFormat', 'Switch-ExportFormat', 'Switch-OpenHTMLReport', 'Get-PhoneLineID', 'Get-BBOXWANDiagsAllActiveSessions'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [string]$MainFormTitle,

        [Parameter(Mandatory=$True)]
        [string]$LabelMessageText,

        [Parameter(Mandatory=$True)]
        [string]$FirstOptionButtonText,

        [Parameter(Mandatory=$True)]
        [string]$SecondOptionButtonText
    )
    
    $MainFormSizeX = 400
    $MainFormSizeY = 300
    
    $LabelMessageSizeX = 300
    $LabelMessageSizeY = 100
    
    $FirstOptionButtonSizeX = 75
    $FirstOptionButtonSizeY = 25
    
    $SecondOptionButtonSizeX = 75
    $SecondOptionButtonSizeY = 25
    
    $LabelMessageLocationX = 20
    $LabelMessageLocationY = 20
    
    $FirstOptionButtonLocationX = 85
    $FirstOptionButtonLocationY = 130
    
    $SecondOptionButtonLocationX = 170
    $SecondOptionButtonLocationY = 130
    
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = $MainFormTitle
    $MainForm.Size = New-Object System.Drawing.Size($MainFormSizeX,$MainFormSizeY)
    $MainForm.StartPosition = 'CenterScreen'
    
    $LabelMessage = New-Object System.Windows.Forms.Label
    $LabelMessage.Location = New-Object System.Drawing.Point($LabelMessageLocationX,$LabelMessageLocationY)
    $LabelMessage.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
    $LabelMessage.Text = $LabelMessageText
    $MainForm.Controls.Add($LabelMessage)
    
    $FirstOptionButton = New-Object System.Windows.Forms.Button
    $FirstOptionButton.Location = New-Object System.Drawing.Point($FirstOptionButtonLocationX,$FirstOptionButtonLocationY)
    $FirstOptionButton.Size = New-Object System.Drawing.Size($FirstOptionButtonSizeX,$FirstOptionButtonSizeY)
    $FirstOptionButton.Text = $FirstOptionButtonText
    $FirstOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.AcceptButton = $FirstOptionButton
    $MainForm.Controls.Add($FirstOptionButton)
    
    $SecondOptionButton = New-Object System.Windows.Forms.Button
    $SecondOptionButton.Location = New-Object System.Drawing.Point($SecondOptionButtonLocationX,$SecondOptionButtonLocationY)
    $SecondOptionButton.Size = New-Object System.Drawing.Size($SecondOptionButtonSizeX,$SecondOptionButtonSizeY)
    $SecondOptionButton.Text = $SecondOptionButtonText
    $SecondOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.CancelButton = $SecondOptionButton
    $MainForm.Controls.Add($SecondOptionButton)
    
    $MainForm.Topmost = $true
    
    If ($MainForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Return $MainForm.ActiveControl.Text
    }
    Else {
        Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop
    }
}

# Used only to force user to make a choice between two options where one is "Cancel"
function Show-WindowsFormDialogBox2ChoicesCancel {

<#
.SYNOPSIS
    To display a Standard System Windows Forms MessageBox to force user to make a choice between two options where one is "Cancel"

.DESCRIPTION
    To display a Standard System Windows Forms MessageBox to force user to make a choice between two options where one is "Cancel"

.PARAMETER LabelMessageText
    Text to display in the System Windows Forms MessageBox

.PARAMETER MainFormTitle
    This is the text display in the header of the message box

.PARAMETER FirstOptionButtonText
    Text to display to validate user action

.PARAMETER SecondOptionButtonText
    Text to display to cancel action

.EXAMPLE
    Show-WindowsFormDialogBox2ChoicesCancel -MainFormTitle "This is my Window Header text" -LabelMessageText "This is the body text " -FirstOptionButtonText "Action" -SecondOptionButtonText "Cancel"

.INPUTS
    $MainFormTitle
    $LabelMessageText
    $FirstOptionButtonText
    $SecondOptionButtonText

.OUTPUTS
    Standard System Windows Forms MessageBox with bouton user action

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): '',

#>

    Param (
        [Parameter(Mandatory=$True)]
        [string]$MainFormTitle,
        
        [Parameter(Mandatory=$True)]
        [string]$LabelMessageText,
        
        [Parameter(Mandatory=$True)]
        [string]$FirstOptionButtonText,
        
        [Parameter(Mandatory=$True)]
        [string]$SecondOptionButtonText
    )
    
    $MainFormSizeX = 400
    $MainFormSizeY = 300
    
    $LabelMessageSizeX = 300
    $LabelMessageSizeY = 100
    
    $FirstOptionButtonSizeX = 75
    $FirstOptionButtonSizeY = 25
    
    $SecondOptionButtonSizeX = 75
    $SecondOptionButtonSizeY = 25
    
    $LabelMessageLocationX = 20
    $LabelMessageLocationY = 20
    
    $FirstOptionButtonLocationX = 85
    $FirstOptionButtonLocationY = 130
    
    $SecondOptionButtonLocationX = 170
    $SecondOptionButtonLocationY = 130
    
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = $MainFormTitle
    $MainForm.Size = New-Object System.Drawing.Size($MainFormSizeX,$MainFormSizeY)
    $MainForm.StartPosition = 'CenterScreen'
    
    $LabelMessage = New-Object System.Windows.Forms.Label
    $LabelMessage.Location = New-Object System.Drawing.Point($LabelMessageLocationX,$LabelMessageLocationY)
    $LabelMessage.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
    $LabelMessage.Text = $LabelMessageText
    $MainForm.Controls.Add($LabelMessage)
    
    $FirstOptionButton = New-Object System.Windows.Forms.Button
    $FirstOptionButton.Location = New-Object System.Drawing.Point($FirstOptionButtonLocationX,$FirstOptionButtonLocationY)
    $FirstOptionButton.Size = New-Object System.Drawing.Size($FirstOptionButtonSizeX,$FirstOptionButtonSizeY)
    $FirstOptionButton.Text = $FirstOptionButtonText
    $FirstOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.AcceptButton = $FirstOptionButton
    $MainForm.Controls.Add($FirstOptionButton)
    
    $SecondOptionButton = New-Object System.Windows.Forms.Button
    $SecondOptionButton.Location = New-Object System.Drawing.Point($SecondOptionButtonLocationX,$SecondOptionButtonLocationY)
    $SecondOptionButton.Size = New-Object System.Drawing.Size($SecondOptionButtonSizeX,$SecondOptionButtonSizeY)
    $SecondOptionButton.Text = $SecondOptionButtonText
    $SecondOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $MainForm.CancelButton = $SecondOptionButton
    $MainForm.Controls.Add($SecondOptionButton)
    
    $MainForm.Topmost = $true
    
    If ($MainForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Return $MainForm.ActiveControl.Text
    }
    Else {
        Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop
    }
}

# Used only to force user to make a choice between three options
function Show-WindowsFormDialogBox3Choices {

<#
.SYNOPSIS
    To display a Standard System Windows Forms MessageBox to force user to make a choice between three options none is "Cancel"

.DESCRIPTION
    To display a Standard System Windows Forms MessageBox to force user to make a choice between three options none is "Cancel"

.PARAMETER LabelMessageText
    Text to display in the System Windows Forms MessageBox

.PARAMETER MainFormTitle
    This is the text display in the header of the message box

.PARAMETER FirstOptionButtonText
    Text to display to get choice 1

.PARAMETER SecondOptionButtonText
    Text to display to get choice 2

.PARAMETER ThirdOptionButtonText
    Text to display to get choice 3

.EXAMPLE
    Show-WindowsFormDialogBox3Choices -MainFormTitle "This is my Window Header text" -LabelMessageText "This is the body text " -FirstOptionButtonText "Choice 1" -SecondOptionButtonText "Choice 2" -ThirdOptionButtonText "Choice 3"

.INPUTS
    $MainFormTitle
    $LabelMessageText
    $FirstOptionButtonText
    $SecondOptionButtonText
    $ThirdOptionButtonText

.OUTPUTS
    Standard System Windows Forms MessageBox with bouton user choice

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Switch-OpenExportFolder', 'Switch-DisplayFormat', 'Switch-ExportFormat', 'Switch-OpenHTMLReport', 'Get-PhoneLineID', 'Get-BBOXWANDiagsAllActiveSessions'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [string]$MainFormTitle,
        
        [Parameter(Mandatory=$True)]
        [string]$LabelMessageText,
        
        [Parameter(Mandatory=$True)]
        [string]$FirstOptionButtonText,
        
        [Parameter(Mandatory=$True)]
        [string]$SecondOptionButtonText,
        
        [Parameter(Mandatory=$True)]
        [string]$ThirdOptionButtonText
    )
    
    $MainFormSizeX = 300
    $MainFormSizeY = 200
    
    $LabelMessageSizeX = 300
    $LabelMessageSizeY = 90
    
    $FirstOptionButtonSizeX = 75
    $FirstOptionButtonSizeY = 25
    
    $SecondOptionButtonSizeX = 75
    $SecondOptionButtonSizeY = 25
    
    $ThirdOptionButtonSizeX = 75
    $ThirdOptionButtonSizeY = 25
    
    $LabelMessageLocationX = 20
    $LabelMessageLocationY = 20
    
    $FirstOptionButtonLocationX = 20
    $FirstOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $SecondOptionButtonLocationX = $FirstOptionButtonLocationX + $FirstOptionButtonSizeX + 10
    $SecondOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $ThirdOptionButtonLocationX = $SecondOptionButtonLocationX + $SecondOptionButtonSizeX + 10
    $ThirdOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = $MainFormTitle
    $MainForm.Size = New-Object System.Drawing.Size($MainFormSizeX,$MainFormSizeY)
    $MainForm.StartPosition = 'CenterScreen'
    
    $LabelMessage = New-Object System.Windows.Forms.Label
    $LabelMessage.Location = New-Object System.Drawing.Point($LabelMessageLocationX,$LabelMessageLocationY)
    $LabelMessage.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
    $LabelMessage.Text = $LabelMessageText
    $MainForm.Controls.Add($LabelMessage)
    
    $FirstOptionButton = New-Object System.Windows.Forms.Button
    $FirstOptionButton.Location = New-Object System.Drawing.Point($FirstOptionButtonLocationX,$FirstOptionButtonLocationY)
    $FirstOptionButton.Size = New-Object System.Drawing.Size($FirstOptionButtonSizeX,$FirstOptionButtonSizeY)
    $FirstOptionButton.Text = $FirstOptionButtonText
    $FirstOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.AcceptButton = $FirstOptionButton
    $MainForm.Controls.Add($FirstOptionButton)
    
    $SecondOptionButton = New-Object System.Windows.Forms.Button
    $SecondOptionButton.Location = New-Object System.Drawing.Point($SecondOptionButtonLocationX,$SecondOptionButtonLocationY)
    $SecondOptionButton.Size = New-Object System.Drawing.Size($SecondOptionButtonSizeX,$SecondOptionButtonSizeY)
    $SecondOptionButton.Text = $SecondOptionButtonText
    $SecondOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.CancelButton = $SecondOptionButton
    $MainForm.Controls.Add($SecondOptionButton)
    
    $ThirdOptionButton = New-Object System.Windows.Forms.Button
    $ThirdOptionButton.Location = New-Object System.Drawing.Point($ThirdOptionButtonLocationX,$ThirdOptionButtonLocationY)
    $ThirdOptionButton.Size = New-Object System.Drawing.Size($ThirdOptionButtonSizeX,$ThirdOptionButtonSizeY)
    $ThirdOptionButton.Text = $ThirdOptionButtonText
    $ThirdOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.CancelButton = $ThirdOptionButton
    $MainForm.Controls.Add($ThirdOptionButton)
    
    $MainForm.Topmost = $true
    
    If ($MainForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Return $MainForm.ActiveControl.Text
    }
    Else {
        Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop
    }
}

# Used only to force user to make a choice between three options where one is "Cancel"
function Show-WindowsFormDialogBox3ChoicesCancel {

<#
.SYNOPSIS
    To display a Standard System Windows Forms MessageBox to force user to make a choice between three options where one is "Cancel"

.DESCRIPTION
    To display a Standard System Windows Forms MessageBox to force user to make a choice between three options where one is "Cancel"

.PARAMETER LabelMessageText
    Text to display in the System Windows Forms MessageBox

.PARAMETER MainFormTitle
    This is the text display in the header of the message box

.PARAMETER FirstOptionButtonText
    Text to display to validate user action 1

.PARAMETER SecondOptionButtonText
    Text to display to validate user action 2

.PARAMETER ThirdOptionButtonText
    Text to display to cancel action

.EXAMPLE
    Show-WindowsFormDialogBox3ChoicesCancel -MainFormTitle "This is my Window Header text" -LabelMessageText "This is the body text " -FirstOptionButtonText "Action 1" -SecondOptionButtonText "Action 2" -ThirdOptionButtonText "Cancel"

.INPUTS
    $MainFormTitle
    $LabelMessageText
    $FirstOptionButtonText
    $SecondOptionButtonText
    $ThirdOptionButtonText

.OUTPUTS
    Standard System Windows Forms MessageBox with bouton user action

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): '',

#>

    Param (
        [Parameter(Mandatory=$True)]
        [string]$MainFormTitle,
        
        [Parameter(Mandatory=$True)]
        [string]$LabelMessageText,
        
        [Parameter(Mandatory=$True)]
        [string]$FirstOptionButtonText,
        
        [Parameter(Mandatory=$True)]
        [string]$SecondOptionButtonText,
        
        [Parameter(Mandatory=$True)]
        [string]$ThirdOptionButtonText
    )   
    
    $MainFormSizeX = 300
    $MainFormSizeY = 200
    
    $LabelMessageSizeX = 300
    $LabelMessageSizeY = 90
    
    $FirstOptionButtonSizeX = 75
    $FirstOptionButtonSizeY = 25
    
    $SecondOptionButtonSizeX = 75
    $SecondOptionButtonSizeY = 25
    
    $ThirdOptionButtonSizeX = 75
    $ThirdOptionButtonSizeY = 25
    
    $LabelMessageLocationX = 20
    $LabelMessageLocationY = 20
    
    $FirstOptionButtonLocationX = 20
    $FirstOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $SecondOptionButtonLocationX = $FirstOptionButtonLocationX + $FirstOptionButtonSizeX + 10
    $SecondOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $ThirdOptionButtonLocationX = $SecondOptionButtonLocationX + $SecondOptionButtonSizeX + 10
    $ThirdOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = $MainFormTitle
    $MainForm.Size = New-Object System.Drawing.Size($MainFormSizeX,$MainFormSizeY)
    $MainForm.StartPosition = 'CenterScreen'
    
    $LabelMessage = New-Object System.Windows.Forms.Label
    $LabelMessage.Location = New-Object System.Drawing.Point($LabelMessageLocationX,$LabelMessageLocationY)
    $LabelMessage.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
    $LabelMessage.Text = $LabelMessageText
    $MainForm.Controls.Add($LabelMessage)
    
    $FirstOptionButton = New-Object System.Windows.Forms.Button
    $FirstOptionButton.Location = New-Object System.Drawing.Point($FirstOptionButtonLocationX,$FirstOptionButtonLocationY)
    $FirstOptionButton.Size = New-Object System.Drawing.Size($FirstOptionButtonSizeX,$FirstOptionButtonSizeY)
    $FirstOptionButton.Text = $FirstOptionButtonText
    $FirstOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.AcceptButton = $FirstOptionButton
    $MainForm.Controls.Add($FirstOptionButton)
    
    $SecondOptionButton = New-Object System.Windows.Forms.Button
    $SecondOptionButton.Location = New-Object System.Drawing.Point($SecondOptionButtonLocationX,$SecondOptionButtonLocationY)
    $SecondOptionButton.Size = New-Object System.Drawing.Size($SecondOptionButtonSizeX,$SecondOptionButtonSizeY)
    $SecondOptionButton.Text = $SecondOptionButtonText
    $SecondOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.CancelButton = $SecondOptionButton
    $MainForm.Controls.Add($SecondOptionButton)
    
    $ThirdOptionButton = New-Object System.Windows.Forms.Button
    $ThirdOptionButton.Location = New-Object System.Drawing.Point($ThirdOptionButtonLocationX,$ThirdOptionButtonLocationY)
    $ThirdOptionButton.Size = New-Object System.Drawing.Size($ThirdOptionButtonSizeX,$ThirdOptionButtonSizeY)
    $ThirdOptionButton.Text = $ThirdOptionButtonText
    $ThirdOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $MainForm.CancelButton = $ThirdOptionButton
    $MainForm.Controls.Add($ThirdOptionButton)
    
    $MainForm.Topmost = $true
    
    If ($MainForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Return $MainForm.ActiveControl.Text
    }
    Else {
        Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop
    }
}

# Used only to force user to make a choice between three options where one is "Cancel"
function Show-WindowsFormDialogBox4ChoicesCancel {

<#
.SYNOPSIS
    To display a Standard System Windows Forms MessageBox to force user to make a choice between four options where one is "Cancel"

.DESCRIPTION
    To display a Standard System Windows Forms MessageBox to force user to make a choice between four options where one is "Cancel"

.PARAMETER LabelMessageText
    Text to display in the System Windows Forms MessageBox

.PARAMETER MainFormTitle
    This is the text display in the header of the message box

.PARAMETER FirstOptionButtonText
    Text to display to validate user action 1

.PARAMETER SecondOptionButtonText
    Text to display to validate user action 2

.PARAMETER ThirdOptionButtonText
    Text to display to validate user action 3

.PARAMETER FourOptionButtonText
    Text to display to cancel action

.EXAMPLE
    Show-WindowsFormDialogBox4ChoicesCancel -MainFormTitle "This is my Window Header text" -LabelMessageText "This is the body text " -FirstOptionButtonText "Action 1" -SecondOptionButtonText "Action 2" -ThirdOptionButtonText "Action 3" -FourOptionButtonText "Cancel"

.INPUTS
    $MainFormTitle
    $LabelMessageText
    $FirstOptionButtonText
    $SecondOptionButtonText
    $ThirdOptionButtonText
    $FourOptionButtonText

.OUTPUTS
    Standard System Windows Forms MessageBox with bouton user action

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): '',

#>

    Param (
        [Parameter(Mandatory=$True)]
        [string]$MainFormTitle,
        
        [Parameter(Mandatory=$True)]
        [string]$LabelMessageText,
        
        [Parameter(Mandatory=$True)]
        [string]$FirstOptionButtonText,
        
        [Parameter(Mandatory=$True)]
        [string]$SecondOptionButtonText,
        
        [Parameter(Mandatory=$True)]
        [string]$ThirdOptionButtonText,

        [Parameter(Mandatory=$True)]
        [string]$FourOptionButtonText
    )   
    
    $MainFormSizeX = 395
    $MainFormSizeY = 200
    
    $LabelMessageSizeX = 300
    $LabelMessageSizeY = 90
    
    $FirstOptionButtonSizeX = 75
    $FirstOptionButtonSizeY = 25
    
    $SecondOptionButtonSizeX = 75
    $SecondOptionButtonSizeY = 25
    
    $ThirdOptionButtonSizeX = 75
    $ThirdOptionButtonSizeY = 25
    
    $FourOptionButtonSizeX = 75
    $FourOptionButtonSizeY = 25
    
    $LabelMessageLocationX = 20
    $LabelMessageLocationY = 20
    
    $FirstOptionButtonLocationX = 20
    $FirstOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $SecondOptionButtonLocationX = $FirstOptionButtonLocationX + $FirstOptionButtonSizeX + 10
    $SecondOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $ThirdOptionButtonLocationX = $SecondOptionButtonLocationX + $SecondOptionButtonSizeX + 10
    $ThirdOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $FourOptionButtonLocationX = $ThirdOptionButtonLocationX + $ThirdOptionButtonSizeX + 10
    $FourOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = $MainFormTitle
    $MainForm.Size = New-Object System.Drawing.Size($MainFormSizeX,$MainFormSizeY)
    $MainForm.StartPosition = 'CenterScreen'
    
    $LabelMessage = New-Object System.Windows.Forms.Label
    $LabelMessage.Location = New-Object System.Drawing.Point($LabelMessageLocationX,$LabelMessageLocationY)
    $LabelMessage.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
    $LabelMessage.Text = $LabelMessageText
    $MainForm.Controls.Add($LabelMessage)
    
    $FirstOptionButton = New-Object System.Windows.Forms.Button
    $FirstOptionButton.Location = New-Object System.Drawing.Point($FirstOptionButtonLocationX,$FirstOptionButtonLocationY)
    $FirstOptionButton.Size = New-Object System.Drawing.Size($FirstOptionButtonSizeX,$FirstOptionButtonSizeY)
    $FirstOptionButton.Text = $FirstOptionButtonText
    $FirstOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.AcceptButton = $FirstOptionButton
    $MainForm.Controls.Add($FirstOptionButton)
    
    $SecondOptionButton = New-Object System.Windows.Forms.Button
    $SecondOptionButton.Location = New-Object System.Drawing.Point($SecondOptionButtonLocationX,$SecondOptionButtonLocationY)
    $SecondOptionButton.Size = New-Object System.Drawing.Size($SecondOptionButtonSizeX,$SecondOptionButtonSizeY)
    $SecondOptionButton.Text = $SecondOptionButtonText
    $SecondOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.CancelButton = $SecondOptionButton
    $MainForm.Controls.Add($SecondOptionButton)
    
    $ThirdOptionButton = New-Object System.Windows.Forms.Button
    $ThirdOptionButton.Location = New-Object System.Drawing.Point($ThirdOptionButtonLocationX,$ThirdOptionButtonLocationY)
    $ThirdOptionButton.Size = New-Object System.Drawing.Size($ThirdOptionButtonSizeX,$ThirdOptionButtonSizeY)
    $ThirdOptionButton.Text = $ThirdOptionButtonText
    $ThirdOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.CancelButton = $ThirdOptionButton
    $MainForm.Controls.Add($ThirdOptionButton)
    
    $FourOptionButton = New-Object System.Windows.Forms.Button
    $FourOptionButton.Location = New-Object System.Drawing.Point($FourOptionButtonLocationX,$FourOptionButtonLocationY)
    $FourOptionButton.Size = New-Object System.Drawing.Size($FourOptionButtonSizeX,$FourOptionButtonSizeY)
    $FourOptionButton.Text = $FourOptionButtonText
    $FourOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $MainForm.CancelButton = $FourOptionButton
    $MainForm.Controls.Add($FourOptionButton)
    
    $MainForm.Topmost = $true
    
    If ($MainForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Return $MainForm.ActiveControl.Text
    }
    Else {
        Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop
    }
}

# Used only to force user to make a choice between four options where one is "Cancel"
function Show-WindowsFormDialogBox5ChoicesCancel {

<#
.SYNOPSIS
    To display a Standard System Windows Forms MessageBox to force user to make a choice between five options where one is "Cancel"

.DESCRIPTION
    To display a Standard System Windows Forms MessageBox to force user to make a choice between five options where one is "Cancel"

.PARAMETER LabelMessageText
    Text to display in the System Windows Forms MessageBox

.PARAMETER MainFormTitle
    This is the text display in the header of the message box

.PARAMETER FirstOptionButtonText
    Text to display to validate user action 1

.PARAMETER SecondOptionButtonText
    Text to display to validate user action 2

.PARAMETER ThirdOptionButtonText
    Text to display to validate user action 3

.PARAMETER FourOptionButtonText
    Text to display to validate user action 4

.PARAMETER FiveOptionButtonText
    Text to display to cancel action

.EXAMPLE
    Show-WindowsFormDialogBox5ChoicesCancel -MainFormTitle "This is my Window Header text" -LabelMessageText "This is the body text " -FirstOptionButtonText "Action 1" -SecondOptionButtonText "Action 2" -ThirdOptionButtonText "Action 3" -FourOptionButtonText "Action 4" -FiveOptionButtonText "Cancel"

.INPUTS
    $MainFormTitle
    $LabelMessageText
    $FirstOptionButtonText
    $SecondOptionButtonText
    $ThirdOptionButtonText
    $FourOptionButtonText
    $FiveOptionButtonText

.OUTPUTS
    Standard System Windows Forms MessageBox with bouton user action

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): '',

#>

    Param (
        [Parameter(Mandatory=$True)]
        [string]$MainFormTitle,
        
        [Parameter(Mandatory=$True)]
        [string]$LabelMessageText,
        
        [Parameter(Mandatory=$True)]
        [string]$FirstOptionButtonText,
        
        [Parameter(Mandatory=$True)]
        [string]$SecondOptionButtonText,
        
        [Parameter(Mandatory=$True)]
        [string]$ThirdOptionButtonText,
        
        [Parameter(Mandatory=$True)]
        [string]$FourOptionButtonText,
        
        [Parameter(Mandatory=$True)]
        [string]$FiveOptionButtonText
    )   
    
    $MainFormSizeX = 480
    $MainFormSizeY = 200
    
    $LabelMessageSizeX = 300
    $LabelMessageSizeY = 90
    
    $LabelMessageLocationX = 20
    $LabelMessageLocationY = 20
    
    $FirstOptionButtonSizeX = 75
    $FirstOptionButtonSizeY = 25
    
    $SecondOptionButtonSizeX = 75
    $SecondOptionButtonSizeY = 25
    
    $ThirdOptionButtonSizeX = 75
    $ThirdOptionButtonSizeY = 25
    
    $FourOptionButtonSizeX = 75
    $FourOptionButtonSizeY = 25
    
    $FiveOptionButtonSizeX = 75
    $FiveOptionButtonSizeY = 25
    
    $FirstOptionButtonLocationX = 20
    $FirstOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $SecondOptionButtonLocationX = $FirstOptionButtonLocationX + $FirstOptionButtonSizeX + 10
    $SecondOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $ThirdOptionButtonLocationX = $SecondOptionButtonLocationX + $SecondOptionButtonSizeX + 10
    $ThirdOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $FourOptionButtonLocationX = $ThirdOptionButtonLocationX + $ThirdOptionButtonSizeX + 10
    $FourOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $FiveOptionButtonLocationX = $FourOptionButtonLocationX + $FourOptionButtonSizeX + 10
    $FiveOptionButtonLocationY = $LabelMessageSizeY + $LabelMessageLocationY
    
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = $MainFormTitle
    $MainForm.Size = New-Object System.Drawing.Size($MainFormSizeX,$MainFormSizeY)
    $MainForm.StartPosition = 'CenterScreen'
    
    $LabelMessage = New-Object System.Windows.Forms.Label
    $LabelMessage.Location = New-Object System.Drawing.Point($LabelMessageLocationX,$LabelMessageLocationY)
    $LabelMessage.Size = New-Object System.Drawing.Size($LabelMessageSizeX,$LabelMessageSizeY)
    $LabelMessage.Text = $LabelMessageText
    $MainForm.Controls.Add($LabelMessage)
    
    $FirstOptionButton = New-Object System.Windows.Forms.Button
    $FirstOptionButton.Location = New-Object System.Drawing.Point($FirstOptionButtonLocationX,$FirstOptionButtonLocationY)
    $FirstOptionButton.Size = New-Object System.Drawing.Size($FirstOptionButtonSizeX,$FirstOptionButtonSizeY)
    $FirstOptionButton.Text = $FirstOptionButtonText
    $FirstOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.AcceptButton = $FirstOptionButton
    $MainForm.Controls.Add($FirstOptionButton)
    
    $SecondOptionButton = New-Object System.Windows.Forms.Button
    $SecondOptionButton.Location = New-Object System.Drawing.Point($SecondOptionButtonLocationX,$SecondOptionButtonLocationY)
    $SecondOptionButton.Size = New-Object System.Drawing.Size($SecondOptionButtonSizeX,$SecondOptionButtonSizeY)
    $SecondOptionButton.Text = $SecondOptionButtonText
    $SecondOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.CancelButton = $SecondOptionButton
    $MainForm.Controls.Add($SecondOptionButton)
    
    $ThirdOptionButton = New-Object System.Windows.Forms.Button
    $ThirdOptionButton.Location = New-Object System.Drawing.Point($ThirdOptionButtonLocationX,$ThirdOptionButtonLocationY)
    $ThirdOptionButton.Size = New-Object System.Drawing.Size($ThirdOptionButtonSizeX,$ThirdOptionButtonSizeY)
    $ThirdOptionButton.Text = $ThirdOptionButtonText
    $ThirdOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.CancelButton = $ThirdOptionButton
    $MainForm.Controls.Add($ThirdOptionButton)
    
    $FourOptionButton = New-Object System.Windows.Forms.Button
    $FourOptionButton.Location = New-Object System.Drawing.Point($FourOptionButtonLocationX,$FourOptionButtonLocationY)
    $FourOptionButton.Size = New-Object System.Drawing.Size($FourOptionButtonSizeX,$FourOptionButtonSizeY)
    $FourOptionButton.Text = $FourOptionButtonText
    $FourOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $MainForm.CancelButton = $FourOptionButton
    $MainForm.Controls.Add($FourOptionButton)
    
    $FiveOptionButton = New-Object System.Windows.Forms.Button
    $FiveOptionButton.Location = New-Object System.Drawing.Point($FiveOptionButtonLocationX,$FiveOptionButtonLocationY)
    $FiveOptionButton.Size = New-Object System.Drawing.Size($FiveOptionButtonSizeX,$FiveOptionButtonSizeY)
    $FiveOptionButton.Text = $FiveOptionButtonText
    $FiveOptionButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $MainForm.CancelButton = $FiveOptionButton
    $MainForm.Controls.Add($FiveOptionButton)
    
    $MainForm.Topmost = $true
    
    If ($MainForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Return $MainForm.ActiveControl.Text
    }
    Else {
        Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop
    }
}

#endregion User Display Box

#endregion Windows Form Dialog Box

#region Program

# Used only to stop and quit the Program
Function Stop-Program {

<#
.SYNOPSIS
    To stop and quit the Program

.DESCRIPTION
    To stop and quit the Program

.EXAMPLE
    Stop-ChromeDriver -Context User
    Stop-ChromeDriver -Context System

.INPUTS
    $Context
    Only 2 value possible :
    - User (If the user enter wrong value or settings)
    - System (If something wrong when system working)

.OUTPUTS
    Stop All ChromeDriver and StandAlone Google Chrome Processes

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Write-Log', 'Show-WindowsFormDialogBox', 'Stop-ChromeDriver','Import-TUNCredentialManager', 'Show-WindowsFormDialogBox2Choices', 'Show-WindowsFormDialogBox2ChoicesCancel', 'Show-WindowsFormDialogBox3Choices', 'Show-WindowsFormDialogBox3ChoicesCancel', 'Test-FolderPath', 'Test-FilePath', 'Get-HostStatus', 'Get-PortStatus', 'Connect-Box', 'Switch-Info', 'Get-JSONSettingsCurrentUserContent', 'Get-JSONSettingsDefaultUserContent', 'Reset-CurrentUserProgramConfiguration'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$False)]
        [ValidateSet("User","System")]
        $Context,
        
        [Parameter(Mandatory=$False)]
        $ErrorMessage,
        
        [Parameter(Mandatory=$False)]
        $Reason
    )
    
    Switch ($Context) {
        
        User    {Write-Log -Type VALUE -Category 'Program Stop' -Name 'Action asked' -Message 'Cancelled by user'
                    $null = Show-WindowsFormDialogBox -Title 'Program Stop' -Message "Program exiting due to User cancelled action `nPlease dont close windows manually !`nWe are closing background processes before to quit the program`nPlease wait ..." -InfoIcon
                }
        System  {Write-Log -Type ERROR -Category 'Program Stop' -Name 'Program Stop' -Message "Program exiting due to : $ErrorMessage - Reason : $Reason `nPlease dont close windows manually !`nWe are closing background processes before to quit the program`nPlease wait ..."
                    $null = Show-WindowsFormDialogBox -Title 'Program Stop' -Message "Program exiting due to : $ErrorMessage -Reason : $Reason `nPlease dont close windows manually !`nWe are closing background processes before to quit the program`nPlease wait ..." -WarnIcon
                }
        Default {Write-Log -Type ERROR -Category 'Program Stop' -Name 'Program Stop' -Message "Program exiting due to : $ErrorMessage - Reason : $Reason `nPlease dont close windows manually !`nWe are closing background processes before to quit the program`nPlease wait ..."
                    $null = Show-WindowsFormDialogBox -Title 'Program Stop' -Message "Program exiting due to : $ErrorMessage - Reason : $Reason `nPlease dont close windows manually !`nWe are closing background processes before to quit the program`nPlease wait ..." -WarnIcon
                }
    }
    
    <#If ($Null -ne $global:ChromeDriver) {
        
        Write-Log -Type INFO -Name 'Stop Chrome Driver' -Message 'Start Stop Chrome Driver' -NotDisplay
        Stop-ChromeDriver
        Write-Log -Type INFO -Name 'Stop Chrome Driver' -Message 'End Stop Chrome Driver' -NotDisplay
    }#>
    
    Start-Sleep $global:SleepChromeDriverNavigation
    Get-Process -ErrorAction SilentlyContinue | Select-Object -Property ProcessName, Id, CPU, Path -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "$global:RessourcesFolderNamePath*"} -ErrorAction SilentlyContinue | Sort-Object -Property ProcessName -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
    $Current_Log_File = "$global:LogDateFolderNamePath\" + (Get-ChildItem -Path $global:LogDateFolderNamePath -Name "$global:LogFileName*" | Select-Object -Property PSChildName | Sort-Object PSChildName -Descending)[0].PSChildName
    Write-Log -Type INFONO -Category 'Program Stop' -Name 'Program Stop' -Message 'Detailed Log file is available here : '
    Write-Log -Type VALUE -Category 'Program Stop' -Name 'Program Stop' -Message $Current_Log_File
    Write-Log -Type WARNING -Category 'Program Stop' -Name 'Program Stop' -Message "Don't forget to close the log files before to launch again the program"
    Write-Log -Type WARNING -Category 'Program Stop' -Name 'Program Stop' -Message "Else the program failed to start the next time"
    Write-Log -Type INFO -Category 'Program Stop' -Name 'Program Stop' -Message 'Program Closed' -NotDisplay
    Write-Log -Type INFO -Category 'Program Stop' -Name 'Program Stop' -Message 'End Program' -NotDisplay
    
    Stop-Transcript -ErrorAction Stop
    
    Exit
}

# Used only to unistall the Program
Function Uninstall-Program {

    <#
    .SYNOPSIS
        To uninstall the Program
    
    .DESCRIPTION
        To uninstall the Program
    
    .EXAMPLE
        Uninstall-Program
    
    .INPUTS
        User Action
    
    .OUTPUTS
        - Stop All ChromeDriver and StandAlone Google Chrome Processes
        - Remove registred credentials
        - Unistall Modules (BOX-Module.psm1 & TUN.CredentialManager) with Admin Rights
        - Remove Chrome Driver registry path
        - Remove All files
        - Remove Logs (Stop-Transcript)
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to function(s): 'Write-Log', 'Show-WindowsFormDialogBox', 'Stop-ChromeDriver','Import-TUNCredentialManager', 'Show-WindowsFormDialogBox2Choices', 'Show-WindowsFormDialogBox2ChoicesCancel', 'Show-WindowsFormDialogBox3Choices', 'Show-WindowsFormDialogBox3ChoicesCancel', 'Test-FolderPath', 'Test-FilePath', 'Get-HostStatus', 'Get-PortStatus', 'Connect-Box', 'Switch-Info', 'Get-JSONSettingsCurrentUserContent', 'Get-JSONSettingsDefaultUserContent', 'Reset-CurrentUserProgramConfiguration'
        Linked to script(s): '.\Box-Administration.psm1'
    
    #>
    
        Param ()
        
        # Stop All ChromeDriver and StandAlone Google Chrome Processes
        Get-Process -ErrorAction SilentlyContinue | Select-Object -Property ProcessName, Id, CPU, Path -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "$global:RessourcesFolderNamePath*"} -ErrorAction SilentlyContinue | Sort-Object -Property ProcessName -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
        $Current_Log_File = "$global:LogDateFolderNamePath\" + (Get-ChildItem -Path $global:LogDateFolderNamePath -Name "$global:LogFileName*" | Select-Object -Property PSChildName | Sort-Object PSChildName -Descending)[0].PSChildName
        Write-Log -Type INFONO -Category 'Program Stop' -Name 'Program Stop' -Message 'Detailed Log file is available here : '
        Write-Log -Type VALUE -Category 'Program Stop' -Name 'Program Stop' -Message $Current_Log_File
        Write-Log -Type WARNING -Category 'Program Stop' -Name 'Program Stop' -Message "Don't forget to close the log files before to launch again the program"
        Write-Log -Type WARNING -Category 'Program Stop' -Name 'Program Stop' -Message "Else the program failed to start the next time"
        Write-Log -Type INFO -Category 'Program Stop' -Name 'Program Stop' -Message 'Program Closed' -NotDisplay 
        
        # Remove Stored Credential
        Remove-StoredCredential -Target 'AdminBBox' -ErrorAction Continue
        Remove-StoredCredential -Target 'AdminFREEBox' -ErrorAction Continue
        
        # Remove / Uninstall Modules
        remove-module -Name BOX-Module -ErrorAction Continue
        remove-module -Name TUN.CredentialManager -ErrorAction Continue
        Uninstall-TUNCredentialManager -ModuleName 'TUN.CredentialManager' -ErrorAction Continue
        
        # Stop-Transcript Logs
        Stop-Transcript -ErrorAction Continue
        
        #Remove All Files
        #Remove-Item -Path $PSScriptRoot -Recurse -Force -ErrorAction Continue
        Get-Childitem -Path $PSScriptRoot -Recurse | Remove-Item -Force -Confirm:$false
        Write-Host "Uninstallation finished" -ForegroundColor Green
        Write-Host "Please remove manually the root foler of the program : $PSScriptRoot" -ForegroundColor Yellow
        Pause
        Exit
}

# Clean folder content
Function Remove-FolderContent {

<#
.SYNOPSIS
    Clean folder content

.DESCRIPTION
    Clean folder content

.PARAMETER FolderRoot
    This is the root Parent folder full path of the folder Name to clean

.PARAMETER FolderName
    This is the folder Name to clean content

.EXAMPLE
    Remove-FolderContent -FolderRoot 'C:\Windows' -FolderName "Temp"

.INPUTS
    $FolderRoot
    $FolderName

.OUTPUTS
    Folder content removed

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    linked to Actions : 'Remove-FCLogs', 'Remove-FCExportCSV', 'Remove-FCExportJSON', 'Remove-FCJournal', 'Remove-FCJBC', 'Remove-FCReport'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$FolderRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$FolderName
    )
    
    $FolderPath = "$FolderRoot\$FolderName\*"
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Clean folder content' -Message "Start Clean `"$FolderPath`" folder" -NotDisplay
    
    If (Test-Path -Path $FolderPath) {
        
        Write-Log -Type INFONO -Category 'Program run' -Name 'Clean folder content' -Message "Cleaning `"$FolderPath`" folder content Status : " -NotDisplay
        Try {
            $Null = Remove-Item -Path $FolderPath -Recurse -Exclude $global:TranscriptFileName
            Write-Log -Type VALUE -Category 'Program run' -Name 'Clean folder content' -Message 'Successful' -NotDisplay
        }
        Catch {
            Write-Log -Type ERROR -Category 'Program run' -Name 'Clean folder content' -Message "Failed, `"$FolderPath`" folder can't be cleaned due to : $($_.ToString())"
        }
    }
    Else {
         Write-Log -Type INFONO -Category 'Program run' -Name 'Clean folder content' -Message "`"$FolderPath`" folder state : " -NotDisplay
         Write-Log -Type VALUE -Category 'Program run' -Name 'Clean folder content' -Message 'Do no exist' -NotDisplay
    }
    Write-Log -Type INFO -Category 'Program run' -Name 'Clean folder content' -Message "End Clean `"$FolderPath`" folder content" -NotDisplay
}

# Clean All folder content
Function Remove-FolderContentAll {

    <#
    .SYNOPSIS
        Clean All folder content
    
    .DESCRIPTION
        Clean All folder content
    
    .PARAMETER FolderRoot
        This is the root Parent folder full path of the folder Name to clean
    
    .PARAMETER FoldersName
        This is the list of folder Name to clean content
    
    .EXAMPLE
        Remove-FolderContentAll -FolderRoot 'C:\Windows' -FoldersName "Temp,Test,..."
    
    .INPUTS
        $FolderRoot
        $FolderName
    
    .OUTPUTS
        Folder content removed
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to Actions : 'Switch-Info'
    
    #>
    
        Param (
            [Parameter(Mandatory=$True)]
            [String]$FolderRoot,
            
            [Parameter(Mandatory=$True)]
            [String]$FoldersName
        )
        
        $TempFoldersName = $($FoldersName.Split(","))
        
        Foreach ($FolderName in $TempFoldersName) {
            
            $FolderPath = "$FolderRoot\$FolderName\*"
            
            Try {
                Remove-FolderContent -FolderRoot $FolderRoot -FolderName $FolderName -ErrorAction SilentlyContinue
            }
            Catch {
                Write-Log -Type ERROR -Category 'Program run' -Name 'Clean folders content' -Message "Failed, `"$FolderPath`" folder can't be cleaned due to : $($_.ToString())"
            }
        }
        
        Write-Log -Type INFO -Category 'Program run' -Name 'Clean folders content' -Message "End Clean `"$FolderPath`" folder content" -NotDisplay
}

# Test and create folder if not yet existing
Function Test-FolderPath {

<#
.SYNOPSIS
    Test and create folder if not yet existing

.DESCRIPTION
    Test and create folder if not yet existing

.PARAMETER FolderRoot
    Root Folder path where the folder is located

.PARAMETER FolderPath
    Folder full path

.PARAMETER FolderName
    Folder Name that already exist or to be create

.EXAMPLE
    Test-FolderPath -FolderRoot "C:\Windows" -FolderPath "C:\Windows\Temp" -FolderName "Temp"

.INPUTS
    $FolderRoot
    $FolderPath
    $FolderName

.OUTPUTS
    Folder created

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$FolderRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$FolderPath,
        
        [Parameter(Mandatory=$True)]
        [String]$FolderName
    )
    
    $FolderName = ($FolderName.Split('\'))[-1]
    
    Write-Log -Type INFO -Category 'Program initialisation' -Name 'Program Folders check' -Message "Start folder check : $FolderName" -NotDisplay
    Write-Log -Type INFO -Category 'Program initialisation' -Name 'Program Folders check' -Message "Folder : $FolderPath" -NotDisplay
    Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Program Folders check' -Message "State : " -NotDisplay
    
    If (-not (Test-Path -Path $FolderPath)) {
        
        Write-Log -Type WARNING -Category 'Program initialisation' -Name 'Program Folders check' -Message "Doesn't exists" -NotDisplay
        Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Program Folders check' -Message "Creation folder : $FolderPath , status : " -NotDisplay
        Try {
            $Null = New-Item -Path $FolderRoot -Name $FolderName -ItemType Directory -Force
            Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Program Folders check' -Message 'Successful' -NotDisplay
        }
        Catch {
            Write-Log -Type ERROR -Category 'Program initialisation' -Name 'Program Folders check' -Message "Failed, `"$FolderPath`" folder can't be created due to : $($_.ToString())"
            Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason "The current folder : $FolderPath , can not be created" -ErrorAction Stop
        }
    }
    Else {
        Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Program Folders check' -Message 'Already exists' -NotDisplay
    }
    Write-Log -Type INFO -Category 'Program initialisation' -Name 'Program Folders check' -Message "End folder check : $FolderName" -NotDisplay
}

# Test and create file if not yet existing
Function Test-FilePath {

<#
.SYNOPSIS
    Test and create file if not yet existing

.DESCRIPTION
    Test and create file if not yet existing

.PARAMETER FileRoot
    Root File path where the file is located

.PARAMETER FilePath
    File full path

.PARAMETER FilePath
    File Name that already exist or to be create

.EXAMPLE
    Test-FilePath -FileRoot "C:\Windows" -FilePath "C:\Windows\Temp" -FileName "Temp"

.INPUTS
    $FileRoot
    $FilePath
    $FileName

.OUTPUTS
    File created

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$FileRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$FilePath,
        
        [Parameter(Mandatory=$True)]
        [String]$FileName
    )
    
    $FileName = ($FileName.Split('\'))[-1]
    
    Write-Log -Type INFO -Category 'Program initialisation' -Name 'Program Files check' -Message "Start file check : $FileName" -NotDisplay
    Write-Log -Type INFO -Category 'Program initialisation' -Name 'Program Files check' -Message "File : $FilePath" -NotDisplay
    Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Program Files check' -Message "State : " -NotDisplay
    
    If (-not (Test-Path -Path $FilePath)) {
    
        Write-Log -Type WARNING -Category 'Program initialisation' -Name 'Program Files check' -Message "Doesn't exists" -NotDisplay
        Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Program Files check' -Message "Creation file status : " -NotDisplay
        Try {
            $Null = New-Item -Path $FileRoot -Name $FileName -ItemType File -Force
            Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Program Files check' -Message 'Successful' -NotDisplay
        }
        Catch {
            Write-Log -Type ERROR -Category 'Program initialisation' -Name 'Program Files check' -Message "Failed, `"$FilePath`" file can't be created due to : $($_.ToString())"
            Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason "The file : $FilePath can nott be created" -ErrorAction Stop
        }
    }
    Else {
        Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Program Files check' -Message 'Already exists' -NotDisplay
    }
    Write-Log -Type INFO -Category 'Program initialisation' -Name 'Program Files check' -Message "End file check : $FileName" -NotDisplay
}

# Import Program and Box Actions available
function Import-Referential {
    
<#
.SYNOPSIS
    Import Program and Box Actions available

.DESCRIPTION
    Import Program and Box Actions available

.PARAMETER ReferentialPath
    Full Referential Path

.EXAMPLE
    Import-Referential -ReferentialPath "C:\Temp\ReferentialFilePath.csv"

.INPUTS
    $ReferentialPath

.OUTPUTS
    Actions loaded to the program

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to script(s): '.\Box-Administration.psm1'

#>
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$ReferentialPath,
        
        [Parameter(Mandatory=$True)]
        [String]$LogCategory,
        
        [Parameter(Mandatory=$True)]
        [String]$LogName
    )
    
    Write-Log -Type INFO -Category $LogCategory -Name $LogName -Message 'Start Referentiel Importation' -NotDisplay
    Write-Log -Type INFO -Category $LogCategory -Name $LogName -Message 'Importing Referentiel from : ' -NotDisplay
    Write-Log -Type VALUE -Category $LogCategory -Name $LogName -Message "$ReferentialPath" -NotDisplay
    Write-Log -Type INFONO -Category $LogCategory -Name $LogName -Message "Importing Referentiel Status : " -NotDisplay
    
    Try {
        $Actions = Import-Csv -Path $ReferentialPath -Delimiter ';' -Encoding utf8 -ErrorAction Stop
        Write-Log -Type VALUE -Category $LogCategory -Name $LogName -Message 'Successful' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category $LogCategory -Name $LogName -Message "Failed. Referentiel can't be imported, due to : $($_.ToString())"
        Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason 'The Referentiel can not be imported, due to : $($_.ToString())' -ErrorAction Stop
    }
    
    Write-Log -Type INFO -Category $LogCategory -Name $LogName -Message 'End Referentiel Importation' -NotDisplay
    
    Return $Actions
}

# Get help regarding the PowerShell Module : '.\BOX-Module.'psm1
function Export-ModuleHelp {

    <#
    .SYNOPSIS
        Get all details that are in a module
    
    .DESCRIPTION
        Get all details that are in a module
    
    .PARAMETER ModuleFileName
        This is the name of the module
    
    .PARAMETER ExportFolderPath
        This is the folder to export result
    
    .EXAMPLE
        Export-ModuleHelp -ModuleFileName "BOX-Module" -ExportFolderPath "C:\temp\Get-Date"
    
    .INPUTS
        $ModuleFileName
    
    .OUTPUTS
        Export result to '.CSV', file
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to script(s): '.\Box-Administration.psm1'
    
    #>
        
    Param (
        [Parameter(Mandatory=$True)]
        [String]$ModuleFileName,
        
        [Parameter(Mandatory=$True)]
        [String]$ExportFolderPath
    )
    
    # Create folder date if do not exist
    $FolderDate = Get-Date -Format yyyyMMdd
    $ExportFolderFullPath = "$ExportFolderPath\$FolderDate"
    
    If ($(Test-Path -Path "$ExportFolderFullPath") -eq $False) {
        
        $null = New-Item -Path $ExportFolderPath -Name $FolderDate -ItemType Directory -Force
    }
    
    # Get all function associated to the module
    $ModuleDetails = Get-Module -Name $ModuleFileName
    
    $Array = @()
    $Date = Get-Date -Format yyyyMMdd-hhmmss
    $SummaryDetailsModuleFilePath = "$ExportFolderFullPath\$Date-SummaryDetailsModule-$ModuleFileName.csv"
    
    $line = New-Object -TypeName PSObject
    $Line | Add-Member -Name 'Name'                -MemberType NoteProperty -Value $ModuleDetails.Name
    $Line | Add-Member -Name 'Path'                -MemberType NoteProperty -Value $ModuleDetails.Path
    $Line | Add-Member -Name 'Description'         -MemberType NoteProperty -Value $ModuleDetails.Description
    $Line | Add-Member -Name 'Module Type'         -MemberType NoteProperty -Value $ModuleDetails.ModuleType
    $Line | Add-Member -Name 'Version'             -MemberType NoteProperty -Value $ModuleDetails.Version
    $Line | Add-Member -Name 'Number of functions' -MemberType NoteProperty -Value $ModuleDetails.ExportedCommands.count
    $Line | Add-Member -Name 'Exported Functions'  -MemberType NoteProperty -Value $($ModuleDetails.ExportedCommands.Keys -Join ",")
    
    $Array += $Line
    $Array | Export-Csv -Path $SummaryDetailsModuleFilePath -Force -Encoding utf8 -Delimiter ';' -NoTypeInformation
    Return $Array
}

# Get All help foreach functions in PowerShell Module : '.\BOX-Module.'psm1
function Export-ModuleFunctions {

    <#
    .SYNOPSIS
        Get All Functions details that are in a module
    
    .DESCRIPTION
        Get All Functions details that are in a module and export them to .json, .CSV, .TXT
    
    .PARAMETER ModuleFolderPath
        This is the path of the module without the name of the module and the extention file (.psm1)
    
    .PARAMETER ModuleFileName
        This is the name of the module
    
    .PARAMETER FileExtention
        This is the file extention for module, must be : .psm1
    
    .PARAMETER ExportFolderPath
        This is the path where for all functions have got a dedicated file will be create.
    
    .EXAMPLE
        Export-ModuleFunctions -ModuleFolderPath "C:\Temp" -ModuleFileName "BOX-Module" -FileExtention ".psm1" -ExportFolderPath "C:\Temp\GetHelp"
    
    .EXAMPLE
        Export-ModuleFunctions -ModuleFolderPath "C:\Temp" -ModuleFileName "BOX-Module" -FileExtention ".psm1" -ExportFolderPath "C:\Temp\GetHelp" -SummaryExport
    
    .EXAMPLE
        Export-ModuleFunctions -ModuleFolderPath "C:\Temp" -ModuleFileName "BOX-Module" -FileExtention ".psm1" -ExportFolderPath "C:\Temp\GetHelp" -DetailedExport
    
    .EXAMPLE
        Export-ModuleFunctions -ModuleFolderPath "C:\Temp" -ModuleFileName "BOX-Module" -FileExtention ".psm1" -ExportFolderPath "C:\Temp\GetHelp" -FullDetailedExport
    
    .EXAMPLE
        Export-ModuleFunctions -ModuleFolderPath "C:\Temp" -ModuleFileName "BOX-Module" -FileExtention ".psm1" -ExportFolderPath "C:\Temp\GetHelp" -SummaryExport -DetailedExport
    
    .EXAMPLE
        Export-ModuleFunctions -ModuleFolderPath "C:\Temp" -ModuleFileName "BOX-Module" -FileExtention ".psm1" -ExportFolderPath "C:\Temp\GetHelp" -SummaryExport -FullDetailedExport
    
    .EXAMPLE
        Export-ModuleFunctions -ModuleFolderPath "C:\Temp" -ModuleFileName "BOX-Module" -FileExtention ".psm1" -ExportFolderPath "C:\Temp\GetHelp" -DetailedExport -FullDetailedExport
    
    .EXAMPLE
        Export-ModuleFunctions -ModuleFolderPath "C:\Temp" -ModuleFileName "BOX-Module" -FileExtention ".psm1" -ExportFolderPath "C:\Temp\GetHelp" -SummaryExport -DetailedExport -FullDetailedExport
    
        .INPUTS
        $ModuleFolderPath
        $ModuleFileName
        $FileExtention
        $ExportFolderPath
        $SummaryExport
        $DetailedExport
    
    .OUTPUTS
        List and export result to '.Json', '.CSV', '.txt' 
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to script(s): '.\Box-Administration.psm1'
    
    #>
        
    Param (
        [Parameter(Mandatory=$True)]
        [String]$ModuleFolderPath,
    
        [Parameter(Mandatory=$True)]
        [String]$ModuleFileName,
    
        [Parameter(Mandatory=$False)]
        [ValidateSet('.psm1')]
        [String]$FileExtention = '.psm1',
        
        [Parameter(Mandatory=$True)]
        [String]$ExportFolderPath,
        
        [Parameter(Mandatory=$False)]
        [switch]$SummaryExport,
        
        [Parameter(Mandatory=$False)]
        [switch]$DetailedExport,
        
        [Parameter(Mandatory=$False)]
        [switch]$FullDetailedExport
    )
    
    # Variables
    $Array = @()
    $Array1 = @()
    $Date = Get-Date -Format yyyyMMdd-hhmmss
    $FolderDate = Get-Date -Format yyyyMMdd
    $ExportFolderFullPath = "$ExportFolderPath\$FolderDate"
    
    # Build Full Module Folder Path
    $FullModuleFolderPath = "$ModuleFolderPath\$ModuleFileName$FileExtention"
    
    # Import Module
    Import-Module $FullModuleFolderPath -Force
    
    # Create folder date if do not exist
    If ($(Test-Path -Path $ExportFolderFullPath) -eq $False) {
        
        $null = New-Item -Path $ExportFolderPath -Name $FolderDate -ItemType Directory -Force -ErrorAction Stop
    }
    
    # Get all function associated to the module
    $FunctionList = $(Get-Command -Module $ModuleFileName) | Where-Object {$_.CommandType -eq 'Function' -and $_.ModuleName -eq $ModuleFileName}
    
    # Get Help foreach function and export it to separate text (.txt) file or in CSV Summay file
    $FunctionTotalCount = $FunctionList.count
    $FunctionCount = 1
    
    Foreach ($Function in $FunctionList) {
        
        Write-Log INFONO -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message "($FunctionCount/$FunctionTotalCount) - Current function : " -NotDisplay
        Write-Log VALUE -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message "$Function" -NotDisplay
        
        # Get-help Details of the current function
        $FunctionListDetails     = Get-Help -Name $Function -Detailed
        $FunctionListFullDetails = Get-Help -Name $Function -Full
        
        If ($SummaryExport) {
        
            # Command Function properties
            $line = New-Object -TypeName PSObject
            $line | Add-Member -Name 'Module'                     -MemberType Noteproperty -Value $Function.Module
            $line | Add-Member -Name 'ModuleName'                 -MemberType Noteproperty -Value $Function.ModuleName
            $line | Add-Member -Name 'Name'                       -MemberType Noteproperty -Value $Function.Name
            $line | Add-Member -Name 'Namespace'                  -MemberType Noteproperty -Value $Function.Namespace
            $line | Add-Member -Name 'Noun'                       -MemberType Noteproperty -Value $Function.Noun
            $line | Add-Member -Name 'CmdletBinding'              -MemberType Noteproperty -Value $Function.CmdletBinding
            $line | Add-Member -Name 'Verb'                       -MemberType Noteproperty -Value $Function.Verb
            $line | Add-Member -Name 'Version'                    -MemberType Noteproperty -Value $Function.Version
            $line | Add-Member -Name 'Visibility'                 -MemberType Noteproperty -Value $Function.Visibility
            $line | Add-Member -Name 'CommandType'                -MemberType Noteproperty -Value $Function.CommandType
            $line | Add-Member -Name 'DefaultParameterSet'        -MemberType Noteproperty -Value $Function.DefaultParameterSet
            $line | Add-Member -Name 'Definition'                 -MemberType Noteproperty -Value $Function.Definition
            $line | Add-Member -Name 'Description'                -MemberType Noteproperty -Value $Function.Description
            $line | Add-Member -Name 'DisplayName'                -MemberType Noteproperty -Value $Function.DisplayName
            $line | Add-Member -Name 'DLL'                        -MemberType Noteproperty -Value $Function.DLL
            $line | Add-Member -Name 'Extension'                  -MemberType Noteproperty -Value $Function.Extension
            $line | Add-Member -Name 'FileVersionInfo'            -MemberType Noteproperty -Value $Function.FileVersionInfo
            $line | Add-Member -Name 'HelpFile'                   -MemberType Noteproperty -Value $Function.HelpFile
            $line | Add-Member -Name 'HelpUri'                    -MemberType Noteproperty -Value $Function.HelpUri
            $line | Add-Member -Name 'ImmediateBaseObject'        -MemberType Noteproperty -Value $Function.ImmediateBaseObject
            $line | Add-Member -Name 'Members'                    -MemberType Noteproperty -Value $Function.Members
            $line | Add-Member -Name 'Methods'                    -MemberType Noteproperty -Value $Function.Methods
            $line | Add-Member -Name 'Options'                    -MemberType Noteproperty -Value $Function.Options
            $line | Add-Member -Name 'OriginalEncoding'           -MemberType Noteproperty -Value $Function.OriginalEncoding
            $line | Add-Member -Name 'OutputType'                 -MemberType Noteproperty -Value $Function.OutputType
            $line | Add-Member -Name 'Parameters'                 -MemberType Noteproperty -Value $Function.Parameters
            $line | Add-Member -Name 'ParameterSets'              -MemberType Noteproperty -Value $Function.ParameterSets
            $line | Add-Member -Name 'Path'                       -MemberType Noteproperty -Value $Function.Path
            $line | Add-Member -Name 'Properties'                 -MemberType Noteproperty -Value $Function.Properties
            $line | Add-Member -Name 'PSSnapIn'                   -MemberType Noteproperty -Value $Function.PSSnapIn
            $line | Add-Member -Name 'ReferencedCommand'          -MemberType Noteproperty -Value $Function.ReferencedCommand
            $line | Add-Member -Name 'RemotingCapability'         -MemberType Noteproperty -Value $Function.RemotingCapability
            $line | Add-Member -Name 'ResolvedCommand'            -MemberType Noteproperty -Value $Function.ResolvedCommand
            $line | Add-Member -Name 'ResolvedCommandName'        -MemberType Noteproperty -Value $Function.ResolvedCommandName
            $line | Add-Member -Name 'TypeNames'                  -MemberType Noteproperty -Value $Function.TypeNames
            $line | Add-Member -Name 'BaseObject'                 -MemberType Noteproperty -Value $Function.BaseObject
            $Array += $line
            
            # Export help summary for each function to text (.txt) file
            $SummaryFunctionDetailsFilePath = "$ExportFolderFullPath\$Date-Summary-Get-Help-$Function.txt"
            $FunctionListDetails | Out-File -FilePath $SummaryFunctionDetailsFilePath -Encoding utf8 -ErrorAction Stop
            
            Write-Log INFONO -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message "Get help summary function details : $($Function.Name) is available here : " -NotDisplay
            Write-Log VALUE -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message $SummaryFunctionDetailsFilePath -NotDisplay
        }
        
        If ($DetailedExport) {
            
            # Export help full details for each function to text (.txt) file
            $DetailedFunctionDetailsFilePath = "$ExportFolderFullPath\$Date-Details-Get-Help-$Function.txt"
            $FunctionListFullDetails | Out-File -FilePath $DetailedFunctionDetailsFilePath -Encoding utf8 -ErrorAction Stop
            
            Write-Log INFONO -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message "Get help full function details : $($Function.Name) is available here : " -NotDisplay
            Write-Log VALUE -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message $DetailedFunctionDetailsFilePath -NotDisplay                        
        }
        
        If ($FullDetailedExport) {
            
            # Export help full details for each function to text (.txt) file
            $FullFunctionDetailsFilePath = "$ExportFolderFullPath\$Date-Full-Details-Get-Help-$Function.txt"
            $Function.Definition | Out-File -FilePath $FullFunctionDetailsFilePath -Encoding utf8 -ErrorAction Stop
            
            Write-Log INFONO -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message "Get help full details for function : $($Function.Name) is available here : " -NotDisplay
            Write-Log VALUE -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message $FullFunctionDetailsFilePath -NotDisplay

            $Parameters = $FunctionListDetails.parameters.parameter
            $ParametersSyntaxe = $FunctionListDetails.syntax.syntaxItem.parameter
            $ParameterFunctionTotalCount = $Parameters.count
            $ParameterCount = 1
            
            Foreach ($Parameter in $Parameters) {
                
                Write-Log INFONO -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message "($ParameterCount/$ParameterFunctionTotalCount) - Current Parameter : " -NotDisplay
                Write-Log VALUE -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message "$($Parameter.Name)" -NotDisplay                
                
                # Function List properties
                $Line1 = New-Object -TypeName PSObject
                $Line1 | Add-Member -Name 'Name'                        -MemberType Noteproperty -Value $FunctionListDetails.Name
                $Line1 | Add-Member -Name 'Function Name'               -MemberType Noteproperty -Value $FunctionListDetails.details.Name
                $Line1 | Add-Member -Name 'Module Name'                 -MemberType Noteproperty -Value $FunctionListDetails.ModuleName
                $Line1 | Add-Member -Name 'Category'                    -MemberType Noteproperty -Value $FunctionListDetails.Category
                $Line1 | Add-Member -Name 'Synopsis'                    -MemberType Noteproperty -Value $FunctionListDetails.Synopsis
                $Line1 | Add-Member -Name 'Sort Description'            -MemberType Noteproperty -Value $FunctionListDetails.description.text
                $Line1 | Add-Member -Name 'Long Description'            -MemberType Noteproperty -Value $FunctionListDetails.details.description.text
                $Line1 | Add-Member -Name 'Example Code'                -MemberType Noteproperty -Value $FunctionListDetails.examples.example.code
                $Line1 | Add-Member -Name 'Example Introduction'        -MemberType Noteproperty -Value $FunctionListDetails.examples.example.Introduction.text
                $Line1 | Add-Member -Name 'Example Title'               -MemberType Noteproperty -Value $FunctionListDetails.examples.example.Title
                $Line1 | Add-Member -Name 'Input Types'                 -MemberType Noteproperty -Value $($FunctionListDetails.inputTypes.inputType.type.name -join '|')
                $Line1 | Add-Member -Name 'Return Values Name'          -MemberType Noteproperty -Value $FunctionListDetails.returnValues.returnValue.type.name
                
                # Function parameters
                $Line1 | Add-Member -Name "Parameter description"       -MemberType Noteproperty -Value $Parameter.description.text
                $Line1 | Add-Member -Name "Parameter default Value"     -MemberType Noteproperty -Value $Parameter.defaultValue
                $Line1 | Add-Member -Name "Parameter name"              -MemberType Noteproperty -Value $Parameter.name
                $Line1 | Add-Member -Name "Parameter type"              -MemberType Noteproperty -Value $Parameter.type.name
                $Line1 | Add-Member -Name "Parameter required"          -MemberType Noteproperty -Value $Parameter.required
                $Line1 | Add-Member -Name "Parameter globbing"          -MemberType Noteproperty -Value $Parameter.globbing
                $Line1 | Add-Member -Name "Parameter pipeline Input"    -MemberType Noteproperty -Value $Parameter.pipelineInput
                $Line1 | Add-Member -Name "Parameter position"          -MemberType Noteproperty -Value $Parameter.position
                $Line1 | Add-Member -Name "Parameter isDynamic"         -MemberType Noteproperty -Value $Parameter.isDynamic
                $Line1 | Add-Member -Name "Parameter parameter Set Name"-MemberType Noteproperty -Value $Parameter.parameterSetName
                $Line1 | Add-Member -Name "Parameter parameter Value"   -MemberType Noteproperty -Value $Parameter.parameterValue
                $Line1 | Add-Member -Name "Parameter aliases"           -MemberType Noteproperty -Value $Parameter.Aliases
                
                # Syntaxe Function parameters
                $Line1 | Add-Member -Name 'Parameter Syntaxe description'    -MemberType Noteproperty -Value $($ParametersSyntaxe.description.text -join ' | ')
                $Line1 | Add-Member -Name 'Parameter Syntaxe globbing'       -MemberType Noteproperty -Value $ParametersSyntaxe[$ParameterCount].globbing
                $Line1 | Add-Member -Name 'Parameter Syntaxe name'           -MemberType Noteproperty -Value $ParametersSyntaxe[$ParameterCount].name
                $Line1 | Add-Member -Name 'Parameter Syntaxe parameterValue' -MemberType Noteproperty -Value $ParametersSyntaxe[$ParameterCount].parameterValue
                $Line1 | Add-Member -Name 'Parameter Syntaxe pipelineInput'  -MemberType Noteproperty -Value $ParametersSyntaxe[$ParameterCount].pipelineInput
                $Line1 | Add-Member -Name 'Parameter Syntaxe position'       -MemberType Noteproperty -Value $ParametersSyntaxe[$ParameterCount].position
                $Line1 | Add-Member -Name 'Parameter Syntaxe required'       -MemberType Noteproperty -Value $ParametersSyntaxe[$ParameterCount].required
                
                # Common Informations
                $Line1 | Add-Member -Name 'Notes'                      -MemberType Noteproperty -Value $FunctionListDetails.alertSet.alert.text
                $Line1 | Add-Member -Name 'Functionality'              -MemberType Noteproperty -Value $FunctionListDetails.Functionality
                $Line1 | Add-Member -Name 'Role'                       -MemberType Noteproperty -Value $FunctionListDetails.Role
                
                $Array1 += $Line1
                $ParameterCount ++
            }

        }
        $FunctionCount ++
    }    
    
    If ($SummaryExport) {
        
        $AllFunctionsSummaryFilePath = "$ExportFolderFullPath\$Date-Get-Help-Summary-All-Functions.csv"
        $Array | Export-Csv -Path $AllFunctionsSummaryFilePath -Force -Encoding utf8 -Delimiter ";" -NoTypeInformation
        
        Write-Log INFONO -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message 'Summary Get-Help details for all Functions are saved to : ' -NotDisplay
        Write-Log VALUE -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message $AllFunctionsSummaryFilePath -NotDisplay
    }
    
    If ($FullDetailedExport) {
        
        $AllFunctionsAllDetailsFilePath = "$ExportFolderFullPath\$Date-Get-Help-Full-Details-All-Functions.csv"
        $Array1 | Export-Csv -Path $AllFunctionsAllDetailsFilePath -Force -Encoding utf8 -Delimiter ";" -NoTypeInformation
        
        Write-Log INFONO -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message 'Full Get-Help details for all Functions are saved to : ' -NotDisplay
        Write-Log VALUE -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message $AllFunctionsAllDetailsFilePath -NotDisplay
    }
    
    Write-Log INFONO -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message 'All files are save to the folder : '
    Write-Log VALUE -Category 'Program run' -Name 'Export All function in module : BOX-Module' -Message $ExportFolderFullPath
    
    Return $Array1
}

#region Load user Json file configuration management

Function Get-JSONSettingsCurrentUserContent {

<#
.SYNOPSIS
    Load current user Json file configuration management

.DESCRIPTION
    Load current user Json file configuration management

.PARAMETER 
    

.EXAMPLE
    Get-JSONSettingsCurrentUserContent

.INPUTS
    None

.OUTPUTS
    Current User Settings loaded

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Reset-CurrentUserProgramConfiguration'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param(    )

    Write-Log -Type INFO -Category 'Program initialisation' -Name 'Json Current User Settings Importation' -Message 'Start Json Current User Settings Importation' -NotDisplay
    Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Json Current User Settings Importation' -Message 'Json Current User Settings Importation Status : ' -NotDisplay
    Try {
        $global:JSONSettingsCurrentUserContent = Get-Content -Path $global:JSONSettingsCurrentUserFileNamePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $global:DisplayFormat           = $global:JSONSettingsCurrentUserContent.DisplayFormat.DisplayFormat
        $global:ExportFormat            = $global:JSONSettingsCurrentUserContent.ExportFormat.ExportFormat
        $global:OpenExportFolder        = $global:JSONSettingsCurrentUserContent.OpenExportFolder.OpenExportFolder
        $global:OpenHTMLReport          = $global:JSONSettingsCurrentUserContent.OpenHTMLReport.OpenHTMLReport
        $global:ResolveDnsName          = $global:JSONSettingsCurrentUserContent.ResolveDnsName.ResolveDnsName
        $global:TriggerExportFormat     = $global:JSONSettingsCurrentUserContent.Trigger.ExportFormat
        $global:TriggerDisplayFormat    = $global:JSONSettingsCurrentUserContent.Trigger.DisplayFormat
        $global:TriggerOpenHTMLReport   = $global:JSONSettingsCurrentUserContent.Trigger.OpenHTMLReport
        $global:TriggerOpenExportFolder = $global:JSONSettingsCurrentUserContent.Trigger.OpenExportFolder
        $global:SiteOldRemotePort       = $global:JSONSettingsCurrentUserContent.Site.OldRemotePort
        $global:SiteOldRemoteUrl        = $global:JSONSettingsCurrentUserContent.Site.OldRemoteUrl
        $global:SiteCurrentLocalUrl     = $global:JSONSettingsCurrentUserContent.Site.CurrentLocalUrl
        $global:SiteCurrentRemoteUrl    = $global:JSONSettingsCurrentUserContent.Site.CurrentRemoteUrl
        $global:SiteCurrentRemotePort   = $global:JSONSettingsCurrentUserContent.Site.CurrentRemotePort
        
        Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Json Current User Settings Importation' -Message 'Successful' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program initialisation' -Name 'Json Current User Settings Importation' -Message "Failed, to import Json Current User Settings file, due to : $($_.ToString())"
        Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason 'Json Current User Settings file import has failed' -ErrorAction Stop
    }
    Write-Log -Type INFO -Category 'Program initialisation' -Name 'Json Current User Settings Importation' -Message 'End Json Current User Settings Importation' -NotDisplay
}

Function Get-JSONSettingsDefaultUserContent {

<#
.SYNOPSIS
    Load default user Json file configuration management

.DESCRIPTION
    Load default user Json file configuration management

.PARAMETER 
    

.EXAMPLE
    Get-JSONSettingsdefaultUserContent

.INPUTS
    None

.OUTPUTS
    Default User Settings loaded

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Reset-CurrentUserProgramConfiguration'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param(    )

    Write-Log -Type INFO -Category 'Program initialisation' -Name 'Json Default User Settings Importation' -Message 'Start Json Default User Settings Importation' -NotDisplay
    Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Json Default User Settings Importation' -Message 'Json Default User Settings Importation Status : '
    Try {
        $global:JSONSettingsDefaultUserContent = Get-Content -Path $global:JSONSettingsDefaultUserFileNamePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $global:DisplayFormat           = $global:JSONSettingsDefaultUserContent.DisplayFormat.DisplayFormat
        $global:ExportFormat            = $global:JSONSettingsDefaultUserContent.ExportFormat.ExportFormat
        $global:OpenExportFolder        = $global:JSONSettingsDefaultUserContent.OpenExportFolder.OpenExportFolder
        $global:OpenHTMLReport          = $global:JSONSettingsDefaultUserContent.OpenHTMLReport.OpenHTMLReport
        $global:ResolveDnsName          = $global:JSONSettingsCurrentUserContent.ResolveDnsName.ResolveDnsName
        $global:TriggerExportFormat     = $global:JSONSettingsDefaultUserContent.Trigger.ExportFormat
        $global:TriggerDisplayFormat    = $global:JSONSettingsDefaultUserContent.Trigger.DisplayFormat
        $global:TriggerOpenHTMLReport   = $global:JSONSettingsDefaultUserContent.Trigger.OpenHTMLReport
        $global:TriggerOpenExportFolder = $global:JSONSettingsDefaultUserContent.Trigger.OpenExportFolder
        $global:SiteOldRemotePort       = $global:JSONSettingsDefaultUserContent.Site.OldRemotePort
        $global:SiteOldRemoteUrl        = $global:JSONSettingsDefaultUserContent.Site.OldRemoteUrl
        $global:SiteCurrentLocalUrl     = $global:JSONSettingsDefaultUserContent.Site.CurrentLocalUrl
        $global:SiteCurrentRemoteUrl    = $global:JSONSettingsDefaultUserContent.Site.CurrentRemoteUrl
        $global:SiteCurrentRemotePort   = $global:JSONSettingsDefaultUserContent.Site.CurrentRemotePort
        
        Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Json Default User Settings Importation' -Message 'Successful'
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program initialisation' -Name 'Json Default User Settings Importation' -Message "Failed, to import Json Default User Settings file, due to : $($_.ToString())"
        Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason 'Json Default User Settings file import has failed' -ErrorAction Stop
    }
    Write-Log -Type INFO -Category 'Program initialisation' -Name 'Json Default User Settings Importation' -Message 'End Json Default User Settings Importation' -NotDisplay
}

#endregion Json file configuration management

#region Reset User Json Configuration files
Function Reset-CurrentUserProgramConfiguration {

<#
.SYNOPSIS
    Reset User Json Configuration files

.DESCRIPTION
    Reset User Json Configuration files

.PARAMETER 
    

.EXAMPLE
    Reset-CurrentUserProgramConfiguration

.INPUTS
    None

.OUTPUTS
    Current User Program Configuration is reset

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): '', ''
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param(    )
    
    Write-Log -Type INFO -Name 'Program - Reset Json Current User Settings' -Message 'Start Reset Json Current User Settings' -NotDisplay
    Write-Log -Type INFONO -Name 'Program - Reset Json Current User Settings' -Message 'Reset Json Current User Settings Status : ' -NotDisplay
    Try {
        Copy-Item -Path $global:JSONSettingsDefaultUserFileNamePath -Destination $global:JSONSettingsCurrentUserFileNamePath -Force
        Start-Sleep -Seconds $global:SleepDefault
        Write-Log -Type VALUE -Name 'Program - Reset Json Current User Settings' -Message 'Successful' -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program - Reset Json Current User Settings' -Message "Failed, to Reset Json Current User Settings file, due to : $($_.ToString())"
        Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason 'Json Current User Settings file reset has failed' -ErrorAction Stop
    }
    Write-Log -Type INFO -Name 'Program - Reset Json Current User Settings' -Message 'End Reset Json Current User Settings' -NotDisplay

    If (Test-Path -Path $global:JSONSettingsCurrentUserFileNamePath) {

        Get-JSONSettingsCurrentUserContent
    }
    Elseif (Test-Path -Path $global:JSONSettingsDefaultUserFileNamePath) {
        
        Get-JSONSettingsDefaultUserContent
    }
    Else {
        Write-Log -Type WARNING -Name 'Program - Json Current User Settings Importation' -Message "Failed, to find any user settings configuration file, due to : $($_.ToString())"
        Write-Log -Type INFO -Name 'Program - Json Current User Settings Importation' -Message 'End Json Current User Settings Importation' -NotDisplay
        Stop-Program -Context System -ErrorMessage $($_.ToString()) -Reason 'Find any user settings configuration file has failed' -ErrorAction Stop
    }
}
#endregion Reset User Json Configuration files

#endregion Program

#region Chrome Driver / Google Chrome

# Used only to detect Google Chrome and Chrome Driver version Online
Function Get-LastestStableChromeVersionOnline {

    <#
    .SYNOPSIS
        To Get Lastest Stable Chrome version
    
    .DESCRIPTION
        To Get Lastest Stable Chrome version
    
    .PARAMETER ChromeDriverLastStableVersionUrl
        This is the url to get the last online version of Chrome Driver and Google Chrome
    
    .EXAMPLE
        Get-LastestStableChromeVersionOnline -ChromeDriverLastStableVersionUrl 'https://getwebdriver.com/chromedriver/api/LATEST_RELEASE_STABLE'
    
    .INPUTS
    Web Url
    
    .OUTPUTS
        Lastest Stable Chrome version
        $global:ChromeDriverLastStableVersion
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to script(s): '.\Box-Administration.psm1'
    #>
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$ChromeDriverLastStableVersionUrl
    )
    
    # Get Chrome Driver Version in the Default Chrome Driver folder
    Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Get Lastest Stable Chrome Version Online' -Message 'Google Chrome/Driver lastest version found : ' -NotDisplay
    
    Try {
        $global:ChromeDriverLastStableVersion = Invoke-WebRequest -Uri $ChromeDriverLastStableVersionUrl -SkipCertificateCheck -SkipHeaderValidation -AllowUnencryptedAuthentication -AllowInsecureRedirect -ConnectionTimeoutSeconds 30 -OperationTimeoutSeconds 30 -RetryIntervalSec 2 -Method Get

        Write-Log -Type VALUE  -Category 'Program initialisation' -Name 'Get Lastest Stable Chrome Version Online' -Message $global:ChromeDriverLastStableVersion -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Category 'Program initialisation' -Name 'Get Lastest Stable Chrome Version Online' -Message "Failed, due to : $($_.ToString())" -NotDisplay
        Stop-Program -Context System -ErrorMessage 'Failed to get Chrome Driver/Google lastest Version' -Reason $($_.ToString())
    }
}

# Used only to detect ChromeDriver version
Function Get-ChromeDriverVersion {

<#
.SYNOPSIS
    To detect ChromeDriver version

.DESCRIPTION
    To detect ChromeDriver version

.PARAMETER


.EXAMPLE
    Get-ChromeDriverVersion

.INPUTS


.OUTPUTS
    ChromeDriver version and path compatible obtenained
    $global:ChromeDriverVersion
    $global:ChromeDriverFolder

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to script(s): '.\Box-Administration.psm1'
#>

    Param ()
    
    # Get Chrome Driver Version in the Default Chrome Driver folder
    $ChromeDriverDefaultVersion = & $global:ChromeDriverDefaultSetupFileNamePath --version
    $ChromeDriverDefaultVersion = $($ChromeDriverDefaultVersion -split " ")[1]
    
    # Get All Chrome Driver Version in Chrome Driver folder
    Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Chrome Driver Version' -Message "Chrome Driver Version installed on device status : " -NotDisplay
    
    Try {
        $ChromeDriverVersionList = Get-childItem -Path $global:ChromeDriverRessourcesFolderNamePath <#-Exclude $global:ChromeDriverDefaultFolderName#> | Select-Object -Property Name | Sort-Object -Descending
        Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Chrome Driver Version' -Message "Successful" -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Category 'Program initialisation' -Name 'Chrome Driver Version' -Message "Failed, No Chrome Driver version was found"  -NotDisplay
        Write-Log -Type WARNING -Category 'Program initialisation' -Name 'Chrome Driver Version' -Message "Error detail : $($_.ToString())"     -NotDisplay
        $ChromeDriverVersionList    = $null
        $global:ChromeDriverVersion = $null
        $global:ChromeDriverFolder  = $null
        $global:TriggerExitSystem = 1
    }
    
    # Get the Higher Chrome Driver Version in Chrome Driver folder
    If ($ChromeDriverVersionList.Name) {
        
        $Temp = $ChromeDriverDefaultVersion
        Foreach ($Item in $ChromeDriverVersionList.Name) {
            
            If ($Item -eq 'Default') {
                
                $Item = $ChromeDriverDefaultVersion
            }
            
            If ($Item -gt $Temp) {
                
                $Temp = $Item
            }
        }
        
        # Check if higher Chrome Driver Version is the default one or not
        If ($Temp -eq $ChromeDriverDefaultVersion) {
            
            $global:ChromeDriverVersion = $ChromeDriverDefaultVersion
            $global:ChromeDriverFolder  = $global:ChromeDriverDefaultFolderName
        }
        Else {
            $global:ChromeDriverVersion = $Temp
            $global:ChromeDriverFolder  = $Temp
        }
        
        Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Chrome Driver Version' -Message 'ChromeDriver version selected : ' -NotDisplay
        Write-Log -Type VALUE  -Category 'Program initialisation' -Name 'Chrome Driver Version' -Message $global:ChromeDriverVersion -NotDisplay
        Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Chrome Driver Folder'  -Message 'ChromeDriver folder selected : ' -NotDisplay
        Write-Log -Type VALUE  -Category 'Program initialisation' -Name 'Chrome Driver Folder'  -Message $global:ChromeDriverFolder -NotDisplay
    }
    Else {
        $global:TriggerExitSystem = 1
    }
}

# Used only to detect Google Chrome version
Function Get-GoogleChromeVersion {

    <#
    .SYNOPSIS
        To detect GoogleChrome version
    
    .DESCRIPTION
        To detect GoogleChrome version
    
    .PARAMETER
    
    
    .EXAMPLE
        Get-GoogleChromeVersion
    
    .INPUTS
    
    
    .OUTPUTS
        GoogleChrome version and path compatible obtenained
        $global:GoogleChromeVersion
        $global:GoogleChromeFolder
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to script(s): '.\Box-Administration.psm1'
    #>
    
        Param ()
        
        # Get Google Chrome Version in the Default Google Chrome folder
        $GoogleChromeDefaultVersion = $(Get-ItemProperty -Path $global:GoogleChromeDefaultSetupFileNamePath).VersionInfo.FileVersion
        
        # Get All Google Chrome Version in Google Chrome folder
        Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Google Chrome Version' -Message "Google Chrome Version installed on device status : " -NotDisplay
        
        Try {
            $GoogleChromeVersionList = Get-childItem -Path $global:GoogleChromeRessourcesFolderNamePath <#-Exclude $global:GoogleChromeDefaultFolderName#> | Select-Object -Property Name | Sort-Object -Descending
            Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Google Chrome Version' -Message "Successful" -NotDisplay
        }
        Catch {
            Write-Log -Type WARNING -Category 'Program initialisation' -Name 'Google Chrome Version' -Message "Failed, No Google Chrome version was found"  -NotDisplay
            Write-Log -Type WARNING -Category 'Program initialisation' -Name 'Google Chrome Version' -Message "Error detail : $($_.ToString())"     -NotDisplay
            $GoogleChromeVersionList    = $null
            $global:GoogleChromeFolder  = $null
            $global:GoogleChromeVersion = $null
            $global:TriggerExitSystem = 1
        }
        
        # Get the Higher Google Chrome Version in Google Chrome folder
        If ($GoogleChromeVersionList.Name) {
            
            $Temp = $GoogleChromeDefaultVersion
            Foreach ($Item in $GoogleChromeVersionList.Name) {
                
                If ($Item -eq 'Default') {
                    
                    $Item = $GoogleChromeDefaultVersion
                }
                
                If ($Item -gt $Temp) {
                    
                    $Temp = $Item
                }
            }
            
            # Check if higher Google Chrome Version is the default one or not
            If ($Temp -eq $GoogleChromeDefaultVersion) {
                
                $global:GoogleChromeVersion = $GoogleChromeDefaultVersion
                $global:GoogleChromeFolder  = $global:GoogleChromeDefaultFolderName
            }
            Else {
                $global:GoogleChromeVersion = $Temp
                $global:GoogleChromeFolder  = $Temp
            }
            
            Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Google Chrome Version' -Message 'GoogleChrome version selected : ' -NotDisplay
            Write-Log -Type VALUE  -Category 'Program initialisation' -Name 'Google Chrome Version' -Message $global:GoogleChromeVersion -NotDisplay
            Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Google Chrome Folder'  -Message 'GoogleChrome folder selected : ' -NotDisplay
            Write-Log -Type VALUE  -Category 'Program initialisation' -Name 'Google Chrome Folder'  -Message $global:GoogleChromeFolder -NotDisplay
        }
        Else {
            $global:TriggerExitSystem = 1
        }
}

# Used only to Start ChromeDriver
Function Start-ChromeDriver {

<#
.SYNOPSIS
    To Start ChromeDriver

.DESCRIPTION
    To Start ChromeDriver

.PARAMETER DownloadPath
    Indicate your download folder

.PARAMETER LogsPath
    Indicate the folder where you want to store the dedicated ChromeDriver Logs

.PARAMETER ChromeBinaryPath
    Indicate the full path of chromeDriver setup is installed

.PARAMETER ChromeDriverDefaultProfile
    Indicate which Google Chrome Profile must be used with ChromeDriver

.EXAMPLE
    Start-ChromeDriver -DownloadPath "C:\Windows\Temp" -LogsPath "C:\Windows\Logs" -ChromeBinaryPath "C:\ProgramFiles\ChromeDriver\ChromeDriver.exe" -ChromeDriverDefaultProfile "Default"

.INPUTS
    $DownloadPath
    $LogsPath
    $ChromeBinaryPath
    $ChromeDriverDefaultProfile

.OUTPUTS
    All ChromeDriver Processes are stopped

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$False)]
        [String]$DownloadPath,
        
        [Parameter(Mandatory=$True)]
        [String]$LogsPath,
        
        [Parameter(Mandatory=$True)]
        [String]$ChromeBinaryPath,

        [Parameter(Mandatory=$True)]
        [String]$ChromeDriverDefaultProfile
    )
    
    # Add path for ChromeDriver.exe to the environmental variable 
    $env:PATH += ";$global:ChromeDriverDefaultFolderNamePath\$global:ChromeDriverDefaultSetupFileName"

    # Add path for GoogleChrome.exe to the environmental variable 
    #$Temp = $($ChromeBinaryPath.Replace("\$($ChromeBinaryPath.Split("\")[-1])",''))
    #$env:PATH += ";$Temp"

    # Adding Selenium's .NET assembly (dll) to access it's classes in this PowerShell session
    Add-Type -Path "$global:ChromeDriverDefaultFolderNamePath\$global:ChromeDriverDefaultWebDriverDLLFileName"
    
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
    $chromeoption.BinaryLocation = $ChromeBinaryPath
    
    # Allow to download file without prompt
    $chromeoption.AddUserProfilePreference('download', @{'default_directory' = $DownloadPath; 'directory_upgrade' = $True;'prompt_for_download' = $False})

    # Disable All Extentions
    $chromeoption.AddArgument("disable-extensions")
    $chromeoption.AddArgument("disable-default-apps")
    $chromeoption.AddArgument("disable-popup-blocking")
    $chromeoption.AddArgument("disable-plugins")
    $chromeoption.AddArgument("no-sandbox")
    
    # Hide ChromeDriver Application
    #$chromeoption.AddArguments("headless")
    #$chromeoption.AddArguments("window-size=200,200")
    
    # Start the ChromeDriver
    $global:ChromeDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($ChromeDriverService,$chromeoption)
    
    # Minimize Windows at startup
    $global:ChromeDriver.Manage().Window.Minimize()
}

# Used only to stop ChromeDriver
Function Stop-ChromeDriver {

<#
.SYNOPSIS
    To stop ChromeDriver

.DESCRIPTION
    To stop ChromeDriver

.PARAMETER 
    

.EXAMPLE
    Stop-ChromeDriver

.INPUTS
    None

.OUTPUTS
    Stop All ChromeDriver Processes

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Stop-Program', 'Update-ChromeDriver'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param ()
    
    # Close all ChromeDriver instances openned
    Get-Process -ErrorAction SilentlyContinue | Select-Object -Property ProcessName, Id, CPU, Path -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "$global:RessourcesFolderNamePath*"} -ErrorAction SilentlyContinue | Sort-Object -Property ProcessName -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
}

# Used only to update ChromeDriver version
Function Update-ChromeDriver {

<#
.SYNOPSIS
    To update ChromeDriver version

.DESCRIPTION
    To update ChromeDriver version

.PARAMETER 
    

.EXAMPLE
    Update-ChromeDriver

.INPUTS
    $global:ChromeDriverVersion

.OUTPUTS
    ChromeDriver version is up to date

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Stop-Program', 'ConvertFrom-HtmlToText'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param () 
    
    Try {
        
        # Set Variables
        $UserDownloadFolderDefault   = Get-ItemPropertyValue -Path $global:DownloadShellRegistryFolder -Name $global:DownloadShellRegistryFolderName
        $SourceFile                  = "$UserDownloadFolderDefault\$global:ChromeDriverDownloadFileName"
        $DestinationPath             = $global:ChromeDriverDefaultFolderNamePath
        $ChromeDriverDownloadPathUrl = "$global:ChromeDriverDownloadPathUrl/$Global:ChromeDriverLastStableVersion/win32/$global:ChromeDriverDownloadFileName"
        
        Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message 'ChromeDriver version status : ' -NotDisplay
        
        $global:ChromeDriverVersion = $Global:ChromeDriverLastStableVersion
        $global:ChromeDriverFolder  = $global:ChromeDriverDefaultFolderNamePath
        
        Write-Log -Type WARNING -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message 'Need to be updated' -NotDisplay
        
        # Navigate to Chrome Driver Version choosen
        Write-Log -Type INFO -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message "Access to Chrome Driver download Page for version : $Global:ChromeDriverLastStableVersion" -NotDisplay
        $Files = @(
            @{
                Uri     = $ChromeDriverDownloadPathUrl
                OutFile = $SourceFile
            }
        )
        
        # Start setup file downloading
        Write-Log -Type INFO -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message "Start to Chrome Driver download version : $Global:ChromeDriverLastStableVersion" -NotDisplay
        $Jobs = @()
        
        Foreach ($File in $Files) {
            $Jobs += Start-ThreadJob -Name $File.OutFile -ScriptBlock {
                $Params = $using:File
                Invoke-WebRequest @params
            }
        }
        
        Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message "Download Chrome Driver Status : " -NotDisplay
        
        Wait-Job -Job $Jobs
        
        Foreach ($Job in $Jobs) {
            Receive-Job -Job $Job
        }
        
        Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message "Successful" -NotDisplay
        Write-Log -Type INFO -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message "End to download Chrome Driver version : $Global:ChromeDriverLastStableVersion" -NotDisplay                
        
        # Unzip new Chrome driver version to destination
        Write-Log -Type INFO -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message "Unzip archive to Chrome Driver repository for version : $Global:ChromeDriverLastStableVersion" -NotDisplay
        Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message "Unzip archive to Chrome Driver repository status : " -NotDisplay
        Try {
            Expand-Archive -Path $SourceFile -DestinationPath $DestinationPath -Force -ErrorAction Stop -WarningAction Stop
            Start-Sleep -Seconds $global:SleepChromeDriverUnzip
            
            Move-Item -Path "$DestinationPath\chromedriver-win32\*" -Destination $DestinationPath -Force
            Start-Sleep -Seconds $global:SleepChromeDriverUnzip
            Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message "Successful" -NotDisplay
            Start-Sleep -Seconds $global:SleepDefault
            
            # Copy chrome Driver DLL
            Copy-Item -Path $global:ChromeDriverDefaultWebDriverDLLFileNamePath     -Destination $global:ChromeDriverDefaultFolderNamePath -Force
            Copy-Item -Path $global:ChromeDriverDefaultWebDriverSupportFileNamePath -Destination $global:ChromeDriverDefaultFolderNamePath -Force
            Start-Sleep -Seconds $global:SleepDefault
            
            # Remove the downloaded source
            Write-Log -Type INFO -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message "Remove source file : $SourceFile" -NotDisplay
            Remove-Item -Path $SourceFile -Force -ErrorAction Stop
            Remove-Item -Path "$DestinationPath\chromedriver-win32\" -Force -ErrorAction Stop
            Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message 'ChromeDriver is up to date' -NotDisplay
        }
        Catch {
            Write-Log -Type ERROR -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message "Failed, due to : $($_.tostring())"
        }
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program initialisation' -Name 'Update ChromeDriver' -Message "Update failed, due to : $($_.ToString())" -NotDisplay
        $global:TriggerExitSystem = 1
    }
}

# Used only to update GoogleChrome version
Function Update-GoogleChrome {

    <#
    .SYNOPSIS
        To update Google Chrome version
    
    .DESCRIPTION
        To update Google Chrome version
    
    .PARAMETER 
        
    
    .EXAMPLE
        Update-GoogleChrome
    
    .INPUTS
        $global:GoogleChromeVersion
    
    .OUTPUTS
        Google Chrome version is up to date
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to function(s): 'Stop-Program', 'ConvertFrom-HtmlToText'
        Linked to script(s): '.\Box-Administration.psm1'
    
    #>
    
    Param () 
    
    Try {
        
        # Set Variables
        $UserDownloadFolderDefault   = Get-ItemPropertyValue -Path $global:DownloadShellRegistryFolder -Name $global:DownloadShellRegistryFolderName
        $SourceFile                  = "$UserDownloadFolderDefault\$global:GoogleChromeDownloadFileName"
        $DestinationPath             = $global:GoogleChromeDefaultFolderNamePath
        $GoogleChromeDownloadHomeUrl = "$global:GoogleChromeDownloadHomeUrl/$Global:ChromeDriverLastStableVersion/win32/$global:GoogleChromeDownloadFileName"
        
        Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Update Google Chrome' -Message 'Google Chrome version status : ' -NotDisplay
        
        $global:GoogleChromeVersion = $Global:ChromeDriverLastStableVersion
        $global:GoogleChromeFolder  = $global:ChromeDriverDefaultFolderNamePath
            
        Write-Log -Type WARNING -Category 'Program initialisation' -Name 'Update Google Chrome' -Message 'Need to be updated' -NotDisplay
        
        # Navigate to Google Chrome Version choosen
        Write-Log -Type INFO -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "Access to Google Chrome download Page for version : $Global:ChromeDriverLastStableVersion" -NotDisplay
        $Files = @(
            @{
                Uri     = $GoogleChromeDownloadHomeUrl
                OutFile = $SourceFile
            }
        )
        
        # Navigate to the main Google Chrome Page
        Write-Log -Type INFO -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "Access to Google Chrome download Page : $GoogleChromeDownloadHomeUrl" -NotDisplay
        $Jobs = @()
        
        Foreach ($File in $Files) {
            $Jobs += Start-ThreadJob -Name $File.OutFile -ScriptBlock {
                $Params = $using:File
                Invoke-WebRequest @params
            }
        }
        
        # Start setup file downloading
        Write-Log -Type INFO -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "Start to download Google Chrome version : $Global:ChromeDriverLastStableVersion" -NotDisplay
        Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "Download Google Chrome Status : " -NotDisplay
        
        Wait-Job -Job $Jobs
        
        Foreach ($Job in $Jobs) {
            Receive-Job -Job $Job
        }                
        
        Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "Successful" -NotDisplay
        Write-Log -Type INFO -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "End to download Google Chrome version : $Global:ChromeDriverLastStableVersion" -NotDisplay
        
        # Unzip new Google Chrome version to destination
        Write-Log -Type INFO -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "Unzip archive to Google Chrome repository for version : $Global:ChromeDriverLastStableVersion" -NotDisplay
        Write-Log -Type INFONO -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "Unzip archive to Google Chrome repository status : " -NotDisplay
        Try {
            Expand-Archive -Path $SourceFile -DestinationPath $DestinationPath -Force -ErrorAction Stop -WarningAction Stop
            Start-Sleep -Seconds $global:SleepChromeDriverUnzip
            Move-Item -Path "$DestinationPath\chrome-win32\*" -Destination $DestinationPath -Force
            Start-Sleep -Seconds $global:SleepChromeDriverUnzip
            Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "Successful" -NotDisplay
            
            # Remove the downloaded source
            Write-Log -Type INFO -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "Remove source file : $SourceFile" -NotDisplay
            Remove-Item -Path $SourceFile -Force -ErrorAction Stop
            Remove-Item -Path "$DestinationPath\chrome-win32\" -Force -ErrorAction Stop
            Write-Log -Type VALUE -Category 'Program initialisation' -Name 'Update Google Chrome' -Message 'Google Chrome is up to date' -NotDisplay
        }
        Catch {
            Write-Log -Type ERROR -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "Failed, due to : $($_.tostring())" -NotDisplay
        }
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program initialisation' -Name 'Update Google Chrome' -Message "Update failed, due to : $($_.ToString())" -NotDisplay
        $global:TriggerExitSystem = 1
    }
}

#endregion Chrome Driver / Google Chrome

#region Common functions

# used only to Get the state
Function Get-State {

<#
.SYNOPSIS
    Convert technical state to Human Readable state

.DESCRIPTION
    Convert technical state to Human Readable state

.PARAMETER State
    State value to convert

.EXAMPLE
    Get-State -State "0"

.INPUTS
    $State

.OUTPUTS
    Human Readable State

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to many functions

#>

    Param (
        [Parameter(Mandatory=$False)]
        [String]$State
    )
    
    Switch ($State) {
    
        ''         {$Value = 'BYTEL Dev Error';Break}
        ' '        {$Value = 'BYTEL Dev Error';Break}
        .          {$Value = 'Not available with your device';Break}
        -1         {$Value = 'Error';Break}
        0          {$Value = 'Disable';Break}
        1          {$Value = 'Enable';Break}
        2          {$Value = 'Enable';Break}
        3          {$Value = 'Enable';Break}
        4          {$Value = 'Enable';Break}
        55         {$Value = 'Enable';Break}
        on         {$Value = 'Enable';Break}
        off        {$Value = 'Disable';Break}
        Up         {$Value = 'Enable';Break}
        Down       {$Value = 'Disable';Break}
        None       {$Value = 'None';Break}
        True       {$Value = 'Yes';Break}
        False      {$Value = 'No';Break}
        Idle       {$Value = 'Idle';Break}
        Configured {$Value = 'Configured';Break}
        Connected  {$Value = 'Connected';Break}
        Discover   {$Value = 'Discover';Break}
        Disabled   {$Value = 'Disabled';Break}
        Disable    {$Value = 'Disable';Break}
        Enabled    {$Value = 'Enabled';Break}
        Enable     {$Value = 'Enable';Break}
        Empty      {$Value = 'Empty';Break}
        Error      {$Value = 'Error';Break}
        stopped    {$Value = 'stopped';Break}
        running    {$Value = 'running';Break}
        Forbidden  {$Value = 'Forbidden';Break}
        Allowed    {$Value = 'Allowed';Break}
        Available  {$Value = 'Available';Break}
        Default    {$Value = 'Unknow / Dev Error';Break}
    }
    
    Return $Value
}

# used only to Get the status
Function Get-Status {

<#
.SYNOPSIS
    Convert technical status to Human Readable status

.DESCRIPTION
    Convert technical status to Human Readable status

.PARAMETER status
    status value to convert

.EXAMPLE
    Get-status -status "0"

.INPUTS
    $status

.OUTPUTS
    Human Readable status

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to many functions

#>

    Param (
        [Parameter(Mandatory=$False)]
        [String]$Status
    )
    
    Switch ($Status) {
    
        ''           {$Value = 'Cant be define because service is disabled';Break}
        .            {$Value = 'Not available with your device';Break}
        -1           {$Value = 'Error';Break}
        0            {$Value = 'Disable';Break}
        1            {$Value = 'Enable';Break}
        2            {$Value = 'Enable';Break}
        3            {$Value = 'Enable';Break}
        4            {$Value = 'Enable';Break}
        8            {$Value = 'Enable';Break}
        55           {$Value = 'Enable';Break}
        on           {$Value = 'Enable';Break}
        off          {$Value = 'Disable';Break}
        Up           {$Value = 'Enable';Break}
        Down         {$Value = 'Disable';Break}
        None         {$Value = 'None';Break}
        True         {$Value = 'Yes';Break}
        False        {$Value = 'No';Break}
        Idle         {$Value = 'Idle';Break}
        Configured   {$Value = 'Configured';Break}
        Connected    {$Value = 'Connected';Break}
        Disconnected {$Value = 'Disconnected';Break}
        Discover     {$Value = 'Discover';Break}
        Disabled     {$Value = 'Disabled';Break}
        Disable      {$Value = 'Disable';Break}
        Enabled      {$Value = 'Enabled';Break}
        Enable       {$Value = 'Enable';Break}
        Empty        {$Value = 'Empty';Break}
        Error        {$Value = 'Error';Break}
        Ready        {$Value = 'Ready';Break}
        Allowed      {$Value = 'Allowed';Break}
        Forbidden    {$Value = 'Forbidden';Break}
        Done         {$Value = 'Done';Break}
        Preferred    {$Value = 'Preferred';Break}
        Reloading    {$Value = 'Reloading';Break}
        Default      {$Value = 'Unknow / Dev Error';Break}
    }
    
    Return $Value
}

# Used only to transform binary answer to Yes (1) or No (0)
Function Get-YesNoAsk {

<#
.SYNOPSIS
    To get if answer is Yes or No

.DESCRIPTION
    To get if answer is Yes or No

.PARAMETER YesNoAsk
    Two value possible : 0 / 1

.EXAMPLE
    Get-YesNoAsk -YesNoAsk 0
    Get-YesNoAsk -YesNoAsk 1

.INPUTS
    $YesNoAsk

.OUTPUTS
    Human Readable

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to many functions

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$YesNoAsk
    )
    
    Switch ($YesNoAsk) {
    
        0       {$Value = 'No';Break}
        1       {$Value = 'Yes';Break}
        Default {$Value = 'Unknow / Dev Error';Break}
    }
    
    Return $Value
}

# Used only when date is in second for the the last Seen Date settings
Function Get-LastSeenDate {

<#
.SYNOPSIS
    Convert when date is in second for the the last Seen Date settings

.DESCRIPTION
    Convert when date is in second for the the last Seen Date settings

.PARAMETER $Seconds
    Time in second to convert to date

.EXAMPLE
    Get-LastSeenDate -Seconds 1
    Get-LastSeenDate -Seconds 100

.INPUTS
    $Seconds

.OUTPUTS
    Seconds converted to date

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-HOSTS', 'Get-HOSTSME'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [Int]$Seconds
    )
    
    $Date = $(Get-Date).AddSeconds(-$Seconds)
    
    Return $Date
}

# Used only to change/Modify date format to Human readable
Function Edit-Date {

<#
.SYNOPSIS
    Edit Bad formated date

.DESCRIPTION
    Edit Bad formated date

.PARAMETER Date
    Date with bad format

.EXAMPLE
    Edit-Date -Date "2023-01-01T00:00:00Z+001"
    Edit-Date -Date "2023-01-01T00:00:00Z+002"

.INPUTS
    $Date

.OUTPUTS
    Date properly formated

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-BackupList', 'Get-USERSAVE', 'Get-Device', 'Get-DeviceLog', 'Get-DeviceFullLog', 'Get-DeviceFullTechnicalLog', 'Get-DeviceConnectionHistoryLog', 'Get-DeviceSummary', 'Get-DYNDNSClient', 'Get-HOSTS', 'Get-IPTVDiags', 'Get-ParentalControl', 'Get-ParentalControlScheduler', 'Get-SUMMARY', 'Get-VOIPScheduler', 'Get-WANAutowanConfig', 'Get-WIRELESSScheduler'

#>

    Param (
        [Parameter(Mandatory=$False)]
        [String]$Date
    )
    
    If (-not ([string]::IsNullOrEmpty($Date))) {
    
        $Temp = $Date.replace("-","/")
        $Temp = $Temp.replace("T"," ")
        $Temp = $Temp.replace("Z","")
        $Temp = $Temp.Split("+")[0]
        
        Return $Temp
    }
    Else {
        Return $Null
    }
}

# Used only to get USB folder type
Function Get-USBFolderType {

<#
.SYNOPSIS
    Convert Usb Folder Type to Human readable

.DESCRIPTION
    Convert Usb Folder Type to Human readable

.PARAMETER USBFolderType
    Technical value for folder type

.EXAMPLE
    Get-USBFolderType -USBFolderType 0
    Get-USBFolderType -USBFolderType 1

.INPUTS
    $USBFolderType

.OUTPUTS
    Human readable for Usb folder Type

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-USBStorage'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$USBFolderType
    )
    
    Switch ($USBFolderType) {
    
        0       {$Value = "Directory";Break}
        1       {$Value = 'Photo';Break}
        2       {$Value = 'Video';Break}
        3       {$Value = 'Music';Break}
        4       {$Value = 'Document';Break}
        10      {$Value = 'Other';Break}
        Default {$Value = 'Unknow / Dev Error';Break}
    }
    
    Return $Value
}

# Format Custom Date/Time where the date is based from 1970 years
function Format-Date1970 {

<#
.SYNOPSIS
    Convert Date/Time based on date 01/01/1970

.DESCRIPTION
    Convert Date/Time based on date 01/01/1970

.PARAMETER Seconds
    Time in seconds

.EXAMPLE
    Format-Date1970 -Seconds 1
    Format-Date1970 -Seconds 10

.INPUTS
    $Seconds

.OUTPUTS
    Date converted

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Start-RefreshBBOXWIRELESSFrequencyNeighborhoodScan', 'Get-VOIPCallLogLineX', 'Get-VOIPFullCallLogLineX'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$Seconds
    )
    
    $Date = (Get-Date -Date '01/01/1970').addseconds($Seconds)
    
    Return $Date
}

# Used only to get USB right
Function Get-USBRight {

<#
.SYNOPSIS
    To convert USB right to Human readable

.DESCRIPTION
    To convert USB right to Human readable

.PARAMETER USBRight
    Technical right to be convert

.EXAMPLE
    Get-USBRight -USBRight 0
    Get-USBRight -USBRight 1

.INPUTS
    $USBRight

.OUTPUTS
    Human readable for Usb folder rights

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-DeviceUSBDevices'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$USBRight
    )
    
    Switch ($USBRight) {
    
        0       {$Value = 'Read Only';Break}
        1       {$Value = 'Read/Write';Break}
        Default {$Value = 'Unknow / Dev Error';Break}
    }
    
    Return $Value
}

# Used only to get which call type
Function Get-VoiceCallType {

<#
.SYNOPSIS
    To get which call type

.DESCRIPTION
    To get which call type

.PARAMETER VoiceCallType
    Voice call Type must be : in, in_reject, in_barred, out

.EXAMPLE
    Get-VoiceCallType -VoiceCallType in
    Get-VoiceCallType -VoiceCallType in_reject
    Get-VoiceCallType -VoiceCallType in_barred
    Get-VoiceCallType -VoiceCallType out
    Get-VoiceCallType -VoiceCallType ?

.INPUTS
    VoiceCallType

.OUTPUTS
    Human readable for Voice Call Type

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-VOIPCallLogLineX'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$VoiceCallType
    )
    
    Switch ($VoiceCallType) {
    
        in        {$Value = 'Incoming';Break}
        in_reject {$Value = "Incoming Rejected (`"Unknow`" active rule)";Break}
        in_barred {$Value = 'Incoming Out Range Call (Active rule)';Break}
        out       {$Value = 'Outgoing';Break}
        Default   {$Value = 'Unknow / Dev Error - $VoiceCallType';Break}
    }
    
    Return $Value
}

# Used only To get Power Status for leds ethernet ports
Function Get-PowerStatus {

<#
.SYNOPSIS
    To get Power Status for leds ethernet ports

.DESCRIPTION
    To get Power Status for leds ethernet ports

.PARAMETER PowerStatus
    Power Status for leds ethernet ports

.EXAMPLE
    Get-PowerStatus -PowerStatus on
    Get-PowerStatus -PowerStatus off
    Get-PowerStatus -PowerStatus Up
    Get-PowerStatus -PowerStatus Down
    Get-PowerStatus -PowerStatus blink

.INPUTS
    $PowerStatus 

.OUTPUTS
    Human Readable for leds ethernet ports status

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-DeviceLED'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$PowerStatus
    )
    
    Switch ($PowerStatus) {
        
        on      {$Value = 'Light Up';Break}
        off     {$Value = 'Light Down';Break}
        Up      {$Value = 'Light Up';Break}
        Down    {$Value = 'Light Down';Break}
        blink   {$Value = 'Light Blinking';Break}
        Default {$Value = 'Unknow / Dev Error';Break}
    }
    
    Return $Value
}

# Used only to get phone line
Function Get-PhoneLine {

<#
.SYNOPSIS
    To get phone line

.DESCRIPTION
    To get phone line

.PARAMETER Phoneline
    Phone line position number, 2 possible values : 1,2

.EXAMPLE
    Get-PhoneLine -Phoneline 1
    Get-PhoneLine -Phoneline 2

.INPUTS
    $Phoneline

.OUTPUTS
    Phone line position detailled

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-DeviceLog', 'Get-LANAlerts', "Get-DeviceFullTechnicalLog", "Get-DeviceFullLog", "", "", "", "", "", ""
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$Phoneline
    )
    
    Switch ($Phoneline) {
    
        1       {$PhoneLinePosition = 'Line 1';Break}
        2       {$PhoneLinePosition = 'Line 2';Break}
        Default {$PhoneLinePosition = 'Unknow';Break}
    }
    
    Return $PhoneLinePosition
}

# Used only to select by user the phone line to check
Function Get-PhoneLineID {

<#
.SYNOPSIS
    To select by user the phone line to check

.DESCRIPTION
    To select by user the phone line to check

.PARAMETER LineID
    Phone line position

.EXAMPLE
    Get-PhoneLineID -LineID 1
    Get-PhoneLineID -LineID 2

.INPUTS
    User phone line selection

.OUTPUTS
    $LineID

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-VOIPCallLogLine', 'Get-VOIPFullCallLogLine'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    While ($LineID -notmatch $global:ValuesLineNumber) {
        
        #$LineID = Read-Host "Enter value"
        $LineID = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Choose Phone Line ID' -LabelMessageText "Which Phone line do you want to select ?`n(1) Main line`n(2) Second line" -FirstOptionButtonText '1' -SecondOptionButtonText '2'
    }
    
    Return $LineID
}

# Used by Function : 'Switch-Info' - To get Call log by line ID
Function Get-VOIPCallLogLine {

<#
.SYNOPSIS
    To get Call log by line ID

.DESCRIPTION
    To get Call log by line ID

.PARAMETER UrlToGo
    Url to get the call log for the selected line ID

.EXAMPLE
    Get-VOIPCallLogLine -UrlToGo "https://mabbox.bytel.fr/api/v1/voip/calllog/1"
    Get-VOIPCallLogLine -UrlToGo "https://mabbox.bytel.fr/api/v1/voip/calllog/2"
    Get-VOIPCallLogLine -UrlToGo "https://exemple.com:8560/api/v1/voip/calllog/1"
    Get-VOIPCallLogLine -UrlToGo "https://exemple.com:8560/api/v1/voip/calllog/2"
    
.INPUTS
    $UrlToGo
    $LineID

.OUTPUTS
    Calls log history for the line ID selected

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-PhoneLineID', 'Get-VOIPCalllogLineX', 'Switch-Info'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )

    $LineID = Get-PhoneLineID
    $FormatedData = Get-VOIPCalllogLineX -UrlToGo "$UrlToGo/$LineID"
    
    Return $FormatedData
}

# Used by Function : Switch-Info  - To get full Call log by line ID
Function Get-VOIPFullCallLogLine {

<#
.SYNOPSIS
    To get full Call log by line ID

.DESCRIPTION
    To get full Call log by line ID

.PARAMETER UrlToGo
    Url to get the full call log for the selected line ID

.EXAMPLE
    Get-VOIPFullCallLogLine -UrlToGo "https://mabbox.bytel.fr/api/v1/voip/fullcalllog/1"
    Get-VOIPFullCallLogLine -UrlToGo "https://mabbox.bytel.fr/api/v1/voip/fullcalllog/2"
    Get-VOIPFullCallLogLine -UrlToGo "https://exemple.com:8560/api/v1/voip/fullcalllog/1"
    Get-VOIPFullCallLogLine -UrlToGo "https://exemple.com:8560/api/v1/voip/fullcalllog/2"
    
.INPUTS
    $UrlToGo
    $LineID

.OUTPUTS
    Full Calls log history for the line ID selected

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-PhoneLineID', 'Get-VOIPFullcalllogLineX', 'Switch-Info'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $LineID = Get-PhoneLineID
    $FormatedData = Get-VOIPFullcalllogLineX -UrlToGo "$UrlToGo/$LineID"
    
    Return $FormatedData
}

# Used only to clarify DynDns Status Error Message
Function Get-DynDnsStatusErrorMessageDetail {

    <#
    .SYNOPSIS
        To get the detail when DynDns is in error
    
    .DESCRIPTION
        To get the detail when DynDns is in error
    
    .PARAMETER Status
        Value possible : many
    
    .EXAMPLE
        Get-DynDnsStatusErrorMessageDetail Status 'Error'
        Get-DynDnsStatusErrorMessageDetail Status 'KO'
    
    .INPUTS
        $Status
    
    .OUTPUTS
        Error Detail message
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to function : Get-DYNDNSClient
    
    #>
    
        Param (
            [Parameter(Mandatory=$True)]
            [String]$Status
        )
        
        Switch ($Status) {
            
            Ok        {$Value = '';Break}
            failed    {$Value = 'Oh, it seems, you enter wrong credentials, please check that you enter the correct login and password';Break}
            dns-error {$Value = 'It seems, the declared DNS HostName to your DYNDNS Box Interface it not yet published to your DNS provider, please check that you enter the correct DNS HostName and if it already exists on your DNS provider list';Break}
            Default   {$Value = 'Unknow / Dev Error';Break}
        }
        
        Return $Value
}

# Used only to clarify DynDns Status Valid Message
Function Get-DynDnsStatusValidMessageDetail {

    <#
    .SYNOPSIS
        To get the detail when DynDns is valid
    
    .DESCRIPTION
        To get the detail when DynDns is valid
    
    .PARAMETER Status
        Value possible : many
    
    .EXAMPLE
        Get-DynDnsStatusValidMessageDetail Status 'Error'
        Get-DynDnsStatusValidMessageDetail Status 'KO'
    
    .INPUTS
        $Status
    
    .OUTPUTS
        Error Detail message
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to function : Get-DYNDNSClient
    
    #>
    
        Param (
            [Parameter(Mandatory=$True)]
            [String]$Status
        )
        
        $Temp = $Status -split ' '
        
        Switch ($Temp[1]) {
            
            nochg   {$Value = "No change have made since last synchronisation with your DNS provider - Answered DNS Server : $($Temp[2])";Break}
            nohos   {$Value = 'Your credentials are valid, but it seems; you miss to register the DNS hostname to your DNS provider console';Break}
            good    {$Value = "Good job, the hostname that you just declare here are well synchronize for the first time with your DNS provider - Answered DNS Server : $($Temp[2])";Break}
            Default {$Value = 'Unknow / Dev Error';Break}
        }
        
        Return $Value
}

# Used only to clarify DynDns Status Valid Message
Function Get-DynDnsRecordDetail {

    <#
    .SYNOPSIS
        To get the detail of DynDns record
    
    .DESCRIPTION
        To get the detail of DynDns record
    
    .PARAMETER Status
        Value possible : many
    
    .EXAMPLE
        Get-DynDnsRecordDetail -Record 'A'
        Get-DynDnsRecordDetail -Record 'AAAA'
    
    .INPUTS
        $Status
    
    .OUTPUTS
        Record Detail
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to function : Get-DYNDNSClient
    
    #>
    
        Param (
            [Parameter(Mandatory=$True)]
            [String]$Record
        )
        
        Switch ($Record) {
            
            A       {$Value = 'IPV4';Break}
            AAAA    {$Value = 'IPV6';Break}
            Default {$Value = 'Unknow / Dev Error';Break}
        }
        
        Return $Value
}

# Used only to set (PUT/POST) information
Function Set-BBOXInformation {

<#
.SYNOPSIS
    To set (PUT/POST) information

.DESCRIPTION
    To set (PUT/POST) information

.PARAMETER UrlHome
    Box login url

.PARAMETER Password
    Box Web administration password

.PARAMETER UrlToGo
    Web request to sent to the API

.EXAMPLE
    Set-BBOXInformation -UrlHome "https://mabbox.bytel.fr/login.html" -Password "password" -UrlToGo ""

.INPUTS
    $UrlHome
    $Password
    $UrlToGo

.OUTPUTS
    Return result of the resquest send to API

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): '', ''
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlHome,
        
        [Parameter(Mandatory=$True)]
        [String]$Password,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    Write-Log -Type ERROR -Category 'Program run' -Name 'Set Box Information' -Message "`nConnexion à la Box : "
    
    # Add path for ChromeDriver.exe to the environmental variable 
    $env:PATH += $PSScriptRoot
    
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
    $global:ChromeDriver.FindElementByName('password').SendKeys("$Password") 
    Start-Sleep $global:SleepDefault
    
    # Click on the connect button
    $global:ChromeDriver.FindElementByClassName('cta-1').Submit()
    Start-Sleep $global:SleepChromeDriverNavigation
    
    Write-Log -Type VALUE -Category 'Program run' -Name 'Set Box Information' -Message  'OK'
    Write-Log -Type INFO -Category 'Program run' -Name 'Set Box Information' -Message  'Application des modifications souhaitées : '
    
    # Go to the web page to get information we need
    $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
    
    # Get Web page Content
    $Html = $global:ChromeDriver.PageSource
    
    # Close all ChromeDriver instances openned
    $global:ChromeDriver.Close()
    $global:ChromeDriver.Dispose()
    $global:ChromeDriver.Quit()
    
    Get-Process -Name chromedriver -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
    
    Write-Log -Type VALUE -Category 'Program run' -Name 'Set Box Information' -Message 'OK'
    
    Return $Html
}    

# Used only to define Box connexion type
Function Get-ConnexionType {

<#
.SYNOPSIS
    To define Box connexion type

.DESCRIPTION
    To define Box connexion type

.PARAMETER TriggerLANNetwork
    Define Box connexion type

.EXAMPLE
    Get-ConnexionType -TriggerLANNetwork 0
    Get-ConnexionType -TriggerLANNetwork 1

.INPUTS
    $TriggerLANNetwork

.OUTPUTS
    $ConnexionType

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Show-WindowsFormDialogBox3ChoicesCancel', 'Show-WindowsFormDialogBox2ChoicesCancel'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$TriggerLANNetwork
    )
    
    Switch ($TriggerLANNetwork) {
    
        '1'        {$ConnexionTypeChoice = $global:ValuesLANNetworkLocal;Break}
        
        '0'        {$ConnexionTypeChoice = $global:ValuesLANNetworkRemote;Break}
        
        Default    {$ConnexionTypeChoice = $global:ValuesLANNetworkLocal;Break}
    }
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Connexion Type' -Message "How do you want to connect to the $global:BoxType ?" -NotDisplay

    $ConnexionType = ''
    While ($ConnexionType -notmatch $ConnexionTypeChoice) {
        
        Switch ($TriggerLANNetwork) {
            
            '1'        {Write-Log -Type INFO -Category 'Program run' -Name 'Connexion Type' -Message '(L) Localy / (R) Remotly / (Q) Quit the Program' -NotDisplay
                        $ConnexionType = Show-WindowsFormDialogBox3ChoicesCancel -MainFormTitle 'Program run - Connexion Type' -LabelMessageText "How do you want to connect to the $global:BoxType ? : `n- (L) Localy`n- (R) Remotly`n- (Q) Quit the Program" -FirstOptionButtonText 'L' -SecondOptionButtonText 'R' -ThirdOptionButtonText 'Q'
                        Break
                    }
            
            '0'        {Write-Log -Type INFO -Category 'Program run' -Name 'Connexion Type' -Message '(R) Remotly / (Q) Quit the Program' -NotDisplay
                        $ConnexionType = Show-WindowsFormDialogBox2ChoicesCancel -MainFormTitle 'Program run - Connexion Type' -LabelMessageText "How do you want to connect to the $global:BoxType ? : `n- (R) Remotly`n- (Q) Quit the Program" -FirstOptionButtonText 'R' -SecondOptionButtonText 'Q'
                        Break
                    }
            
            Default    {Write-Log -Type INFO -Category 'Program run' -Name 'Connexion Type' -Message '(L) Localy / (R) Remotly / (Q) Quit the Program' -NotDisplay
                        $ConnexionType = Show-WindowsFormDialogBox3ChoicesCancel -MainFormTitle 'Program run - Connexion Type' -LabelMessageText "How do you want to connect to the $global:BoxType ? : `n- (L) Localy`n- (R) Remotly`n- (Q) Quit the Program" -FirstOptionButtonText 'L' -SecondOptionButtonText 'R' -ThirdOptionButtonText 'Q'
                        Break
                    }
        }
    }
     
    Write-Log -Type INFO -Category 'Program run' -Name 'Connexion Type' -Message "Connexion Type chosen by user : $ConnexionType" -NotDisplay
    
    Return $ConnexionType
}

# Used only to check if external Box DNS is online 
Function Get-HostStatus {

<#
.SYNOPSIS
    To check if external Box DNS is online

.DESCRIPTION
    To check if external Box DNS is online

.PARAMETER UrlRoot
    This is the Root DNS/url to connect to the Box web interface

.EXAMPLE
    Get-HostStatus -UrlRoot "mybox.bytel.fr"
    Get-HostStatus -UrlRoot "exemple.com"

.INPUTS
    $UrlRoot

.OUTPUTS
    Box Host Status

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Stop-Program', 'Show-WindowsFormDialogBoxInuput', 'Test-Connection', 'Show-WindowsFormDialogBox', 'Set-ValueToJSONFile'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param ()
    
    If ($global:BoxType -eq "Freebox") {
        
        $UrlRoot = Show-WindowsFormDialogBoxInuput -MainFormTitle 'Program run - Check Host' -LabelMessageText "Enter your external $global:BoxType IP/DNS Address, Example : example.com" -OkButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.Ok -CancelButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.Cancel -DefaultValue $DefaultValue
        Return $UrlRoot
    }
    
    Else {

        If (-not [string]::IsNullOrEmpty($global:SiteCurrentLocalUrl) -and ($global:SiteCurrentLocalUrl -notcontains $global:ErrorResolveDNSMessage)) {
            $DefaultValue = $global:SiteCurrentLocalUrl
        }
        Elseif (-not [string]::IsNullOrEmpty($global:SiteOldRemoteUrl) -and ($global:SiteOldRemoteUrl -notcontains $global:ErrorResolveDNSMessage)) {
            $DefaultValue = $global:SiteOldRemoteUrl
        }
        Else {
            $DefaultValue = $global:DefaultLocalUrl
        }
        
        $BoxDnsStatus = $null
        While ($null -eq $BoxDnsStatus) {
            
            $UrlRoot = Show-WindowsFormDialogBoxInuput -MainFormTitle 'Program run - Check Host' -LabelMessageText "Enter your external $global:BoxType IP/DNS Address, Example : example.com" -OkButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.OK -CancelButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.Cancel -DefaultValue $DefaultValue
            Write-Log -Type INFONO -Category 'Program run' -Name 'Check Host' -Message "Host `"$UrlRoot`" status : " -NotDisplay
            
            If ($global:TriggerDialogBox -eq 1) {
                
                Write-Log -Type VALUE -Category 'Program run' -Name 'Check Host' -Message 'User Cancel the action' -NotDisplay
                Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop
                $UrlRoot = $null
                Return $UrlRoot
                Break
            }
            
            If (-not ([string]::IsNullOrEmpty($UrlRoot))) {
                
                Try {
                    $BoxDnsStatus = Test-Connection -ComputerName $UrlRoot -Quiet
                }
                
                Catch {
                    Write-Log -Type ERROR -Category 'Program run' -Name 'Check Host' -Message "Failed to resolve / Access to : $UrlRoot, due to : $($_.ToString())"
                    #$global:TriggerExitSystem = 1
                }
                
                If ($BoxDnsStatus -eq $true) {
                    
                    Write-Log -Type VALUE -Category 'Program run' -Name 'Check Host' -Message 'Online' -NotDisplay
                    $global:JSONSettingsCurrentUserContent.Site.oldRemoteUrl = $global:SiteCurrentRemoteUrl
                    $global:JSONSettingsCurrentUserContent.Site.CurrentRemoteUrl = $UrlRoot
                    Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath
                    Return $UrlRoot
                    Break
                }
                Else {
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Host' -Message 'Offline' -NotDisplay
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Host' -Message "Host : $UrlRoot , seems OffLine ; please make sure :"
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Host' -Message "- You are connected to internet"
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Host' -Message "- You enter a valid DNS address or IP address"
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Host' -Message "- The `"PingResponder`" service is enabled ($global:BoxUrlFirewall)"
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Host' -Message "- The `"DYNDNS`" service is enabled and properly configured ($global:BoxUrlDynDns)"
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Host' -Message "- The `"Remote`" service is enabled and properly configured ($global:BoxUrlRemote)"
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Host' -Message "- If you use a proxy, that do not block the connection to your public dyndns"
                    Show-WindowsFormDialogBox -Title 'Program run - Check Host' -Message "Host : $UrlRoot , seems OffLine ; please make sure :`n`n- You are connected to internet`n- You enter a valid DNS address or IP address`n- The `"PingResponder`" service is enabled ($global:BoxUrlFirewall)`n- The `"DYNDNS`" service is enabled and properly configured ($global:BoxUrlDynDns)`n- The `"Remote`" service is enabled and properly configured ($global:BoxUrlRemote)`n- If you use a proxy, that do not block the connection to your public dyndns" -WarnIcon
                    $BoxDnsStatus = $null
                    $UrlRoot = $null
                }
            }
            Else {
                Write-Log -Type WARNING -Category 'Program initialisation' -Name 'Check Host' -Message "This field can't be empty or null"
                Show-WindowsFormDialogBox -Title 'Program run - Check Host' -Message "This field can't be empty or null" -WarnIcon
                $BoxDnsStatus = $null
                $UrlRoot = $null
            }
        }
    }
}

# Used only to check if external Box Port is open
Function Get-PortStatus {

<#
.SYNOPSIS
    To check if external Box Port is open

.DESCRIPTION
    To check if external Box Port is open

.PARAMETER UrlRoot
    This is the Root DNS/url to connect to the Box web interface

.PARAMETER Port
    This is the port to check if open or not

.EXAMPLE
    Get-HostStatus -UrlRoot "exemple.com" -Port "8560"
    Get-HostStatus -UrlRoot "exemple.com" -Port "80"

.INPUTS
    $UrlRoot
    $Port

.OUTPUTS
    $Port

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Stop-Program', 'Show-WindowsFormDialogBoxInuput', 'Show-WindowsFormDialogBox', 'Test-NetConnection', 'Set-ValueToJSONFile'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot
    )

    If ($global:BoxType -eq "Freebox") {
        
        [Int]$Port = Show-WindowsFormDialogBoxInuput -MainFormTitle 'Program run - Check Port' -LabelMessageText "Enter your external remote $global:BoxType port`nDefault is : $global:DefaultRemotePort`nExample : 80,443" -OkButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.Ok -CancelButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.Cancel -DefaultValue $global:DefaultRemotePort
    }
    Else {
        
        If (-not [string]::IsNullOrEmpty($global:SiteCurrentRemotePort) -and ($global:SiteCurrentRemotePort -notcontains $global:ErrorResolveDNSMessage)) {
            $DefaultValue = $global:SiteCurrentRemotePort
        }
        Elseif (-not [string]::IsNullOrEmpty($global:SiteOldRemotePort) -and ($global:SiteOldRemotePort -notcontains $global:ErrorResolveDNSMessage)) {
            $DefaultValue = $global:SiteOldRemotePort
        }
        Else {
            $DefaultValue = $global:DefaultRemotePort
        }
        
        $PortStatus = $null
        While ([string]::IsNullOrEmpty($PortStatus) -or [string]::IsNullOrEmpty($Port)) {
            
            [Int]$Port = Show-WindowsFormDialogBoxInuput -MainFormTitle 'Program run - Check Port' -LabelMessageText "Enter your external remote $global:BoxType port`nValid range port is from : 1 to : 65535`nDefault is : $global:DefaultRemotePort`nExample : 80,443" -OkButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.Ok -CancelButtonText $global:JSONSettingsProgramContent.DialogueBox.ButtonText.Cancel -DefaultValue $DefaultValue
            Write-Log -Type INFONO -Category 'Program run' -Name 'Check Port' -Message "Port `"$Port`" status : " -NotDisplay
            
            If ($global:TriggerDialogBox -eq 1) {
                
                Write-Log -Type VALUE -Category 'Program run' -Name 'Check Port' -Message 'User Cancel the action' -NotDisplay
                Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop
                Break
            }
            
            If (($Port -ge 1) -and ($Port -le 65535)) {
                
                $PortStatus = Test-NetConnection -ComputerName $UrlRoot -Port $Port -InformationLevel Detailed
                Write-Log -Type VALUE -Category 'Program run' -Name 'Check Port' -Message $PortStatus.TcpTestSucceeded -NotDisplay
                
                If ($PortStatus.TcpTestSucceeded -eq $true) {
                    
                    Write-Log -Type VALUE -Category 'Program run' -Name 'Check Port' -Message 'Opened' -NotDisplay
                    $global:JSONSettingsCurrentUserContent.Site.OldRemotePort = $global:SiteCurrentRemotePort
                    $global:JSONSettingsCurrentUserContent.Site.CurrentRemotePort = $Port
                    Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath
                    Return $Port
                    Break
                }
                Else {
                    
                    If ([string]::IsNullOrEmpty($global:SiteOldRemotePort)) {
                        $OldRemotePort = $global:SiteOldRemotePort
                    }
                    Else {
                        $OldRemotePort = $global:DefaultRemotePort
                    }
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Port' -Message 'Closed' -NotDisplay
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Port' -Message "Port $Port seems closed, please make sure :"
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Port' -Message "- You enter a valid port number"
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Port' -Message "- None Firewall rule(s) block this port ($global:BoxUrlFirewall)"
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Port' -Message "- `"Remote`" service is enabled and properly configured ($global:BoxUrlRemote)"
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Check Port' -Message "- For remember you use the port : $OldRemotePort the last time"
                    Show-WindowsFormDialogBox -Title 'Program run - Check Port' -Message "Port $Port seems closed, please make sure :`n`n- You enter a valid port number between 1 and 65535`n- None Firewall rule(s) block this port ($global:BoxUrlFirewall)`n- `"Remote`" service is enabled and properly configured ($global:BoxUrlRemote)`n- For remember you use the port : $OldRemotePort the last time" -WarnIcon
                    $Port = $null
                    $PortStatus = $null
                }
            }
            Else {
                Write-Log -Type WARNING -Category 'Program run' -Name 'Check Port' -Message 'This field cant be empty or null or must be in the range between 1 and 65565'
                Show-WindowsFormDialogBox -Title 'Program run - Check Port' -Message 'This field cant be empty or null or must be in the range between 1 and 65565' -WarnIcon
                $Port = $null
                $PortStatus = $null
            }
        }
    }
}

# Used only to get Box LAN Switch Port State
Function Get-LanPortState {

<#
.SYNOPSIS
    To get Box LAN Switch Port State

.DESCRIPTION
    To get Box LAN Switch Port State

.PARAMETER LanPortState
    This is the switch port number to get the state

.EXAMPLE
    Get-LanPortState -LanPortState 1
    Get-LanPortState -LanPortState 2
    Get-LanPortState -LanPortState 3
    Get-LanPortState -LanPortState 4

.INPUTS
    $LanPortState

.OUTPUTS
    $State

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-BBOXDeviceFullLog'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$LanPortState
    )
    
    Switch ($LanPortState) {
    
        0          {$State = "Disable";Break}
        1          {$State = "Enable";Break}
        2          {$State = "Enable";Break}
        3          {$State = "Enable";Break}
        4          {$State = "Enable";Break}
        Default    {$State = "Unknow";Break}
    }
    
    Return $State
}

# Used only to connect to BBox Web Interface
Function Connect-BBox {

<#
.SYNOPSIS
    To connect to BBox Web interface

.DESCRIPTION
    To connect to BBox Web interface

.PARAMETER UrlAuth
    This is the url use to login to the BBox web interface

.PARAMETER UrlHome
    This is the main page of BBox web interface

.PARAMETER Password
    This is the user password to authentificate to Box web interface
    
.EXAMPLE
    Connect-BBOX -UrlAuth "https://mabbox.bytel.fr"      -UrlHome "https://mabbox.bytel.fr/index.html"      -Password "Password"
    Connect-BBOX -UrlAuth "https://mabbox.bytel.fr:8560" -UrlHome "https://mabbox.bytel.fr:8560/index.html" -Password "Password"
    Connect-BBOX -UrlAuth "https://exemple.com:80"       -UrlHome "https://exemple.com:80/index.html"       -Password "Password"

.INPUTS
    $UrlAuth
    $UrlHome
    $Password

.OUTPUTS
    User authentificated to the Box Web Interface

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Stop-Program'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlAuth,

        [Parameter(Mandatory=$True)]
        [String]$UrlHome,
        
        [Parameter(Mandatory=$True)]
        [String]$Password
    )
    
    # Open Web Site Home Page 
    $global:ChromeDriver.Navigate().GoToURL($UrlAuth)
    Start-Sleep $global:SleepChromeDriverNavigation
    
    # Enter the password to connect (# Methods to find the input textbox for the password)
    $global:ChromeDriver.FindElementByName("password").SendKeys("$Password") 
    Start-Sleep $global:SleepDefault
    
    # Tic checkBox "Stay Connect" (# Methods to find the input checkbox for stay connect)
    $global:ChromeDriver.FindElementByClassName('cb').Click()
    Start-Sleep $global:SleepDefault
    
    # Click on the connect button
    $global:ChromeDriver.FindElementByClassName('cta-1').Submit()
    Start-Sleep $global:SleepDefault

    If ($global:ChromeDriver.Url -ne $UrlHome) {
        Write-Log ERROR -Category 'Program run' -Name 'ChromeDriver Authentification' -Message "Failed, Authentification can't be done, due to : Wrong Password or connection timeout"
        Stop-Program -Context System -ErrorMessage 'Authentification can not be done' -Reason 'Authentification can not be done' -ErrorAction Stop
    }
    
    <#
    $LoginParameters = @{
        Uri             = $UrlAuth
        SessionVariable = 'Session'
        Method          = 'POST'
        Body            = @{
        Password        = $Password
        }
    }
     
    $LoginResponse = Invoke-WebRequest @LoginParameters

    If ($LoginResponse.StatusCode -ne '200') {
        Write-Log ERROR -Category 'Program run' -Name 'ChromeDriver Authentification' -Message 'Failed, Authentification cant be done, due to : Wrong Password or connection timeout'
        Stop-Program -Context System -ErrorMessage 'Authentification can not be done' -Reason 'Authentification can not be done' -ErrorAction Stop
    }
    Else {
        Write-Log value -Category 'Program run' -Name 'ChromeDriver Authentification' -Message 'Successful'
    }
    #>
}

# Used only to connect to FREEBOX Web Interface
Function Connect-FREEBOX {
    
<#
.SYNOPSIS
    To connect to Box Web interface

.DESCRIPTION
    To connect to Box Web interface

.PARAMETER UrlAuth
    This is the url use to login to the Box web interface

.PARAMETER UrlHome
    This is the main page of Box web interface

.PARAMETER Password
    This is the user password to authentificate to Box web interface
    
.EXAMPLE
    Connect-BOX -UrlAuth "https://192.168.0.254"      -UrlHome "https://192.168.0.254/index.html"      -Password "Password"
    Connect-BOX -UrlAuth "https://192.168.0.254:8560" -UrlHome "https://192.168.0.254:8560/index.html" -Password "Password"
    Connect-BOX -UrlAuth "https://exemple.com:80"     -UrlHome "https://exemple.com:80/index.html"     -Password "Password"

.INPUTS
    $UrlAuth
    $UrlHome
    $Password

.OUTPUTS
    User authentificated to the Box Web Interface

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Stop-Program'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlAuth,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlHome,
        
        [Parameter(Mandatory=$True)]
        [String]$Password
    )
    
    # Open Web Site Home Page 
    $global:ChromeDriver.Navigate().GoToURL($UrlAuth)
    Start-Sleep $global:SleepDefault

    # Enter the password to connect (# Methods to find the input textbox for the password)
    $global:ChromeDriver.FindElementByClassName("password").SendKeys("$Password") 
    Start-Sleep $global:SleepDefault
    
    # Click on the connect button
    $global:ChromeDriver.FindElementByClassName("submit-btn").Submit()
    Start-Sleep $global:SleepChromeDriverLoading

    <#"If ($global:ChromeDriver.Url -ne $UrlHome) {
        Write-Log ERROR -Category 'Program run' -Name 'ChromeDriver Authentification' -Message 'Failed, Authentification cant be done, due to : Wrong Password or connection timeout'
        Stop-Program -Context System -ErrorAction Stop
    }#>
}

# Used only to get information from API page content for BBOX
Function Get-BBOXInformation {

<#
.SYNOPSIS
    To get information from API page content

.DESCRIPTION
    To get information from API page content

.PARAMETER UrlToGo
    This is the url that you want to collect data

.EXAMPLE
    Get-BBOXInformation -UrlToGo "https://mabbox.bytel.fr/api/v1/device/log"
    Get-BBOXInformation -UrlToGo "https://exemple.com:8560/api/v1/device/log"
    Get-BBOXInformation -UrlToGo "https://exemple.com:80/api/v1/device/log"

.INPUTS
    UrlToGo

.OUTPUTS
    PSCustomObject = $Json

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'ConvertFrom-HtmlToText', 'Get-BBOXErrorCode', 'ConvertFrom-Json'
    linked to many functions in the module : '.\Box-Modules.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Get Information' -Message "Start retrieve informations requested" -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name 'Get Information' -Message "Get informations requested from url : $UrlToGo" -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name 'Get Information' -Message "Request status :" -NotDisplay
    
    If ($global:PreviousUrlToGo -notcontains $UrlToGo) {
        
        $global:PreviousUrlToGo = $UrlToGo
        
        If (($global:TriggerAuthentification -eq 1) -or ($UrlToGo -match $global:APINameExclusionsChrome)) {
        
            Try {
                # Go to the web page to get information we need
                $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
                Write-Log -Type INFO -Category 'Program run' -Name 'Get Information' -Message 'Successful' -NotDisplay
            }
            Catch {
                Write-Log -Type ERROR -Category 'Program run' -Name 'Get Information' -Message "Failed, due to : $($_.ToString())"
                Write-Log -Type ERROR -Category 'Program run' -Name 'Get Information' -Message "Please check your local/internet network connection"
                Return "0"
                Break
            }
            
            Write-Log -Type INFO -Category 'Program run' -Name 'Get Information' -Message "End retrieve informations requested" -NotDisplay
            Write-Log -Type INFO -Category 'Program run' -Name 'Convert HTML' -Message "Start convert data from Html to plaintxt format" -NotDisplay
            Write-Log -Type INFONO -Category 'Program run' -Name 'Convert HTML' -Message "HTML Conversion status : " -NotDisplay
            
            Try {
                # Get Web page Content
                $Html = $global:ChromeDriver.PageSource
                # Convert $Html To Text
                $Plaintxt = ConvertFrom-HtmlToText -Html $Html
                Write-Log -Type VALUE -Category 'Program run' -Name 'Convert HTML' -Message 'Successful' -NotDisplay
            }
            Catch {
                Write-Log -Type ERROR -Category 'Program run' -Name 'Convert HTML' -Message "Failed to convert to HTML, due to : $($_.ToString())"
                Write-Log -Type INFO -Category 'Program run' -Name 'Convert HTML' -Message "End convert data from Html to plaintxt format" -NotDisplay
                Return "0"
                Break
            }
            Write-Log -Type INFO -Category 'Program run' -Name 'Convert HTML' -Message "End convert data from Html to plaintxt format" -NotDisplay
            Try {
                # Convert $Plaintxt as JSON to array
                $Global:Json = $Plaintxt | ConvertFrom-Json -ErrorAction Stop
                Write-Log -Type VALUE -Category 'Program run' -Name "Convert JSON" -Message 'Successful' -NotDisplay
            }
            Catch {
                Write-Log -Type ERROR -Category 'Program run' -Name "Convert JSON" -Message "Failed - Due to : $($_.ToString())"
                Return "0"
                Break
            }
            Write-Log -Type INFO -Category 'Program run' -Name "Convert JSON" -Message "End convert data from plaintxt to Json format" -NotDisplay
            
            If ($Global:Json.exception.domain -and ($Global:Json.exception.domain -ne "v1/device/log")) {
                
                Write-Log -Type INFO -Category 'Program run' -Name "Get API Error Code" -Message "Start get API error code" -NotDisplay
                Write-Log -Type INFONO -Category 'Program run' -Name "Get API Error Code" -Message "API Error Code : "
                
                Try {
                    $ErrorCode = Get-BBOXErrorCode -Json $Global:Json
                    Write-Log -Type ERROR -Category 'Program run' -Name "Get API Error Code" -Message "$($ErrorCode.Code) - $($ErrorCode.Domain) - $($ErrorCode.Name) - $($ErrorCode.ErrorReason)"
                    Return $ErrorCode.String()
                    Break
                }
                Catch {
                    Write-Log -Type ERROR -Category 'Program run' -Name "Get API Error Code" -Message $Global:Json -NotDisplay
                    Write-Log -Type ERROR -Category 'Program run' -Name "Get API Error Code" -Message "Failed - Due to : $($_.ToString())"
                    Return $null
                }
                
                Write-Log -Type INFO -Category 'Program run' -Name "Get API Error Code" -Message "End get API Error Code" -NotDisplay
            }
            Else {
                Return $Global:Json
            }
        }
        Else {
        
            Try {
                # Get Web page Content
                $Response = Invoke-WebRequest -Uri $UrlToGo -AllowUnencryptedAuthentication -SkipCertificateCheck -SkipHeaderValidation -AllowInsecureRedirect -ConnectionTimeoutSeconds 30 -OperationTimeoutSeconds 30 -RetryIntervalSec 1 -Method Get
                Write-Log -Type INFO -Category 'Program run' -Name 'Get Information' -Message 'Successful' -NotDisplay
            }
            Catch {
                
                Write-Log -Type ERROR -Category 'Program run' -Name 'Get Information' -Message "Failed, due to : $($_.ToString())"
            }
            
            Write-Log -Type INFO -Category 'Program run' -Name "Convert JSON" -Message "Start convert data from plaintxt to Json format" -NotDisplay
            Write-Log -Type INFONO -Category 'Program run' -Name "Convert JSON" -Message "JSON Conversion status : " -NotDisplay
            
            Try {
                # Convert $Plaintxt as JSON to array
                $Global:Json = $($Response.Content) | ConvertFrom-Json -ErrorAction Stop
                Write-Log -Type VALUE -Category 'Program run' -Name "Convert JSON" -Message 'Successful' -NotDisplay
            }
            Catch {
                Write-Log -Type ERROR -Category 'Program run' -Name "Convert JSON" -Message "Failed - Due to : $($_.ToString())"
                Return "0"
                Break
            }
            
            Write-Log -Type INFO -Category 'Program run' -Name "Convert JSON" -Message "End convert data from plaintxt to Json format" -NotDisplay
            
            If ($Global:Json.exception.domain -and ($Global:Json.exception.domain -ne "v1/device/log")) {
                
                Write-Log -Type INFO -Category 'Program run' -Name "Get API Error Code" -Message "Start get API error code" -NotDisplay
                Write-Log -Type INFONO -Category 'Program run' -Name "Get API Error Code" -Message "API Error Code : "
                
                Try {
                    $ErrorCode = Get-BBOXErrorCode -Json $Global:Json
                    Write-Log -Type ERROR -Category 'Program run' -Name "Get API Error Code" -Message "$($ErrorCode.Code) - $($ErrorCode.Domain) - $($ErrorCode.Name) - $($ErrorCode.ErrorReason)"
                    Return $ErrorCode.String()
                    Break
                }
                Catch {
                    Write-Log -Type ERROR -Category 'Program run' -Name "Get API Error Code" -Message $Global:Json -NotDisplay
                    Write-Log -Type ERROR -Category 'Program run' -Name "Get API Error Code" -Message "Failed - Due to : $($_.ToString())"
                    Return $null
                }
                
                Write-Log -Type INFO -Category 'Program run' -Name "Get API Error Code" -Message "End get API Error Code" -NotDisplay
            }
            Else {
                Return $Global:Json
            }
        }
    }
    Else {
        Write-Log -Type VALUE -Category 'Program run' -Name 'Get Information' -Message "Data already loaded in cache" -NotDisplay
        $global:PreviousUrlToGo = $UrlToGo
        Return $Global:Json
    }
}

# Used only to get information from API page content for FREEBOX
Function Get-FREEBOXInformation {
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    Write-Log -Type INFO -Category 'Program run' -Name "Get Information" -Message "Start retrieving informations requested" -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name "Get Information" -Message "Get informations requested from url : $UrlToGo" -NotDisplay
    Try {
        # Go to the web page to get information we need
        $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
        Write-Log -Type INFO -Category 'Program run' -Name "Get Information" -Message "Successsful" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program run' -Name "Get Information" -Message "Failed - Due to : $($_.ToString())"
        Write-Host "Please check your local/internet network connection" -ForegroundColor Yellow
        Return "0"
        Break
    }
    Write-Log -Type INFO -Category 'Program run' -Name "Get Information" -Message "End retrieving informations requested" -NotDisplay

    Write-Log -Type INFO -Category 'Program run' -Name 'Convert HTML' -Message "Start converting data from Html to plaintxt format" -NotDisplay
    Write-Log -Type INFONO -Category 'Program run' -Name 'Convert HTML' -Message "HTML Conversion status : " -NotDisplay
    Try {
        # Get Web page Content
        $Html = $global:ChromeDriver.PageSource
        
        # Convert $Html To Text
        $Plaintxt = ConvertFrom-HtmlToText -Html $Html
        
        Write-Log -Type VALUE -Category 'Program run' -Name 'Convert HTML' -Message "Successful" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program run' -Name 'Convert HTML' -Message "Failed to convert to HTML, due to : $($_.ToString())"
        Write-Log -Type INFO -Category 'Program run' -Name 'Convert HTML' -Message "End converting data from Html to plaintxt format" -NotDisplay
        Return "0"
        Break
    }
    Write-Log -Type INFO -Category 'Program run' -Name 'Convert HTML' -Message "End converting data from Html to plaintxt format" -NotDisplay
        
    Write-Log -Type INFO -Category 'Program run' -Name "Convert JSON" -Message "Start convert data from plaintxt to Json format" -NotDisplay
    Write-Log -Type INFONO -Category 'Program run' -Name "Convert JSON" -Message "JSON Conversion status : " -NotDisplay
    Try {
        # Convert $Plaintxt as JSON to array
        $Json = $Plaintxt | ConvertFrom-Json
        Write-Log -Type VALUE -Category 'Program run' -Name "Convert JSON" -Message "Successful" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program run' -Name "Convert JSON" -Message "Failed - Due to : $($_.ToString())"
        Return "0"
    }
    Write-Log -Type INFO -Category 'Program run' -Name "Convert JSON" -Message "End converting data from plaintxt to Json format" -NotDisplay
    
    If ($Json.success -eq 'false') {
        
        Write-Log -Type INFO -Category 'Program run' -Name "Get API Error Code" -Message "Start getting API error code" -NotDisplay
        Write-Log -Type INFONO -Category 'Program run' -Name "Get API Error Code" -Message "API error code : "
        Try {
            $ErrorCode = Get-FREEBOXErrorCode -Json $Json -ErrorAction Stop
            Write-Log -Type ERROR -Category 'Program run' -Name "Get API Error Code" -Message "$ErrorCode"
            Return $ErrorCode
        }
        Catch {
            Write-Log -Type ERROR -Category 'Program run' -Name "Get API Error Code" -Message "Failed - Due to : $($_.ToString())"
        }

        Write-Log -Type INFO -Category 'Program run' -Name "Get API Error Code" -Message "End getting API error code" -NotDisplay
    }
    Else {
        Return $Json
    }
}

# Used only to convert HTML page to TXT
Function ConvertFrom-HtmlToText {

<#
.SYNOPSIS
    Convert HTML page to TXT

.DESCRIPTION
    Convert HTML page to TXT

.PARAMETER $Html
    This is the HTML code content from the Web API content

.EXAMPLE
    ConvertFrom-HtmlToText -Html $Html

.INPUTS
    $Html

.OUTPUTS
    $Html

.NOTES
    Author : Winston - 2010/09/21
    Function get from internet : http://winstonfassett.com/blog/2010/09/21/html-to-text-conversion-in-powershell/
    Linked to function(s): 'Get-BBOXInformation', 'Update-ChromeDriver'

#>
    
    Param (
        [Parameter(Mandatory=$True)]
        [System.String]$Html
    )
    
    # remove line breaks, replace with spaces
    $Html = $Html -replace "(`r|`n|`t)", ' '
    # write-verbose "removed line breaks: `n`n$Html`n"
    
    # remove invisible content
    @('head', 'style', 'script', 'object', 'embed', 'applet', 'noframes', 'noscript', 'noembed') | Foreach-object {
    $Html = $Html -replace "<$_[^>]*?>.*?</$_>", ''
    }
    # write-verbose "removed invisible blocks: `n`n$Html`n"
    
    # Condense extra whitespace
    $Html = $Html -replace "( )+", ' '
    # write-verbose "condensed whitespace: `n`n$Html`n"
    
    # Add line breaks
    @('div','p','blockquote','h[1-9]') | Foreach-object { $Html = $Html -replace "</?$_[^>]*?>.*?</$_>", ("`n" + '$0' )} 
    # Add line breaks for self-closing tags
    @('div','p','blockquote','h[1-9]','br') | Foreach-object { $Html = $Html -replace "<$_[^>]*?/>", ('$0' + "`n")} 
    # write-verbose "added line breaks: `n`n$Html`n"
    
    #strip tags 
    $Html = $Html -replace "<[^>]*?>", ''
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
    @("&amp;nbsp;", ' '),
    @("&amp;(.{2,6});", '')
    ) | Foreach-object { $Html = $Html -replace $_[0], $_[1] }
    # write-verbose "replaced entities: `n`n$Html`n"
    
    Return $Html
}

# Used only to Set value(s) to JSON File
Function Set-ValueToJSONFile {

<#
.SYNOPSIS
    To set value(s) to JSON File

.DESCRIPTION
    To set value(s) to JSON File

.PARAMETER JSONFileContent
    This is settings to be set to the JSON file

.PARAMETER JSONFileContentPath
    This is JSON file path where Settings will be saved

.EXAMPLE
    Set-ValueToJSONFile JSONFileContent @{} -JSONFileContentPath "C:\Temp\File.json"

.INPUTS
    $JSONFileContent
    $JSONFileContentPath

.OUTPUTS
    Settings saved to JSON file
    Write in logs files

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Get-HostStatus', 'Get-PortStatus', 'Switch-DisplayFormat', 'Switch-OpenExportFolder', 'Switch-OpenHTMLReport', 'Export-HTMLReport', 'Switch-ExportFormat', 'Set-TriggerOpenExportFolder', 'Export-GlobalOutputData'
    Linked to script(s) : .\BBox-Administration.ps1

#>
    
    Param (
        [Parameter(Mandatory=$True)]
        [Array]$JSONFileContent,
        
        [Parameter(Mandatory=$True)]
        [String]$JSONFileContentPath
    )
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Save Settings to JSON File' -Message "Start Save Settings to JSON File" -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name 'Save Settings to JSON File' -Message "Try to save settings to JSON File : $JSONFileContentPath" -NotDisplay
    Write-Log -Type INFONO -Category 'Program run' -Name 'Save Settings to JSON File' -Message "Save Settings to JSON File Status : " -NotDisplay
    Try {
        $JSONFileContent | ConvertTo-Json -ErrorAction Continue | Out-File -FilePath $JSONFileContentPath -Encoding unicode -Force -ErrorAction Continue
        Write-Log -Type VALUE -Category 'Program run' -Name 'Save Settings to JSON File' -Message "Successful" -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Category 'Program run' -Name 'Save Settings to JSON File' -Message "Failed, due to : $($_.ToString())" -NotDisplay
    }
    Write-Log -Type INFO -Category 'Program run' -Name 'Save Settings to JSON File' -Message "End Save Settings to JSON File" -NotDisplay
}

# Used only to select function to get data from Box web API or do actions
Function Switch-Info {

<#
.SYNOPSIS
    To select function to get data from Box web API or do actions

.DESCRIPTION
    To select function to get data from Box web API or do actions

.PARAMETER 
    

.EXAMPLE
    Switch-Info -Label "Get-BBOXDEVICEFLOG" -UrlToGo "https://mabbox.bytel.fr/api/v1/device/log" -APIName "device/log" -Mail "Tom78_91_45@yahoo.fr" -JournalPath "C:\Journal" -GitHubUrlSite "https://github.com/Zardrilokis/BBOX-Administration-Powershell"
    Switch-Info -Label "Get-BBOXDEVICEFLOG" -UrlToGo "https://exemple.com:8560/api/v1/device/log" -APIName "device/log" -Mail "Tom78_91_45@yahoo.fr" -JournalPath "C:\Journal" -GitHubUrlSite "https://github.com/Zardrilokis/BBOX-Administration-Powershell"
    Switch-Info -Label "Get-BBOXDEVICEFLOG" -UrlToGo "https://exemple.com:80/api/v1/device/log" -APIName "device/log" -Mail "Tom78_91_45@yahoo.fr" -JournalPath "C:\Journal" -GitHubUrlSite "https://github.com/Zardrilokis/BBOX-Administration-Powershell"

.INPUTS
    $Label
    $UrlToGo
    $APIName
    $Mail
    $JournalPath
    $GitHubUrlSite

.OUTPUTS
    $FormatedData

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Export-BoxConfigTestingProgram', ''
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$Label,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$Mail,
        
        [Parameter(Mandatory=$True)]
        [String]$JournalPath,
        
        [Parameter(Mandatory=$True)]
        [String]$GitHubUrlSite
    )
    
        Switch ($Label) {
            
            # Error Code 
            Get-BBOXErrorCode        {$FormatedData = Get-BBOXErrorCode -UrlToGo $UrlToGo;Break}
            
            Get-BBOXErrorCodeTest    {$FormatedData = Get-BBOXErrorCodeTest -UrlToGo $UrlToGo;Break}
            
            # API Version 
            Get-FREEBOXAPIVersion    {$FormatedData = Get-FREEBOXAPIVersion -UrlToGo $UrlToGo;Break}
            
            # Contact 
            Get-FREEBOXContact       {$FormatedData = Get-FREEBOXContact -UrlToGo $UrlToGo;Break}
            
            # Call Log
            Get-FREEBOXCalllog       {$FormatedData = Get-FREEBOXCalllog -UrlToGo $UrlToGo;Break}
            
            # Call Log Summary
            Get-FREEBOXCalllogS      {$FormatedData = Get-FREEBOXCalllogSummary -UrlToGo $UrlToGo;Break}
            
            # Airties
            Get-BBOXAirties          {$FormatedData = Get-BBOXAirties -UrlToGo $UrlToGo;Break}
            
            Get-BBOXAirtiesL         {$FormatedData = Get-BBOXAirtiesLANmode -UrlToGo $UrlToGo;Break}
            
            # Backup
            Get-BBOXCONFIGSL         {$FormatedData = Get-BBOXBackupList -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            # DHCP
            Get-BBOXDHCP             {$FormatedData = Get-BBOXDHCP -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXDHCPC            {$FormatedData = Get-BBOXDHCPClients -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDHCPCID          {$FormatedData = Get-BBOXDHCPClientsID -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDHCPAO           {$FormatedData = Get-BBOXDHCPActiveOptions -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDHCPO            {$FormatedData = Get-BBOXDHCPOptions -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDHCPOID          {$FormatedData = Get-BBOXDHCPOptionsID -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDHCPSTBO         {$FormatedData = Get-BBOXDHCPSTBOptions -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDHCPv6PFD        {$FormatedData = Get-BBOXDHCPv6PrefixDelegation -UrlToGo $UrlToGo;Break}

            Get-BBOXDHCPv6O          {$FormatedData = Get-BBOXDHCPv6Options -UrlToGo $UrlToGo;Break}
            
            # DNS
            Get-BBOXDNSS             {$FormatedData = Get-BBOXDNSStats -UrlToGo $UrlToGo;Break}
            
            # DEVICE
            Get-BBOXDEVICE           {$FormatedData = Get-BBOXDevice -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXDEVICELOG        {$FormatedData = Get-BBOXDeviceLog -UrlToGo $UrlToGo;Break}

            Get-BBOXDEVICEFLOG       {$FormatedData = Get-BBOXDeviceFullLog -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDEVICEFTLOG      {$FormatedData = Get-BBOXDeviceFullTechnicalLog -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDEVICECHLOG      {$FormatedData = Get-BBOXDeviceConnectionHistoryLog -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDEVICECHLOGID    {$FormatedData = Get-BBOXDeviceConnectionHistoryLogID -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDEVICEC          {$FormatedData = Get-BBOXDeviceCpu -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDEVICEM          {$FormatedData = Get-BBOXDeviceMemory -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDEVICELED        {$FormatedData = Get-BBOXDeviceLED -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDEVICES          {$FormatedData = Get-BBOXDeviceSummary -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDEVICET          {$FormatedData = Get-BBOXDeviceToken -UrlToGo $UrlToGo;Break}
            
            Set-BBOXDEVICER          {Set-BBOXDeviceReboot -UrlToGo $UrlToGo;Break}
            
            Set-BBOXDEVICEFR         {Set-BBOXDeviceResetFactory -UrlToGo $UrlToGo;Break}
            
            # DYNDNS
            Get-BBOXDYNDNS           {$FormatedData = Get-BBOXDYNDNS -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXDYNDNSPL         {$FormatedData = Get-BBOXDYNDNSProviderList -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXDYNDNSC          {$FormatedData = Get-BBOXDYNDNSClient -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXDYNDNSCID        {$FormatedData = Get-BBOXDYNDNSClientID -UrlToGo $UrlToGo;Break}

            # FIREWALL
            Get-BBOXFIREWALL         {$FormatedData = Get-BBOXFIREWALL -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXFIREWALLR        {$FormatedData = Get-BBOXFIREWALLRules -UrlToGo $UrlToGo;Break}
            
            Get-BBOXFIREWALLRID      {$FormatedData = Get-BBOXFIREWALLRulesID -UrlToGo $UrlToGo;Break}
            
            Get-BBOXFIREWALLGM       {$FormatedData = Get-BBOXFIREWALLGamerMode -UrlToGo $UrlToGo;Break}
            
            Get-BBOXFIREWALLPR       {$FormatedData = Get-BBOXFIREWALLPingResponder -UrlToGo $UrlToGo;Break}
            
            Get-BBOXFIREWALLv6R      {$FormatedData = Get-BBOXFIREWALLv6Rules -UrlToGo $UrlToGo;Break}
            
            Get-BBOXFIREWALLv6RID    {$FormatedData = Get-BBOXFIREWALLv6RulesID -UrlToGo $UrlToGo;Break}
            
            Get-BBOXFIREWALLv6L      {$FormatedData = Get-BBOXFIREWALLv6Level -UrlToGo $UrlToGo;Break}
            
            # API
            Get-BBOXAPIRM            {$FormatedData = Get-BBOXAPIRessourcesMap -UrlToGo $UrlToGo;Break}
            
            # HOST
            Get-BBOXHOSTSDTH         {$FormatedData = Get-BBOXHOSTSDownloadThreshold -UrlToGo $UrlToGo;Break}
            
            Get-BBOXHOSTS            {$FormatedData = Get-BBOXHOSTS -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXHOSTSID          {$FormatedData = Get-BBOXHOSTSID -UrlToGo $UrlToGo;Break}
            
            Get-BBOXHOSTSW           {$FormatedData = Get-BBOXHOSTSWireless -UrlToGo $UrlToGo;Break}
            
            Get-BBOXHOSTSME          {$FormatedData = Get-BBOXHOSTSME -UrlToGo $UrlToGo;Break}
            
            Get-BBOXHOSTSL           {$FormatedData = Get-BBOXHOSTSLite -UrlToGo $UrlToGo;Break}
            
            Get-BBOXHOSTSP           {$FormatedData = Get-BBOXHOSTSPAUTH -UrlToGo $UrlToGo;Break}
            
            # LAN
            Get-BBOXLANIPC           {$FormatedData = Get-BBOXLANIPConfig -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXLANIPSC          {$FormatedData = Get-BBOXLANIPSwitchConfig -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXLANS             {$FormatedData = Get-BBOXLANStats -UrlToGo $UrlToGo;Break}
            
            Get-BBOXLANPS            {$FormatedData = Get-BBOXLANPortStats -UrlToGo $UrlToGo;Break}
            
            Get-BBOXLANA             {$FormatedData = Get-BBOXLANAlerts -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            # NAT
            Get-BBOXNAT              {$FormatedData = Get-BBOXNAT -UrlToGo $UrlToGo;Break}
            
            Get-BBOXNATDMZ           {$FormatedData = Get-BBOXNATDMZ -UrlToGo $UrlToGo;Break}
            
            Get-BBOXNATR             {$FormatedData = Get-BBOXNATRules -UrlToGo $UrlToGo;Break}
            
            Get-BBOXNATRID           {$FormatedData = Get-BBOXNATRulesID -UrlToGo $UrlToGo;Break}
            
            # Parental Control
            Get-BBOXPARENTALCONTROL  {$FormatedData = Get-BBOXParentalControl -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXPARENTALCONTROLS {$FormatedData = Get-BBOXParentalControlScheduler -UrlToGo $UrlToGo;Break}
            
            Get-BBOXPARENTALCONTROLSR{$FormatedData = Get-BBOXParentalControlSchedulerRules -UrlToGo $UrlToGo;Break}
            
            # PROFILE
            Get-BBOXPROFILEC         {$FormatedData = Get-BBOXProfileConsumption -UrlToGo $UrlToGo;Break}
            
            # REMOTE
            Get-BBOXREMOTEPWOL       {$FormatedData = Get-BBOXREMOTEProxyWOL -UrlToGo $UrlToGo;Break}
            
            # SERVICES
            Get-BBOXSERVICES         {$FormatedData = Get-BBOXSERVICES -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            # IP TV
            Get-BBOXIPTV             {$FormatedData = Get-BBOXIPTV -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXIPTVD            {$FormatedData = Get-BBOXIPTVDiags -UrlToGo $UrlToGo;Break}
            
            # NOTIFICATION
            Get-BBOXNOTIFICATION     {$FormatedData = Get-BBOXNOTIFICATIONConfig -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXNOTIFICATIONCA   {$FormatedData = Get-BBOXNOTIFICATIONAlerts -UrlToGo $UrlToGo;Break}
            
            Get-BBOXNOTIFICATIONCC   {$FormatedData = Get-BBOXNOTIFICATIONContacts -UrlToGo $UrlToGo;Break}
            
            Get-BBOXNOTIFICATIONCE   {$FormatedData = Get-BBOXNOTIFICATIONEvents -UrlToGo $UrlToGo;Break}
            
            Get-BBOXNOTIFICATIONA    {$FormatedData = Get-BBOXNOTIFICATIONAlerts -UrlToGo $UrlToGo;Break}
            
            Get-BBOXNOTIFICATIONC    {$FormatedData = Get-BBOXNOTIFICATIONContacts -UrlToGo $UrlToGo;Break}
            
            Get-BBOXNOTIFICATIONE    {$FormatedData = Get-BBOXNOTIFICATIONEvents -UrlToGo $UrlToGo;Break}
            
            # UPNP IGD
            Get-BBOXUPNPIGD          {$FormatedData = Get-BBOXUPNPIGD -UrlToGo $UrlToGo;Break}
            
            Get-BBOXUPNPIGDR         {$FormatedData = Get-BBOXUPNPIGDRules -UrlToGo $UrlToGo;Break}
            
            # USB
            Get-BBOXDEVICEUSBP       {$FormatedData = Get-BBOXDeviceUSBPrinter -UrlToGo $UrlToGo;Break}
            
            Get-BBOXDEVICEUSBD       {$FormatedData = Get-BBOXDeviceUSBDevices -UrlToGo $UrlToGo;Break}
            
            Get-BBOXUSBS             {$FormatedData = Get-BBOXUSBStorage -UrlToGo $UrlToGo;Break}
            
            # VOIP
            Get-BBOXVOIP             {$FormatedData = Get-BBOXVOIP -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXVOIPDC           {$FormatedData = Get-BBOXVOIPDiagConfig -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPDL           {$FormatedData = Get-BBOXVOIPDiagLine -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPDU           {$FormatedData = Get-BBOXVOIPDiagUSB -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPDH           {$FormatedData = Get-BBOXVOIPDiagHost -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPS            {$FormatedData = Get-BBOXVOIPScheduler -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPSR           {$FormatedData = Get-BBOXVOIPSchedulerRules -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPCL           {$FormatedData = Get-BBOXVOIPCallLogLine -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPCLPN         {$FormatedData = Get-BBOXVOIPCallLogLineXPhoneNumber -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPCLS          {$FormatedData = Get-BBOXVOIPCallLogLineXSummary -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPFCL          {$FormatedData = Get-BBOXVOIPFullCallLogLine -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPFCLPN        {$FormatedData = Get-BBOXVOIPFullCallLogLineXPhoneNumber -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPFCLS         {$FormatedData = Get-BBOXVOIPFullCallLogLineXSummary -UrlToGo $UrlToGo;Break}
            
            Get-BBOXVOIPALN          {$FormatedData = Get-BBOXVOIPAllowedListNumber -UrlToGo $UrlToGo;Break}
            
            # CPL
            Get-BBOXCPL              {$FormatedData = Get-BBOXCPL -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXCPLDL            {$FormatedData = Get-BBOXCPLDeviceList -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            # WAN
            Get-BBOXWANAC            {$FormatedData = Get-BBOXWANAutowanConfig -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWANAP            {$FormatedData = Get-BBOXWANAutowanProfiles -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWAND             {$FormatedData = Get-BBOXWANDiags -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWANDS            {$FormatedData = Get-BBOXWANDiagsSessions -UrlToGo $UrlToGo;Break}

            Get-BBOXWANDSHAS         {$FormatedData = Get-BBOXWANDiagsSummaryHostsActiveSessions -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWANDAAS          {$FormatedData = Get-BBOXWANDiagsAllActiveSessions -UrlToGo $UrlToGo;Break}

            Get-BBOXWANDAASH         {$FormatedData = Get-BBOXWANDiagsAllActiveSessionsHost -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWANFS            {$FormatedData = Get-BBOXWANFTTHStats -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWANIP            {$FormatedData = Get-BBOXWANIP -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWANIPS           {$FormatedData = Get-BBOXWANIPStats -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWANXDSL          {$FormatedData = Get-BBOXWANXDSL -UrlToGo $UrlToGo;Break}

            Get-BBOXWANXDSLS         {$FormatedData = Get-BBOXWANXDSLStats -UrlToGo $UrlToGo;Break}

            Get-BBOXWANSFF           {$FormatedData = Get-BBOXWANSFF -UrlToGo $UrlToGo;Break}
            
            # WIRELESS
            Get-BBOXWIRELESS         {$FormatedData = Get-BBOXWIRELESS -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXWIRELESSSTD      {$FormatedData = Get-BBOXWIRELESSSTANDARD -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESS24       {$FormatedData = Get-BBOXWIRELESS24Ghz -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESS24S      {$FormatedData = Get-BBOXWIRELESSStats -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESS5        {$FormatedData = Get-BBOXWIRELESS5Ghz -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESS5S       {$FormatedData = Get-BBOXWIRELESSStats -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESSACL      {$FormatedData = Get-BBOXWIRELESSACL -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESSACLR     {$FormatedData = Get-BBOXWIRELESSACLRules -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESSACLRID   {$FormatedData = Get-BBOXWIRELESSACLRulesID -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESSWPS      {$FormatedData = Get-BBOXWIRELESSWPS -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESSFBNH     {$FormatedData = Get-BBOXWIRELESSFrequencyNeighborhoodScan -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-BBOXWIRELESSFSM      {$FormatedData = Get-BBOXWIRELESSFastScanMe -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESSS        {$FormatedData = Get-BBOXWIRELESSScheduler -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESSSR       {$FormatedData = Get-BBOXWIRELESSSchedulerRules -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESSR        {$FormatedData = Get-BBOXWIRELESSRepeater -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESSVBSTB    {$FormatedData = Get-BBOXWIRELESSVideoBridgeSetTopBoxes -UrlToGo $UrlToGo;Break}
            
            Get-BBOXWIRELESSVBR      {$FormatedData = Get-BBOXWIRELESSVideoBridgeRepeaters -UrlToGo $UrlToGo;Break}
            
            # SUMMARY
            Get-BBOXSUMMARY          {$FormatedData = Get-BBOXSUMMARY -UrlToGo $UrlToGo;Break}
            
            # USERSAVE
            Get-BBOXUSERSAVE         {$FormatedData = Get-BBOXUSERSAVE -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            # Password Recovery Verify
            Get-BBOXPASSRECOVERV     {$FormatedData = Get-BBOXPasswordRecoveryVerify -UrlToGo $UrlToGo;Break}
            
            # BoxJournal
            Get-BBOXBoxJournal       {$FormatedData = Get-BBOXBoxJournal -UrlToGo $UrlToGo -JournalPath $JournalPath;Break}
            
            # BBox Referential Contact
            Show-BBOXRC              {$FormatedData = Show-BBOXReferentialContact;Break}
            
            Add-BBOXNewRC            {$FormatedData = Add-BBOXNewReferentialContact;Break}
            
            Remove-BBOXRC            {$FormatedData = Remove-BBOXReferentialContact;Break}
            
            # Export Program files Number
            Export-PFC           {$FormatedData = Export-ProgramFilesCount -FolderRoot $PSScriptRoot;Break}
            
            # Remove-FolderContent
            Remove-FCAll         {$FormatedData = Remove-FolderContentAll -FolderRoot $PSScriptRoot -FoldersName $APIName;Break}
            
            Remove-FCLogs        {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            Remove-FCExportCSV   {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            Remove-FCExportJSON  {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            Remove-FCJournal     {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            Remove-FCJBC         {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            Remove-FCReport      {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            Remove-FCH           {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            # DisplayFormat
            Switch-DF            {$FormatedData = Switch-DisplayFormat;Break}
            
            # ExportFormat
            Switch-EF            {$FormatedData = Switch-ExportFormat;Break}
            
            # OpenExportFormat
            SWITCH-OEF           {$FormatedData = Switch-OpenExportFolder;Break}
            
            # OpenHTMLReport
            Switch-OHR           {$FormatedData = Switch-OpenHTMLReport;Break}
            
            # Switch Resolved Dns Name
            Switch-RDN           {$FormatedData = Switch-ResolveDnsName;Break}
            
            # Remove Box Windows Password Manager
            Remove-BoxC          {$FormatedData = Remove-BoxCredential;Break}
            
            # Show Box Windows Password Manager
            Get-BoxC             {$FormatedData = Get-BoxCredential;Break}
            
            # Show Box Windows Password Manager
            Show-BoxC            {$FormatedData = Show-BoxCredential;Break}
            
            # Set Box Windows Password Manager
            Add-BoxC             {$FormatedData = Add-BoxCredential;Break}
            
            # Reset-Current User Program Configuration
            Reset-CUPC           {$FormatedData = Reset-CurrentUserProgramConfiguration;Break}
            
            # Export-ModuleHelp
            Export-MH            {$FormatedData = Export-ModuleHelp -ModuleFileName $global:JSONSettingsProgramContent.Path.BoxModuleFileName -ExportFolderPath $global:HelpFolderNamePath;Break}
            
            # Export-Module Function
            Export-MF            {$FormatedData = Export-ModuleFunctions -ModuleFolderPath $PSScriptRoot -ModuleFileName $global:JSONSettingsProgramContent.Path.BoxModuleFileName -FileExtention $global:ValuesPowershellModuleFileExtention -ExportFolderPath $global:HelpFolderNamePath;Break}
            
            Export-MFS           {$FormatedData = Export-ModuleFunctions -ModuleFolderPath $PSScriptRoot -ModuleFileName $global:JSONSettingsProgramContent.Path.BoxModuleFileName -FileExtention $global:ValuesPowershellModuleFileExtention -ExportFolderPath $global:HelpFolderNamePath -SummaryExport;Break}
            
            Export-MFD           {$FormatedData = Export-ModuleFunctions -ModuleFolderPath $PSScriptRoot -ModuleFileName $global:JSONSettingsProgramContent.Path.BoxModuleFileName -FileExtention $global:ValuesPowershellModuleFileExtention -ExportFolderPath $global:HelpFolderNamePath -DetailedExport;Break}
            
            Export-MFF           {$FormatedData = Export-ModuleFunctions -ModuleFolderPath $PSScriptRoot -ModuleFileName $global:JSONSettingsProgramContent.Path.BoxModuleFileName -FileExtention $global:ValuesPowershellModuleFileExtention -ExportFolderPath $global:HelpFolderNamePath -FullDetailedExport;Break}
            
            Export-MFSD          {$FormatedData = Export-ModuleFunctions -ModuleFolderPath $PSScriptRoot -ModuleFileName $global:JSONSettingsProgramContent.Path.BoxModuleFileName -FileExtention $global:ValuesPowershellModuleFileExtention -ExportFolderPath $global:HelpFolderNamePath -SummaryExport -DetailedExport;Break}
            
            Export-MFSF          {$FormatedData = Export-ModuleFunctions -ModuleFolderPath $PSScriptRoot -ModuleFileName $global:JSONSettingsProgramContent.Path.BoxModuleFileName -FileExtention $global:ValuesPowershellModuleFileExtention -ExportFolderPath $global:HelpFolderNamePath -SummaryExport -FullDetailedExport;Break}
            
            Export-MFDF          {$FormatedData = Export-ModuleFunctions -ModuleFolderPath $PSScriptRoot -ModuleFileName $global:JSONSettingsProgramContent.Path.BoxModuleFileName -FileExtention $global:ValuesPowershellModuleFileExtention -ExportFolderPath $global:HelpFolderNamePath -DetailedExport -FullDetailedExport;Break}
            
            Export-MFSDF         {$FormatedData = Export-ModuleFunctions -ModuleFolderPath $PSScriptRoot -ModuleFileName $global:JSONSettingsProgramContent.Path.BoxModuleFileName -FileExtention $global:ValuesPowershellModuleFileExtention -ExportFolderPath $global:HelpFolderNamePath -SummaryExport -DetailedExport -FullDetailedExport;Break}
                        
            # Exit
            Q                    {Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop;Break}
            
            # Quit/Close Program
            Stop-Program         {Stop-Program -Context User -ErrorMessage 'User want to quit the program' -Reason 'User want to quit the program' -ErrorAction Stop;Break}
            
            # Uninstall Program
            Uninstall-Program    {Uninstall-Program -ErrorAction Stop;Break}
            
            # Default
            Default              {Write-log WARNING -Category 'Program run' -Name "Action : $Label not yet developed" -Message "Selected Action is not yet developed, please chose another one, for more information contact me by mail : $Mail or post on github : $GitHubUrlSite"
                                  Show-WindowsFormDialogBox -Title "Program run - Action : $Label not yet developed" -Message "Selected Action is not yet developed, please chose another one, for more information contact me by mail : $Mail or post on github : $GitHubUrlSite" -WarnIcon
                                  $FormatedData = 'Program'
                                  Break
                                 }
        }
    
        Return $FormatedData
}

#endregion Common functions

#region Refresh WIRELESS Frequency Neighborhood Scan

# Used only to Refresh WIRELESS Frequency Neighborhood Scan
function Start-RefreshBBOXWIRELESSFrequencyNeighborhoodScan {

<#
.SYNOPSIS
    To Refresh WIRELESS Frequency Neighborhood Scan

.DESCRIPTION
    To Refresh WIRELESS Frequency Neighborhood Scan

.PARAMETER APIName
    Indicate the API name associated to wireless scan result

.PARAMETER UrlToGo
    Indicate the url to start the wireless scan

.EXAMPLE
    Start-RefreshBBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/24/neighborhood" -UrlToGo "https://mabbox.bytel.fr/api/v1/wireless/24/neighborhood"
    Start-RefreshBBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/5/neighborhood" -UrlToGo "https://mabbox.bytel.fr/api/v1/wireless/5/neighborhood"

    Start-RefreshBBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/24/neighborhood" -UrlToGo "https://exemple.com:8560/api/v1/wireless/24/neighborhood"
    Start-RefreshBBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/5/neighborhood" -UrlToGo "https://exemple.com:8560/api/v1/wireless/5/neighborhood"

    Start-RefreshBBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/24/neighborhood" -UrlToGo "https://exemple.com:80/api/v1/wireless/24/neighborhood"
    Start-RefreshBBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/5/neighborhood" -UrlToGo "https://exemple.com:80/api/v1/wireless/5/neighborhood"

.INPUTS
    $APIName
    $UrlToGo

.OUTPUTS
    Wireless scan neighborhood done

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Format-Date1970', 'Get-BBOXWIRELESSFrequencyNeighborhoodScan'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    Write-Log -Type INFO -Category 'Program run' -Name 'WIRELESS Frequency Neighborhood scan' -Message 'Start WIRELESS Frequency Neighborhood scan' -NotDisplay
    
    # Get information from Box API and last scan date
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    $Lastscan = $Json.lastscan
    
    Write-Log -Type INFONO -Category 'Program run' -Name 'WIRELESS Frequency Neighborhood scan' -Message 'WIRELESS Frequency Neighborhood Lastscan : ' -NotDisplay
    
    If ($Lastscan -eq 0) {
        
        Write-Log -Type VALUE -Category 'Program run' -Name 'WIRELESS Frequency Neighborhood scan' -Message 'Never' -NotDisplay
    }
    Else {
        Write-Log -Type VALUE -Category 'Program run' -Name 'WIRELESS Frequency Neighborhood scan' -Message $(Format-Date1970 -Seconds $Lastscan) -NotDisplay
    }
    
    $global:ChromeDriver.Navigate().GoToURL($($UrlToGo.replace("$global:APIVersion/$APIName",'diagnostic.html')))
    Start-Sleep -Seconds $global:SleepDefault
    
    Switch ($APIName) {
        
        wireless/24/neighborhood {($global:ChromeDriver.FindElementsByClassName('scan24') | Where-Object -Property text -eq 'Scanner').click();Break}
            
        wireless/5/neighborhood  {($global:ChromeDriver.FindElementsByClassName('scan5') | Where-Object -Property text -eq 'Scanner').click();Break}
    }
    
    If ($global:TriggerExportConfig -eq $false) {
        
        Write-Log -Type WARNING -Category 'Program run' -Name 'WIRELESS Frequency Neighborhood scan' -Message 'Be careful, the scan can temporary suspend your Wi-Fi network'
        Write-Log -Type WARNING -Category 'Program run' -Name 'WIRELESS Frequency Neighborhood scan' -Message 'Do you want to continue ? : ' -NotDisplay
        
        While ($ActionState -notmatch "Y|N") {
                
            #$ActionState = Read-Host "Do you want to continue ? (Y) Yes / (N) No"
            $ActionState = Show-WindowsFormDialogBox -Title 'Program run - WIRELESS Frequency Neighborhood scan' -Message 'Do you want to continue ? (Y) Yes / (N) No' -YesNo
            Write-Log -Type INFO -Category 'Program run' -Name 'WIRELESS Frequency Neighborhood scan' -Message "Action chosen by user : $ActionState" -NotDisplay
        }
    }
    Else {
        $ActionState = 'Y'
    }

    If ($ActionState[0] -eq 'Y') {
        
        # addd
        Try {
            ($global:ChromeDriver.FindElementsByClassName('cta-1') | Where-Object -Property text -eq 'Rafraîchir').click()
            Start-Sleep -Seconds $global:SleepDefault
            ($global:ChromeDriver.FindElementsByClassName('cta-2') | Where-Object -Property text -eq 'OK').click()
        }
        Catch {
            ($global:ChromeDriver.FindElementsByClassName("cta-2") | Where-Object -Property text -eq 'OK').click()
        }
        
        Write-Log -Type INFONO -Category 'Program run' -Name 'WIRELESS Frequency Neighborhood scan' -Message 'Refresh WIRELESS Frequency Neighborhood scan : ' -NotDisplay
        Start-Sleep -Seconds $global:SleepRefreshWIRELESSFrequencyNeighborhoodScan
        Write-Log -Type VALUE -Category 'Program run' -Name 'WIRELESS Frequency Neighborhood scan' -Message 'Ended' -NotDisplay
    }
    Write-Log -Type INFO -Category 'Program run' -Name 'WIRELESS Frequency Neighborhood scan' -Message 'End WIRELESS Frequency Neighborhood scan' -NotDisplay
}

# Used only to Refresh WIRELESS Frequency Neighborhood Scan ID
Function Get-BBOXWIRELESSFrequencyNeighborhoodScan {

<#
.SYNOPSIS
    To Refresh WIRELESS Frequency Neighborhood Scan ID

.DESCRIPTION
    To Refresh WIRELESS Frequency Neighborhood Scan ID

.PARAMETER APIName
    Indicate the API name associated to wireless scan result

.PARAMETER UrlToGo
    Indicate the url to start the wireless scan

.EXAMPLE
    Get-BBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/24/neighborhood" -UrlToGo "https://mabbox.bytel.fr/api/v1/wireless/24/neighborhood"
    Get-BBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/5/neighborhood" -UrlToGo "https://mabbox.bytel.fr/api/v1/wireless/5/neighborhood"

    Get-BBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/24/neighborhood" -UrlToGo "https://exemple.com:8560/api/v1/wireless/24/neighborhood"
    Get-BBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/5/neighborhood" -UrlToGo "https://exemple.com:8560/api/v1/wireless/5/neighborhood"

    Get-BBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/24/neighborhood" -UrlToGo "https://exemple.com:80/api/v1/wireless/24/neighborhood"
    Get-BBOXWIRELESSFrequencyNeighborhoodScan -APIName "wireless/5/neighborhood" -UrlToGo "https://exemple.com:80/api/v1/wireless/5/neighborhood"

.INPUTS
    $APIName
    $UrlToGo

.OUTPUTS
    $FormatedData

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Start-RefreshBBOXWIRELESSFrequencyNeighborhoodScan', 'Get-BBOXWIRELESSFrequencyNeighborhoodScanID'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    Start-RefreshBBOXWIRELESSFrequencyNeighborhoodScan -APIName $APIName -UrlToGo $UrlToGo
    $FormatedData = @()
    $FormatedData = Get-BBOXWIRELESSFrequencyNeighborhoodScanID -UrlToGo $UrlToGo
    
    Return $FormatedData
}

#endregion Refresh WIRELESS Frequency Neighborhood Scan

#region Manage Output Display after data export

#region Switch

# Used only to change Display Format
Function Switch-DisplayFormat {

<#
.SYNOPSIS
    To change Display Format

.DESCRIPTION
    To change Display Format

.PARAMETER 
    Switch-DisplayFormat

.EXAMPLE
    

.INPUTS
    User choice

.OUTPUTS
    HTML or Table format

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Export-GlobalOutputData', 'Show-WindowsFormDialogBox2Choices', 'Switch-Info', 'Set-ValueToJSONFile'

#>

    Param(  )
    
    # Choose Display Format : HTML or Table
    Write-Log -Type INFO -Category 'Program run' -Name 'Choose Display Format' -Message 'Start data display format' -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name 'Choose Display Format' -Message "Please choose a display format (Can be changed later) : (H) HTML or (T) Table/Gridview" -NotDisplay
    $global:DisplayFormat = ''
    
    While ($global:DisplayFormat[0] -notmatch $global:ValuesDisplayFormat) {
        
        #$Temp = Read-Host "Enter your choice"
        $Temp = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Choose Display Format' -LabelMessageText "Please choose a display format (Can be changed later) :`n- (H) HTML`n- (T) Table/Gridview" -FirstOptionButtonText 'H' -SecondOptionButtonText 'T'
        
        Switch ($Temp) {
                
            H    {$global:DisplayFormat = 'H';Break}
            T    {$global:DisplayFormat = 'T';Break}
        }
    }
    
    Write-Log -Type VALUE -Category 'Program run' -Name 'Choose Display Format' -Message "Value Choosen : $global:DisplayFormat" -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name 'Choose Display Format' -Message 'End data display format' -NotDisplay
    
    $global:JSONSettingsCurrentUserContent.DisplayFormat.DisplayFormat = $global:DisplayFormat
    Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath
}

# Used only to change Open Export Folder
Function Switch-OpenExportFolder {

<#
.SYNOPSIS
    To change Open Export Folder

.DESCRIPTION
    To change Open Export Folder

.PARAMETER 
    

.EXAMPLE
    Switch-OpenExportFolder

.INPUTS
    User choice

.OUTPUTS
    Open or not export folder

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Show-WindowsFormDialogBox2Choices', 'Switch-Info', 'Export-toCSV', "'xport-toJSON', "Export-BoxConfiguration', 'Export-BoxConfigTestingProgram', 'Export-GlobalOutputData', 'Set-ValueToJSONFile'

#>

    Param ()
    
    # Choose Open Export Folder : Y (Yes) or N (No)
    Write-Log -Type INFO -Category 'Program run' -Name 'Choose Open Export Folder' -Message 'Start switch Open Export Folder' -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name 'Choose Open Export Folder' -Message "Please choose if you want to open 'Export' folder at each export (Can be changed later) : Y (Yes) or N (No)" -NotDisplay
    $global:OpenExportFolder = ""
    
    While ($global:OpenExportFolder[0] -notmatch $global:ValuesOpenExportFolder) {
            
        #$Temp = Read-Host "Enter your choice"
        $Temp = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Choose Open Export Folder' -LabelMessageText "Please choose if you want to open 'Export' folder (Can be changed later) :`n- (Y) Yes`n- (N) No" -FirstOptionButtonText 'Y' -SecondOptionButtonText 'N'
        
        Switch ($Temp) {
                
            Y    {$global:OpenExportFolder = 'Y';Break}
            N    {$global:OpenExportFolder = 'N';Break}
        }
    }
    
    Write-Log -Type VALUE -Category 'Program run' -Name 'Choose Open Export Folder' -Message "Value Choosen : $global:OpenExportFolder" -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name 'Choose Open Export Folder' -Message 'End switch Open Export Folder' -NotDisplay
    
    $global:JSONSettingsCurrentUserContent.OpenExportFolder.OpenExportFolder = $global:OpenExportFolder
    Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath
}

# Used only to open or not HTML Report
Function Switch-OpenHTMLReport {

<#
.SYNOPSIS
    To open or not HTML Report

.DESCRIPTION
    To open or not HTML Report

.PARAMETER 
    

.EXAMPLE
    Switch-OpenHTMLReport

.INPUTS
    User choice

.OUTPUTS
    HTML report will be open or not

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Export-HTMLReport', 'Open-HTMLReport', 'Switch-info', 'Set-ValueToJSONFile'

#>

    Write-Log -Type INFO -Category 'Program run' -Name 'Switch Open HTML Report' -Message 'Start Switch Open HTML Report' -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name 'Switch Open HTML Report' -Message 'Do you want to open HTML Report at each time ? : (Y) Yes or (N) No' -NotDisplay
    $global:OpenHTMLReport = ''
    
    While ($global:OpenHTMLReport[0] -notmatch $global:ValuesOpenHTMLReport) {
        
        $Temp = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Switch Open HTML Report' -LabelMessageText "Do you want to open HTML Report at each time ? :`n- (Y) Yes`n- (N) No" -FirstOptionButtonText 'Y' -SecondOptionButtonText 'N'        
        
        Switch ($Temp) {
                
            Y    {$global:OpenHTMLReport = 'Y';Break}
            N    {$global:OpenHTMLReport = 'N';Break}
        }
    }
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Switch Open HTML Report' -Message "Value Choosen : $global:OpenHTMLReport" -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name 'Switch Open HTML Report' -Message 'End Switch Open HTML Report' -NotDisplay
    
    $global:JSONSettingsCurrentUserContent.OpenHTMLReport.OpenHTMLReport = $global:OpenHTMLReport
    Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath
}

# Used only to change Display Format
Function Switch-ResolveDnsName {

    <#
    .SYNOPSIS
        To allow or not to Resolve Dns Name from an IP Address
    
    .DESCRIPTION
        To allow or not to Resolve Dns Name from an IP Address
    
    .PARAMETER 
        user answer/Action
    
    .EXAMPLE
        Switch-ResolveDnsName
    
    .INPUTS
        User choice
    
    .OUTPUTS
        Enable to resolve an IP address to a hostname
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to function(s): ''
    
    #>
    
        Param(  )
        
        # Switch Resolve Dns Name : Yes or No
        Write-Log -Type INFO -Category 'Program run' -Name 'Switch Resolve Dns Name' -Message 'Start Switch Resolve Dns Name' -NotDisplay
        Write-Log -Type INFO -Category 'Program run' -Name 'Switch Resolve Dns Name' -Message "Please choose if you want to resolve IP Address to DNS Hostname (Can be changed later) : (Y) Yes or (N) No" -NotDisplay
        $global:ResolveDnsName = ''
        
        While ($global:ResolveDnsName[0] -notmatch $global:ValuesResolveDnsName) {
            
            #$Temp = Read-Host "Enter your choice"
            $Temp = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Switch Resolve Dns Name' -LabelMessageText "Please choose if you want to resolve IP Address to DNS Hostname or not (Can be changed later) :`n- (Y) Yes`n- (N) No" -FirstOptionButtonText 'Y' -SecondOptionButtonText 'N'
            
            Switch ($Temp) {
                    
                Y    {$global:ResolveDnsName = 'Y';Break}
                N    {$global:ResolveDnsName = 'N';Break}
            }
        }
        
        Write-Log -Type VALUE -Category 'Program run' -Name 'Switch Resolve Dns Name' -Message "Value Choosen : $global:ResolveDnsName" -NotDisplay
        Write-Log -Type INFO -Category 'Program run' -Name 'Switch Resolve Dns Name' -Message 'End Switch Resolve Dns Name' -NotDisplay
        
        $global:JSONSettingsCurrentUserContent.ResolveDnsName.ResolveDnsName = $global:ResolveDnsName
        Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath
}

# Used only to Switch Export Format
Function Switch-ExportFormat {

<#
.SYNOPSIS
    To Switch Export Format

.DESCRIPTION
    To Switch Export Format

.PARAMETER 
    

.EXAMPLE
    Switch-ExportFormat

.INPUTS
    User Choice

.OUTPUTS
    Export format is define to CSV or JSON

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Switch-Info', 'Export-GlobalOutputData', 'Set-ValueToJSONFile'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    # Choose Export Format : CSV or JSON
    Write-Log -Type INFO -Category 'Program run' -Name 'Choose Export Result' -Message 'Start data export format' -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name 'Choose Export Result' -Message 'Please choose an export format (Can be changed later) : (C) CSV or (J) JSON' -NotDisplay
    $global:ExportFormat = ''
    
    While ($global:ExportFormat[0] -notmatch $global:ValuesExportFormat) {
        
        #$Temp = Read-Host "Enter your choice"
        $Temp = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Choose Export Result' -LabelMessageText "Please choose an export format (Can be changed later) :`n- (C) CSV`n- (J) JSON" -FirstOptionButtonText 'C' -SecondOptionButtonText 'J'
            
        Switch ($Temp) {
            
            C    {$global:ExportFormat = 'C';Break}
            J    {$global:ExportFormat = 'J';Break}
        }
    }
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Choose Export Result' -Message "Value Choosen  : $global:ExportFormat" -NotDisplay
    Write-Log -Type INFO -Category 'Program run' -Name 'Choose Export Result' -Message 'End data export format' -NotDisplay
    
    $global:JSONSettingsCurrentUserContent.ExportFormat.ExportFormat = $global:ExportFormat
    Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath
}

#endregion Switch

#region Format

# Used only to format display result function user choice
Function Format-DisplayResult {

<#
.SYNOPSIS
    To format display result function user choice

.DESCRIPTION
    To format display result function user choice

.PARAMETER FormatedData
    Data were already format and will be displayed

.PARAMETER APIName
    Title report name or Title the Out-GridView Window

.PARAMETER Description
    Description of the report

.PARAMETER ReportType
    Report type can be : Table or List

.PARAMETER ReportPath
    Path of the report folder

.PARAMETER Exportfile
    Full path of export file

.EXAMPLE
    Format-DisplayResult -FormatedData $FormatedData -APIName "device/log" -Description "Device log" -ReportType "Table" -ReportPath "C:\Windows\Report" -Exportfile "C:\Windows\Report\device-log.csv"

.INPUTS
    $FormatedData
    $APIName
    $Description
    $ReportType
    $ReportPath
    $Exportfile

.OUTPUTS
    Result is Displayed in HTML or in table under Out-Gridview

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Export-GlobalOutputData', 'Export-HTMLReport', 'Out-GridviewDisplay', 'Open-HTMLReport'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
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
    
    Switch ($global:DisplayFormat) {
        
        'H' {# Display result by HTML Report
             Export-HTMLReport -DataReported $FormatedData -ReportTitle "$global:BoxType Configuration Report - $APIName" -ReportType $ReportType -ReportPath $ReportPath -ReportFileName $Exportfile -HTMLTitle "$global:BoxType Configuration Report" -ReportPrecontent $APIName -Description $Description
             Break
            }
        
        'T' {# Display result by Out-Gridview
             Out-GridviewDisplay -FormatedData $FormatedData -APIName $APIName -Description $Description
             Break
            }
    }
    Write-Log -Type INFO -Category 'Program run' -Name 'Display Result' -Message 'End display result' -NotDisplay
}

# Used only to format export result function user choice
Function Format-ExportResult {

<#
.SYNOPSIS
    To format export result function user choice

.DESCRIPTION
    To format export result function user choice

.PARAMETER FormatedData
    Data you want to export

.PARAMETER APIName
    API path use to get data to export

.PARAMETER ExportCSVPath
    Path Folder for CSV file

.PARAMETER ExportJSONPath
    Path Folder for JSON file

.PARAMETER Exportfile
    Export file Name

.EXAMPLE
    Format-ExportResult -FormatedData "$FormatedData" -APIName "" -ExportCSVPath "" -ExportJSONPath "" -Exportfile ""

.INPUTS
    $global:ExportFormat
    $FormatedData
    $APIName
    $ExportCSVPath
    $ExportJSONPath
    $Exportfile

.OUTPUTS
    Data exported to CSV or JSON file depending of : $global:ExportFormat value

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Export-GlobalOutputData', 'Export-toCSV', 'Export-toJSON'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$False)]
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
    
    Switch ($global:ExportFormat) {
        
        'C' {# Export result to CSV
                Export-toCSV -FormatedData $FormatedData -APIName $APIName -ExportCSVPath $ExportCSVPath -Exportfile $Exportfile;Break
            }
        'J' {# Export result to JSON
                Export-toJSON -FormatedData $FormatedData -APIName $APIName -ExportJSONPath $ExportJSONPath -Exportfile $Exportfile;Break
            }
    }
}

#endregion Format

#region Export

# Used only to export result to CSV File
Function Export-toCSV {

<#
.SYNOPSIS
    To export result to CSV File

.DESCRIPTION
    To export result to CSV File

.PARAMETER FormatedData
    This is the data you want to export to the csv file

.PARAMETER APIName
    This is the name of the API where data are retrived

.PARAMETER ExportCSVPath
    This is the folder path of the Export CSV folder

.PARAMETER Exportfile
    This is the name of the export CSV File (Include file extention)

.EXAMPLE
    Export-toCSV -FormatedData "$FormatedData" -APIName "Device\log" -ExportCSVPath "C:\ExportFolder" -Exportfile "Device-log.csv"

.INPUTS
    $FormatedData
    $APIName
    $ExportCSVPath
    $Exportfile

.OUTPUTS
    Csv File

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Format-ExportResult'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$ExportCSVPath,
        
        [Parameter(Mandatory=$True)]
        [String]$Exportfile
    )
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Export Result CSV' -Message 'Start export result as CSV' -NotDisplay
    
    Try {
        # Define Export file path
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $DateShort = $(Get-Date -UFormat %Y%m%d)
        Test-FolderPath -FolderRoot "$ExportCSVPath\$global:BoxType" -FolderPath "$ExportCSVPath\$global:BoxType\$DateShort" -FolderName $DateShort
        $ExportPath = "$ExportCSVPath\$global:BoxType\$DateShort\$Date-$Exportfile.csv"
        $FormatedData | Export-Csv -Path $ExportPath -Encoding unicode -Delimiter ";" -NoTypeInformation -Force        
        Write-Log -Type INFONO -Category 'Program run' -Name 'Export Result CSV' -Message 'CSV Data have been exported to : ' -NotDisplay
        Write-Log -Type VALUE -Category 'Program run' -Name 'Export Result CSV' -Message $ExportPath -NotDisplay
        
        Open-ExportFolder -WriteLogName 'Program run - Export Result CSV' -ExportFolderPath $ExportCSVPath
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program run' -Name 'Export Result CSV' -Message "Failed, to export data to : `"$ExportPath`", due to : $($_.ToString())"
    }
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Export Result CSV' -Message 'End export result as CSV' -NotDisplay
}

# Used only to export result to JSON File
Function Export-toJSON {

<#
.SYNOPSIS
    To export result to JSON File

.DESCRIPTION
    To export result to JSON File

.PARAMETER FormatedData
    This is the data you want to export to the JSON file

.PARAMETER APIName
    This is the name of the API where data are retrived

.PARAMETER ExportJSONPath
    This is the folder path of the Export JSON folder

.PARAMETER Exportfile
    This is the name of the export JSON File (Include file extention)

.EXAMPLE
    Export-toJSON -FormatedData "$FormatedData" -APIName "Device\log" -ExportJSONPath "C:\ExportFolder" -Exportfile "Device-log.json"

.INPUTS
    $FormatedData
    $APIName
    $ExportJSONPath
    $Exportfile

.OUTPUTS
    JSON File

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Format-ExportResult'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$ExportJSONPath,
        
        [Parameter(Mandatory=$True)]
        [String]$Exportfile
    )
    
     Write-Log -Type INFO -Category 'Program run' -Name 'Export Result JSON' -Message 'Start export result as JSON' -NotDisplay
     
     Try {
        # Define Export file path
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $DateShort = $(Get-Date -UFormat %Y%m%d)
        Test-FolderPath -FolderRoot "$ExportJSONPath\$global:BoxType" -FolderPath "$ExportJSONPath\$global:BoxType\$DateShort" -FolderName $DateShort
        $FullPath = "$ExportJSONPath\$global:BoxType\$DateShort\$Date-$Exportfile.json"
        $FormatedData | ConvertTo-Json -depth 10 | Out-File -FilePath $FullPath -Force
        Write-Log -Type INFONO -Category 'Program run' -Name 'Export Result JSON' -Message 'JSON Data have been exported to : ' -NotDisplay
        Write-Log -Type VALUE -Category 'Program run' -Name 'Export Result JSON' -Message $FullPath -NotDisplay
        
        Open-ExportFolder -WriteLogName 'Program run - Export Result JSON' -ExportFolderPath $ExportJSONPath
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program run' -Name 'Export Result JSON' -Message "Failed to export data to : `"$FullPath`", due to : $($_.ToString())"
    }
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Export Result JSON' -Message 'End export result as JSON' -NotDisplay
}

# Used only to create HTML Report
Function Export-HTMLReport {

<#
.SYNOPSIS
    To create HTML Report

.DESCRIPTION
    To create HTML Report

.PARAMETER DataReported
    This is the array data that display in the body html report

.PARAMETER ReportType
    This is the type of the report that are available
    Validated values :
    - Table
    - List

.PARAMETER ReportTitle
    This is the Main Title of the report in the tab in the web browser

.PARAMETER ReportPath
    This is the folder path where HTML report are saved

.PARAMETER ReportFileName
    This is the name of the HTLM report file

.PARAMETER HTMLTitle
    This is the Main Title of the report

.PARAMETER ReportPrecontent
    This is the short description of the report

.PARAMETER Description
    This is the description of the report

.EXAMPLE
    Export-HTMLReport -DataReported "$DataReported" -ReportType "List" -ReportTitle "Report of data" -ReportPath "C:\Report" -ReportFileName "Report.html" -HTMLTitle "Main Data Reporting" -ReportPrecontent "Subtitle / Subcategory" -Description "This is the main data to report"
    Export-HTMLReport -DataReported "$DataReported" -ReportType "Table" -ReportTitle "Report of data" -ReportPath "C:\Report" -ReportFileName "Report.html" -HTMLTitle "Main Data Reporting" -ReportPrecontent "Subtitle / Subcategory" -Description "This is the main data to report"

.INPUTS
    $DataReported
    $ReportType
    $ReportTitle
    $ReportPath
    $ReportFileName
    $HTMLTitle
    $ReportPrecontent
    $Description

.OUTPUTS
    HTML Report Created

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Format-DisplayResult', 'Switch-OpenHTMLReport', 'Switch-OpenExportFolder', 'Open-HTMLReport', 'ConvertTo-Html', 'Open-ExportFolder', 'Set-ValueToJSONFile'

#>

    Param (
        [Parameter(Mandatory=$False)]
        [Array]$DataReported,
        
        [Parameter(Mandatory=$True)]
        [ValidateSet('List','Table')]
        [String]$ReportType = 'List',
        
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
    
    $Date = $(Get-Date -Format yyyyMMdd-HHmmss)
    $DateShort = $(Get-Date -UFormat %Y%m%d)
    $FullReportPath = "$ReportPath\$global:BoxType\$DateShort\$Date-$ReportFileName.html"
    Test-FolderPath -FolderRoot "$ReportPath\$global:BoxType" -FolderPath "$ReportPath\$global:BoxType\$DateShort" -FolderName $DateShort
    
    If ($DataReported) {
    
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
        
        $Date = $(Get-Date -Format yyyy/MM/dd-HH:mm:ss)
        $ReportAuthor = "Report generated from : $env:COMPUTERNAME, by : $env:USERNAME, at : $Date (Local Time)."
        $HTML = ConvertTo-Html -Body "$Title $PreContent $($DataReported | ConvertTo-Html -As $ReportType)" -Title $ReportTitle -Head $header -PostContent "<br/>$ReportAuthor"
        
        Write-Log -Type INFO -Category 'Program run' -Name 'Export HTML Report' -Message 'Start export HTML report' -NotDisplay
        Write-Log -Type INFONO -Category 'Program run' -Name 'Export HTML Report' -Message 'Export HTML report status : ' -NotDisplay
        
        Try {
            $HTML | Out-File -FilePath $FullReportPath -Force -Encoding unicode
            Write-Log -Type VALUE -Category 'Program run' -Name 'Export HTML Report' -Message 'Successful' -NotDisplay
            Write-Log -Type INFONO -Category 'Program run' -Name 'Export HTML Report' -Message 'HTML Report has been exported to : '
            Write-Log -Type VALUE -Category 'Program run' -Name 'Export HTML Report' -Message $FullReportPath
            Open-HTMLReport -Path $FullReportPath
        }
        Catch {
            Write-Log -Type WARNING -Category 'Program run' -Name 'Export HTML Report' -Message "Failed, to export HTML report : `"$FullReportPath`", due to $($_.tostring())" -NotDisplay
        }
        
        Write-Log -Type INFO -Category 'Program run' -Name 'Export HTML Report' -Message 'End export HTML report' -NotDisplay
        
        If ($global:TriggerOpenHTMLReport -eq 0) {
            
            $global:TriggerOpenHTMLReport = Switch-OpenHTMLReport
            $global:JSONSettingsCurrentUserContent.Trigger.OpenHTMLReport = $global:TriggerOpenHTMLReport
            Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath
        }
        
        Open-ExportFolder -WriteLogName 'Program run - Export Result HTML' -ExportFolderPath $ReportPath
    }
    Else {
        Write-Log -Type WARNING -Category 'Program run' -Name 'Export HTML Report' -Message "Failed, to export HTML report : `"$FullReportPath`", due to : there is not data to export/Display" -NotDisplay
    }
}

#endregion Export

#region Manage Output Display

# Used only to allow to open export folder
Function Set-TriggerOpenExportFolder {

<#
.SYNOPSIS
    To set TriggerOpenExportFolder 

.DESCRIPTION
    To open TriggerOpenExportFolder

.PARAMETER None
    None

.EXAMPLE
    Set-TriggerOpenExportFolder

.INPUTS
    User input from Windows form dialogue box

.OUTPUTS
    Open Export Folder Trigger is set

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Open-ExportFolder', 'Export-BoxConfiguration', 'Set-ValueToJSONFile'

#>

    Param ()
    
    If ($global:TriggerOpenExportFolder -eq 0) {
        
        $global:TriggerOpenExportFolder = Switch-OpenExportFolder
        $global:JSONSettingsCurrentUserContent.Trigger.OpenExportFolder = $global:TriggerOpenExportFolder
        Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath
    }
}

# Used only to open HTML Report
Function Open-HTMLReport {

<#
.SYNOPSIS
    To open HTML Report

.DESCRIPTION
    To open HTML Report

.PARAMETER Path
    This is the full path of the HTML file to open

.EXAMPLE
    Open-HTMLReport -Path "C:\HTMLReportFolder\ReportHTML.html"

.INPUTS
    $Path

.OUTPUTS
    HTML report openned

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Export-HTMLReport'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$Path
    )
    
    Write-Log -Type INFO -Category 'Program initialisation' -Name "Open HTML Report" -Message "Start Open HTML Report" -NotDisplay
    Write-Log -Type INFONO -Category 'Program initialisation' -Name "Open HTML Report" -Message "Open HTML Report Status : " -NotDisplay
    
    If ($global:OpenHTMLReport -eq "Y") {
        
        Try {
            Invoke-Item -Path $Path
            Write-Log -Type VALUE -Category 'Program initialisation' -Name "Open HTML Report" -Message 'Successful' -NotDisplay
            Write-Log -Type INFONO -Name $WriteLogName -Message "Opening HTML Report : "
            Write-Log -Type VALUE -Name $WriteLogName -Message $Path
        }
        Catch {
            Write-Log -Type WARNING -Category 'Program initialisation' -Name "Open HTML Report" -Message "Failed to open HTML report : $Path, due to $($_.tostring())" -NotDisplay
        }
    }
    Else {
        Write-Log -Type VALUE -Category 'Program initialisation' -Name "Open HTML Report" -Message "User don't want to open HTML report" -NotDisplay
    }
    
    Write-Log -Type INFO -Category 'Program initialisation' -Name "Open HTML Report" -Message "End Open HTML Report" -NotDisplay
}

# Used only to open Export Folder
Function Open-ExportFolder {

<#
.SYNOPSIS
    To open Export Folder

.DESCRIPTION
    To open Export Folder

.PARAMETER WriteLogName
    This is the log categorie link the action and folder to open

.PARAMETER ExportFolderPath
    This is the full path of the Export Folder to open

.EXAMPLE
    Open-ExportFolder -WriteLogName "This is the log categorie" -ExportFolderPath "C:\Temp"

.INPUTS
    $WriteLogName
    $ExportFolderPath

.OUTPUTS
    Export Folder openned

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Export-toCSV', 'Export-toJSON', 'Export-HTMLReport', 'Export-BoxConfigTestingProgram', 'Set-TriggerOpenExportFolder', Export-BoxConfiguration

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$WriteLogName,
        
        [Parameter(Mandatory=$True)]
        [String]$ExportFolderPath
    )
    
    Set-TriggerOpenExportFolder
    
    $DateShort = Get-Date -Format yyyyMMdd
    $ExportFolderPath = "$ExportFolderPath\$global:BoxType\$DateShort"
    
    If ($global:OpenExportFolder -eq 'Y') {
        Write-Log -Type INFONO -Name $WriteLogName -Message "Opening folder : "
        Write-Log -Type VALUE -Name $WriteLogName -Message $ExportFolderPath
        Invoke-Item -Path $ExportFolderPath
    }
}

# Used only to Out-Gridview Display
Function Out-GridviewDisplay {

<#
.SYNOPSIS
    To Out-Gridview Display

.DESCRIPTION
    To Out-Gridview Display

.PARAMETER FormatedData
    Data you want to be displayed by out-gridview 

.PARAMETER APIName
    This is the name of API where data have been obtained

.PARAMETER Description
    This is the description of data have been collected by the API Name

.EXAMPLE
    Out-GridviewDisplay -FormatedData "$FormatedData" -APIName "device/log" - "Get log"

.INPUTS
    $FormatedData
    $APIName
    $Description

.OUTPUTS
    Data displayed by out-gridview

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Format-DisplayResult'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$Description
    )
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Out-Gridview Display' -Message 'Start Out-Gridview Display' -NotDisplay
    $FormatedData | Out-GridView -Title $Description -Wait
    Write-Log -Type INFO -Category 'Program run' -Name 'Out-Gridview Display' -Message 'End Out-Gridview Display' -NotDisplay
}

#endregion Manage Output Display

#endregion Manage Output Display after data export

#region Export data

# Used only to export Full Box Configuration to CSV/JSON files
function Export-BoxConfiguration {

<#
.SYNOPSIS
    To export Full Box Configuration to CSV/JSON files

.DESCRIPTION
    To export Full Box Configuration to CSV/JSON files

.PARAMETER APISName
    This is the list of API name that based to collect data

.PARAMETER UrlRoot
    This is the root API url that API name are based to collect data

.PARAMETER JSONFolderPath
    This is the folder path use for JSON export file

.PARAMETER CSVFolderPath
    This is the folder path use for CSV export file

.PARAMETER GitHubUrlSite
    This is the url of the Github Project

.PARAMETER JournalPath
    This is the path of the folder use to store Box Journal

.PARAMETER Mail
    This is the mail address of the developper

.EXAMPLE
    Export-BoxConfiguration -APISName "API Name list" -UrlRoot "https://mabbox.bytel.fr" -JSONFolderPath "C:\Export\JSON" CSVFolderPath "C:\Export\CSV" -GitHubUrlSite "https://github.com/Zardrilokis/BBOX-Administration-Powershell" -JournalPath "C:\Export\Journal" -Mail "Tom78_91_45@yahoo.fr"
    Export-BoxConfiguration -APISName "API Name list" -UrlRoot "https://mabbox.bytel.fr:8560" -JSONFolderPath "C:\Export\JSON" CSVFolderPath "C:\Export\CSV" -GitHubUrlSite "https://github.com/Zardrilokis/BBOX-Administration-Powershell" -JournalPath "C:\Export\Journal" -Mail "Tom78_91_45@yahoo.fr"

.INPUTS
    $APISName
    $UrlRoot
    $JSONFolderPath
    $CSVFolderPath
    $GitHubUrlSite
    $JournalPath
    $Mail

.OUTPUTS
    Data exported to csv and json files

.NOTES
    Author : @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Switch-OpenExportFolder', 'Get-BBOXInformation', 'Open-ExportFolder'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [Array]$APISName,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$JSONFolderPath,

        [Parameter(Mandatory=$True)]
        [String]$CSVFolderPath,

        [Parameter(Mandatory=$True)]
        [String]$ReportPath,
        
        [Parameter(Mandatory=$True)]
        [String]$GitHubUrlSite,

        [Parameter(Mandatory=$True)]
        [String]$JournalPath,

        [Parameter(Mandatory=$True)]
        [String]$Mail
    ) 
    
    Foreach ($APIName in $APISName) {
        
        $UrlToGo = "$UrlRoot/$($APIName.APIName)"
        
        # Get information from Box API
        Write-Log -Type INFO -Category 'Program run' -Name 'Get Information' -Message "Get $($APIName.Label) configuration ..."
        $Json = Get-BBOXInformation -UrlToGo $UrlToGo
        
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $DateShort = $(Get-Date -UFormat %Y%m%d)
        
        # Export result as JSON file
        Test-FolderPath -FolderRoot "$JSONFolderPath\$global:BoxType" -FolderPath "$JSONFolderPath\$global:BoxType\$DateShort" -FolderName $DateShort
        
        $ExportPathJson = "$JSONFolderPath\$global:BoxType\$DateShort\$Date-$($APIName.Exportfile).json"
        Write-Log -Type INFO -Category 'Program run' -Name 'Export Box Configuration To JSON' -Message 'Start Export Box Configuration To JSON' -NotDisplay
        Write-Log -Type INFONO -Category 'Program run' -Name 'Export Box Configuration To JSON' -Message 'Export Box Configuration To JSON status : ' -NotDisplay
        
        Try {
            $Json | ConvertTo-Json -depth 10 | Out-File -FilePath $ExportPathJson -Force
            Write-Log -Type VALUE -Category 'Program run' -Name 'Export Box Configuration To JSON' -Message 'Successful' -NotDisplay
            Write-Log -Type INFONO -Category 'Program run' -Name 'Export Box Configuration To JSON' -Message 'Export configuration to : '
            Write-Log -Type VALUE -Category 'Program run' -Name 'Export Box Configuration To JSON' -Message $ExportPathJson
        }
        Catch {
            Write-Log -Type WARNING -Category 'Program run' -Name 'Export Box Configuration To JSON' -Message "Failed, due to $($_.tostring())"
        }
        
        Write-Log -Type INFO -Category 'Program run' -Name 'Export Box Configuration To JSON' -Message 'End Export Box Configuration To JSON' -NotDisplay
        
        # Export result as CSV file
        Test-FolderPath -FolderRoot "$CSVFolderPath\$global:BoxType" -FolderPath "$CSVFolderPath\$global:BoxType\$DateShort" -FolderName $DateShort
        $FormatedData = Switch-Info -Label $APIName.label -UrlToGo $UrlToGo -APIName $APIName.APIName -Mail $Mail -JournalPath $JournalPath -GitHubUrlSite $GitHubUrlSite
        
        If (-not ([string]::IsNullOrEmpty($FormatedData))) {
        
            Write-Log -Type INFO -Category 'Program run' -Name 'Export Box Configuration To CSV' -Message 'Start Export Box Configuration To CSV' -NotDisplay
            Write-Log -Type INFONO -Category 'Program run' -Name 'Export Box Configuration To CSV' -Message 'Export Box Configuration To CSV status : ' -NotDisplay 
            $ExportPathCSV = "$CSVFolderPath\$global:BoxType\$DateShort\$Date-$($APIName.Exportfile).csv"   
            
            Try {
                $FormatedData | Export-Csv -Path $ExportPathCSV -Encoding unicode -Force -Delimiter ";" -NoTypeInformation
                Write-Log -Type VALUE -Category 'Program run' -Name 'Export Box Configuration To CSV' -Message 'Successful' -NotDisplay
                Write-Log -Type INFONO -Category 'Program run' -Name 'Export Box Configuration To CSV' -Message 'Export configuration to : '
                Write-Log -Type VALUE -Category 'Program run' -Name 'Export Box Configuration To CSV' -Message $ExportPathCSV
            }
            Catch {
                Write-Log -Type WARNING -Category 'Program run' -Name 'Export Box Configuration To CSV' -Message "Failed, due to $($_.tostring())"
            }
            
            Write-Log -Type INFO -Category 'Program run' -Name 'Export Box Configuration To CSV' -Message 'End Export Box Configuration To CSV' -NotDisplay
        }
        
        # Export result as HTML file
        $Json = Switch-Info -Label $APIName.Label -UrlToGo $UrlToGo -APIName $APIName.APIName -Mail $Mail -JournalPath $JournalPath -GitHubUrlSite $GitHubUrlSite
        Export-HTMLReport -DataReported $Json -ReportType $APIName.ReportType -ReportTitle "$global:BoxType Configuration Report - $($APIName.APIName)" -ReportPath $ReportPath -ReportFileName $APIName.ExportFile -HTMLTitle "$global:BoxType Configuration Report" -ReportPrecontent $APIName.APIName -Description $APIName.Description
    }

    # Open Export Folder
    Open-ExportFolder -WriteLogName 'Program run - Export Box Configuration To JSON' -ExportFolderPath $JSONFolderPath
    Open-ExportFolder -WriteLogName 'Program run - Export Box Configuration To CSV' -ExportFolderPath $CSVFolderPath
}

# Used only to export Full Box Configuration to JSON files to test the program
function Export-BoxConfigTestingProgram {

<#
.SYNOPSIS
    To export Full Box Configuration to JSON files to test the program

.DESCRIPTION
    To export Full Box Configuration to JSON files to test the program

.PARAMETER APISName
    This is the list of API name that based to collect data

.PARAMETER UrlRoot
    This is the root API url that API name are based to collect data

.PARAMETER OutputFolder
    This is the folder path use for export files

.PARAMETER GitHubUrlSite
    This is the url of the Github Project

.PARAMETER JournalPath
    This is the path of the folder use to store Box Journal

.PARAMETER Mail
    This is the mail address of the developper

.EXAMPLE
    Export-BoxConfigTestingProgram -APISName "API Name list" -UrlRoot "https://mabbox.bytel.fr" -OutputFolder "C:\Export\JSON" -GitHubUrlSite "https://github.com/Zardrilokis/BBOX-Administration-Powershell" -JournalPath "C:\Export\Journal" -Mail "Tom78_91_45@yahoo.fr"
    Export-BoxConfigTestingProgram -APISName "API Name list" -UrlRoot "https://mabbox.bytel.fr:8560" -OutputFolder "C:\Export\JSON" -GitHubUrlSite "https://github.com/Zardrilokis/BBOX-Administration-Powershell" -JournalPath "C:\Export\Journal" -Mail "Tom78_91_45@yahoo.fr"

.INPUTS
    $APISName
    $UrlRoot
    $OutputFolder
    $GitHubUrlSite
    $JournalPath
    $Mail

.OUTPUTS
    Data exported to json files

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        
        [Parameter(Mandatory=$True)]
        [Array]$APISName,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$Mail,
        
        [Parameter(Mandatory=$True)]
        [String]$JournalPath,
        
        [Parameter(Mandatory=$True)]
        [String]$OutputFolder,

        [Parameter(Mandatory=$True)]
        [String]$GitHubUrlSite
    )
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Testing Program' -Message 'Start Testing Program'
    
    Foreach ($APIName in $APISName) {
        
        Write-Log -Type INFONO -Category 'Program run' -Name 'Testing Program' -Message 'Tested action : '
        Write-Log -Type VALUE -Category 'Program run' -Name 'Testing Program' -Message $($APIName.Label)   
        
        $UrlToGo = "$UrlRoot/$($APIName.APIName)"
        
        # Get information from Box API
        $FormatedData = @()
        $FormatedData = Switch-Info -Label $APIName.Label -UrlToGo $UrlToGo -APIName $APIName.APIName -Mail $Mail -JournalPath $JournalPath -GitHubUrlSite $GitHubUrlSite
        
        # Export result as CSV file
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $DateShort = $(Get-Date -UFormat %Y%m%d)
        
        If ($APIName.ExportFile -and $FormatedData) {
            
            Test-FolderPath -FolderRoot "$OutputFolder\$global:BoxType" -FolderPath "$OutputFolder\$global:BoxType\$DateShort" -FolderName $DateShort
            Write-Log -Type INFO -Category 'Program run' -Name 'Testing Program' -Message 'Start Export Box Configuration To CSV' -NotDisplay
            Write-Log -Type INFONO -Category 'Program run' -Name 'Testing Program' -Message 'Export Box Configuration To CSV status : ' -NotDisplay
            
            Try {
                $FullPath = "$OutputFolder\$global:BoxType\$DateShort\$Date-$($APIName.ExportFile).csv"
                $FormatedData | Export-Csv -Path $FullPath -Encoding unicode -Force -NoTypeInformation -Delimiter ";" -ErrorAction Continue
                Write-Log -Type VALUE -Category 'Program run' -Name 'Testing Program' -Message 'Successful' -NotDisplay
                Write-Log -Type INFONO -Category 'Program run' -Name 'Testing Program' -Message 'Export configuration to : '
                Write-Log -Type VALUE -Category 'Program run' -Name 'Testing Program' -Message $FullPath
            }
            Catch {
                Write-Log -Type WARNING -Category 'Program run' -Name 'Testing Program' -Message "Failed, due to $($_.tostring())"
            }
            
            Write-Log -Type INFO -Category 'Program run' -Name 'Testing Program' -Message 'End Export Box Configuration To CSV' -NotDisplay
        }
        Else {
            Write-Log -Type INFO -Category 'Program run' -Name 'Testing Program' -Message 'No data were found, export cant be possible' -NotDisplay
        }
    }
    
    Open-ExportFolder -WriteLogName 'Program run - Testing Program' -ExportFolderPath $OutputFolder
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Testing Program' -Message 'End Testing Program'
}

# Used only to export Box Journal
Function Get-BoxJournal {

<#
.SYNOPSIS
    To export Box Journal

.DESCRIPTION
    To export Box Journal

.PARAMETER UrlToGo
    This is the url to get data from the journal

.PARAMETER JournalPath
    This is the full path of the export file for the journal

.EXAMPLE
    Get-BoxJournal -UrlToGo "https://mabbox.bytel.fr/log.html" -JournalPath "C:\Journal\Journal.csv"
    Get-BoxJournal -UrlToGo "https://mabbox.bytel.fr:8560/log.html" -JournalPath "C:\Journal\Journal.csv"

.INPUTS
    $UrlToGo
    $JournalPath

.OUTPUTS
    Journal exported to CSV file

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Switch-Info'

#>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$JournalPath
    )
        
    # Loading Journal Home Page
    $UrlToGo = $UrlToGo -replace $global:APIVersion -replace ('//','/')
    $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
    Start-Sleep $global:SleepChromeDriverLoading
    
    # Download Journal file from Box
    Write-Log -Type INFO -Category 'Program run' -Name 'Download Box Journal to export' -Message 'Start download Box Journal' -NotDisplay
    Try {
        $global:ChromeDriver.FindElementByClassName('download').click()
    }
    Catch {
        Write-Log -Type WARNING -Category 'Program run' -Name 'Download Box Journal to export' -Message "Failed to start the download Box Journal, due to : $($_.tostring())" -NotDisplay
    }
    Write-Log -Type INFONO -Category 'Program run' -Name 'Download Box Journal to export' -Message "Download Journal in progress ... : "
    
    # Waiting end of journal's download
    Start-Sleep $global:SleepBoxJournalDownload
    
    Write-Log -Type INFONO -Category 'Program run' -Name 'Download Box Journal to export' -Message 'User download folder location : ' -NotDisplay
    Try {
        $UserDownloadFolderDefault = Get-ItemPropertyValue -Path $global:DownloadShellRegistryFolder -Name $global:DownloadShellRegistryFolderName -ErrorAction Stop
        Write-Log -Type VALUE -Category 'Program run' -Name 'Download Box Journal to export' -Message $UserDownloadFolderDefault -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Category 'Program run' -Name 'Download Box Journal to export' -Message "Unknown, due to : $($_.tostring())" -NotDisplay
    }
    
    Write-Log -Type INFONO -Category 'Program run' -Name 'Download Box Journal to export' -Message 'User download folder status : ' -NotDisplay
    If (Test-Path -Path $UserDownloadFolderDefault) {
        
        Try {
            Write-Log -Type VALUE -Category 'Program run' -Name 'Download Box Journal to export' -Message 'Exists' -NotDisplay
            $UserDownloadFolderDefaultFileName = (Get-ChildItem -Path $UserDownloadFolderDefault -Name "$global:JournalName*" | Select-Object -Property PSChildName | Sort-Object PSChildName -Descending)[0].PSChildName
            $UserDownloadFileFullPath          = "$UserDownloadFolderDefault\$UserDownloadFolderDefaultFileName"
            Write-Log -Type VALUE -Category 'Program run' -Name 'Download Box Journal to export' -Message $UserDownloadFileFullPath -NotDisplay
        }
        Catch {
            Write-Log -Type WARNING -Category 'Program run' -Name 'Download Box Journal to export' -Message "Unknown, due to : $($_.tostring())" -NotDisplay
        }
    }
    Else {
        Write-Log -Type WARNING -Category 'Program run' -Name 'Download Box Journal to export' -Message 'Unable to find user download folder' -NotDisplay
    }
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Download Box Journal to export' -Message 'Download Box Journal status : ' -NotDisplay
    If (-not ([string]::IsNullOrEmpty($UserDownloadFileFullPath))) {
        
        If (Test-Path -Path $UserDownloadFileFullPath) {
            
            $DateShort                   = $(Get-Date -UFormat %Y%m%d)
            $ExportJournalFolderRootPath = "$JournalPath\$global:BoxType"
            $ExportJournalFolderPath     = "$ExportJournalFolderRootPath\$DateShort"
            
            Write-Log -Type INFONO -Category 'Program run' -Name 'Journal download location folder creation' -Message "Journal download location folder creation to $ExportJournalFolderPath, status : " -NotDisplay
            If ($(Test-Path -Path $ExportJournalFolderPath) -eq $false) {
                
                Try {
                    $null = New-Item -Path $ExportJournalFolderRootPath -Name $DateShort -ItemType Directory -Force -ErrorAction Stop
                    Write-Log -Type INFO -Category 'Program run' -Name 'Journal download location folder creation' -Message 'Successful' -NotDisplay
                }
                Catch {
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Journal download location folder creation' -Message "Failed, to create folder : $ExportJournalFolderPath, due to $($_.ToString())"
                }
            }
            Else {
                Write-Log -Type INFO -Category 'Program run' -Name 'Journal download location folder creation' -Message 'Already created' -NotDisplay
            }
            
            $DownloadedJournalDestinationPath = "$ExportJournalFolderPath\$UserDownloadFolderDefaultFileName"
            Write-Log -Type INFONO -Category 'Program run' -Name 'Download Box Journal to export' -Message 'Box Journal has been downloaded from : ' -NotDisplay
            Write-Log -Type VALUE -Category 'Program run' -Name 'Download Box Journal to export' -Message $UserDownloadFileFullPath -NotDisplay
            Write-Log -Type INFONO -Category 'Program run' -Name 'Download Box Journal to export' -Message 'Box Journal has been downloaded to : ' -NotDisplay
            Write-Log -Type VALUE -Category 'Program run' -Name 'Download Box Journal to export' -Message $DownloadedJournalDestinationPath -NotDisplay
            Try {
                # Move Journal file from Download folder to journal folder : "$PSScriptRoot\Journal"
                Move-Item -Path $UserDownloadFileFullPath -Destination $DownloadedJournalDestinationPath -Force -ErrorAction Stop
                Write-Log -Type VALUE -Category 'Program run' -Name 'Download Box Journal to export' -Message 'Finish' -NotDisplay
            }
            Catch {
                Write-Log -Type WARNING -Category 'Program run' -Name 'Download Box Journal to export' -Message "Failed, due to : $($_.tostring())" -NotDisplay
            }
            
            # Export Journal data as CSV file to the correct folder
            If (Test-path -Path $DownloadedJournalDestinationPath) {
                
                Try {
                    $FormatedData = Import-Csv -Path $DownloadedJournalDestinationPath -Delimiter ';' -Encoding unicode
                }
                Catch {
                    Write-Log -Type WARNING -Category 'Program run' -Name 'Download Box Journal to export' -Message "Failed, due to : $($_.tostring())" -NotDisplay
                }
            }
            Else {
                $FormatedData = $null
            }
            
            Write-Log -Type VALUE -Category 'Program run' -Name 'Download Box Journal to export' -Message 'Successful'
            Write-Log -Type INFONO -Category 'Program run' -Name 'Download Box Journal to export' -Message 'Box Journal has been saved to : '
            Write-Log -Type INFONO -Category 'Program run' -Name 'Download Box Journal to export' -Message "$DownloadedJournalDestinationPath"
            Write-Log -Type INFO -Category 'Program run' -Name 'Download Box Journal to export' -Message "End download Box Journal" -NotDisplay
            Return $FormatedData
        }
    }
    Else {
        Write-Log -Type WARNING -Category 'Program run' -Name 'Download Box Journal to export' -Message 'Failed, due to time out'
        Write-Log -Type WARNING -Category 'Program run' -Name 'Download Box Journal to export' -Message 'Failed to download Journal' -NotDisplay
        Write-Log -Type INFO -Category 'Program run' -Name 'Download Box Journal to export' -Message 'End download Box Journal' -NotDisplay
    }
}

# Used only to manage errors when there is no data to Export/Display
Function Get-EmptyFormatedDATA {

<#
.SYNOPSIS
    To manage errors when there is no data to Export/Display

.DESCRIPTION
    To manage errors when there is no data to Export/Display

.PARAMETER FormatedData
    Array with data or not

.EXAMPLE
    Get-EmptyFormatedDATA -FormatedData $FormatedData

.INPUTS
    $FormatedData

.OUTPUTS
    Write log when there is no data to Export/Display

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Export-GlobalOutputData'

#>

    Param (
        [Parameter(Mandatory=$False)]
        [array]$FormatedData
    )
    
    Write-Log -Type INFO -Category 'Program run' -Name 'Display/Export Result' -Message 'Start display/export result' -NotDisplay
    
    Switch ($FormatedData) {
        
        $Null     {Write-Log -Type INFO -Category 'Program initialisation' -Name "Display / Export Result" -Message 'No data were found, no need to Export/Display' -NotDisplay;Break}
        
        ''        {Write-Log -Type INFO -Category 'Program initialisation' -Name "Display / Export Result" -Message 'No data were found, no need to Export/Display' -NotDisplay;Break}
        
        ' '       {Write-Log -Type INFO -Category 'Program initialisation' -Name "Display / Export Result" -Message 'No data were found, no need to Export/Display' -NotDisplay;Break}
        
        'Domain'  {Write-Log -Type WARNING -Category 'Program initialisation' -Name "Display / Export Result" -Message 'Due to error, the result cant be displayed / exported' -NotDisplay;Break}
                
        'Program' {Write-Log -Type INFO -Category 'Program initialisation' -Name "Display / Export Result" -Message 'No data need to be exported or displayed' -NotDisplay;Break}
        
        Default   {Write-Log -Type WARNING -Category 'Program initialisation' -Name "Display / Export Result" -Message "Unknow Error, seems dev missing, result : $FormatedData";Break}
    }

    Write-Log -Type INFO -Category 'Program initialisation' -Name "Export/Display Result" -Message 'End export/display result' -NotDisplay
}

# Used only to manage data Export/Display
function Export-GlobalOutputData {

<#
.SYNOPSIS
    To manage data Export/Display

.DESCRIPTION
    To manage data Export/Display

.PARAMETER FormatedData
    Data to export

.PARAMETER APIName
    API name (Url) used to get data

.PARAMETER ExportCSVPath
    Folder path for CSV files

.PARAMETER ExportJSONPath
    Folder path for JSON files

.PARAMETER ExportFile
    Name of the exoprt file

.PARAMETER Description
    Description base on the API Name and the associated action

.PARAMETER ReportType
    Type of the report 2 choices : Table / List

.PARAMETER ReportPath
    Folder path for report Files

.EXAMPLE
    Export-GlobalOutputData -FormatedData $FormatedData -APIName "device\log" -ExportCSVPath "C:\Export\CSV" -ExportJSONPath "C:\Export\JSON" -ExportFile "device-log" -Description "Device Logs" -ReportType "Table" -ReportPath "C:\Export\Report"
    Export-GlobalOutputData -FormatedData $FormatedData -APIName "device\log" -ExportCSVPath "C:\Export\CSV" -ExportJSONPath "C:\Export\JSON" -ExportFile "device-log" -Description "Device Logs" -ReportType "List" -ReportPath "C:\Export\Report"

.INPUTS
    $FormatedData
    $APIName
    $ExportCSVPath
    $ExportJSONPath
    $ExportFile
    $Description
    $ReportType
    $ReportPath

.OUTPUTS
    Data exported to CSV, JSON, HTML
    Data display Out-GridView or HTML

.NOTES
    Author: @Zardrilokis => Tom78_91_45@yahoo.fr
    Linked to function(s): 'Switch-ExportFormat', 'Switch-DisplayFormat', 'Format-ExportResult', 'Format-DisplayResult', 'Get-EmptyFormatedDATA', 'Set-ValueToJSONFile', 'Set-ValueToJSONFile'
    Linked to script(s): '.\Box-Administration.psm1'

#>

    Param (
        [Parameter(Mandatory=$False)]
        [array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [string]$APIName,
        
        [Parameter(Mandatory=$True)]
        [string]$ExportCSVPath,
        
        [Parameter(Mandatory=$True)]
        [string]$ExportJSONPath,
        
        [Parameter(Mandatory=$False)]
        [string]$ExportFile,
        
        [Parameter(Mandatory=$True)]
        [string]$Description,
        
        [Parameter(Mandatory=$False)]
        [string]$ReportType,
        
        [Parameter(Mandatory=$True)]
        [string]$ReportPath
    )
    
    # Format data before choose output format
    If (($FormatedData -notmatch $global:FormatedDataGlobalOutputDataExclusion) -and ($null -ne $FormatedData) -and ($FormatedData -ne '') -and ($FormatedData -ne ' ')) {
        
        # Choose Export format => CSV or JSON
        If ($global:TriggerExportFormat -eq 0) {
            
            $global:TriggerExportFormat = Switch-ExportFormat
            $global:JSONSettingsCurrentUserContent.Trigger.ExportFormat = $global:TriggerExportFormat
        }
        
        # Choose Display format => HTML or Table
        If ($global:TriggerDisplayFormat -eq 0) {
            
            $global:TriggerDisplayFormat = Switch-DisplayFormat
            $global:JSONSettingsCurrentUserContent.Trigger.DisplayFormat = $global:TriggerDisplayFormat
        }
        
        # Choose if open export folder
        If ($global:TriggerOpenExportFolder -eq 0) {
            
            $global:TriggerOpenExportFolder = Switch-OpenExportFolder
            $global:JSONSettingsCurrentUserContent.Trigger.OpenExportFolder = $global:TriggerOpenExportFolder
        }

        # Save New settings set to JSON configuration file
        Set-ValueToJSONFile -JSONFileContent $global:JSONSettingsCurrentUserContent -JSONFileContentPath $global:JSONSettingsCurrentUserFileNamePath
        
        # Apply Export Format
        Format-ExportResult -FormatedData $FormatedData -APIName $APIName -Exportfile $ExportFile -ExportCSVPath $ExportCSVPath -ExportJSONPath $ExportJSONPath -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        
        # Apply Display Format
        Format-DisplayResult -FormatedData $FormatedData -APIName $APIName -Exportfile $ExportFile -Description $Description -ReportType $ReportType -ReportPath $ReportPath -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }
    Else {
        Get-EmptyFormatedDATA -FormatedData $FormatedData -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }
}

# Used only to get Files count for each export folder
function Export-ProgramFilesCount {

    <#
    .SYNOPSIS
        Export Files numbers generate by the program
    
    .DESCRIPTION
        Export Files numbers generate by the program
    
    .PARAMETER FolderRoot
        This is the root folder where files data are stored
    
    .EXAMPLE
        Export-ProgramFilesCount -FolderRoot 'C:\Temp'

    .INPUTS
        $FolderRoot

    .OUTPUTS
        $Array

    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        Linked to function(s): ''
        Linked to script(s): ''
    
    #>
    
        Param (
            [Parameter(Mandatory=$False)]
            [string]$FolderRoot
        )
        
        # Create array
        $Array = @()
        
        $global:RessourcesFolderName = 'Ressources'
        $FolderRoot = "D:\OneDrive\Scripting\Projets\BBOX-Administration\Version-2.7"
        $FolderList = Get-ChildItem -Path $FolderRoot -Exclude $global:RessourcesFolderName -Directory
        
        Foreach ($Folder in $FolderList) {
            
            $FileCount = $(get-childItem -Path $Folder.FullName -Recurse).count
            
            $FolderLine = New-Object -TypeName PSObject
            $FolderLine | Add-Member -Name 'Folder Name'        -MemberType Noteproperty -Value $Folder.Name
            $FolderLine | Add-Member -Name 'Folder Path'        -MemberType Noteproperty -Value $Folder.FullName
            $FolderLine | Add-Member -Name 'Parent Folder'      -MemberType Noteproperty -Value $Folder.Parent
            $FolderLine | Add-Member -Name 'Folder Files count' -MemberType Noteproperty -Value $FileCount
            
            # Add lines to $Array
            $Array += $FolderLine
        
        }
        Return $Array
}

#endregion Export data

#endregion GLOBAL Functions

#region Switch-Info

#region BBox

#region Errors code

Function Get-BBOXErrorCode {
    
    <#
    .SYNOPSIS
        Get Error code and convert it to human readable

    .DESCRIPTION
        Get Error code and convert it to human readable

    .PARAMETER Json
        This the Json error code to convert

    .EXAMPLE
        Get-BBOXErrorCode -Json $JSON

    .INPUTS
        [Array]$Json
        This the Json error code to convert

    .OUTPUTS
        [PSObject]$Array

    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : '', ''
        linked to script : '.\BBOX-Administration.psm1'
    #>
    
    Param (
        [Parameter(Mandatory=$True)]
        [Array]$Json
    )
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.exception

    # Create New PSObject and add values to array
    $ErrorLine = New-Object -TypeName PSObject
    $ErrorLine | Add-Member -Name 'Domain'      -MemberType Noteproperty -Value $Json.domain
    $ErrorLine | Add-Member -Name 'Code'        -MemberType Noteproperty -Value $Json.code
    $ErrorLine | Add-Member -Name 'ErrorName'   -MemberType Noteproperty -Value $Json.errors[0].name
    $ErrorLine | Add-Member -Name 'ErrorReason' -MemberType Noteproperty -Value $Json.errors[0].reason
    
    # Add lines to $Array
    $Array += $ErrorLine
    
    Return $Array
}

Function Get-BBOXErrorCodeTest {
    
    <#
    .SYNOPSIS
        Get Error code and convert it to human readable

    .DESCRIPTION
        Get Error code and convert it to human readable

    .PARAMETER Json
        This the Json error code to convert

    .EXAMPLE
        Get-BBOXErrorCodeTest -Json $JSON

    .INPUTS
        [Array]$Json
        This the Json error code to convert

    .OUTPUTS
        [PSObject]$Array

    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : '', ''
        linked to script : '.\BBOX-Administration.psm1'

    #>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    #$Json = $Json.exception
    
    # Create New PSObject and add values to array
    $ErrorLine = New-Object -TypeName PSObject
    $ErrorLine | Add-Member -Name 'Domain'      -MemberType Noteproperty -Value $Json.exception.domain
    $ErrorLine | Add-Member -Name 'Code'        -MemberType Noteproperty -Value $Json.exception.code
    $ErrorLine | Add-Member -Name 'ErrorName'   -MemberType Noteproperty -Value $Json.exception.errors[0].name
    $ErrorLine | Add-Member -Name 'ErrorReason' -MemberType Noteproperty -Value $Json.exception.errors[0].reason
    
    # Add lines to $Array
    $Array += $ErrorLine
    
    Return $Array
}

#endregion Errors code

#region Get Function

#region PasswordRecoveryVerify

Function Get-BBOXPasswordRecoveryVerify {
    
    <#
    .SYNOPSIS
        Get Password Recovery Verify
        
    .DESCRIPTION
        Get Password Recovery Verify
        
    .PARAMETER UrlToGo
        This is the Url to get information
        
    .EXAMPLE
        Function can be used only on local network
        Get-BBOXPasswordRecoveryVerify -UrlToGo 'https://192.168.1.254/api/v1/password-recovery/verify'
        
    .INPUTS
        [String]$UrlToGo
        
    .OUTPUTS
        Password recovery verify is set to 'Yes' or 'No'

    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : 'Get-BBOXInformation'
        linked to script : '.\BBOX-Administration.psm1'
    #>
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )

    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Create New PSObject and add values to array
    $PasswordLine = New-Object -TypeName PSObject
    $PasswordLine | Add-Member -Name 'Service'    -MemberType Noteproperty -Value 'Password Recovery Verify'
    $PasswordLine | Add-Member -Name 'Method'     -MemberType Noteproperty -Value $Json.method
    $PasswordLine | Add-Member -Name 'Expiration' -MemberType Noteproperty -Value $Json.expires
    
    # Add lines to $Array
    $Array += $PasswordLine
    
    Return $Array
}

#endregion PasswordRecoveryVerify

#region Airties

function Get-BBOXAirties {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Select $JSON header
    $Json = $Json.airties
        
    Return $Json
}

function Get-BBOXAirtiesLANMode {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.airties.lanmode
    
    # Create New PSObject and add values to array
    $LANMode = New-Object -TypeName PSObject
    $LANMode | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'Airties - LAN Mode'
    $LANMode | Add-Member -Name 'State'   -MemberType Noteproperty -Value $(Get-Status -Status $Json.enable)

    # Add lines to $Array
    $Array += $LANMode
    
    Return $Array
}

#endregion Airties

#region API Ressources Map

Function Get-BBOXAPIRessourcesMap {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.apis
    
    $API = 0
    $UrlRoot = $UrlToGo -replace ('/V1/map','')
    
    While ($API -lt ($Json.Count)) {
        
        # If Method is only PUT (Set) or POST (Modify)
        If ($Json[$API].method -notlike 'GET') {             
                
            $Params = 0
            
            While ($Params -lt $Json[$API].params.count) {
                
                # Create New PSObject and add values to array    
                $APILine = New-Object -TypeName PSObject
                $APILine | Add-Member -Name 'API name'           -MemberType Noteproperty -Value $($Json[$API]).api
                $APILine | Add-Member -Name 'API url'            -MemberType Noteproperty -Value "$UrlRoot/$($($Json[$API]).api)"
                $APILine | Add-Member -Name 'Action'             -MemberType Noteproperty -Value ($Json[$API]).method
                $APILine | Add-Member -Name 'Local permissions'  -MemberType Noteproperty -Value ($Json[$API]).permission.local
                $APILine | Add-Member -Name 'Remote permissions' -MemberType Noteproperty -Value ($Json[$API]).permission.remote
                $APILine | Add-Member -Name 'CSRFP'              -MemberType Noteproperty -Value (Get-Status -Status $(($Json[$API]).permission.csrfp))
                $APILine | Add-Member -Name 'CDC'                -MemberType Noteproperty -Value (Get-Status -Status $(($Json[$API]).permission.cdc))
                $APILine | Add-Member -Name 'Scope'              -MemberType Noteproperty -Value ($Json[$API]).permission.scope
                
                # Add new colomns for settings
                $APILine | Add-Member -Name 'Settings'           -MemberType Noteproperty -Value 'Yes'
                $APILine | Add-Member -Name 'Name'               -MemberType Noteproperty -Value ($Json[$API]).params[$Params].name
                $APILine | Add-Member -Name 'Is optionnal ?'     -MemberType Noteproperty -Value (Get-Status -Status $(($Json[$API]).params[$Params].optional))
                $APILine | Add-Member -Name 'Type'               -MemberType Noteproperty -Value ($Json[$API]).params[$Params].type
                $APILine | Add-Member -Name 'Minimal value'      -MemberType Noteproperty -Value ($Json[$API]).params[$Params].range.min
                $APILine | Add-Member -Name 'Maximal value'      -MemberType Noteproperty -Value ($Json[$API]).params[$Params].range.max
                
                # Add lines to $Array
                $Array += $APILine
                    
                # Go to next line
                $Params ++
            }
        }
        
        # If Method is only GET (read)
        Else {
            $APILine = New-Object -TypeName PSObject
            $APILine | Add-Member -Name 'API name'           -MemberType Noteproperty -Value $($Json[$API]).api
            $APILine | Add-Member -Name 'API url'            -MemberType Noteproperty -Value "$UrlRoot/$($($Json[$API]).api)"
            $APILine | Add-Member -Name 'Action'             -MemberType Noteproperty -Value ($Json[$API]).method
            $APILine | Add-Member -Name 'Local permissions'  -MemberType Noteproperty -Value ($Json[$API]).permission.local
            $APILine | Add-Member -Name 'Remote permissions' -MemberType Noteproperty -Value ($Json[$API]).permission.remote
            $APILine | Add-Member -Name 'CSRFP'              -MemberType Noteproperty -Value (Get-Status -Status $(($Json[$API]).permission.csrfp))
            $APILine | Add-Member -Name 'CDC'                -MemberType Noteproperty -Value (Get-Status -Status $(($Json[$API]).permission.cdc))
            $APILine | Add-Member -Name 'Scope'              -MemberType Noteproperty -Value ($Json[$API]).permission.scope
            
            # Add new colomns for settings and set them to ''
            $APILine | Add-Member -Name 'Settings'           -MemberType Noteproperty -Value 'No'
            $APILine | Add-Member -Name 'Name'               -MemberType Noteproperty -Value ''
            $APILine | Add-Member -Name 'Is optionnal ?'     -MemberType Noteproperty -Value ''
            $APILine | Add-Member -Name 'Type'               -MemberType Noteproperty -Value ''
            $APILine | Add-Member -Name 'Minimal value'      -MemberType Noteproperty -Value ''
            $APILine | Add-Member -Name 'Maximal value'      -MemberType Noteproperty -Value ''
            
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

Function Get-BBOXBackupList {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
        
    # Check if there local Box configurations save
    If ($Json.Count -ne '0') {
        
        $Config = 0
        
        While ($Config -lt $Json.count) {
            
            # Create New PSObject and add values to array
            $ConfigLine = New-Object -TypeName PSObject
            $ConfigLine | Add-Member -Name 'ID'                      -MemberType Noteproperty -Value $Json[$Config].id
            $ConfigLine | Add-Member -Name 'Backup Name'             -MemberType Noteproperty -Value $Json[$Config].name
            If ($Json[$Config].date) {
                $ConfigLine | Add-Member -Name 'Backup Creation Date' -MemberType Noteproperty -Value $(Edit-Date -Date $Json[$Config].date)
            }
            $ConfigLine | Add-Member -Name 'Backup Firmware Version' -MemberType Noteproperty -Value $Json[$Config].firmware
            
            # Add lines to $Array
            $Array += $ConfigLine
            
            # Go to next line
            $Config ++
        }
        
        Return $Array
    }
    # Check if Box Cloud Synchronisation Service is Active and if user allow it
    Else {
        
        $APIName                   = 'usersave'
        $UrlToGo                   = $UrlToGo.Replace('configs',$APIName)
        $CloudSynchronisationState = Get-BBOXInformation -UrlToGo $UrlToGo
        $Enable                    = $(Get-State -State $CloudSynchronisationState.$APIName.enable)
        $Status                    = $(Get-Status -Status $CloudSynchronisationState.$APIName.status)
        $Authorized                = $(Get-YesNoAsk -YesNoAsk $CloudSynchronisationState.$APIName.authorized)
        $Datelastsave              = $(Edit-Date -Date $CloudSynchronisationState.$APIName.datelastsave)
        $Datelastrestore           = $(Edit-Date -Date $CloudSynchronisationState.$APIName.datelastrestore)
        If ([string]::IsNullOrEmpty($Datelastrestore)) {$Datelastrestore = "Never"}
        
        Write-Log -Type WARNING -Category 'Program run' -Name 'Get Box Configuration Save' -Message 'No local backups were found'
        
        Write-Log -Type INFONO -Category 'Program run' -Name 'Get Box Configuration Save' -Message 'Checking Box cloud save synchronisation state : '
        Write-Log -Type VALUE -Category 'Program run' -Name 'Get Box Configuration Save' -Message $Enable
        
        Write-Log -Type INFONO -Category 'Program run' -Name 'Get Box Configuration Save' -Message 'Checking Box cloud save synchronisation status : '
        Write-Log -Type VALUE -Category 'Program run' -Name 'Get Box Configuration Save' -Message $Status
        
        Write-Log -Type INFONO -Category 'Program run' -Name 'Get Box Configuration Save' -Message 'Checking Box cloud save synchronisation user consent : '
        Write-Log -Type VALUE -Category 'Program run' -Name 'Get Box Configuration Save' -Message $Authorized
        
        Write-Log -Type INFONO -Category 'Program run' -Name 'Get Box Configuration Save' -Message 'Last Time Box Configuration save to the cloud : '
        Write-Log -Type VALUE -Category 'Program run' -Name 'Get Box Configuration Save' -Message $Datelastsave
        
        Write-Log -Type INFONO -Category 'Program run' -Name 'Get Box Configuration Save' -Message 'Last Time Box Configuration restored from the cloud : '
        If ($Datelastrestore) {Write-Log -Type VALUE -Category 'Program run' -Name 'Get Box Configuration Save' -Message $Datelastrestore}
        Else {Write-Log -Type VALUE -Category 'Program run' -Name 'Get Box Configuration Save' -Message ''}
        
        $Message = "No local backups in Box configuration were found.`nBox cloud save synchronisation settings :
        - State : $Enable
        - Status : $Status
        - User Consent for Cloud Synchronisation : $Authorized
        - Last Cloud Synchronisation : $Datelastsave
        - Last Cloud Restoration : $Datelastrestore
        "
        
        If ($global:TriggerExportConfig -eq $false) {
            
            Show-WindowsFormDialogBox -Title 'Program run - Get Box Configuration Save' -Message $Message -WarnIcon
        }
    }
}

#endregion BACKUP

#region USERSAVE

Function Get-BBOXUSERSAVE {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Calculate Values
    If ($Json.datelastrestore) {$DateLastRestore = $(Edit-Date -Date $Json.datelastrestore)}
    Else {$DateLastRestore = 'Never'}
    If ($Json.restorefromfactory) {$RestoreFromFactory = $Json.restorefromfactory}
    Else {$RestoreFromFactory = 'Never'}

    
    # Create New PSObject and add values to array
    $UsersaveLine = New-Object -TypeName PSObject
    $UsersaveLine | Add-Member -Name 'Service'                 -MemberType Noteproperty -Value $APIName
    $UsersaveLine | Add-Member -Name 'State'                   -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $UsersaveLine | Add-Member -Name 'Status'                  -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $UsersaveLine | Add-Member -Name 'Boots Number'            -MemberType Noteproperty -Value $Json.numberofboots # Since Version : 19.2.12
    $UsersaveLine | Add-Member -Name 'Last Restore date'       -MemberType Noteproperty -Value $DateLastRestore
    $UsersaveLine | Add-Member -Name 'Last Date Save'          -MemberType Noteproperty -Value $(Edit-Date -Date $Json.datelastsave)
    $UsersaveLine | Add-Member -Name 'Restore From Factory'    -MemberType Noteproperty -Value $RestoreFromFactory
    $UsersaveLine | Add-Member -Name 'Delay'                   -MemberType Noteproperty -Value $Json.delay
    $UsersaveLine | Add-Member -Name 'Allow Cloud Sync ?'      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.authorized) # Since Version : 19.2.12
    $UsersaveLine | Add-Member -Name 'Never Synced ?'          -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.neversynced) # Since Version : 19.2.12
    
    # Add lines to $Array
    $Array += $UsersaveLine
    
    Return $Array
}

#endregion USERSAVE

#region CPL

Function Get-BBOXCPL {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.cpl
    
    # Create New PSObject and add values to array
    $CPLLine = New-Object -TypeName PSObject
    $CPLLine | Add-Member -Name 'Service'       -MemberType Noteproperty -Value "CPL"
    $CPLLine | Add-Member -Name 'State'         -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.running)
    $CPLLine | Add-Member -Name 'Devices Count' -MemberType Noteproperty -Value $($Json.list.count)
    
    # Add lines to $Array
    $Array += $CPLLine
    
    Return $Array
}

Function Get-BBOXCPLDeviceList {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.cpl.list
    
    If ($Json.cpl.list.count -ne 0) {
        
        $Index = 0
        While ($Index -ne $Json.cpl.list.count.count) {
            # Create New PSObject and add values to array
            $CPLLine = New-Object -TypeName PSObject
            $CPLLine | Add-Member -Name 'Master ID'                -MemberType Noteproperty -Value $Json[$Index].list.id
            $CPLLine | Add-Member -Name 'Master MACAddress'        -MemberType Noteproperty -Value $Json[$Index].list.macaddress
            $CPLLine | Add-Member -Name 'Master Manufacturer'      -MemberType Noteproperty -Value $Json[$Index].list.manufacturer
            $CPLLine | Add-Member -Name 'Master Speed'             -MemberType Noteproperty -Value $Json[$Index].list.speed
            $CPLLine | Add-Member -Name 'Master Chipset'           -MemberType Noteproperty -Value $Json[$Index].list.chipset
            $CPLLine | Add-Member -Name 'Master Version'           -MemberType Noteproperty -Value $Json[$Index].list.version
            $CPLLine | Add-Member -Name 'Master Port'              -MemberType Noteproperty -Value $Json[$Index].list.port
            
            If (-not ([string]::IsNullOrEmpty($Json[$Index].list.active))) {
                $CPLLine | Add-Member -Name 'Master State'         -MemberType Noteproperty -Value (Get-State -State $Json[$Index].list.active)
                $CPLLine | Add-Member -Name 'Plug State'           -MemberType Noteproperty -Value (Get-State -State $Json[$Index].list.associateddevice.active)
            }
            Else {
                $CPLLine | Add-Member -Name 'Master State'        -MemberType Noteproperty -Value ''
                $CPLLine | Add-Member -Name 'Plug State'          -MemberType Noteproperty -Value ''
            }
            
            $CPLLine | Add-Member -Name 'Plug MAC Address'         -MemberType Noteproperty -Value $Json[$Index].list.associateddevice.macaddress
            $CPLLine | Add-Member -Name 'Plug Manufacturer'        -MemberType Noteproperty -Value $Json[$Index].list.associateddevice.manufacturer
            $CPLLine | Add-Member -Name 'Plug Chipset'             -MemberType Noteproperty -Value $Json[$Index].list.associateddevice.chipset
            $CPLLine | Add-Member -Name 'Plug Speed'               -MemberType Noteproperty -Value $Json[$Index].list.associateddevice.speed
            $CPLLine | Add-Member -Name 'Plug Version'             -MemberType Noteproperty -Value $Json[$Index].list.associateddevice.version
            $CPLLine | Add-Member -Name 'End Stations MAC Address' -MemberType Noteproperty -Value $Json[$Index].list.endstations.macaddress
            
            # Add lines to $Array
            $Array += $CPLLine
                
            # Go to next line
            $Index++
        }
        Return $Array
    }
    Else {
        Return $null
    }
}

#endregion CPL

#region DEVICE

Function Get-BBOXDevice {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    If (-not ([string]::IsNullOrEmpty($Json.temperature.status))) {
        $TemperatureStatus = Get-Status -Status $Json.temperature.status
    }
    Else {
        $TemperatureStatus = ''
    }
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name 'Date'                           -MemberType Noteproperty -Value $(Edit-Date -Date $Json.now)
    $DeviceLine | Add-Member -Name 'Status'                         -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $DeviceLine | Add-Member -Name 'Nb Boots since 1st use'         -MemberType Noteproperty -Value $Json.numberofboots
    $DeviceLine | Add-Member -Name 'Box Model'                      -MemberType Noteproperty -Value $Json.modelname
    $DeviceLine | Add-Member -Name 'Box Model Class'                -MemberType Noteproperty -Value $Json.modelclass # New since version : 23.7.8
    $DeviceLine | Add-Member -Name 'Is GUI password is set ?'       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.user_configured)
    $DeviceLine | Add-Member -Name 'Wifi Optimisation Status'       -MemberType Noteproperty -Value (Get-Status -Status $Json.optimisation)
    $DeviceLine | Add-Member -Name 'Serial Number'                  -MemberType Noteproperty -Value $Json.serialnumber
    $DeviceLine | Add-Member -Name 'Current Temperature (°C)'       -MemberType Noteproperty -Value $Json.temperature.current
    $DeviceLine | Add-Member -Name 'Temperature Status'             -MemberType Noteproperty -Value $TemperatureStatus
    $DeviceLine | Add-Member -Name 'Display Orientation (°)'        -MemberType Noteproperty -Value $Json.display.orientation
    $DeviceLine | Add-Member -Name 'Luminosity Grade (%) '          -MemberType Noteproperty -Value $Json.display.luminosity
    $DeviceLine | Add-Member -Name 'Luminosity Extended Grade (%) ' -MemberType Noteproperty -Value $Json.display.luminosity_extender
    $DeviceLine | Add-Member -Name 'Front Screen Displayed'         -MemberType Noteproperty -Value $Json.display.state
    $DeviceLine | Add-Member -Name 'MAIN Firmware Version'          -MemberType Noteproperty -Value $Json.main.version
    $DeviceLine | Add-Member -Name 'MAIN Firmware Date'             -MemberType Noteproperty -Value $(Edit-Date -Date $Json.main.date)
    $DeviceLine | Add-Member -Name 'RECOVERY Firmware Version'      -MemberType Noteproperty -Value $Json.reco.version
    $DeviceLine | Add-Member -Name 'RECOVERY Firmware Date'         -MemberType Noteproperty -Value $(Edit-Date -Date $Json.reco.date)
    $DeviceLine | Add-Member -Name 'RUNNING Firmware Version'       -MemberType Noteproperty -Value $Json.running.version                 # Missing in online documentation : https://api.bbox.fr/doc/apirouter/index.html
    $DeviceLine | Add-Member -Name 'RUNNING Firmware Date'          -MemberType Noteproperty -Value $(Edit-Date -Date $Json.running.date) # Missing in online documentation : https://api.bbox.fr/doc/apirouter/index.html
    $DeviceLine | Add-Member -Name 'BACKUP Version'                 -MemberType Noteproperty -Value $Json.bcck.version
    $DeviceLine | Add-Member -Name 'BOOTLOADER 1 Version'           -MemberType Noteproperty -Value $Json.ldr1.version
    $DeviceLine | Add-Member -Name 'BOOTLOADER 2 Version'           -MemberType Noteproperty -Value $Json.ldr2.version
    $DeviceLine | Add-Member -Name 'First use date'                 -MemberType Noteproperty -Value $Json.firstusedate
    $DeviceLine | Add-Member -Name 'Last boot Time'                 -MemberType Noteproperty -Value (Get-Date).AddSeconds(- $Json.uptime)
    $DeviceLine | Add-Member -Name 'Up Time'                        -MemberType Noteproperty -Value (Get-Date).AddSeconds(- $Json.uptime)
    $DeviceLine | Add-Member -Name 'IPV4 Status'                    -MemberType Noteproperty -Value (Get-Status -Status $Json.using.ipv4)
    $DeviceLine | Add-Member -Name 'IPV6 Status'                    -MemberType Noteproperty -Value (Get-Status -Status $Json.using.ipv6)
    $DeviceLine | Add-Member -Name 'FTTH Status'                    -MemberType Noteproperty -Value (Get-Status -Status $Json.using.ftth)
    $DeviceLine | Add-Member -Name 'ADSL Status'                    -MemberType Noteproperty -Value (Get-Status -Status $Json.using.adsl)
    $DeviceLine | Add-Member -Name 'VDSL Status'                    -MemberType Noteproperty -Value (Get-Status -Status $Json.using.vdsl)
    $DeviceLine | Add-Member -Name 'is Cellular Enable'             -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.isCellularEnable) # New since version : 23.7.8
    
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

Function Get-BBOXDeviceLog {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.log
    
    $Line = 0
    $Index = 0
    
    While ($Line -lt $Json.count) {
        
        $Date = $(Edit-Date -Date $($Json[$Line].date))
        
        If ((-not (([string]::IsNullOrEmpty($Json[$Line].param)))) -and ($Json[$Line].param -match ';' )) {
            
            $Params = ($Json[$Line].param).split(';')
        }
        
        Switch ($Json[$Line].log) {
            
            CONNTRACK_ERROR            {$Details = "Le nombre de sessions IP est trop élevé : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            CONNTRACK_OK               {$Details = "Le nombre de sessions IP est redevenu normal : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DHCP_POOL_OK               {$Details = "Le dimensionnement de plage DHCP est redevenu suffisant : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            DHCP_POOL_TOO_SMALL        {$Details = "Le dimensionnement de plage DHCP est trop petit : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            MEMORY_ERROR               {$Details = "Le taux d'utilisation de la mémoire est trop élevé : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            MEMORY_OK                  {$Details = "Le taux d'utilisation de la mémoire est redevenu normal : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }            
            
            DEVICE_NEW                 {$Details = "Un nouveau périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) à été ajouté sur le réseau"
                                        $LogType = 'Périphérique'
                                        Break
                                       }
            
            DEVICE_UP                  {$Details = "Connexion du périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) sur le réseau"
                                        $LogType = 'Périphérique'
                                        Break
                                       }
            
            DEVICE_DOWN                {$Details = "Déconnexion du périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) sur le réseau"
                                        $LogType = 'Périphérique'
                                        Break
                                       }
            
            DHCLIENT_ACK               {$Details = "Assignation d'une adresse IP : $($Json[$Line].param)"
                                        $LogType = 'Réseau'
                                        Break
                                       }
            
            DHCLIENT_REQUEST           {$Details = "Réception d'une requête de la part d'un client : $($Json[$Line].param)"
                                        $LogType = 'Réseau'
                                        Break
                                       }
            
            DHCLIENT_DISCOVER          {$Details = "Envoie d'une requête en brodcast : $($Json[$Line].param)"
                                        $LogType = 'Réseau'
                                        Break
                                       }
            
            DIAG_DNS_FAILURE           {$Details = "Echec des tests d'autodiagnostic DNS : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DIAG_DNS_SUCCESS           {$Details = "Tests d'autodiagnostic DNS réussis : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DIAG_HTTP_FAILURE          {$Details = "Echec des tests d'autodiagnostic HTTP : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DIAG_HTTP_SUCCESS          {$Details = "Tests d'autodiagnostic HTTP réussis : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DIAG_PING_FAILURE          {$Details = "Echec des tests d'autodiagnostic PING : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DIAG_PING_SUCCESS          {$Details = "Tests d'autodiagnostic PING réussis : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DIAG_TIMEOUT               {$Details = "Tests d'autodiagnostic d'accès Internet expirés : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DIAG_FAILURE               {$Details = "Echec des tests d'autodiagnostic d'accès Internet : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DIAG_SUCCESS               {$Details = "Diagnostic réalisé avec succès : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DISPLAY_STATE              {$Details = "Changement d'état de la Box : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            DSL_DOWN                   {$Details = "Ligne DSL désynchronisée : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DSL_EXCHANGE               {$Details = "Synchronisation DSL en cours : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            DSL_UP                     {$Details = "Signal DSL acquis. En attente d'obtention de l'adresse IP publique : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            LAN_OFFLINE_IP             {$Details = "IP Address Source : $($Params[0]), Hostname : $($Params[2]), IP Address destination : $($Params[1])"
                                        $LogType = 'Réseau'
                                        Break
                                       }
            
            LAN_PORT_UP                {$Details = "Un ou plusieurs équipements ont été connecté sur le port : $($Json[$Line].param) du switch de la box"
                                        $LogType = 'Réseau'
                                        Break
                                       }
            
            LAN_PORT_DOWN              {$Details = "Plus aucun équipement n'est connecté sur le port : $($Json[$Line].param) du switch de la box"
                                        $LogType = 'Réseau'
                                        Break
                                       }
            
            LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Hostname : $($Params[2]), IP Address in conflict : $($Params[1])"
                                        $LogType = 'Réseau'
                                        Break
                                       }
            
            LAN_BAD_SUBNET             {$Details = "L'équipement : $($Params[2]) ayant pour adresse Mac : $($Params[0]) et pour adresse IP : $($Params[1]), n'est pas sur le bon sous-réseau"
                                        $LogType = 'Réseau'
                                        Break
                                       }
            
            LAN_DUPLICATE_IP           {$Details = "Les 2 équipements ayant respectivements les MAC Address  et Hostname : $($Params[0]) - $($Params[3]) et pour Hostname : $($Params[1]) - $($Params[4]), sont en conflits car ils ont la même IP Address : $($Params[2]),"
                                        $LogType = 'Réseau'
                                        Break
                                       }
            
            LOGIN_LOCAL                {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0])"
                                        $LogType = 'Administration'
                                        Break
                                       }
            
            LOGIN_LOCAL_FAILED         {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a échoué"
                                        $LogType = 'Administration'
                                        Break
                                       }
            
            LOGIN_LOCAL_LOCKED         {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a été bloqué"
                                        $LogType = 'Administration'
                                        Break
                                       }
            
            LOGIN_REMOTE               {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0])"
                                        $LogType = 'Administration'
                                        Break
                                       }
            
            LOGIN_REMOTE_FAILED        {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a échoué"
                                        $LogType = 'Administration'
                                        Break
                                       }
            
            LOGIN_REMOTE_LOCKED        {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a été bloqué"
                                        $LogType = 'Administration'
                                        Break
                                       }
            
            LOGIN_CDC                  {$Details = "Accès distant à l'interface d'administration par le service client Bouygues Telecom depuis l'adresse IP : $($Params[0])"
                                        $LogType = 'Administration'
                                        Break
                                       }
            
            USER_CHANGEPWD             {$Details = "Changement du mot de passe d'administration de la Box : $($Json[$Line].param))"
                                        $LogType = 'Réseau local'
                                        Break
                                       }
            
            MAIL_ERROR                 {$Details = "Erreur lors de l'envoi d'un e-mail de notification à l'adresse mail : $($Json[$Line].param)"
                                        $LogType = 'Notification'
                                        Break
                                       }
            
            MAIL_SENT                  {$Details = "Envoi d'un e-mail de notification à l'adresse mail : $($Json[$Line].param)"
                                        $LogType = 'Notification'
                                        Break
                                       }
            
            NTP_SYNCHRONIZATION        {$Details = "L'heure et la date ont été obtenues - Synchronisation du temps : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            VOIP_DIAG_ECHOTEST_OFF     {$Details = "Test d'écho arrêté : $($Json[$Line].param)"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_DIAG_ECHOTEST_ON      {$Details = "Test d'écho démarré : $($Json[$Line].param)"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_DIAG_RINGTEST_OFF     {$Details = "Test de sonnerie arrêté : $($Json[$Line].param)"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_DIAG_RINGTEST_ON      {$Details = "Test de sonnerie démarré : $($Json[$Line].param)"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_INCOMING_CALL_RINGING {$Details = "Appel en cours du : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_INCOMING_CALL_MISSED  {$Details = "Appel entrant manqué du : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_INCOMING_CALL_START   {$Details = "Communication entrante en cours avec le : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_INCOMING_CALL_END     {$Details = "Communication entrante terminée avec le : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_OUTGOING_CALL_START   {$Details = "Communication sortante en cours avec le : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_OUTGOING_CALL_END     {$Details = "Communication entrante terminée avec le : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_MWI                   {$Details = "Il y a : $($Params[1]) message(s) vocal/aux sur la ligne : $($Params[0])"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_ONHOOK                {$Details = "Téléphone raccroché sur la ligne : $(Get-Phoneline -Phoneline $Json[$Line].param)"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_OFFHOOK               {$Details = "Téléphone décroché sur la ligne : $(Get-Phoneline -Phoneline $Json[$Line].param)"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_REGISTERED            {$Details = "La ligne téléphonique est active : $($Json[$Line].param)"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            VOIP_UNREGISTERED          {$Details = "La ligne téléphonique n'est pas active : $($Json[$Line].param)"
                                        $LogType = 'Téléphonie'
                                        Break
                                       }
            
            WAN_DOWN                   {$Details = "Accès Internet indisponible : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            WAN_UP                     {$Details = "Accès Internet disponible : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            WAN_ROUTE_ADDED            {$Details = "Ajout nouvelle règle de routage sur l'adresse IP : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            WAN_ROUTE_REMOVED          {$Details = "Suppression règle de routage sur l'adresse IP : $($Json[$Line].param)"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            WAN_UPNP_ADD               {$Details = "Ajout d'une règle NAT sur le port externe : $($Params[2]) vers l'adresse IP : $($Params[0]) sur le port local : $($Params[1]) via UPnP "
                                        $LogType = 'Utilisation du réseau'
                                        Break
                                       }
            
            WAN_UPNP_REMOVE            {$Details = "Suppression de la règle NAT du port externe : $($Params[1]) vers l'adresse IP : $($Params[0]) via UPnP"
                                        $LogType = 'Utilisation du réseau'
                                        Break
                                       }
            
            WIFI_UP                    {$Details = "Wifi activé : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            WIFI_DOWN                  {$Details = "Wifi désactivé : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            WIFI_SSID_24               {$Details = "Changement de nom du réseau Wi-Fi 2.4 GHz : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            WIFI_SSID_5                {$Details = "Changement de nom du réseau Wi-Fi 5 GHz : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            WIFI_PWD_24                {$Details = "Changement du mot de passe Wi-Fi 2.4 GHz : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            WIFI_PWD_5                 {$Details = "Changement du mot de passe Wi-Fi 5 GHz : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            PPP_BOUND                  {$Details = "Obtention d'adresse IP via PPP : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            PPP_FAIL                   {$Details = "Echec d'btention d'adresse IP via PPP : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            SCHEDULER_PARENTAL_DISABLE{$Details = "Contrôle d'accès désactivé : $($Json[$Line].param)"
                                        $LogType = 'Utilisation du réseau'
                                        Break
                                       }
            
            SCHEDULER_PARENTAL_ENABLE  {$Details = "Contrôle d'accès activé : $($Json[$Line].param)"
                                        $LogType = 'Utilisation du réseau'
                                        Break
                                       }
            
            SCHEDULER_PARENTAL_RUNNING {$Details = "Contrôle d'accès e cours : $($Json[$Line].param)"
                                        $LogType = 'Utilisation du réseau'
                                        Break
                                       }
            
            SCHEDULER_PARENTAL_STOPPING{$Details = "Contrôle d'accès arrêté : $($Json[$Line].param)"
                                        $LogType = 'Utilisation du réseau'
                                        Break
                                       }
            
            SCHEDULER_WIFI_DISABLE     {$Details = "Gestion des plages horaires Wi-Fi désactivé : $($Json[$Line].param)"
                                        $LogType = 'Utilisation du réseau'
                                        Break
                                       }
            
            SCHEDULER_WIFI_ENABLE      {$Details = "Gestion des plages horaires Wi-Fi activée : $($Json[$Line].param)"
                                        $LogType = 'Utilisation du réseau'
                                        Break
                                       }
            
            UPGRADE_MAIN_FINISH        {$Details = "Mise à jour du logiciel de la Box réussie (firmware opérationnel) : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            UPGRADE_MAIN_FINISH_FAILED {$Details = "Echec de la mise à jour du logiciel de la Box (firmware opérationnel) : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            UPGRADE_START              {$Details = "Mise à jour du logiciel de la Box en cours (firmware opérationnel) : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            USB_PRINTER_PLUG           {$Details = "Connexion d'une imprimante USB : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            USB_PRINTER_UNPLUG         {$Details = "Déconnexion d'une imprimante USB : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            USB_STORAGE_MOUNT          {$Details = "Partition d'une clé ou d'un disque USB montée : $($Params[0]) sur le port USB : $($Params[1])"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            USB_STORAGE_MOUNT_RW       {$Details = "Droits de lecture et écriture sur la partition : $($Params[0]) sur le port USB : $($Params[1])"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            USB_STORAGE_PLUG           {$Details = "Branchement d'un périphérique de stockage USB : $($Params[0]) ayant pour désignation : $($Params[1])"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            USB_STORAGE_UMOUNT         {$Details = "Partition d'une clé ou d'un disque USB démontée : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            USB_STORAGE_UNPLUG         {$Details = "Déconnexion d'un périphérique de stockage USB : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            Default                    {$Details = $Json[$Line].param
                                        $LogType = 'Unknow / Dev error'
                                        Break
                                       }
        }
        
        # Create New PSObject and add values to array
        $LogLine = New-Object -TypeName PSObject
        $LogLine | Add-Member -Name 'ID'           -MemberType Noteproperty -Value $Index
        $LogLine | Add-Member -Name 'Date'         -MemberType Noteproperty -Value $Date
        $LogLine | Add-Member -Name 'Log type'     -MemberType Noteproperty -Value $LogType
        $LogLine | Add-Member -Name 'Log Category' -MemberType Noteproperty -Value $Json[$Line].log
        $LogLine | Add-Member -Name 'Details'      -MemberType Noteproperty -Value $Details
        
        # Add lines to $Array
        $Array += $LogLine
        
        # Go to next line
        $Line ++
        $Index ++
    }
    
    Return $Array
}

Function Get-BBOXDeviceFullLog {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    $Pageid = 1
    $Index = 0
    
    While ($Json.exception.code -ne '404') {
        
        # Select $JSON header
        $Json = $Json.log
        
        $Line = 0
        
        While ($Line -lt $Json.count) {
            
            $Date = $(Edit-Date -Date $Json[$Line].date)
            
            If ((-not (([string]::IsNullOrEmpty($Json[$Line].param)))) -and ($Json[$Line].param -match ';')) {
                
                $Params = ($Json[$Line].param).split(';')
            }
            
            Switch ($Json[$Line].log) {
            
                CONNTRACK_ERROR            {$Details = "Le nombre de sessions IP est trop élevé : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                CONNTRACK_OK               {$Details = "Le nombre de sessions IP est redevenu normal : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DHCP_POOL_OK               {$Details = "Le dimensionnement de plage DHCP est redevenu suffisant : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                DHCP_POOL_TOO_SMALL        {$Details = "Le dimensionnement de plage DHCP est trop petit : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                MEMORY_ERROR               {$Details = "Le taux d'utilisation de la mémoire est trop élevé : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                MEMORY_OK                  {$Details = "Le taux d'utilisation de la mémoire est redevenu normal : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }            
                
                DEVICE_NEW                 {$Details = "Un nouveau périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) à été ajouté sur le réseau"
                                            $LogType = 'Périphérique'
                                            Break
                                           }
                
                DEVICE_UP                  {$Details = "Connexion du périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) sur le réseau"
                                            $LogType = 'Périphérique'
                                            Break
                                           }
                
                DEVICE_DOWN                {$Details = "Déconnexion du périphérique : $($Params[2]), ayant pour adresse IP : $($Params[1]) et l'adresse MAC : $($Params[0]) sur le réseau"
                                            $LogType = 'Périphérique'
                                            Break
                                           }
                
                DHCLIENT_ACK               {$Details = "Assignation d'une adresse IP : $($Json[$Line].param)"
                                            $LogType = 'Réseau'
                                            Break
                                           }
                
                DHCLIENT_REQUEST           {$Details = "Réception d'une requête de la part d'un client : $($Json[$Line].param)"
                                            $LogType = 'Réseau'
                                            Break
                                           }
                
                DHCLIENT_DISCOVER          {$Details = "Envoie d'une requête en brodcast : $($Json[$Line].param)"
                                            $LogType = 'Réseau'
                                            Break
                                           }
                
                DIAG_DNS_FAILURE           {$Details = "Echec des tests d'autodiagnostic DNS : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DIAG_DNS_SUCCESS           {$Details = "Tests d'autodiagnostic DNS réussis : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DIAG_HTTP_FAILURE          {$Details = "Echec des tests d'autodiagnostic HTTP : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DIAG_HTTP_SUCCESS          {$Details = "Tests d'autodiagnostic HTTP réussis : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DIAG_PING_FAILURE          {$Details = "Echec des tests d'autodiagnostic PING : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DIAG_PING_SUCCESS          {$Details = "Tests d'autodiagnostic PING réussis : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DIAG_TIMEOUT               {$Details = "Tests d'autodiagnostic d'accès Internet expirés : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DIAG_FAILURE               {$Details = "Echec des tests d'autodiagnostic d'accès Internet : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DIAG_SUCCESS               {$Details = "Diagnostic réalisé avec succès : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DISPLAY_STATE              {$Details = "Changement d'Ã©tat de la Box : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                DSL_DOWN                   {$Details = "Ligne DSL désynchronisée : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DSL_EXCHANGE               {$Details = "Synchronisation DSL en cours : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                DSL_UP                     {$Details = "Signal DSL acquis. En attente d'obtention de l'adresse IP publique : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                LAN_OFFLINE_IP             {$Details = "IP Address Source : $($Params[0]), Hostname : $($Params[2]), IP Address destination : $($Params[1])"
                                            $LogType = 'Réseau'
                                            Break
                                           }
                
                LAN_PORT_UP                {$Details = "Un ou plusieurs équipements ont été connecté sur le port : $($Json[$Line].param) du switch de la box"
                                            $LogType = 'Réseau'
                                            Break
                                           }
                
                LAN_PORT_DOWN              {$Details = "Plus aucun équipement n'est connecté sur le port : $($Json[$Line].param) du switch de la box"
                                            $LogType = 'Réseau'
                                            Break
                                           }
                
                LAN_BAD_SUBNET             {$Details = "L'équipement : $($Params[2]) ayant pour adresse Mac : $($Params[0]) et pour adresse IP : $($Params[1]), n'est pas sur le bon sous-réseau"
                                            $LogType = 'Réseau'
                                            Break
                                           }
                
                LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Hostname : $($Params[2]), IP Address in conflict : $($Params[1])"
                                            $LogType = 'Réseau'
                                            Break
                                           }
                
                LAN_DUPLICATE_IP           {$Details = "Les 2 équipements ayant respectivements les MAC Address  et Hostname : $($Params[0]) - $($Params[3]) et pour Hostname : $($Params[1]) - $($Params[4]), sont en conflits car ils ont la même IP Address : $($Params[2]),"
                                            $LogType = 'Réseau'
                                            Break
                                           }
                
                LOGIN_LOCAL                {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0])"
                                            $LogType = 'Administration'
                                            Break
                                           }
                
                LOGIN_LOCAL_FAILED         {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a échoué"
                                            $LogType = 'Administration'
                                            Break
                                           }
                
                LOGIN_LOCAL_LOCKED         {$Details = "Accès local à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a été bloqué"
                                            $LogType = 'Administration'
                                            Break
                                           }
                
                LOGIN_REMOTE               {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0])"
                                            $LogType = 'Administration'
                                            Break
                                           }
                
                LOGIN_REMOTE_FAILED        {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a échoué"
                                            $LogType = 'Administration'
                                            Break
                                           }
                
                LOGIN_REMOTE_LOCKED        {$Details = "Accès distant à l'interface d'administration depuis l'équipement : $($Params[1]), ayant l'adresse IP : $($Params[0]) a été bloqué"
                                            $LogType = 'Administration'
                                            Break
                                           }
                
                LOGIN_CDC                  {$Details = "Accès distant à l'interface d'administration par le service client Bouygues Telecom depuis l'adresse IP : $($Params[0])"
                                            $LogType = 'Administration'
                                            Break
                                           }
                
                USER_CHANGEPWD             {$Details = "Changement du mot de passe d'administration de la Box : $($Json[$Line].param))"
                                            $LogType = 'Réseau local'
                                            Break
                                           }
                
                MAIL_ERROR                 {$Details = "Erreur lors de l'envoi d'un e-mail de notification à l'adresse mail : $($Json[$Line].param)"
                                            $LogType = 'Notification'
                                            Break
                                           }
                
                MAIL_SENT                  {$Details = "Envoi d'un e-mail de notification à l'adresse mail : $($Json[$Line].param)"
                                            $LogType = 'Notification'
                                            Break
                                           }
                
                NTP_SYNCHRONIZATION        {$Details = "L'heure et la date ont été obtenues - Synchronisation du temps : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                VOIP_DIAG_ECHOTEST_OFF     {$Details = "Test d'écho arrêté : $($Json[$Line].param)"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_DIAG_ECHOTEST_ON      {$Details = "Test d'écho démarré : $($Json[$Line].param)"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_DIAG_RINGTEST_OFF     {$Details = "Test de sonnerie arrêté : $($Json[$Line].param)"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_DIAG_RINGTEST_ON      {$Details = "Test de sonnerie démarré : $($Json[$Line].param)"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_INCOMING_CALL_RINGING {$Details = "Appel en cours du : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_INCOMING_CALL_MISSED  {$Details = "Appel entrant manqué du : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_INCOMING_CALL_START   {$Details = "Communication entrante en cours avec le : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_INCOMING_CALL_END     {$Details = "Communication entrante terminée avec le : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_OUTGOING_CALL_START   {$Details = "Communication sortante en cours avec le : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_OUTGOING_CALL_END     {$Details = "Communication entrante terminée avec le : $($Params[1]) sur la ligne : $(Get-Phoneline -Phoneline $Params[0])"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_MWI                   {$Details = "Il y a : $($Params[1]) message(s) vocal/aux sur la ligne : $($Params[0])"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_ONHOOK                {$Details = "Téléphone raccroché sur la ligne : $(Get-Phoneline -Phoneline $Json[$Line].param)"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_OFFHOOK               {$Details = "Téléphone décroché sur la ligne : $(Get-Phoneline -Phoneline $Json[$Line].param)"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_REGISTERED            {$Details = "La ligne téléphonique est active : $($Json[$Line].param)"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                VOIP_UNREGISTERED          {$Details = "La ligne téléphonique n'est pas active : $($Json[$Line].param)"
                                            $LogType = 'Téléphonie'
                                            Break
                                           }
                
                WAN_DOWN                   {$Details = "Accès Internet indisponible : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                WAN_UP                     {$Details = "Accès Internet disponible : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                WAN_ROUTE_ADDED            {$Details = "Ajout nouvelle règle de routage sur l'adresse IP : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                WAN_ROUTE_REMOVED          {$Details = "Suppression règle de routage sur l'adresse IP : $($Json[$Line].param)"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                WAN_UPNP_ADD               {$Details = "Ajout d'une règle NAT sur le port externe : $($Params[2]) vers l'adresse IP : $($Params[0]) sur le port local : $($Params[1]) via UPnP "
                                            $LogType = 'Utilisation du réseau'
                                            Break
                                           }
                
                WAN_UPNP_REMOVE            {$Details = "Suppression de la règle NAT du port externe : $($Params[1]) vers l'adresse IP : $($Params[0]) via UPnP"
                                            $LogType = 'Utilisation du réseau'
                                            Break
                                           }
                
                WIFI_UP                    {$Details = "Wifi activé : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                WIFI_DOWN                  {$Details = "Wifi désactivé : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                WIFI_SSID_24               {$Details = "Changement de nom du réseau Wi-Fi 2.4 GHz : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                WIFI_SSID_5                {$Details = "Changement de nom du réseau Wi-Fi 5 GHz : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                WIFI_PWD_24                {$Details = "Changement du mot de passe Wi-Fi 2.4 GHz : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                WIFI_PWD_5                 {$Details = "Changement du mot de passe Wi-Fi 5 GHz : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                PPP_BOUND                  {$Details = "Obtention d'adresse IP via PPP : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                PPP_FAIL                   {$Details = "Echec d'btention d'adresse IP via PPP : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                SCHEDULER_PARENTAL_DISABLE {$Details = "Contrôle d'accès désactivé : $($Json[$Line].param)"
                                            $LogType = 'Utilisation du réseau'
                                            Break
                                           }
                
                SCHEDULER_PARENTAL_ENABLE  {$Details = "Contrôle d'accès activé : $($Json[$Line].param)"
                                            $LogType = 'Utilisation du réseau'
                                            Break
                                           }
                
                SCHEDULER_PARENTAL_RUNNING {$Details = "Contrôle d'accès e cours : $($Json[$Line].param)"
                                            $LogType = 'Utilisation du réseau'
                                            Break
                                           }
                
                SCHEDULER_PARENTAL_STOPPING{$Details = "Contrôle d'accès arrêté : $($Json[$Line].param)"
                                            $LogType = 'Utilisation du réseau'
                                            Break
                                           }
                
                SCHEDULER_WIFI_DISABLE     {$Details = "Gestion des plages horaires Wi-Fi désactivé : $($Json[$Line].param)"
                                            $LogType = 'Utilisation du réseau'
                                            Break
                                           }
                
                SCHEDULER_WIFI_ENABLE      {$Details = "Gestion des plages horaires Wi-Fi activée : $($Json[$Line].param)"
                                            $LogType = 'Utilisation du réseau'
                                            Break
                                           }
                
                UPGRADE_MAIN_FINISH        {$Details = "Mise à jour du logiciel de la Box réussie (firmware opérationnel) : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                UPGRADE_MAIN_FINISH_FAILED {$Details = "Echec de la mise à jour du logiciel de la Box (firmware opérationnel) : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                UPGRADE_START              {$Details = "Mise à jour du logiciel de la Box en cours (firmware opérationnel) : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                USB_PRINTER_PLUG           {$Details = "Connexion d'une imprimante USB : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                USB_PRINTER_UNPLUG         {$Details = "Déconnexion d'une imprimante USB : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                USB_STORAGE_MOUNT          {$Details = "Partition d'une clé ou d'un disque USB montée : $($Params[0]) sur le port USB : $($Params[1])"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                USB_STORAGE_MOUNT_RW       {$Details = "Droits de lecture et écriture sur la partition : $($Params[0]) sur le port USB : $($Params[1])"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                USB_STORAGE_PLUG           {$Details = "Branchement d'un périphérique de stockage USB : $($Params[0]) ayant pour désignation : $($Params[1])"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                USB_STORAGE_UMOUNT         {$Details = "Partition d'une clé ou d'un disque USB démontée : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                USB_STORAGE_UNPLUG         {$Details = "Déconnexion d'un périphérique de stockage USB : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                Default                    {$Details = $Json[$Line].param
                                            $LogType = "Unknow / Dev error"
                                            Break
                                           }
            }
            
            # Create New PSObject and add values to array
            $LogLine = New-Object -TypeName PSObject
            $LogLine | Add-Member -Name 'ID'           -MemberType Noteproperty -Value $Index
            $LogLine | Add-Member -Name 'Date'         -MemberType Noteproperty -Value $Date
            $LogLine | Add-Member -Name 'Log type'     -MemberType Noteproperty -Value $LogType
            $LogLine | Add-Member -Name 'Log Category' -MemberType Noteproperty -Value $Json[$Line].log
            $LogLine | Add-Member -Name 'Details'      -MemberType Noteproperty -Value $Details
            
            # Add lines to $Array
            $Array += $LogLine
            
            # Go to next line
            $Line ++
            $Index ++
        }
        
        # Get the next page
        $Pageid ++
        
        # Get information from Box API
        $Json = Get-BBOXInformation -UrlToGo "$UrlToGo/$Pageid"
    }
    
    Return $Array
}

Function Get-BBOXDeviceFullTechnicalLog {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    $Pageid = 1
    $Index = 0
    
    While ($Json.exception.code -ne '404') {
        
        # Select $JSON header
        $Json = $Json.log
        
        $Line = 1
        
        While ($Line -lt $Json.count) {
            
            $Date = $(Edit-Date -Date $Json[$Line].date)
            
            If ((-not (([string]::IsNullOrEmpty($Json[$Line].param)))) -and ($Json[$Line].param -match ';')) {
                
                $Params = ($Json[$Line].param).split(';')
            }
            
            Switch ($Json[$Line].log) {
                
                DEVICE_NEW                 {$Details = "Hostname : $($Params[2]), IP Address : $($Params[1]), MAC Address : $($Params[0])";Break}
                
                DEVICE_UP                  {$Details = "Hostname : $($Params[2]), IP Address : $($Params[1]), MAC Address : $($Params[0])";Break}
                
                DEVICE_DOWN                {$Details = "Hostname : $($Params[2]), IP Address : $($Params[1]), MAC Address : $($Params[0])";Break}
                
                DHCLIENT_ACK               {$Details = $Json[$Line].param;Break}
                
                DHCLIENT_REQUEST           {$Details = $Json[$Line].param;Break}
                
                DHCLIENT_DISCOVER          {$Details = $Json[$Line].param;Break}
                
                DIAG_FAILURE               {$Details = $Json[$Line].param;Break}
                
                DIAG_SUCCESS               {$Details = $Json[$Line].param;Break}
                
                DISPLAY_STATE              {$Details = $Json[$Line].param;Break}
                
                LAN_OFFLINE_IP             {$Details = "IP Address Source : $($Params[0]), Hostname : $($Params[2]), IP Address destination : $($Params[1])";Break}
                
                LAN_DUPLICATE_IP           {$Details = "MAC Address Conflict : $($Params[0]) - $($Params[1]), IP Address in conflict : $($Params[2]), Hostname Conflict : $($Params[3]) - $($Params[4])";Break}
                
                LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Hostname : $($Params[2]), IP Address in conflict : $($Params[1])";Break}
                
                LAN_PORT_UP                {$Details = "Box Switch Port : $($Json[$Line].param)";Break}
                
                LAN_BAD_SUBNET             {$Details = "MAC Address :$($Params[0]) ,IP Address : $($Params[1]), Hostname : $($Params[2]),";Break}
                
                LAN_PORT_DOWN              {$Details = "Box Switch Port : $($Json[$Line].param)";Break}
                
                LOGIN_LOCAL                {$Details = "Hostname : $($Params[1]), IP Address : $($Params[0])";Break}
                
                LOGIN_LOCAL_FAILED         {$Details = "Hostname : $($Params[1]), IP Address : $($Params[0])";Break}
                
                LOGIN_REMOTE               {$Details = "Hostname : $($Params[1]), IP Address : $($Params[0])";Break}
                
                LOGIN_REMOTE_FAILED        {$Details = "Hostname : $($Params[1]), IP Address : $($Params[0])";Break}
                
                LOGIN_CDC                  {$Details = "IP Address : $($Params[0])";Break}
                
                MAIL_ERROR                 {$Details = "Mail Address : $($Json[$Line].param)";Break}
                
                MAIL_SENT                  {$Details = "Mail Address : $($Json[$Line].param)";Break}
                
                NTP_SYNCHRONIZATION        {$Details = $Json[$Line].param;Break}
                
                VOIP_INCOMING_CALL_RINGING {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])";Break}
                
                VOIP_INCOMING_CALL_MISSED  {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])";Break}
                
                VOIP_INCOMING_CALL_START   {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])";Break}
                
                VOIP_INCOMING_CALL_END     {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])";Break}
                
                VOIP_OUTGOING_CALL_START   {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])";Break}
                
                VOIP_OUTGOING_CALL_END     {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])";Break}
                
                VOIP_MWI                   {$Details = "Voice Message on line : $($Params[1]), Unread Voice Message Number : $($Params[0])";Break}
                
                VOIP_ONHOOK                {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$Line].param) is available";Break}
                
                VOIP_OFFHOOK               {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$Line].param) is busy";Break}
                
                VOIP_REGISTERED            {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$Line].param)";Break}
                
                VOIP_UNREGISTERED          {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$Line].param)";Break}
                
                WAN_ROUTE_ADDED            {$Details = "IP Address : $($Json[$Line].param)";Break}
                
                WAN_ROUTE_REMOVED          {$Details = "IP Address : $($Json[$Line].param)";Break}
                
                WAN_UPNP_ADD               {$Details = "IP Address : $($Params[0]), Local Port : $($Params[1]), External Port : $($Params[2])";Break}
                
                WAN_UPNP_REMOVE            {$Details = "IP Address : $($Params[0]), External Port : $($Params[1])";Break}
                
                WIFI_UP                    {$Details = $Json[$Line].param;Break}
                
                WIFI_DOWN                  {$Details = $Json[$Line].param;Break}
                
                Default                    {$Details = $Json[$Line].param;Break}
                
            }
            
            # Create New PSObject and add values to array
            $LogLine = New-Object -TypeName PSObject
            $LogLine | Add-Member -Name 'ID'           -MemberType Noteproperty -Value $Index
            $LogLine | Add-Member -Name 'Date'         -MemberType Noteproperty -Value $Date
            $LogLine | Add-Member -Name 'Log Category' -MemberType Noteproperty -Value $Json[$Line].log
            $LogLine | Add-Member -Name 'Details'      -MemberType Noteproperty -Value $Details
            
            # Add lines to $Array
            $Array += $LogLine
            
            # Go to next line
            $Line ++
            $Index ++
        }
        
        # Get the next page
        $Pageid ++
        
        # Get information from Box API
        $Json = Get-BBOXInformation -UrlToGo "$UrlToGo/$Pageid"
    }
    
    Return $Array
}

Function Get-BBOXDeviceConnectionHistoryLog {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    $Pageid = 1
    $Index = 0
    
    While ($Json.exception.code -ne '404') {
        
        # Select $JSON header
        $Json = $Json.log
        
        $Line = 1
        
        While ($Line -lt $Json.count) {
            
            If ($Json[$Line].log -match "DEVICE_UP|DEVICE_DOWN") {
            
                $Date = $(Edit-Date -Date $($Json[$Line].date))
                
                If ((-not (([string]::IsNullOrEmpty($Json[$Line].param)))) -and ($Json[$Line].param -match ';')) {
                    
                    $Params = ($Json[$Line].param).split(';')
                }
                
                # Create New PSObject and add values to array
                $LogLine = New-Object -TypeName PSObject
                $LogLine | Add-Member -Name 'ID'          -MemberType Noteproperty -Value $Index
                $LogLine | Add-Member -Name 'Date'        -MemberType Noteproperty -Value $Date
                $LogLine | Add-Member -Name 'LogCategory' -MemberType Noteproperty -Value $Json[$Line].log
                $LogLine | Add-Member -Name 'MACAddress'  -MemberType Noteproperty -Value $Params[0]
                $LogLine | Add-Member -Name 'IPAddress'   -MemberType Noteproperty -Value $Params[1]
                $LogLine | Add-Member -Name 'Hostname'    -MemberType Noteproperty -Value $Params[2]
                
                # Add lines to $Array
                $Array += $LogLine
            }
            
            # Go to next line
            $Line ++
            $Index ++
        }
        
        # Get the next page
        $Pageid ++
        
        # Get information from Box API
        $Json = Get-BBOXInformation -UrlToGo "$UrlToGo/$Pageid"
    }
    
    $Devices = $Array | Select-Object -Property MACAddress -Unique
    $Output = @()
    $Index = 0
    
    Foreach ($Device in $Devices) {
        
        $DeviceEntriesUp   = $Array | Where-Object {$_.MACAddress -match $Device -and $_.LogCategory -match 'DEVICE_UP'} | Sort-Object -Property Date
        $DeviceEntriesDown = $Array | Where-Object {$_.MACAddress -match $Device -and $_.LogCategory -match 'DEVICE_DOWN'} | Sort-Object -Property Date
        $Count = $DeviceEntriesUp.count
        $CurrentCount = 0
        
        While ($CurrentCount -ne $Count) {
            
            $LogLine = New-Object -TypeName PSObject
            $LogLine | Add-Member -Name 'ID'                   -MemberType Noteproperty -Value $Index
            $LogLine | Add-Member -Name 'Connexion Date Start' -MemberType Noteproperty -Value $DeviceEntriesUp[$CurrentCount].Date
            $LogLine | Add-Member -Name 'Connexion Date End'   -MemberType Noteproperty -Value $DeviceEntriesDown[$CurrentCount].Date
            $LogLine | Add-Member -Name 'MAC Address'          -MemberType Noteproperty -Value $DeviceEntriesUp[$CurrentCount].MACAddress
            $LogLine | Add-Member -Name 'IP Address'           -MemberType Noteproperty -Value $DeviceEntriesUp[$CurrentCount].IPAddress
            $LogLine | Add-Member -Name 'Hostname'             -MemberType Noteproperty -Value $DeviceEntriesUp[$CurrentCount].Hostname
            $Output += $LogLine
            
            $Index ++
            $CurrentCount ++
        }
    }
    
    Return $Output
}

Function Get-BBOXDeviceConnectionHistoryLogID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $DeviceConnectionHistoryLogIDs = Get-BBOXDeviceConnectionHistoryLog -UrlToGo $UrlToGo
    If ($global:TriggerExportConfig -eq $true) {
        $DeviceConnectionHistoryLogID = $DeviceConnectionHistoryLogIDs | Select-Object -Property 'Mac Address',Hostname -Unique -First 1
    }
    Else {
        $DeviceConnectionHistoryLogID = $DeviceConnectionHistoryLogIDs | Select-Object -Property 'Mac Address',Hostname -Unique | Out-GridView -Title "Devices List" -OutputMode Single
    }
    
    $DeviceConnectionHistoryLogHost = $DeviceConnectionHistoryLogIDs | Where-Object {$_.'Mac Address' -like $DeviceConnectionHistoryLogID.'Mac Address'}
    
    Return $DeviceConnectionHistoryLogHost
}

Function Get-BBOXDeviceCpu {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].device.cpu
    
    # Create New PSObject and add values to array
    $LedLine = New-Object -TypeName PSObject
    $LedLine | Add-Member -Name 'Total Time'        -MemberType Noteproperty -Value $Json.time.total
    $LedLine | Add-Member -Name 'User Time'         -MemberType Noteproperty -Value $Json.time.user
    $LedLine | Add-Member -Name 'Nice Time'         -MemberType Noteproperty -Value $Json.time.nice
    $LedLine | Add-Member -Name 'System Time'       -MemberType Noteproperty -Value $Json.time.system
    $LedLine | Add-Member -Name 'IO Time'           -MemberType Noteproperty -Value $Json.time.io
    $LedLine | Add-Member -Name 'Idle Time'         -MemberType Noteproperty -Value $Json.time.idle
    $LedLine | Add-Member -Name 'Irq Time'          -MemberType Noteproperty -Value $Json.time.irq
    $LedLine | Add-Member -Name 'Created processus' -MemberType Noteproperty -Value $Json.process.created
    $LedLine | Add-Member -Name 'Running processus' -MemberType Noteproperty -Value $Json.process.running
    $LedLine | Add-Member -Name 'Blocked processus' -MemberType Noteproperty -Value $Json.process.blocked
    
    # Add lines to $Array
    $Array += $LedLine
    
    Return $Array
}

Function Get-BBOXDeviceMemory {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.device.mem
    
    # Create New PSObject and add values to array
    $MemoryLine = New-Object -TypeName PSObject
    $MemoryLine | Add-Member -Name 'Total Memory'     -MemberType Noteproperty -Value $Json.total
    $MemoryLine | Add-Member -Name 'Free Memory'      -MemberType Noteproperty -Value $Json.free
    $MemoryLine | Add-Member -Name 'Cached Memory'    -MemberType Noteproperty -Value $Json.cached
    $MemoryLine | Add-Member -Name 'Committed Memory' -MemberType Noteproperty -Value $Json.committedas
    
    # Add lines to $Array
    $Array += $MemoryLine
    
    Return $Array
}

Function Get-BBOXDeviceLED {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
        
    # Create New PSObject and add values to array
    
    # Led
    $LedLine = New-Object -TypeName PSObject
    $LedLine | Add-Member -Name 'State Power Led'           -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.power)
    $LedLine | Add-Member -Name 'State Power Red Led'       -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.power_red)
    $LedLine | Add-Member -Name 'State Power Green Led'     -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.power_green)
    $LedLine | Add-Member -Name 'State Wifi Led'            -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.wifi)
    $LedLine | Add-Member -Name 'State Wifi red Led'        -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.wifi_red)
    $LedLine | Add-Member -Name 'State Phone 1 Led'         -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.phone1)
    $LedLine | Add-Member -Name 'State Phone 1 Red Led'     -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.phone1_red)
    $LedLine | Add-Member -Name 'State Phone 2 Led'         -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.phone2)
    $LedLine | Add-Member -Name 'State Phone 2 Red Led'     -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.phone2_red)
    $LedLine | Add-Member -Name 'State WAN Led'             -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.wan)
    $LedLine | Add-Member -Name 'State WAN Red Led'         -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.wan_red)
    
    # Ethernet Switch Port LED State
    $LedLine | Add-Member -Name 'State sw1_1 Led'           -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.sw1_1)
    $LedLine | Add-Member -Name 'State sw1_2 Led'           -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.sw1_2)
    $LedLine | Add-Member -Name 'State sw2_1 Led'           -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.sw2_1)
    $LedLine | Add-Member -Name 'State sw2_2 Led'           -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.sw2_2)
    $LedLine | Add-Member -Name 'State sw3_1 Led'           -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.sw3_1)
    $LedLine | Add-Member -Name 'State sw3_2 Led'           -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.sw3_2)
    $LedLine | Add-Member -Name 'State sw4_1 Led'           -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.sw4_1)
    $LedLine | Add-Member -Name 'State sw4_2 Led'           -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.sw4_2)
    $LedLine | Add-Member -Name 'State phy_1 Led'           -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.phy_1)
    $LedLine | Add-Member -Name 'State phy_2 Led'           -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.led.phy_2)
    
    # Ethernet Switch LED State
    $LedLine | Add-Member -Name 'State Ethernet port 1 Led' -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.ethernetPort[0].state)
    $LedLine | Add-Member -Name 'State Ethernet port 2 Led' -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.ethernetPort[1].state)
    $LedLine | Add-Member -Name 'State Ethernet port 3 Led' -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.ethernetPort[2].state)
    $LedLine | Add-Member -Name 'State Ethernet port 4 Led' -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.ethernetPort[3].state)
    $LedLine | Add-Member -Name 'State Ethernet port 5 Led' -MemberType Noteproperty -Value $(Get-PowerStatus -PowerStatus $Json.ethernetPort[4].state)
    
    # Add lines to $Array
    $Array += $LedLine
    
    Return $Array
}

Function Get-BBOXDeviceSummary {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.device
    
    # Create New PSObject and add values to array
    $SummaryLine = New-Object -TypeName PSObject
    $SummaryLine | Add-Member -Name 'Date'          -MemberType Noteproperty -Value $(Edit-Date -Date $Json.now)
    $SummaryLine | Add-Member -Name 'Status'        -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $SummaryLine | Add-Member -Name 'Default'       -MemberType Noteproperty -Value (Get-Status -Status $Json.default)
    $SummaryLine | Add-Member -Name 'Model'         -MemberType Noteproperty -Value $Json.modelname
    $SummaryLine | Add-Member -Name 'Serial Number' -MemberType Noteproperty -Value $Json.serialnumber
    
    # Add lines to $Array
    $Array += $SummaryLine
    
    Return $Array
}

Function Get-BBOXDeviceToken {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.device
    
    # Convert string value to date time 
    $Date = $Json.now
    $ExpirationDate = $Json.expires
    $TimeLeft = New-TimeSpan -Start $Date -End $ExpirationDate
    
    # Create New PSObject and add values to array
    $TokenLine = New-Object -TypeName PSObject
    $TokenLine | Add-Member -Name 'Date'                  -MemberType Noteproperty -Value $Date
    $TokenLine | Add-Member -Name 'Token'                 -MemberType Noteproperty -Value $Json.token
    $TokenLine | Add-Member -Name 'Token Expiration Date' -MemberType Noteproperty -Value $ExpirationDate
    $TokenLine | Add-Member -Name 'Token Valid Time Left' -MemberType Noteproperty -Value $TimeLeft

    # Add lines to $Array
    $Array += $TokenLine
    
    Return $Array
}

#endregion DEVICE

#region DHCP

Function Get-BBOXDHCP {
        
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $DHCP = New-Object -TypeName PSObject
    $DHCP | Add-Member -Name 'Service'                -MemberType Noteproperty -Value "DHCP"
    $DHCP | Add-Member -Name 'State'                  -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $DHCP | Add-Member -Name 'Status'                 -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $DHCP | Add-Member -Name 'First Range IP Address' -MemberType Noteproperty -Value $Json.minaddress
    $DHCP | Add-Member -Name 'Last Range IP Address'  -MemberType Noteproperty -Value $Json.maxaddress
    $DHCP | Add-Member -Name 'Bail (Secondes)'        -MemberType Noteproperty -Value $Json.leasetime
    $DHCP | Add-Member -Name 'Bail (Minutes)'         -MemberType Noteproperty -Value ($Json.leasetime / 60)
    $DHCP | Add-Member -Name 'Bail (Hours)'           -MemberType Noteproperty -Value ($Json.leasetime / 3600)
    
    # Add lines to $Array
    $Array += $DHCP
    
    Return $Array
}

Function Get-BBOXDHCPClients {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.clients
            
    If ($Json.Count -ne 0) {
        
        $Client = 0
        
        While ($Client -lt $Json.Count) {
            
            $ClientName = New-Object -TypeName PSObject
            $ClientName | Add-Member -Name 'ID'              -MemberType Noteproperty -Value $Json[$Client].ID
            $ClientName | Add-Member -Name 'Device HostName' -MemberType Noteproperty -Value $Json[$Client].HostName
            $ClientName | Add-Member -Name 'IPV4 Address'    -MemberType Noteproperty -Value $Json[$Client].IPAddress
            $ClientName | Add-Member -Name 'IPV6 Address'    -MemberType Noteproperty -Value $Json[$Client].IP6Address
            $ClientName | Add-Member -Name 'MACAddress'      -MemberType Noteproperty -Value $Json[$Client].MACAddress
            $ClientName | Add-Member -Name 'State'           -MemberType Noteproperty -Value (Get-State -State $Json[$Client].enable)
            
            # Add line to $Array
            $Array += $ClientName
            
            # Go to next line
            $Client ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXDHCPClientsID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $DeviceIDs = Get-BBOXDHCPClients -UrlToGo $UrlToGo
    If ($global:TriggerExportConfig -eq $true) {
        $DeviceID = $DeviceIDs | Select-Object -Property ID,'Device HostName' -First 1
    }
    Else {
        $DeviceID = $DeviceIDs | Select-Object -Property ID,'Device HostName' | Out-GridView -Title 'DHCP Client List' -OutputMode Single
    }
    $Device = $DeviceIDs | Where-Object {$_.ID -ilike $DeviceID.id}
    
    Return $Device
}

Function Get-BBOXDHCPActiveOptions {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $OptionsStatic       = $Json.dhcp.optionsstatic
    $OptionsStaticCount  = $OptionsStatic.Count
    $OptionsDynamic      = $Json.dhcp.options
    $OptionsDynamiccount = $OptionsDynamic.count
    
    # Get DHCP Capabilities Options
    $OptionsCapabilities = $Json.dhcp.optionscapabilities
    
    # Set variables
    $LineID = 1
    
    # Add Static DHCP Options
    
    If ($OptionsStaticCount -ne 0) {
        
        $Line = 0
        
        While ($Line -lt $OptionsStaticCount) {
            
            $OptionsCapabilitiesDetails = $OptionsCapabilities | Where-Object {$_.id -ilike $($OptionsStatic[$Line].option)}
            $DataType                   = $OptionsCapabilitiesDetails.type
            $RFC                        = $OptionsCapabilitiesDetails.rfc
            $Description                = $OptionsCapabilitiesDetails.description
            
            # Create New PSObject and add values to array 
            $OptionsStaticLine = New-Object -TypeName PSObject
            $OptionsStaticLine | Add-Member -Name 'LineID'      -MemberType Noteproperty -Value $LineID
            $OptionsStaticLine | Add-Member -Name 'OptionID'    -MemberType Noteproperty -Value $OptionsStatic[$Line].id
            $OptionsStaticLine | Add-Member -Name 'Option'      -MemberType Noteproperty -Value $OptionsStatic[$Line].option
            $OptionsStaticLine | Add-Member -Name 'Value'       -MemberType Noteproperty -Value $OptionsStatic[$Line].value
            $OptionsStaticLine | Add-Member -Name 'Type'        -MemberType Noteproperty -Value 'Static'
            $OptionsStaticLine | Add-Member -Name 'Description' -MemberType Noteproperty -Value $Description
            $OptionsStaticLine | Add-Member -Name 'DataType'    -MemberType Noteproperty -Value $DataType
            $OptionsStaticLine | Add-Member -Name 'RFC'         -MemberType Noteproperty -Value $RFC
            
            # Add lines to $Array
            $Array += $OptionsStaticLine
            
            # Go to next line
            $Line ++
            $LineID ++
        }
    }    
    
    # Add Dynamic DHCP Options
    
    If ($OptionsDynamicCount -ne 0) {
        
        $Line = 0
        
        While ($Line -lt $OptionsDynamicCount) {
            
            $OptionsCapabilitiesDetails = $OptionsCapabilities | Where-Object {$_.id -ilike $($OptionsDynamic[$Line].option)}
            $DataType                   = $OptionsCapabilitiesDetails.type
            $RFC                        = $OptionsCapabilitiesDetails.rfc
            $Description                = $OptionsCapabilitiesDetails.description
            
            # Create New PSObject and add values to array
            $OptionsDynamicLine = New-Object -TypeName PSObject
            $OptionsDynamicLine | Add-Member -Name 'LineID'      -MemberType Noteproperty -Value $LineID
            $OptionsDynamicLine | Add-Member -Name 'OptionID'    -MemberType Noteproperty -Value $OptionsDynamic[$Line].id
            $OptionsDynamicLine | Add-Member -Name 'Option'      -MemberType Noteproperty -Value $OptionsDynamic[$Line].option
            $OptionsDynamicLine | Add-Member -Name 'Value'       -MemberType Noteproperty -Value $OptionsDynamic[$Line].value
            $OptionsDynamicLine | Add-Member -Name 'Type'        -MemberType Noteproperty -Value 'Dynamic'
            $OptionsDynamicLine | Add-Member -Name 'Description' -MemberType Noteproperty -Value $Description
            $OptionsDynamicLine | Add-Member -Name 'DataType'    -MemberType Noteproperty -Value $DataType
            $OptionsDynamicLine | Add-Member -Name 'RFC'         -MemberType Noteproperty -Value $RFC
            
            # Add lines to $Array
            $Array += $OptionsDynamicLine
            
            # Go to next line
            $Line ++
            $LineID ++
        }
    }
    
    Return $Array
}

Function Get-BBOXDHCPOptions {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.optionscapabilities
    
    If ($Json.Count -ne 0) {
        
        $Line = 0
        
        While ($Line -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $OptionLine = New-Object -TypeName PSObject
            $OptionLine | Add-Member -Name 'ID'          -MemberType Noteproperty -Value $Json[$Line].ID
            $OptionLine | Add-Member -Name 'RFC'         -MemberType Noteproperty -Value $Json[$Line].RFC
            $OptionLine | Add-Member -Name 'Type'        -MemberType Noteproperty -Value $Json[$Line].Type
            $OptionLine | Add-Member -Name 'Description' -MemberType Noteproperty -Value $Json[$Line].Description
            
            # Add lines to $Array
            $Array += $OptionLine
            
            # Go to next line
            $Line ++
        }
    
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXDHCPOptionsID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $OptionIDs = Get-BBOXDHCPOptions -UrlToGo $UrlToGo
    If ($global:TriggerExportConfig -eq $true) {
        $OptionID = $OptionIDs | Select-Object -Property ID,Description -First 1
    }
    Else {
        $OptionID = $OptionIDs | Select-Object -Property ID,Description | Out-GridView -Title "DHCP Capabilities Options" -OutputMode Single
    }
    $Option = $OptionIDs | Where-Object {$_.ID -ilike $OptionID.id}
    
    Return $Option
}

Function Get-BBOXDHCPSTBOptions {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.options
    
    If ($Json.count -ne 0) {
        
        $Line = 0
        
        While ($Line -lt $Json.count) {
            
            # Create New PSObject and add values to array
            $OptionLine = New-Object -TypeName PSObject
            $OptionLine | Add-Member -Name 'ID'     -MemberType Noteproperty -Value $Json[$Line].id
            $OptionLine | Add-Member -Name 'Option' -MemberType Noteproperty -Value $Json[$Line].option
            
            # Add lines to $Array
            $Array += $OptionLine
            
            # Go to next line
            $Line ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

function Get-BBOXDHCPv6PrefixDelegation {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.prefixdelegation
    
    If ($Json.Count -ne 0) {
        
        $PrefixID = 0
        
        While ($PrefixID -lt $Json.Count) {
            
            $PrefixDelegationLine = New-Object -TypeName PSObject
            $PrefixDelegationLine | Add-Member -Name 'ID'             -MemberType Noteproperty -Value $Json[$PrefixID].ID
            $PrefixDelegationLine | Add-Member -Name 'State'          -MemberType Noteproperty -Value $(Get-Status -Status $Json[$PrefixID].enable)
            $PrefixDelegationLine | Add-Member -Name 'Prefix Start'   -MemberType Noteproperty -Value $Json[$PrefixID].prefixstart
            $PrefixDelegationLine | Add-Member -Name 'Prefix End'     -MemberType Noteproperty -Value $Json[$PrefixID].prefixend
            $PrefixDelegationLine | Add-Member -Name 'Security Level' -MemberType Noteproperty -Value $Json[$PrefixID].securitylevel
            $PrefixDelegationLine | Add-Member -Name 'MAC Address '   -MemberType Noteproperty -Value $Json[$PrefixID].macaddress
            $PrefixDelegationLine | Add-Member -Name 'Type'           -MemberType Noteproperty -Value $Json[$PrefixID].type
            
            # Add lines to $Array
            $Array += $PrefixDelegationLine
            
            # Go to next line
            $PrefixID ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXDHCPv6Options {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.optionscapabilities
    
    If ($Json.Count -ne 0) {
        
        $Line = 0
        
        While ($Line -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $OptionLine = New-Object -TypeName PSObject
            $OptionLine | Add-Member -Name 'ID'          -MemberType Noteproperty -Value $Json[$Line].ID
            $OptionLine | Add-Member -Name 'RFC'         -MemberType Noteproperty -Value $Json[$Line].RFC
            $OptionLine | Add-Member -Name 'Type'        -MemberType Noteproperty -Value $Json[$Line].Type
            $OptionLine | Add-Member -Name 'Description' -MemberType Noteproperty -Value $Json[$Line].Description
            
            # Add lines to $Array
            $Array += $OptionLine
            
            # Go to next line
            $Line ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

#endregion DHCP

#region DNS

Function Get-BBOXDNSStats {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dns
    
    # Create New PSObject and add values to array
    
    $DnsStats = New-Object -TypeName PSObject
    $DnsStats | Add-Member -Name 'Range Date Start'          -MemberType Noteproperty -Value $((Get-Date).AddDays(-14)) # Not included in API
    $DnsStats | Add-Member -Name 'Range Date End'            -MemberType Noteproperty -Value $(Get-Date) # Not included in API
    $DnsStats | Add-Member -Name 'Query Count in range time' -MemberType Noteproperty -Value $Json.nbqueries
    $DnsStats | Add-Member -Name 'Averrage Query Per Day'    -MemberType Noteproperty -Value $($Json.nbqueries / 14) # Not included in API
    $DnsStats | Add-Member -Name 'Answer Min Time (ms)'      -MemberType Noteproperty -Value $Json.min
    $DnsStats | Add-Member -Name 'Answer Min Time (s)'       -MemberType Noteproperty -Value $($Json.min / 1000) # Not included in API
    $DnsStats | Add-Member -Name 'Answer Max Time (ms)'      -MemberType Noteproperty -Value $Json.max
    $DnsStats | Add-Member -Name 'Answer Max Time (s) '      -MemberType Noteproperty -Value $($Json.max / 1000) # Not included in API
    $DnsStats | Add-Member -Name 'Answer Averrage Time (ms)' -MemberType Noteproperty -Value $Json.avg
    $DnsStats | Add-Member -Name 'Answer Averrage Time (s)'  -MemberType Noteproperty -Value $($Json.avg / 1000) # Not included in API
    
    # Add lines to $Array
    $Array += $DnsStats
    
    Return $Array
}

#endregion DNS

#region DYNDNS

Function Get-BBOXDYNDNS {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $DyndnsLine = New-Object -TypeName PSObject
    $DyndnsLine | Add-Member -Name 'Service'                        -MemberType Noteproperty -Value 'DYNDNS'
    $DyndnsLine | Add-Member -Name 'State'                          -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $DyndnsLine | Add-Member -Name 'Status'                         -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $DyndnsLine | Add-Member -Name 'Provider Available List'        -MemberType Noteproperty -Value ($Json.servercapabilities.name -join ",")
    $DyndnsLine | Add-Member -Name 'Configured Available Domain '   -MemberType Noteproperty -Value ($($Json.domain.server | Select-Object -Unique) -join ",")
    $DyndnsLine | Add-Member -Name 'Configured Record Type'         -MemberType Noteproperty -Value $(($Json.domain.record | Select-Object -Unique) -join ",")
    $DyndnsLine | Add-Member -Name 'Configured Record Type Details' -MemberType Noteproperty -Value $($(($Json.domain.record | Select-Object -Unique) | ForEach-Object {Get-DynDnsRecordDetail -Record $_}) -join ",")
    $DyndnsLine | Add-Member -Name 'Configured Hosts List'          -MemberType Noteproperty -Value ($Json.domain.host -join ",")
    $DyndnsLine | Add-Member -Name 'Configured domain List'         -MemberType Noteproperty -Value ($Json.domaincount)
    
    # Add lines to $Array
    $Array += $DyndnsLine
    
    Return $Array
}

Function Get-BBOXDYNDNSProviderList {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName.servercapabilities
    
    If ($Json.count -ne 0) {
    
    $Providers = 0
    
    While ($Providers -lt $Json.count) {
        
        $IPV4Status = 'No'
        $IPV6Status = 'No'
        
        If ($Json[$Providers].Support -match 'IPV4') {
            $IPV4Status = 'Yes'
        }
        If ($Json[$Providers].Support -match 'IPV6') {
            $IPV6Status = 'Yes'
        }
        
        # Create New PSObject and add values to array
        $ProviderLine = New-Object -TypeName PSObject
        $ProviderLine | Add-Member -Name 'Provider'                -MemberType Noteproperty -Value $Json[$Providers].name
        $ProviderLine | Add-Member -Name 'IPv4 Supported Protocol' -MemberType Noteproperty -Value $IPV4Status
        $ProviderLine | Add-Member -Name 'IPv6 Supported Protocol' -MemberType Noteproperty -Value $IPV6Status
        $ProviderLine | Add-Member -Name 'Provider Web Site'       -MemberType Noteproperty -Value $Json[$Providers].Site
        
        # Add lines to $Array
        $Array += $ProviderLine
        
        # Go to next line
        $Providers ++
    }
    
    Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXDYNDNSClient {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName.domain
    
    If ($Json.count -ne '0') {
        
        $ProviderId = 0
        
        While ($ProviderId -lt $Json.count) {
            
            $DynDnsStatusErrorMessageDetail = $Null
            $DynDnsStatusValidMessageDetail = $Null
            
            If ($Json[$ProviderId].status.status -match 'Ok') {
                $DynDnsStatusValidMessageDetail = Get-DynDnsStatusValidMessageDetail -Status $Json[$ProviderId].status.message
                $DynDnsStatusErrorMessageDetail = 'N/A'
            }
            Else {
                $DynDnsStatusErrorMessageDetail = Get-DynDnsStatusErrorMessageDetail -Status $Json[$ProviderId].status.status
                $DynDnsStatusValidMessageDetail = 'N/A'
            }
            
            # Create New PSObject and add values to array
            $ProviderLine = New-Object -TypeName PSObject
            $ProviderLine | Add-Member -Name 'ID'                  -MemberType Noteproperty -Value $Json[$ProviderId].id
            $ProviderLine | Add-Member -Name 'Provider'            -MemberType Noteproperty -Value $Json[$ProviderId].server
            $ProviderLine | Add-Member -Name 'State'               -MemberType Noteproperty -Value $(Get-State -State $Json[$ProviderId].enable)
            $ProviderLine | Add-Member -Name 'Username'            -MemberType Noteproperty -Value $Json[$ProviderId].username
            $ProviderLine | Add-Member -Name 'Password'            -MemberType Noteproperty -Value $Json[$ProviderId].password
            $ProviderLine | Add-Member -Name 'Host'                -MemberType Noteproperty -Value $Json[$ProviderId].host
            $ProviderLine | Add-Member -Name 'Record Type'         -MemberType Noteproperty -Value $Json[$ProviderId].record
            $ProviderLine | Add-Member -Name 'Record Type Detail'  -MemberType Noteproperty -Value $(Get-DynDnsRecordDetail -Record $Json[$ProviderId].record)
            $ProviderLine | Add-Member -Name 'MAC Address'         -MemberType Noteproperty -Value $Json[$ProviderId].device
            $ProviderLine | Add-Member -Name 'Last Update Date'    -MemberType Noteproperty -Value $(Edit-Date -Date $Json[$ProviderId].status.date)
            $ProviderLine | Add-Member -Name 'Status'              -MemberType Noteproperty -Value $Json[$ProviderId].status.status
            $ProviderLine | Add-Member -Name 'Message'             -MemberType Noteproperty -Value $Json[$ProviderId].status.message
            $ProviderLine | Add-Member -Name 'Error Message Detail'-MemberType Noteproperty -Value $DynDnsStatusErrorMessageDetail
            $ProviderLine | Add-Member -Name 'Valid Message Detail'-MemberType Noteproperty -Value $DynDnsStatusValidMessageDetail
            $ProviderLine | Add-Member -Name 'IP Address'          -MemberType Noteproperty -Value $Json[$ProviderId].status.ip
            $ProviderLine | Add-Member -Name 'Cache Date'          -MemberType Noteproperty -Value $(Edit-Date -Date $Json[$ProviderId].status.cache_date)
            $ProviderLine | Add-Member -Name 'Periodic Update (D)' -MemberType Noteproperty -Value $Json[$ProviderId].periodicupdate
            
            $Array += $ProviderLine
            
            # Go to next line
            $ProviderId ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXDYNDNSClientID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $DyndnsIDs = Get-BBOXDYNDNSClient -UrlToGo $UrlToGo -APIName $APIName
    If ($global:TriggerExportConfig -eq $true) {
        $DyndnsID = $DyndnsIDs | Select-Object -Property ID,Provider,Host -First 1
    }
    Else {
        $DyndnsID = $DyndnsIDs | Select-Object -Property ID,Provider,Host | Out-GridView -Title "DYNDNS Configuration List" -OutputMode Single
    }
    $Dyndns = $DyndnsIDs | Where-Object {$_.ID -ilike $DyndnsID.id}
    
    Return $Dyndns
}

#endregion DYNDNS

#region FIREWALL

Function Get-BBOXFIREWALL {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    $Firewall = New-Object -TypeName PSObject
    $Firewall | Add-Member -Name 'Service'             -MemberType Noteproperty -Value $APIName
    $Firewall | Add-Member -Name 'State'               -MemberType Noteproperty -Value $Json.state
    $Firewall | Add-Member -Name 'Status'              -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $Firewall | Add-Member -Name 'Supported Protocols' -MemberType Noteproperty -Value ($($Json.protoscapabilities) -join ',')
    
    # Add lines to $Array
    $Array += $Firewall
    
    Return $Array
}

Function Get-BBOXFIREWALLRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.firewall.rules
    
    If ($Json.Count -ne 0) {
        
        $Rule = 0
        
        While ($Rule -lt $Json.Count) {
            
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name 'ID'                             -MemberType Noteproperty -Value $Json[$Rule].ID
            $RuleLine | Add-Member -Name 'Status'                         -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].enable)
            $RuleLine | Add-Member -Name 'Description'                    -MemberType Noteproperty -Value $Json[$Rule].description
            $RuleLine | Add-Member -Name 'Action'                         -MemberType Noteproperty -Value $Json[$Rule].action
            $RuleLine | Add-Member -Name 'IP source is excluded ?'        -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcipnot)
            $RuleLine | Add-Member -Name 'IP source (Range/IP)'           -MemberType Noteproperty -Value $Json[$Rule].srcip
            $RuleLine | Add-Member -Name 'IP destination is excluded ?'   -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstipnot)
            $RuleLine | Add-Member -Name 'IP destination (Range/IP)'      -MemberType Noteproperty -Value $Json[$Rule].dstip
            $RuleLine | Add-Member -Name 'Port source is excluded ?'      -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcportnot)
            $RuleLine | Add-Member -Name 'Port source (Range/Port)'       -MemberType Noteproperty -Value $Json[$Rule].srcports
            $RuleLine | Add-Member -Name 'Port destination is excluded ?' -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstportnot)
            $RuleLine | Add-Member -Name 'Port destination (Range/Port)'  -MemberType Noteproperty -Value $Json[$Rule].dstports
            $RuleLine | Add-Member -Name 'Priority'                       -MemberType Noteproperty -Value $Json[$Rule].order
            $RuleLine | Add-Member -Name 'TCP/UDP Protocols'              -MemberType Noteproperty -Value $Json[$Rule].protocols
            $RuleLine | Add-Member -Name 'IP Protocols'                   -MemberType Noteproperty -Value $Json[$Rule].ipprotocol
            $RuleLine | Add-Member -Name 'Nb time used'                   -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].utilisation)
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXFIREWALLRulesID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )

    $RuleIDs = Get-BBOXFIREWALLRules -UrlToGo $UrlToGo
    If ($global:TriggerExportConfig -eq $true) {
        $RuleID = $RuleIDs | Select-Object -Property ID,Description -First 1
    }
    Else {
        $RuleID = $RuleIDs | Select-Object -Property ID,Description | Out-GridView -Title "IPV4 FireWall List" -OutputMode Single
    }
    $Rule = $RuleIDs | Where-Object {$_.ID -ilike $RuleID.id}
    
    Return $Rule
}

Function Get-BBOXFIREWALLPingResponder {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.firewall.pingresponder
    
    # Create new PSObject
    $PingResponderLine = New-Object -TypeName PSObject
    $PingResponderLine | Add-Member -Name 'Service'                   -MemberType Noteproperty -Value 'Ping Responder'
    $PingResponderLine | Add-Member -Name 'Status'                    -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $PingResponderLine | Add-Member -Name 'IPV4 Addess/Range Allowed' -MemberType Noteproperty -Value $Json.ip
    $PingResponderLine | Add-Member -Name 'IPV6 Addess/Range Allowed' -MemberType Noteproperty -Value $Json.ipv6
    
    # Add lines to $Array
    $Array += $PingResponderLine
    
    Return $Array
}

Function Get-BBOXFIREWALLGamerMode {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.firewall.gamermode
    
    # Create new PSObject
    $GamerModeLine = New-Object -TypeName PSObject
    $GamerModeLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'Gamer Mode'
    $GamerModeLine | Add-Member -Name 'Status' -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    
    # Add lines to $Array
    $Array += $GamerModeLine
    
    Return $Array
}

Function Get-BBOXFIREWALLv6Rules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.firewall.rules
    
    If ($Json.Count -ne 0) {
        
        $Rule = 0
        
        While ($Rule -lt $Json.Count) {
            
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name 'ID'                             -MemberType Noteproperty -Value $Json[$Rule].ID
            $RuleLine | Add-Member -Name 'Status'                         -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].enable)
            $RuleLine | Add-Member -Name 'Description'                    -MemberType Noteproperty -Value $Json[$Rule].description
            $RuleLine | Add-Member -Name 'Action'                         -MemberType Noteproperty -Value $Json[$Rule].action
            $RuleLine | Add-Member -Name 'IP Source is excluded ?'        -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcipnot)
            $RuleLine | Add-Member -Name 'IP Source (Range/IP)'           -MemberType Noteproperty -Value $Json[$Rule].srcip
            $RuleLine | Add-Member -Name 'IP Destination is excluded ?'   -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstipnot)
            $RuleLine | Add-Member -Name 'IP Destination (Range/IP)'      -MemberType Noteproperty -Value $Json[$Rule].dstip
            $RuleLine | Add-Member -Name 'MACs Source is excluded ?'      -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcmacnot) # Since version : 20.2.32
            $RuleLine | Add-Member -Name 'MACs Source list'               -MemberType Noteproperty -Value $Json[$Rule].srcmac                         # Since version : 20.2.32
            $RuleLine | Add-Member -Name 'MACs Destination is excluded ?' -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstmacnot) # Since version : 20.2.32
            $RuleLine | Add-Member -Name 'MACs Destination list'          -MemberType Noteproperty -Value $Json[$Rule].dstmac                         # Since version : 20.2.32
            $RuleLine | Add-Member -Name 'Port Source is excluded ?'      -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].srcportnot)
            $RuleLine | Add-Member -Name 'Port Source (Range/Port)'       -MemberType Noteproperty -Value $Json[$Rule].srcports
            $RuleLine | Add-Member -Name 'Port Destination is excluded ?' -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].dstportnot)
            $RuleLine | Add-Member -Name 'Port Destination (Range/Port)'  -MemberType Noteproperty -Value $Json[$Rule].dstports
            $RuleLine | Add-Member -Name 'Priority'                       -MemberType Noteproperty -Value $Json[$Rule].order
            $RuleLine | Add-Member -Name 'TCP/UDP Protocols'              -MemberType Noteproperty -Value $Json[$Rule].protocols
            $RuleLine | Add-Member -Name 'IP Protocols'                   -MemberType Noteproperty -Value $Json[$Rule].ipprotocol
            $RuleLine | Add-Member -Name 'Number time used ?'             -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].utilisation)
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXFIREWALLv6RulesID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $RuleIDs = Get-BBOXFIREWALLv6Rules -UrlToGo $UrlToGo
    If ($global:TriggerExportConfig -eq $true) {
        $RuleID = $RuleIDs | Select-Object -Property ID,Description -First 1
    }
    Else {
        $RuleID = $RuleIDs | Select-Object -Property ID,Description | Out-GridView -Title "IPV6 FireWall Rules List : " -OutputMode Single
    }
    $Rule = $RuleIDs | Where-Object {$_.ID -ilike $RuleID.id}
    
    Return $Rule
}

function Get-BBOXFIREWALLv6Level {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.firewall
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'FireWall IPV6'
    $DeviceLine | Add-Member -Name 'Level'   -MemberType Noteproperty -Value $Json.level
    
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

#endregion FIREWALL

#region HOSTS

Function Get-BBOXHOSTSDownloadThreshold {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.downloadThreshold
    
    # Create New PSObject and add values to array

    # RX
    $DownloadThresholdLine = New-Object -TypeName PSObject
    $DownloadThresholdLine | Add-Member -Name 'wifi Low'  -MemberType Noteproperty -Value $Json.wifiLow
    $DownloadThresholdLine | Add-Member -Name 'wifi High' -MemberType Noteproperty -Value $Json.wifiHigh
    $DownloadThresholdLine | Add-Member -Name 'wifi MCS'  -MemberType Noteproperty -Value $Json.wifiMCS
    $DownloadThresholdLine | Add-Member -Name 'ETH Low'   -MemberType Noteproperty -Value $Json.ethLow
    $DownloadThresholdLine | Add-Member -Name 'ETH High'  -MemberType Noteproperty -Value $Json.ethHigh
    
    # Add lines to $Array
    $Array += $DownloadThresholdLine
    
    Return $Array
}

Function Get-BBOXHOSTS {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName.list
    
    If ($Json.Count -ne 0) {
        
        $Device = 0
        
        While ($Device -lt ($Json.Count)) {
            
            # Create New PSObject and add values to array
            $DeviceLine = New-Object -TypeName PSObject
            $DeviceLine | Add-Member -Name 'ID'                                  -MemberType Noteproperty -Value $Json[$Device].id
            $DeviceLine | Add-Member -Name 'Hostname'                            -MemberType Noteproperty -Value $Json[$Device].hostname
            $DeviceLine | Add-Member -Name 'MAC Address'                         -MemberType Noteproperty -Value $Json[$Device].macaddress
            $DeviceLine | Add-Member -Name 'DUID'                                -MemberType Noteproperty -Value $Json[$Device].duid
            $DeviceLine | Add-Member -Name 'IPV4 Adress'                         -MemberType Noteproperty -Value $Json[$Device].ipaddress
            $DeviceLine | Add-Member -Name 'DHCP Mode'                           -MemberType Noteproperty -Value $Json[$Device].type
            $DeviceLine | Add-Member -Name 'Link Type'                           -MemberType Noteproperty -Value $Json[$Device].link
            $DeviceLine | Add-Member -Name 'Is Guest'                            -MemberType Noteproperty -Value $Json[$Device].guest # Since version : 23.7.8
            $DeviceLine | Add-Member -Name 'Device Type'                         -MemberType Noteproperty -Value $Json[$Device].devicetype
            
            # If STB part
            If ($Json[$Device].devicetype -like 'STB') {
                
                $DeviceLine | Add-Member -Name 'STB - Product'                   -MemberType Noteproperty -Value $Json[$Device].stb.product
                $DeviceLine | Add-Member -Name 'STB - Serial'                    -MemberType Noteproperty -Value $Json[$Device].stb.serial
            }
            Else {
                $DeviceLine | Add-Member -Name 'STB - Product'                   -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'STB - Serial'                    -MemberType Noteproperty -Value ''
            }
            
            $DeviceLine | Add-Member -Name 'IPV4 Date First Connexion'           -MemberType Noteproperty -Value $(Edit-Date -Date $Json[$Device].firstseen)
            $DeviceLine | Add-Member -Name 'IPV4 Date Last Connexion'            -MemberType Noteproperty -Value $(Get-LastSeenDate -Seconds $Json[$Device].lastseen)
            
            # If IPV6 part
            If (-not ([string]::IsNullOrEmpty($Json.ip6address))) {
        
                $IPV6Line = 0
                $IPAddress = @()
                $Status = @()
                $Lastseen = @()
                $Lastscan = @()
                
                While ($IPV6Line -ne $Json.ip6address.count) {
                    
                    $IPAddress += $($Json.ip6address[$IPV6Line].ipaddress)
                    $Status    += $($Json.ip6address[$IPV6Line].status)
                    $Lastseen  += $(Edit-Date -Date $Json.ip6address[$IPV6Line].lastseen)
                    $Lastscan  += $(Edit-Date -Date $Json.ip6address[$IPV6Line].lastscan)
                    
                    # Go to next line
                    $IPV6Line ++
                }
                
                $DeviceLine | Add-Member -Name 'IPV6 Address'                 -MemberType Noteproperty -Value $($IPAddress -join ",")
                $DeviceLine | Add-Member -Name 'IPV6 Statut'                  -MemberType Noteproperty -Value $($Status -join ",")
                $DeviceLine | Add-Member -Name 'IPV6 First Connexion Date'    -MemberType Noteproperty -Value $($Lastseen -join ",")
                $DeviceLine | Add-Member -Name 'IPV6 Last Connexion Date'     -MemberType Noteproperty -Value $($Lastscan -join ",")
            }
            Else {
                $DeviceLine | Add-Member -Name 'IPV6 Address'                 -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'IPV6 Statut'                  -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'IPV6 First Connexion Date'    -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'IPV6 Last Connexion Date'     -MemberType Noteproperty -Value ''
            }
            
            $DeviceLine | Add-Member -Name 'Physical Port'                       -MemberType Noteproperty -Value $Json[$Device].ethernet.physicalport
            $DeviceLine | Add-Member -Name 'Logical Port'                        -MemberType Noteproperty -Value $Json[$Device].ethernet.logicalport
            $DeviceLine | Add-Member -Name 'Speed Connexion'                     -MemberType Noteproperty -Value $Json[$Device].ethernet.speed
            $DeviceLine | Add-Member -Name 'Mode'                                -MemberType Noteproperty -Value $Json[$Device].ethernet.mode
            $DeviceLine | Add-Member -Name 'Band'                                -MemberType Noteproperty -Value $Json[$Device].wireless.band
            $DeviceLine | Add-Member -Name 'RSSIO'                               -MemberType Noteproperty -Value $Json[$Device].wireless.rssi0
            $DeviceLine | Add-Member -Name 'RSSI1'                               -MemberType Noteproperty -Value $Json[$Device].wireless.rssi1
            $DeviceLine | Add-Member -Name 'RSSI2'                               -MemberType Noteproperty -Value $Json[$Device].wireless.rssi2
            $DeviceLine | Add-Member -Name 'TX Usage'                            -MemberType Noteproperty -Value $Json[$Device].wireless.txUsage # Since version : 23.7.8
            $DeviceLine | Add-Member -Name 'RX Usage'                            -MemberType Noteproperty -Value $Json[$Device].wireless.rxUsage # Since version : 23.7.8
            $DeviceLine | Add-Member -Name 'Estimated Rate'                      -MemberType Noteproperty -Value $Json[$Device].wireless.estimatedRate # Since version : 23.7.8
            $DeviceLine | Add-Member -Name 'MSC'                                 -MemberType Noteproperty -Value $Json[$Device].wireless.mcs
            $DeviceLine | Add-Member -Name 'Rate'                                -MemberType Noteproperty -Value $Json[$Device].wireless.rate
            $DeviceLine | Add-Member -Name 'Idle'                                -MemberType Noteproperty -Value $Json[$Device].wireless.idle
            $DeviceLine | Add-Member -Name 'WexIndex'                            -MemberType Noteproperty -Value $Json[$Device].wireless.wexindex
            $DeviceLine | Add-Member -Name 'Starealmac'                          -MemberType Noteproperty -Value $Json[$Device].wireless.starealmac
            $DeviceLine | Add-Member -Name 'Wireless Static'                     -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Device].wireless.static)
            $DeviceLine | Add-Member -Name 'RXPhyrate'                           -MemberType Noteproperty -Value $Json[$Device].plc.rxphyrate
            $DeviceLine | Add-Member -Name 'TXPhyrate'                           -MemberType Noteproperty -Value $Json[$Device].plc.txphyrate
            $DeviceLine | Add-Member -Name 'Associated Device'                   -MemberType Noteproperty -Value $Json[$Device].plc.associateddevice
            $DeviceLine | Add-Member -Name 'Interface'                           -MemberType Noteproperty -Value $Json[$Device].plc.interface
            $DeviceLine | Add-Member -Name 'Ethernet Speed'                      -MemberType Noteproperty -Value $Json[$Device].plc.ethernetspeed
            $DeviceLine | Add-Member -Name 'DHCP Bail'                           -MemberType Noteproperty -Value $Json[$Device].lease
            $DeviceLine | Add-Member -Name 'Is Active ?'                         -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Device].active)
            $DeviceLine | Add-Member -Name 'Parental Control - State'            -MemberType Noteproperty -Value (Get-state -State $Json[$Device].parentalcontrol.enable)
            $DeviceLine | Add-Member -Name 'Parental Control - Status'           -MemberType Noteproperty -Value (Get-Status -Status $Json[$Device].parentalcontrol.status)
            $DeviceLine | Add-Member -Name 'Parental Control - Last Time Status' -MemberType Noteproperty -Value $(Get-LastSeenDate -Seconds $Json[$Device].parentalcontrol.statusRemaining)
            $DeviceLine | Add-Member -Name 'Parental Control - Next Time Status' -MemberType Noteproperty -Value $Json[$Device].parentalcontrol.statusUntil
            $DeviceLine | Add-Member -Name 'Average Ping'                        -MemberType Noteproperty -Value $Json[$Device].ping.average
            $DeviceLine | Add-Member -Name 'Detected Active Services'            -MemberType Noteproperty -Value $($Json[$Device].scan.services -join ',')
            
            <# If Services part
            If (-not ([string]::IsNullOrEmpty($Json[$Device].scan.services))) {
                
                $DeviceLine | Add-Member -Name 'Detected Protocol'               -MemberType Noteproperty -Value $Json[$Device].scan.services.protocol
                $DeviceLine | Add-Member -Name 'Detected Port'                   -MemberType Noteproperty -Value $Json[$Device].scan.services.port
                $DeviceLine | Add-Member -Name 'Port State'                      -MemberType Noteproperty -Value $Json[$Device].scan.services.state
                $DeviceLine | Add-Member -Name 'Reason'                          -MemberType Noteproperty -Value $Json[$Device].scan.services.reason
            }
            Else {
                $DeviceLine | Add-Member -Name 'Detected Protocol'               -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'Detected Port'                   -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'Port State'                      -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'Reason'                          -MemberType Noteproperty -Value ''
            }
            #>
            
            # Add lines to $Array
            $Array += $DeviceLine
            
            # Go to next line
            $Device ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXHOSTSID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $HostIDs = Get-BBOXHOSTS -UrlToGo $UrlToGo -APIName $APIName
    If ($global:TriggerExportConfig -eq $true) {
        $HostID = $HostIDs | Select-Object -Property ID,Hostname -First 1
    }
    Else {
        $HostID = $HostIDs | Select-Object -Property ID,Hostname | Out-GridView -Title "Hosts List" -OutputMode Single
    }
    $MachineID = $HostIDs | Where-Object {$_.ID -ilike $HostID.id}
    
    Return $MachineID
}

Function Get-BBOXHOSTSWireless {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wirelesshosts
    
    If ($Json.Count -ne 0) {
        
        $Device = 0
        
        While ($Device -lt ($Json.Count)) {
            
            $Station = 0
            
            While ($Station -lt $($Json[$Device].stations).count) {
                
                # Create New PSObject and add values to array
                $StationLine = New-Object -TypeName PSObject
                $StationLine | Add-Member -Name 'MAC address' -MemberType Noteproperty -Value $Json[$Device].stations[$Station].macaddress
                $StationLine | Add-Member -Name 'CAPS'        -MemberType Noteproperty -Value $Json[$Device].stations[$Station].caps
                
                # Add lines to $Array
                $Array += $StationLine
                
                # Go to next line
                $Station ++
            }
            # Go to next line
            $Device ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXHOSTSME {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.host
    
    If (-not ([string]::IsNullOrEmpty($Json.hostname))) {
    
        # Create New PSObject and add values to array
        $DeviceLine = New-Object -TypeName PSObject
        $DeviceLine | Add-Member -Name 'ID'                               -MemberType Noteproperty -Value $Json.id
        $DeviceLine | Add-Member -Name 'Hostname'                         -MemberType Noteproperty -Value $Json.hostname
        $DeviceLine | Add-Member -Name 'MAC Address'                      -MemberType Noteproperty -Value $Json.macaddress
        $DeviceLine | Add-Member -Name 'DUID'                             -MemberType Noteproperty -Value $Json.duid
        $DeviceLine | Add-Member -Name 'IPV4 Adress'                      -MemberType Noteproperty -Value $Json.ipaddress
        $DeviceLine | Add-Member -Name 'DHCP Mode'                        -MemberType Noteproperty -Value $Json.type
        $DeviceLine | Add-Member -Name 'Link Type'                        -MemberType Noteproperty -Value $Json.link
        $DeviceLine | Add-Member -Name 'Device Type'                      -MemberType Noteproperty -Value $Json.devicetype
        
        # If STB part
        If ($Json.devicetype -like 'STB') {
                
            $DeviceLine | Add-Member -Name 'STB - Product'                -MemberType Noteproperty -Value $Json.stb.product
            $DeviceLine | Add-Member -Name 'STB - Serial'                 -MemberType Noteproperty -Value $Json.stb.serial
        }
        Else {
            $DeviceLine | Add-Member -Name 'STB - Product'                -MemberType Noteproperty -Value ''
            $DeviceLine | Add-Member -Name 'STB - Serial'                 -MemberType Noteproperty -Value ''
        }
        
        $DeviceLine | Add-Member -Name 'IPV4 Date first connexion'        -MemberType Noteproperty -Value $Json.firstseen
        
        If ($Json.lastseen -ne 0) {
            $DeviceLine | Add-Member -Name 'IPV4 Date last connexion'     -MemberType Noteproperty -Value $(Get-LastSeenDate -Seconds $Json.lastseen)
        }
        Else {
            $DeviceLine | Add-Member -Name 'IPV4 Date last connexion'     -MemberType Noteproperty -Value $Json.lastseen
        }

        # If IPV6 part
        If (-not ([string]::IsNullOrEmpty($Json.ip6address))) {
            
            $IPV6Line = 0
            $IPAddress = @()
            $Status = @()
            $Lastseen = @()
            $Lastscan = @()
            
            While ($IPV6Line -ne $Json.ip6address.count) {
                
                $IPAddress += $($Json.ip6address[$IPV6Line].ipaddress)
                $Status    += $($Json.ip6address[$IPV6Line].status)
                $Lastseen  += $(Edit-Date -Date $Json.ip6address[$IPV6Line].lastseen)
                $Lastscan  += $(Edit-Date -Date $Json.ip6address[$IPV6Line].lastscan)
                
                # Go to next line
                $IPV6Line ++
            }
            
            $DeviceLine | Add-Member -Name 'IPV6 Address'                 -MemberType Noteproperty -Value $($IPAddress -join ",")
            $DeviceLine | Add-Member -Name 'IPV6 Statut'                  -MemberType Noteproperty -Value $($Status -join ",")
            $DeviceLine | Add-Member -Name 'IPV6 First Connexion Date'    -MemberType Noteproperty -Value $($Lastseen -join ",")
            $DeviceLine | Add-Member -Name 'IPV6 Last Connexion Date'     -MemberType Noteproperty -Value $($Lastscan -join ",")
        }
        Else {
            $DeviceLine | Add-Member -Name 'IPV6 Address'                 -MemberType Noteproperty -Value ''
            $DeviceLine | Add-Member -Name 'IPV6 Statut'                  -MemberType Noteproperty -Value ''
            $DeviceLine | Add-Member -Name 'IPV6 First Connexion Date'    -MemberType Noteproperty -Value ''
            $DeviceLine | Add-Member -Name 'IPV6 Last Connexion Date'     -MemberType Noteproperty -Value ''
        }
        
        $DeviceLine | Add-Member -Name 'Physical Port'                    -MemberType Noteproperty -Value $Json.ethernet.physicalport
        $DeviceLine | Add-Member -Name 'Logical Port'                     -MemberType Noteproperty -Value $Json.ethernet.logicalport
        $DeviceLine | Add-Member -Name 'Ethernet Speed'                   -MemberType Noteproperty -Value $Json.ethernet.speed
        $DeviceLine | Add-Member -Name 'Mode'                             -MemberType Noteproperty -Value $Json.ethernet.mode
        $DeviceLine | Add-Member -Name 'Band'                             -MemberType Noteproperty -Value $Json.wireless.band
        $DeviceLine | Add-Member -Name 'RSSIO'                            -MemberType Noteproperty -Value $Json.wireless.rssi0
        $DeviceLine | Add-Member -Name 'RSSI1'                            -MemberType Noteproperty -Value $Json.wireless.rssi1
        $DeviceLine | Add-Member -Name 'RSSI2'                            -MemberType Noteproperty -Value $Json.wireless.rssi2
        $DeviceLine | Add-Member -Name 'TX Usage'                         -MemberType Noteproperty -Value $Json.wireless.txUsage # Since version : 23.7.8
        $DeviceLine | Add-Member -Name 'RX Usage'                         -MemberType Noteproperty -Value $Json.wireless.rxUsage # Since version : 23.7.8
        $DeviceLine | Add-Member -Name 'Estimated Rate'                   -MemberType Noteproperty -Value $Json.wireless.estimatedRate # Since version : 23.7.8
        $DeviceLine | Add-Member -Name 'MSC'                              -MemberType Noteproperty -Value $Json.wireless.mcs
        $DeviceLine | Add-Member -Name 'Rate'                             -MemberType Noteproperty -Value $Json.wireless.rate
        $DeviceLine | Add-Member -Name 'Idle'                             -MemberType Noteproperty -Value $Json.wireless.idle
        $DeviceLine | Add-Member -Name 'wexindex'                         -MemberType Noteproperty -Value $Json.wireless.wexindex
        $DeviceLine | Add-Member -Name 'Wireless Static'                  -MemberType Noteproperty -Value $(Get-YesNoAsk -YesNoAsk $Json.wireless.static)
        $DeviceLine | Add-Member -Name 'RXPhyrate'                        -MemberType Noteproperty -Value $Json.plc.rxphyrate
        $DeviceLine | Add-Member -Name 'TXPhyrate'                        -MemberType Noteproperty -Value $Json.plc.txphyrate
        $DeviceLine | Add-Member -Name 'Associated Device'                -MemberType Noteproperty -Value $Json.plc.associateddevice
        $DeviceLine | Add-Member -Name 'Interface'                        -MemberType Noteproperty -Value $Json.plc.interface
        $DeviceLine | Add-Member -Name 'PCL Ethernet Speed'               -MemberType Noteproperty -Value $Json.plc.ethernetspeed
        $DeviceLine | Add-Member -Name 'Parental Control - State'         -MemberType Noteproperty -Value $(Get-State -State $Json.parentalcontrol.enable)
        $DeviceLine | Add-Member -Name 'Parental Control - Status'        -MemberType Noteproperty -Value $(Get-Status -Status $Json.parentalcontrol.status)
        If ($Json.parentalcontrol.statusRemaining -ne 0) {
            $DeviceLine | Add-Member -Name 'Parental Control - Last Time Status' -MemberType Noteproperty -Value $(Get-LastSeenDate -Seconds $Json.parentalcontrol.statusRemaining)
        }
        Else {
            $DeviceLine | Add-Member -Name 'Parental Control - Last Time Status' -MemberType Noteproperty -Value $Json.parentalcontrol.statusRemaining
        }
        $DeviceLine | Add-Member -Name 'Parental Control - Next Time Status' -MemberType Noteproperty -Value $Json.parentalcontrol.statusUntil
        $DeviceLine | Add-Member -Name 'DHCP Bail'                        -MemberType Noteproperty -Value $Json.lease
        $DeviceLine | Add-Member -Name 'First Connexion Date'             -MemberType Noteproperty -Value $Json.firstSeen
        If ($Json.lastSeen -ne 0) {
            $DeviceLine | Add-Member -Name 'Last Connexion Date'          -MemberType Noteproperty -Value $(Get-LastSeenDate -Seconds $Json.lastSeen)
        }
        Else {
            $DeviceLine | Add-Member -Name 'Last Connexion Date'          -MemberType Noteproperty -Value $Json.lastSeen
        }
        $DeviceLine | Add-Member -Name 'Is Active ?'                      -MemberType Noteproperty -Value $(Get-YesNoAsk -YesNoAsk $Json.active)
        $DeviceLine | Add-Member -Name 'Ping Min'                         -MemberType Noteproperty -Value $Json.ping.min
        $DeviceLine | Add-Member -Name 'Ping Max'                         -MemberType Noteproperty -Value $Json.ping.max
        $DeviceLine | Add-Member -Name 'Ping Average'                     -MemberType Noteproperty -Value $Json.ping.average
        $DeviceLine | Add-Member -Name 'Ping Successful'                  -MemberType Noteproperty -Value $Json.ping.Successful
        $DeviceLine | Add-Member -Name 'Ping Error'                       -MemberType Noteproperty -Value $Json.ping.error
        $DeviceLine | Add-Member -Name 'Ping Tries'                       -MemberType Noteproperty -Value $Json.ping.tries
        If ($Json.ping.status) {
            $DeviceLine | Add-Member -Name 'Ping status'                  -MemberType Noteproperty -Value $(Get-Status -Status $Json.ping.status)
        }
        Else {
            $DeviceLine | Add-Member -Name 'Ping status'                  -MemberType Noteproperty -Value $Json.ping.status
        }
        $DeviceLine | Add-Member -Name 'Ping Result'                      -MemberType Noteproperty -Value $Json.ping.results
        If ($Json.scan.status) {
            $DeviceLine | Add-Member -Name 'Scan Status'                  -MemberType Noteproperty -Value $(Get-Status -Status $Json.scan.status)
        }
        Else {
            $DeviceLine |Add-Member -Name 'Scan Status'                   -MemberType Noteproperty -Value $Json.scan.status
        }
        $DeviceLine | Add-Member -Name 'Scan State'                       -MemberType Noteproperty -Value $(Get-State -State $Json.scan.enable)
        $DeviceLine | Add-Member -Name 'Services Detected'                -MemberType Noteproperty -Value $Json.scan.services
        $DeviceLine | Add-Member -Name 'wirelesshosts'                    -MemberType Noteproperty -Value $Json.wirelesshosts
        $DeviceLine | Add-Member -Name 'extenderhosts'                    -MemberType Noteproperty -Value $Json.extenderhosts

        <# Get Services open for devices
        $Services = @()
        $Service = 1
        
        While ($Service -lt $Json.scan.services.count) {
            
            # Create New PSObject and add values to array
            $ServiceLine = New-Object -TypeName PSObject
            $ServiceLine | Add-Member -Name 'Detected Protocol'           -MemberType Noteproperty -Value $Json.scan.services.protocol
            $ServiceLine | Add-Member -Name 'Detected Port'               -MemberType Noteproperty -Value $Json.scan.services.port
            $ServiceLine | Add-Member -Name 'Port State'                  -MemberType Noteproperty -Value $Json.scan.services.state
            $ServiceLine | Add-Member -Name 'Reason'                      -MemberType Noteproperty -Value $Json.scan.services.reason 
            
            $Services += $ServiceLine
            $Service ++
        }
        #>
        
        # Add lines to $Array
        $Array += $DeviceLine
    }
    Else {
        Write-Log -Type WARNING -Category 'Program run' -Name 'Get Hosts Me' -Message "No information found, due to you are connected remotly. Please connect to your local $global:BoxType Ethernet or Wifi Network to get information"
    }
    
    Return $Array
}

Function Get-BBOXHOSTSLite {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.hosts.list
    
    If ($Json.count -ne 0) {
        
        $Device = 0
        
        While ($Device -lt $Json.count) {
            
            # Create New PSObject and add values to array
            $DeviceLine = New-Object -TypeName PSObject
            $DeviceLine | Add-Member -Name 'ID'          -MemberType Noteproperty -Value $Json[$Device].id
            $DeviceLine | Add-Member -Name 'Hostname'    -MemberType Noteproperty -Value $Json[$Device].hostname
            $DeviceLine | Add-Member -Name 'IP Address'  -MemberType Noteproperty -Value $Json[$Device].ipaddress
            $DeviceLine | Add-Member -Name 'MAC Address' -MemberType Noteproperty -Value $Json[$Device].macaddress
            $DeviceLine | Add-Member -Name 'Link'        -MemberType Noteproperty -Value $Json[$Device].link
            
            # Add lines to $Array
            $Array += $DeviceLine
            
            # Go to next line
            $Device ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXHOSTSPAUTH {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.hosts.list
    
    If ($Json.Count -ne 0) {
    
        $Device = 0
    
        While ($Device -lt ($Json.Count)) {
        
            # Create New PSObject and add values to array
            $DeviceLine = New-Object -TypeName PSObject
            $DeviceLine | Add-Member -Name 'ID'                -MemberType Noteproperty -Value $Json[$Device].id
            If ($Json[$Device].me) {
                $DeviceLine | Add-Member -Name 'Is my host'    -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Device].me)
            }
            Else {
                $DeviceLine | Add-Member -Name 'Is my host'    -MemberType Noteproperty -Value 'No'
            }
            $DeviceLine | Add-Member -Name 'DUID'              -MemberType Noteproperty -Value $Json[$Device].duid
            $DeviceLine | Add-Member -Name 'DHCP Mode'         -MemberType Noteproperty -Value $Json[$Device].type
            $DeviceLine | Add-Member -Name 'Link Type'         -MemberType Noteproperty -Value $Json[$Device].link
            $DeviceLine | Add-Member -Name 'Device Type'       -MemberType Noteproperty -Value $Json[$Device].devicetype
            $DeviceLine | Add-Member -Name 'Physical Port'     -MemberType Noteproperty -Value $Json[$Device].ethernet.physicalport
            $DeviceLine | Add-Member -Name 'Logical Port'      -MemberType Noteproperty -Value $Json[$Device].ethernet.logicalport
            $DeviceLine | Add-Member -Name 'Speed connexion'   -MemberType Noteproperty -Value $Json[$Device].ethernet.speed
            $DeviceLine | Add-Member -Name 'Mode'              -MemberType Noteproperty -Value $Json[$Device].ethernet.mode
            $DeviceLine | Add-Member -Name 'Band'              -MemberType Noteproperty -Value $Json[$Device].wireless.band
            $DeviceLine | Add-Member -Name 'RSSIO'             -MemberType Noteproperty -Value $Json[$Device].wireless.rssi0
            $DeviceLine | Add-Member -Name 'RSSI1'             -MemberType Noteproperty -Value $Json[$Device].wireless.rssi1
            $DeviceLine | Add-Member -Name 'RSSI2'             -MemberType Noteproperty -Value $Json[$Device].wireless.rssi2
            $DeviceLine | Add-Member -Name 'MSC'               -MemberType Noteproperty -Value $Json[$Device].wireless.mcs
            $DeviceLine | Add-Member -Name 'Rate'              -MemberType Noteproperty -Value $Json[$Device].wireless.rate
            $DeviceLine | Add-Member -Name 'Idle'              -MemberType Noteproperty -Value $Json[$Device].wireless.idle
            $DeviceLine | Add-Member -Name 'WexIndex'          -MemberType Noteproperty -Value $Json[$Device].wireless.wexindex
            $DeviceLine | Add-Member -Name 'Starealmac'        -MemberType Noteproperty -Value $Json[$Device].wireless.starealmac
            $DeviceLine | Add-Member -Name 'RXPhyrate'         -MemberType Noteproperty -Value $Json[$Device].plc.rxphyrate
            $DeviceLine | Add-Member -Name 'TXPhyrate'         -MemberType Noteproperty -Value $Json[$Device].plc.txphyrate
            $DeviceLine | Add-Member -Name 'Associated Device' -MemberType Noteproperty -Value $Json[$Device].plc.associateddevice
            $DeviceLine | Add-Member -Name 'Interface'         -MemberType Noteproperty -Value $Json[$Device].plc.interface
            $DeviceLine | Add-Member -Name 'Ethernet Speed'    -MemberType Noteproperty -Value $Json[$Device].plc.ethernetspeed
            $DeviceLine | Add-Member -Name 'DHCP Bail'         -MemberType Noteproperty -Value $Json[$Device].lease
            $DeviceLine | Add-Member -Name 'Is Active ?'       -MemberType Noteproperty -Value (Get-State -State $Json[$Device].active)
            $DeviceLine | Add-Member -Name 'Ping Average'      -MemberType Noteproperty -Value $Json[$Device].ping.average
            $DeviceLine | Add-Member -Name 'Active Services'   -MemberType Noteproperty -Value $($Json[$Device].scan.services -join ',')

            # Add lines to $Array
            $Array += $DeviceLine
            
            # Go to next line
            $Device ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

#endregion HOSTS

#region IPTV

Function Get-BBOXIPTV {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    If ($Json.Count -ne 0) {
        
        $IPTV = 0
        
        While ($IPTV -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $IPTVLine = New-Object -TypeName PSObject
            $IPTVLine | Add-Member -Name 'Multicast IP Address'   -MemberType Noteproperty -Value $Json[$IPTV].address
            $IPTVLine | Add-Member -Name 'Destination IP Address' -MemberType Noteproperty -Value $Json[$IPTV].ipaddress
            $IPTVLine | Add-Member -Name 'Image Logo Name'        -MemberType Noteproperty -Value $Json[$IPTV].logo
            $IPTVLine | Add-Member -Name 'Offset Logo'            -MemberType Noteproperty -Value $Json[$IPTV].logooffset
            $IPTVLine | Add-Member -Name 'Channel Name'           -MemberType Noteproperty -Value $Json[$IPTV].name
            $IPTVLine | Add-Member -Name 'Channel Number'         -MemberType Noteproperty -Value $Json[$IPTV].number
            $IPTVLine | Add-Member -Name 'Channel Status'         -MemberType Noteproperty -Value (Get-Status -Status $Json[$IPTV].receipt)
            $IPTVLine | Add-Member -Name 'EPG Channel ID'         -MemberType Noteproperty -Value $Json[$IPTV].epgid
            
            # Add lines to $Array
            $Array += $IPTVLine
            
            # Go to next line
            $IPTV ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXIPTVDiags {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0]
    
    # Create New PSObject and add values to array
    $IPTVDiagsLine = New-Object -TypeName PSObject
    $IPTVDiagsLine | Add-Member -Name 'Date'                      -MemberType Noteproperty -Value $(Edit-Date -Date $Json.now) # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name 'IGMP State'                -MemberType Noteproperty -Value (Get-State -State $Json.igmp.state) # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name 'IGMP Status'               -MemberType Noteproperty -Value (Get-Status -Status $Json.igmp.enable) # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name 'IPTV Multicast State'      -MemberType Noteproperty -Value (Get-State -State $Json.iptv.multicast.state)
    If ($Json.iptv.multicast.date) {$IPTVDiagsLine | Add-Member   -Name 'IPTV Multicast Date' -MemberType Noteproperty -Value $(Edit-Date -Date $Json.iptv.multicast.date)}
    Else {$IPTVDiagsLine | Add-Member -Name 'IPTV Multicast Date' -MemberType Noteproperty -Value ""}
    $IPTVDiagsLine | Add-Member -Name 'IPTV Platform State'       -MemberType Noteproperty -Value (Get-State -State $Json.iptv.platform.state)
    If ($Json.iptv.platform.date) {$IPTVDiagsLine | Add-Member    -Name 'IPTV Platform Date' -MemberType Noteproperty -Value $(Edit-Date -Date $Json.iptv.platform.date)}
    Else {$IPTVDiagsLine | Add-Member -Name 'IPTV Platform Date' -MemberType Noteproperty -Value ""}
    
    # Add lines to $Array
    $Array += $IPTVDiagsLine
    
    Return $Array
}

#endregion IPTV

#region LAN

Function Get-BBOXLANIPConfig {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create arrays
    $IP = @()
    
    # Select $JSON 's head
    $Json = $Json.lan.ip
    
    # Create New PSObject and add values to array
    
    If ($global:ResolveDnsName -eq 'Y') {
        $HostName = $(Resolve-DnsName -Name $Json.ipaddress -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost
    }
    Else {
        $HostName = 'User ask to not resolved the IPadress'
    }
    
    $IPLine = New-Object -TypeName PSObject
    $IPLine | Add-Member -Name 'State'                           -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $IPLine | Add-Member -Name 'MTU (Maximum transmission unit)' -MemberType Noteproperty -Value $Json.mtu
    $IPLine | Add-Member -Name 'IPV4 Address'                    -MemberType Noteproperty -Value $Json.ipaddress
    $IPLine | Add-Member -Name 'IPV4 NetMask'                    -MemberType Noteproperty -Value $Json.netmask
    $IPLine | Add-Member -Name 'HostName (DNS)'                  -MemberType Noteproperty -Value $HostName
    $IPLine | Add-Member -Name 'IPV6 Statut'                     -MemberType Noteproperty -Value (Get-Status -Status $Json.ip6enable)
    $IPLine | Add-Member -Name 'IPV6 State'                      -MemberType Noteproperty -Value (Get-State -State $Json.ip6state)
    $IPLine | Add-Member -Name 'IPV6 Address'                    -MemberType Noteproperty -Value $($Json.ip6address.ipaddress -join ",")
    $IPLine | Add-Member -Name 'IPV6 Address Status'             -MemberType Noteproperty -Value $($Json.ip6address.status -join ",")
    $IPLine | Add-Member -Name 'IPV6 Address Valid Time'         -MemberType Noteproperty -Value $($($Json.ip6address.valid | ForEach-Object {Edit-Date -Date $_} | Select-Object -Unique) -join ",")
    $IPLine | Add-Member -Name 'IPV6 Address Preferred Time'     -MemberType Noteproperty -Value $($($Json.ip6address.preferred | ForEach-Object {Edit-Date -Date $_} | Select-Object -Unique) -join ",")
    $IPLine | Add-Member -Name 'IPV6 Prefix'                     -MemberType Noteproperty -Value $($Json.ip6prefix.prefix -join ",")
    $IPLine | Add-Member -Name 'IPV6 Prefix Status'              -MemberType Noteproperty -Value $($Json.ip6prefix.status -join ",")
    $IPLine | Add-Member -Name 'IPV6 Prefix Valid Time'          -MemberType Noteproperty -Value $($($Json.ip6prefix.valid | ForEach-Object {Edit-Date -Date $_} | Select-Object -Unique) -join ",")
    $IPLine | Add-Member -Name 'IPV6 Prefix Preferred Time'      -MemberType Noteproperty -Value $($($Json.ip6prefix.preferred | ForEach-Object {Edit-Date -Date $_} | Select-Object -Unique) -join ",")
    $IPLine | Add-Member -Name 'MAC Address'                     -MemberType Noteproperty -Value $Json.mac
    $IPLine | Add-Member -Name 'Box Hostname'                    -MemberType Noteproperty -Value $Json.hostname
    $IPLine | Add-Member -Name 'Box Domain'                      -MemberType Noteproperty -Value $Json.domain
    $IPLine | Add-Member -Name 'Box Aliases (DNS)'               -MemberType Noteproperty -Value $Json.aliases.replace(' ',',')
    
    $IP += $IPLine
    
    Return $IP
}

Function Get-BBOXLANIPSwitchConfig {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create arrays
    $Array = @()
    
    # Select $JSON 's head
    $Json = $json.lan.switch.ports
    $Port = 0
    
    While ($Port -lt $json.Count) {
        
        # Create New PSObject and add values to array
        $PortLine = New-Object -TypeName PSObject
        $PortLine | Add-Member -Name 'Port number'  -MemberType Noteproperty -Value $Json[$Port].id
        $PortLine | Add-Member -Name 'State'        -MemberType Noteproperty -Value $Json[$Port].state
        $PortLine | Add-Member -Name 'Link Mode'    -MemberType Noteproperty -Value $Json[$Port].link_mode
        $PortLine | Add-Member -Name 'Is Blocked ?' -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Port].blocked)
        $PortLine | Add-Member -Name 'Flickering ?' -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Port].flickering)
        
        $Array += $PortLine
        
        # Go to next line
        $Port ++
    }
    
    Return $Array
}

Function Get-BBOXLANStats {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.lan.stats
    
    # Create New PSObject and add values to array

    # RX
    $LanStatsLine = New-Object -TypeName PSObject
    $LanStatsLine | Add-Member -Name 'RX Bytes'            -MemberType Noteproperty -Value $Json.rx.bytes
    $LanStatsLine | Add-Member -Name 'RX Packets'          -MemberType Noteproperty -Value $Json.rx.packets
    $LanStatsLine | Add-Member -Name 'RX Packets Errors'   -MemberType Noteproperty -Value $Json.rx.packetserrors
    $LanStatsLine | Add-Member -Name 'RX Packets Discards' -MemberType Noteproperty -Value $Json.rx.packetsdiscards
    
    # TX
    $LanStatsLine | Add-Member -Name 'TX Bytes'            -MemberType Noteproperty -Value $Json.tx.bytes
    $LanStatsLine | Add-Member -Name 'TX Packets'          -MemberType Noteproperty -Value $Json.tx.packets
    $LanStatsLine | Add-Member -Name 'TX Packets Errors'   -MemberType Noteproperty -Value $Json.tx.packetserrors
    $LanStatsLine | Add-Member -Name 'TX Packets Discards' -MemberType Noteproperty -Value $Json.tx.packetsdiscards
    
    # Add lines to $Array
    $Array += $LanStatsLine
    
    Return $Array
}

Function Get-BBOXLANPortStats {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.lan.stats.port
    
    If ($Json.count -ne 0) {
        
        $Line = 0
        
        While ($Line -lt $Json.count) {
            
            # Create New PSObject and add values to array
            $LANPortStats = New-Object -TypeName PSObject
            $LANPortStats | Add-Member -Name 'Port Number'  -MemberType Noteproperty -Value $Json[$Line].index # Since Version : 23.7.8
            
            # RX
            $LANPortStats | Add-Member -Name 'RX Bandwidth' -MemberType Noteproperty -Value $Json[$Line].rx.bandwidth # Since Version : 23.7.8
            $LANPortStats | Add-Member -Name 'RX Bytes'     -MemberType Noteproperty -Value $Json[$Line].rx.bytes # Since Version : 23.7.8
            $LANPortStats | Add-Member -Name 'RX Packets'   -MemberType Noteproperty -Value $Json[$Line].rx.packets # Since Version : 23.7.8
            
            # TX
            $LANPortStats | Add-Member -Name 'TX Bandwidth' -MemberType Noteproperty -Value $Json[$Line].tx.bandwidth # Since Version : 23.7.8
            $LANPortStats | Add-Member -Name 'TX Bytes'     -MemberType Noteproperty -Value $Json[$Line].tx.bytes # Since Version : 23.7.8
            $LANPortStats | Add-Member -Name 'TX Packets'   -MemberType Noteproperty -Value $Json[$Line].tx.packets # Since Version : 23.7.8

            # Add lines to $Array
            $Array += $LANPortStats
            
            # Go to next line
            $Line ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXLANAlerts {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName.list
    
    If ($Json.count -ne 0) {
        
        $Line = 0
        
        While ($Line -lt $Json.count) {
            
            # $RecoveryDate formatting
            If (-not ([string]::IsNullOrEmpty($Json[$Line].param))) {
                $RecoveryDate = $Json[$Line].recovery_date
            }
            Else {
                $RecoveryDate = $Json[$Line].recovery_date
            }
            
            # $SolvedTime formatting
            If ($Json[$Line].total_duration -ne 0) {
                
                $SolvedTime = $Json[$Line].total_duration
            }
            Else {
                $SolvedTime = '0'
            }
            
            # $Params formatting
            If ((-not (([string]::IsNullOrEmpty($Json[$Line].param)))) -and ($Json[$Line].param -match ';' )) {
                
                $Params = ($Json[$Line].param).split(';')
            }
            
            # $Details formatting
            Switch ($Json[$Line].ident) {
                
                ALERT_DEVICE_UP                  {$Details = "Hostname : $($Params[2]), IP Address : $($Params[1]), MAC Address : $($Params[0])";Break}
                
                ALERT_DEVICE_DOWN                {$Details = "Hostname : $($Params[2]), IP Address : $($Params[1]), MAC Address : $($Params[0])";Break}
                
                ALERT_DHCLIENT_ACK               {$Details = $Json[$Line].param;Break}
                
                ALERT_DHCLIENT_REQUEST           {$Details = $Json[$Line].param;Break}
                
                ALERT_DHCLIENT_DISCOVER          {$Details = $Json[$Line].param;Break}
                
                ALERT_DIAG_SUCCESS               {$Details = $Json[$Line].param;Break}
                
                ALERT_DISPLAY_STATE              {$Details = $Json[$Line].param;Break}
                
                ALERT_LAN_API_LOCKED             {$Details = "IP Address Source : $($Params[0]), Hostname : $($Params[3]), Failed Attempt Count : $($Params[1]), Block Time : $($Params[2]) min";Break}
                
                ALERT_LAN_OFFLINE_IP             {$Details = "IP Address Source : $($Params[0]), Hostname : $($Params[2]), IP Address destination : $($Params[1])";Break}
                
                ALERT_LAN_PORT_UP                {$Details = "Box Switch Port : $($Json[$Line].param)";Break}
                
                ALERT_LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Associated Hostname : $($Params[2]), IP Address in conflict : $($Params[1])";Break}
                
                ALERT_LAN_DUP_IP                 {$Details = "IP Address conflict between : $($Json[$Line].param)";Break}
                
                ALERT_LOGIN_LOCAL                {$Details = "Hostname : $($Params[1]), IP Address : $($Params[0])";Break}
                
                ALERT_MAIL_ERROR                 {$Details = "Error to send alert to the Mail Address : $($Json[$Line].param)";Break}
                
                ALERT_NTP_SYNCHRONIZATION        {$Details = $Json[$Line].param}
                
                ALERT_VOIP_INCOMING_CALL_END     {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])";Break}
                
                ALERT_VOIP_INCOMING_CALL_RINGING {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])";Break}
                
                ALERT_VOIP_INCOMING_CALL_START   {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Params[0]), Number : $($Params[1])";Break}
                
                ALERT_VOIP_ONHOOK                {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$Line].param)";Break}
                
                ALERT_VOIP_OFFHOOK               {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$Line].param)";Break}
                
                ALERT_VOIP_REGISTERED            {$Details = "Phone Line : $(Get-Phoneline -Phoneline $Json[$Line].param)";Break}
                
                ALERT_WAN_ROUTE_ADDED            {$Details = "IP Address : $($Params[0])";Break}
                
                ALERT_WAN_UPNP_ADD               {$Details = "IP Address : $($Params[0]), Local Port : $($Params[1]), External Port : $($Params[2])";Break}
                
                ALERT_WAN_UPNP_REMOVE            {$Details = "IP Address : $($Params[0]), Port : $($Params[1])";Break}
                
                ALERT_WIFI_UP                    {$Details = $Json[$Line].param;Break}
                
                Default                          {$Details = $Json[$Line].param;Break}
            }
            
            # Create New PSObject and add values to array
            $AlertLine = New-Object -TypeName PSObject
            $AlertLine | Add-Member -Name 'ID'                -MemberType Noteproperty -Value $Json[$Line].id
            $AlertLine | Add-Member -Name 'Alert type'        -MemberType Noteproperty -Value $Json[$Line].ident
            $AlertLine | Add-Member -Name 'Details'           -MemberType Noteproperty -Value $Details # Calculate field not inclued in API
            $AlertLine | Add-Member -Name 'First Date seen'   -MemberType Noteproperty -Value $Json[$Line].first_date
            $AlertLine | Add-Member -Name 'Last Date seen'    -MemberType Noteproperty -Value $Json[$Line].last_date
            $AlertLine | Add-Member -Name 'Recovery Date'     -MemberType Noteproperty -Value $RecoveryDate
            $AlertLine | Add-Member -Name 'Nb Occurences'     -MemberType Noteproperty -Value $Json[$Line].count
            $AlertLine | Add-Member -Name 'Solved Time'       -MemberType Noteproperty -Value $SolvedTime # Calculate filed not inclued in API
            $AlertLine | Add-Member -Name 'Notification Type' -MemberType Noteproperty -Value $Json[$Line].level
            
            # Add lines to $Array
            $Array += $AlertLine
            
            # Go to next line
            $Line ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

#endregion LAN

#region NAT

Function Get-BBOXNAT {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].nat
    
    # Get Configured Rules 
    $RulesConfig = Get-BBOXNATRules -UrlToGo $UrlToGo
    $EnableRulesCount  = $($RulesConfig.Status | Where-Object {$_ -match "Enable"}).count
    $DisableRulesCount = $($RulesConfig.Status | Where-Object {$_ -match "Disable"}).count

    # Create New PSObject and add values to array
    $NATLine = New-Object -TypeName PSObject
    $NATLine | Add-Member -Name 'Service'                    -MemberType Noteproperty -Value 'NAT/PAT'
    $NATLine | Add-Member -Name 'Status'                     -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $NATLine | Add-Member -Name 'Nb configured Rules'        -MemberType Noteproperty -Value $Json.rules.count
    $NATLine | Add-Member -Name 'Nb Enable Rules'            -MemberType Noteproperty -Value $EnableRulesCount
    $NATLine | Add-Member -Name 'Nb Disable Rules'           -MemberType Noteproperty -Value $DisableRulesCount 
    $NATLine | Add-Member -Name 'Opened Internal IP Address' -MemberType Noteproperty -Value $($($RulesConfig.'Internal IP Address' | Select-Object -Unique) -join ",")
    $NATLine | Add-Member -Name 'Opened Internal Port'       -MemberType Noteproperty -Value $($($RulesConfig.'Internal Port' | Select-Object -Unique) -join ",")
    $NATLine | Add-Member -Name 'Opened External IP Address' -MemberType Noteproperty -Value $($($RulesConfig.'External IP Address' | Select-Object -Unique) -join ",")
    $NATLine | Add-Member -Name 'Opened External Port'       -MemberType Noteproperty -Value $($($RulesConfig.'External Port' | Select-Object -Unique) -join ",")
    $NATLine | Add-Member -Name 'Configured Protocols'       -MemberType Noteproperty -Value $($($RulesConfig.Protocol | Select-Object -Unique) -join ",")
    
    # Add lines to $Array
    $Array += $NATLine
    
    Return $Array
}

Function Get-BBOXNATDMZ {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.nat.dmz
    
    If ($Json.ipaddress -and ($global:ResolveDnsName -eq 'Y')) {
        $dns = $(Resolve-DnsName -Name $($Json.ipaddress) -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost
    }
    Else {
        $dns = ''
    }
    
    # Create New PSObject and add values to array
    $NATDMZLine = New-Object -TypeName PSObject
    $NATDMZLine | Add-Member -Name 'Service'            -MemberType Noteproperty -Value 'DMZ'
    $NATDMZLine | Add-Member -Name 'State'              -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $NATDMZLine | Add-Member -Name 'Status'             -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $NATDMZLine | Add-Member -Name 'IP Address'         -MemberType Noteproperty -Value $Json.ipaddress
    $NATDMZLine | Add-Member -Name 'HostName'           -MemberType Noteproperty -Value $dns
    $NATDMZLine | Add-Member -Name 'DNS Protect Status' -MemberType Noteproperty -Value (Get-State -State $Json.dnsprotect)
    
    # Add lines to $Array
    $Array += $NATDMZLine
    
    Return $Array
}

Function Get-BBOXNATRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.nat.rules
    
    If ($Json.count -ne 0) {
        
        If ($global:ResolveDnsName -eq 'Y') {
            $Line = 0
            While ($Line -lt $Json.Count) {
                    
                $IPAdresses += $Json[$Line].srcip
                $IPAdresses += $Json[$Line].dstip
                $Line ++
            }
            
            $IPAdresses = $IPAdresses | Select-Object -Unique
            
            $IPAdresses | ForEach-Object {
                
                $IsValidIPAddress = [ipaddress]$_
                If ($IsValidIPAddress.AddressFamily -eq "InterNetwork") {
                
                    Try {
                        $Hostname = $(Resolve-DnsName -Name $_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost
                    }
                    Catch {
                        $Hostname = ''
                    }
                    If ($Hostname) {
                        $Hostname = $Hostname -join ","
                    }
                    
                    $DNS = New-Object -TypeName PSObject
                    $DNS | Add-Member -Name 'IPaddress' -MemberType Noteproperty -Value $_
                    $DNS | Add-Member -Name 'Hostname'  -MemberType Noteproperty -Value $Hostname
                    $Referential += $DNS
                }
            }
        }
        
        $NAT = 0
        
        While ($NAT -lt $Json.count) {
            
            If ($global:ResolveDnsName -eq 'Y') {
                $ExternalHostname = $($Referential | Where-Object {$_ -match $Json[$NAT].externalip}).Hostname
                $InternalHostname = $($Referential | Where-Object {$_ -match $Json[$NAT].internalip}).Hostname
            }
            Else {
                $ExternalHostname = $null
                $InternalHostname = $null
            }
            
            # Create New PSObject and add values to array
            $NATLine = New-Object -TypeName PSObject
            $NATLine | Add-Member -Name 'ID'                  -MemberType Noteproperty -Value $Json[$NAT].id
            $NATLine | Add-Member -Name 'Status'              -MemberType Noteproperty -Value $(Get-Status -Status $Json[$NAT].enable)
            $NATLine | Add-Member -Name 'Description'         -MemberType Noteproperty -Value $Json[$NAT].description
            $NATLine | Add-Member -Name 'External IP Address' -MemberType Noteproperty -Value $Json[$NAT].externalip
            $NATLine | Add-Member -Name 'External Hostname'   -MemberType Noteproperty -Value $ExternalHostname
            $NATLine | Add-Member -Name 'External Port'       -MemberType Noteproperty -Value $Json[$NAT].externalport
            $NATLine | Add-Member -Name 'Internal Port'       -MemberType Noteproperty -Value $Json[$NAT].internalport
            $NATLine | Add-Member -Name 'Internal IP Address' -MemberType Noteproperty -Value $Json[$NAT].internalip
            $NATLine | Add-Member -Name 'Internal Hostname'   -MemberType Noteproperty -Value $InternalHostname
            $NATLine | Add-Member -Name 'Protocol'            -MemberType Noteproperty -Value $Json[$NAT].protocol
            
            # Add lines to $Array
            $Array += $NATLine
            
            # Go to next line
            $NAT ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXNATRulesID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $RuleIDs = Get-BBOXNATRules -UrlToGo $UrlToGo
    If ($global:TriggerExportConfig -eq $true) {
        $RuleID = $RuleIDs | Select-Object -Property ID,Description -First 1
    }
    Else {
        $RuleID = $RuleIDs | Select-Object -Property ID,Description | Out-GridView -Title "NAT Rules List" -OutputMode Single
    }
    $HostRules = $RuleIDs | Where-Object {$_.ID -ilike $RuleID.id}
    
    Return $HostRules
}

#endregion NAT

#region Notification

Function Get-BBOXNOTIFICATIONConfig {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $NOTIFICATIONLine = New-Object -TypeName PSObject
    $NOTIFICATIONLine | Add-Member -Name 'Service'                        -MemberType Noteproperty -Value $APIName
    $NOTIFICATIONLine | Add-Member -Name 'State'                          -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $NOTIFICATIONLine | Add-Member -Name 'Nb Alerts Configured'           -MemberType Noteproperty -Value $Json.alerts.count
    $NOTIFICATIONLine | Add-Member -Name 'Nb Alerts Configured Enable'    -MemberType Noteproperty -Value $($Json.alerts | Where-Object {$_.Enable -eq 1}).count
    $NOTIFICATIONLine | Add-Member -Name 'Nb Alerts Configured Disable'   -MemberType Noteproperty -Value $($Json.alerts | Where-Object {$_.Enable -eq 0}).count
    $NOTIFICATIONLine | Add-Member -Name 'Nb Events Configured'           -MemberType Noteproperty -Value $Json.events.count
    $NOTIFICATIONLine | Add-Member -Name 'Nb Contacts Configured'         -MemberType Noteproperty -Value $Json.contacts.count
    $NOTIFICATIONLine | Add-Member -Name 'Nb Contacts Configured Enable'  -MemberType Noteproperty -Value $($Json.contacts | Where-Object {$_.Enable -eq 1}).count
    $NOTIFICATIONLine | Add-Member -Name 'Nb Contacts Configured Disable' -MemberType Noteproperty -Value $($Json.contacts | Where-Object {$_.Enable -eq 0}).count
    $NOTIFICATIONLine | Add-Member -Name 'Contacts Mail List'             -MemberType Noteproperty -Value ($Json.contacts.mail -join ",")
    
    # Add lines to $Array
    $Array += $NOTIFICATIONLine
    
    Return $Array
}

Function Get-BBOXNOTIFICATIONAlerts {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.notification.Alerts
    
    If ($Json.Count -ne 0) {
        
        $Contacts = Get-BBOXNOTIFICATIONContacts -UrlToGo $($UrlToGo -replace("alerts","contacts"))
        $Index = 0
        
        While ($Index -lt $Json.Count) {
            
            If ($Null -eq $Dests) {
                $Mail = $Contacts.mail -join ","
            }
            Else {
                $Mail = @()
                $Dests = $Json[$Index].action.mail.dests
                
                Foreach ($Dest in $Dests) {
                    
                    $Mail += $($Contacts | Where-Object {$Dest -eq $_.id}).mail
                }
                $Mail = $Mail -join ","
            }
            
            # Create New PSObject and add values to array
            $NOTIFICATIONLine = New-Object -TypeName PSObject
            $NOTIFICATIONLine | Add-Member -Name 'ID'              -MemberType Noteproperty -Value $Json[$Index].id
            $NOTIFICATIONLine | Add-Member -Name 'State'           -MemberType Noteproperty -Value (Get-State -State $Json[$Index].enable)
            $NOTIFICATIONLine | Add-Member -Name 'Name'            -MemberType Noteproperty -Value $Json[$Index].name # To be review due to syntaxe
            $NOTIFICATIONLine | Add-Member -Name 'Events'          -MemberType Noteproperty -Value $Json[$Index].events
            $NOTIFICATIONLine | Add-Member -Name 'Action Type'     -MemberType Noteproperty -Value $Json[$Index].action.type
            $NOTIFICATIONLine | Add-Member -Name 'Send Mail Delay' -MemberType Noteproperty -Value $Json[$Index].action.delay
            $NOTIFICATIONLine | Add-Member -Name 'Contact ID'      -MemberType Noteproperty -Value $Json[$Index].action.mail.dests
            $NOTIFICATIONLine | Add-Member -Name 'Mail'            -MemberType Noteproperty -Value $Mail
            
            # Add lines to $Array
            $Array += $NOTIFICATIONLine
            
            # Go to next line
            $Index ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXNOTIFICATIONContacts {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.notification.contacts
    
    If ($Json.Count -ne 0) {
        
        $Contacts = 0
        
        While ($Contacts -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $ContactsLine = New-Object -TypeName PSObject
            $ContactsLine | Add-Member -Name 'ID'    -MemberType Noteproperty -Value $Json[$Contacts].id
            $ContactsLine | Add-Member -Name 'State' -MemberType Noteproperty -Value (Get-Status -Status $Json[$Contacts].enable)
            $ContactsLine | Add-Member -Name 'Name'  -MemberType Noteproperty -Value $Json[$Contacts].name
            $ContactsLine | Add-Member -Name 'Mail'  -MemberType Noteproperty -Value $Json[$Contacts].mail
            
            # Add lines to $Array
            $Array += $ContactsLine
            
            # Go to next line
            $Contacts ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXNOTIFICATIONEvents {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.notification.events
    
    If ($Json.Count -ne 0) {
        
        $Index = 0
        
        While ($Index -lt $Json.Count) {
            
            $Split = $Json[$Index].name -split "_"
            
            If ($Json[$Index].name -match $Global:NotificationEventType) {
                
                $Temp = $Split[1]
                
                Switch ($Temp) {
                    
                    ALARM   {$Type = $Split[1]
                             $Scope = $Split[2]
                             $ShortName = $($Json[$Index].name.Split("_",3))[-1]
                            }
                    NOTIFY  {$Type = $Split[1]
                             $Scope = $Split[2]
                             $ShortName = $($Json[$Index].name.Split("_",3))[-1]
                            }
                    Default {$Type = $Split[0]
                             $Scope = $Split[2]
                             $ShortName = $($Json[$Index].name.Split("_",3))[-1]
                            }
                }
            }
            Else {
                $Type = $Split[0]
                $Scope = $Split[1]
                $ShortName = $($Json[$Index].name.Split("_",2))[-1]
            }
            
            # Create New PSObject and add values to array
            $EventsLine = New-Object -TypeName PSObject
            $EventsLine | Add-Member -Name 'Index'       -MemberType Noteproperty -Value $Index
            $EventsLine | Add-Member -Name 'Type'        -MemberType Noteproperty -Value $Type
            $EventsLine | Add-Member -Name 'Scope'       -MemberType Noteproperty -Value $Scope
            $EventsLine | Add-Member -Name 'Category'    -MemberType Noteproperty -Value $($Json[$Index].category) # Syntaxe to be reviewed
            $EventsLine | Add-Member -Name 'Name'        -MemberType Noteproperty -Value $($Json[$Index].name)
            $EventsLine | Add-Member -Name 'Short Name'  -MemberType Noteproperty -Value $ShortName
            $EventsLine | Add-Member -Name 'Message'     -MemberType Noteproperty -Value $($Json[$Index].humanReadable) # Syntaxe to be reviewed
            $EventsLine | Add-Member -Name 'Description' -MemberType Noteproperty -Value $($Json[$Index].description) # Syntaxe to be reviewed
            
            # Add lines to $Array
            $Array += $EventsLine
            
            # Go to next line
            $Index ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

#endregion Notification

#region PARENTAL CONTROL

Function Get-BBOXParentalControl {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName.scheduler
    
    # Create New PSObject and add values to array
    $ParentalControlLine = New-Object -TypeName PSObject
    $ParentalControlLine | Add-Member -Name 'Service'        -MemberType Noteproperty -Value 'Parental Control'
    $ParentalControlLine | Add-Member -Name 'Date'           -MemberType Noteproperty -Value $(Edit-Date -Date $Json.now)
    $ParentalControlLine | Add-Member -Name 'State'          -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $ParentalControlLine | Add-Member -Name 'Default Policy' -MemberType Noteproperty -Value $Json.defaultpolicy
    
    # Add lines to $Array
    $Array += $ParentalControlLine
    
    Return $Array
}

Function Get-BBOXParentalControlScheduler {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.parentalcontrol.scheduler
    
    $Scheduler = 0
    
    # Create New PSObject and add values to array
    $SchedulerLine = New-Object -TypeName PSObject
    $SchedulerLine | Add-Member -Name 'Service'     -MemberType Noteproperty -Value 'Parental Control Scheduler'
    $SchedulerLine | Add-Member -Name 'Date'        -MemberType Noteproperty -Value $(Edit-Date -Date $Json.now)
    $SchedulerLine | Add-Member -Name 'State'       -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $SchedulerLine | Add-Member -Name 'Rules count' -MemberType Noteproperty -Value $Json.rules.count
    
    # Add lines to $Array
    $Array += $SchedulerLine
    
    # Go to next line
    $Scheduler ++
    
    Return $Array
}

Function Get-BBOXParentalControlSchedulerRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.parentalcontrol.scheduler.rules
    
    If ($Json.Count -ne 0) {
        
        $Scheduler = 0
        
        While ($Scheduler -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $SchedulerLine = New-Object -TypeName PSObject
            $SchedulerLine | Add-Member -Name 'ID'         -MemberType Noteproperty -Value $($Json[$Scheduler].id)
            $SchedulerLine | Add-Member -Name 'State'      -MemberType Noteproperty -Value (Get-State -State $Json[$Scheduler].enable)
            $SchedulerLine | Add-Member -Name 'Name'       -MemberType Noteproperty -Value $Json[$Scheduler].name # Not define for Fast5330b-r1
            $SchedulerLine | Add-Member -Name 'Start Time' -MemberType Noteproperty -Value "From : $($Json[$Scheduler].start.day), $($Json[$Scheduler].start.hour)h0$($Json[$Scheduler].start.minute)"
            $SchedulerLine | Add-Member -Name 'End Time'   -MemberType Noteproperty -Value "To : $($Json[$Scheduler].end.day), $($Json[$Scheduler].end.hour)h0$($Json[$Scheduler].end.minute)"
            
            # Add lines to $Array
            $Array += $SchedulerLine
            
            # Go to next line
            $Scheduler ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

#endregion PARENTAL CONTROL

#region PROFILE

Function Get-BBOXProfileConsumption {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.profile
    
    # Create New PSObject and add values to array
    $ProfileLine = New-Object -TypeName PSObject
    $ProfileLine | Add-Member -Name 'Service'  -MemberType Noteproperty -Value 'Profile'
    $ProfileLine | Add-Member -Name 'Login'    -MemberType Noteproperty -Value $($Json.login)
    $ProfileLine | Add-Member -Name 'Password' -MemberType Noteproperty -Value '*************'
    
    # Add lines to $Array
    $Array += $ProfileLine
    
    Return $Array
}

#endregion PROFILE

#region REMOTE

Function Get-BBOXREMOTEProxyWOL {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.Proxywol
    
    # Create New PSObject and add values to array
    $ProfileLine = New-Object -TypeName PSObject
    $ProfileLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'Remote Proxy WOL'
    $ProfileLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $ProfileLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    
    # Add lines to $Array
    $Array += $ProfileLine
    
    Return $Array
}

#endregion REMOTE

#region SERVICES

Function Get-BBOXSERVICES {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # FIREWALL
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'FIREWALL'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.firewall.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.firewall.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value "$($Json.firewall.nbrules) rule(s)"
    $Array += $ServiceLine
    
    # DYNDNS
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'DYNDNS'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.dyndns.state)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.dyndns.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value "$($Json.dyndns.nbrules) configuration(s)"
    $Array += $ServiceLine
    
    # DHCPV4
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'DHCPv4'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.dhcp.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.dhcp.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value "$($Json.dhcp.nbrules) host(s)"
    $Array += $ServiceLine
    
    # DHCPV6 New Since Version 19.2.12
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'DHCPv6'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.dhcp6.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.dhcp6.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value "$($Json.dhcp6.nbrules) host(s)"
    $Array += $ServiceLine
    
    # NAT/PAT
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'NAT/PAT'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.nat.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.nat.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value "$($Json.nat.nbrules) rule(s)"
    $Array += $ServiceLine
    
    # GAMER MODE
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'GAMER MODE'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.gamermode.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.gamermode.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value ''
    $Array += $ServiceLine
    
    # UPNP/IGD
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'UPNP/IGD'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.upnp.igd.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.upnp.igd.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value "$($Json.upnp.igd.nbrules) rule(s)"
    $Array += $ServiceLine
    
    # WOL PROXY
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'WOL PROXY'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.remote.proxywol.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.remote.proxywol.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value "IP address : $($Json.remote.proxywol.ip)"
    $Array += $ServiceLine
    
    # ADMIN / Box REMOTE ACCESS
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'REMOTE ACCESS'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.remote.admin.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.remote.admin.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value "Activable : $(Get-YesNoAsk -YesNoAsk $Json.remote.admin.activable), Allowed IPV4 : $($Json.remote.admin.ip), Allowed IPV6 : $($Json.remote.admin.ip6address), External port : $($Json.remote.admin.port), Delay : $($Json.remote.admin.duration)"
    $Array += $ServiceLine
    
    # PARENTAL CONTROL
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'PARENTAL CONTROL'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value ''
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.parentalcontrol.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value ''
    $Array += $ServiceLine
    
    # WIFI SCHEDULER
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'WIFI SCHEDULER'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value ''
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.wifischeduler.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value ''
    $Array += $ServiceLine
    
    # VOIP SCHEDULER
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'VOIP SCHEDULER'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value ''
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.voipscheduler.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value ''
    $Array += $ServiceLine
    
    # NOTIFICATION
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'Notification'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value ''
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-Status -Status $Json.notification.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value "$($Json.notification.enable) active rules"
    $Array += $ServiceLine
    
    # WIFI HOTSPOT
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'WIFI HOTSPOT'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.hotspot.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.hotspot.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value ''
    $Array += $ServiceLine
    
    # SAMBA
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'USB SAMBA STORAGE'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.usb.samba.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.usb.samba.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value ''
    $Array += $ServiceLine
    
    # PRINTER
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'USB PRINTER'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.usb.printer.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.usb.printer.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value ''
    $Array += $ServiceLine
    
    # DLNA
    $ServiceLine = New-Object -TypeName PSObject
    $ServiceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'DLNA'
    $ServiceLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.usb.dlna.status)
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.upnp.igd.enable)
    $ServiceLine | Add-Member -Name 'Params'  -MemberType Noteproperty -Value ''
    $Array += $ServiceLine

    Return $Array
}

#endregion SERVICES

#region SUMMARY

Function Get-BBOXSUMMARY {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Calculate Intermediary values
    
    #IPTV Devices list
    $I = 0
    $IPTVSourceIPAddress      = @()
    $IPTVDestinationIPAddress = @()
    $IPTVReceptionInProgress  = @()
    $IPTVChannelNumber        = @()
    
    While ($I -lt $Json.iptv.count) {
        
        $IPTVSourceIPAddress      += $($Json.iptv[$I].address)
        $IPTVDestinationIPAddress += $($Json.iptv[$I].ipaddress)
        $IPTVReceptionInProgress  += $($Json.iptv[$I].receipt)
        $IPTVChannelNumber        += $($Json.iptv[$I].number)
        
        # Go to next line
        $I++
    }
    $IPTV = $($IPTV -join ',')
    
    # USB Printers list
    $J = 0
    $PrinterName  = @()
    $PrinterState = @()
    
    While ($J -lt $Json.usb.printer.count) {
        
        $PrinterName += $($Json.usb.printer[$J].product)
        $PrinterState += $($Json.usb.printer[$J].state)
        
        # Go to next line
        $J++
    }
    $PrinterName = $($PrinterName -join ',')
    $PrinterState = $($PrinterState -join ',')
    
    # USB Samba Storage
    $K = 0
    $StorageLabel = @()
    $StorageState = @()
    
    While ($k -lt $Json.usb.storage.count) {
        
        # Get data
        $StorageLabel += $($Json.usb.storage[$K].label)
        $StorageState += $($Json.usb.storage[$K].state)
        
        # Go to next line
        $K++
    }
    $StorageLabel = $($StorageLabel -join ',')
    $Storage = $($Storage -join ',')
    
    # Hosts List
    $L = 0
    $Hosts = @()
    $IPAdresses = @()
    
    While ($L -lt $Json.hosts.count) {
        
        # Get data
        $Hosts += $($Json.hosts[$L].hostname)
        $IPAdresses += $($Json.hosts[$L].ipaddress)
        
        # Go to next line
        $L++
    }
    $Hosts = $($Hosts -join ',')
    $IPAdresses = $($IPAdresses -join ',')
    
    # StatusRemaning
    $ParentalControlStatusRemaining = New-TimeSpan -Seconds $Json.services.parentalcontrol.statusRemaining
    $WifiSchedulerStatusRemaining   = New-TimeSpan -Seconds $Json.services.wifischeduler.statusRemaining
    $VOIPSchedulerStatusRemaining   = New-TimeSpan -Seconds $Json.services.voipscheduler.statusRemaining
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name 'Date'                              -MemberType Noteproperty -Value (Edit-Date -Date $Json.now)
    $DeviceLine | Add-Member -Name 'User Authentication State'         -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.authenticated)
    $DeviceLine | Add-Member -Name 'Luminosity State'                  -MemberType Noteproperty -Value (Get-State -State $Json.display.state)
    $DeviceLine | Add-Member -Name 'Luminosity Power (%)'              -MemberType Noteproperty -Value $Json.display.luminosity
    $DeviceLine | Add-Member -Name 'Internet State'                    -MemberType Noteproperty -Value (Get-State -State $Json.internet.state)
    $DeviceLine | Add-Member -Name 'VOIP Status'                       -MemberType Noteproperty -Value (Get-Status -Status $Json.voip[0].status)
    $DeviceLine | Add-Member -Name 'VOIP Call State'                   -MemberType Noteproperty -Value $Json.voip[0].callstate
    $DeviceLine | Add-Member -Name 'VOIP Message count'                -MemberType Noteproperty -Value $Json.voip[0].message
    $DeviceLine | Add-Member -Name 'VOIP Call failed'                  -MemberType Noteproperty -Value $Json.voip[0].notanswered
    $DeviceLine | Add-Member -Name 'IPTV Source IP Address'            -MemberType Noteproperty -Value $($IPTVSourceIPAddress -join ',')
    $DeviceLine | Add-Member -Name 'IPTV Destination IP Address'       -MemberType Noteproperty -Value $($IPTVDestinationIPAddress -join ',')
    $DeviceLine | Add-Member -Name 'IPTV Reception In Progress'        -MemberType Noteproperty -Value $($IPTVReceptionInProgress -join ',')
    $DeviceLine | Add-Member -Name 'IPTV Channel Number'               -MemberType Noteproperty -Value $($IPTVChannelNumber -join ',')
    $DeviceLine | Add-Member -Name 'USB Printers Name'                 -MemberType Noteproperty -Value $($PrinterName -join ',')
    $DeviceLine | Add-Member -Name 'USB Printers State'                -MemberType Noteproperty -Value $($PrinterState -join ',')
    $DeviceLine | Add-Member -Name 'USB Storages Label'                -MemberType Noteproperty -Value $($StorageLabel -join ',')
    $DeviceLine | Add-Member -Name 'USB Storages State'                -MemberType Noteproperty -Value $($StorageState -join ',')
    $DeviceLine | Add-Member -Name 'Wireless Status'                   -MemberType Noteproperty -Value $Json.wireless.status
    $DeviceLine | Add-Member -Name 'Wireless Channel'                  -MemberType Noteproperty -Value $Json.wireless.radio
    $DeviceLine | Add-Member -Name 'Wireless Change Date'              -MemberType Noteproperty -Value $Json.wireless.changedate
    $DeviceLine | Add-Member -Name 'WPS 2,4Ghz '                       -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps.'24'.available)
    $DeviceLine | Add-Member -Name 'WPS 5,2Ghz'                        -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps.'5'.available)
    $DeviceLine | Add-Member -Name 'WPS State'                         -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps.enable)
    $DeviceLine | Add-Member -Name 'WPS Status'                        -MemberType Noteproperty -Value $Json.wireless.wps.status
    $DeviceLine | Add-Member -Name 'WPS Timeout'                       -MemberType Noteproperty -Value $Json.wireless.wps.timeout
    $DeviceLine | Add-Member -Name 'Wireless Red Led'                  -MemberType Noteproperty -Value (Get-Status -Status $Json.wireless.redled)
    $DeviceLine | Add-Member -Name 'Wifi Hotspot State'                -MemberType Noteproperty -Value (Get-State -State $Json.services.hotspot.enable)
    $DeviceLine | Add-Member -Name 'Firewall State'                    -MemberType Noteproperty -Value (Get-State -State $Json.services.firewall.enable)
    $DeviceLine | Add-Member -Name 'DYNDNS State'                      -MemberType Noteproperty -Value $Json.services.dyndns.enable
    $DeviceLine | Add-Member -Name 'DYNDNS Active Connections'         -MemberType Noteproperty -Value (Get-State -State $Json.services.dyndns.enable)
    $DeviceLine | Add-Member -Name 'DHCP State'                        -MemberType Noteproperty -Value (Get-State -State $Json.services.dhcp.enable)
    $DeviceLine | Add-Member -Name 'NAT State'                         -MemberType Noteproperty -Value (Get-State -State $Json.services.nat.enable)
    $DeviceLine | Add-Member -Name 'NAT Active Rules'                  -MemberType Noteproperty -Value ($Json.services.nat.enable)
    $DeviceLine | Add-Member -Name 'DMZ State'                         -MemberType Noteproperty -Value (Get-State -State $Json.services.dmz.enable)
    $DeviceLine | Add-Member -Name 'NATPAT State'                      -MemberType Noteproperty -Value (Get-State -State $Json.services.natpat.enable)
    $DeviceLine | Add-Member -Name 'UPNP/IGD State'                    -MemberType Noteproperty -Value (Get-State -State $Json.services.upnp.igd.enable)
    $DeviceLine | Add-Member -Name 'Notification State'                -MemberType Noteproperty -Value (Get-State -State $Json.services.notification.enable)
    $DeviceLine | Add-Member -Name 'Notification Active Rules'         -MemberType Noteproperty -Value ($Json.services.notification.enable)
    $DeviceLine | Add-Member -Name 'ProxyWOL State'                    -MemberType Noteproperty -Value (Get-State -State $Json.services.proxywol.enable)
    $DeviceLine | Add-Member -Name 'Web Remote State'                  -MemberType Noteproperty -Value (Get-State -State $Json.services.remoteweb.enable)
    $DeviceLine | Add-Member -Name 'Parental Control State'            -MemberType Noteproperty -Value (Get-State -State $Json.services.parentalcontrol.enable)
    $DeviceLine | Add-Member -Name 'Parental Control Status'           -MemberType Noteproperty -Value (Get-Status -Status $Json.services.parentalcontrol.status)
    $DeviceLine | Add-Member -Name 'Parental Control Status Until'     -MemberType Noteproperty -Value $Json.services.parentalcontrol.statusUntil
    $DeviceLine | Add-Member -Name 'Parental Control Status Remaining' -MemberType Noteproperty -Value "$($ParentalControlStatusRemaining.Hours)h$($ParentalControlStatusRemaining.Minutes)m$($ParentalControlStatusRemaining.Seconds)s"
    $DeviceLine | Add-Member -Name 'WIFI Scheduler State'              -MemberType Noteproperty -Value (Get-State -State $Json.services.wifischeduler.enable)
    $DeviceLine | Add-Member -Name 'WIFI Scheduler Status'             -MemberType Noteproperty -Value (Get-Status -Status $Json.services.wifischeduler.status)
    $DeviceLine | Add-Member -Name 'WIFI Scheduler Status Until'       -MemberType Noteproperty -Value $Json.services.wifischeduler.statusUntil
    $DeviceLine | Add-Member -Name 'WIFI Scheduler Status Remaining'   -MemberType Noteproperty -Value "$($WifiSchedulerStatusRemaining.Hours)h$($WifiSchedulerStatusRemaining.Minutes)m$($WifiSchedulerStatusRemaining.Seconds)s"
    $DeviceLine | Add-Member -Name 'VOIP Scheduler State'              -MemberType Noteproperty -Value (Get-State -State $Json.services.voipscheduler.enable)
    $DeviceLine | Add-Member -Name 'VOIP Scheduler Status'             -MemberType Noteproperty -Value (Get-Status -Status $Json.services.voipscheduler.status)
    $DeviceLine | Add-Member -Name 'VOIP Scheduler Status Until'       -MemberType Noteproperty -Value $Json.services.voipscheduler.statusUntil
    $DeviceLine | Add-Member -Name 'VOIP Scheduler Status Remaining'   -MemberType Noteproperty -Value "$($VOIPSchedulerStatusRemaining.Hours)h$($VOIPSchedulerStatusRemaining.Minutes)m$($VOIPSchedulerStatusRemaining.Seconds)s"
    $DeviceLine | Add-Member -Name 'GamerMode State'                   -MemberType Noteproperty -Value (Get-State -State $Json.services.gamermode.enable)
    $DeviceLine | Add-Member -Name 'DHCP V6 State'                     -MemberType Noteproperty -Value (Get-State -State $Json.services.dhcp6.enable) # Since version : 19.2.12
    $DeviceLine | Add-Member -Name 'USB Samba State'                   -MemberType Noteproperty -Value (Get-State -State $Json.services.samba.enable)
    $DeviceLine | Add-Member -Name 'USB Samba Status'                  -MemberType Noteproperty -Value (Get-Status -Status $Json.services.samba.status)
    $DeviceLine | Add-Member -Name 'USB Printer State'                 -MemberType Noteproperty -Value (Get-State -State $Json.services.printer.enable)
    $DeviceLine | Add-Member -Name 'USB Printer Status'                -MemberType Noteproperty -Value (Get-Status -Status $Json.services.printer.status)
    $DeviceLine | Add-Member -Name 'DLNA State'                        -MemberType Noteproperty -Value (Get-State -State $Json.services.dlna.enable)
    $DeviceLine | Add-Member -Name 'DLNA Status'                       -MemberType Noteproperty -Value (Get-Status -Status $Json.services.dlna.status)
    $DeviceLine | Add-Member -Name 'Phone Line 1 Echo Test Status'     -MemberType Noteproperty -Value (Get-Status -Status $Json.diags[0].echo_test.status)
    $DeviceLine | Add-Member -Name 'Phone Line 1 Ring Test Status'     -MemberType Noteproperty -Value (Get-Status -Status $Json.diags[0].ring_test.status)
    $DeviceLine | Add-Member -Name 'Phone Line 2 Echo Test Status'     -MemberType Noteproperty -Value (Get-Status -Status $Json.diags[1].echo_test.status)
    $DeviceLine | Add-Member -Name 'Phone Line 2 Ring Test Status'     -MemberType Noteproperty -Value (Get-Status -Status $Json.diags[1].ring_test.status)
    $DeviceLine | Add-Member -Name 'Hosts List'                        -MemberType Noteproperty -Value $Hosts
    $DeviceLine | Add-Member -Name 'IPAdress Hosts List'               -MemberType Noteproperty -Value $IPAdresses
    $DeviceLine | Add-Member -Name 'Link State'                        -MemberType Noteproperty -Value (Get-State -State $Json.link.state) # Since version : 23.7.8
    $DeviceLine | Add-Member -Name 'Link Type'                         -MemberType Noteproperty -Value $Json.link.type                     # Since version : 23.7.8
    $DeviceLine | Add-Member -Name 'WAN IPV4 State'                    -MemberType Noteproperty -Value (Get-State -State $Json.wan.ip.state.ip)
    $DeviceLine | Add-Member -Name 'WAN IPV6State'                     -MemberType Noteproperty -Value (Get-State -State $Json.wan.ip.state.ipv6)
    $DeviceLine | Add-Member -Name 'WAN IP stats Tx Occupation'        -MemberType Noteproperty -Value $Json.wan.ip.stats.tx.occupation
    $DeviceLine | Add-Member -Name 'WAN IP stats Rx Occupation'        -MemberType Noteproperty -Value $Json.wan.ip.stats.rx.occupation
    $DeviceLine | Add-Member -Name 'Alerts Count'                      -MemberType Noteproperty -Value $Json.alerts.count
    $DeviceLine | Add-Member -Name 'CPL Count'                         -MemberType Noteproperty -Value $Json.cpl.count

    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

#endregion SUMMARY

#region UPNP/IGD

Function Get-BBOXUPNPIGD {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.upnp.igd
    
    # Create New PSObject and add values to array
    $EventsLine = New-Object -TypeName PSObject
    $EventsLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'UPNP/IGD'
    $EventsLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $EventsLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $EventsLine | Add-Member -Name 'UUID'    -MemberType Noteproperty -Value $Json.uuid
    $EventsLine | Add-Member -Name 'Name'    -MemberType Noteproperty -Value $Json.friendlyname
    
    # Add lines to $Array
    $Array += $EventsLine
    
    Return $Array
}

Function Get-BBOXUPNPIGDRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    If ($Json.Count -ne 0) {
    
        # Create array
        $Array = @()
        
        # Select $JSON header
        $Json = $Json.upnp.igd.rules
        
        $Rule = 0
        
        While ($Rule -lt $Json.Count) {
            
            If ($global:ResolveDnsName -eq 'Y') {
                $InternalHostName = $(Resolve-DnsName -Name $Json[$Rule].internalip -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost -join ','
            }
            Else {$InternalHostName}
            
            # Create New PSObject and add values to array
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name 'ID'                  -MemberType Noteproperty -Value $Json[$Rule].id
            $RuleLine | Add-Member -Name 'Status'              -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].enable)
            $RuleLine | Add-Member -Name 'Description'         -MemberType Noteproperty -Value $Json[$Rule].description
            $RuleLine | Add-Member -Name 'Internal IP Address' -MemberType Noteproperty -Value $Json[$Rule].internalip
            $RuleLine | Add-Member -Name 'Internal HostName'   -MemberType Noteproperty -Value $InternalHostName
            $RuleLine | Add-Member -Name 'Protocol'            -MemberType Noteproperty -Value $Json[$Rule].protocol
            $RuleLine | Add-Member -Name 'Internal Port'       -MemberType Noteproperty -Value $Json[$Rule].internalport
            $RuleLine | Add-Member -Name 'External Port'       -MemberType Noteproperty -Value $Json[$Rule].externalport
            $RuleLine | Add-Member -Name 'Expiration Date'     -MemberType Noteproperty -Value $Json[$Rule].expire
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

#endregion UPNP/IGD

#region USB

Function Get-BBOXDeviceUSBDevices {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    If ($Json.usb.count -ne '0') {
        
        # Create array
        $Array = @()
        
        # Select $JSON header
        $Json = $Json.usb
        $USBDevice = 0
        
        While ($USBDevice -lt $Json.parent.Count) {
            
            # Create New PSObject and add values to array
            
            # Parent
            $USBDeviceLine = New-Object -TypeName PSObject
            $USBDeviceLine | Add-Member -Name 'Index'              -MemberType Noteproperty -Value $Json.child[$USBDevice].index
            $USBDeviceLine | Add-Member -Name 'Parent Identity'    -MemberType Noteproperty -Value $Json.parent[$USBDevice].ident
            $USBDeviceLine | Add-Member -Name 'Parent Description' -MemberType Noteproperty -Value $Json.parent[$USBDevice].description
            
            # Children
            $USBDeviceLine | Add-Member -Name 'File System type'   -MemberType Noteproperty -Value $Json.child[$USBDevice].ident
            $USBDeviceLine | Add-Member -Name 'Parent'             -MemberType Noteproperty -Value $Json.child[$USBDevice].parent
            $USBDeviceLine | Add-Member -Name 'UUID'               -MemberType Noteproperty -Value $Json.child[$USBDevice].uuid
            $USBDeviceLine | Add-Member -Name 'Partition Label'    -MemberType Noteproperty -Value $Json.child[$USBDevice].label
            $USBDeviceLine | Add-Member -Name 'Description'        -MemberType Noteproperty -Value $Json.child[$USBDevice].description
            $USBDeviceLine | Add-Member -Name 'File System'        -MemberType Noteproperty -Value $Json.child[$USBDevice].fs
            $USBDeviceLine | Add-Member -Name 'Samba Name'         -MemberType Noteproperty -Value $Json.child[$USBDevice].name
            $USBDeviceLine | Add-Member -Name 'Is writable ?'      -MemberType Noteproperty -Value $(Get-USBRight -USBRight $($Json.child[$USBDevice].writable))
            $USBDeviceLine | Add-Member -Name 'USB Port number'    -MemberType Noteproperty -Value $Json.child[$USBDevice].host
            $USBDeviceLine | Add-Member -Name 'Partition State'    -MemberType Noteproperty -Value $Json.child[$USBDevice].state
            $USBDeviceLine | Add-Member -Name 'Space Used (Octet)' -MemberType Noteproperty -Value $Json.child[$USBDevice].used
            $USBDeviceLine | Add-Member -Name 'Space Total (Octet)'-MemberType Noteproperty -Value $Json.child[$USBDevice].total
            $USBDeviceLine | Add-Member -Name 'Space Free (Octet)' -MemberType Noteproperty -Value $($Json.child[$USBDevice].total - $Json.child[$USBDevice].used)
            
            # Add lines to $Array
            $Array += $USBDeviceLine
            
            # Go to next line
            $USBDevice ++
        }
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXDeviceUSBPrinter {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.printer
        
    If ($Json.printer.count -ne '0') {  
        
        $USBPrinter = 0
        
        While ($USBPrinter -lt ($Json.Count)) {
            
            # Create New PSObject and add values to array
            $PrinterLine = New-Object -TypeName PSObject
            $PrinterLine | Add-Member -Name 'Index'        -MemberType Noteproperty -Value $Json[$USBPrinter].index
            $PrinterLine | Add-Member -Name 'Name'         -MemberType Noteproperty -Value $Json[$USBPrinter].name
            $PrinterLine | Add-Member -Name 'Description'  -MemberType Noteproperty -Value $Json[$USBPrinter].description
            $PrinterLine | Add-Member -Name 'Manufacturer' -MemberType Noteproperty -Value $Json[$USBPrinter].manufacturer
            $PrinterLine | Add-Member -Name 'Product'      -MemberType Noteproperty -Value $Json[$USBPrinter].product
            $PrinterLine | Add-Member -Name 'State'        -MemberType Noteproperty -Value (Get-state -State $Json[$USBPrinter].state)
            
            # Add lines to $Array
            $Array += $PrinterLine
            
            # Go to next line
            $USBPrinter ++
        }
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXUSBStorage {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.file_info
    
    If ($Json.count -ne '0') {
    
        $USBStorage = 0
        
        While ($USBStorage -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $USBStorageLine = New-Object -TypeName PSObject
            $USBStorageLine | Add-Member -Name 'Path'         -MemberType Noteproperty -Value $Json[$USBStorage].path
            $USBStorageLine | Add-Member -Name 'Size'         -MemberType Noteproperty -Value $Json[$USBStorage].size
            $USBStorageLine | Add-Member -Name 'Preview Type' -MemberType Noteproperty -Value $Json[$USBStorage].preview_type
            $USBStorageLine | Add-Member -Name 'Hash'         -MemberType Noteproperty -Value $Json[$USBStorage].hash
            $USBStorageLine | Add-Member -Name 'Type'         -MemberType Noteproperty -Value (Get-USBFolderType -USBFolderType $($Json[$USBStorage].type))
            $USBStorageLine | Add-Member -Name 'Icon'         -MemberType Noteproperty -Value $Json[$USBStorage].icon
            $USBStorageLine | Add-Member -Name 'Bytes'        -MemberType Noteproperty -Value $Json[$USBStorage].bytes
            
            # Add lines to $Array
            $Array += $USBStorageLine
            
            # Go to next line
            $USBStorage ++
        }
        Return $Array
    }
    Else {
        Return $null
    }
}

#endregion USB

#region VOIP

Function Get-BBOXVOIP {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $VOIPLine = New-Object -TypeName PSObject
    $VOIPLine | Add-Member -Name 'Phone line index'             -MemberType Noteproperty -Value $Json.id
    $VOIPLine | Add-Member -Name 'Status'                       -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $VOIPLine | Add-Member -Name 'Call State'                   -MemberType Noteproperty -Value $Json.callstate
    $VOIPLine | Add-Member -Name 'SIP Phone Number Uri'         -MemberType Noteproperty -Value $Json.uri
    $VOIPLine | Add-Member -Name 'SIP Phone Number'             -MemberType Noteproperty -Value $($Json.uri -split "@")[0] # Not included in Box API
    $VOIPLine | Add-Member -Name 'SIP Phone Number Domain'      -MemberType Noteproperty -Value $($Json.uri -split "@")[1] # Not included in Box API
    $VOIPLine | Add-Member -Name 'Anonymous call Blocked State' -MemberType Noteproperty -Value (Get-State -State $Json.blockstate)
    $VOIPLine | Add-Member -Name 'Anonymous Call State'         -MemberType Noteproperty -Value (Get-State -State $Json.anoncallstate)
    $VOIPLine | Add-Member -Name 'Is Voice Mail waiting ?'      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.mwi)
    $VOIPLine | Add-Member -Name 'Voice Mail Count waiting'     -MemberType Noteproperty -Value $Json.message_count
    $VOIPLine | Add-Member -Name 'Missed call'                  -MemberType Noteproperty -Value $Json.notanswered
    $VOIPLine | Add-Member -Name 'Hand Set Plugged'             -MemberType Noteproperty -Value $Json.handsetplugged # Since version : 23.7.8
    
    # Add lines to $Array
    $Array += $VOIPLine
    
    Return $Array
}

Function Get-BBOXVOIPDiagConfig {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Calculate Intermediaries Values
    # Phone Lines
    $PhoneLineCount = $($Json.phy_interface).count
    
    # Devices List
    $Devices = $Json.host
    $DevicesCount        = $Devices.count
    $DevicesEnableCount  = $($Devices | Where-Object {$_.active -eq 1}).count
    $DevicesDisableCount = $($Devices | Where-Object {$_.active -eq 0}).count
    $DevicesList          = $($Devices.hostname -join ',')
    
    # Usb Devices
    $UsbDevicesCount = $($Json.usb).count
    $UsbDevicesList  = $($Json.usb.name -join ',')
    
    # Create New PSObject and add values to array
    $VOIPConfig = New-Object -TypeName PSObject
    $VOIPConfig | Add-Member -Name 'Phone Line Count'     -MemberType Noteproperty -Value $PhoneLineCount
    $VOIPConfig | Add-Member -Name 'Device Count'         -MemberType Noteproperty -Value $DevicesCount
    $VOIPConfig | Add-Member -Name 'Device Enable Count'  -MemberType Noteproperty -Value $DevicesEnableCount
    $VOIPConfig | Add-Member -Name 'Device Disable Count' -MemberType Noteproperty -Value $DevicesDisableCount
    $VOIPConfig | Add-Member -Name 'Device Name List'     -MemberType Noteproperty -Value $DevicesList
    $VOIPConfig | Add-Member -Name 'USB Devices Count'    -MemberType Noteproperty -Value $UsbDevicesCount
    $VOIPConfig | Add-Member -Name 'USB Name List'        -MemberType Noteproperty -Value $UsbDevicesList
    
    # Add lines to $Array
    $Array += $VOIPConfig

    Return $Array
}

Function Get-BBOXVOIPDiagLine {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.phy_interface
    
    If ($Json.Count -ne 0) {
        
        $VOIPID = 0
        
        While ($VOIPID -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $VOIPLine = New-Object -TypeName PSObject
            $VOIPLine | Add-Member -Name 'Phone Line ID'    -MemberType Noteproperty -Value $Json[$VOIPID].ring_test.id
            $VOIPLine | Add-Member -Name 'Ring Test Status' -MemberType Noteproperty -Value $Json[$VOIPID].ring_test.status
            $VOIPLine | Add-Member -Name 'Echo Test Status' -MemberType Noteproperty -Value $Json[$VOIPID].echo_test.status
            
            # Add lines to $Array
            $Array += $VOIPLine
            
            # Go to next line
            $VOIPID ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXVOIPDiagHost {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.host
    
    If ($Json.Count -ne 0) {
        
        $Device = 0
        
        While ($Device -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $DeviceLine = New-Object -TypeName PSObject
            $DeviceLine | Add-Member -Name 'ID'          -MemberType Noteproperty -Value $Json[$Device].id
            $DeviceLine | Add-Member -Name 'Hostname'    -MemberType Noteproperty -Value $Json[$Device].hostname
            $DeviceLine | Add-Member -Name 'IP Address'  -MemberType Noteproperty -Value $Json[$Device].ipaddress
            $DeviceLine | Add-Member -Name 'MAC Address' -MemberType Noteproperty -Value $Json[$Device].macaddress
            $DeviceLine | Add-Member -Name 'State'       -MemberType Noteproperty -Value (Get-State -State $Json[$Device].active)
            
            # Add lines to $Array
            $Array += $DeviceLine
            
            # Go to next line
            $Device ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXVOIPDiagUSB {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.usb
    
    If ($Json.Count -ne 0) {
        
        $USB = 0
        
        While ($USB -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $USBLine = New-Object -TypeName PSObject
            $USBLine | Add-Member -Name 'ID'          -MemberType Noteproperty -Value $Json[$USB].index
            $USBLine | Add-Member -Name 'Identify '   -MemberType Noteproperty -Value $Json[$USB].ident
            $USBLine | Add-Member -Name 'UUID'        -MemberType Noteproperty -Value $Json[$USB].uuid
            $USBLine | Add-Member -Name 'Label'       -MemberType Noteproperty -Value $Json[$USB].label
            $USBLine | Add-Member -Name 'Name'        -MemberType Noteproperty -Value $Json[$USB].name
            $USBLine | Add-Member -Name 'Description' -MemberType Noteproperty -Value $Json[$USB].description
            
            # Add lines to $Array
            $Array += $USBLine
            
            # Go to next line
            $USB ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXVOIPScheduler {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.voip.scheduler
    
    If ($Json.enable -eq 1) {
        $VOIPSchedulerStatusRemaining = New-TimeSpan -Seconds $Json.statusRemaining
        $TimeRemaining = "$($VOIPSchedulerStatusRemaining.Hours)h$($VOIPSchedulerStatusRemaining.Minutes)m$($VOIPSchedulerStatusRemaining.Seconds)s"
    }
    Else {
        $TimeRemaining = $Json.services.voipscheduler.statusRemaining
    }
    
    # Create New PSObject and add values to array
    $SchedulerLine = New-Object -TypeName PSObject
    $SchedulerLine | Add-Member -Name 'Service'        -MemberType Noteproperty -Value 'Voip Scheduler'
    $SchedulerLine | Add-Member -Name 'Date'           -MemberType Noteproperty -Value $(Edit-Date -Date $Json.now)
    $SchedulerLine | Add-Member -Name 'State'          -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $SchedulerLine | Add-Member -Name 'Unbloked ?'     -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.unblock)
    $SchedulerLine | Add-Member -Name 'Status'         -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $SchedulerLine | Add-Member -Name 'Status Until'   -MemberType Noteproperty -Value $Json.statusuntil
    $SchedulerLine | Add-Member -Name 'Time Remaining' -MemberType Noteproperty -Value $TimeRemaining
    $SchedulerLine | Add-Member -Name 'Rules'          -MemberType Noteproperty -Value $Json.rules.count # Since Version 19.2.12

    # Add lines to $Array
    $Array += $SchedulerLine
    
    Return $Array
}

Function Get-BBOXVOIPSchedulerRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.voip.scheduler.rules
    
    If ($Json.Count -ne 0) {
        
        $Rule = 0
        
        While ($Rule -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name 'ID'    -MemberType Noteproperty -Value $Json[$Rule].id
            $RuleLine | Add-Member -Name 'State' -MemberType Noteproperty -Value (Get-State -State $Json[$Rule].enable)
            $RuleLine | Add-Member -Name 'Start' -MemberType Noteproperty -Value "$($Json[$Rule].start.day) at $($Json[$Rule].start.hour):$($Json[$Rule].start.minute)"
            $RuleLine | Add-Member -Name 'End'   -MemberType Noteproperty -Value "$($Json[$Rule].end.day) at $($Json[$Rule].end.hour):$($Json[$Rule].end.minute)"
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXVOIPCallLogLineX {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.calllog
    
    If ($Json.Count -ne 0) {
        
        $Call = 0
        
        While ($Call -lt $Json.Count) {
            
            # Calculate call time
            $CallTime = New-TimeSpan -Seconds $($Json[$Call].duree)
            
            # Get Phone Number Details
            $NumberDetails = $global:PhoneNumberReferential | Where-Object {$_.Number -ilike $Json[$Call].number}
            
            # Create New PSObject and add values to array
            $CallLine = New-Object -TypeName PSObject
            $CallLine | Add-Member -Name 'ID'                  -MemberType Noteproperty -Value $Json[$Call].id
            $CallLine | Add-Member -Name 'Number'              -MemberType Noteproperty -Value $Json[$Call].number
            $CallLine | Add-Member -Name 'Date'                -MemberType Noteproperty -Value (Format-Date1970 -Seconds $Json[$Call].date)
            $CallLine | Add-Member -Name 'Call Type'           -MemberType Noteproperty -Value (Get-VoiceCallType -VoiceCallType $Json[$Call].type)
            $CallLine | Add-Member -Name 'Was Answered ?'      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Call].answered)
            $CallLine | Add-Member -Name 'Call Time'           -MemberType Noteproperty -Value "$($CallTime.Hours)h$($CallTime.Minutes)m$($CallTime.Seconds)s"
            $CallLine | Add-Member -Name 'Call Time (Default)' -MemberType Noteproperty -Value $Json[$Call].duree
            $CallLine | Add-Member -Name 'Name'                -MemberType Noteproperty -Value $NumberDetails.Name
            $CallLine | Add-Member -Name 'Surname'             -MemberType Noteproperty -Value $NumberDetails.Surname
            $CallLine | Add-Member -Name 'Description'         -MemberType Noteproperty -Value $NumberDetails.Description
            $CallLine | Add-Member -Name 'Category'            -MemberType Noteproperty -Value $NumberDetails.Category
            $CallLine | Add-Member -Name 'Type'                -MemberType Noteproperty -Value $NumberDetails.Type
            
            # Add lines to $Array
            $Array += $CallLine
            
            # Go to next line
            $Call ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXVOIPCallLogLineXSummary {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Data = Get-BBOXVOIPCallLogLine -UrlToGo $UrlToGo
    $PhoneNumbers = $Data.number | Select-Object -Unique
    
    # Create array
    $Array = @()
    
    # Get details foreach Phone Numbers
    Foreach ($Number in $PhoneNumbers) {
        
        $CallTime = $Null
        $Details = $Data | Where-Object {$_.number -match $Number}
        $Details | ForEach-Object {$CallTime = $CallTime + $_.'Call Time (Default)'}
        $TotalCallTime = New-TimeSpan -Seconds $CallTime
        
        # Get Phone Number Details
        $NumberDetails = $global:PhoneNumberReferential | Where-Object {$_.Number -ilike $Number}
        
        # Create New PSObject and add values to array
        $CallLine = New-Object -TypeName PSObject
        $CallLine | Add-Member -Name 'Number'                                                -MemberType Noteproperty -Value $Number
        $CallLine | Add-Member -Name 'Call Date'                                             -MemberType Noteproperty -Value $($Details.Date -join ",")
        $CallLine | Add-Member -Name 'Call Count'                                            -MemberType Noteproperty -Value $Details.Count
        $CallLine | Add-Member -Name 'Call Type'                                             -MemberType Noteproperty -Value $($($Details.'Call Type' | Select-Object -Unique) -join ",")
        $CallLine | Add-Member -Name 'Call Incoming Count'                                   -MemberType Noteproperty -Value $($Details.'Call Type' | Where-Object {$_ -match "Incoming"}).count
        $CallLine | Add-Member -Name "Call Incoming Rejected (`"Unknow`" active rule) Count" -MemberType Noteproperty -Value $($Details.'Call Type' | Where-Object {$_ -match "Incoming Rejected (`"Unknow`" active rule)"}).count
        $CallLine | Add-Member -Name 'Call Incoming Out Range Call (Active rule) Count'      -MemberType Noteproperty -Value $($Details.'Call Type' | Where-Object {$_ -match "Incoming Out Range Call (Active rule)"}).count
        $CallLine | Add-Member -Name 'Call Outgoing Count'                                   -MemberType Noteproperty -Value $($Details.'Call Type' | Where-Object {$_ -match "Outgoing"}).count
        $CallLine | Add-Member -Name 'Total Call Time'                                       -MemberType Noteproperty -Value $TotalCallTime
        $CallLine | Add-Member -Name 'Name'                                                  -MemberType Noteproperty -Value $NumberDetails.Name
        $CallLine | Add-Member -Name 'Surname'                                               -MemberType Noteproperty -Value $NumberDetails.Surname
        $CallLine | Add-Member -Name 'Description'                                           -MemberType Noteproperty -Value $NumberDetails.Description
        $CallLine | Add-Member -Name 'Category'                                              -MemberType Noteproperty -Value $NumberDetails.Category
        $CallLine | Add-Member -Name 'Type'                                                  -MemberType Noteproperty -Value $NumberDetails.Type
        
        # Add lines to $Array
        $Array += $CallLine
    }
    
    Return $Array
}

Function Get-BBOXVOIPCallLogLineXPhoneNumber {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $CallLogLineXPhoneNumberIDs = Get-BBOXVOIPCallLogLine -UrlToGo $UrlToGo
    
    If ($global:TriggerExportConfig -eq $true) {
        $CallLogLineXPhoneNumberID = $CallLogLineXPhoneNumberIDs | Select-Object -Property Number -First 1 -Unique
    }
    Else {
        $CallLogLineXPhoneNumberID = $CallLogLineXPhoneNumberIDs | Select-Object -Property Number -Unique | Out-GridView -Title "Phone Number List" -OutputMode Single
    }
    
    $CallLogLineXPhoneNumbers = $CallLogLineXPhoneNumberIDs | Where-Object {$_.Number -ilike $CallLogLineXPhoneNumberID.Number}
    
    Return $CallLogLineXPhoneNumbers
}

Function Get-BBOXVOIPFullCallLogLineX {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.calllog
    
    If ($Json.Count -ne 0) {
        
        $Call = 0
        
        While ($Call -lt $Json.Count) {
            
            # Calculate call time
            $CallTime = New-TimeSpan -Seconds $($Json[$Call].duree)
            
            # Get Phone Number Details
            $NumberDetails = $global:PhoneNumberReferential | Where-Object {$_.Number -ilike $Json[$Call].number}
            
            # Create New PSObject and add values to array
            $CallLine = New-Object -TypeName PSObject
            $CallLine | Add-Member -Name 'ID'                  -MemberType Noteproperty -Value $Json[$Call].id
            $CallLine | Add-Member -Name 'Number'              -MemberType Noteproperty -Value $Json[$Call].number
            $CallLine | Add-Member -Name 'Date'                -MemberType Noteproperty -Value (Format-Date1970 -Seconds $Json[$Call].date)
            $CallLine | Add-Member -Name 'Call Type'           -MemberType Noteproperty -Value (Get-VoiceCallType -VoiceCallType $Json[$Call].type)
            $CallLine | Add-Member -Name 'Was Answered ?'      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Call].answered)
            $CallLine | Add-Member -Name 'Call Time'           -MemberType Noteproperty -Value "$($CallTime.Hours)h$($CallTime.Minutes)m$($CallTime.Seconds)s"
            $CallLine | Add-Member -Name 'Call Time (Default)' -MemberType Noteproperty -Value $Json[$Call].duree
            $CallLine | Add-Member -Name 'Name'                -MemberType Noteproperty -Value $NumberDetails.Name
            $CallLine | Add-Member -Name 'Surname'             -MemberType Noteproperty -Value $NumberDetails.Surname
            $CallLine | Add-Member -Name 'Description'         -MemberType Noteproperty -Value $NumberDetails.Description
            $CallLine | Add-Member -Name 'Category'            -MemberType Noteproperty -Value $NumberDetails.Category
            $CallLine | Add-Member -Name 'Type'                -MemberType Noteproperty -Value $NumberDetails.Type
            
            # Add lines to $Array
            $Array += $CallLine
            
            # Go to next line
            $Call ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXVOIPFullCallLogLineXSummary {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Data = Get-BBOXVOIPFullCallLogLine -UrlToGo $UrlToGo
    $PhoneNumbers = $Data.number | Select-Object -Unique
    
    # Create array
    $Array = @()
    
    # Get details foreach Phone Numbers
    Foreach ($Number in $PhoneNumbers) {
        
        $CallTime = $Null
        $Details = $Data | Where-Object {$_.number -match $Number}
        $Details | ForEach-Object {$CallTime = $CallTime + $_.'Call Time (Default)'}
        $TotalCallTime = New-TimeSpan -Seconds $CallTime
        
        $NumberDetails = $global:PhoneNumberReferential | Where-Object {$_.Number -ilike $Number}
        
        # Create New PSObject and add values to array
        $CallLine = New-Object -TypeName PSObject
        $CallLine | Add-Member -Name 'Number'                                                -MemberType Noteproperty -Value $Number
        $CallLine | Add-Member -Name 'Call Date'                                             -MemberType Noteproperty -Value $($Details.Date -join ",")
        $CallLine | Add-Member -Name 'Call Count'                                            -MemberType Noteproperty -Value $Details.Count
        $CallLine | Add-Member -Name 'Call Type'                                             -MemberType Noteproperty -Value $($($Details.'Call Type' | Select-Object -Unique) -join ",")
        $CallLine | Add-Member -Name 'Call Incoming Count'                                   -MemberType Noteproperty -Value $($Details.'Call Type' | Where-Object {$_ -match "Incoming"}).count
        $CallLine | Add-Member -Name "Call Incoming Rejected (`"Unknow`" active rule) Count" -MemberType Noteproperty -Value $($Details.'Call Type' | Where-Object {$_ -match "Incoming Rejected (`"Unknow`" active rule)"}).count
        $CallLine | Add-Member -Name 'Call Incoming Out Range Call (Active rule) Count'      -MemberType Noteproperty -Value $($Details.'Call Type' | Where-Object {$_ -match "Incoming Out Range Call (Active rule)"}).count
        $CallLine | Add-Member -Name 'Call Outgoing Count'                                   -MemberType Noteproperty -Value $($Details.'Call Type' | Where-Object {$_ -match "Outgoing"}).count
        $CallLine | Add-Member -Name 'Total Call Time'                                       -MemberType Noteproperty -Value $TotalCallTime
        $CallLine | Add-Member -Name 'Name'                                                  -MemberType Noteproperty -Value $NumberDetails.Name
        $CallLine | Add-Member -Name 'Surname'                                               -MemberType Noteproperty -Value $NumberDetails.Surname
        $CallLine | Add-Member -Name 'Description'                                           -MemberType Noteproperty -Value $NumberDetails.Description
        $CallLine | Add-Member -Name 'Category'                                              -MemberType Noteproperty -Value $NumberDetails.Category
        $CallLine | Add-Member -Name 'Type'                                                  -MemberType Noteproperty -Value $NumberDetails.Type
        
        # Add lines to $Array
        $Array += $CallLine
    }
    
    Return $Array
}

Function Get-BBOXVOIPFullCallLogLineXPhoneNumber {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $VOIPFullCallLogLineXPhoneNumberIDs = Get-BBOXVOIPFullCallLogLine -UrlToGo $UrlToGo
    
    If ($global:TriggerExportConfig -eq $true) {
        $VOIPFullCallLogLineXPhoneNumberID = $VOIPFullCallLogLineXPhoneNumberIDs | Select-Object -Property Number -First 1 -Unique
    }
    Else {
        $VOIPFullCallLogLineXPhoneNumberID = $VOIPFullCallLogLineXPhoneNumberIDs | Select-Object -Property Number -Unique | Out-GridView -Title "Phone Number List" -OutputMode Single
    }
    
    $VOIPFullCallLogLineXPhoneNumbers = $VOIPFullCallLogLineXPhoneNumberIDs | Where-Object {$_.number -ilike $VOIPFullCallLogLineXPhoneNumberID.Number}
    
    Return $VOIPFullCallLogLineXPhoneNumbers
}

Function Get-BBOXVOIPAllowedListNumber {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.voip.scheduler
    
    If ($Json.Count -ne 0) {
        
        $Number = 0
        
        While ($Number -lt $Json.Count) {
            
            # Get Phone Numer Detail
            $Prefixe       = $Json[$Number].number[0..2] -join ""
            $PhoneNumber   = $Json[$Number].number.replace($Prefixe,"0")
            $NumberDetails = $global:PhoneNumberReferential | Where-Object {$_.Number -ilike $PhoneNumber}
            
            # Create New PSObject and add values to array
            $NumberLine = New-Object -TypeName PSObject
            $NumberLine | Add-Member -Name 'ID'          -MemberType Noteproperty -Value $Json[$Number].id
            $NumberLine | Add-Member -Name 'Full Number' -MemberType Noteproperty -Value $Json[$Number].Number
            $NumberLine | Add-Member -Name 'Prefixe'     -MemberType Noteproperty -Value $Prefixe
            $NumberLine | Add-Member -Name 'Number'      -MemberType Noteproperty -Value $PhoneNumber
            $NumberLine | Add-Member -Name 'Name'        -MemberType Noteproperty -Value $NumberDetails.Name
            $NumberLine | Add-Member -Name 'Surname'     -MemberType Noteproperty -Value $NumberDetails.Surname
            $NumberLine | Add-Member -Name 'Description' -MemberType Noteproperty -Value $NumberDetails.Description
            $NumberLine | Add-Member -Name 'Category'    -MemberType Noteproperty -Value $NumberDetails.Category
            $NumberLine | Add-Member -Name 'Type'        -MemberType Noteproperty -Value $NumberDetails.Type
            
            # Add lines to $Array
            $Array += $NumberLine
            
            # Go to next line
            $Number ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

#endregion VOIP

#region WAN

Function Get-BBOXWANAutowanConfig {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.autowan
    
    # Create New PSObject and add values to array
    $AutoWanLine = New-Object -TypeName PSObject
    $AutoWanLine | Add-Member -Name 'Model'            -MemberType Noteproperty -Value $Json.device.model
    $AutoWanLine | Add-Member -Name 'Firmware Version' -MemberType Noteproperty -Value $Json.device.firmware.main
    $AutoWanLine | Add-Member -Name 'Firmware Date'    -MemberType Noteproperty -Value $(Edit-Date -Date $Json.device.firmware.date)
    $AutoWanLine | Add-Member -Name 'WAN IP Address'   -MemberType Noteproperty -Value $Json.ip.address
    $AutoWanLine | Add-Member -Name 'WAN Bytel DNS'    -MemberType Noteproperty -Value $($(Resolve-DnsName -Name $Json.ip.address -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost -join ',') # Not included in API
    $AutoWanLine | Add-Member -Name 'Profile Device'   -MemberType Noteproperty -Value $Json.Profile.device
    $AutoWanLine | Add-Member -Name 'Profile Active'   -MemberType Noteproperty -Value $Json.Profile.active
    $AutoWanLine | Add-Member -Name 'IGMP State'       -MemberType Noteproperty -Value (Get-State -State $Json.Services.igmp)
    $AutoWanLine | Add-Member -Name 'VOIP State'       -MemberType Noteproperty -Value (Get-State -State $Json.Services.voip)
    
    # Add lines to $Array
    $Array += $AutoWanLine
    
    Return $Array
}

Function Get-BBOXWANAutowanProfiles {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.autowan

    # Profiles part
    If ($Json.Profiles.Count -ne 0) {
        
        $Line = 0
        
        While ($Line -lt  $Json.Profiles.Count) {
            
            # Create New PSObject and add values to array
            $AutowanProfilesLine = New-Object -TypeName PSObject
            $AutowanProfilesLine | Add-Member -Name 'Index'      -MemberType Noteproperty -Value $Json.Profiles[$Line].index
            $AutowanProfilesLine | Add-Member -Name 'Name'       -MemberType Noteproperty -Value $Json.Profiles[$Line].name
            $AutowanProfilesLine | Add-Member -Name 'Flags'      -MemberType Noteproperty -Value $Json.Profiles[$Line].flags
            $AutowanProfilesLine | Add-Member -Name 'State'      -MemberType Noteproperty -Value (Get-State -State $Json.Profiles[$Line].state)
            $AutowanProfilesLine | Add-Member -Name 'Successful' -MemberType Noteproperty -Value $Json.Profiles[$Line].Successful
            $AutowanProfilesLine | Add-Member -Name 'Failure'    -MemberType Noteproperty -Value $Json.Profiles[$Line].failure
            $AutowanProfilesLine | Add-Member -Name 'Timeout'    -MemberType Noteproperty -Value $Json.Profiles[$Line].timeout
            $AutowanProfilesLine | Add-Member -Name 'Fallback'   -MemberType Noteproperty -Value $Json.Profiles[$Line].fallback
            $AutowanProfilesLine | Add-Member -Name 'Starttime'  -MemberType Noteproperty -Value $Json.Profiles[$Line].starttime
            $AutowanProfilesLine | Add-Member -Name 'Tostart'    -MemberType Noteproperty -Value $Json.Profiles[$Line].tostart
            $AutowanProfilesLine | Add-Member -Name 'Toip'       -MemberType Noteproperty -Value $Json.Profiles[$Line].toip
            $AutowanProfilesLine | Add-Member -Name 'Todns'      -MemberType Noteproperty -Value $Json.Profiles[$Line].todns
            $AutowanProfilesLine | Add-Member -Name 'Totr069'    -MemberType Noteproperty -Value $Json.Profiles[$Line].totr069
            $AutowanProfilesLine | Add-Member -Name 'Torunning'  -MemberType Noteproperty -Value $Json.Profiles[$Line].torunning
            $AutowanProfilesLine | Add-Member -Name 'Laststop'   -MemberType Noteproperty -Value $Json.Profiles[$Line].laststop
            
            # Add lines to $Array
            $Array += $AutowanProfilesLine
            
            # Go to next line
            $Line ++
        }
    }
    Else {
        $Array = $null
    }
    
    Return $Array
}

Function Get-BBOXWANDiags {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create arrays
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.diags
    
    # DNS Diags Part
    $DNS = 0
    While ($DNS -lt $Json.dns.Count) {
        
        # Create New PSObject and add values to array
        $DNSLine = New-Object -TypeName PSObject
        $DNSLine | Add-Member -Name 'Type'      -MemberType Noteproperty -Value 'DNS'
        $DNSLine | Add-Member -Name 'Min'        -MemberType Noteproperty -Value $Json.dns[$DNS].min
        $DNSLine | Add-Member -Name 'Max'        -MemberType Noteproperty -Value $Json.dns[$DNS].max
        $DNSLine | Add-Member -Name 'Average'    -MemberType Noteproperty -Value $Json.dns[$DNS].average
        $DNSLine | Add-Member -Name 'Success   ' -MemberType Noteproperty -Value $Json.dns[$DNS].Success
        $DNSLine | Add-Member -Name 'Error'      -MemberType Noteproperty -Value $Json.dns[$DNS].error
        $DNSLine | Add-Member -Name 'Tries'      -MemberType Noteproperty -Value $Json.dns[$DNS].tries
        $DNSLine | Add-Member -Name 'Status'     -MemberType Noteproperty -Value $Json.dns[$DNS].status
        $DNSLine | Add-Member -Name 'Protocol'   -MemberType Noteproperty -Value $Json.dns[$DNS].protocol
        
        # Add lines to $Array
        $Array += $DNSLine
        
        # Go to next line
        $DNS ++
    }
    
    # HTTP Diags Part
    $HTTP = 0
    While ($HTTP -lt $Json.HTTP.Count) {
        
        # Create New PSObject and add values to array
        $HTTPLine = New-Object -TypeName PSObject
        $HTTPLine | Add-Member -Name 'Type'      -MemberType Noteproperty -Value 'HTTP'
        $HTTPLine | Add-Member -Name 'Min'      -MemberType Noteproperty -Value $Json.HTTP[$HTTP].min
        $HTTPLine | Add-Member -Name 'Max'      -MemberType Noteproperty -Value $Json.HTTP[$HTTP].max
        $HTTPLine | Add-Member -Name 'Average'  -MemberType Noteproperty -Value $Json.HTTP[$HTTP].average
        $HTTPLine | Add-Member -Name 'Successful'  -MemberType Noteproperty -Value $Json.HTTP[$HTTP].Successful
        $HTTPLine | Add-Member -Name 'Error'    -MemberType Noteproperty -Value $Json.HTTP[$HTTP].error
        $HTTPLine | Add-Member -Name 'Tries'    -MemberType Noteproperty -Value $Json.HTTP[$HTTP].tries
        $HTTPLine | Add-Member -Name 'Status'   -MemberType Noteproperty -Value $Json.HTTP[$HTTP].status
        $HTTPLine | Add-Member -Name 'Protocol' -MemberType Noteproperty -Value $Json.HTTP[$HTTP].protocol
        
        # Add lines to $Array
        $Array += $HTTPLine
        
        # Go to next line
        $HTTP ++
    }
    
    # Ping Diags Part
        $Ping = 0
    While ($Ping -lt $Json.Ping.Count) {
        
        # Create New PSObject and add values to array
        $PingLine = New-Object -TypeName PSObject
        $PingLine | Add-Member -Name 'Type'       -MemberType Noteproperty -Value 'PING'
        $PingLine | Add-Member -Name 'Min'        -MemberType Noteproperty -Value $Json.Ping[$Ping].min
        $PingLine | Add-Member -Name 'Max'        -MemberType Noteproperty -Value $Json.Ping[$Ping].max
        $PingLine | Add-Member -Name 'Average'    -MemberType Noteproperty -Value $Json.Ping[$Ping].average
        $PingLine | Add-Member -Name 'Successful' -MemberType Noteproperty -Value $Json.Ping[$Ping].Successful
        $PingLine | Add-Member -Name 'Error'      -MemberType Noteproperty -Value $Json.Ping[$Ping].error
        $PingLine | Add-Member -Name 'Tries'      -MemberType Noteproperty -Value $Json.Ping[$Ping].tries
        $PingLine | Add-Member -Name 'Status'     -MemberType Noteproperty -Value $Json.Ping[$Ping].status
        $PingLine | Add-Member -Name 'Protocol'   -MemberType Noteproperty -Value $Json.Ping[$Ping].protocol
        
        # Add lines to $Array
        $Array += $PingLine
        
        # Go to next line
        $Ping ++
    }    
    
    Return $Array
}

Function Get-BBOXWANDiagsSessions {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Calculate Nb current TCP/UDP IP Sessions
    If ($Json.hosts.Count) {
        
        $TCP_Sessions = $null
        $UDP_Sessions = $null
        $Line = 0
        
        While ($Line -lt $Json.hosts.Count) {
            
            $TCP_Sessions += $Json.hosts[$Line].currenttcp
            $UDP_Sessions += $Json.hosts[$Line].currentudp
            
            # Go to next line
            $Line ++
        }
        
        # Create New PSObject and add values to array
        $SessionsLine = New-Object -TypeName PSObject
        $SessionsLine | Add-Member -Name 'Nb Hosts With Opened Sessions'       -MemberType Noteproperty -Value $Json.hosts.Count
        $SessionsLine | Add-Member -Name 'Total current IP sessions'           -MemberType Noteproperty -Value $Json.currentip
        $SessionsLine | Add-Member -Name 'Average current IP sessions by host' -MemberType Noteproperty -Value $($Json.currentip / $Json.hosts.Count) # Not included with API
        $SessionsLine | Add-Member -Name 'Total TCP IP sessions'               -MemberType Noteproperty -Value $TCP_Sessions # Not included with API
        $SessionsLine | Add-Member -Name 'Total UDP IP sessions'               -MemberType Noteproperty -Value $UDP_Sessions # Not included with API
        $SessionsLine | Add-Member -Name 'Total ICMP IP sessions'              -MemberType Noteproperty -Value $($Json.currentip - ($TCP_Sessions + $UDP_Sessions)) # Not included with API
        $SessionsLine | Add-Member -Name 'TCP Timeout'                         -MemberType Noteproperty -Value $Json.tcptimeout
        $SessionsLine | Add-Member -Name 'High Threshold'                      -MemberType Noteproperty -Value $Json.highthreshold
        $SessionsLine | Add-Member -Name 'Low Threshold'                       -MemberType Noteproperty -Value $Json.lowthreshold
        $SessionsLine | Add-Member -Name 'Update Date'                         -MemberType Noteproperty -Value $Json.updatedate
        $SessionsLine | Add-Member -Name 'Nb Page'                             -MemberType Noteproperty -Value $Json.pages
        $SessionsLine | Add-Member -Name 'Nb Result Per Page'                  -MemberType Noteproperty -Value $Json.resultperpage
        
        # Add lines to $Array
        $Array += $SessionsLine
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-BBOXWANDiagsSummaryHostsActiveSessions {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    If ($Json.Count -ne 0) {
        
        $Line = 0
        
        While ($Line -lt $Json.hosts.Count) {
            
            If ($global:ResolveDnsName -eq 'Y') {
                $HostName = $(Resolve-DnsName -Name $Json.hosts[$Line].ip -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost
            }
            Else {
                $HostName = $null
            }
            
            # Create New PSObject and add values to array
            $SessionsLine = New-Object -TypeName PSObject
            $SessionsLine | Add-Member -Name 'Host IP Address'             -MemberType Noteproperty -Value $Json.hosts[$Line].ip
            $SessionsLine | Add-Member -Name 'HostName'                    -MemberType Noteproperty -Value $HostName
            $SessionsLine | Add-Member -Name 'All Current Opened Sessions' -MemberType Noteproperty -Value $Json.hosts[$Line].currentip
            $SessionsLine | Add-Member -Name 'TCP Current Opened Sessions' -MemberType Noteproperty -Value $Json.hosts[$Line].currenttcp
            $SessionsLine | Add-Member -Name 'UDP Current Opened Sessions' -MemberType Noteproperty -Value $Json.hosts[$Line].currentudp
            
            # Add lines to $Array
            $Array += $SessionsLine
            
            # Go to next line
            $Line ++
        }
        
        Return $Array
	}
    Else {
        Return $null
    }
}

Function Get-BBOXWANDiagsAllActiveSessions {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Create array
    $Array = @()
    
    $NbPages = $(Get-BBOXInformation -UrlToGo $UrlToGo).pages + 1
    $Currentpage = 1
    $Choice = ''
    
    If ($global:TriggerExportConfig -eq $false) {
        
        While ($Choice[0] -notmatch "Y|N") {
            
            $Temp = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Resolve IP Address to Hostname' -LabelMessageText "Do you want to resolve IP Address to Hostname ? It will takes a while, around 1 to 5 minutes (Depending of number of current Active Hosts Sessions) :`n- (Y) Yes`n- (N) No" -FirstOptionButtonText 'Y' -SecondOptionButtonText 'N'
            
            Switch ($Temp) {
                
                Y    {$Choice = 'Y';Break}
                N    {$Choice = 'N';Break}
            }
        }
    }
    Else {
        $Choice = 'N'
    }
    
    If ($Choice -match 'Y') {

        $Referential = @()
        $IPAdresses = @()
        $Line = 0
        
        While ($Currentpage -ne $NbPages) {
            
            $SessionPage = "$UrlToGo/$Currentpage"
            $Json = Get-BBOXInformation -UrlToGo $SessionPage
            
            While ($Line -lt $Json.Count) {
                
                $IPAdresses += $Json[$Line].srcip
                $IPAdresses += $Json[$Line].dstip
                $Line ++
            }
            $Currentpage ++
        }
        
        $IPAdresses = $IPAdresses | Select-Object -Unique
        
        $IPAdresses | ForEach-Object {
            
            $IsValidIPAddress = [ipaddress]$_
            If ($IsValidIPAddress.AddressFamily -eq "InterNetwork") {
            
                Try {
                    $Hostname = $(Resolve-DnsName -Name $_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost
                }
                Catch {
                    $Hostname = ''
                }
                If ($Hostname) {
                    $Hostname = $Hostname -join ","
                }
                
                $DNS = New-Object -TypeName PSObject
                $DNS | Add-Member -Name 'IPaddress' -MemberType Noteproperty -Value $_
                $DNS | Add-Member -Name 'Hostname'  -MemberType Noteproperty -Value $Hostname
                $Referential += $DNS
            }
        }
    }
    
    $Currentpage = 1
    While ($Currentpage -ne $NbPages) {
        
        $SessionPage = "$UrlToGo/$Currentpage"
        $Date = Get-Date
        # Get information from Box API
        $Json = Get-BBOXInformation -UrlToGo $SessionPage
        $Line = 0
        
        While ($Line -lt $Json.Count) {
            
            If ($Choice -match 'Y') {
                $sourcedns = $($Referential | Where-Object {$_ -match $Json[$Line].srcip}).Hostname
                $destinationdns = $($Referential | Where-Object {$_ -match $Json[$Line].dstip}).Hostname
            }
            Else {
                $sourcedns = ''
                $destinationdns = ''
            }

            # Create New PSObject and add values to array
            $SessionLine = New-Object -TypeName PSObject
            $SessionLine | Add-Member -Name 'Source HostName'        -MemberType Noteproperty -Value $sourcedns
            $SessionLine | Add-Member -Name 'Source IP Address'      -MemberType Noteproperty -Value $Json[$Line].srcip
            $SessionLine | Add-Member -Name 'Source Port'            -MemberType Noteproperty -Value $Json[$Line].srcport
            $SessionLine | Add-Member -Name 'Destination HostName'   -MemberType Noteproperty -Value $destinationdns
            $SessionLine | Add-Member -Name 'Destination IP Address' -MemberType Noteproperty -Value $Json[$Line].dstip
            $SessionLine | Add-Member -Name 'Destination Port'       -MemberType Noteproperty -Value $Json[$Line].dstport
            $SessionLine | Add-Member -Name 'Protocol'               -MemberType Noteproperty -Value $Json[$Line].proto
            $SessionLine | Add-Member -Name 'Expire at'              -MemberType Noteproperty -Value ($Date.AddSeconds($Json[$Line].expirein))
            $SessionLine | Add-Member -Name 'Action Type'            -MemberType Noteproperty -Value $Json[$Line].type
            
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

Function Get-BBOXWANDiagsAllActiveSessionsHost {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $AllActiveSessions = Get-BBOXWANDiagsAllActiveSessions -UrlToGo $UrlToGo
    If ($global:TriggerExportConfig -eq $true) {
        $HostID = $AllActiveSessions | Select-Object -Property 'Source IP Address','Source HostName' -First 1
    }
    Else {
        $HostID = $AllActiveSessions | Select-Object -Property 'Source IP Address','Source HostName' -Unique | Out-GridView -Title "Active Session Hosts List" -OutputMode Single
    }
    $HostAllActiveSessions = $AllActiveSessions | Where-Object {($_.'Source IP Address' -ilike $HostID.'Source IP Address') -or ($_.'Destination IP Address' -ilike $HostID.'Source IP Address')}
    
    Return $HostAllActiveSessions
}

Function Get-BBOXWANFTTHStats {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wan.ftth
    
    # Create New PSObject and add values to array
    $FTTHLine = New-Object -TypeName PSObject
    $FTTHLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'FTTH'
    $FTTHLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $FTTHLine | Add-Member -Name 'Mode'    -MemberType Noteproperty -Value $Json.mode
    
    # Add lines to $Array
    $Array += $FTTHLine
    
    Return $Array
}

Function Get-BBOXWANIP {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wan
    
    $dnsIP = $(Resolve-DnsName -Name $Json.ip.address -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost -join ","
    $dnsgateway = $(Resolve-DnsName -Name $Json.ip.gateway -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost -join ","
    
    $dnsservers = @()
    $ipdnsservers = $Json.ip.dnsservers -split ","
    $ipdnsservers | ForEach-Object {$dnsservers += $(Resolve-DnsName -Name $_).NameHost}
    $dnsservers = $dnsservers -join ","
    
    $dnsserversv6 = @()
    $dnsserversv6 = $Json.ip.dnsserversv6 -split ","
    #$dnsserversv6 | ForEach-Object {$dnsserversv6 += $(Resolve-DnsName -Name $_).NameHost}
    $dnsserversv6 = $dnsserversv6 -join ","

    # Create New PSObject and add values to array
    $IPLine = New-Object -TypeName PSObject
    $IPLine | Add-Member -Name 'Internet State'                    -MemberType Noteproperty -Value (Get-State -State $Json.internet.state)
    $IPLine | Add-Member -Name 'Interface ID'                      -MemberType Noteproperty -Value $Json.interface.id
    $IPLine | Add-Member -Name 'Interface Default configuration ?' -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.interface.default)
    $IPLine | Add-Member -Name 'Interface State'                   -MemberType Noteproperty -Value (Get-State -State $Json.interface.state)
    $IPLine | Add-Member -Name 'Carrier-grade NAT Enable ?'        -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ip.cgnatenable)
    $IPLine | Add-Member -Name 'Map T Enable ?'                    -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ip.maptenable)
    $IPLine | Add-Member -Name 'WAN State'                         -MemberType Noteproperty -Value (Get-State -State $Json.ip.state)
    $IPLine | Add-Member -Name 'WAN IP Address Assigned'           -MemberType Noteproperty -Value $Json.ip.address
    $IPLine | Add-Member -Name 'WAN HostName Assigned'             -MemberType Noteproperty -Value $dnsIP
    $IPLine | Add-Member -Name 'WAN Subnet'                        -MemberType Noteproperty -Value $Json.ip.subnet
    $IPLine | Add-Member -Name 'WAN Gateway'                       -MemberType Noteproperty -Value $Json.ip.gateway
    $IPLine | Add-Member -Name 'WAN Gateway HostName'              -MemberType Noteproperty -Value $dnsgateway
    $IPLine | Add-Member -Name 'WAN DNS Servers'                   -MemberType Noteproperty -Value $Json.ip.dnsservers
    $IPLine | Add-Member -Name 'WAN DNS Servers Hostname'          -MemberType Noteproperty -Value $dnsservers
    $IPLine | Add-Member -Name 'WAN MAC Address'                   -MemberType Noteproperty -Value $Json.ip.mac
    $IPLine | Add-Member -Name 'WAN MTU'                           -MemberType Noteproperty -Value $Json.ip.mtu
    $IPLine | Add-Member -Name 'WAN IPV6 State'                    -MemberType Noteproperty -Value (Get-State -State $Json.ip.ip6state)
    $IPLine | Add-Member -Name 'WAN DNS Servers IPV6'              -MemberType Noteproperty -Value $Json.ip.dnsserversv6
    $IPLine | Add-Member -Name 'WAN DNS Servers IPV6 Hostname'     -MemberType Noteproperty -Value $dnsserversv6
    
    If ($Json.ip.ip6address) {
        $IPLine | Add-Member -Name 'WAN IPV6 Address'              -MemberType Noteproperty -Value $Json.ip.ip6address.ipaddress
        $IPLine | Add-Member -Name 'WAN IPV6 Status'               -MemberType Noteproperty -Value (Get-Status -Status $Json.ip.ip6address.status)
        $IPLine | Add-Member -Name 'WAN IPV6 Valid'                -MemberType Noteproperty -Value $Json.ip.ip6address.valid
        $IPLine | Add-Member -Name 'WAN IPV6 Preferred'            -MemberType Noteproperty -Value $Json.ip.ip6address.preferred
    }
    Else {
        $IPLine | Add-Member -Name 'WAN IPV6 Address'              -MemberType Noteproperty -Value ''
        $IPLine | Add-Member -Name 'WAN IPV6 Status'               -MemberType Noteproperty -Value ''
        $IPLine | Add-Member -Name 'WAN IPV6 Valid'                -MemberType Noteproperty -Value ''
        $IPLine | Add-Member -Name 'WAN IPV6 Preferred'            -MemberType Noteproperty -Value ''
    }
    If ($Json.ip.ip6prefix) {
        $IPLine | Add-Member -Name 'WAN IPV6 Prefix'               -MemberType Noteproperty -Value $Json.ip.ip6prefix.prefix
        $IPLine | Add-Member -Name 'WAN IPV6 Prefix Status'        -MemberType Noteproperty -Value (Get-Status -Status $Json.ip.ip6prefix.status)
        $IPLine | Add-Member -Name 'WAN IPV6 Prefix Valid'         -MemberType Noteproperty -Value $Json.ip.ip6prefix.valid
        $IPLine | Add-Member -Name 'WAN IPV6 Prefix Preferred'     -MemberType Noteproperty -Value $Json.ip.ip6prefix.preferred
    }
    Else {
        $IPLine | Add-Member -Name 'WAN IPV6 Prefix'               -MemberType Noteproperty -Value ''
        $IPLine | Add-Member -Name 'WAN IPV6 Prefix Status'        -MemberType Noteproperty -Value ''
        $IPLine | Add-Member -Name 'WAN IPV6 Prefix Valid'         -MemberType Noteproperty -Value ''
        $IPLine | Add-Member -Name 'WAN IPV6 Prefix Preferred'     -MemberType Noteproperty -Value ''
    }

    $IPLine | Add-Member -Name 'Link State'                        -MemberType Noteproperty -Value (Get-State -State $Json.link.state)
    $IPLine | Add-Member -Name 'Link Type'                         -MemberType Noteproperty -Value $Json.link.type
    
    # Add lines to $Array
    $Array += $IPLine
    
    Return $Array
}

Function Get-BBOXWANIPStats {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wan.ip.stats
    
    # Create New PSObject and add values to array
    $StatsLine = New-Object -TypeName PSObject
    
    # RX
    $StatsLine | Add-Member -Name 'RX-Bytes'           -MemberType Noteproperty -Value $Json.rx.bytes
    $StatsLine | Add-Member -Name 'RX-Packets'         -MemberType Noteproperty -Value $Json.rx.packets
    $StatsLine | Add-Member -Name 'RX-PacketsErrors'   -MemberType Noteproperty -Value $Json.rx.packetserrors
    $StatsLine | Add-Member -Name 'RX-PacketsDiscards' -MemberType Noteproperty -Value $Json.rx.packetsdiscards
    $StatsLine | Add-Member -Name 'RX-Occupation'      -MemberType Noteproperty -Value $Json.rx.occupation
    $StatsLine | Add-Member -Name 'RX-Bandwidth'       -MemberType Noteproperty -Value $Json.rx.bandwidth
    $StatsLine | Add-Member -Name 'RX-MaxBandwidth'    -MemberType Noteproperty -Value $Json.rx.maxBandwidth
    
    # TX
    $StatsLine | Add-Member -Name 'TX-Bytes'           -MemberType Noteproperty -Value $Json.tx.bytes
    $StatsLine | Add-Member -Name 'TX-Packets'         -MemberType Noteproperty -Value $Json.tx.packets
    $StatsLine | Add-Member -Name 'TX-PacketsErrors'   -MemberType Noteproperty -Value $Json.tx.packetserrors
    $StatsLine | Add-Member -Name 'TX-PacketsDiscards' -MemberType Noteproperty -Value $Json.tx.packetsdiscards
    $StatsLine | Add-Member -Name 'TX-Occupation'      -MemberType Noteproperty -Value $Json.tx.occupation
    $StatsLine | Add-Member -Name 'TX-Bandwidth'       -MemberType Noteproperty -Value $Json.tx.bandwidth
    $StatsLine | Add-Member -Name 'TX-MaxBandwidth'    -MemberType Noteproperty -Value $Json.tx.maxBandwidth    
    
    # Add lines to $Array
    $Array += $StatsLine
    
    Return $Array
}

Function Get-BBOXWANXDSL {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wan.xdsl
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name 'Service'               -MemberType Noteproperty -Value 'XDSL'
    $DeviceLine | Add-Member -Name 'State'                 -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $DeviceLine | Add-Member -Name 'Modulation'            -MemberType Noteproperty -Value $Json.modulation
    $DeviceLine | Add-Member -Name 'Show Time'             -MemberType Noteproperty -Value $Json.showtime
    $DeviceLine | Add-Member -Name 'ATUR Provider'         -MemberType Noteproperty -Value $Json.atur_provider
    $DeviceLine | Add-Member -Name 'ATUC Provider'         -MemberType Noteproperty -Value $Json.atuc_provider
    $DeviceLine | Add-Member -Name 'Synchronisation Count' -MemberType Noteproperty -Value $Json.sync_count
    $DeviceLine | Add-Member -Name 'Up Bitrates'           -MemberType Noteproperty -Value $Json.up.bitrates
    $DeviceLine | Add-Member -Name 'Up Noise'              -MemberType Noteproperty -Value $Json.up.noise
    $DeviceLine | Add-Member -Name 'Up Attenuation'        -MemberType Noteproperty -Value $Json.up.attenuation
    $DeviceLine | Add-Member -Name 'Up Power'              -MemberType Noteproperty -Value $Json.up.power
    $DeviceLine | Add-Member -Name 'Up Phyr'               -MemberType Noteproperty -Value $Json.up.phyr
    $DeviceLine | Add-Member -Name 'Up GINP'               -MemberType Noteproperty -Value $Json.up.ginp
    $DeviceLine | Add-Member -Name 'Up Nitro'              -MemberType Noteproperty -Value $Json.up.nitro
    $DeviceLine | Add-Member -Name 'Up Interleave Delay'   -MemberType Noteproperty -Value $Json.up.interleave_delay
    $DeviceLine | Add-Member -Name 'Down Bitrates'         -MemberType Noteproperty -Value $Json.down.bitrates
    $DeviceLine | Add-Member -Name 'Down Noise'            -MemberType Noteproperty -Value $Json.down.noise
    $DeviceLine | Add-Member -Name 'Down Attenuation'      -MemberType Noteproperty -Value $Json.down.attenuation
    $DeviceLine | Add-Member -Name 'Down Power'            -MemberType Noteproperty -Value $Json.down.power
    $DeviceLine | Add-Member -Name 'Down Phyr'             -MemberType Noteproperty -Value $Json.down.phyr
    $DeviceLine | Add-Member -Name 'Down GINP'             -MemberType Noteproperty -Value $Json.down.ginp
    $DeviceLine | Add-Member -Name 'Down Nitro'            -MemberType Noteproperty -Value $Json.down.nitro
    $DeviceLine | Add-Member -Name 'Down Interleave Delay' -MemberType Noteproperty -Value $Json.down.interleave_delay
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

Function Get-BBOXWANXDSLStats {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wan.xdsl.stats
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name 'Local CRC'  -MemberType Noteproperty -Value $Json.local_crc
    $DeviceLine | Add-Member -Name 'Local FEC'  -MemberType Noteproperty -Value $Json.local_fec
    $DeviceLine | Add-Member -Name 'Local HEC'  -MemberType Noteproperty -Value $Json.local_hec
    $DeviceLine | Add-Member -Name 'Remote CRC' -MemberType Noteproperty -Value $Json.remote_crc
    $DeviceLine | Add-Member -Name 'Remote FEC' -MemberType Noteproperty -Value $Json.remote_fec
    $DeviceLine | Add-Member -Name 'Remote HEC' -MemberType Noteproperty -Value $Json.remote_hec
    
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

function Get-BBOXWANSFF {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].wan
    
    # Create New PSObject and add values to array
    $WanLine = New-Object -TypeName PSObject
    $WanLine | Add-Member -Name 'Enable'                    -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $WanLine | Add-Member -Name 'Type'                      -MemberType Noteproperty -Value $Json.pon_mode.type
    $WanLine | Add-Member -Name 'Module Class'              -MemberType Noteproperty -Value $Json.pon_mode.moduleclass
    $WanLine | Add-Member -Name 'Internal Status'           -MemberType Noteproperty -Value $Json.pon_mode.internalstatus
    $WanLine | Add-Member -Name 'SFF Serial'                -MemberType Noteproperty -Value $Json.sffserial
    $WanLine | Add-Member -Name 'SFF Vendor id'             -MemberType Noteproperty -Value $Json.sff_vendor_id
    $WanLine | Add-Member -Name 'OLT Vendor id'             -MemberType Noteproperty -Value $Json.olt_vendor_id
    $WanLine | Add-Member -Name 'Serial Number'             -MemberType Noteproperty -Value $Json.serial_number
    $WanLine | Add-Member -Name 'Receive Power'             -MemberType Noteproperty -Value $Json.receive_power
    $WanLine | Add-Member -Name 'Transmit Power'            -MemberType Noteproperty -Value $Json.transmit_power
    $WanLine | Add-Member -Name 'Temperature'               -MemberType Noteproperty -Value $Json.temperature
    $WanLine | Add-Member -Name 'Tension'                   -MemberType Noteproperty -Value $Json.voltage
    $WanLine | Add-Member -Name 'Firmware Version 1'        -MemberType Noteproperty -Value $Json.firmware_vers_1
    $WanLine | Add-Member -Name 'Firmware Version 1 Status' -MemberType Noteproperty -Value (Get-Status -Status $Json.status_firmware_v1)
    $WanLine | Add-Member -Name 'Firmware Version 2'        -MemberType Noteproperty -Value $Json.firmware_vers_2
    $WanLine | Add-Member -Name 'Firmware Version 2 Status' -MemberType Noteproperty -Value (Get-Status -Status $Json.status_firmware_v2)
    
    # Add lines to $Array
    $Array += $WanLine
    
    Return $Array
}

#endregion WAN

#region WIRELESS

Function Get-BBOXWIRELESS {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.$APIName
    
    # Create New PSObject and add values to array
    $WIRELESSLine = New-Object -TypeName PSObject
    $WIRELESSLine | Add-Member -Name 'Service'                      -MemberType Noteproperty -Value $APIName
    $WIRELESSLine | Add-Member -Name 'Status'                       -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $WIRELESSLine | Add-Member -Name 'Extended Character SSID'      -MemberType Noteproperty -Value $Json.extended_character_ssid # Since Version : 20.2.32
    $WIRELESSLine | Add-Member -Name 'Driver Busy'                  -MemberType Noteproperty -Value $Json.driverbusy # Since Version : 20.2.32
    $WIRELESSLine | Add-Member -Name 'WIFI Unified Active ?'        -MemberType Noteproperty -Value (Get-state -State $Json.unified)
    $WIRELESSLine | Add-Member -Name 'WIFI Unify Available ?'       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.unified_available)
    $WIRELESSLine | Add-Member -Name 'Is Default 24Ghz Config'      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.isDefault24) # Since Version : 19.2.12
    $WIRELESSLine | Add-Member -Name 'Is Default 5Ghz Config'       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.isDefault5) # Since Version : 19.2.12
    $WIRELESSLine | Add-Member -Name 'WIFI Scheduled Status'        -MemberType Noteproperty -Value $(Get-State -State $Json.scheduler.enable)
    
    # 2,4 Ghz
    $WIRELESSLine | Add-Member -Name '2,4Ghz Status'                    -MemberType Noteproperty -Value (Get-State -State  $Json.radio.'24'.enable)
    $WIRELESSLine | Add-Member -Name '2,4Ghz State'                     -MemberType Noteproperty -Value (Get-State -State $Json.radio.'24'.state)
    $WIRELESSLine | Add-Member -Name '2,4Ghz Radio Type List'           -MemberType Noteproperty -Value $($Json.standard.'24'.value -join ',')
    $WIRELESSLine | Add-Member -Name '2,4Ghz Radio Type List Available' -MemberType Noteproperty -Value $($Json.standard.'24'.key -join ',')
    $WIRELESSLine | Add-Member -Name '2,4Ghz Type'                      -MemberType Noteproperty -Value $Json.radio.'24'.standard
    $WIRELESSLine | Add-Member -Name '2,4Ghz Current Channel'           -MemberType Noteproperty -Value $Json.radio.'24'.current_channel
    $WIRELESSLine | Add-Member -Name '2,4Ghz Channel'                   -MemberType Noteproperty -Value $Json.radio.'24'.channel
    $WIRELESSLine | Add-Member -Name '2,4Ghz Channel Width'             -MemberType Noteproperty -Value $Json.radio.'24'.htbw
    
    $WIRELESSLine | Add-Member -Name '2,4Ghz SSID State'                -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'24'.enable)
    $WIRELESSLine | Add-Member -Name '2,4Ghz SSID Name'                 -MemberType Noteproperty -Value $Json.ssid.'24'.id
    $WIRELESSLine | Add-Member -Name '2,4Ghz SSID Hidden ?'             -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'24'.hidden)
    $WIRELESSLine | Add-Member -Name '2,4Ghz DSSID'                     -MemberType Noteproperty -Value $Json.ssid.'24'.bssid
    $WIRELESSLine | Add-Member -Name '2,4Ghz Default Security ?'        -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'24'.security.isdefault)
    $WIRELESSLine | Add-Member -Name '2,4Ghz Encryption method'         -MemberType Noteproperty -Value $Json.ssid.'24'.security.encryption
    $WIRELESSLine | Add-Member -Name '2,4Ghz Password'                  -MemberType Noteproperty -Value $Json.ssid.'24'.security.passphrase
    $WIRELESSLine | Add-Member -Name '2,4Ghz Protocol'                  -MemberType Noteproperty -Value $Json.ssid.'24'.security.protocol
    $WIRELESSLine | Add-Member -Name '2,4Ghz Multimedia QoS Status'     -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'24'.wmmenable)
    $WIRELESSLine | Add-Member -Name '2,4Ghz WPS State'                 -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'24'.wps.enable)
    $WIRELESSLine | Add-Member -Name '2,4Ghz WPS Avalability'           -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'24'.wps.available)
    $WIRELESSLine | Add-Member -Name '2,4Ghz WPS Status'                -MemberType Noteproperty -Value (Get-Status -Status $Json.ssid.'24'.wps.status)
    
    # 5,2 Ghz
    $WIRELESSLine | Add-Member -Name '5,2Ghz Status'                    -MemberType Noteproperty -Value (Get-State -State $Json.radio.'5'.enable)
    $WIRELESSLine | Add-Member -Name '5,2Ghz State'                     -MemberType Noteproperty -Value (Get-State -State $Json.radio.'5'.state)
    $WIRELESSLine | Add-Member -Name '5,2Ghz Radio Type List'           -MemberType Noteproperty -Value $($Json.standard.'5'.value -join ',')
    $WIRELESSLine | Add-Member -Name '5,2Ghz Radio Type List Available' -MemberType Noteproperty -Value $($Json.standard.'5'.key -join ',')
    $WIRELESSLine | Add-Member -Name '5,2Ghz Type'                      -MemberType Noteproperty -Value $Json.radio.'5'.standard
    $WIRELESSLine | Add-Member -Name '5,2Ghz Current Channel'           -MemberType Noteproperty -Value $Json.radio.'5'.current_channel
    $WIRELESSLine | Add-Member -Name '5,2Ghz Channel'                   -MemberType Noteproperty -Value $Json.radio.'5'.channel
    $WIRELESSLine | Add-Member -Name '5,2Ghz Channel Width'             -MemberType Noteproperty -Value $Json.radio.'5'.htbw
    $WIRELESSLine | Add-Member -Name '5,2Ghz DFS'                       -MemberType Noteproperty -Value $Json.radio.'5'.dfs
    $WIRELESSLine | Add-Member -Name '5,2Ghz GreenAP'                   -MemberType Noteproperty -Value $Json.radio.'5'.greenap
    
    $WIRELESSLine | Add-Member -Name '5,2Ghz SSID State'                -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'5'.enable)
    $WIRELESSLine | Add-Member -Name '5,2Ghz SSID Name'                 -MemberType Noteproperty -Value $Json.ssid.'5'.id
    $WIRELESSLine | Add-Member -Name '5,2Ghz SSID Hidden ?'             -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'5'.hidden)
    $WIRELESSLine | Add-Member -Name '5,2Ghz DSSID'                     -MemberType Noteproperty -Value $Json.ssid.'5'.bssid
    $WIRELESSLine | Add-Member -Name '5,2Ghz Default Security ?'        -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'5'.security.isdefault)
    $WIRELESSLine | Add-Member -Name '5,2Ghz Encryption method'         -MemberType Noteproperty -Value $Json.ssid.'5'.security.encryption
    $WIRELESSLine | Add-Member -Name '5,2Ghz Password'                  -MemberType Noteproperty -Value $Json.ssid.'5'.security.passphrase
    $WIRELESSLine | Add-Member -Name '5,2Ghz Protocol'                  -MemberType Noteproperty -Value $Json.ssid.'5'.security.protocol
    $WIRELESSLine | Add-Member -Name '5,2Ghz Multimedia QoS Status'     -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'5'.wmmenable)
    $WIRELESSLine | Add-Member -Name '5,2Ghz WPS State'                 -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'5'.wps.enable)
    $WIRELESSLine | Add-Member -Name '5,2Ghz WPS Avalability'           -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'5'.wps.available)
    $WIRELESSLine | Add-Member -Name '5,2Ghz WPS Status'                -MemberType Noteproperty -Value (Get-Status -Status $Json.ssid.'5'.wps.status)
    
    $WIRELESSLine | Add-Member -Name '5,2Ghz Capabilities'              -MemberType Noteproperty -Value $(Get-BBOXWIRELESS5GHCAPABILITIES -Capabilities $Json.capabilities.'5')
    
    # Add lines to $Array
    $Array += $WIRELESSLine
    
    Return $Array
}

Function Get-BBOXWIRELESSSTANDARD {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wireless.standard
    
    $Line = 0
    
    While ($Line -lt $Json.'24'.Count) {
        
        # Create New PSObject and add values to array
        $WIRELESSLine = New-Object -TypeName PSObject
        $WIRELESSLine | Add-Member -Name 'Norme'   -MemberType Noteproperty -Value $Json.'24'[$Line].key
        $WIRELESSLine | Add-Member -Name 'Comment' -MemberType Noteproperty -Value $Json.'24'[$Line].value
        
        # Add lines to $Array
        $Array += $WIRELESSLine

        $Line ++
    }
    
    $Line = 0
    
    While ($Line -lt $Json.'5'.Count) {
        
        # Create New PSObject and add values to array
        $WIRELESSLine = New-Object -TypeName PSObject
        $WIRELESSLine | Add-Member -Name 'Norme'   -MemberType Noteproperty -Value $Json.'5'[$Line].key
        $WIRELESSLine | Add-Member -Name 'Comment' -MemberType Noteproperty -Value $Json.'5'[$Line].value
        
        # Add lines to $Array
        $Array += $WIRELESSLine

        $Line ++
    }
    
    Return $Array
}

Function Get-BBOXWIRELESS24Ghz {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wireless
    
    # Create New PSObject and add values to array
    $WIRELESSLine = New-Object -TypeName PSObject
    $WIRELESSLine | Add-Member -Name 'Status'                -MemberType Noteproperty -Value $Json.status
    $WIRELESSLine | Add-Member -Name 'WIFI N'                -MemberType Noteproperty -Value (Get-Status -Status $Json.wifiN)
    $WIRELESSLine | Add-Member -Name 'Country'               -MemberType Noteproperty -Value $Json.Country
    $WIRELESSLine | Add-Member -Name 'Vendor'                -MemberType Noteproperty -Value $Json.ChipVendor
    $WIRELESSLine | Add-Member -Name 'Reference'             -MemberType Noteproperty -Value $Json.ChipReference
    $WIRELESSLine | Add-Member -Name 'Radio State'           -MemberType Noteproperty -Value (Get-Status -Status $Json.radio.state)
    $WIRELESSLine | Add-Member -Name 'Radio Status'          -MemberType Noteproperty -Value (Get-State -State $Json.radio.enable)
    $WIRELESSLine | Add-Member -Name 'Radio Profile'         -MemberType Noteproperty -Value $Json.radio.standard
    $WIRELESSLine | Add-Member -Name 'Radio Channel'         -MemberType Noteproperty -Value $Json.radio.channel
    $WIRELESSLine | Add-Member -Name 'Radio Current Channel' -MemberType Noteproperty -Value $Json.radio.current_channel
    $WIRELESSLine | Add-Member -Name 'Scheduler Status'      -MemberType Noteproperty -Value (Get-State -State $Json.scheduler.enable)
    $WIRELESSLine | Add-Member -Name 'SSID ID'               -MemberType Noteproperty -Value $Json.ssid.'24'.id
    $WIRELESSLine | Add-Member -Name 'SSID Status'           -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'24'.enable)
    $WIRELESSLine | Add-Member -Name 'SSID is hidden ?'      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'24'.hidden)
    $WIRELESSLine | Add-Member -Name 'BSSID'                 -MemberType Noteproperty -Value $Json.ssid.'24'.bssid
    $WIRELESSLine | Add-Member -Name 'WMM is enable ?'       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'24'.wmmenable)
    $WIRELESSLine | Add-Member -Name 'HTBW'                  -MemberType Noteproperty -Value $Json.ssid.'24'.htbw
    $WIRELESSLine | Add-Member -Name 'WPS State'             -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'24'.wps.enable)
    $WIRELESSLine | Add-Member -Name 'WPS Status'            -MemberType Noteproperty -Value (Get-Status -Status $Json.ssid.'24'.wps.status)
    $WIRELESSLine | Add-Member -Name 'Security Protocol'     -MemberType Noteproperty -Value $Json.ssid.'24'.security.protocol
    $WIRELESSLine | Add-Member -Name 'Encryption'            -MemberType Noteproperty -Value $Json.ssid.'24'.security.encryption
    $WIRELESSLine | Add-Member -Name 'Passphrase'            -MemberType Noteproperty -Value $Json.ssid.'24'.security.passphrase
    $WIRELESSLine | Add-Member -Name 'Available Channel'     -MemberType Noteproperty -Value $($Json.capabilities.'24'.channel -join ',')
        
    # Add lines to $Array
    $Array += $WIRELESSLine
    
    Return $Array
}

Function Get-BBOXWIRELESS5Ghz {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wireless
    
    # Create New PSObject and add values to array
    $WIRELESSLine = New-Object -TypeName PSObject
    $WIRELESSLine | Add-Member -Name 'Status'                -MemberType Noteproperty -Value $Json.status
    $WIRELESSLine | Add-Member -Name 'WIFI N'                -MemberType Noteproperty -Value (Get-Status -Status $Json.wifiN)
    $WIRELESSLine | Add-Member -Name 'Country'               -MemberType Noteproperty -Value $Json.Country
    $WIRELESSLine | Add-Member -Name 'Vendor'                -MemberType Noteproperty -Value $Json.ChipVendor
    $WIRELESSLine | Add-Member -Name 'Reference'             -MemberType Noteproperty -Value $Json.ChipReference
    $WIRELESSLine | Add-Member -Name 'Radio State'           -MemberType Noteproperty -Value (Get-Status -Status $Json.radio.state)
    $WIRELESSLine | Add-Member -Name 'Radio Status'          -MemberType Noteproperty -Value (Get-State -State $Json.radio.enable)
    $WIRELESSLine | Add-Member -Name 'Radio Profile'         -MemberType Noteproperty -Value $Json.radio.standard
    $WIRELESSLine | Add-Member -Name 'Radio Channel'         -MemberType Noteproperty -Value $Json.radio.channel
    $WIRELESSLine | Add-Member -Name 'Radio Current Channel' -MemberType Noteproperty -Value $Json.radio.current_channel
    $WIRELESSLine | Add-Member -Name 'Scheduler Status'      -MemberType Noteproperty -Value (Get-State -State $Json.scheduler.enable)
    $WIRELESSLine | Add-Member -Name 'SSID ID'               -MemberType Noteproperty -Value $Json.ssid.'5'.id
    $WIRELESSLine | Add-Member -Name 'SSID Status'           -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'5'.enable)
    $WIRELESSLine | Add-Member -Name 'SSID is hidden ?'      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'5'.hidden)
    $WIRELESSLine | Add-Member -Name 'BSSID'                 -MemberType Noteproperty -Value $Json.ssid.'5'.bssid
    $WIRELESSLine | Add-Member -Name 'WMM is enable ?'       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'5'.wmmenable)
    $WIRELESSLine | Add-Member -Name 'HTBW'                  -MemberType Noteproperty -Value $Json.ssid.'5'.htbw
    $WIRELESSLine | Add-Member -Name 'WPS State'             -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'5'.wps.enable)
    If ($Json.ssid.'5'.wps.status) {
        $WIRELESSLine | Add-Member -Name 'WPS Status'        -MemberType Noteproperty -Value (Get-Status -Status $Json.ssid.'5'.wps.status)
    }
    Else {
        $WIRELESSLine | Add-Member -Name 'WPS Status'       -MemberType Noteproperty -Value 'Unknow'
    }
    $WIRELESSLine | Add-Member -Name 'Security Protocol'     -MemberType Noteproperty -Value $Json.ssid.'5'.security.protocol
    $WIRELESSLine | Add-Member -Name 'Encryption'            -MemberType Noteproperty -Value $Json.ssid.'5'.security.encryption
    $WIRELESSLine | Add-Member -Name 'Passphrase'            -MemberType Noteproperty -Value $Json.ssid.'5'.security.passphrase
    $WIRELESSLine | Add-Member -Name 'Capabilities'          -MemberType Noteproperty -Value $(Get-BBOXWIRELESS5GHCAPABILITIES -Capabilities $Json.capabilities.'5')
    $WIRELESSLine | Add-Member -Name 'Advanced'              -MemberType Noteproperty -Value $Json.Advanced
    
    # Add lines to $Array
    $Array += $WIRELESSLine
    
    Return $Array
}

Function Get-BBOXWIRELESS5GHCAPABILITIES {
    
    Param (
        [Parameter(Mandatory=$True)]
        [Array]$Capabilities
    )
    
    # Create array
    $Array = @()
    
    $Capabilitie = 0
    
    While ($Capabilitie -lt $Capabilities.Count) {
        
        # Create New PSObject and add values to array
        $CapabilitieLine = New-Object -TypeName PSObject
        $CapabilitieLine | Add-Member -Name 'Channel'   -MemberType Noteproperty -Value $Capabilities[$Capabilitie].channel
        $CapabilitieLine | Add-Member -Name 'HT-20'     -MemberType Noteproperty -Value $Capabilities[$Capabilitie].ht.'20'
        $CapabilitieLine | Add-Member -Name 'HT-40'     -MemberType Noteproperty -Value $Capabilities[$Capabilitie].ht.'40'
        $CapabilitieLine | Add-Member -Name 'HT-80'     -MemberType Noteproperty -Value $Capabilities[$Capabilitie].ht.'80'
        $CapabilitieLine | Add-Member -Name 'NODFS'     -MemberType Noteproperty -Value $Capabilities[$Capabilitie].nodfs
        $CapabilitieLine | Add-Member -Name 'cactime'   -MemberType Noteproperty -Value $Capabilities[$Capabilitie].cactime
        $CapabilitieLine | Add-Member -Name 'cactime40' -MemberType Noteproperty -Value $Capabilities[$Capabilitie].cactime40
        
        # Add lines to $Array
        $Array += $($CapabilitieLine -join ',')
        
        # Go to next line
        $Capabilitie ++
    }
    
    Return $Array
}

Function Get-BBOXWIRELESSStats {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wireless.ssid
    
    # Create New PSObject and add values to array
    $StatsLine = New-Object -TypeName PSObject
    $StatsLine | Add-Member -Name 'Frequency'          -MemberType Noteproperty -Value $Json.id
    $StatsLine | Add-Member -Name 'RX-Bytes'           -MemberType Noteproperty -Value $Json.stats.rx.bytes
    $StatsLine | Add-Member -Name 'RX-Packets'         -MemberType Noteproperty -Value $Json.stats.rx.packets
    $StatsLine | Add-Member -Name 'RX-PacketsErrors'   -MemberType Noteproperty -Value $Json.stats.rx.packetserrors
    $StatsLine | Add-Member -Name 'RX-PacketsDiscards' -MemberType Noteproperty -Value $Json.stats.rx.packetsdiscards
    $StatsLine | Add-Member -Name 'TX-Bytes'           -MemberType Noteproperty -Value $Json.stats.tx.bytes
    $StatsLine | Add-Member -Name 'TX-Packets'         -MemberType Noteproperty -Value $Json.stats.tx.packets
    $StatsLine | Add-Member -Name 'TX-PacketsErrors'   -MemberType Noteproperty -Value $Json.stats.tx.packetserrors
    $StatsLine | Add-Member -Name 'TX-PacketsDiscards' -MemberType Noteproperty -Value $Json.stats.tx.packetsdiscards  
    
    # Add lines to $Array
    $Array += $StatsLine
    
    Return $Array
}

Function Get-BBOXWIRELESSACL {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.acl
    
    # Create New PSObject and add values to array
    $RuleLine = New-Object -TypeName PSObject
    $RuleLine | Add-Member -Name 'Service'     -MemberType Noteproperty -Value 'Mac Address Filtering'
    $RuleLine | Add-Member -Name 'Status'      -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $RuleLine | Add-Member -Name 'Rules Count' -MemberType Noteproperty -Value $Json.rules.count
    
    # Add lines to $Array
    $Array += $RuleLine
    
    Return $Array
}

Function Get-BBOXWIRELESSACLRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.acl
    
    If ($Json.rules.Count -ne 0) {
        
        $Rule = 0
        
        While ($Rule -lt $Json.rules.Count) {
            
            # Create New PSObject and add values to array
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name 'ID'          -MemberType Noteproperty -Value $Json.rules[$Rule].id
            $RuleLine | Add-Member -Name 'Status'      -MemberType Noteproperty -Value (Get-Status -Status $Json.rules[$Rule].enable)
            $RuleLine | Add-Member -Name 'Mac Address' -MemberType Noteproperty -Value $Json.rules[$Rule].macaddress
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
	}
    Else {
        Return $null
    }
}

Function Get-BBOXWIRELESSACLRulesID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $WIRELESSACLIDs = Get-WIRELESSACLRules -UrlToGo $UrlToGo
    If ($global:TriggerExportConfig -eq $true) {
        $WIRELESSACLID = $WIRELESSACLIDs | Select-Object -Property ID,'Mac Address' -First 1
    }
    Else {
        $WIRELESSACLID = $WIRELESSACLIDs | Select-Object -Property ID,'Mac Address' | Out-GridView -Title "Wireless ACL Rules List" -OutputMode Single
    }
    $WIRELESSACLHost = $WIRELESSACLIDs | Where-Object {$_.ID -ilike $WIRELESSACLID.id}
    
    Return $WIRELESSACLHost
}

Function Get-BBOXWIRELESSFastScanMe {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )

    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()

    # Create New PSObject and add values to array
    $Line = New-Object -TypeName PSObject
    $Line | Add-Member -Name 'link'       -MemberType Noteproperty -Value $Json.link
    $Line | Add-Member -Name 'MACAddress' -MemberType Noteproperty -Value $Json.macaddress
    $Line | Add-Member -Name 'RSSI'       -MemberType Noteproperty -Value $Json.rssi
    $Line | Add-Member -Name 'Rate'       -MemberType Noteproperty -Value $Json.rate
    $Line | Add-Member -Name 'RxRate'     -MemberType Noteproperty -Value $Json.rxrate
    $Line | Add-Member -Name 'MCS'        -MemberType Noteproperty -Value $Json.mcs
    
    # Add lines to $Array
    $Array += $Line
        
    Return $Array
}

Function Get-BBOXWIRELESSFrequencyNeighborhoodScanID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.scan
    
    $lineid = 0
    
    If ($Json.Count -ne 0) {
        
        While ($lineid -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $WifiLine = New-Object -TypeName PSObject
            $WifiLine | Add-Member -Name 'Band'       -MemberType Noteproperty -Value $Json[$lineid].band
            $WifiLine | Add-Member -Name 'SSID'       -MemberType Noteproperty -Value $Json[$lineid].ssid
            $WifiLine | Add-Member -Name 'MACAddress' -MemberType Noteproperty -Value $Json[$lineid].macaddress
            $WifiLine | Add-Member -Name 'Channel'    -MemberType Noteproperty -Value $Json[$lineid].channel
            $WifiLine | Add-Member -Name 'Security'   -MemberType Noteproperty -Value $Json[$lineid].security
            $WifiLine | Add-Member -Name 'RSSI'       -MemberType Noteproperty -Value "$($Json[$lineid].rssi) $($Json[$lineid].rssiunit)"
            $WifiLine | Add-Member -Name 'Mode'       -MemberType Noteproperty -Value $Json[$lineid].mode
            
            # Add lines to $Array
            $Array += $WifiLine
            
            # Go to next line
            $lineid ++
        }
        
        Return $Array
    }
    Else {      
        Return $null
    }
}

Function Get-BBOXWIRELESSScheduler {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wireless.scheduler
    
    If ($Json.enable -eq 1) {
        
        $VOIPSchedulerStatusRemaining = New-TimeSpan -Seconds $Json.services.voipscheduler.statusRemaining
        $TimeRemaining = "$($VOIPSchedulerStatusRemaining.Hours)h$($VOIPSchedulerStatusRemaining.Minutes)m$($VOIPSchedulerStatusRemaining.Seconds)s"
    }
    Else {
        $TimeRemaining = $Json.services.voipscheduler.statusRemaining
    }
    
    # Create New PSObject and add values to array
    $SchedulerLine = New-Object -TypeName PSObject
    $SchedulerLine | Add-Member -Name 'Date'           -MemberType Noteproperty -Value $(Edit-Date -Date $Json.now)
    $SchedulerLine | Add-Member -Name 'Service'        -MemberType Noteproperty -Value 'Wireless Scheduler'
    $SchedulerLine | Add-Member -Name 'State'          -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $SchedulerLine | Add-Member -Name 'Status'         -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $SchedulerLine | Add-Member -Name 'Status Until'   -MemberType Noteproperty -Value $Json.statusuntil
    $SchedulerLine | Add-Member -Name 'Time Remaining' -MemberType Noteproperty -Value $TimeRemaining
    $SchedulerLine | Add-Member -Name 'Rules Count'    -MemberType Noteproperty -Value $Json.rules.count
    
    # Add lines to $Array
    $Array += $SchedulerLine
    
    Return $Array
}

Function Get-BBOXWIRELESSSchedulerRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wireless.scheduler.rules
    
    If ($Json.Count -ne 0) {
        
        $Rule = 0
        
        While ($Rule -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name 'ID'    -MemberType Noteproperty -Value $Json[$Rule].id
            $RuleLine | Add-Member -Name 'Name'  -MemberType Noteproperty -Value $Json[$Rule].name
            $RuleLine | Add-Member -Name 'State' -MemberType Noteproperty -Value (Get-State -State $Json[$Rule].enable)
            $RuleLine | Add-Member -Name 'Start' -MemberType Noteproperty -Value "$($Json[$Rule].start.day) at $($Json[$Rule].start.hour):$($Json[$Rule].start.minute)"
            $RuleLine | Add-Member -Name 'End'   -MemberType Noteproperty -Value "$($Json[$Rule].end.day) at $($Json[$Rule].end.hour):$($Json[$Rule].end.minute)"
            
            # Add lines to $Array
            $Array += $RuleLine
            
            # Go to next line
            $Rule ++
        }
        
        Return $Array
	}
    Else {
        Return $null
    }
}

Function Get-BBOXWIRELESSRepeater {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Create New PSObject and add values to array
    $RepeaterLine = New-Object -TypeName PSObject
    $RepeaterLine | Add-Member -Name 'Service'           -MemberType Noteproperty -Value 'WIRELESS Repeater'
    $RepeaterLine | Add-Member -Name 'Station Count'     -MemberType Noteproperty -Value $Json.stationscount
    If ($Json.list) {
        $RepeaterLine | Add-Member -Name 'Station List'  -MemberType Noteproperty -Value $($Json.list -join ',')
    }
    Else {
        $RepeaterLine | Add-Member -Name 'Station List'  -MemberType Noteproperty -Value "0"
    }
    If ($Json.zerotouch.list) {
        $RepeaterLine | Add-Member -Name 'ZeroTouch'     -MemberType Noteproperty -Value $($Json.zerotouch.list -join ',') # Since version 20.6.8
    }
    Else {
        $RepeaterLine | Add-Member -Name 'ZeroTouch'     -MemberType Noteproperty -Value "0"
    }
    
    # Add lines to $Array
    $Array += $RepeaterLine
    
    Return $Array
}

function Get-BBOXWIRELESSVideoBridgeSetTopBoxes {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].videobridge.topology.settopboxes
    $Lineid = 0
    
    While ($Lineid -lt ($Json.Count)) {
        
        # Create New PSObject and add values to array
        $VideoBridgeLine = New-Object -TypeName PSObject
        $VideoBridgeLine | Add-Member -Name 'IMEI'                     -MemberType Noteproperty -Value $Json[$lineid].imei
        $VideoBridgeLine | Add-Member -Name 'MACAddress'               -MemberType Noteproperty -Value $Json[$lineid].macaddress
        $VideoBridgeLine | Add-Member -Name 'RSSI'                     -MemberType Noteproperty -Value $Json[$lineid].rssi
        $VideoBridgeLine | Add-Member -Name 'Connection Status'        -MemberType Noteproperty -Value $(Get-Status -Status $($Json[$lineid].connection_status))
        $VideoBridgeLine | Add-Member -Name 'Connection Mode'          -MemberType Noteproperty -Value $Json[$lineid].connection_mode
        $VideoBridgeLine | Add-Member -Name 'Access Point'             -MemberType Noteproperty -Value $Json[$lineid].access_point
        $VideoBridgeLine | Add-Member -Name 'Access Point IMEI'        -MemberType Noteproperty -Value $Json[$lineid].access_point_imei
        $VideoBridgeLine | Add-Member -Name 'Access Point MAC Address' -MemberType Noteproperty -Value $Json[$lineid].access_point_macaddress
        $VideoBridgeLine | Add-Member -Name 'Repeater RSSI'            -MemberType Noteproperty -Value $Json[$lineid].repeater_rssi
        
        # Add lines to $Array
        $Array += $VideoBridgeLine
        $Lineid ++
    }
    Return $Array
}

function Get-BBOXWIRELESSVideoBridgeRepeaters {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json[0].videobridge.topology.repeaters
    $Lineid = 0
    
    While ($Lineid -lt ($Json.Count)) {
        
        # Create New PSObject and add values to array
        $RepeaterLine = New-Object -TypeName PSObject
        $RepeaterLine | Add-Member -Name 'IMEI'                     -MemberType Noteproperty -Value $Json[$lineid].imei
        $RepeaterLine | Add-Member -Name 'MACAddress'               -MemberType Noteproperty -Value $Json[$lineid].macaddress
        $RepeaterLine | Add-Member -Name 'RSSI'                     -MemberType Noteproperty -Value $Json[$lineid].rssi
        $RepeaterLine | Add-Member -Name 'Connection Status'        -MemberType Noteproperty -Value $(Get-Status -Status $($Json[$lineid].connection_status))
        $RepeaterLine | Add-Member -Name 'Connection Mode'          -MemberType Noteproperty -Value $Json[$lineid].connection_mode
        $RepeaterLine | Add-Member -Name 'Access Point'             -MemberType Noteproperty -Value $Json[$lineid].access_point
        $RepeaterLine | Add-Member -Name 'Access Point IMEI'        -MemberType Noteproperty -Value $Json[$lineid].access_point_imei
        $RepeaterLine | Add-Member -Name 'Access Point MAC Address' -MemberType Noteproperty -Value $Json[$lineid].access_point_macaddress
        $RepeaterLine | Add-Member -Name 'Repeater RSSI'            -MemberType Noteproperty -Value $Json[$lineid].repeater_rssi
        
        # Add lines to $Array
        $Array += $RepeaterLine
        $Lineid ++
    }
    Return $Array
}

#endregion WIRELESS

#region WPS

Function Get-BBOXWIRELESSWPS {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-BBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wps
    
    # Create New PSObject and add values to array
    $WPSLine = New-Object -TypeName PSObject
    $WPSLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'WPS'
    $WPSLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $WPSLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $WPSLine | Add-Member -Name 'Timeout' -MemberType Noteproperty -Value $json.timeout
    
    # Add lines to $Array
    $Array += $WPSLine
    
    Return $Array
}

#endregion WPS

#endregion Get Function

#region Set function

Function Set-BBOXDeviceReboot {
    
    <#
    .SYNOPSIS
        Reboot the box
        
    .DESCRIPTION
        Reboot the box with token ID
        
    .PARAMETER UrlToGo
        This is the Url to reboot the box
        
    .EXAMPLE
        It is possible to do it localy and remotly
        SET-BBOXDeviceReboot -UrlToGo 'https://192.168.1.254/api/v1/device/reboot'
        
    .INPUTS
        [String]$UrlToGo
        [String]$Token
        
    .OUTPUTS
        Box reboote
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : 'Get-BBOXDeviceToken', ''
        linked to script : '.\BBOX-Administration.psm1'
    #>
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $Token = Get-BBOXDeviceToken -UrlToGo $UrlToGo
    $Token = ($Token | Where-Object {$_.Description -like 'Token'}).value
    $UrlToGo = $UrlToGo.replace('token','reboot?btoken=')
    $UrlToGo = "$UrlToGo$Token"
    Write-log INFO -Category 'Program run' -Name 'Device Reboot' -Message 'Send reboot command ...' -NotDisplay
    #Set-BBOXInformation -UrlToGo $UrlToGo
}

Function Set-BBOXDeviceResetFactory {
    
    <#
    .SYNOPSIS
        Reset to factory the box
        
    .DESCRIPTION
        Reset to factory the box with token ID
        
    .PARAMETER UrlToGo
        This is the Url to reset the box
        
    .EXAMPLE
        It is possible to do it only localy
        Set-BBOXDeviceResetFactory -UrlToGo 'https://192.168.1.254/api/v1/device/factory'
        
    .INPUTS
        [String]$UrlToGo
        [String]$Token
        
    .OUTPUTS
        Box reseted
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : 'Get-BBOXDeviceToken', ''
        linked to script : '.\BBOX-Administration.psm1'
    #>
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $Token = Get-BBOXDeviceToken -UrlToGo $UrlToGo
    $Token = ($Token | Where-Object {$_.Description -like 'Token'}).value
    $UrlToGo = $UrlToGo.replace('token','factory?btoken=')
    $UrlToGo = "$UrlToGo$Token"
    Write-log INFO -Category 'Program run' -Name 'Device Factory Reset' -Message 'Send Factory reset command ...' -NotDisplay
    #Set-BBOXInformation -UrlToGo $UrlToGo
}

#endregion Set function

#region Referential Contact for BBox

# To Show Referential Contact for BBox
function Show-BBOXReferentialContact {
    
    <#
    .SYNOPSIS
        To show contact in the referencial for Bytel Box
        
    .DESCRIPTION
        To show contact in the referencial for Bytel Box
        
    .PARAMETER
        No parameter, values are asked directly in function
        
    .EXAMPLE
        Show-ReferentialContact
        
    .INPUTS
        $global:PhoneNumberReferential
        
    .OUTPUTS
        [PSCustomObject]@{
            PhoneNumber = $TextBox0.Text
            Prefixe     = $TextBox1.Text
            Number      = $TextBox2.Text
            Name        = $TextBox3.Text
            Surname     = $TextBox4.Text
            Description = $TextBox5.Text
            Category    = $TextBox6.Text
            Type        = $TextBox7.Text
        }
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : ''
        linked to script : '.\BOX-Module.psm1'
    #>
    
    Param()
    
    Write-Log -Type INFO -Category 'Program Run' -Name 'Show Referential Contact' -Message 'Start Show Referential Contact' -NotDisplay
    Write-Log -Type INFONO -Category 'Program Run' -Name 'Show Referential Contact' -Message 'Show Referential Contact Status :' -NotDisplay
    
    Try {
        # Display contact Information from BBox
        $global:PhoneNumberReferential | Out-GridView -Title "Referential Contact for BBox" -Wait -ErrorAction Stop
        Write-Log -Type VALUE -Category 'Program Run' -Name 'Show Referential Contact' -Message "Successful" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program Run' -Name 'Show Referential Contact' -Message "Failed, due to : $($_.ToString())"
    }
    
    Write-Log -Type INFO -Category 'Program Run' -Name 'Show Referential Contact' -Message 'End Show Referential Contact' -NotDisplay
    
}

# To Add New Referential Contact for BBox
function Add-BBOXNewReferentialContact {
    
    <#
    .SYNOPSIS
        To add new contact in the referencial for Bytel Box
        
    .DESCRIPTION
        To add new contact in the referencial for Bytel Box
        
    .PARAMETER
        No parameter, values are asked directly in function
        
    .EXAMPLE
        Show-WindowsFormDialogBox8Inuput -MainFormTitle "Please complete this form :" -LabelMessageText0 "PhoneNumber :" -DefaultValue0 "+33102030405" -LabelMessageText1 "Prefixe :" -DefaultValue1 "+33" -LabelMessageText2 "Number :" -DefaultValue2 "0102030405" -LabelMessageText3 "Name :" -DefaultValue3 "DUPONT" -LabelMessageText4 "SurName :" -DefaultValue4 "Dupont" -LabelMessageText5 "Description :" -DefaultValue5 "This is the desciption of the contact" -LabelMessageText6 "Category :" -DefaultValue6 "Family / Friend / Others" -LabelMessageText7 "Type :" -DefaultValue7 "Mobile / Fixe" -OkButtonText "OK" -CancelButtonText "Cancel"
        
    .INPUTS
        User inputs
        
    .OUTPUTS
        [PSCustomObject]@{
            PhoneNumber = $TextBox0.Text
            Prefixe     = $TextBox1.Text
            Number      = $TextBox2.Text
            Name        = $TextBox3.Text
            Surname     = $TextBox4.Text
            Description = $TextBox5.Text
            Category    = $TextBox6.Text
            Type        = $TextBox7.Text
        }
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : 'Show-WindowsFormDialogBox8Inuput'
        linked to script : '.\BOX-Module.psm1'
    #>
    
    Param()
    
    Write-Log -Type INFO -Category 'Program Run' -Name 'Add New Referential Contact' -Message 'Start Add New Referential Contact' -NotDisplay
    Write-Log -Type INFONO -Category 'Program Run' -Name 'Add New Referential Contact' -Message 'Add New Referential Contact Status :' -NotDisplay
    
    Try {
        # Get New contact Information from user inputs
        $NewReferentialContact = Show-WindowsFormDialogBox8Inuput -MainFormTitle "Please complete this form :" -LabelMessageText0 "PhoneNumber :" -DefaultValue0 "+33102030405" -LabelMessageText1 "Prefixe :" -DefaultValue1 "+33" -LabelMessageText2 "Number :" -DefaultValue2 "0102030405" -LabelMessageText3 "Name :" -DefaultValue3 "DUPONT" -LabelMessageText4 "SurName :" -DefaultValue4 "Dupont" -LabelMessageText5 "Description :" -DefaultValue5 "This is the desciption of the contact" -LabelMessageText6 "Category :" -DefaultValue6 "Family / Friend / Others" -LabelMessageText7 "Type :" -DefaultValue7 "Mobile / Fixe" -OkButtonText "OK" -CancelButtonText "Cancel"
        
        # Add New contact to the referential
        $global:PhoneNumberReferential += $NewReferentialContact
        
        Write-Log -Type VALUE -Category 'Program Run' -Name 'Add New Referential Contact' -Message "Successful" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program Run' -Name 'Add New Referential Contact' -Message "Failed, due to : $($_.ToString())"
    }
    
    Write-Log -Type INFO -Category 'Program Run' -Name 'Add New Referential Contact' -Message 'End Add New Referential Contact' -NotDisplay
    
    # Export New Phone Number Referential to CSV file
    Write-Log -Type INFO -Category 'Program Run' -Name 'Export New Referential Contact' -Message 'Start Export New Referential Contact' -NotDisplay
    Write-Log -Type INFONO -Category 'Program Run' -Name 'Export New Referential Contact' -Message 'Export New Referential Contact Status :' -NotDisplay
    
    Try { 
        $global:PhoneNumberReferential | Export-Csv -Path $global:PhoneNumberReferentialFileNamePath -Force -Encoding utf8 -Delimiter ";"
        Write-Log -Type VALUE -Category 'Program Run' -Name 'Export New Referential Contact' -Message "Successful" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program Run' -Name 'Export New Referential Contact' -Message "Failed, due to : $($_.ToString())"
    }
    
    Write-Log -Type INFO -Category 'Program Run' -Name 'Export New Referential Contact' -Message 'End Export New Referential Contact' -NotDisplay
}

# To Remove Referential Contact for BBox
function Remove-BBOXReferentialContact {
    
    <#
    .SYNOPSIS
        To Remove contact in the referencial for Bytel Box
        
    .DESCRIPTION
        To Remove contact in the referencial for Bytel Box
        
    .PARAMETER
        No parameter, values are asked directly in function
        
    .EXAMPLE
        Remove-ReferentialContact
        
    .INPUTS
        $global:PhoneNumberReferential
        
    .OUTPUTS
        [PSCustomObject]@{
            PhoneNumber = $TextBox0.Text
            Prefixe     = $TextBox1.Text
            Number      = $TextBox2.Text
            Name        = $TextBox3.Text
            Surname     = $TextBox4.Text
            Description = $TextBox5.Text
            Category    = $TextBox6.Text
            Type        = $TextBox7.Text
        }
    
    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : ''
        linked to script : '.\BOX-Module.psm1'
    #>
    
    Param()
    
    Write-Log -Type INFO -Category 'Program Run' -Name 'Remove Referential Contact' -Message 'Start Remove Referential Contact' -NotDisplay
    Write-Log -Type INFONO -Category 'Program Run' -Name 'Remove Referential Contact' -Message 'Remove Referential Contact Status :' -NotDisplay
    
    Try {
        # Display contact Information from BBox
        $RemoveReferentialContact = $global:PhoneNumberReferential | Out-GridView -Title "Referential Contact for BBox" -OutputMode Single -ErrorAction Stop
        $RemoveReferentialContact
        $KeepReferentialContact = $global:PhoneNumberReferential | Where-Object {$_.Number -notlike $RemoveReferentialContact.Number}
        $KeepReferentialContact
        $global:PhoneNumberReferential = $KeepReferentialContact
        Write-Log -Type VALUE -Category 'Program Run' -Name 'Remove Referential Contact' -Message "Successful" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program Run' -Name 'Remove Referential Contact' -Message "Failed, due to : $($_.ToString())"
    }
    
    Write-Log -Type INFO -Category 'Program Run' -Name 'Remove Referential Contact' -Message 'End Remove Referential Contact' -NotDisplay    
    
    # Export New Phone Number Referential to CSV file
    Write-Log -Type INFO -Category 'Program Run' -Name 'Export New Referential Contact' -Message 'Start Export New Referential Contact' -NotDisplay
    Write-Log -Type INFONO -Category 'Program Run' -Name 'Export New Referential Contact' -Message 'Export New Referential Contact Status :' -NotDisplay
    
    Try { 
        $global:PhoneNumberReferential | Export-Csv -Path $global:PhoneNumberReferentialFileNamePath -Force -Encoding utf8 -Delimiter ";"
        Write-Log -Type VALUE -Category 'Program Run' -Name 'Export New Referential Contact' -Message "Successful" -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Category 'Program Run' -Name 'Export New Referential Contact' -Message "Failed, due to : $($_.ToString())"
    }
    
    Write-Log -Type INFO -Category 'Program Run' -Name 'Export New Referential Contact' -Message 'End Export New Referential Contact' -NotDisplay    
}

#endregion Referential Contact for BBox

#endregion BBox

#region Freebox

#region Errors code

Function Get-FREEBOXErrorCode {
    
    <#
    .SYNOPSIS
        Get Error code and convert it to human readable

    .DESCRIPTION
        Get Error code and convert it to human readable

    .PARAMETER Json
        This the Json error code to convert

    .EXAMPLE
        Get-FREEBOXErrorCode -Json $JSON

    .INPUTS
        [Array]$Json
        This the Json error code to convert

    .OUTPUTS
        [PSObject]$Array

    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : '', ''
        linked to script : '.\BBOX-Administration.psm1'
    #>
    
    Param (
        [Parameter(Mandatory=$True)]
        [Array]$Json
    )
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.exception

    # Create New PSObject and add values to array
    $ErrorLine = New-Object -TypeName PSObject
    $ErrorLine | Add-Member -Name 'Success'       -MemberType Noteproperty -Value $Json.success
    $ErrorLine | Add-Member -Name 'Message'       -MemberType Noteproperty -Value $Json.msg
    $ErrorLine | Add-Member -Name 'ErrorCode'     -MemberType Noteproperty -Value $Json.error_code
    $ErrorLine | Add-Member -Name 'UID'           -MemberType Noteproperty -Value $Json.uid
    $ErrorLine | Add-Member -Name 'Password Salt' -MemberType Noteproperty -Value $Json.result.password_salt
    $ErrorLine | Add-Member -Name 'Challenge'     -MemberType Noteproperty -Value $Json.result.challenge
    
    # Add lines to $Array
    $Array += $ErrorLine
    
    Return $Array
}

Function Get-FREEBOXErrorCodeTest {
    
    <#
    .SYNOPSIS
        Get Error code and convert it to human readable

    .DESCRIPTION
        Get Error code and convert it to human readable

    .PARAMETER Json
        This the Json error code to convert

    .EXAMPLE
        Get-FREEBOXErrorCodeTest -Json $JSON

    .INPUTS
        [Array]$Json
        This the Json error code to convert

    .OUTPUTS
        [PSObject]$Array

    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : '', ''
        linked to script : '.\BBOX-Administration.psm1'

    #>

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from Box API
    $Json = Get-FREEBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    #$Json = $Json.exception
    
    # Create New PSObject and add values to array
    $ErrorLine = New-Object -TypeName PSObject
    $ErrorLine | Add-Member -Name 'Success'       -MemberType Noteproperty -Value $Json.success
    $ErrorLine | Add-Member -Name 'Message'       -MemberType Noteproperty -Value $Json.msg
    $ErrorLine | Add-Member -Name 'ErrorCode'     -MemberType Noteproperty -Value $Json.error_code
    $ErrorLine | Add-Member -Name 'UID'           -MemberType Noteproperty -Value $Json.uid
    $ErrorLine | Add-Member -Name 'Password Salt' -MemberType Noteproperty -Value $Json.result.password_salt
    $ErrorLine | Add-Member -Name 'Challenge'     -MemberType Noteproperty -Value $Json.result.challenge
    
    # Add lines to $Array
    $Array += $ErrorLine
    
    Return $Array
}

#endregion Errors code

#region Get Function

#region API VERSION

Function Get-FREEBOXAPIVersion {
    
    <#
    .SYNOPSIS
        To get all information about API version and associated Url
        
    .DESCRIPTION
        To get all information about API version and associated Url
        
    .PARAMETER UrlToGo
        This is the Url to get information about API version
        
    .EXAMPLE
        Get-FREEBOXAPIVersion -UrlToGo 'https://mafreebox.freebox.fr/api/v4/api_version'
        
    .INPUTS
        [String]$UrlToGo
        This is the url to go to get API Version
        
    .OUTPUTS
        [Array]$Array
        This is the result of API Version information

    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : 'Get-FREEBOXInformation'
        linked to script : '.\BBOX-Administration.psm1'
    #>
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from FREEBOX API
    $Json = Get-FREEBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Create New PSObject and add values to array
    $APIVersionLine = New-Object -TypeName PSObject
    $APIVersionLine | Add-Member -Name "Box Model Name"  -MemberType Noteproperty -Value $Json.box_model_name
    $APIVersionLine | Add-Member -Name "Device Type"     -MemberType Noteproperty -Value $Json.device_type
    $APIVersionLine | Add-Member -Name "BOX Model"       -MemberType Noteproperty -Value $Json.box_model
    $APIVersionLine | Add-Member -Name "UID"             -MemberType Noteproperty -Value $Json.uid
    $APIVersionLine | Add-Member -Name "HTTPS Port"      -MemberType Noteproperty -Value $Json.https_port
    $APIVersionLine | Add-Member -Name "HTTPS Status"    -MemberType Noteproperty -Value $(Get-Status -Status $Json.https_available)
    $APIVersionLine | Add-Member -Name "API Version"     -MemberType Noteproperty -Value $Json.api_version
    $APIVersionLine | Add-Member -Name "API Base URL"    -MemberType Noteproperty -Value $Json.api_base_url
    #$APIVersionLine | Add-Member -Name "APIVersion Name" -MemberType Noteproperty -Value $Json.APIVersion_name
    $APIVersionLine | Add-Member -Name "API Domain"      -MemberType Noteproperty -Value $Json.api_domain
    
    # Add lines to $Array
    $Array += $APIVersionLine
    
    Return $Array
}

#endregion API VERSION

#region Contact/Annuary

Function Get-FREEBOXContact {
    
    <#
    .SYNOPSIS
        To get All contacts details
        
    .DESCRIPTION
        To get All contacts details
        
    .PARAMETER UrlToGo
        This is the Url to get Contact Information
        
    .EXAMPLE
        Get-FREEBOXContact -UrlToGo 'https://mafreebox.freebox.fr/api/v4/contact'
        
    .INPUTS
        [String]$UrlToGo
        This is the Url to get Contact Information
        
    .OUTPUTS
        [Array]$Array
        This is the array with all contacts information

    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : 'Get-FREEBOXInformation'
        linked to script : '.\BBOX-Administration.psm1'
#>
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from FREEBOX API
    $Json = Get-FREEBOXInformation -UrlToGo $UrlToGo
    $Json = $Json.result

    # Create array
    $Array = @()
    
    $ContactLine = 0
    While ($ContactLine -lt $Json.count) {
        
        $numberLine = 0
        While ($numberLine -lt $Json[$ContactLine].numbers.count) {
            
            # Create New PSObject and add values to array
            $ContactLineList = New-Object -TypeName PSObject
            $ContactLineList | Add-Member -Name "ID"            -MemberType Noteproperty -Value $Json[$ContactLine].id
            $ContactLineList | Add-Member -Name "Display Name"  -MemberType Noteproperty -Value $Json[$ContactLine].display_name
            $ContactLineList | Add-Member -Name "Last Name"     -MemberType Noteproperty -Value $Json[$ContactLine].last_name
            $ContactLineList | Add-Member -Name "First Name"    -MemberType Noteproperty -Value $Json[$ContactLine].first_name
            $ContactLineList | Add-Member -Name "Number"        -MemberType Noteproperty -Value $Json[$ContactLine].numbers[$numberLine].number
            $ContactLineList | Add-Member -Name "Type"          -MemberType Noteproperty -Value $Json[$ContactLine].numbers[$numberLine].type
            $ContactLineList | Add-Member -Name "Contact ID"    -MemberType Noteproperty -Value $Json[$ContactLine].numbers[$numberLine].contact_id
            $ContactLineList | Add-Member -Name "Is default"    -MemberType Noteproperty -Value $Json[$ContactLine].numbers[$numberLine].is_default
            $ContactLineList | Add-Member -Name "Is onw"        -MemberType Noteproperty -Value $Json[$ContactLine].numbers[$numberLine].is_own
            $ContactLineList | Add-Member -Name "Birthday Date" -MemberType Noteproperty -Value $Json[$ContactLine].birthday
            $ContactLineList | Add-Member -Name "Company"       -MemberType Noteproperty -Value $Json[$ContactLine].company
            $ContactLineList | Add-Member -Name "Notes"         -MemberType Noteproperty -Value $Json[$ContactLine].notes
            $ContactLineList | Add-Member -Name "Ulr Photo"     -MemberType Noteproperty -Value $Json[$ContactLine].photo_url
            $ContactLineList | Add-Member -Name "Last Update"   -MemberType Noteproperty -Value $((Get-Date -Date "01/01/1970").addseconds($Json[$ContactLine].last_update))
            
            # Add lines to $Array
            $Array += $ContactLineList

            $numberLine ++
        }
    $ContactLine ++
    }
    Return $Array
}

#endregion Contacts/Annuary

#region Call Log

Function Get-FREEBOXCalllog {
    
    <#
    .SYNOPSIS
        To get all log call
        
    .DESCRIPTION
        To get all log call
        
    .PARAMETER $UrlToGo
        This is the Url to get Call Log information
        
    .EXAMPLE
        Get-FREEBOXCalllog -UrlToGo 'https://mafreebox.freebox.fr/api/v4/call/log/'
        
    .INPUTS
        [String]$UrlToGo
        This is the Url to get Call Log information
        
    .OUTPUTS
        [Array]$Array
        This is the array with all call log information

    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : 'Get-FREEBOXInformation'
        linked to script : '.\BBOX-Administration.psm1'
#>
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from FREEBOX API
    $Json = Get-FREEBOXInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.result
    
    $Call = 0
    
    While ($Call -lt $Json.Count) {
        
        $CallTime = New-TimeSpan -Seconds $Json[$Call].duration
        
        # Create New PSObject and add values to array
        $CallLine = New-Object -TypeName PSObject
        $CallLine | Add-Member -Name "Call ID"      -MemberType Noteproperty -Value $Json[$Call].id
        $CallLine | Add-Member -Name "Number"       -MemberType Noteproperty -Value "0$($Json[$Call].number)"
        $CallLine | Add-Member -Name "Call Type"    -MemberType Noteproperty -Value $Json[$Call].type
        $CallLine | Add-Member -Name "Duration"     -MemberType Noteproperty -Value "$($CallTime.Hours)h $($CallTime.Minutes)min $($CallTime.Seconds)s"
        $CallLine | Add-Member -Name "Call Date"    -MemberType Noteproperty -Value $((Get-Date -Date "01/01/1970").addseconds($Json[$Call].datetime))
        $CallLine | Add-Member -Name "Contact ID"   -MemberType Noteproperty -Value $Json[$Call].contact_id
        $CallLine | Add-Member -Name "Line ID"      -MemberType Noteproperty -Value $Json[$Call].line_id
        $CallLine | Add-Member -Name "Contact Name" -MemberType Noteproperty -Value $Json[$Call].name
        $CallLine | Add-Member -Name "Is New ?"     -MemberType Noteproperty -Value $(Get-Status -Status $Json[$Call].new)
        
        # Add lines to $Array
        $Array += $CallLine
        
        $Call ++
    }
    
    Return $Array
}

Function Get-FREEBOXCalllogSummary {
    
    <#
    .SYNOPSIS
        To get all log call Summary
        
    .DESCRIPTION
        To get all log call Summary
        
    .PARAMETER $UrlToGo
        This is the Url to get Call Log information
        
    .EXAMPLE
        Get-FREEBOXCalllogSummary -UrlToGo 'https://mafreebox.freebox.fr/api/v4/call/log/'
        
    .INPUTS
        [String]$UrlToGo
        This is the Url to get Call Log information
        
    .OUTPUTS
        [Array]$Array
        This is the array with all call log information

    .NOTES
        Author: @Zardrilokis => Tom78_91_45@yahoo.fr
        linked to functions : 'Get-FREEBOXInformation'
        linked to script : '.\BBOX-Administration.psm1'
#>
    
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from FREEBOX API
    $Data = Get-FREEBOXInformation -UrlToGo $UrlToGo
    $PhoneNumbers = $Data.result.number | Select-Object -Unique
        
    # Create array
    $Array = @()
    
    # Get details foreach Phone Numbers
    Foreach ($Number in $PhoneNumbers) {
        
        $CallTime = $Null
        $Details = $Data.result | Where-Object {$_.number -match $Number}
        $Details | ForEach-Object {$CallTime = $CallTime + $_.duration}
        $TotalCallTime = New-TimeSpan -Seconds $CallTime
        $CallDate = $($Details | ForEach-Object {$((Get-Date -Date "01/01/1970").addseconds($_.datetime))}) -join ","
        
        # Create New PSObject and add values to array
        $CallLine = New-Object -TypeName PSObject
        $CallLine | Add-Member -Name "Call IDs"            -MemberType Noteproperty -Value $($Details.id -join ",")
        $CallLine | Add-Member -Name 'Number'              -MemberType Noteproperty -Value $Number
        $CallLine | Add-Member -Name 'Call Date'           -MemberType Noteproperty -Value $CallDate
        $CallLine | Add-Member -Name 'Call Count'          -MemberType Noteproperty -Value $Details.Count
        $CallLine | Add-Member -Name 'Call Type'           -MemberType Noteproperty -Value $($($Details.Type | Select-Object -Unique) -join ",")
        $CallLine | Add-Member -Name 'Call Accepted Count' -MemberType Noteproperty -Value $($Details.Type | Where-Object {$_ -match "Accepted"}).count
        $CallLine | Add-Member -Name "Call Missed Count"   -MemberType Noteproperty -Value $($Details.Type | Where-Object {$_ -match "Missed"}).count
        $CallLine | Add-Member -Name 'Call Outgoing Count' -MemberType Noteproperty -Value $($Details.Type | Where-Object {$_ -match "Outgoing"}).count
        $CallLine | Add-Member -Name 'Total Call Time'     -MemberType Noteproperty -Value $TotalCallTime
        $CallLine | Add-Member -Name "Contact ID"          -MemberType Noteproperty -Value $($Details.contact_id | Select-Object -Unique)
        $CallLine | Add-Member -Name "Line ID"             -MemberType Noteproperty -Value $($Details.line_id | Select-Object -Unique)
        $CallLine | Add-Member -Name "Contact Name"        -MemberType Noteproperty -Value $($Details.name | Select-Object -Unique)
        $CallLine | Add-Member -Name "Is New ?"            -MemberType Noteproperty -Value $(Get-Status -Status $($Details.new | Select-Object -Unique))
        
        # Add lines to $Array
        $Array += $CallLine
    }
    
    Return $Array
}

#endregion Call Log

#endregion Get Function

#region Set function

#endregion Set function

#endregion Freebox

#endregion Switch-Info
