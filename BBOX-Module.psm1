
# Be carefull some variables are linked from main script BBOX-Administration to :
# - $global:JSONSettingsProgramContent
# - $JSONSettingsCurrentUserContent or $global:JSONSettingsDefaultUserContent

#region GLOBAL (All functions below are used only on powershell script : ".\BBOX-Administration.ps1")

#region Add AssemblyName Classies

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#endregion Add AssemblyName Classies

<#
    .SYNOPSIS
    Write-Log allow to write fonctionnal execution logs
    
    .DESCRIPTION
    Write a log in the host console and to a csv file.
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
    
    $global:logpath = $Logname + $(get-date -UFormat %Y%m%d).toString() + '.csv'
    
    # Create log object 
    $log = [pscustomobject] @{Date=(Get-Date -UFormat %Y%m%d_%H%M%S) ; Type=$type ; Name=$name ; Message=$Message  ; user= $(whoami) ; PID=$PID} 
    $log | Add-member -Name ToString -MemberType ScriptMethod -value {$this.date + ' : ' + $this.type +' : ' +$this.name +' : ' + $this.Message} -Force 
    
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
        $mtx = [System.Threading.Mutex]::OpenExisting("Global\PegaseMutex")
    }
    Catch {
        $mtx = New-Object System.Threading.Mutex($false,"Global\PegaseMutex")
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

#region Windows Credential Manager

# Import module TUN.CredentialManager
Function Import-TUNCredentialManager {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$ModuleName
    )
    
    Write-Log -Type INFONO -Name "Program initialisation - Powershell $ModuleName Module installation" -Message "Powershell $ModuleName Module installation status : " -NotDisplay
    
    If ($null -eq (Get-InstalledModule -name $ModuleName -ErrorAction SilentlyContinue)) {
        
        Write-Log -Type WARNING -Name "Program initialisation - Powershell $ModuleName Module installation" -Message 'Not yet' -NotDisplay
        Write-Log -Type INFO -Name "Program initialisation - Powershell $ModuleName Module installation" -Message "Try to install Powershell $ModuleName Module in user context" -NotDisplay
        Write-Log -Type INFO -Name "Program initialisation - Powershell $ModuleName Module installation" -Message "Powershell $ModuleName Module installation status : " -NotDisplay
        
        Try {
            Start-Process -FilePath Pwsh -Verb RunAs -WindowStyle Normal -Wait -ArgumentList {-ExecutionPolicy bypass -command "Install-Module -Name TUN.CredentialManager -Scope Allusers -verbose -Force -ErrorAction Stop;Pause"} -ErrorAction Stop
            Start-Sleep -Seconds 5
        }
        Catch {
            Write-Log -Type WARNING -Name "Program initialisation - Powershell $ModuleName Module installation" -Message "Failed, due to $($_.ToString())" -NotDisplay
            Stop-Program -ErrorAction Stop
        }
    }
    Else {
        Write-Log -Type VALUE -Name "Program initialisation - Powershell $ModuleName Module installation" -Message 'Already installed' -NotDisplay
    }
    
    If (($null -eq $global:TriggerExit) -and (Get-InstalledModule -name $ModuleName)) {
        
        Write-Log -Type VALUE -Name "Program initialisation - Powershell $ModuleName Module installation" -Message 'Success or already installed' -NotDisplay
        Write-Log -Type INFONO -Name "Program initialisation - Powershell $ModuleName Module Importation" -Message "Powershell $ModuleName Module Importation status : " -NotDisplay
        
        Try {
            Import-Module $ModuleName -Global -Force -ErrorAction Stop
            Write-Log -Type VALUE -Name "Program initialisation - Powershell $ModuleName Module Importation" -Message 'Success' -NotDisplay
        }
        Catch {
            Write-Log -Type WARNING -Name "Program initialisation - Powershell $ModuleName Module Importation" -Message "Failed, due to $($_.ToString())" -NotDisplay
            Stop-Program -ErrorAction Stop
        }
    }
    Else {
        Write-Log -Type WARNING -Name "Program initialisation - Powershell $ModuleName Module installation" -Message "Failed, due to $($_.ToString())" -NotDisplay
    }
}

# Remove BBox Credential stored in Windows Credential Manager
Function Remove-BBoxCredential {
    
    Param ()
    
    Write-Log -Type INFO -Name 'Program run - Remove BBox Credential' -Message 'Start Remove BBox Credential' -NotDisplay
    Write-Log -Type INFONO -Name 'Program run - Remove BBox Credential' -Message 'Remove BBox Credential status : ' -NotDisplay
    
    Try {
        $null = Remove-StoredCredential -Target $global:Target -ErrorAction Stop
        Write-Log -Type VALUE -Name 'Program run - Remove BBox Credential' -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program run - Remove BBox Credential' -Message "Failed, due to : $($_.ToString())" -NotDisplay
    }
    
    Write-Log -Type INFO -Name 'Program run - Remove BBox Credential' -Message 'Start Remove BBox Credential' -NotDisplay
    Return 'Program'
}

# Show BBox Credential stored in Windows Credential Manager
Function Show-BBoxCredential {
    
    Param ()

    Write-Log -Type INFO -Name 'Program run - Show BBox Credential' -Message 'Start Show BBox Credential' -NotDisplay
    Write-Log -Type INFONO -Name 'Program run - Show BBox Credential' -Message 'Show BBox Credential status : ' -NotDisplay

    Try {
        $Password = $(Get-StoredCredential -Target $global:Target | Select-Object -Property Password).password 
        
        If($Password){
            
            $Password = $Password | ConvertFrom-SecureString -AsPlainText
            Write-Log -Type VALUE -Name 'Program run - Show BBox Credential' -Message 'Success' -NotDisplay
            Write-Log -Type INFONO -Name 'Program run - Show BBox Credential' -Message "Actual BBox Stored Password : **********" -NotDisplay
        }
        Else {
            $Password = 'None password was found, please set it, before to show it'
            Write-Log -Type VALUE -Name 'Program run - Show BBox Credential' -Message $Password -NotDisplay
        }
        
        $null = Show-WindowsFormDialogBox -Title 'Program run - Show BBox Credential' -Message "Actual BBox Password stored in Windows Credential Manager : $Password" -InfoIcon
        Clear-Variable -Name Password
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program run - Show BBox Credential' -Message "Failed, due to : $($_.ToString())" -NotDisplay
    }

    Write-Log -Type INFO -Name 'Program run - Show BBox Credential' -Message 'Start Show BBox Credential' -NotDisplay
    Return 'Program'
}

# Add BBox Credential in Windows Credential Manager
function Add-BBoxCredential {
    
    Param ()
    
    $Credential = $null
    $Credentialbuild = $null
    Write-Log -Type INFO -Name 'Program run - Password Status' -Message 'Asking password to the user ...' -NotDisplay
    
    While ([string]::IsNullOrEmpty($Credential.Password) -or [string]::IsNullOrEmpty($Credential.UserName)) {
        
        # Ask user to provide BBOX Web Interface Password
        $Credential = Get-Credential -Message 'Please enter your bbox Admin password use for the web portal interface`nIt will store securly in Windows Credential Manager to be used in future' -UserName $global:Target
    }
    
    Write-Log -Type INFO -Name 'Program run - Password Status' -Message 'Set new password to Windows Credential Manager in progress ...' -NotDisplay
    Write-Log -Type INFONO -Name 'Program run - Password Status' -Message 'Windows Credential Manager status : ' -NotDisplay

    Try {
        $Comment = $global:Comment + " - Last modification : $(get-date -Format yyyyMMdd-HHmmss) - By : $(whoami)"
        $Password = $Credential.Password | ConvertFrom-SecureString -AsPlainText
        $Credentialbuild = New-StoredCredential -Target $global:Target -UserName $global:UserName -Password $Password -Comment $Comment -Type Generic -Persist Session | Out-Null
        Write-Log -Type VALUE -Name 'Program run - Password Status' -Message 'Set' -NotDisplay
        Clear-Variable -Name Password
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program run - Password Status' -Message "Failed, due to : $($_.ToString())" -NotDisplay
    }
    
    Show-BBoxCredential
    
    Return $Credentialbuild
    Clear-Variable -Name Credentialbuild
}

#endregion Windows Credential Manager

#region Windows Form Dialog Box

# Used only to display default Windows Form Dialog Box
function Show-WindowsFormDialogBox {
    
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

# Used only to get user's input
function Show-WindowsFormDialogBoxInuput {
    
    Param (
        [Parameter(Mandatory=$True)]
        [string]$MainFormTitle,

        [Parameter(Mandatory=$True)]
        [string]$LabelMessageText,

        [Parameter(Mandatory=$True)]
        [string]$OkButtonText,

        [Parameter(Mandatory=$True)]
        [string]$CancelButtonText
    )
    
    $MainFormSizeX = 330
    $MainFormSizeY = 230
    
    $LabelMessageSizeX = 300
    $LabelMessageSizeY = 60
    
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

# Used only to force user to make a choice between two options none is "Cancel"
function Show-WindowsFormDialogBox2Choices {
    
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
        Stop-Program -ErrorAction Stop
    }
}

# Used only to force user to make a choice between two options where one is "Cancel"
function Show-WindowsFormDialogBox2ChoicesCancel {
    
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
        Stop-Program -ErrorAction Stop
    }
}

# Used only to force user to make a choice between three options
function Show-WindowsFormDialogBox3Choices {
    
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
        Stop-Program -ErrorAction Stop
    }
}

# Used only to force user to make a choice between three options where one is "Cancel"
function Show-WindowsFormDialogBox3ChoicesCancel {
    
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
        Stop-Program -ErrorAction Stop
    }
}

#endregion Windows Form Dialog Box

# Clean folder content
Function Remove-FolderContent {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$FolderRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$FolderName
    )
    
    $FolderPath = "$FolderRoot\$FolderName"
    
    Write-Log -Type INFO -Name 'Program run - Clean folder content' -Message "Start Clean `"$FolderPath`" folder" -NotDisplay
    
    If (Test-Path -Path $FolderPath) {
        
        Write-Log -Type INFONO -Name 'Program run - Clean folder content' -Message "Cleaning `"$FolderPath`" folder content Status : " -NotDisplay
        Try {
            $Null = Remove-Item -Path "$FolderPath\*" -Recurse -Exclude $global:TranscriptFileName
            Write-Log -Type VALUE -Name 'Program run - Clean folder content' -Message 'Success' -NotDisplay
        }
        Catch {
            Write-Log -Type ERROR -Name 'Program run - Clean folder content' -Message "Failed, `"$FolderPath`" folder can't be cleaned due to : $($_.ToString())"
        }
    }
    Else {
         Write-Log -Type INFONO -Name 'Program run - Clean folder content' -Message "`"$FolderPath`" folder state : " -NotDisplay
         Write-Log -Type VALUE -Name 'Program run - Clean folder content' -Message 'Not found' -NotDisplay
    }
    Write-Log -Type INFO -Name 'Program run - Clean folder content' -Message "End Clean `"$FolderPath`" folder content" -NotDisplay
}

# Test and create folder if not yet existing
Function Test-FolderPath {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$FolderRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$FolderPath,
        
        [Parameter(Mandatory=$True)]
        [String]$FolderName
    )
    
    $FolderName = ($FolderName.Split('\'))[-1]
    
    Write-Log -Type INFO -Name 'Program initialisation - Program Folders check' -Message "Start folder check : $FolderPath" -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Program Folders check' -Message "Folder : $FolderPath , state : " -NotDisplay
    
    If (-not (Test-Path -Path $FolderPath)) {
        
        Write-Log -Type WARNING -Name 'Program initialisation - Program Folders check' -Message "Doesn't exists" -NotDisplay
        Write-Log -Type INFONO -Name 'Program initialisation - Program Folders check' -Message "Creation folder : $FolderPath , status : " -NotDisplay
        Try {
            $Null = New-Item -Path $FolderRoot -Name $FolderName -ItemType Directory -Force
            Write-Log -Type VALUE -Name 'Program initialisation - Program Folders check' -Message 'Success' -NotDisplay
        }
        Catch {
            Write-Log -Type ERROR -Name 'Program initialisation - Program Folders check' -Message "Failed, `"$FolderPath`" folder can't be created due to : $($_.ToString())"
            Stop-Program -ErrorAction Stop
        }
    }
    Else {
        Write-Log -Type VALUE -Name 'Program initialisation - Program Folders check' -Message 'Already exists' -NotDisplay
    }
    Write-Log -Type INFO -Name 'Program initialisation - Program Folders check' -Message "End folder check : $FolderName" -NotDisplay
}

# Test and create file if not yet existing
Function Test-FilePath {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$FileRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$FilePath,
        
        [Parameter(Mandatory=$True)]
        [String]$FileName
    )
    
    $FileName = ($FileName.Split('\'))[-1]
    
    Write-Log -Type INFO -Name 'Program initialisation - Program Files check' -Message "Start file check : $FilePath" -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Program Files check' -Message "File : $FilePath , state : " -NotDisplay
    
    If (-not (Test-Path -Path $FilePath)) {
    
        Write-Log -Type WARNING -Name 'Program initialisation - Program Files check' -Message "Doesn't exists" -NotDisplay
        Write-Log -Type INFONO -Name 'Program initialisation - Program Files check' -Message "Creation file status : " -NotDisplay
        Try {
            $Null = New-Item -Path $FileRoot -Name $FileName -ItemType File -Force
            Write-Log -Type VALUE -Name 'Program initialisation - Program Files check' -Message 'Success' -NotDisplay
        }
        Catch {
            Write-Log -Type ERROR -Name 'Program initialisation - Program Files check' -Message "Failed, `"$FilePath`" file can't be created due to : $($_.ToString())"
            Stop-Program -ErrorAction Stop
        }
    }
    Else {
        Write-Log -Type VALUE -Name 'Program initialisation - Program Files check' -Message 'Already exists'  -NotDisplay
    }
    Write-Log -Type INFO -Name 'Program initialisation - Program Files check' -Message "End file check : $FileName" -NotDisplay
}

# Used only to detect ChromeDriver version
Function Get-ChromeDriverVersion {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$ChromeVersion,
        
        [Parameter(Mandatory=$True)]
        [String]$ChromeDriverPath
    )
    
    $ChromeMainVersion = $ChromeVersion.split(".")[0]
    $ChromeDriverVersionList = Get-childItem -Path $ChromeDriverPath | Select-Object Name
    
    Try {
        $ChromeDriverVersion = $($ChromeDriverVersionList | Where-Object {$_.Name -match $ChromeMainVersion})[-1].Name
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Chrome Driver Version' -Message "No Chrome Driver version was found to match Google Chrome version : $ChromeVersion" -NotDisplay
        Write-Log -Type WARNING -Name 'Program initialisation - Chrome Driver Version' -Message "Error detail : $($_.ToString())" -NotDisplay
        Write-Log -Type WARNING -Name 'Program initialisation - Chrome Driver Version' -Message 'Using Chrome Driver default version' -NotDisplay
        $ChromeDriverVersion = 'Default'
    }
    Write-Log -Type INFONO -Name 'Program initialisation - Chrome Driver Version' -Message 'ChromeDriver version selected : ' -NotDisplay    
    Write-Log -Type VALUE -Name 'Program initialisation - Chrome Driver Version' -Message $ChromeDriverVersion -NotDisplay
    
    Return $ChromeDriverVersion
}

# Used only to define bbox connexion type
Function Get-ConnexionType {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$TriggerLANNetwork
    )
    
    Switch ($TriggerLANNetwork) {
    
        '1'        {$ConnexionTypeChoice = $global:JSONSettingsProgramContent.Values.LANNetworkLocal;Break}
        
        '0'        {$ConnexionTypeChoice = $global:JSONSettingsProgramContent.Values.LANNetworkRemote;Break}
        
        Default    {$ConnexionTypeChoice = $global:JSONSettingsProgramContent.Values.LANNetworkLocal;Break}
    }
    
    Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message 'How do you want to connect to the BBOX ?' -NotDisplay

    $ConnexionType = ''
    While ($ConnexionType -notmatch $ConnexionTypeChoice) {
        
        Switch ($TriggerLANNetwork) {
            
            '1'        {Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message '(L) Localy / (R) Remotly / (Q) Quit the Program' -NotDisplay
                        $ConnexionType = Show-WindowsFormDialogBox3ChoicesCancel -MainFormTitle 'Program run - Connexion Type' -LabelMessageText "How do you want to connect to the BBOX ? : `n- (L) Localy`n- (R) Remotly`n- (Q) Quit the Program" -FirstOptionButtonText 'L' -SecondOptionButtonText 'R' -ThirdOptionButtonText 'Q'
                        Break
                    }
            
            '0'        {Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message '(R) Remotly / (Q) Quit the Program' -NotDisplay
                        $ConnexionType = Show-WindowsFormDialogBox2ChoicesCancel -MainFormTitle 'Program run - Connexion Type' -LabelMessageText "How do you want to connect to the BBOX ? : `n- (R) Remotly`n- (Q) Quit the Program" -FirstOptionButtonText 'R' -SecondOptionButtonText 'Q'
                        Break
                    }
            
            Default    {Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message '(L) Localy / (R) Remotly / (Q) Quit the Program' -NotDisplay
                        $ConnexionType = Show-WindowsFormDialogBox3ChoicesCancel -MainFormTitle 'Program run - Connexion Type' -LabelMessageText "How do you want to connect to the BBOX ? : `n- (L) Localy`n- (R) Remotly`n- (Q) Quit the Program" -FirstOptionButtonText 'L' -SecondOptionButtonText 'R' -ThirdOptionButtonText 'Q'
                        Break
                    }
        }
    }
     
    Write-Log -Type INFO -Name 'Program run - Connexion Type' -Message "Connexion Type chosen by user : $ConnexionType" -NotDisplay
    
    Return $ConnexionType
}

# Used only to check if external Bbox DNS is online
Function Get-HostStatus {
    
    Param (
        [Parameter(Mandatory=$false)]
        [String]$UrlRoot
    )
    
    $BBoxDnsStatus = $null
    While ($null -eq $BBoxDnsStatus) {
        
        $UrlRoot = Show-WindowsFormDialogBoxInuput -MainFormTitle 'Program run - Check Host' -LabelMessageText 'Enter your external BBOX IP/DNS Address, Example : example.com' -OkButtonText 'OK' -CancelButtonText 'Cancel'
        Write-Log -Type INFONO -Name 'Program run - Check Host' -Message "Host `"$UrlRoot`" status : " -NotDisplay
        
        If ($global:TriggerDialogBox -eq 1) {
            
            Write-Log -Type VALUE -Name 'Program run - Check Host' -Message 'User Cancel the action' -NotDisplay
            Stop-Program -ErrorAction Stop
            $UrlRoot = $null
            Return $UrlRoot
            Break
        }

        If (-not ([string]::IsNullOrEmpty($UrlRoot))) {
            
            $BBoxDnsStatus = Test-Connection -ComputerName $UrlRoot -Quiet
            
            If ($BBoxDnsStatus -like $true) {
                
                Write-Log -Type VALUE -Name 'Program run - Check Host' -Message 'Online' -NotDisplay
                $global:JSONSettingsCurrentUserContent.Site.oldRemoteUrl = $global:JSONSettingsCurrentUserContent.Site.CurrentRemoteUrl
                $global:JSONSettingsCurrentUserContent.Site.CurrentRemoteUrl = $UrlRoot
                $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
                Return $UrlRoot
                Break
            }
            Else {
                Write-Log -Type WARNING -Name 'Program run - Check Host' -Message 'Offline' -NotDisplay
                Write-Log -Type WARNING -Name 'Program run - Check Host' -Message "Host : $UrlRoot , seems not Online ; please make sure :"
                Write-Log -Type WARNING -Name 'Program run - Check Host' -Message "- You are connected to internet"
                Write-Log -Type WARNING -Name 'Program run - Check Host' -Message "- You enter a valid DNS address or IP address"
                Write-Log -Type WARNING -Name 'Program run - Check Host' -Message "- The `"PingResponder`" service is enabled $($global:JSONSettingsProgramContent.BBoxUrlFirewall)"
                Write-Log -Type WARNING -Name 'Program run - Check Host' -Message "- The `"DYNDNS`" service is enabled and properly configured $($global:JSONSettingsProgramContent.bbox.BBoxUrlDynDns)"
                Write-Log -Type WARNING -Name 'Program run - Check Host' -Message "- The `"Remote`" service is enabled and properly configured $($global:JSONSettingsProgramContent.bbox.BBoxUrlRemote)"
                Show-WindowsFormDialogBox -Title 'Program run - Check Host' -Message "Host : $UrlRoot , seems not Online ; please make sure :`n`n- You are connected to internet`n- You enter a valid DNS address or IP address`n- The `"PingResponder`" service is enabled $($global:JSONSettingsProgramContent.BBoxUrlFirewall)`n- The `"DYNDNS`" service is enabled and properly configured $($global:JSONSettingsProgramContent.bbox.BBoxUrlDynDns)`n- The `"Remote`" service is enabled and properly configured $($global:JSONSettingsProgramContent.bbox.BBoxUrlRemote)" -WarnIcon
                $BBoxDnsStatus = $null
                $UrlRoot = $null
            }
        }
        Else {
            Write-Log -Type WARNING -Name "Program run - Check Host" -Message "This field can't be empty or null"
            Show-WindowsFormDialogBox -Title 'Program run - Check Host' -Message "This field can't be empty or null" -WarnIcon
            $BBoxDnsStatus = $null
            $UrlRoot = $null
        }
    }
}

# Used only to check if external Bbox Port is open
Function Get-PortStatus {
    
    Param (
        [Parameter(Mandatory=$False)]
        [String]$UrlRoot
    )

    $PortStatus = $null
    While (($null -eq $PortStatus)) {
        
        If ($global:TriggerDialogBox -ne 1){
            
            [int]$Port = Show-WindowsFormDialogBoxInuput -MainFormTitle 'Program run - Check Port' -LabelMessageText "Enter your external remote BBOX port`nDefault is 8560`nExample : 80,443" -OkButtonText 'Ok' -CancelButtonText 'Cancel'
            Write-Log -Type INFONO -Name 'Program run - Check Port' -Message "Port `"$Port`" status : " -NotDisplay
        }
        Else {
            Write-Log -Type VALUE -Name 'Program run - Check Port' -Message 'User Cancel the action' -NotDisplay
            Stop-Program -ErrorAction Stop
            $Port = $null
            Return $Port
            Break
        }
        
        If ($global:TriggerDialogBox -ne 1){

            If (($Port -ge 1) -and ($Port -le 65535)) {
                
                $PortStatus = Test-NetConnection -ComputerName $UrlRoot -Port $Port -InformationLevel Detailed | Out-Null
                
                If ($PortStatus.TcpTestSucceeded -like $true) {
                    
                    Write-Log -Type VALUE -Name 'Program run - Check Port' -Message 'Opened' -NotDisplay
                    $global:JSONSettingsCurrentUserContent.Site.OldRemotePort = $global:JSONSettingsCurrentUserContent.Site.CurrentRemotePort
                    $global:JSONSettingsCurrentUserContent.Site.CurrentRemotePort = $Port
                    $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
                    Return $Port
                    Break
                }
                Else {
                    Write-Log -Type WARNING -Name 'Program run - Check Port' -Message 'Closed' -NotDisplay
                    Write-Log -Type WARNING -Name 'Program run - Check Port' -Message "Port $Port seems closed, please make sure :"
                    Write-Log -Type WARNING -Name 'Program run - Check Port' -Message '- You enter a valid port number'
                    Write-Log -Type WARNING -Name 'Program run - Check Port' -Message "- None Firewall rule(s) block this port ($($global:JSONSettingsProgramContent.bbox.Firewall))" 
                    Write-Log -Type WARNING -Name 'Program run - Check Port' -Message "- `"Remote`" service is enabled and properly configured ($($global:JSONSettingsProgramContent.bbox.BBoxUrlRemote))"
                    Show-WindowsFormDialogBox -Title 'Program run - Check Port' -Message "Port $Port seems closed, please make sure :`n`n'- You enter a valid port number'`n- None Firewall rule(s) block this port ($($global:JSONSettingsProgramContent.bbox.Firewall))`n- `"Remote`" service is enabled and properly configured ($($global:JSONSettingsProgramContent.bbox.BBoxUrlRemote))" -WarnIcon
                    $Port = $null
                    $PortStatus = $null
                }
            }
            Else {
                Write-Log -Type WARNING -Name 'Program run - Check Port' -Message 'This field cant be empty or null or must be in the range between 1 and 65565'
                Show-WindowsFormDialogBox -Title 'Program run - Check Port' -Message 'This field cant be empty or null or must be in the range between 1 and 65565' -WarnIcon
                $Port = $null
                $PortStatus = $null
            }
        }
    }
}

# Used only to get BBOX LAN Switch Port State, linked to : "Get-DeviceFullLog"
Function Get-LanPortState {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$LanPortState
    )
    
    Switch ($State) {
    
        0          {$Value = "Disable";Break}
        1          {$Value = "Enable";Break}
        2          {$Value = "Enable";Break}
        3          {$Value = "Enable";Break}
        4          {$Value = "Enable";Break}
        Default    {$Value = "Unknow";Break}
    }
    
    Return $Value
}

# Used only to connect to BBox Web interface
Function Connect-BBOX {
    
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
    Start-Sleep 2
    
    # Enter the password to connect (# Methods to find the input textbox for the password)
    $global:ChromeDriver.FindElementByName("password").SendKeys("$Password") 
    Start-Sleep 1
    
    # Tic checkBox "Stay Connect" (# Methods to find the input checkbox for stay connect)
    $global:ChromeDriver.FindElementByClassName('cb').Click()
    Start-Sleep 1
    
    # Click on the connect button
    $global:ChromeDriver.FindElementByClassName('cta-1').Submit()
    Start-Sleep 1

    If ($global:ChromeDriver.Url -ne $UrlHome) {
        Write-Log ERROR -Name 'Program run - ChromeDriver Authentification' -Message 'Failed, Authentification cant be done, due to : Wrong Password'
        Stop-Program -ErrorAction Stop
    }
}

# Used only to get information from API page content, linked to many functions
Function Get-BBoxInformation {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    Write-Log -Type INFO -Name 'Program run - Get Information' -Message "Start retrieve informations requested" -NotDisplay
    Write-Log -Type INFO -Name 'Program run - Get Information' -Message "Get informations requested from url : $UrlToGo" -NotDisplay
    Write-Log -Type INFO -Name 'Program run - Get Information' -Message "Request status :" -NotDisplay
    
    Try {
        # Go to the web page to get information we need
        $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
        Write-Log -Type INFO -Name 'Program run - Get Information' -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program run - Get Information' -Message "Failed, due to : $($_.ToString())"
        Write-Log -Type ERROR -Name 'Program run - Get Information' -Message "Please check your local/internet network connection"
        Return "0"
        Break
    }
    
    Write-Log -Type INFO -Name 'Program run - Get Information' -Message "End retrieve informations requested" -NotDisplay

    Write-Log -Type INFO -Name "Program run - Convert HTML" -Message "Start convert data from Html to plaintxt format" -NotDisplay
    Write-Log -Type INFONO -Name "Program run - Convert HTML" -Message "HTML Conversion status : " -NotDisplay
    
    Try {
        # Get Web page Content
        $Html = $global:ChromeDriver.PageSource
        # Convert $Html To Text
        $Plaintxt = ConvertFrom-HtmlToText -Html $Html
        Write-Log -Type VALUE -Name "Program run - Convert HTML" -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name "Program run - Convert HTML" -Message "Failed to convert to HTML, due to : $($_.ToString())"
        Write-Log -Type INFO -Name "Program run - Convert HTML" -Message "End convert data from Html to plaintxt format" -NotDisplay
        Return "0"
        Break
    }
    Write-Log -Type INFO -Name "Program run - Convert HTML" -Message "End convert data from Html to plaintxt format" -NotDisplay
        
    Write-Log -Type INFO -Name "Program run - Convert JSON" -Message "Start convert data from plaintxt to Json format" -NotDisplay
    Write-Log -Type INFONO -Name "Program run - Convert JSON" -Message "JSON Conversion status : " -NotDisplay
    
    Try {
        # Convert $Plaintxt as JSON to array
        $Json = $Plaintxt | ConvertFrom-Json -ErrorAction Stop
        Write-Log -Type VALUE -Name "Program run - Convert JSON" -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type ERROR -Name "Program run - Convert JSON" -Message "Failed - Due to : $($_.ToString())"
        Return "0"
    }
    
    Write-Log -Type INFO -Name "Program run - Convert JSON" -Message "End convert data from plaintxt to Json format" -NotDisplay
    
    If ($Json.exception.domain -and ($Json.exception.domain -ne "v1/device/log")) {
        
        Write-Log -Type INFO -Name "Program run - Get API Error Code" -Message "Start get API error code" -NotDisplay
        Write-Log -Type INFONO -Name "Program run - Get API Error Code" -Message "API error code : "
        Try {
            $ErrorCode = Get-ErrorCode -Json $Json
            Write-Log -Type WARNING -Name "Program run - Get API Error Code" -Message $ErrorCode.ErrorReason
            Write-Log -Type WARNING -Name "Program run - Get API Error Code" -Message $ErrorCode -NotDisplay
            Return $ErrorCode
        }
        Catch {
            Write-Log -Type WARNING -Name "Program run - Get API Error Code" -Message $Json -NotDisplay
            Write-Log -Type ERROR -Name "Program run - Get API Error Code" -Message "Failed - Due to : $($_.ToString())"
            Return $null
        }

        Write-Log -Type INFO -Name "Program run - Get API Error Code" -Message "End get API error code" -NotDisplay
    }
    Else {
        Return $Json
    }
}

# Used only to convert HTML page to TXT, linked to : "Get-BBoxInformation"
Function ConvertFrom-HtmlToText {
    
    # Function get from internet : http://winstonfassett.com/blog/2010/09/21/html-to-text-conversion-in-powershell/
    
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

# Used only to select function to get data from BBOX web API or do actions
Function Switch-Info {
    
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
            Get-ErrorCode        {$FormatedData = Get-ErrorCode -UrlToGo $UrlToGo;Break}
            
            Get-ErrorCodeTest    {$FormatedData = Get-ErrorCodeTest -UrlToGo $UrlToGo;Break}
            
            # Airties
            Get-Airties          {$FormatedData = Get-Airties -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            Get-AirtiesL         {$FormatedData = Get-AirtiesLANmode -UrlToGo $UrlToGo;Break}
            
            # Backup
            GET-CONFIGSL         {$FormatedData = Get-BackupList -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            # DHCP
            GET-DHCP             {$FormatedData = Get-DHCP -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-DHCPC            {$FormatedData = Get-DHCPClients -UrlToGo $UrlToGo;Break}
            
            GET-DHCPCID          {$FormatedData = Get-DHCPClientsID -UrlToGo $UrlToGo;Break}
            
            GET-DHCPAO           {$FormatedData = Get-DHCPActiveOptions -UrlToGo $UrlToGo;Break}
            
            GET-DHCPO            {$FormatedData = Get-DHCPOptions -UrlToGo $UrlToGo;Break}
            
            GET-DHCPOID          {$FormatedData = Get-DHCPOptionsID -UrlToGo $UrlToGo;Break}
            
            Get-DHCPSTBO         {$FormatedData = Get-DHCPSTBOptions -UrlToGo $UrlToGo;Break}
            
            Get-DHCPv6PFD        {$FormatedData = Get-DHCPv6PrefixDelegation -UrlToGo $UrlToGo;Break}

            Get-DHCPv6O          {$FormatedData = Get-DHCPv6Options -UrlToGo $UrlToGo;Break}
            
            # DNS
            GET-DNSS             {$FormatedData = Get-DNSStats -UrlToGo $UrlToGo;Break}
            
            # DEVICE
            GET-DEVICE           {$FormatedData = Get-Device -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-DEVICELOG        {$FormatedData = Get-DeviceLog -UrlToGo $UrlToGo;Break}

            GET-DEVICEFLOG       {$FormatedData = Get-DeviceFullLog -UrlToGo $UrlToGo;Break}
            
            GET-DEVICEFTLOG      {$FormatedData = Get-DeviceFullTechnicalLog -UrlToGo $UrlToGo;Break}
            
            GET-DEVICEC          {$FormatedData = Get-DeviceCpu -UrlToGo $UrlToGo;Break}
            
            GET-DEVICEM          {$FormatedData = Get-DeviceMemory -UrlToGo $UrlToGo;Break}
            
            GET-DEVICELED        {$FormatedData = Get-DeviceLED -UrlToGo $UrlToGo;Break}
            
            GET-DEVICES          {$FormatedData = Get-DeviceSummary -UrlToGo $UrlToGo;Break}
            
            GET-DEVICET          {$FormatedData = Get-DeviceToken -UrlToGo $UrlToGo;Break}
            
            SET-DEVICER          {$Token = Get-DeviceToken -UrlToGo $UrlToGo
                                  $Token = ($Token | Where-Object {$_.Description -like 'Token'}).value
                                  $UrlToGo = $UrlToGo.replace('token','reboot?btoken=')
                                  $UrlToGo = "$UrlToGo$Token"
                                  Write-log INFO -Name 'Program run - Device Reboot' -Message 'Send reboot command ...' -NotDisplay
                                  #Set-BBoxInformation -UrlToGo $UrlToGo
                                  Break
                                 }
            
            SET-DEVICEFR         {$Token = Get-DeviceToken -UrlToGo $UrlToGo
                                  $Token = ($Token | Where-Object {$_.Description -like 'Token'}).value
                                  $UrlToGo = $UrlToGo.replace('token','factory?btoken=')
                                  $UrlToGo = "$UrlToGo$Token"
                                  Write-log INFO -Name 'Program run - Device Factory Reset' -Message 'Send Factory reset command ...' -NotDisplay
                                  #Set-BBoxInformation -UrlToGo $UrlToGo
                                  Break
                                 }
            
            # DYNDNS
            GET-DYNDNS           {$FormatedData = Get-DYNDNS -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-DYNDNSPL         {$FormatedData = Get-DYNDNSProviderList -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-DYNDNSC          {$FormatedData = Get-DYNDNSClient -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-DYNDNSCID        {$FormatedData = Get-DYNDNSClientID -UrlToGo $UrlToGo;Break}

            # FIREWALL
            GET-FIREWALL         {$FormatedData = Get-FIREWALL -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-FIREWALLR        {$FormatedData = Get-FIREWALLRules -UrlToGo $UrlToGo;Break}
            
            GET-FIREWALLRID      {$FormatedData = Get-FIREWALLRulesID -UrlToGo $UrlToGo;Break}
            
            GET-FIREWALLGM       {$FormatedData = Get-FIREWALLGamerMode -UrlToGo $UrlToGo;Break}
            
            GET-FIREWALLPR       {$FormatedData = Get-FIREWALLPingResponder -UrlToGo $UrlToGo;Break}
            
            Get-FIREWALLv6R      {$FormatedData = Get-FIREWALLv6Rules -UrlToGo $UrlToGo;Break}
            
            GET-FIREWALLv6RID    {$FormatedData = Get-FIREWALLv6RulesID -UrlToGo $UrlToGo;Break}
            
            Get-FIREWALLv6L      {$FormatedData = Get-FIREWALLv6Level -UrlToGo $UrlToGo;Break}
            
            # API
            GET-APIRM            {$FormatedData = Get-APIRessourcesMap -UrlToGo $UrlToGo;Break}
            
            # HOST
            GET-HOSTS            {$FormatedData = Get-HOSTS -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-HOSTSID          {$FormatedData = Get-HOSTSID -UrlToGo $UrlToGo;Break}
            
            GET-HOSTSME          {$FormatedData = Get-HOSTSME -UrlToGo $UrlToGo;Break}
            
            Get-HOSTSL           {$FormatedData = Get-HOSTSLite -UrlToGo $UrlToGo;Break}
            
            Get-HOSTSP           {$FormatedData = Get-HOSTSPAUTH -UrlToGo $UrlToGo;Break}
            
            # LAN
            GET-LANIP            {$FormatedData = Get-LANIP -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-LANS             {$FormatedData = Get-LANStats -UrlToGo $UrlToGo;Break}
            
            GET-LANA             {$FormatedData = Get-LANAlerts -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            # NAT
            GET-NAT              {$FormatedData = Get-NAT -UrlToGo $UrlToGo;Break}
            
            GET-NATDMZ           {$FormatedData = Get-NATDMZ -UrlToGo $UrlToGo;Break}
            
            GET-NATR             {$FormatedData = Get-NATRules -UrlToGo $UrlToGo;Break}
            
            GET-NATRID           {$FormatedData = Get-NATRulesID -UrlToGo $UrlToGo;Break}
            
            # Parental Control
            GET-PARENTALCONTROL  {$FormatedData = Get-ParentalControl -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-PARENTALCONTROLS {$FormatedData = Get-ParentalControlScheduler -UrlToGo $UrlToGo;Break}
            
            GET-PARENTALCONTROLSR{$FormatedData = Get-ParentalControlSchedulerRules -UrlToGo $UrlToGo;Break}
            
            # PROFILE
            GET-PROFILEC         {$FormatedData = Get-ProfileConsumption -UrlToGo $UrlToGo;Break}
            
            # REMOTE
            GET-REMOTEPWOL       {$FormatedData = Get-REMOTEProxyWOL -UrlToGo $UrlToGo;Break}
            
            # SERVICES
            GET-SERVICES         {$FormatedData = Get-SERVICES -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-IPTV             {$FormatedData = Get-IPTV -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-IPTVD            {$FormatedData = Get-IPTVDiags -UrlToGo $UrlToGo;Break}
            
            GET-NOTIFICATION     {$FormatedData = Get-NOTIFICATIONConfig -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-NOTIFICATIONCA   {$FormatedData = Get-NOTIFICATIONConfigAlerts -UrlToGo $UrlToGo;Break}
            
            GET-NOTIFICATIONCC   {$FormatedData = Get-NOTIFICATIONConfigContacts -UrlToGo $UrlToGo;Break}
            
            GET-NOTIFICATIONCE   {$FormatedData = Get-NOTIFICATIONConfigEvents -UrlToGo $UrlToGo;Break}
            
            GET-NOTIFICATIONA    {$FormatedData = Get-NOTIFICATIONAlerts -UrlToGo $UrlToGo;Break}
            
            GET-NOTIFICATIONC    {$FormatedData = Get-NOTIFICATIONContacts -UrlToGo $UrlToGo;Break}
            
            GET-NOTIFICATIONE    {$FormatedData = Get-NOTIFICATIONEvents -UrlToGo $UrlToGo;Break}
            
            # UPNP IGD
            GET-UPNPIGD          {$FormatedData = Get-UPNPIGD -UrlToGo $UrlToGo;Break}
            
            GET-UPNPIGDR         {$FormatedData = Get-UPNPIGDRules -UrlToGo $UrlToGo;Break}
            
            # USB
            GET-DEVICEUSBP       {$FormatedData = Get-DeviceUSBPrinter -UrlToGo $UrlToGo;Break}
            
            GET-DEVICEUSBD       {$FormatedData = Get-DeviceUSBDevices -UrlToGo $UrlToGo;Break}
            
            GET-USBS             {$FormatedData = Get-USBStorage -UrlToGo $UrlToGo;Break}
            
            # VOIP
            GET-VOIP             {$FormatedData = Get-VOIP -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-VOIPD            {$FormatedData = Get-VOIPDiag -UrlToGo $UrlToGo;Break}
            
            GET-VOIPDU           {$FormatedData = Get-VOIPDiagUSB -UrlToGo $UrlToGo;Break}
            
            GET-VOIPDH           {$FormatedData = Get-VOIPDiagHost -UrlToGo $UrlToGo;Break}
            
            GET-VOIPS            {$FormatedData = Get-VOIPScheduler -UrlToGo $UrlToGo;Break}
            
            GET-VOIPSR           {$FormatedData = Get-VOIPSchedulerRules -UrlToGo $UrlToGo;Break}
            
            GET-VOIPCL           {$FormatedData = Get-VOIPCallLogLine -UrlToGo $UrlToGo;Break}
            
            GET-VOIPFCL          {$FormatedData = Get-VOIPFullCallLogLine -UrlToGo $UrlToGo;Break}
            
            GET-VOIPALN          {$FormatedData = Get-VOIPAllowedListNumber -UrlToGo $UrlToGo;Break}
            
            # CPL
            GET-CPL              {$FormatedData = Get-CPL -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-CPLDL            {$FormatedData = Get-CPLDeviceList -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            # WAN
            GET-WANA             {$FormatedData = Get-WANAutowan -UrlToGo $UrlToGo;Break}
            
            GET-WAND             {$FormatedData = Get-WANDiags -UrlToGo $UrlToGo;Break}
            
            GET-WANDS            {$FormatedData = Get-WANDiagsSessions -UrlToGo $UrlToGo;Break}

            GET-WANDSHAS         {$FormatedData = Get-WANDiagsSummaryHostsActiveSessions -UrlToGo $UrlToGo;Break}
            
            Get-WANDAAS          {$FormatedData = Get-WANDiagsAllActiveSessions -UrlToGo $UrlToGo;Break}

            Get-WANDAASH         {$FormatedData = Get-WANDiagsAllActiveSessionsHost -UrlToGo $UrlToGo;Break}
            
            GET-WANFS            {$FormatedData = Get-WANFTTHStats -UrlToGo $UrlToGo;Break}
            
            GET-WANIP            {$FormatedData = Get-WANIP -UrlToGo $UrlToGo;Break}
            
            GET-WANIPS           {$FormatedData = Get-WANIPStats -UrlToGo $UrlToGo;Break}
            
            Get-WANXDSL          {$FormatedData = Get-WANXDSL -UrlToGo $UrlToGo;Break}

            Get-WANXDSLS         {$FormatedData = Get-WANXDSLStats -UrlToGo $UrlToGo;Break}

            Get-WANSFF           {$FormatedData = Get-WANSFF -UrlToGo $UrlToGo;Break}
            
            # WIRELESS
            Get-WIRELESS         {$FormatedData = Get-WIRELESS -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-WIRELESS24       {$FormatedData = Get-WIRELESS24Ghz -UrlToGo $UrlToGo;Break}
            
            GET-WIRELESS24S      {$FormatedData = Get-WIRELESSStats -UrlToGo $UrlToGo;Break}
            
            GET-WIRELESS5        {$FormatedData = Get-WIRELESS5Ghz -UrlToGo $UrlToGo;Break}
            
            GET-WIRELESS5S       {$FormatedData = Get-WIRELESSStats -UrlToGo $UrlToGo;Break}
            
            GET-WIRELESSACL      {$FormatedData = Get-WIRELESSACL -UrlToGo $UrlToGo;Break}
            
            GET-WIRELESSACLR     {$FormatedData = Get-WIRELESSACLRules -UrlToGo $UrlToGo;Break}
            
            GET-WIRELESSACLRID   {$FormatedData = Get-WIRELESSACLRulesID -UrlToGo $UrlToGo;Break}
            
            GET-WIRELESSWPS      {$FormatedData = GET-WIRELESSWPS -UrlToGo $UrlToGo;Break}
            
            GET-WIRELESSFBNH     {$FormatedData = Get-WIRELESSFrequencyNeighborhoodScan -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            GET-WIRELESSFSM      {$FormatedData = Get-WIRELESSFastScanMe -UrlToGo $UrlToGo;Break}
            
            GET-WIRELESSS        {$FormatedData = Get-WIRELESSScheduler -UrlToGo $UrlToGo;Break}
            
            GET-WIRELESSSR       {$FormatedData = Get-WIRELESSSchedulerRules -UrlToGo $UrlToGo;Break}
            
            Get-WIRELESSR        {$FormatedData = Get-WIRELESSRepeater -UrlToGo $UrlToGo;Break}
            
            Get-WIRELESSVBSTB    {$FormatedData = Get-WIRELESSVideoBridgeSetTopBoxes -UrlToGo $UrlToGo;Break}
            
            Get-WIRELESSVBR      {$FormatedData = Get-WIRELESSVideoBridgeRepeaters -UrlToGo $UrlToGo;Break}
            
            # SUMMARY
            Get-SUMMARY          {$FormatedData = Get-SUMMARY -UrlToGo $UrlToGo;Break}
            
            # USERSAVE
            Get-USERSAVE         {$FormatedData = Get-USERSAVE -UrlToGo $UrlToGo -APIName $APIName;Break}
            
            # PasswordRecoveryVerify
            GET-PASSRECOVERV     {$FormatedData = Get-PasswordRecoveryVerify -UrlToGo $UrlToGo;Break}
            
            # BBOXJournal
            Get-BBoxJournal      {$FormatedData = Get-BBoxJournal -UrlToGo $UrlToGo -JournalPath $JournalPath;Break}
            
            # Remove-FolderContent
            Remove-FCLogs        {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            Remove-FCExportCSV   {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            Remove-FCExportJSON  {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            Remove-FCJournal     {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            Remove-FCJBC         {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            Remove-FCReport      {$FormatedData = Remove-FolderContent -FolderRoot $PSScriptRoot -FolderName $APIName;Break}
            
            # DisplayFormat
            Switch-DF            {$FormatedData = Switch-DisplayFormat;Break}
            
            # ExportFormat
            Switch-EF            {$FormatedData = Switch-ExportFormat;Break}
            
            # OpenExportFormat
            SWITCH-OEF           {$FormatedData = Switch-OpenExportFolder;Break}
            
            # OpenHTMLReport
            Switch-OHR           {$FormatedData = Switch-OpenHTMLReport;Break}
            
            # RemoveBBoxWindowsPasswordManager
            Remove-BBoxC         {$FormatedData = Remove-BBoxCredential;Break}
            
            # ShowBBoxWindowsPasswordManager
            Show-BBoxC           {$FormatedData = Show-BBoxCredential;Break}
            
            # SetBBoxWindowsPasswordManager
            Add-BBoxC            {$FormatedData = Add-BBoxCredential;Break}
            
            # Reset-CurrentUserProgrammConfiguration
            Reset-CUPC           {$FormatedData = Reset-CurrentUserProgrammConfiguration;Break}
            
            # Exit
            Q                    {Stop-Program;Break}
            
            # Quit/Close Program
            Stop-Program         {Stop-Program;Break}
            
            # Default
            Default              {Write-log WARNING -Name 'Program run - Action not yet developed' -Message "Selected Action is not yet developed, please chose another one, for more information contact me by mail : $Mail or post on github : $GitHubUrlSite"
                                  Show-WindowsFormDialogBox -Title 'Program run - Action not yet developed' -Message "Selected Action is not yet developed, please chose another one, for more information contact me by mail : $Mail or post on github : $GitHubUrlSite" -WarnIcon
                                  $FormatedData = 'Program'
                                  Break
                                 }
        }
    
        Return $FormatedData
}

# Used only to quit the Program
Function Stop-Program {
    
    Param ()
    
    $null = Show-WindowsFormDialogBox -Title 'Stop Program' -Message "Program exiting ... `nPlease dont close windows manually !`nWe are closing background processes before quit the program`nPlease wait ..." -WarnIcon
    Write-Log -Type WARNING -Name 'Stop Program' -Message "Program exiting ... `nPlease dont close windows manually !`nWe are closing background processes before quit the program`nPlease wait ..."
    
    If ($Null -ne $global:ChromeDriver) {
        
        Write-Log -Type INFO -Name 'Stop Chrome Driver' -Message 'Start Stop Chrome Driver' -NotDisplay
        Stop-ChromeDriver
        Write-Log -Type INFO -Name 'Stop Chrome Driver' -Message 'End Stop Chrome Driver' -NotDisplay

        Write-Log -Type INFO -Name 'Stop Google Chrome' -Message 'Start Stop Google Chrome' -NotDisplay
        $Global:ActiveChromeAfter = Get-Process Chrome -ErrorAction SilentlyContinue | ForEach-Object {$_.Id} | Where-Object {$Global:ActiveChromeBefore -notcontains $_} -ErrorAction SilentlyContinue
        
        If ($null -ne $Global:ActiveChromeAfter) {
            
            Stop-Process -Id $Global:ActiveChromeAfter -Force -ErrorAction SilentlyContinue
        }
        Write-Log -Type INFO -Name 'Stop Google Chrome ' -Message 'End Stop Google Chrome' -NotDisplay
    }
    
    Start-Sleep 2
    $Current_Log_File = "$global:LogFolderPath\" + (Get-ChildItem -Path $global:LogFolderPath -Name "$global:LogFileName*" | Select-Object PSChildName | Sort-Object PSChildName -Descending)[0].PSChildName
    Write-Log -Type INFONO -Name 'Stop Program' -Message 'Log file is available here : '
    Write-Log -Type VALUE -Name 'Stop Program' -Message $Current_Log_File
    Write-Log -Type INFO -Name 'Stop Program' -Message 'Program Closed' -NotDisplay 
    
    $global:TriggerExit = 1
    Stop-Transcript -ErrorAction Stop
    Exit
}

#region ChromeDriver 

# Used only to Start ChromeDriver
Function Start-ChromeDriver {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$ChromeDriverVersion,
        
        [Parameter(Mandatory=$False)]
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
    #$Temp = $($ChromeBinaryPath.Replace("\$($ChromeBinaryPath.Split("\")[-1])",''))
    #$env:PATH += ";$Temp"

    # Adding Selenium's .NET assembly (dll) to access it's classes in this PowerShell session
    Add-Type -Path "$ChromeDriverPath\$ChromeDriverVersion\$($global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultWebDriverDLLFileName)"
    
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

# Used only to stop ChromeDriver, linked to : "Stop-Program"
Function Stop-ChromeDriver {
    
    Param ()
    
    # Close all ChromeDriver instances openned
    $global:ChromeDriver.Close()
    $global:ChromeDriver.Dispose()
    $global:ChromeDriver.Quit()
    Get-Process -Name chromedriver -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
}

# Used only to update ChromeDriver version
Function Update-ChromeDriver {
    
    Param (
        
        [Parameter(Mandatory=$True)]
        [String]$ChromeDriverVersion,

        [Parameter(Mandatory=$True)]
        [String]$ChromeDriverPath
    ) 
    
    Try {
        # Set Varibales
        $ChromeDriverDownloadHomeUrl = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDownloadHomeUrl
        $ChromeDriverDownloadPathUrl = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDownloadPathUrl
        $ChromeDriverVersionShort = $($ChromeDriverVersion -split ".")[0]
        
        $FileName = $global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDownloadFileName
        $UserDownloadFolderDefault = Get-ItemPropertyValue -Path $global:JSONSettingsProgramContent.Path.DownloadShellRegistryFolder -Name $global:JSONSettingsProgramContent.Path.DownloadShellRegistryFolderName
        $SourceFile = "$UserDownloadFolderDefault\$FileName"
        
        # Navigate to the main Chrome Driver Page
        Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message "Access to download Page : $ChromeDriverDownloadHomeUrl" -NotDisplay
        $global:ChromeDriver.Navigate().GoToURL("$ChromeDriverDownloadHomeUrl")
        Start-Sleep -Seconds 1
        
        # Get Content Page
        Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message 'Get HTML code page' -NotDisplay
        $Html = $global:ChromeDriver.PageSource
        Start-Sleep -Seconds 1
        
        # Convert-html to text
        Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message 'Convert HTML code to txt' -NotDisplay
        $Plaintxt = ConvertFrom-HtmlToText -Html $Html
        Start-Sleep -Seconds 1
        
        # Get Chrome Driver Version list available
        Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message 'Get last Chrome driver version available with Google Chrome installed version' -NotDisplay
        $Temp = $Plaintxt -split '---'
        $Version = $($Temp | Where-Object {$_ -notmatch 'Index of /NameLast modifiedSizeETag2.0' -and $_ -notmatch 'icons' -and $_ -notmatch 'LATEST_RELEASE' -and $_ -match "$ChromeDriverVersionShort"})[-1]
        $url = "$ChromeDriverDownloadPathUrl$Version/"
        $DestinationPath = "$ChromeDriverPath\$Version"
        
        If ((Test-Path -Path $DestinationPath) -eq $false) {

            # Navigate to Chrome Driver Version choosen
            Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message "Access to download Page for version : $url" -NotDisplay
            $global:ChromeDriver.Navigate().GoToURL($url)
            Start-Sleep -Seconds 2
            
            # Start setup file downloading
            Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message "Start to download chrome Driver version : $Version" -NotDisplay
            $global:ChromeDriver.FindElementByLinkText($FileName).click()
            Start-Sleep -Seconds 15

            # Create new directory to use chrome Driver update
            Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message "Create chrome Driver repository for version : $Version" -NotDisplay
            $null = New-Item -Path $ChromeDriverPath -Name $Version -ItemType Directory -ErrorAction Stop
            Start-Sleep -Seconds 1
            
            # Unzip new Chrome driver version to destination
            Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message "Unzip archive to chrome Driver repository for version : $Version" -NotDisplay
            Expand-Archive -Path $SourceFile -DestinationPath $DestinationPath -Force -ErrorAction Stop -WarningAction Stop
            Start-Sleep -Seconds 5

            # Copy DLL System
            Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message "Copy DLLs to : $DestinationPath" -NotDisplay
            Copy-Item -Path "$ChromeDriverPath\Default\$($global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultWebDriverDLLFileName)" -Destination $DestinationPath -Force
            Copy-Item -Path "$ChromeDriverPath\Default\$($global:JSONSettingsProgramContent.GoogleChrome.ChromeDriverDefaultWebDriverSupportFileName)" -Destination $DestinationPath -Force

            # Remove the downloaded source
            Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message "Remove source file : $SourceFile" -NotDisplay
            Remove-Item -Path $SourceFile -Force -ErrorAction Stop
        }
        
        # Stop chrome Driver
        Write-Log -Type INFO -Name 'Program initialisation - Update ChromeDriver' -Message 'Stop Chrome Driver' -NotDisplay
        Stop-ChromeDriver -ErrorAction Stop
        Write-Log -Type VALUE -Name 'Program initialisation - Update ChromeDriver' -Message 'Updated' -NotDisplay
        $global:ChromeDriver = $null
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Update ChromeDriver' -Message "Update failed, due to : $($_.ToString())" -NotDisplay
        $global:TriggerExit = 1
    }
}

#endregion ChromeDriver

# Used only to Refresh WIRELESS Frequency Neighborhood Scan, linked to : "Format-Date1970"
function Start-RefreshWIRELESSFrequencyNeighborhoodScan {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    Write-Log -Type INFO -Name 'Program run - WIRELESS Frequency Neighborhood scan' -Message 'Start WIRELESS Frequency Neighborhood scan' -NotDisplay
    
    # Get information from BBOX API and last scan date
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    $Lastscan = $Json.lastscan
    
    Write-Log -Type INFONO -Name 'Program run - WIRELESS Frequency Neighborhood scan' -Message 'WIRELESS Frequency Neighborhood Lastscan : ' -NotDisplay
    
    If ($Lastscan -eq 0) {
        
        Write-Log -Type VALUE -Name 'Program run - WIRELESS Frequency Neighborhood scan' -Message 'Never' -NotDisplay
    }
    Else {
        Write-Log -Type VALUE -Name 'Program run - WIRELESS Frequency Neighborhood scan' -Message $(Format-Date1970 -Seconds $Lastscan) -NotDisplay
    }
    
    $global:ChromeDriver.Navigate().GoToURL($($UrlToGo.replace("api/v1/$APIName",'diagnostic.html')))
    Start-Sleep -Seconds 1
    
    Switch ($APIName) {
        
        wireless/24/neighborhood {($global:ChromeDriver.FindElementsByClassName('scan24') | Where-Object -Property text -eq 'Scanner').click();Break}
            
        wireless/5/neighborhood  {($global:ChromeDriver.FindElementsByClassName('scan5') | Where-Object -Property text -eq 'Scanner').click();Break}
    }
    
    Write-Log -Type WARNING -Name 'Program run - WIRELESS Frequency Neighborhood scan' -Message 'Be careful, the scan can temporary suspend your Wi-Fi network'
    Write-Log -Type WARNING -Name 'Program run - WIRELESS Frequency Neighborhood scan' -Message 'Do you want to continue ? : ' -NotDisplay
    
    While ($ActionState -notmatch "Y|N") {
            
        #$ActionState = Read-Host "Do you want to continue ? (Y) Yes / (N) No"
        $ActionState = Show-WindowsFormDialogBox -Title 'Program run - WIRELESS Frequency Neighborhood scan' -Message 'Do you want to continue ? (Y) Yes / (N) No' -YesNo
        Write-Log -Type INFO -Name 'Program run - WIRELESS Frequency Neighborhood scan' -Message "Action chosen by user : $ActionState" -NotDisplay
    }

    If ($ActionState[0] -eq 'Y') {
        
        # addd
        Try {
            ($global:ChromeDriver.FindElementsByClassName('cta-1') | Where-Object -Property text -eq 'Rafraîchir').click()
            ($global:ChromeDriver.FindElementsByClassName('cta-2') | Where-Object -Property text -eq 'OK').click()
        }
        Catch {
            ($global:ChromeDriver.FindElementsByClassName("cta-2") | Where-Object -Property text -eq 'OK').click()
        }
        
        Write-Log -Type INFONO -Name 'Program run - WIRELESS Frequency Neighborhood scan' -Message 'Refresh WIRELESS Frequency Neighborhood scan : ' -NotDisplay
        Start-Sleep -Seconds 20
        Write-Log -Type VALUE -Name 'Program run - WIRELESS Frequency Neighborhood scan' -Message 'Ended' -NotDisplay
    }
    Write-Log -Type INFO -Name 'Program run - WIRELESS Frequency Neighborhood scan' -Message 'End WIRELESS Frequency Neighborhood scan' -NotDisplay
}

# Used only to Refresh WIRELESS Frequency Neighborhood Scan ID and linked to : "Start-RefreshWIRELESSFrequencyNeighborhoodScan" and "Get-WIRELESSFrequencyNeighborhoodScanID"
Function Get-WIRELESSFrequencyNeighborhoodScan {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName
    )
    
    Start-RefreshWIRELESSFrequencyNeighborhoodScan -APIName $APIName -UrlToGo $UrlToGo
    $FormatedData = @()
    $FormatedData = Get-WIRELESSFrequencyNeighborhoodScanID -UrlToGo $UrlToGo
    
    Return $FormatedData
}

#endregion GLOBAL

#region Json file configuration management

Function Get-JSONSettingsCurrentUserContent {

    Param(

    )

    Write-Log -Type INFO -Name 'Program initialisation - Json Current User Settings Importation' -Message 'Start Json Current User Settings Importation' -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Json Current User Settings Importation' -Message 'Json Current User Settings Importation Status : ' -NotDisplay
    Try {
        $global:JSONSettingsCurrentUserContent = Get-Content -Path $global:JSONSettingsCurrentUserFilePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $global:DisplayFormat           = $global:JSONSettingsCurrentUserContent.DisplayFormat.DisplayFormat
        $global:ExportFormat            = $global:JSONSettingsCurrentUserContent.ExportFormat.ExportFormat
        $global:OpenExportFolder        = $global:JSONSettingsCurrentUserContent.OpenExportFolder.OpenExportFolder
        $global:OpenHTMLReport          = $global:JSONSettingsCurrentUserContent.OpenHTMLReport.OpenHTMLReport
        $global:TriggerExportFormat     = $global:JSONSettingsCurrentUserContent.Trigger.ExportFormat
        $global:TriggerDisplayFormat    = $global:JSONSettingsCurrentUserContent.Trigger.DisplayFormat
        $global:TriggerOpenHTMLReport   = $global:JSONSettingsCurrentUserContent.Trigger.OpenHTMLReport
        $global:TriggerOpenExportFolder = $global:JSONSettingsCurrentUserContent.Trigger.OpenExportFolder
        $global:Target                  = $global:JSONSettingsCurrentUserContent.Credentials.Target
        $global:UserName                = $global:JSONSettingsCurrentUserContent.Credentials.UserName
        $global:Comment                 = $global:JSONSettingsCurrentUserContent.Credentials.Comment
        
        Write-Log -Type VALUE -Name 'Program initialisation - Json Current User Settings Importation' -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Json Current User Settings Importation' -Message "Failed, due to : $($_.ToString())"
        Stop-Program -ErrorAction Stop
    }
    Write-Log -Type INFO -Name 'Program initialisation - Json Current User Settings Importation' -Message 'End Json Current User Settings Importation' -NotDisplay
}

Function Get-JSONSettingsDefaultUserContent {

    Param(

    )

    Write-Log -Type INFO -Name 'Program initialisation - Json Default User Settings Importation' -Message 'Start Json Default User Settings Importation' -NotDisplay
    Write-Log -Type INFONO -Name 'Program initialisation - Json Default User Settings Importation' -Message 'Json Default User Settings Importation Status : '
    Try {
        $global:JSONSettingsDefaultUserContent = Get-Content -Path $global:JSONSettingsDefaultUserFilePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $global:DisplayFormat           = $global:JSONSettingsDefaultUserContent.DisplayFormat.DisplayFormat
        $global:ExportFormat            = $global:JSONSettingsDefaultUserContent.ExportFormat.ExportFormat
        $global:OpenExportFolder        = $global:JSONSettingsDefaultUserContent.OpenExportFolder.OpenExportFolder
        $global:OpenHTMLReport          = $global:JSONSettingsDefaultUserContent.OpenHTMLReport.OpenHTMLReport
        $global:TriggerExportFormat     = $global:JSONSettingsDefaultUserContent.Trigger.ExportFormat
        $global:TriggerDisplayFormat    = $global:JSONSettingsDefaultUserContent.Trigger.DisplayFormat
        $global:TriggerOpenHTMLReport   = $global:JSONSettingsDefaultUserContent.Trigger.OpenHTMLReport
        $global:TriggerOpenExportFolder = $global:JSONSettingsDefaultUserContent.Trigger.OpenExportFolder
        $global:Target                  = $global:JSONSettingsDefaultUserContent.Credentials.Target
        $global:UserName                = $global:JSONSettingsDefaultUserContent.Credentials.UserName
        $global:Comment                 = $global:JSONSettingsDefaultUserContent.Credentials.Comment
        
        Write-Log -Type VALUE -Name 'Program initialisation - Json Default User Settings Importation' -Message 'Success'
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program initialisation - Json Default User Settings Importation' -Message "Failed, due to : $($_.ToString())"
        Stop-Program -ErrorAction Stop
    }
    Write-Log -Type INFO -Name 'Program initialisation - Json Default User Settings Importation' -Message 'End Json Default User Settings Importation' -NotDisplay
}

#endregion Json file configuration management

#region Reset User Json Configuration files
Function Reset-CurrentUserProgrammConfiguration {

    Param(

    )
    
    Write-Log -Type INFO -Name 'Program - Reset Json Current User Settings' -Message 'Start Reset Json Current User Settings' -NotDisplay
    Write-Log -Type INFONO -Name 'Program - Reset Json Current User Settings' -Message 'Reset Json Current User Settings Status : ' -NotDisplay
    Try {
        Copy-Item -Path $global:JSONSettingsDefaultUserFilePath -Destination $global:JSONSettingsCurrentUserFilePath -Force
        Start-Sleep -Seconds 2
        Write-Log -Type VALUE -Name 'Program - Reset Json Current User Settings' -Message 'Success' -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program - Reset Json Current User Settings' -Message "Failed, to Reset Json Current User Settings file, due to : $($_.ToString())"
        Stop-Program -ErrorAction Stop
    }
    Write-Log -Type INFO -Name 'Program - Reset Json Current User Settings' -Message 'End Reset Json Current User Settings' -NotDisplay

    If (Test-Path -Path $global:JSONSettingsCurrentUserFilePath) {

        Get-JSONSettingsCurrentUserContent
    }
    Elseif (Test-Path -Path $global:JSONSettingsDefaultUserFilePath) {
        
        Get-JSONSettingsDefaultUserContent
    }
    Else {
        Write-Log -Type WARNING -Name 'Program - Json Current User Settings Importation' -Message "Failed, to find find any user settings configuration file, due to : $($_.ToString())"
        Write-Log -Type INFO -Name 'Program - Json Current User Settings Importation' -Message 'End Json Current User Settings Importation' -NotDisplay
        Stop-Program -ErrorAction Stop
    }
}
#endregion Reset User Json Configuration files

#region Manage Output Display after data export

# Used only to change Open Export Folder, linked to : "Switch-Info" and "Export-toCSV" and "Export-toJSON" and "Export-BboxConfiguration" and "Export-BBoxConfigTestingProgram"
Function Switch-OpenExportFolder {

    # Choose Open Export Folder : Y (Yes) or N (No)
    Write-Log -Type INFO -Name 'Program run - Choose Open Export Folder' -Message 'Start switch Open Export Folder' -NotDisplay
    Write-Log -Type INFO -Name 'Program run - Choose Open Export Folder' -Message "Please choose if you want to open 'Export' folder (Can be changed later) : Y (Yes) or N (No)" -NotDisplay
    $global:OpenExportFolder = $global:JSONSettingsCurrentUserContent.OpenExportFolder.OpenExportFolder
    
    While ($global:OpenExportFolder[0] -notmatch $global:JSONSettingsProgramContent.Values.OpenExportFolder) {
            
        #$Temp = Read-Host "Enter your choice"
        $Temp = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Choose Open Export Folder' -LabelMessageText "Please choose if you want to open 'Export' folder (Can be changed later) :`n- (Y) Yes`n- (N) No" -FirstOptionButtonText 'Y' -SecondOptionButtonText 'N'
        
        Switch ($Temp) {
                
            Y    {$global:OpenExportFolder = 'Y';Break}
            N    {$global:OpenExportFolder = 'N';Break}
        }
    }
    
    $global:JSONSettingsCurrentUserContent.OpenExportFolder.OpenExportFolder = $global:OpenExportFolder
    $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
    Write-Log -Type VALUE -Name 'Program run - Choose Open Export Folder' -Message "Value Choosen : $global:OpenExportFolder" -NotDisplay
    Write-Log -Type INFO -Name 'Program run - Choose Open Export Folder' -Message 'End switch Open Export Folder' -NotDisplay
    Return 'Program'
}

# Used only to change Display Format, linked to : "Export-GlobalOutputData"
Function Switch-DisplayFormat {
    
    # Choose Display Format : HTML or Table
    Write-Log -Type INFO -Name 'Program run - Choose Display Format' -Message 'Start data display format' -NotDisplay
    Write-Log -Type INFO -Name 'Program run - Choose Display Format' -Message "Please choose a display format (Can be changed later) : (H) HTML or (T) Table/Gridview" -NotDisplay
    $global:DisplayFormat = ''
    
    While ($global:DisplayFormat[0] -notmatch $global:JSONSettingsProgramContent.Values.DisplayFormat) {
        
        #$Temp = Read-Host "Enter your choice"
        $Temp = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Choose Display Format' -LabelMessageText "Please choose a display format (Can be changed later) :`n- (H) HTML`n- (T) Table/Gridview" -FirstOptionButtonText 'H' -SecondOptionButtonText 'T'
        
        Switch ($Temp) {
                
            H    {$global:DisplayFormat = 'H';Break}
            T    {$global:DisplayFormat = 'T';Break}
        }
    }
    
    $global:JSONSettingsCurrentUserContent.DisplayFormat.DisplayFormat = $global:DisplayFormat
    $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
    Write-Log -Type VALUE -Name 'Program run - Choose Display Format' -Message "Value Choosen : $global:DisplayFormat" -NotDisplay
    Write-Log -Type INFO -Name 'Program run - Choose Display Format' -Message 'End data display format' -NotDisplay
    Return 'Program'
}

# Used only to format display result function user choice, linked to : "Export-GlobalOutputData" and "Export-HTMLReport" and "Out-GridviewDisplay" and "Open-HTMLReport"
Function Format-DisplayResult {
    
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
             Export-HTMLReport -DataReported $FormatedData -ReportTitle "BBOX Configuration Report - $APIName" -ReportType $ReportType -ReportPath $ReportPath -ReportFileName $Exportfile -HTMLTitle 'BBOX Configuration Report' -ReportPrecontent $APIName -Description $Description
             Break
            }
        
        'T' {# Display result by Out-Gridview
             Out-GridviewDisplay -FormatedData $FormatedData -APIName $APIName -Description $Description
             Break
            }
    }
    Write-Log -Type INFO -Name 'Program run - Display Result' -Message 'End display result' -NotDisplay
}

# Used only to export result to CSV File, linked to : "Format-ExportResult"
Function Export-toCSV {
    
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
    
    Write-Log -Type INFO -Name 'Program run - Export Result CSV' -Message 'Start export result as CSV' -NotDisplay
    
    Try {
        # Define Export file path
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $ExportPath = "$ExportCSVPath\$Date-$Exportfile.csv"
        $FormatedData | Export-Csv -Path $ExportPath -Encoding UTF8 -Delimiter ";" -NoTypeInformation -Force        
        Write-Log -Type INFONO -Name 'Program run - Export Result CSV' -Message 'CSV Data have been exported to : ' -NotDisplay
        Write-Log -Type VALUE -Name 'Program run - Export Result CSV' -Message $ExportPath -NotDisplay
        
        If ($global:TriggerOpenExportFolder -eq 0) {
            
            $global:TriggerOpenExportFolder = Switch-OpenExportFolder
            $global:JSONSettingsCurrentUserContent.Trigger.OpenExportFolder = $global:TriggerOpenExportFolder
            $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
        }

        If ($global:OpenExportFolder -eq 'Y') {
            Write-Log -Type INFO -Name 'Program run - Export Result CSV' -Message "Open folder : $ExportCSVPath"
            Invoke-Item -Path $ExportCSVPath
        }
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program run - Export Result CSV' -Message "Failed, to export data to : `"$ExportPath`", due to : $($_.ToString())"
    }
    
    Write-Log -Type INFO -Name 'Program run - Export Result CSV' -Message 'End export result as CSV' -NotDisplay
}

# Used only to export result to JSON File, linked to : "Format-ExportResult"
Function Export-toJSON {
    
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
    
     Write-Log -Type INFO -Name 'Program run - Export Result JSON' -Message 'Start export result as JSON' -NotDisplay
     
     Try {
        # Define Export file path
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $FullPath = "$ExportJSONPath\$Date-$Exportfile.json"
        $FormatedData | ConvertTo-Json -depth 10 | Out-File -FilePath $FullPath -Force
        Write-Log -Type INFONO -Name 'Program run - Export Result JSON' -Message 'JSON Data have been exported to : ' -NotDisplay
        Write-Log -Type VALUE -Name 'Program run - Export Result JSON' -Message $FullPath -NotDisplay
        
        If ($global:TriggerOpenExportFolder -eq 0) {
        
            $global:TriggerOpenExportFolder = Switch-OpenExportFolder
            $global:JSONSettingsCurrentUserContent.Trigger.OpenExportFolder = $global:TriggerOpenExportFolder
            $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
        }
        
        If ($global:OpenExportFolder -eq 'Y') {
            Write-Log -Type INFO -Name 'Program run - Export Result JSON' -Message "Open folder : $ExportJSONPath"
            Invoke-Item -Path $ExportJSONPath
        }
    }
    Catch {
        Write-Log -Type ERROR -Name 'Program run - Export Result JSON' -Message "Failed to export data to : `"$FullPath`", due to : $($_.ToString())"
    }
    
    Write-Log -Type INFO -Name 'Program run - Export Result JSON' -Message 'End export result as JSON' -NotDisplay
}

# Used only to change Export Format, linked to : "Export-GlobalOutputData"
Function Switch-ExportFormat {
    
    # Choose Export Format : CSV or JSON
    Write-Log -Type INFO -Name 'Program run - Choose Export Result' -Message 'Start data export format' -NotDisplay
    Write-Log -Type INFO -Name 'Program run - Choose Export Result' -Message 'Please choose an export format (Can be changed later) : (C) CSV or (J) JSON' -NotDisplay
    $global:ExportFormat = ''

    While ($global:ExportFormat[0] -notmatch $global:JSONSettingsProgramContent.Values.ExportFormat) {
        
        #$Temp = Read-Host "Enter your choice"
        $Temp = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Choose Export Result' -LabelMessageText "Please choose an export format (Can be changed later) :`n- (C) CSV`n- (J) JSON" -FirstOptionButtonText 'C' -SecondOptionButtonText 'J'
            
        Switch ($Temp) {
            
            C    {$global:ExportFormat = 'C';Break}
            J    {$global:ExportFormat = 'J';Break}
        }
    }
    
    $global:JSONSettingsCurrentUserContent.ExportFormat.ExportFormat = $global:ExportFormat
    $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
    Write-Log -Type INFO -Name 'Program run - Choose Export Result' -Message "Value Choosen  : $global:ExportFormat" -NotDisplay
    Write-Log -Type INFO -Name 'Program run - Choose Export Result' -Message 'End data export format' -NotDisplay
    Return 'Program'
}

# Used only to format export result function user choice, linked to : "Export-GlobalOutputData" and "Export-toCSV" and "Export-toJSON"
Function Format-ExportResult {
    
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

# Used only to open or not HTML Report, linked to : "Export-HTMLReport" and "Open-HTMLReport"
Function Switch-OpenHTMLReport {
    
    Write-Log -Type INFO -Name 'Program run - Switch Open HTML Report' -Message 'Start Switch Open HTML Report' -NotDisplay
    Write-Log -Type INFO -Name 'Program run - Switch Open HTML Report' -Message 'Do you want to open HTML Report at each time ? : (Y) Yes or (N) No' -NotDisplay
    $global:OpenHTMLReport = ''
    
    While ($global:OpenHTMLReport[0] -notmatch $global:JSONSettingsProgramContent.Values.OpenHTMLReport) {
        
        $Temp = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Switch Open HTML Report' -LabelMessageText "Do you want to open HTML Report at each time ? :`n- (Y) Yes`n- (N) No" -FirstOptionButtonText 'Y' -SecondOptionButtonText 'N'        
        
        Switch ($Temp) {
                
            Y    {$global:OpenHTMLReport = 'Y';Break}
            N    {$global:OpenHTMLReport = 'N';Break}
        }
    }
    
    $global:JSONSettingsCurrentUserContent.OpenHTMLReport.OpenHTMLReport = $global:OpenHTMLReport
    $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
    Write-Log -Type INFO -Name 'Program run - Switch Open HTML Report' -Message "Value Choosen : $global:OpenHTMLReport" -NotDisplay
    Write-Log -Type INFO -Name 'Program run - Switch Open HTML Report' -Message 'End Switch Open HTML Report' -NotDisplay
    Return 'Program'
}

# Used only to open HTML Report, linked to : "Export-HTMLReport"
Function Open-HTMLReport {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$Path
    )
    
    Write-Log -Type INFO -Name "Program run - Open HTML Report" -Message "Start Open HTML Report" -NotDisplay
    Write-Log -Type INFONO -Name "Program run - Open HTML Report" -Message "Open HTML Report Status : " -NotDisplay
    
    If ($global:OpenHTMLReport -eq "Y") {
        
        Try {
            Invoke-Item -Path $Path
            Write-Log -Type VALUE -Name "Program run - Open HTML Report" -Message 'Success' -NotDisplay
        }
        Catch {
            Write-Log -Type WARNING -Name "Program run - Open HTML Report" -Message "Failed to open HTML report : $Path, due to $($_.tostring())" -NotDisplay
        }
    }
    Else {
        Write-Log -Type VALUE -Name "Program run - Open HTML Report" -Message "User don't want to open HTML report" -NotDisplay
    }
    
    Write-Log -Type INFO -Name "Program run - Open HTML Report" -Message "End Open HTML Report" -NotDisplay
}

# Used only to create HTML Report, linked to : "Format-DisplayResult" and "Switch-OpenHTMLReport" and "Open-HTMLReport"
Function Export-HTMLReport {
    
    Param (
        [Parameter(Mandatory=$True)]
        [Array]$DataReported,
        
        [Parameter(Mandatory=$True)]
        [ValidateSet('List','Table')]
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
    
    Switch ($ReportPrecontent) {
        
        'lan/ip'    {$LANIP     = $DataReported[0] | ConvertTo-Html -As List -PreContent "<h2> LAN Configuration </h2><br/>"
                     $LANSwitch = $DataReported[1] | ConvertTo-Html -As Table -PreContent "<h2> LAN Switch Configuration </h2><br/>"
                     $HTML      = ConvertTo-HTML -Body "$Title $PreContent $LANIP $LANSwitch" -Title $ReportTitle -Head $header -PostContent "<br/>$ReportAuthor"
                     Break
                    }
        
        'wan/diags' {$DNS  = $DataReported.DNS  | ConvertTo-Html -As Table -PreContent "<h2> WAN DNS Statistics </h2>"
                     $HTTP = $DataReported.HTTP | ConvertTo-Html -As Table -PreContent "<h2> WAN HTTP Statistics </h2>"
                     $PING = $DataReported.PING | ConvertTo-Html -As Table -PreContent "<h2> WAN PING Statistics </h2>"
                     $HTML = ConvertTo-HTML -Body "$Title $PreContent $DNS $HTTP $PING" -Title $ReportTitle -Head $header -PostContent "<br/>$ReportAuthor"
                     Break
                    }
        
        'wan/autowan'{$Config          = $DataReported[0] | ConvertTo-Html -As Table -PreContent "<h2> Auto WAN Configuration </h2>"
                     $Profiles         = $DataReported[1] | ConvertTo-Html -As Table -PreContent "<h2> WAN Profiles</h2>"
                     $ProfilesDetailed = $DataReported[2] | ConvertTo-Html -As Table -PreContent "<h2> WAN Profiles Détailled </h2>"
                     $Services         = $DataReported[3] | ConvertTo-Html -As Table -PreContent "<h2> WAN PING Statistics </h2>"
                     $HTML             = ConvertTo-HTML -Body "$Title $PreContent $Config $Services $Profiles $ProfilesDetailed" -Title $ReportTitle -Head $header -PostContent "<br/>$ReportAuthor"
                     Break
                    }
        
        Default     {$HTML = ConvertTo-Html -Body "$Title $PreContent $($DataReported | ConvertTo-Html -As $ReportType)" -Title $ReportTitle -Head $header -PostContent "<br/>$ReportAuthor"
                     Break
                    }
    }
    
    $FullReportPath = "$ReportPath\$Date-$ReportFileName.html"
    
    Write-Log -Type INFO -Name 'Program run - Export HTML Report' -Message 'Start export HTML report' -NotDisplay
    Write-Log -Type INFONO -Name 'Program run - Export HTML Report' -Message 'Export HTML report status : ' -NotDisplay
    
    Try {
        $HTML | Out-File -FilePath $FullReportPath -Force -Encoding utf8
        Write-Log -Type VALUE -Name 'Program run - Export HTML Report' -Message 'Success' -NotDisplay
        Write-Log -Type INFONO -Name 'Program run - Export HTML Report' -Message 'HTML Report has been exported to : ' -NotDisplay
        Write-Log -Type VALUE -Name 'Program run - Export HTML Report' -Message $FullReportPath -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program run - Export HTML Report' -Message "Failed, to export HTML report : `"$FullReportPath`", due to $($_.tostring())" -NotDisplay
    }
    
    Write-Log -Type INFO -Name 'Program run - Export HTML Report' -Message 'End export HTML report' -NotDisplay
    
    If ($global:TriggerOpenHTMLReport -eq 0) {
        
        $global:TriggerOpenHTMLReport = Switch-OpenHTMLReport
        $global:JSONSettingsCurrentUserContent.Trigger.OpenHTMLReport = $global:TriggerOpenHTMLReport
        $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath  $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
    }

    Open-HTMLReport -Path $FullReportPath

    If ($global:TriggerOpenExportFolder -eq 0) {
        
        $global:TriggerOpenExportFolder = Switch-OpenExportFolder
        $global:JSONSettingsCurrentUserContent.Trigger.OpenExportFolder = $global:TriggerOpenExportFolder
        $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
    }
    
    If ($global:OpenExportFolder -eq 'Y') {
        Write-Log -Type INFO -Name 'Program run - Export Result CSV' -Message "Open folder : $ReportPath"
        Invoke-Item -Path $ReportPath
    }
}

# Used only to Out-Gridview Display, linked to : "Format-DisplayResult"
Function Out-GridviewDisplay {
    
    Param (
        [Parameter(Mandatory=$True)]
        [Array]$FormatedData,
        
        [Parameter(Mandatory=$True)]
        [String]$APIName,
        
        [Parameter(Mandatory=$True)]
        [String]$Description
    )
    
    Write-Log -Type INFO -Name 'Program run - Out-Gridview Display' -Message 'Start Out-Gridview Display' -NotDisplay
    
    Switch ($APIName) {
                
        'lan/ip'   {$FormatedData[0] | Out-GridView -Title "$Description - LAN Configuration"
                    $FormatedData[1] | Out-GridView -Title "$Description - Bbox Switch Port Configuration"
                    Break
                   }
        
        'wan/diags'{$FormatedData.DNS  | Out-GridView -Title "$Description - DNS"
                    $FormatedData.HTTP | Out-GridView -Title "$Description - HTTP"
                    $FormatedData.Ping | Out-GridView -Title "$Description - PING"
                    Break
                   }
                    
        Default    {$FormatedData | Out-GridView -Title $Description -Wait;Break}
                
    }
    
    Write-Log -Type INFO -Name 'Program run - Out-Gridview Display' -Message 'End Out-Gridview Display' -NotDisplay
}

#endregion Manage Output Display

#region Export data (All functions below are used only on powershell script : ".\BBOX-Administration.ps1")

# Used only to export Full BBOX Configuration to JSON files
function Export-BboxConfiguration {
    
    Param (
        [Parameter(Mandatory=$True)]
        [Array]$APISName,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlRoot,
        
        [Parameter(Mandatory=$True)]
        [String]$OutputFolder
    ) 
    
    Foreach ($APIName in $APISName) {
        
        $UrlToGo = "$UrlRoot/$APIName"
        
        # Get information from BBOX API
        Write-Log -Type INFO -Name 'Program run - Get Information' -Message "Get $APIName configuration ..."
        $Json = Get-BBoxInformation -UrlToGo $UrlToGo
        
        # Export result as JSON file
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        $Exportfile = $APIName.replace("/","-")
        $FullPath = "$OutputFolder\$Date-$Exportfile.json"
        Write-Log -Type INFO -Name 'Program run - Export Bbox Configuration To JSON' -Message 'Start Export Bbox Configuration To JSON' -NotDisplay
        Write-Log -Type INFONO -Name 'Program run - Export Bbox Configuration To JSON' -Message 'Export configuration to : '
        Write-Log -Type VALUE -Name 'Program run - Export Bbox Configuration To JSON' -Message $FullPath
        Write-Log -Type INFONO -Name 'Program run - Export Bbox Configuration To JSON' -Message 'Export Bbox Configuration To JSON status : ' -NotDisplay
        Try {
            $Json | ConvertTo-Json -depth 10 | Out-File -FilePath $FullPath -Force
            Write-Log -Type VALUE -Name 'Program run - Export Bbox Configuration To JSON' -Message 'Success' -NotDisplay
        }
        Catch {
            Write-Log -Type WARNING -Name 'Program run - Export Bbox Configuration To JSON' -Message "Failed, due to $($_.tostring())"
        }
        
        Write-Log -Type INFO -Name 'Program run - Export Bbox Configuration To JSON' -Message "End Export Bbox Configuration To JSON" -NotDisplay
    }

    If ($global:TriggerOpenExportFolder -eq 0) {
        
        $global:TriggerOpenExportFolder = Switch-OpenExportFolder
        $global:JSONSettingsCurrentUserContent.Trigger.OpenExportFolder = $global:TriggerOpenExportFolder
        $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
    }

    If ($global:OpenExportFolder -eq 'Y') {
        Write-Log -Type INFO -Name 'Program run - Export Bbox Configuration To JSON' -Message "Open folder : $OutputFolder"
        Invoke-Item -Path $OutputFolder
    }
    Return 'Program'
}

# Used only to export Full BBOX Configuration to JSON files
function Export-BBoxConfigTestingProgram {
    
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
    
    Write-Log -Type INFO -Name 'Program run - Testing Program' -Message 'Start Testing Program'
    
    Foreach ($APIName in $APISName) {
        
        Write-Log -Type INFONO -Name 'Program run - Testing Program' -Message 'Tested action : '
        Write-Log -Type VALUE -Name 'Program run - Testing Program' -Message $($APIName.Label)   
        
        $UrlToGo = "$UrlRoot/$($APIName.APIName)"
        
        # Get information from BBOX API
        $FormatedData = @()
        $FormatedData = Switch-Info -Label $APIName.Label -UrlToGo $UrlToGo -APIName $APIName.APIName -Mail $Mail -JournalPath $JournalPath -GitHubUrlSite $GitHubUrlSite
        
        # Export result as CSV file
        $Date = $(Get-Date -UFormat %Y%m%d_%H%M%S)
        
        If ($APIName.ExportFile -and $FormatedData) {
            
            $FullPath = "$OutputFolder\$Date-$($APIName.ExportFile).csv"
            Write-Log -Type INFO -Name 'Program run - Testing Program' -Message 'Start Export Bbox Configuration To CSV' -NotDisplay
            Write-Log -Type INFONO -Name 'Program run - Testing Program' -Message 'Export configuration to : '
            Write-Log -Type VALUE -Name 'Program run - Testing Program' -Message $FullPath
            Write-Log -Type INFONO -Name 'Program run - Testing Program' -Message 'Export Bbox Configuration To CSV status : ' -NotDisplay
            
            Try {
                $FormatedData | Export-Csv -Path $FullPath -Encoding UTF8 -Force -NoTypeInformation -Delimiter ";" -ErrorAction Continue
                Write-Log -Type VALUE -Name 'Program run - Testing Program' -Message 'Success' -NotDisplay
            }
            Catch {
                Write-Log -Type WARNING -Name 'Program run - Testing Program' -Message "Failed, due to $($_.tostring())"
            }
            
            Write-Log -Type INFO -Name 'Program run - Testing Program' -Message 'End Export Bbox Configuration To CSV' -NotDisplay
        }
        Else {
            Write-Log -Type INFO -Name 'Program run - Testing Program' -Message 'No data were found, export cant be possible' -NotDisplay
        }
    }
    
    If ($global:TriggerOpenExportFolder -eq 0) {
        
        $global:TriggerOpenExportFolder = Switch-OpenExportFolder
        $global:JSONSettingsCurrentUserContent.Trigger.OpenExportFolder = $global:TriggerOpenExportFolder
        $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
    }

    If ($global:OpenExportFolder -eq 'Y') {
        Write-Log -Type INFO -Name 'Program run - Testing Program' -Message "Open folder : $OutputFolder"
        Invoke-Item -Path $OutputFolder
    }
    
    Write-Log -Type INFO -Name 'Program run - Testing Program' -Message 'End Testing Program'
    Return 'Program'
}

# Used only to export BBOX Journal
Function Get-BBoxJournal {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo,
        
        [Parameter(Mandatory=$True)]
        [String]$JournalPath
    )
        
    # Loading Journal Home Page
    $UrlToGo = $UrlToGo -replace $global:JSONSettingsProgramContent.bbox.APIVersion -replace ('//','/')
    $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
    Start-Sleep 5
    
    # Download Journal file from BBOX
    Write-Log -Type INFO -Name 'Program run - Download Bbox Journal to export' -Message 'Start download Bbox Journal' -NotDisplay
    Try {
        $global:ChromeDriver.FindElementByClassName('download').click()
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program run - Download Bbox Journal to export' -Message "Failed to download Bbox Journal, due to : $($_.tostring())" -NotDisplay
    }
    Write-Log -Type INFONO -Name 'Program run - Download Bbox Journal to export' -Message "Download Journal in progress ... : "
    
    # Waiting end of journal's download
    Start-Sleep 8
    
    $JournalName = $global:JSONSettingsProgramContent.Path.JournalName
    Write-Log -Type INFONO -Name 'Program run - Download Bbox Journal to export' -Message 'User download folder : ' -NotDisplay
    Try {
        $UserDownloadFolderDefault = Get-ItemPropertyValue -Path $global:JSONSettingsProgramContent.Path.DownloadShellRegistryFolder -Name $global:JSONSettingsProgramContent.Path.DownloadShellRegistryFolderName -ErrorAction Stop
        Write-Log -Type VALUE -Name 'Program run - Download Bbox Journal to export' -Message $UserDownloadFolderDefault -NotDisplay
    }
    Catch {
        Write-Log -Type WARNING -Name 'Program run - Download Bbox Journal to export' -Message "Unknown, due to : $($_.tostring())" -NotDisplay
    }
    
    If (Test-Path -Path $UserDownloadFolderDefault) {
        
        Write-Log -Type INFONO -Name 'Program run - Download Bbox Journal to export' -Message 'Journal download location : ' -NotDisplay
        Try {
            $UserDownloadFolderDefaultFileName = (Get-ChildItem -Path $UserDownloadFolderDefault -Name "$JournalName*" | Select-Object PSChildName | Sort-Object PSChildName -Descending)[0].PSChildName
            $UserDownloadFileFullPath = "$UserDownloadFolderDefault\$UserDownloadFolderDefaultFileName"
            Write-Log -Type VALUE -Name 'Program run - Download Bbox Journal to export' -Message $UserDownloadFileFullPath -NotDisplay
        }
        Catch {
            Write-Log -Type WARNING -Name 'Program run - Download Bbox Journal to export' -Message "Unknown, due to : $($_.tostring())" -NotDisplay
        }
    }
    Else {
        Write-Log -Type WARNING -Name 'Program run - Download Bbox Journal to export' -Message 'Unable to find user download folder' -NotDisplay
    }
    
    If (-not ([string]::IsNullOrEmpty($UserDownloadFileFullPath))) {
        
        If (Test-Path -Path $UserDownloadFileFullPath) {
            
            Try {
                # Move Journal file from Download folder to journal folder : "$PSScriptRoot\Journal"
                $DownloadedJournalDestination = "$JournalPath\$UserDownloadFolderDefaultFileName"
                Move-Item -Path $UserDownloadFileFullPath -Destination $DownloadedJournalDestination -Force -ErrorAction Stop
                
                # Getting last Journal file version
                Write-Log -Type VALUE -Name 'Program run - Download Bbox Journal to export' -Message 'Finish' -NotDisplay
                Write-Log -Type INFONO -Name 'Program run - Download Bbox Journal to export' -Message 'Bbox Journal has been downloaded to : ' -NotDisplay
                Write-Log -Type VALUE -Name 'Program run - Download Bbox Journal to export' -Message $DownloadedJournalDestination -NotDisplay
            }
            Catch {
                Write-Log -Type WARNING -Name 'Program run - Download Bbox Journal to export' -Message "Failed, due to : $($_.tostring())" -NotDisplay
            }
            
            # Export Journal data as CSV file to to correct folder
            If (Test-path -Path $DownloadedJournalDestination) {
                
                Try {
                    $FormatedData = Import-Csv -Path $DownloadedJournalDestination -Delimiter ';' -Encoding UTF8
                }
                Catch {
                    Write-Log -Type WARNING -Name 'Program run - Download Bbox Journal to export' -Message "Failed, due to : $($_.tostring())" -NotDisplay
                }
            }
            Else {
                $FormatedData = $null
            }
            
            Write-Log -Type VALUE -Name 'Program run - Download Bbox Journal to export' -Message 'Success'
            Write-Log -Type INFO -Name 'Program run - Download Bbox Journal to export' -Message "End download Bbox Journal" -NotDisplay
            Return $FormatedData
        }
    }
    Else {
        Write-Log -Type WARNING -Name 'Program run - Download Bbox Journal to export' -Message 'Failed, due to time out'
        Write-Log -Type WARNING -Name 'Program run - Download Bbox Journal to export' -Message 'Failed to download Journal' -NotDisplay
        Write-Log -Type INFO -Name 'Program run - Download Bbox Journal to export' -Message 'End download Bbox Journal' -NotDisplay
        Return 'Program'
    }
}

# Used only to manage errors when there is no data to Export/Display, linked to : "Export-GlobalOutputData"
Function EmptyFormatedDATA {
    
    Param (
        [Parameter(Mandatory=$False)]
        [array]$FormatedData
    )
    
    Write-Log -Type INFO -Name 'Program run - Display/Export Result' -Message 'Start display/export result' -NotDisplay
    
    Switch ($FormatedData) {
        
        $Null     {Write-Log -Type INFO -Name "Program run - Display / Export Result" -Message 'No data were found, no need to Export/Display' -NotDisplay;Break}
        
        ''        {Write-Log -Type INFO -Name "Program run - Display / Export Result" -Message 'No data were found, no need to Export/Display' -NotDisplay;Break}
        
        ' '       {Write-Log -Type INFO -Name "Program run - Display / Export Result" -Message 'No data were found, no need to Export/Display' -NotDisplay;Break}
        
        'Domain'  {Write-Log -Type WARNING -Name "Program run - Display / Export Result" -Message 'Due to error, the result cant be displayed / exported' -NotDisplay;Break}
                
        'Program' {Write-Log -Type INFO -Name "Program run - Display / Export Result" -Message 'No data need to be exported or displayed' -NotDisplay;Break}
        
        Default   {Write-Log -Type WARNING -Name "Program run - Display / Export Result" -Message "Unknow Error, seems dev missing, result : $FormatedData";Break}
    }

    Write-Log -Type INFO -Name "Program run - Export/Display Result" -Message 'End export/display result' -NotDisplay
}

# Used only to manage data Export/Display, linked to : "Switch-ExportFormat" and "Switch-DisplayFormat" and "Format-ExportResult" and "Format-DisplayResult" and "EmptyFormatedDATA"
function Export-GlobalOutputData {
    
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
    If (($FormatedData -notmatch "Program") -and ($FormatedData -notmatch "Domain") -and ($null -ne $FormatedData) -and ($FormatedData -ne '') -and ($FormatedData -ne ' ')){
        
        # Choose Export format => CSV or JSON
        If ($global:TriggerExportFormat -eq 0) {
            
            $global:TriggerExportFormat = Switch-ExportFormat
            $global:JSONSettingsCurrentUserContent.Trigger.ExportFormat = $global:TriggerExportFormat
            $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
        }
        
        # Choose Display format => HTML or Table
        If ($global:TriggerDisplayFormat -eq 0) {
            
            $global:TriggerDisplayFormat = Switch-DisplayFormat
            $global:JSONSettingsCurrentUserContent.Trigger.DisplayFormat = $global:TriggerDisplayFormat
            $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
        }
        
        # Choose if open export folder
        If ($global:TriggerOpenExportFolder -eq 0) {
            
            $global:TriggerOpenExportFolder = Switch-OpenExportFolder
            $global:JSONSettingsCurrentUserContent.Trigger.OpenExportFolder = $global:TriggerOpenExportFolder
            $global:JSONSettingsCurrentUserContent | ConvertTo-Json | Out-File -FilePath $global:JSONSettingsCurrentUserFilePath -Encoding utf8 -Force
        }

        # Apply Export Format
        Format-ExportResult -FormatedData $FormatedData -APIName $APIName -Exportfile $ExportFile -ExportCSVPath $ExportCSVPath -ExportJSONPath $ExportJSONPath -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        
        # Apply Display Format
        Format-DisplayResult -FormatedData $FormatedData -APIName $APIName -Exportfile $ExportFile -Description $Description -ReportType $ReportType -ReportPath $ReportPath -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }
    Else {
        EmptyFormatedDATA -FormatedData $FormatedData -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }
}

#endregion Export data

#region Features (Functions used by functions in the PSM1 file : ".\BBOX-Module.psm1")

Function Get-State {
    
    Param (
        [Parameter(Mandatory=$False)]
        [String]$State
    )
    
    Switch ($State) {
    
        ''         {$Value = 'BYTEL Dev Error';Break}
        ' '        {$Value = 'BYTEL Dev Error';Break}
        .          {$Value = 'Not available with your device / BYTEL Dev Error';Break}
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
        running    {$Value = 'running';Break}
        Forbidden  {$Value = 'Forbidden';Break}
        Allowed    {$Value = 'Allowed';Break}
        Available  {$Value = 'Available';Break}
        Default    {$Value = 'Unknow / Dev Error';Break}
    }
    
    Return $Value
}

Function Get-Status {
    
    Param (
        [Parameter(Mandatory=$False)]
        [String]$Status
    )
    
    Switch ($Status) {
    
        ''           {$Value = 'Cant be define because service is disabled / BYTEL Dev Error';Break}
        .            {$Value = 'Not available with your device / BYTEL Dev Error';Break}
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
        Default      {$Value = 'Unknow / Dev Error';Break}
    }
    
    Return $Value
}

Function Get-YesNoAsk {
    
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

# Used only to get USB folder type, linked to : "Get-USBStorage"
Function Get-USBFolderType {
    
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

# Format Custom Date/Time, linked to : "Start-RefreshWIRELESSFrequencyNeighborhoodScan" and "Get-VOIPCallLogLineX" and "Get-VOIPFullCallLogLineX"
function Format-Date1970 {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$Seconds
    )
    
    $Date = (Get-Date -Date '01/01/1970').addseconds($Seconds)
    
    Return $Date
}

# Used only to get USB right, linked to : "Get-DeviceUSBDevices"
Function Get-USBRight {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$USBRight
    )
    
    Switch ($USBRight) {
    
        0       {$Value = 'Read Only';Break}
        1       {$Value = 'Read/Right';Break}
        Default {$Value = 'Unknow / Dev Error';Break}
    }
    
    Return $Value
}

# Used only to know which call type, linked to : "Get-VOIPCallLogLineX"
Function Get-VoiceCallType {
    
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

# Used only to get Powersatus for leds, linked to : "Get-DeviceLED"
Function Get-PowerStatus {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$PowerStatus
    )
    
    Switch ($PowerStatus) {
        
        on      {$Value = 'Light up';Break}
        off     {$Value = 'Light down';Break}
        Up      {$Value = 'Light up';Break}
        Down    {$Value = 'Light down';Break}
        blink   {$Value = 'Light blinking';Break}
        Default {$Value = 'Unknow / Dev Error';Break}
    }
    
    Return $Value
}

# Used only to get phone line linked to : Get-DeviceLog
Function Get-PhoneLine {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$Phoneline
    )
    
    Switch ($Phoneline) {
    
        1       {$Value = 'Line 1';Break}
        2       {$Value = 'Line 2';Break}
        Default {$Value = 'Unknow';Break}
    }
    
    Return $Value
}

# Used only to select by user the phone line to check, linked to : Get-VOIPCallLogLine / Get-VOIPFullCallLogLine
Function Get-PhoneLineID {

    While ($LineID -notmatch $global:JSONSettingsProgramContent.Values.LineNumber) {
        
        #$LineID = Read-Host "Enter value"
        $LineID = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Choose Phone Line ID' -LabelMessageText "Which Phone line do you want to select ?`n(1) Main line`n(2) Second line" -FirstOptionButtonText '1' -SecondOptionButtonText '2'
    }
    
    Return $LineID
}

# Used by Function : Switch-Info, linked to "Get-PhoneLineID" and "Get-VOIPCalllogLineX"
Function Get-VOIPCallLogLine {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )

    $LineID = Get-PhoneLineID
    $FormatedData = Get-VOIPCalllogLineX -UrlToGo "$UrlToGo/$LineID"
    
    Return $FormatedData
}

# Used by Function : Switch-Info, linked to "Get-PhoneLineID" and "Get-VOIPFullcalllogLineX"
Function Get-VOIPFullCallLogLine {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $LineID = Get-PhoneLineID
    $FormatedData = Get-VOIPFullcalllogLineX -UrlToGo "$UrlToGo/$LineID"
    
    Return $FormatedData
}

# Used only to set (PUT/POST) information
Function Set-BBoxInformation {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlHome,
        
        [Parameter(Mandatory=$True)]
        [String]$Password,
        
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    Write-Log -Type ERROR -Name 'Program run - Set BBox Information' -Message "`nConnexion à la BBOX : "
    
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
    Start-Sleep 1
    
    # Click on the connect button
    $global:ChromeDriver.FindElementByClassName('cta-1').Submit()
    Start-Sleep 2
    
    Write-Log -Type VALUE -Name 'Program run - Set BBox Information' -Message  'OK'
    Write-Log -Type INFO -Name 'Program run - Set BBox Information' -Message  'Application des modifications souhaitées : '
    
    # Go to the web page to get information we need
    $global:ChromeDriver.Navigate().GoToURL($UrlToGo)
    
    # Get Web page Content
    $Html = $global:ChromeDriver.PageSource
    
    # Close all ChromeDriver instances openned
    $global:ChromeDriver.Close()
    $global:ChromeDriver.Dispose()
    $global:ChromeDriver.Quit()
    
    Get-Process -Name chromedriver -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
    
    Write-Log -Type VALUE -Name 'Program run - Set BBox Information' -Message 'OK'
    
    Return $Html
}

#endregion Features

#region Switch-Info (Functions used only in the PSM1 file : ".\BBOX-Module.psm1")

#region Errors code

Function Get-ErrorCode {
    
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

Function Get-ErrorCodeTest {
    
    Param (
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
    $ErrorLine | Add-Member -Name 'Domain'      -MemberType Noteproperty -Value $Json.exception.domain
    $ErrorLine | Add-Member -Name 'Code'        -MemberType Noteproperty -Value $Json.exception.code
    $ErrorLine | Add-Member -Name 'ErrorName'   -MemberType Noteproperty -Value $Json.exception.errors[0].name
    $ErrorLine | Add-Member -Name 'ErrorReason' -MemberType Noteproperty -Value $Json.exception.errors[0].reason
    
    # Add lines to $Array
    $Array += $ErrorLine
    
    Return $Array
}

#endregion Errors code

#region PasswordRecoveryVerify

Function Get-PasswordRecoveryVerify {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )

    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

# Depreciated
function Get-Airties {
    
    Param (
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
    $Airties | Add-Member -Name 'Agent Status'                    -MemberType Noteproperty -Value $(Get-Status -Status $Json.agent.enable)
    $Airties | Add-Member -Name 'Band Steering Status'            -MemberType Noteproperty -Value $(Get-Status -Status $Json.bandsteering.enable)
    $Airties | Add-Member -Name 'Mesh Steering Status'            -MemberType Noteproperty -Value $(Get-Status -Status $Json.meshsteering.enable)
    $Airties | Add-Member -Name 'Remote Manager Status'           -MemberType Noteproperty -Value $(Get-Status -Status $Json.remotemanager.enable)
    $Airties | Add-Member -Name 'CACS Status'                     -MemberType Noteproperty -Value $(Get-Status -Status $Json.cacs.enable)
    $Airties | Add-Member -Name 'Live View Status'                -MemberType Noteproperty -Value $(Get-Status -Status $Json.liveview.enable)
    $Airties | Add-Member -Name 'Zero Touch Status'               -MemberType Noteproperty -Value $(Get-Status -Status $Json.zerotouch.enable) # New Since version : 20.2.16
    $Airties | Add-Member -Name 'Device Serial Number'            -MemberType Noteproperty -Value $Json.device.serialnumber
    $Airties | Add-Member -Name 'Device Firmware Main Version'    -MemberType Noteproperty -Value $Json.device.main.version
    $Airties | Add-Member -Name 'Device Firmware Main Date'       -MemberType Noteproperty -Value $Json.device.main.date
    $Airties | Add-Member -Name 'Device Firmware Running Version' -MemberType Noteproperty -Value $Json.device.running.version
    $Airties | Add-Member -Name 'Device Firmware Running date'    -MemberType Noteproperty -Value $Json.device.running.date
    $Airties | Add-Member -Name 'IP Address'                      -MemberType Noteproperty -Value $Json.lanmode.ip
    $Airties | Add-Member -Name 'IP Lan Address'                  -MemberType Noteproperty -Value $Json.lanmode.iplan

    # Add lines to $Array
    $Array += $Airties
    
    Return $Array
}

function Get-AirtiesLANMode {
    
    Param (
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
    $LANMode | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'Airties - LAN Mode'
    $LANMode | Add-Member -Name 'State'   -MemberType Noteproperty -Value $(Get-Status -Status $Json.enable)

    # Add lines to $Array
    $Array += $LANMode
    
    Return $Array
}

#endregion Airties

#region API Ressources Map

Function Get-APIRessourcesMap {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-BackupList {
    
    Param (
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
    If ($Json.Count -ne '0') {
        
        $Config = 0
        
        While ($Config -lt $Json.count) {
            
            # Create New PSObject and add values to array
            $ConfigLine = New-Object -TypeName PSObject
            $ConfigLine | Add-Member -Name 'ID'                      -MemberType Noteproperty -Value $Json[$Config].id
            $ConfigLine | Add-Member -Name 'Backup Name'             -MemberType Noteproperty -Value $Json[$Config].name
            $ConfigLine | Add-Member -Name 'Backup Creation Date'    -MemberType Noteproperty -Value $Json[$Config].date
            $ConfigLine | Add-Member -Name 'Backup Firmware Version' -MemberType Noteproperty -Value $Json[$Config].firmware
            
            # Add lines to $Array
            $Array += $ConfigLine
            
            # Go to next line
            $Config ++
        }
        
        Return $Array
    }
    # Check if BBox Cloud Synchronisation Service is Active and if user allow it
    Else {
        $APIName = 'usersave'
        $UrlToGo = $UrlToGo.Replace('configs',$APIName)
        $CloudSynchronisationState = Get-BBoxInformation -UrlToGo $UrlToGo
        $Enable = $(Get-State -State $CloudSynchronisationState.$APIName.enable)
        $Status = $(Get-Status -Status $CloudSynchronisationState.$APIName.status)
        $Authorized = $(Get-YesNoAsk -YesNoAsk $CloudSynchronisationState.$APIName.authorized)
        $Datelastsave = $($CloudSynchronisationState.$APIName.datelastsave)

        Write-Log -Type WARNING -Name 'Program run - Get BBOX Configuration Save' -Message 'No local backups were found'
        
        Write-Log -Type INFONO -Name 'Program run - Get BBOX Configuration Save' -Message 'Checking BBox cloud save synchronisation state : '
        Write-Log -Type VALUE -Name 'Program run - Get BBOX Configuration Save' -Message $Enable
        
        Write-Log -Type INFONO -Name 'Program run - Get BBOX Configuration Save' -Message 'Checking BBox cloud save synchronisation status : '
        Write-Log -Type VALUE -Name 'Program run - Get BBOX Configuration Save' -Message $Status
        
        Write-Log -Type INFONO -Name 'Program run - Get BBOX Configuration Save' -Message 'Checking BBox cloud save synchronisation user consent : '
        Write-Log -Type VALUE -Name 'Program run - Get BBOX Configuration Save' -Message $Authorized
        
        Write-Log -Type INFONO -Name 'Program run - Get BBOX Configuration Save' -Message 'Last Time BBox Configuration save to the cloud : '
        Write-Log -Type VALUE -Name 'Program run - Get BBOX Configuration Save' -Message $Datelastsave
        
        $Message = "No local backups in BBox configuration were found.`nBBox cloud save synchronisation settings :
        - State : $Enable
        - Status : $Status
        - User consent : $Authorized
        - Last Synchronisation : $Datelastsave
        "
        
        Show-WindowsFormDialogBox -Title 'Program run - Get BBOX Configuration Save' -Message $Message -WarnIcon
        Return "Program"
    }
}

#endregion BACKUP

#region USERSAVE

Function Get-USERSAVE {
    
    Param (
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
    $UsersaveLine | Add-Member -Name 'Service'              -MemberType Noteproperty -Value $APIName
    $UsersaveLine | Add-Member -Name 'State'                -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $UsersaveLine | Add-Member -Name 'Status'               -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $UsersaveLine | Add-Member -Name 'Boots Number'       -MemberType Noteproperty -Value $Json.numberofboots # Since Version : 19.2.12
    $UsersaveLine | Add-Member -Name 'Last Restore date'    -MemberType Noteproperty -Value $Json.datelastrestore
    $UsersaveLine | Add-Member -Name 'Last Date Save'       -MemberType Noteproperty -Value $Json.datelastsave
    $UsersaveLine | Add-Member -Name 'Restore From Factory' -MemberType Noteproperty -Value $Json.restorefromfactory
    $UsersaveLine | Add-Member -Name 'Delay'                -MemberType Noteproperty -Value $Json.delay
    $UsersaveLine | Add-Member -Name 'Allow Cloud Sync ?'   -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.authorized) # Since Version : 19.2.12
    $UsersaveLine | Add-Member -Name 'Never Synced ?'       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.neversynced) # Since Version : 19.2.12
    
    # Add lines to $Array
    $Array += $UsersaveLine
    
    Return $Array
}

#endregion USERSAVE

#region CPL

Function Get-CPL {
    
    Param (
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
    $CPLLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value $APIName
    $CPLLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.running)
    
    # Add lines to $Array
    $Array += $CPLLine
    
    Return $Array
}

Function Get-CPLDeviceList {
    
    Param (
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
    
    If ($Json.$APIName.count -ne 0) {
        
        $Index = 0
        While ($Index -ne $Json.$APIName.count) {
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

Function Get-Device {
    
    Param (
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
    
    If (-not ([string]::IsNullOrEmpty($Json.temperature.status))) {
        $TemperatureStatus = Get-Status -Status $Json.temperature.status
    }
    Else {
        $TemperatureStatus = ''
    }
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name 'Date'                      -MemberType Noteproperty -Value $Json.now
    $DeviceLine | Add-Member -Name 'Status'                    -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $DeviceLine | Add-Member -Name 'Nb Boots since 1st use'    -MemberType Noteproperty -Value $Json.numberofboots
    $DeviceLine | Add-Member -Name 'Bbox Model'                -MemberType Noteproperty -Value $Json.modelname
    $DeviceLine | Add-Member -Name 'Is GUI password is set ?'  -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.user_configured)
    $DeviceLine | Add-Member -Name 'Wifi Optimisation Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.optimisation)
    $DeviceLine | Add-Member -Name 'Serial Number'             -MemberType Noteproperty -Value $Json.serialnumber
    $DeviceLine | Add-Member -Name 'Current Temperature (°C)'  -MemberType Noteproperty -Value $Json.temperature.current
    $DeviceLine | Add-Member -Name 'Temperature Status'        -MemberType Noteproperty -Value $TemperatureStatus
    $DeviceLine | Add-Member -Name 'Display Orientation (°)'   -MemberType Noteproperty -Value $Json.display.orientation
    $DeviceLine | Add-Member -Name 'Luminosity Grade (%) '     -MemberType Noteproperty -Value $Json.display.luminosity
    $DeviceLine | Add-Member -Name 'Front Screen Displayed'    -MemberType Noteproperty -Value $Json.display.state
    $DeviceLine | Add-Member -Name 'MAIN Firmware Version'     -MemberType Noteproperty -Value $Json.main.version
    $DeviceLine | Add-Member -Name 'MAIN Firmware Date'        -MemberType Noteproperty -Value $Json.main.date
    $DeviceLine | Add-Member -Name 'RECOVERY Firmware Version' -MemberType Noteproperty -Value $Json.reco.version
    $DeviceLine | Add-Member -Name 'RECOVERY Firmware Date'    -MemberType Noteproperty -Value $Json.reco.date
    $DeviceLine | Add-Member -Name 'RUNNING Firmware Version'  -MemberType Noteproperty -Value $Json.running.version # Missing in online documentation : https://api.bbox.fr/doc/apirouter/index.html
    $DeviceLine | Add-Member -Name 'RUNNING Firmware Date'     -MemberType Noteproperty -Value $Json.running.date    # Missing in online documentation : https://api.bbox.fr/doc/apirouter/index.html
    $DeviceLine | Add-Member -Name 'BACKUP Version'            -MemberType Noteproperty -Value $Json.bcck.version
    $DeviceLine | Add-Member -Name 'BOOTLOADER 1 Version'      -MemberType Noteproperty -Value $Json.ldr1.version
    $DeviceLine | Add-Member -Name 'BOOTLOADER 2 Version'      -MemberType Noteproperty -Value $Json.ldr2.version
    $DeviceLine | Add-Member -Name 'First use date'            -MemberType Noteproperty -Value $Json.firstusedate
    $DeviceLine | Add-Member -Name 'Last boot Time'            -MemberType Noteproperty -Value (Get-Date).AddSeconds(- $Json.uptime)
    $DeviceLine | Add-Member -Name 'IPV4 Status'               -MemberType Noteproperty -Value (Get-Status -Status $Json.using.ipv4)
    $DeviceLine | Add-Member -Name 'IPV6 Status'               -MemberType Noteproperty -Value (Get-Status -Status $Json.using.ipv6)
    $DeviceLine | Add-Member -Name 'FTTH Status'               -MemberType Noteproperty -Value (Get-Status -Status $Json.using.ftth)
    $DeviceLine | Add-Member -Name 'ADSL Status'               -MemberType Noteproperty -Value (Get-Status -Status $Json.using.adsl)
    $DeviceLine | Add-Member -Name 'VDSL Status'               -MemberType Noteproperty -Value (Get-Status -Status $Json.using.vdsl)
    
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

Function Get-DeviceLog {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.log
    
    $Line = 0
    $Index = 0
    
    While ($Line -lt $Json.count) {
        
        $Date = $Json[$Line].date
        
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
            
            DISPLAY_STATE              {$Details = "Changement d'Ã©tat de la Bbox : $($Json[$Line].param)"
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
            
            LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Hostname : $($Params[2]), IP Address in conflit : $($Params[1])"
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
            
            USER_CHANGEPWD             {$Details = "Changement du mot de passe d'administration de la BBOX : $($Json[$Line].param))"
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
            
            WAN_ROUTE_ADDED            {$Details = "Ajout nouvelle règle de routage sur l'adresse MAC : $($Params[0])"
                                        $LogType = 'Internet'
                                        Break
                                       }
            
            WAN_ROUTE_REMOVED          {$Details = "Suppression règle de routage sur l'adresse MAC : $($Params[0])"
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
            
            UPGRADE_MAIN_FINISH        {$Details = "Mise à jour du logiciel de la Bbox réussie (firmware opérationnel) : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            UPGRADE_MAIN_FINISH_FAILED {$Details = "Echec de la mise à jour du logiciel de la Bbox (firmware opérationnel) : $($Json[$Line].param)"
                                        $LogType = 'Système'
                                        Break
                                       }
            
            UPGRADE_START              {$Details = "Mise à jour du logiciel de la Bbox en cours (firmware opérationnel) : $($Json[$Line].param)"
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

Function Get-DeviceFullLog {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    $Pageid = 1
    $Index = 0
    
    While ($Json.exception.code -ne '404') {
        
        # Select $JSON header
        $Json = $Json.log
        
        $Line = 0
        
        While ($Line -lt $Json.count) {
            
            $Date = $Json[$Line].date
            
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
                
                DISPLAY_STATE              {$Details = "Changement d'Ã©tat de la Bbox : $($Json[$Line].param)"
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
                
                LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Hostname : $($Params[2]), IP Address in conflit : $($Params[1])"
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
                
                USER_CHANGEPWD             {$Details = "Changement du mot de passe d'administration de la BBOX : $($Json[$Line].param))"
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
                
                WAN_ROUTE_ADDED            {$Details = "Ajout nouvelle règle de routage sur l'adresse MAC : $($Params[0])"
                                            $LogType = 'Internet'
                                            Break
                                           }
                
                WAN_ROUTE_REMOVED          {$Details = "Suppression règle de routage sur l'adresse MAC : $($Params[0])"
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
                
                UPGRADE_MAIN_FINISH        {$Details = "Mise à jour du logiciel de la Bbox réussie (firmware opérationnel) : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                UPGRADE_MAIN_FINISH_FAILED {$Details = "Echec de la mise à jour du logiciel de la Bbox (firmware opérationnel) : $($Json[$Line].param)"
                                            $LogType = 'Système'
                                            Break
                                           }
                
                UPGRADE_START              {$Details = "Mise à jour du logiciel de la Bbox en cours (firmware opérationnel) : $($Json[$Line].param)"
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
        
        # Get information from BBOX API
        $Json = Get-BBoxInformation -UrlToGo "$UrlToGo/$Pageid"
    }
    
    Return $Array
}

Function Get-DeviceFullTechnicalLog {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    $Pageid = 1
    $Index = 0
    
    While ($Json.exception.code -ne '404') {
        
        # Select $JSON header
        $Json = $Json.log
        
        $Line = 1
        
        While ($Line -lt $Json.count) {
            
            $Date = $Json[$Line].date
            
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
                
                LAN_PORT_UP                {$Details = "Bbox Switch Port : $($Json[$Line].param)";Break}
                
                LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Hostname : $($Params[2]), IP Address in conflit : $($Params[1])";Break}
                
                LOGIN_LOCAL                {$Details = "Hostname : $($Params[1]), IP Address : $($Params[0])";Break}
                
                LOGIN_REMOTE               {$Details = "Hostname : $($Params[1]), IP Address : $($Params[0])";Break}
                
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
                
                WAN_ROUTE_ADDED            {$Details = "MAC Address : $($Params[0])";Break}
                
                WAN_ROUTE_REMOVED          {$Details = "MAC Address : $($Params[0])";Break}
                
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
        
        # Get information from BBOX API
        $Json = Get-BBoxInformation -UrlToGo "$UrlToGo/$Pageid"
    }
    
    Return $Array
}

Function Get-DeviceCpu {
    
    Param (
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

Function Get-DeviceMemory {
    
    Param (
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
    $MemoryLine | Add-Member -Name 'Total Memory'     -MemberType Noteproperty -Value $Json.total
    $MemoryLine | Add-Member -Name 'Free Memory'      -MemberType Noteproperty -Value $Json.free
    $MemoryLine | Add-Member -Name 'Cached Memory'    -MemberType Noteproperty -Value $Json.cached
    $MemoryLine | Add-Member -Name 'Committed Memory' -MemberType Noteproperty -Value $Json.committedas
    
    # Add lines to $Array
    $Array += $MemoryLine
    
    Return $Array
}

Function Get-DeviceLED {
    
    Param (
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
    $LedLine | Add-Member -Name 'State Power Led'           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.power)
    $LedLine | Add-Member -Name 'State Power Red Led'       -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.power_red)
    $LedLine | Add-Member -Name 'State Power Green Led'     -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.power_green)
    $LedLine | Add-Member -Name 'State Wifi Led'            -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.wifi)
    $LedLine | Add-Member -Name 'State Wifi red Led'        -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.wifi_red)
    $LedLine | Add-Member -Name 'State Phone 1 Led'         -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phone1)
    $LedLine | Add-Member -Name 'State Phone 1 Red Led'     -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phone1_red)
    $LedLine | Add-Member -Name 'State Phone 2 Led'         -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phone2)
    $LedLine | Add-Member -Name 'State Phone 2 Red Led'     -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phone2_red)
    $LedLine | Add-Member -Name 'State WAN Led'             -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.wan)
    $LedLine | Add-Member -Name 'State WAN Red Led'         -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.wan_red)
    
    # Ethernet Switch Port LED State
    $LedLine | Add-Member -Name 'State sw1_1 Led'           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw1_1)
    $LedLine | Add-Member -Name 'State sw1_2 Led'           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw1_2)
    $LedLine | Add-Member -Name 'State sw2_1 Led'           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw2_1)
    $LedLine | Add-Member -Name 'State sw2_2 Led'           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw2_2)
    $LedLine | Add-Member -Name 'State sw3_1 Led'           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw3_1)
    $LedLine | Add-Member -Name 'State sw3_2 Led'           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw3_2)
    $LedLine | Add-Member -Name 'State sw4_1 Led'           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw4_1)
    $LedLine | Add-Member -Name 'State sw4_2 Led'           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.sw4_2)
    $LedLine | Add-Member -Name 'State phy_1 Led'           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phy_1)
    $LedLine | Add-Member -Name 'State phy_2 Led'           -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.led.phy_2)
    
    # Ethernet Switch LED State
    $LedLine | Add-Member -Name 'State Ethernet port 1 Led' -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.ethernetPort[0].state)
    $LedLine | Add-Member -Name 'State Ethernet port 2 Led' -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.ethernetPort[1].state)
    $LedLine | Add-Member -Name 'State Ethernet port 3 Led' -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.ethernetPort[2].state)
    $LedLine | Add-Member -Name 'State Ethernet port 4 Led' -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.ethernetPort[3].state)
    $LedLine | Add-Member -Name 'State Ethernet port 5 Led' -MemberType Noteproperty -Value (Get-PowerStatus -PowerStatus $Json.ethernetPort[4].state)
    
    # Add lines to $Array
    $Array += $LedLine
    
    Return $Array
}

Function Get-DeviceSummary {
    
    Param (
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
    $SummaryLine | Add-Member -Name 'Date'          -MemberType Noteproperty -Value $Json.now
    $SummaryLine | Add-Member -Name 'Status'        -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $SummaryLine | Add-Member -Name 'Default'       -MemberType Noteproperty -Value (Get-Status -Status $Json.default)
    $SummaryLine | Add-Member -Name 'Model'         -MemberType Noteproperty -Value $Json.modelname
    $SummaryLine | Add-Member -Name 'Serial Number' -MemberType Noteproperty -Value $Json.serialnumber
    
    # Add lines to $Array
    $Array += $SummaryLine
    
    Return $Array
}

Function Get-DeviceToken {
    
    Param (
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
    $Date = $Json.now
    $ExpirationDate = $Json.expires
    $TimeLeft = New-TimeSpan -Start $Date -End $ExpirationDate
    
    # Create New PSObject and add values to array
    $TokenLine = New-Object -TypeName PSObject
    $TokenLine | Add-Member -Name 'Token'                 -MemberType Noteproperty -Value $Json.token
    $TokenLine | Add-Member -Name 'Date'                  -MemberType Noteproperty -Value $Date
    $TokenLine | Add-Member -Name 'Token Expiration Date' -MemberType Noteproperty -Value $ExpirationDate
    $TokenLine | Add-Member -Name 'Token Valid Time Left' -MemberType Noteproperty -Value $TimeLeft

    # Add lines to $Array
    $Array += $TokenLine
    
    Return $Array
}

#endregion DEVICE

#region DHCP

Function Get-DHCP {
        
    Param (
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
    $DHCP | Add-Member -Name 'State'                  -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $DHCP | Add-Member -Name 'Status'                 -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $DHCP | Add-Member -Name 'First Range IP Address' -MemberType Noteproperty -Value $Json.minaddress
    $DHCP | Add-Member -Name 'Last Last IP Address'   -MemberType Noteproperty -Value $Json.maxaddress
    $DHCP | Add-Member -Name 'Bail (Secondes)'        -MemberType Noteproperty -Value $Json.leasetime
    $DHCP | Add-Member -Name 'Bail (Minutes)'         -MemberType Noteproperty -Value ($Json.leasetime / 60)
    $DHCP | Add-Member -Name 'Bail (Hours)'           -MemberType Noteproperty -Value ($Json.leasetime / 3600)
    
    # Add lines to $Array
    $Array += $DHCP
    
    Return $Array
}

Function Get-DHCPClients {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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
            
            # Add lines to $Array
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

Function Get-DHCPClientsID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $DeviceIDs = Get-DHCPClients -UrlToGo $UrlToGo
    $DeviceID = $DeviceIDs | Select-Object ID,'Device HostName' | Out-GridView -Title 'DHCP Client List' -OutputMode Single
    $Device = $DeviceIDs | Where-Object {$_.ID -ilike $DeviceID.id}
    
    Return $Device
}

Function Get-DHCPActiveOptions {
    
    Param (
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
    $OptionLine | Add-Member -Name 'ID'     -MemberType Noteproperty -Value $Json.optionsstatic.id
    $OptionLine | Add-Member -Name 'Option' -MemberType Noteproperty -Value $Json.optionsstatic.option
    $OptionLine | Add-Member -Name 'Value'  -MemberType Noteproperty -Value $Json.optionsstatic.value
    $OptionLine | Add-Member -Name 'Type'   -MemberType Noteproperty -Value 'Static'
    
    $Array += $OptionLine
    
    # Add DYnamic DHCP Options
    
    If ($Json.options.Count -ne 0) {
        
        $Option = 0
        
        While ($Option -lt $Json.options.Count) {
            
            # Create New PSObject and add values to array
            $OptionLine = New-Object -TypeName PSObject
            $OptionLine | Add-Member -Name 'ID'     -MemberType Noteproperty -Value $Json.options[$Option].id
            $OptionLine | Add-Member -Name 'Option' -MemberType Noteproperty -Value $Json.options[$Option].option
            $OptionLine | Add-Member -Name 'Value'  -MemberType Noteproperty -Value $Json.options[$Option].value
            $OptionLine | Add-Member -Name 'Type'   -MemberType Noteproperty -Value 'Dynamic'
            
            # Add lines to $Array
            $Array += $OptionLine
            
            # Go to next line
            $Option ++
        }
    }
    
    Return $Array
}

Function Get-DHCPOptions {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.optionscapabilities
    
    If ($Json.Count -ne 0) {
        
        $Option = 0
        
        While ($Option -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $OptionLine = New-Object -TypeName PSObject
            $OptionLine | Add-Member -Name 'ID'          -MemberType Noteproperty -Value $Json[$Option].ID
            $OptionLine | Add-Member -Name 'Type'        -MemberType Noteproperty -Value $Json[$Option].Type
            $OptionLine | Add-Member -Name 'Description' -MemberType Noteproperty -Value $Json[$Option].Description
            $OptionLine | Add-Member -Name 'RFC'         -MemberType Noteproperty -Value $Json[$Option].RFC
            
            # Add lines to $Array
            $Array += $OptionLine
            
            # Go to next line
            $Option ++
        }
    
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-DHCPOptionsID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $OptionIDs = Get-DHCPOptions -UrlToGo $UrlToGo
    $OptionID = $OptionIDs | Select-Object ID,Description | Out-GridView -Title "DHCP Capabilities Options" -OutputMode Single
    $Option = $OptionIDs | Where-Object {$_.ID -ilike $OptionID.id}
    
    Return $Option
}

Function Get-DHCPSTBOptions {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.options
    
    If ($Json.count -ne 0) {
        
        $Option = 0
        
        While ($Option -lt $Json.count) {
            
            # Create New PSObject and add values to array
            $OptionLine = New-Object -TypeName PSObject
            $OptionLine | Add-Member -Name 'ID'     -MemberType Noteproperty -Value $Json[$Option].id
            $OptionLine | Add-Member -Name 'Option' -MemberType Noteproperty -Value $Json[$Option].option
            
            # Add lines to $Array
            $Array += $OptionLine
            
            # Go to next line
            $Option ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

function Get-DHCPv6PrefixDelegation {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-DHCPv6Options {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.dhcp.optionscapabilities
    
    If ($Json.Count -ne 0) {
        
        $Option = 0
        
        While ($Option -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $OptionLine = New-Object -TypeName PSObject
            $OptionLine | Add-Member -Name 'ID'          -MemberType Noteproperty -Value $Json[$Option].ID
            $OptionLine | Add-Member -Name 'Type'        -MemberType Noteproperty -Value $Json[$Option].Type
            $OptionLine | Add-Member -Name 'Description' -MemberType Noteproperty -Value $Json[$Option].Description
            $OptionLine | Add-Member -Name 'RFC'         -MemberType Noteproperty -Value $Json[$Option].RFC
            
            # Add lines to $Array
            $Array += $OptionLine
            
            # Go to next line
            $Option ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

#endregion DHCP

#region DNS

Function Get-DNSStats {
    
    Param (
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
    $DnsStats | Add-Member -Name 'Answer Min Time (ms)'      -MemberType Noteproperty -Value $Json.min
    $DnsStats | Add-Member -Name 'Answer Max Time (ms)'      -MemberType Noteproperty -Value $Json.max
    $DnsStats | Add-Member -Name 'Answer Averrage Time (ms)' -MemberType Noteproperty -Value $Json.avg
    
    # Add lines to $Array
    $Array += $DnsStats
    
    Return $Array
}

#endregion DNS

#region DYNDNS

Function Get-DYNDNS {
    
    Param (
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
    $DyndnsLine | Add-Member -Name 'Service'              -MemberType Noteproperty -Value 'DYNDNS'
    $DyndnsLine | Add-Member -Name 'State'                -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $DyndnsLine | Add-Member -Name 'Status'               -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $DyndnsLine | Add-Member -Name 'Nb Configured domain' -MemberType Noteproperty -Value ($Json.domaincount)
    
    # Add lines to $Array
    $Array += $DyndnsLine
    
    Return $Array
}

Function Get-DYNDNSProviderList {
    
    Param (
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
    
    If ($Json.count -ne 0) {
    
    $Providers = 0
    
    While ($Providers -lt $Json.count) {
        
        # Create New PSObject and add values to array
        $ProviderLine = New-Object -TypeName PSObject
        $ProviderLine | Add-Member -Name 'Provider'                        -MemberType Noteproperty -Value $Json[$Providers].name
        $ProviderLine | Add-Member -Name 'Supported Protocols (IPv4/IPv6)' -MemberType Noteproperty -Value ($($Json[$Providers].Support) -join '/')
        $ProviderLine | Add-Member -Name 'Web Site'                        -MemberType Noteproperty -Value $Json[$Providers].Site
        
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

Function Get-DYNDNSClient {
    
    Param (
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
    
    If ($Json.count -ne '0') {
        
        $Provider = 0
        
        While ($Provider -lt $Json.count) {
            
            # Create New PSObject and add values to array
            $ProviderLine = New-Object -TypeName PSObject
            $ProviderLine | Add-Member -Name 'ID'                  -MemberType Noteproperty -Value $Json[$Provider].id
            $ProviderLine | Add-Member -Name 'Provider'            -MemberType Noteproperty -Value $Json[$Provider].server
            $ProviderLine | Add-Member -Name 'State'               -MemberType Noteproperty -Value (Get-State -State $Json[$Provider].enable)
            $ProviderLine | Add-Member -Name 'Username'            -MemberType Noteproperty -Value $Json[$Provider].username
            $ProviderLine | Add-Member -Name 'Password'            -MemberType Noteproperty -Value $Json[$Provider].password
            $ProviderLine | Add-Member -Name 'Host'                -MemberType Noteproperty -Value $Json[$Provider].host
            $ProviderLine | Add-Member -Name 'Record Type'         -MemberType Noteproperty -Value $Json[$Provider].record
            $ProviderLine | Add-Member -Name 'MAC Address'         -MemberType Noteproperty -Value $Json[$Provider].device
            $ProviderLine | Add-Member -Name 'Date'                -MemberType Noteproperty -Value $Json[$Provider].status.date
            $ProviderLine | Add-Member -Name 'Status'              -MemberType Noteproperty -Value $Json[$Provider].status.status
            $ProviderLine | Add-Member -Name 'Message'             -MemberType Noteproperty -Value $Json[$Provider].status.message
            $ProviderLine | Add-Member -Name 'IP Address'          -MemberType Noteproperty -Value $Json[$Provider].status.ip
            $ProviderLine | Add-Member -Name 'Cache Date'          -MemberType Noteproperty -Value $Json[$Provider].status.cache_date
            $ProviderLine | Add-Member -Name 'Periodic Update (H)' -MemberType Noteproperty -Value $Json[$Provider].periodicupdate
            
            $Array += $ProviderLine
            
            # Go to next line
            $Provider ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-DYNDNSClientID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $DyndnsIDs = Get-DYNDNSClient -UrlToGo $UrlToGo -APIName $APIName
    $DyndnsID = $DyndnsIDs | Select-Object ID,Provider,Host | Out-GridView -Title "DYNDNS Configuration List" -OutputMode Single
    $Dyndns = $DyndnsIDs | Where-Object {$_.ID -ilike $DyndnsID.id}
    
    Return $Dyndns
}

#endregion DYNDNS

#region FIREWALL

Function Get-FIREWALL {
    
    Param (
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
    $Firewall | Add-Member -Name 'Service'             -MemberType Noteproperty -Value $APIName
    $Firewall | Add-Member -Name 'State'               -MemberType Noteproperty -Value $Json.state
    $Firewall | Add-Member -Name 'Status'              -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $Firewall | Add-Member -Name 'Supported Protocols' -MemberType Noteproperty -Value ($($Json.protoscapabilities) -join ',')
    
    # Add lines to $Array
    $Array += $Firewall
    
    Return $Array
}

Function Get-FIREWALLRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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
            $RuleLine | Add-Member -Name 'Nb time used ?'                 -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].utilisation)
            
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

Function Get-FIREWALLRulesID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )

    $RuleIDs = Get-FIREWALLRules -UrlToGo $UrlToGo
    $RuleID = $RuleIDs | Select-Object ID,Description | Out-GridView -Title "IPV4 FireWall List" -OutputMode Single
    $Rule = $RuleIDs | Where-Object {$_.ID -ilike $RuleID.id}
    
    Return $Rule
}

Function Get-FIREWALLPingResponder {
    
    Param (
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
    $PingResponderLine | Add-Member -Name 'Service'                   -MemberType Noteproperty -Value 'Ping Responder'
    $PingResponderLine | Add-Member -Name 'Status'                    -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $PingResponderLine | Add-Member -Name 'IPV4 Addess/Range Allowed' -MemberType Noteproperty -Value $Json.ip
    $PingResponderLine | Add-Member -Name 'IPV6 Addess/Range Allowed' -MemberType Noteproperty -Value $Json.ipv6
    
    # Add lines to $Array
    $Array += $PingResponderLine
    
    Return $Array
}

Function Get-FIREWALLGamerMode {
    
    Param (
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
    $GamerModeLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'Gamer Mode'
    $GamerModeLine | Add-Member -Name 'Status' -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    
    # Add lines to $Array
    $Array += $GamerModeLine
    
    Return $Array
}

Function Get-FIREWALLv6Rules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-FIREWALLv6RulesID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $RuleIDs = Get-FIREWALLv6Rules -UrlToGo $UrlToGo
    $RuleID = $RuleIDs | Select-Object ID,Description | Out-GridView -Title "IPV6 FireWall Rules List : " -OutputMode Single
    $Rule = $RuleIDs | Where-Object {$_.ID -ilike $RuleID.id}
    
    Return $Rule
}

function Get-FIREWALLv6Level {
    
    Param (
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
    $DeviceLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'FireWall IPV6'
    $DeviceLine | Add-Member -Name 'Level'   -MemberType Noteproperty -Value $Json.level
    
    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

#endregion FIREWALL

#region HOSTS

Function Get-HOSTS {
    
    Param (
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
    
    If ($Json.Count -ne 0) {
        
        $Device = 0
        
        While ($Device -lt ($Json.Count)) {
            
            # Create New PSObject and add values to array
            $DeviceLine = New-Object -TypeName PSObject
            $DeviceLine | Add-Member -Name 'ID'                               -MemberType Noteproperty -Value $Json[$Device].id
            $DeviceLine | Add-Member -Name 'Hostname'                         -MemberType Noteproperty -Value $Json[$Device].hostname
            $DeviceLine | Add-Member -Name 'MAC Address'                      -MemberType Noteproperty -Value $Json[$Device].macaddress
            $DeviceLine | Add-Member -Name 'DUID'                             -MemberType Noteproperty -Value $Json[$Device].duid
            $DeviceLine | Add-Member -Name 'IPV4 Adress'                      -MemberType Noteproperty -Value $Json[$Device].ipaddress
            $DeviceLine | Add-Member -Name 'DHCP Mode'                        -MemberType Noteproperty -Value $Json[$Device].type
            $DeviceLine | Add-Member -Name 'Link Type'                        -MemberType Noteproperty -Value $Json[$Device].link
            $DeviceLine | Add-Member -Name 'Device Type'                      -MemberType Noteproperty -Value $Json[$Device].devicetype
            
            # If STB part
            If ($Json[$Device].devicetype -like 'STB') {
                
                $DeviceLine | Add-Member -Name 'STB - Product'                -MemberType Noteproperty -Value $Json[$Device].stb.product
                $DeviceLine | Add-Member -Name 'STB - Serial'                 -MemberType Noteproperty -Value $Json[$Device].stb.serial
            }
            Else {
                $DeviceLine | Add-Member -Name 'STB - Product'                -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'STB - Serial'                 -MemberType Noteproperty -Value ''
            }
            
            $DeviceLine | Add-Member -Name 'IPV4 Date First Connexion'        -MemberType Noteproperty -Value $($($($Json[$Device].firstseen).replace("T"," ")).replace("+0100",""))
            $DeviceLine | Add-Member -Name 'IPV4 Date Last Connexion'         -MemberType Noteproperty -Value $(Get-Date).AddSeconds(-$Json[$Device].lastseen)
            
            # If IPV6 part
            If (-not ([string]::IsNullOrEmpty($Json[$Device].ip6address))) {
                
                $DeviceLine | Add-Member -Name 'IPV6 Address'                 -MemberType Noteproperty -Value $($Json[$Device].ip6address.ipaddress -join ',')
                $DeviceLine | Add-Member -Name 'IPV6 Statut'                  -MemberType Noteproperty -Value $($Json[$Device].ip6address.status -join ',')
                $DeviceLine | Add-Member -Name 'IPV6 First Connexion Date'    -MemberType Noteproperty -Value $($($(Get-Date).AddSeconds($($Json[$Device].ip6address.lastseen).replace("T"," ")).replace("+0100","")) -join ',')
                $DeviceLine | Add-Member -Name 'IPV6 Last Connexion Date'     -MemberType Noteproperty -Value $($($($($Json[$Device].ip6address.lastscan).replace("T"," ")).replace("+0100","")) -join ',')
            }
            Else {
                $DeviceLine | Add-Member -Name 'IPV6 Address'                 -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'IPV6 Statut'                  -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'IPV6 First Connexion Date'    -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'IPV6 Last Connexion Date'     -MemberType Noteproperty -Value ''
            }
            
            $DeviceLine | Add-Member -Name 'Physical Port'                    -MemberType Noteproperty -Value $Json[$Device].ethernet.physicalport
            $DeviceLine | Add-Member -Name 'Logical Port'                     -MemberType Noteproperty -Value $Json[$Device].ethernet.logicalport
            $DeviceLine | Add-Member -Name 'Speed Connexion'                  -MemberType Noteproperty -Value $Json[$Device].ethernet.speed
            $DeviceLine | Add-Member -Name 'Mode'                             -MemberType Noteproperty -Value $Json[$Device].ethernet.mode
            $DeviceLine | Add-Member -Name 'Band'                             -MemberType Noteproperty -Value $Json[$Device].wireless.band
            $DeviceLine | Add-Member -Name 'RSSIO'                            -MemberType Noteproperty -Value $Json[$Device].wireless.rssi0
            $DeviceLine | Add-Member -Name 'RSSI1'                            -MemberType Noteproperty -Value $Json[$Device].wireless.rssi1
            $DeviceLine | Add-Member -Name 'RSSI2'                            -MemberType Noteproperty -Value $Json[$Device].wireless.rssi2
            $DeviceLine | Add-Member -Name 'MSC'                              -MemberType Noteproperty -Value $Json[$Device].wireless.mcs
            $DeviceLine | Add-Member -Name 'Rate'                             -MemberType Noteproperty -Value $Json[$Device].wireless.rate
            $DeviceLine | Add-Member -Name 'Idle'                             -MemberType Noteproperty -Value $Json[$Device].wireless.idle
            $DeviceLine | Add-Member -Name 'WexIndex'                         -MemberType Noteproperty -Value $Json[$Device].wireless.wexindex
            $DeviceLine | Add-Member -Name 'Starealmac'                       -MemberType Noteproperty -Value $Json[$Device].wireless.starealmac
            $DeviceLine | Add-Member -Name 'Wireless Static'                  -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Device].wireless.static)
            $DeviceLine | Add-Member -Name 'RXPhyrate'                        -MemberType Noteproperty -Value $Json[$Device].plc.rxphyrate
            $DeviceLine | Add-Member -Name 'TXPhyrate'                        -MemberType Noteproperty -Value $Json[$Device].plc.txphyrate
            $DeviceLine | Add-Member -Name 'Associated Device'                -MemberType Noteproperty -Value $Json[$Device].plc.associateddevice
            $DeviceLine | Add-Member -Name 'Interface'                        -MemberType Noteproperty -Value $Json[$Device].plc.interface
            $DeviceLine | Add-Member -Name 'Ethernet Speed'                   -MemberType Noteproperty -Value $Json[$Device].plc.ethernetspeed
            $DeviceLine | Add-Member -Name 'DHCP Bail'                        -MemberType Noteproperty -Value $Json[$Device].lease
            $DeviceLine | Add-Member -Name 'Is Active ?'                      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Device].active)
            $DeviceLine | Add-Member -Name 'Parental Control - State'         -MemberType Noteproperty -Value (Get-state -State $Json[$Device].parentalcontrol.enable)
            $DeviceLine | Add-Member -Name 'Parental Control - Status'        -MemberType Noteproperty -Value (Get-Status -Status $Json[$Device].parentalcontrol.status)
            $DeviceLine | Add-Member -Name 'Parental Control - Last Time Status' -MemberType Noteproperty -Value $(Get-Date).AddSeconds(-$Json[$Device].parentalcontrol.statusRemaining)
            $DeviceLine | Add-Member -Name 'Parental Control - Next Time Status' -MemberType Noteproperty -Value $Json[$Device].parentalcontrol.statusUntil
            $DeviceLine | Add-Member -Name 'Average Ping'                     -MemberType Noteproperty -Value $Json[$Device].ping.average
            $DeviceLine | Add-Member -Name 'Detected Active Services'         -MemberType Noteproperty -Value $($Json[$Device].scan.services -join ',')
            
            <# If Services part
            If (-not ([string]::IsNullOrEmpty($Json[$Device].scan.services))) {
                
                $DeviceLine | Add-Member -Name 'Detected Protocol'            -MemberType Noteproperty -Value $Json[$Device].scan.services.protocol
                $DeviceLine | Add-Member -Name 'Detected Port'                -MemberType Noteproperty -Value $Json[$Device].scan.services.port
                $DeviceLine | Add-Member -Name 'Port State'                   -MemberType Noteproperty -Value $Json[$Device].scan.services.state
                $DeviceLine | Add-Member -Name 'Reason'                       -MemberType Noteproperty -Value $Json[$Device].scan.services.reason
            }
            Else {
                $DeviceLine | Add-Member -Name 'Detected Protocol'            -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'Detected Port'                -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'Port State'                   -MemberType Noteproperty -Value ''
                $DeviceLine | Add-Member -Name 'Reason'                       -MemberType Noteproperty -Value ''
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

Function Get-HOSTSID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $HostIDs = Get-HOSTS -UrlToGo $UrlToGo -APIName $APIName
    $HostID = $HostIDs | Select-Object ID,Hostname | Out-GridView -Title "Hosts List" -OutputMode Single
    $MachineID = $HostIDs | Where-Object {$_.ID -ilike $HostID.id}
    
    Return $MachineID
}

Function Get-HOSTSME {
    
    Param (
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
        $DeviceLine | Add-Member -Name 'IPV4 Date last connexion'     -MemberType Noteproperty -Value $(Get-Date).AddSeconds(-$Json.lastseen)
    }
    Else {
        $DeviceLine | Add-Member -Name 'IPV4 Date last connexion'     -MemberType Noteproperty -Value $Json.lastseen
    }

    # If IPV6 part
    If (-not ([string]::IsNullOrEmpty($Json.ip6address))) {
        
        $IPV6Line = 0
        $IPAddress = ''
        $Lastseen = ''
        $Lastscan = ''
        $Status = ''
        
        While ($IPV6Line -ne $Json.ip6address.count) {
            
            $IPAddress += "$($Json.ip6address[$IPV6Line].ipaddress);"
            $Status    += "$($Json.ip6address[$IPV6Line].status);"
            $Lastseen  += "$(($Json.ip6address[$IPV6Line].lastseen).Replace('T',' '));"
            $Lastscan  += "$(($Json.ip6address[$IPV6Line].lastscan).Replace('T',' '));"
            
            # Go to next line
            $IPV6Line ++
        }
        
        $DeviceLine | Add-Member -Name 'IPV6 Address'                 -MemberType Noteproperty -Value $IPAddress
        $DeviceLine | Add-Member -Name 'IPV6 Statut'                  -MemberType Noteproperty -Value $Status
        $DeviceLine | Add-Member -Name 'IPV6 First Connexion Date'    -MemberType Noteproperty -Value $Lastseen
        $DeviceLine | Add-Member -Name 'IPV6 Last Connexion Date'     -MemberType Noteproperty -Value $Lastscan
    }
    Else {
        $DeviceLine | Add-Member -Name 'IPV6 Address'                 -MemberType Noteproperty -Value ''
        $DeviceLine | Add-Member -Name 'IPV6 Statut'                  -MemberType Noteproperty -Value ''
        $DeviceLine | Add-Member -Name 'IPV6 First Connexion Date'    -MemberType Noteproperty -Value ''
        $DeviceLine | Add-Member -Name 'IPV6 Last Connexion Date'     -MemberType Noteproperty -Value ''
    }
    
    $DeviceLine | Add-Member -Name 'Physical Port'                    -MemberType Noteproperty -Value $Json.ethernet.physicalport
    $DeviceLine | Add-Member -Name 'Logical Port'                     -MemberType Noteproperty -Value $Json.ethernet.logicalport
    $DeviceLine | Add-Member -Name 'Speed connexion'                  -MemberType Noteproperty -Value $Json.ethernet.speed
    $DeviceLine | Add-Member -Name 'Mode'                             -MemberType Noteproperty -Value $Json.ethernet.mode
    $DeviceLine | Add-Member -Name 'Band'                             -MemberType Noteproperty -Value $Json.wireless.band
    $DeviceLine | Add-Member -Name 'RSSIO'                            -MemberType Noteproperty -Value $Json.wireless.rssi0
    $DeviceLine | Add-Member -Name 'RSSI1'                            -MemberType Noteproperty -Value $Json.wireless.rssi1
    $DeviceLine | Add-Member -Name 'RSSI2'                            -MemberType Noteproperty -Value $Json.wireless.rssi2
    $DeviceLine | Add-Member -Name 'MSC'                              -MemberType Noteproperty -Value $Json.wireless.mcs
    $DeviceLine | Add-Member -Name 'Rate'                             -MemberType Noteproperty -Value $Json.wireless.rate
    $DeviceLine | Add-Member -Name 'Idle'                             -MemberType Noteproperty -Value $Json.wireless.idle
    $DeviceLine | Add-Member -Name 'wexindex'                         -MemberType Noteproperty -Value $Json.wireless.wexindex
    $DeviceLine | Add-Member -Name 'Wireless Static'                  -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Device].wireless.static)
    $DeviceLine | Add-Member -Name 'RXPhyrate'                        -MemberType Noteproperty -Value $Json.plc.rxphyrate
    $DeviceLine | Add-Member -Name 'TXPhyrate'                        -MemberType Noteproperty -Value $Json.plc.txphyrate
    $DeviceLine | Add-Member -Name 'Associated Device'                -MemberType Noteproperty -Value $Json.plc.associateddevice
    $DeviceLine | Add-Member -Name 'Interface'                        -MemberType Noteproperty -Value $Json.plc.interface
    $DeviceLine | Add-Member -Name 'Ethernet Speed'                   -MemberType Noteproperty -Value $Json.plc.ethernetspeed
    $DeviceLine | Add-Member -Name 'Parental Control - State'         -MemberType Noteproperty -Value (Get-State -State $Json.parentalcontrol.enable)
    $DeviceLine | Add-Member -Name 'Parental Control - Status'        -MemberType Noteproperty -Value (Get-Status -Status $Json.parentalcontrol.status)
    If ($Json.parentalcontrol.statusRemaining -ne 0) {
        $DeviceLine | Add-Member -Name 'Parental Control - Last Time Status' -MemberType Noteproperty -Value $(Get-Date).AddSeconds(-$Json.parentalcontrol.statusRemaining)
    }
    Else {
        $DeviceLine | Add-Member -Name 'Parental Control - Last Time Status' -MemberType Noteproperty -Value $Json.parentalcontrol.statusRemaining
    }
    $DeviceLine | Add-Member -Name 'Parental Control - Next Time Status' -MemberType Noteproperty -Value $Json.parentalcontrol.statusUntil
    $DeviceLine | Add-Member -Name 'DHCP Bail'                        -MemberType Noteproperty -Value $Json.lease
    $DeviceLine | Add-Member -Name 'First Connexion Date'             -MemberType Noteproperty -Value $Json.firstSeen
    If ($Json.lastSeen -ne 0) {
        $DeviceLine | Add-Member -Name 'Last Connexion Date'          -MemberType Noteproperty -Value $(Get-Date).AddSeconds(-$Json.lastSeen)
    }
    Else {
        $DeviceLine | Add-Member -Name 'Last Connexion Date'          -MemberType Noteproperty -Value $Json.lastSeen
    }
    $DeviceLine | Add-Member -Name 'Is Active ?'                      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.active)
    $DeviceLine | Add-Member -Name 'Ping Min'                         -MemberType Noteproperty -Value $Json.ping.min
    $DeviceLine | Add-Member -Name 'Ping Max'                         -MemberType Noteproperty -Value $Json.ping.max
    $DeviceLine | Add-Member -Name 'Ping Average'                     -MemberType Noteproperty -Value $Json.ping.average
    $DeviceLine | Add-Member -Name 'Ping Success'                     -MemberType Noteproperty -Value $Json.ping.success
    $DeviceLine | Add-Member -Name 'Ping Error'                       -MemberType Noteproperty -Value $Json.ping.error
    $DeviceLine | Add-Member -Name 'Ping Tries'                       -MemberType Noteproperty -Value $Json.ping.tries
    If ($Json.ping.status) {
        $DeviceLine | Add-Member -Name 'Ping status'                  -MemberType Noteproperty -Value (Get-Status -Status $Json.ping.status)
    }
    Else {
        $DeviceLine | Add-Member -Name 'Ping status'                  -MemberType Noteproperty -Value $Json.ping.status
    }
    $DeviceLine | Add-Member -Name 'Ping Result'                      -MemberType Noteproperty -Value $Json.ping.result
    If ($Json.scan.status) {
        $DeviceLine | Add-Member -Name 'Scan Status'                  -MemberType Noteproperty -Value (Get-Status -Status $Json.scan.status)
    }
    Else {
        $DeviceLine |Add-Member -Name 'Scan Status'                   -MemberType Noteproperty -Value $Json.scan.status
    }
    $DeviceLine | Add-Member -Name 'Scan State'                       -MemberType Noteproperty -Value (Get-State -State $Json.scan.enable)
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
    
    Return $Array
}

Function Get-HOSTSLite {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-HOSTSPAUTH {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-IPTV {
    
    Param (
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

Function Get-IPTVDiags {
    
    Param (
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
    $IPTVDiagsLine | Add-Member -Name 'Date'                 -MemberType Noteproperty -Value $Json.now # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name 'IGMP State'           -MemberType Noteproperty -Value (Get-State -State $Json.igmp.state) # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name 'IGMP Status'          -MemberType Noteproperty -Value (Get-Status -Status $Json.igmp.enable) # Not present in doc : https://api.bbox.fr/doc/apirouter/index.html#api-Services-GetIPTVDiag
    $IPTVDiagsLine | Add-Member -Name 'IPTV Multicast State' -MemberType Noteproperty -Value (Get-State -State $Json.iptv.multicast.state)
    $IPTVDiagsLine | Add-Member -Name 'IPTV Multicast Date'  -MemberType Noteproperty -Value $Json.iptv.multicast.date
    $IPTVDiagsLine | Add-Member -Name 'IPTV Platform State'  -MemberType Noteproperty -Value (Get-State -State $Json.iptv.platform.state)
    $IPTVDiagsLine | Add-Member -Name 'IPTV Platform Date'   -MemberType Noteproperty -Value $Json.iptv.platform.date
    
    # Add lines to $Array
    $Array += $IPTVDiagsLine
    
    Return $Array
}

#endregion IPTV

#region LAN

Function Get-LANIP {
    
    Param (
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
    $dns = $(Resolve-DnsName -Name $Json.ip.ipaddress -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost
    
    $IPLine = New-Object -TypeName PSObject
    $IPLine | Add-Member -Name 'State'                           -MemberType Noteproperty -Value (Get-State -State $Json.ip.state)
    $IPLine | Add-Member -Name 'MTU (Maximum transmission unit)' -MemberType Noteproperty -Value $Json.ip.mtu
    $IPLine | Add-Member -Name 'IPV4 Address'                    -MemberType Noteproperty -Value $Json.ip.ipaddress
    $IPLine | Add-Member -Name 'IPV4 NetMask'                    -MemberType Noteproperty -Value $Json.ip.netmask
    $IPLine | Add-Member -Name 'HostName'                        -MemberType Noteproperty -Value $dns
    $IPLine | Add-Member -Name 'IPV6 Statut'                     -MemberType Noteproperty -Value (Get-Status -Status $Json.ip.ip6enable)
    $IPLine | Add-Member -Name 'IPV6 State'                      -MemberType Noteproperty -Value (Get-State -State $Json.ip.ip6state)
    $IPV6Line = 0
    $IPV6Params = ''
    While ($IPV6Line -lt $json.ip.ip6address.Count) {
        
        $IPV6Params += "$($Json.ip.ip6address[$IPV6Line].ipaddress),$($Json.ip.ip6address[$IPV6Line].status),$($Json.ip.ip6address[$IPV6Line].valid),$($Json.ip.ip6address[$IPV6Line].preferred);"
        
        # Go to next line
        $IPV6Line ++
    }
    $IPLine | Add-Member -Name 'IPV6 Address'                    -MemberType Noteproperty -Value $IPV6Params
    $IPLine | Add-Member -Name 'IPV6 Prefix'                     -MemberType Noteproperty -Value $Json.ip.ip6prefix.prefix
    $IPLine | Add-Member -Name 'IPV6 Prefix Status'              -MemberType Noteproperty -Value $Json.ip.ip6prefix.status
    If (-not ([string]::IsNullOrEmpty($Json.ip.ip6prefix.valid))) {
        $IPLine | Add-Member -Name 'IPV6 Prefix Valid'           -MemberType Noteproperty -Value $Json.ip.ip6prefix.valid
    }
    If (-not ([string]::IsNullOrEmpty($Json.ip.ip6prefix.preferred))) {
        $IPLine | Add-Member -Name 'IPV6 Prefix Preferred'       -MemberType Noteproperty -Value $Json.ip.ip6prefix.preferred
    }
    $IPLine | Add-Member -Name 'MAC Address'                     -MemberType Noteproperty -Value $Json.ip.mac
    $IPLine | Add-Member -Name 'BBOX Hostname'                   -MemberType Noteproperty -Value $Json.ip.hostname
    $IPLine | Add-Member -Name 'BBOX Domain'                     -MemberType Noteproperty -Value $Json.ip.domain
    $IPLine | Add-Member -Name 'BBOX Alias (DNS)'                -MemberType Noteproperty -Value $Json.ip.aliases.replace(' ',',')
    
    $IP += $IPLine
    
    # Switch Part
    $Port = 0
    
    While ($Port -lt $json.switch.ports.Count) {
        
        # Create New PSObject and add values to array
        $PortLine = New-Object -TypeName PSObject
        $PortLine | Add-Member -Name 'Port number'  -MemberType Noteproperty -Value $Json.switch.ports[$Port].id
        $PortLine | Add-Member -Name 'State'        -MemberType Noteproperty -Value $Json.switch.ports[$Port].state
        $PortLine | Add-Member -Name 'Link Mode'    -MemberType Noteproperty -Value $Json.switch.ports[$Port].link_mode
        $PortLine | Add-Member -Name 'Is Blocked ?' -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.switch.ports[$Port].blocked)
        $PortLine | Add-Member -Name 'Flickering ?' -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.switch.ports[$Port].flickering)
        
        $Switch += $PortLine
        
        # Go to next line
        $Port ++
    }
    
    Return $IP, $Switch
}

Function Get-LANStats {
    
    Param (
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

Function Get-LANAlerts {

    Param (
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
                
                ALERT_LAN_API_LOCKED             {$Details = "IP Address Source : $($Params[0]), Hostname : $($Params[3]), Failed Attempt Time : $($Params[1]), Block Time : $($Params[2]) min";Break}
                
                ALERT_LAN_OFFLINE_IP             {$Details = "IP Address Source : $($Params[0]), Hostname : $($Params[2]), IP Address destination : $($Params[1])";Break}
                
                ALERT_LAN_PORT_UP                {$Details = "BBox Switch Port : $($Json[$Line].param)";Break}
                
                ALERT_LAN_UNKNOWN_IP             {$Details = "IP Address : $($Params[0]), Associated Hostname : $($Params[2]), IP Address in conflit : $($Params[1])";Break}
                
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
            $AlertLine | Add-Member -Name 'ID'                 -MemberType Noteproperty -Value $Json[$Line].id
            $AlertLine | Add-Member -Name 'Alert type'         -MemberType Noteproperty -Value $Json[$Line].ident
            $AlertLine | Add-Member -Name 'Details'            -MemberType Noteproperty -Value $Details # Calculate field not inclued in API
            $AlertLine | Add-Member -Name 'First Date seen'    -MemberType Noteproperty -Value $Json[$Line].first_date
            $AlertLine | Add-Member -Name 'Last Date seen'     -MemberType Noteproperty -Value $Json[$Line].last_date
            $AlertLine | Add-Member -Name 'Recovery Date'      -MemberType Noteproperty -Value $RecoveryDate
            $AlertLine | Add-Member -Name 'Nb Occurences'      -MemberType Noteproperty -Value $Json[$Line].count
            $AlertLine | Add-Member -Name 'Solved Time'        -MemberType Noteproperty -Value $SolvedTime # Calculate filed not inclued in API
            $AlertLine | Add-Member -Name 'Notification Level' -MemberType Noteproperty -Value $Json[$Line].level
            
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

Function Get-NAT {
    
    Param (
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
    $NATLine | Add-Member -Name 'Service'              -MemberType Noteproperty -Value 'NAT/PAT'
    $NATLine | Add-Member -Name 'Status'               -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $NATLine | Add-Member -Name 'Nb configured Rules'  -MemberType Noteproperty -Value $Json.rules.count
    
    # Add lines to $Array
    $Array += $NATLine
    
    Return $Array
}

Function Get-NATDMZ {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.nat.dmz
    
    If ($Json.ipaddress) {
        $dns = $(Resolve-DnsName -Name $Json.ipaddress -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost
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

Function Get-NATRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.nat.rules
    
    If ($Json.count -ne 0) {
        
        $NAT = 0
        
        While ($NAT -lt $Json.count) {
            
            # Create New PSObject and add values to array
            $NATLine = New-Object -TypeName PSObject
            $NATLine | Add-Member -Name 'ID'                  -MemberType Noteproperty -Value $Json[$NAT].id
            $NATLine | Add-Member -Name 'Status'              -MemberType Noteproperty -Value $(Get-Status -Status $Json[$NAT].enable)
            $NATLine | Add-Member -Name 'Description'         -MemberType Noteproperty -Value $Json[$NAT].description
            $NATLine | Add-Member -Name 'External IP Address' -MemberType Noteproperty -Value $Json[$NAT].externalip
            $NATLine | Add-Member -Name 'External Port'       -MemberType Noteproperty -Value $Json[$NAT].externalport
            $NATLine | Add-Member -Name 'Internal Port'       -MemberType Noteproperty -Value $Json[$NAT].internalport
            $NATLine | Add-Member -Name 'Internal IP Address' -MemberType Noteproperty -Value $Json[$NAT].internalip
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

Function Get-NATRulesID {
    
    Param (
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

Function Get-NOTIFICATIONConfig {
    
    Param (
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
    $NOTIFICATIONLine | Add-Member -Name 'Service'                -MemberType Noteproperty -Value $APIName
    $NOTIFICATIONLine | Add-Member -Name 'State'                  -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $NOTIFICATIONLine | Add-Member -Name 'Nb configured Alerts'   -MemberType Noteproperty -Value $Json.alerts.count
    $NOTIFICATIONLine | Add-Member -Name 'Nb configured Events'   -MemberType Noteproperty -Value $Json.events.count
    $NOTIFICATIONLine | Add-Member -Name 'Nb configured Contacts' -MemberType Noteproperty -Value $Json.contacts.count
    
    # Add lines to $Array
    $Array += $NOTIFICATIONLine
    
    Return $Array
}

Function Get-NOTIFICATIONConfigAlerts {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.notification.Alerts
    
    If ($Json.Count -ne 0) {
        
        $NOTIFICATION = 0
        
        While ($NOTIFICATION -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $NOTIFICATIONLine = New-Object -TypeName PSObject
            $NOTIFICATIONLine | Add-Member -Name 'ID'              -MemberType Noteproperty -Value $Json[$NOTIFICATION].id
            $NOTIFICATIONLine | Add-Member -Name 'State'           -MemberType Noteproperty -Value (Get-State -State $Json[$NOTIFICATION].enable)
            $NOTIFICATIONLine | Add-Member -Name 'Name'            -MemberType Noteproperty -Value $Json[$NOTIFICATION].name # To be review due to syntaxe
            $NOTIFICATIONLine | Add-Member -Name 'Events'          -MemberType Noteproperty -Value $Json[$NOTIFICATION].events
            $NOTIFICATIONLine | Add-Member -Name 'Action Type'     -MemberType Noteproperty -Value $Json[$NOTIFICATION].action.type
            $NOTIFICATIONLine | Add-Member -Name 'Send Mail Delay' -MemberType Noteproperty -Value $Json[$NOTIFICATION].action.delay
            $NOTIFICATIONLine | Add-Member -Name 'Contact ID'      -MemberType Noteproperty -Value $Json[$NOTIFICATION].action.mail.dests
            
            # Add lines to $Array
            $Array += $NOTIFICATIONLine
            
            # Go to next line
            $NOTIFICATION ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-NOTIFICATIONConfigContacts {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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
            $ContactsLine | Add-Member -Name 'Mail'  -MemberType Noteproperty -Value $Json[$Contacts].mail
            $ContactsLine | Add-Member -Name 'Name'  -MemberType Noteproperty -Value $Json[$Contacts].name
            
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

Function Get-NOTIFICATIONConfigEvents {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.notification.events
    
    If ($Json.Count -ne 0) {
        
        $Events = 0
        
        While ($Events -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $EventsLine = New-Object -TypeName PSObject
            $EventsLine | Add-Member -Name 'Name'        -MemberType Noteproperty -Value $($Json[$Events].name)
            $EventsLine | Add-Member -Name 'Category'    -MemberType Noteproperty -Value $($Json[$Events].category) # Syntaxe to be reviewed
            $EventsLine | Add-Member -Name 'Description' -MemberType Noteproperty -Value $($Json[$Events].description) # Syntaxe to be reviewed
            $EventsLine | Add-Member -Name 'Message'     -MemberType Noteproperty -Value $($Json[$Events].humanReadable) # Syntaxe to be reviewed
            
            # Add lines to $Array
            $Array += $EventsLine
            
            # Go to next line
            $Events ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-NOTIFICATIONAlerts {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.notification.Alerts
    
    If ($Json.Count -ne 0) {
        
        $NOTIFICATION = 0
        
        While ($NOTIFICATION -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $NOTIFICATIONLine = New-Object -TypeName PSObject
            $NOTIFICATIONLine | Add-Member -Name 'ID'              -MemberType Noteproperty -Value $Json[$NOTIFICATION].id
            $NOTIFICATIONLine | Add-Member -Name 'State'           -MemberType Noteproperty -Value (Get-State -State $Json[$NOTIFICATION].enable)
            $NOTIFICATIONLine | Add-Member -Name 'Name'            -MemberType Noteproperty -Value $Json[$NOTIFICATION].name # To be review due to syntaxe
            $NOTIFICATIONLine | Add-Member -Name 'Events'          -MemberType Noteproperty -Value $Json[$NOTIFICATION].events
            $NOTIFICATIONLine | Add-Member -Name 'Action Type'     -MemberType Noteproperty -Value $Json[$NOTIFICATION].action.type
            $NOTIFICATIONLine | Add-Member -Name 'Send Mail Delay' -MemberType Noteproperty -Value $Json[$NOTIFICATION].action.delay
            $NOTIFICATIONLine | Add-Member -Name 'Contact ID'      -MemberType Noteproperty -Value $Json[$NOTIFICATION].action.mail.dests
            
            # Add lines to $Array
            $Array += $NOTIFICATIONLine
            
            # Go to next line
            $NOTIFICATION ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

Function Get-NOTIFICATIONContacts {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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
            $ContactsLine | Add-Member -Name 'Mail'  -MemberType Noteproperty -Value $Json[$Contacts].mail
            $ContactsLine | Add-Member -Name 'Name'  -MemberType Noteproperty -Value $Json[$Contacts].name
            
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

Function Get-NOTIFICATIONEvents {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.notification.events
    
    If ($Json.Count -ne 0) {
        
        $Events = 0
        
        While ($Events -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $EventsLine = New-Object -TypeName PSObject
            $EventsLine | Add-Member -Name 'Name'        -MemberType Noteproperty -Value $($Json[$Events].name)
            $EventsLine | Add-Member -Name 'Category'    -MemberType Noteproperty -Value $($Json[$Events].category) # Syntaxe to be reviewed
            $EventsLine | Add-Member -Name 'Description' -MemberType Noteproperty -Value $($Json[$Events].description) # Syntaxe to be reviewed
            $EventsLine | Add-Member -Name 'Message'     -MemberType Noteproperty -Value $($Json[$Events].humanReadable) # Syntaxe to be reviewed
            
            # Add lines to $Array
            $Array += $EventsLine
            
            # Go to next line
            $Events ++
        }
        
        Return $Array
    }
    Else {
        Return $null
    }
}

#endregion Notification

#region PARENTAL CONTROL

Function Get-ParentalControl {
    
    Param (
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
    $ParentalControlLine | Add-Member -Name 'Service'        -MemberType Noteproperty -Value 'Parental Control'
    $ParentalControlLine | Add-Member -Name 'Date'           -MemberType Noteproperty -Value $Json.now
    $ParentalControlLine | Add-Member -Name 'State'          -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $ParentalControlLine | Add-Member -Name 'Default Policy' -MemberType Noteproperty -Value $Json.defaultpolicy
    
    # Add lines to $Array
    $Array += $ParentalControlLine
    
    Return $Array
}

Function Get-ParentalControlScheduler {
    
    Param (
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
    $SchedulerLine | Add-Member -Name 'Service'     -MemberType Noteproperty -Value 'Parental Control Scheduler'
    $SchedulerLine | Add-Member -Name 'Date'        -MemberType Noteproperty -Value $Json.now
    $SchedulerLine | Add-Member -Name 'State'       -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $SchedulerLine | Add-Member -Name 'Rules count' -MemberType Noteproperty -Value $Json.rules.count
    
    # Add lines to $Array
    $Array += $SchedulerLine
    
    # Go to next line
    $Scheduler ++
    
    Return $Array
}

Function Get-ParentalControlSchedulerRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-ProfileConsumption {
    
    Param (
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
    $ProfileLine | Add-Member -Name 'Service'  -MemberType Noteproperty -Value 'Profile'
    $ProfileLine | Add-Member -Name 'Login'    -MemberType Noteproperty -Value $($Json.login)
    $ProfileLine | Add-Member -Name 'Password' -MemberType Noteproperty -Value '*************'
    
    # Add lines to $Array
    $Array += $ProfileLine
    
    Return $Array
}

#endregion PROFILE

#region REMOTE

Function Get-REMOTEProxyWOL {
    
    Param (
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
    $ProfileLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'Remote Proxy WOL'
    $ProfileLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $ProfileLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    
    # Add lines to $Array
    $Array += $ProfileLine
    
    Return $Array
}

#endregion REMOTE

#region SERVICES

Function Get-SERVICES {
    
    Param (
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
    
    # ADMIN / BBOX REMOTE ACCESS
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
    $ServiceLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value ''
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

Function Get-SUMMARY {
    
    Param (
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
    While ($I -lt $Json.iptv.count) {
        $IPTV += "Source IP Address : $($Json.iptv[$I].address), Destination IP Address : $($Json.iptv[$I].ipaddress), Reception en cours : $($Json.iptv[$I].receipt), Channel Number : $($Json.iptv[$I].number)"
        
        # Go to next line
        $I++
    }
    $IPTV = $IPTV -join ';'
    
    # USB Printers list
    $J = 0
    $Printer = @()
    While ($J -lt $Json.usb.printer.count) {
        $Printer += "Name : $($Json.usb.printer[$J].product), State : $($Json.usb.printer[$J].state)"
        
        # Go to next line
        $J++
    }
    $Printer = $Printer -join ';'
    
    # USB Samba Storage
    $K = 0
    $Storage = @()
    While ($k -lt $Json.usb.storage.count) {
        $Storage += "Label : $($Json.usb.storage[$K].label), State : $($Json.usb.storage[$K].state)"
        
        # Go to next line
        $K++
    }
    $Storage = $Storage -join ';'
    
    # Hosts List
    $L = 0
    $Hosts = @()
    While ($L -lt $Json.hosts.count) {
        $Hosts += "Hostname : $($Json.hosts[$L].hostname), IP address : $($Json.hosts[$L].ipaddress)"
        
        # Go to next line
        $L++
    }
    $Hosts = $Hosts -join ';'
    
    # StatusRemaning
    $ParentalControlStatusRemaining = New-TimeSpan -Seconds $Json.services.parentalcontrol.statusRemaining
    $WifiSchedulerStatusRemaining   = New-TimeSpan -Seconds $Json.services.wifischeduler.statusRemaining
    $VOIPSchedulerStatusRemaining   = New-TimeSpan -Seconds $Json.services.voipscheduler.statusRemaining
    
    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name 'Date'                              -MemberType Noteproperty -Value $Json.now
    $DeviceLine | Add-Member -Name 'User Authenticated State'          -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.authenticated)
    $DeviceLine | Add-Member -Name 'Luminosity State'                  -MemberType Noteproperty -Value (Get-State -State $Json.display.state)
    $DeviceLine | Add-Member -Name 'Luminosity Power (%)'              -MemberType Noteproperty -Value $Json.display.luminosity
    $DeviceLine | Add-Member -Name 'Internet State'                    -MemberType Noteproperty -Value (Get-State -State $Json.internet.state)
    $DeviceLine | Add-Member -Name 'VOIP Status'                       -MemberType Noteproperty -Value (Get-Status -Status $Json.voip[0].status)
    $DeviceLine | Add-Member -Name 'VOIP Call State'                   -MemberType Noteproperty -Value $Json.voip[0].callstate
    $DeviceLine | Add-Member -Name 'VOIP Message count'                -MemberType Noteproperty -Value $Json.voip[0].message
    $DeviceLine | Add-Member -Name 'VOIP Call failed'                  -MemberType Noteproperty -Value $Json.voip[0].notanswered
    $DeviceLine | Add-Member -Name 'IPTV Device List'                  -MemberType Noteproperty -Value $iptv
    $DeviceLine | Add-Member -Name 'USB Printer'                       -MemberType Noteproperty -Value $Printer
    $DeviceLine | Add-Member -Name 'USB Storage'                       -MemberType Noteproperty -Value $Storage
    $DeviceLine | Add-Member -Name 'Wireless Status'                   -MemberType Noteproperty -Value $Json.wireless.status
    $DeviceLine | Add-Member -Name 'Wireless Channel'                  -MemberType Noteproperty -Value $Json.wireless.radio
    $DeviceLine | Add-Member -Name 'Wireless Change Date'              -MemberType Noteproperty -Value $Json.wireless.changedate
    $DeviceLine | Add-Member -Name 'WPS 2,4Ghz '                       -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps.'24'.available)
    $DeviceLine | Add-Member -Name 'WPS 5,2Ghz'                        -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps.'5'.available)
    $DeviceLine | Add-Member -Name 'WPS State'                         -MemberType Noteproperty -Value (Get-State -State $Json.wireless.wps.enable)
    $DeviceLine | Add-Member -Name 'WPS Status'                        -MemberType Noteproperty -Value $Json.wireless.wps.status
    $DeviceLine | Add-Member -Name 'WPS Timeout'                       -MemberType Noteproperty -Value $Json.wireless.wps.timeout
    $DeviceLine | Add-Member -Name 'Wifi Hotspot State'                -MemberType Noteproperty -Value (Get-State -State $Json.services.hotspot.enable)
    $DeviceLine | Add-Member -Name 'Firewall State'                    -MemberType Noteproperty -Value (Get-State -State $Json.services.firewall.enable)
    $DeviceLine | Add-Member -Name 'DYNDNS State'                      -MemberType Noteproperty -Value (Get-State -State $Json.services.dyndns.enable)
    $DeviceLine | Add-Member -Name 'DHCP State'                        -MemberType Noteproperty -Value (Get-State -State $Json.services.dhcp.enable)
    $DeviceLine | Add-Member -Name 'NAT State'                         -MemberType Noteproperty -Value "$(Get-State -State $Json.services.nat.enable), Active Rules : $($Json.services.nat.enable)"
    $DeviceLine | Add-Member -Name 'DMZ State'                         -MemberType Noteproperty -Value (Get-State -State $Json.services.dmz.enable)
    $DeviceLine | Add-Member -Name 'NATPAT State'                      -MemberType Noteproperty -Value (Get-State -State $Json.services.natpat.enable)
    $DeviceLine | Add-Member -Name 'UPNP/IGD State'                    -MemberType Noteproperty -Value (Get-State -State $Json.services.upnp.igd.enable)
    $DeviceLine | Add-Member -Name 'Notification State'                -MemberType Noteproperty -Value "$(Get-State -State $Json.services.notification.enable), Active Notifications Rules : $($Json.services.notification.enable)"
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
    $DeviceLine | Add-Member -Name 'WAN IPV4'                          -MemberType Noteproperty -Value (Get-State -State $Json.wan.ip.state.ip)
    $DeviceLine | Add-Member -Name 'WAN IPV6'                          -MemberType Noteproperty -Value (Get-State -State $Json.wan.ip.state.ipv6)
    $DeviceLine | Add-Member -Name 'WAN IP stats Tx Occupation'        -MemberType Noteproperty -Value $Json.wan.ip.stats.tx.occupation
    $DeviceLine | Add-Member -Name 'WAN IP stats Rx Occupation'        -MemberType Noteproperty -Value $Json.wan.ip.stats.rx.occupation
    $DeviceLine | Add-Member -Name 'Nb Alerts'                         -MemberType Noteproperty -Value $Json.alerts.count
    $DeviceLine | Add-Member -Name 'Nb CPL'                            -MemberType Noteproperty -Value $Json.cpl.count

    # Add lines to $Array
    $Array += $DeviceLine
    
    Return $Array
}

#endregion SUMMARY

#region UPNP/IGD

Function Get-UPNPIGD {
    
    Param (
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
    $EventsLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'UPNP/IGD'
    $EventsLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $EventsLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $EventsLine | Add-Member -Name 'UUID'    -MemberType Noteproperty -Value $Json.uuid
    $EventsLine | Add-Member -Name 'Name'    -MemberType Noteproperty -Value $Json.friendlyname
    
    # Add lines to $Array
    $Array += $EventsLine
    
    Return $Array
}

Function Get-UPNPIGDRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    If ($Json.Count -ne 0) {
    
        # Create array
        $Array = @()
        
        # Select $JSON header
        $Json = $Json.upnp.igd.rules
        
        $Rule = 0
        
        While ($Rule -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $RuleLine = New-Object -TypeName PSObject
            $RuleLine | Add-Member -Name 'ID'                  -MemberType Noteproperty -Value $Json[$Rule].id
            $RuleLine | Add-Member -Name 'Status'              -MemberType Noteproperty -Value (Get-Status -Status $Json[$Rule].enable)
            $RuleLine | Add-Member -Name 'Description'         -MemberType Noteproperty -Value $Json[$Rule].description
            $RuleLine | Add-Member -Name 'Internal IP Address' -MemberType Noteproperty -Value $Json[$Rule].internalip
            $RuleLine | Add-Member -Name 'Internal Port'       -MemberType Noteproperty -Value $Json[$Rule].internalport
            $RuleLine | Add-Member -Name 'External Port'       -MemberType Noteproperty -Value $Json[$Rule].externalport
            $RuleLine | Add-Member -Name 'Protocol'            -MemberType Noteproperty -Value $Json[$Rule].protocol
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

Function Get-DeviceUSBDevices {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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
            $USBDeviceLine | Add-Member -Name 'Label Partition'    -MemberType Noteproperty -Value $Json.child[$USBDevice].label
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

Function Get-DeviceUSBPrinter {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-USBStorage {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.file_info
    
    If ($Json.file_info.count -ne '0') {
    
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

Function Get-VOIP {
    
    Param (
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
    $VOIPLine | Add-Member -Name 'Phone line index'             -MemberType Noteproperty -Value $Json.id
    $VOIPLine | Add-Member -Name 'Status'                       -MemberType Noteproperty -Value (Get-Status -Status $Json.status)
    $VOIPLine | Add-Member -Name 'Call State'                   -MemberType Noteproperty -Value $Json.callstate
    $VOIPLine | Add-Member -Name 'SIP Phone Number'             -MemberType Noteproperty -Value $Json.uri
    $VOIPLine | Add-Member -Name 'Anonymous call Blocked State' -MemberType Noteproperty -Value $Json.blockstate
    $VOIPLine | Add-Member -Name 'Anonymous Call State'         -MemberType Noteproperty -Value (Get-State -State $Json.anoncallstate)
    $VOIPLine | Add-Member -Name 'Is Voice Mail waiting ?'      -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.mwi)
    $VOIPLine | Add-Member -Name 'Voice Mail Count waiting'     -MemberType Noteproperty -Value $Json.message_count
    $VOIPLine | Add-Member -Name 'Missed call'                  -MemberType Noteproperty -Value $Json.notanswered
    
    # Add lines to $Array
    $Array += $VOIPLine
    
    Return $Array
}

Function Get-VOIPDiag {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-VOIPDiagHost {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-VOIPDiagUSB {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-VOIPScheduler {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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
    $SchedulerLine | Add-Member -Name 'Date'           -MemberType Noteproperty -Value $Json.now
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

Function Get-VOIPSchedulerRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-VOIPCallLogLineX {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.calllog
    
    If ($Json.Count -ne 0) {
        
        $Call = 0
        
        While ($Call -lt $Json.Count) {
            
            # Calculate call time
            $CallTime = New-TimeSpan -Seconds $($Json[$Call].duree)
            
            # Create New PSObject and add values to array
            $CallLine = New-Object -TypeName PSObject
            $CallLine | Add-Member -Name 'ID'             -MemberType Noteproperty -Value $Json[$Call].id
            $CallLine | Add-Member -Name 'Number'         -MemberType Noteproperty -Value $Json[$Call].number
            $CallLine | Add-Member -Name 'Date'           -MemberType Noteproperty -Value (Format-Date1970 -Seconds $Json[$Call].date)
            $CallLine | Add-Member -Name 'Call Type'      -MemberType Noteproperty -Value (Get-VoiceCallType -VoiceCallType $Json[$Call].type)
            $CallLine | Add-Member -Name 'Was Answered ?' -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Call].answered)
            $CallLine | Add-Member -Name 'Call Time'      -MemberType Noteproperty -Value "$($CallTime.Hours)h$($CallTime.Minutes)m$($CallTime.Seconds)s"
            
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

Function Get-VOIPFullCallLogLineX {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.fullcalllog
    
    If ($Json.Count -ne 0) {
        
        $Call = 0
        
        While ($Call -lt $Json.Count) {
            
            # Calculate call time
            $CallTime = New-TimeSpan -Seconds $($Json[$Call].duree)
            
            # Create New PSObject and add values to array
            $CallLine = New-Object -TypeName PSObject
            $CallLine | Add-Member -Name 'ID'             -MemberType Noteproperty -Value $Json[$Call].id
            $CallLine | Add-Member -Name 'Number'         -MemberType Noteproperty -Value $Json[$Call].number
            $CallLine | Add-Member -Name 'Date'           -MemberType Noteproperty -Value (Format-Date1970 -Seconds $Json[$Call].date)
            $CallLine | Add-Member -Name 'Call Type'      -MemberType Noteproperty -Value (Get-VoiceCallType -VoiceCallType $Json[$Call].type)
            $CallLine | Add-Member -Name 'Was Answered ?' -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json[$Call].answered)
            $CallLine | Add-Member -Name 'Call Time'      -MemberType Noteproperty -Value "$($CallTime.Hours)h$($CallTime.Minutes)m$($CallTime.Seconds)s"
            
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

Function Get-VOIPAllowedListNumber {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.voip.scheduler
    
    If ($Json.Count -ne 0) {
        
        $Number = 0
        
        While ($Number -lt $Json.Count) {
            
            # Create New PSObject and add values to array
            $NumberLine = New-Object -TypeName PSObject
            $NumberLine | Add-Member -Name 'ID'     -MemberType Noteproperty -Value $Json[$Number].id
            $NumberLine | Add-Member -Name 'Number' -MemberType Noteproperty -Value $Json[$Number].number
            
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

Function Get-WANAutowan {
    
    Param (
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

    $DNS = $(Resolve-DnsName -Name $Json.ip.address -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost

    # Create New PSObject and add values to array
    $DeviceLine = New-Object -TypeName PSObject
    $DeviceLine | Add-Member -Name 'Model'            -MemberType Noteproperty -Value $Json.device.model
    $DeviceLine | Add-Member -Name 'Firmware Version' -MemberType Noteproperty -Value $Json.device.firmware.main
    $DeviceLine | Add-Member -Name 'Firmware Date'    -MemberType Noteproperty -Value $Json.device.firmware.date
    $DeviceLine | Add-Member -Name 'WAN IP Address'   -MemberType Noteproperty -Value $Json.ip.address
    $DeviceLine | Add-Member -Name 'WAN Bytel DNS'    -MemberType Noteproperty -Value $DNS # Not included in API
    
    # Add lines to $Array
    $Device += $DeviceLine
    
    
    # Profile part
    # Create New PSObject and add values to array
    $ProfileActive = $Json.Profile.active -split ','
    
    $ProfileLine = New-Object -TypeName PSObject
    $ProfileLine | Add-Member -Name 'Profile Name'          -MemberType Noteproperty -Value $Json.Profile.device
    $ProfileLine | Add-Member -Name 'Active Profile Chanel' -MemberType Noteproperty -Value $ProfileActive[0]
    $ProfileLine | Add-Member -Name 'Active Profile Name'   -MemberType Noteproperty -Value $ProfileActive[1]
    
    # Add lines to $Array
    $ProfileWan += $ProfileLine
    
    
    # Profiles part
    If ($Json.Profiles.Count -ne 0) {
        
        $Line = 0
        
        While ($Line -lt  $Json.Profiles.Count) {
            
            # Create New PSObject and add values to array
            $ProfilesLine = New-Object -TypeName PSObject
            $ProfilesLine | Add-Member -Name 'Index'     -MemberType Noteproperty -Value $Json.Profiles[$Line].index
            $ProfilesLine | Add-Member -Name 'Name'      -MemberType Noteproperty -Value $Json.Profiles[$Line].name
            $ProfilesLine | Add-Member -Name 'Flags'     -MemberType Noteproperty -Value $Json.Profiles[$Line].flags
            $ProfilesLine | Add-Member -Name 'State'     -MemberType Noteproperty -Value (Get-State -State $Json.Profiles[$Line].state)
            $ProfilesLine | Add-Member -Name 'Success'   -MemberType Noteproperty -Value $Json.Profiles[$Line].success
            $ProfilesLine | Add-Member -Name 'Failure'   -MemberType Noteproperty -Value $Json.Profiles[$Line].failure
            $ProfilesLine | Add-Member -Name 'Timeout'   -MemberType Noteproperty -Value $Json.Profiles[$Line].timeout
            $ProfilesLine | Add-Member -Name 'Fallback'  -MemberType Noteproperty -Value $Json.Profiles[$Line].fallback
            $ProfilesLine | Add-Member -Name 'Starttime' -MemberType Noteproperty -Value $Json.Profiles[$Line].starttime
            $ProfilesLine | Add-Member -Name 'Tostart'   -MemberType Noteproperty -Value $Json.Profiles[$Line].tostart
            $ProfilesLine | Add-Member -Name 'Toip'      -MemberType Noteproperty -Value $Json.Profiles[$Line].toip
            $ProfilesLine | Add-Member -Name 'Todns'     -MemberType Noteproperty -Value $Json.Profiles[$Line].todns
            $ProfilesLine | Add-Member -Name 'Totr069'   -MemberType Noteproperty -Value $Json.Profiles[$Line].totr069
            $ProfilesLine | Add-Member -Name 'Torunning' -MemberType Noteproperty -Value $Json.Profiles[$Line].torunning
            $ProfilesLine | Add-Member -Name 'Laststop'  -MemberType Noteproperty -Value $Json.Profiles[$Line].laststop
            
            # Add lines to $Array
            $Profiles += $ProfilesLine
            
            # Go to next line
            $Line ++
        }
    }
    Else {
        $Profiles = $null
    }
    
    # Services part
    # Create New PSObject and add values to array
    $ServicesLine = New-Object -TypeName PSObject
    $ServicesLine | Add-Member -Name 'IGMP' -MemberType Noteproperty -Value (Get-State -State $Json.Services.igmp)
    $ServicesLine | Add-Member -Name 'VOIP' -MemberType Noteproperty -Value (Get-State -State $Json.Services.voip)
    
    # Add lines to $Array
    $Services += $ServicesLine
    
    Return $Device, $Profile, $Profiles, $Services
}

Function Get-WANDiags {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create arrays
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.diags
    
    # DNS Diags Part
    $DNS = 0
    While ($DNS -lt $Json.dns.Count) {
        
        # Create New PSObject and add values to array
        $DNSLine = New-Object -TypeName PSObject
        $DNSLine | Add-Member -Name 'Type'     -MemberType Noteproperty -Value 'DNS'
        $DNSLine | Add-Member -Name 'Min'      -MemberType Noteproperty -Value $Json.dns[$DNS].min
        $DNSLine | Add-Member -Name 'Max'      -MemberType Noteproperty -Value $Json.dns[$DNS].max
        $DNSLine | Add-Member -Name 'Average'  -MemberType Noteproperty -Value $Json.dns[$DNS].average
        $DNSLine | Add-Member -Name 'Success'  -MemberType Noteproperty -Value $Json.dns[$DNS].success
        $DNSLine | Add-Member -Name 'Error'    -MemberType Noteproperty -Value $Json.dns[$DNS].error
        $DNSLine | Add-Member -Name 'Tries'    -MemberType Noteproperty -Value $Json.dns[$DNS].tries
        $DNSLine | Add-Member -Name 'Status'   -MemberType Noteproperty -Value $Json.dns[$DNS].status
        $DNSLine | Add-Member -Name 'Protocol' -MemberType Noteproperty -Value $Json.dns[$DNS].protocol
        
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
        $HTTPLine | Add-Member -Name 'Success'  -MemberType Noteproperty -Value $Json.HTTP[$HTTP].success
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
        $PingLine | Add-Member -Name 'Type'      -MemberType Noteproperty -Value 'PING'
        $PingLine | Add-Member -Name 'Min'      -MemberType Noteproperty -Value $Json.Ping[$Ping].min
        $PingLine | Add-Member -Name 'Max'      -MemberType Noteproperty -Value $Json.Ping[$Ping].max
        $PingLine | Add-Member -Name 'Average'  -MemberType Noteproperty -Value $Json.Ping[$Ping].average
        $PingLine | Add-Member -Name 'Success'  -MemberType Noteproperty -Value $Json.Ping[$Ping].success
        $PingLine | Add-Member -Name 'Error'    -MemberType Noteproperty -Value $Json.Ping[$Ping].error
        $PingLine | Add-Member -Name 'Tries'    -MemberType Noteproperty -Value $Json.Ping[$Ping].tries
        $PingLine | Add-Member -Name 'Status'   -MemberType Noteproperty -Value $Json.Ping[$Ping].status
        $PingLine | Add-Member -Name 'Protocol' -MemberType Noteproperty -Value $Json.Ping[$Ping].protocol
        
        # Add lines to $Array
        $Array += $PingLine
        
        # Go to next line
        $Ping ++
    }    
    
    Return $Array
}

Function Get-WANDiagsSessions {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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
        $SessionsLine | Add-Member -Name 'Average current IP sessions by host' -MemberType Noteproperty -Value $($Json.currentip / $Json.hosts.Count) # Not included vith API
        $SessionsLine | Add-Member -Name 'Total TCP IP sessions'               -MemberType Noteproperty -Value $TCP_Sessions
        $SessionsLine | Add-Member -Name 'Total UDP IP sessions'               -MemberType Noteproperty -Value $UDP_Sessions
        $SessionsLine | Add-Member -Name 'Total ICMP IP sessions'              -MemberType Noteproperty -Value $($Json.currentip - ($TCP_Sessions + $UDP_Sessions))
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

Function Get-WANDiagsSummaryHostsActiveSessions {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    If ($Json.Count -ne 0) {
        
        $Line = 0
        
        While ($Line -lt $Json.hosts.Count) {
            
            $dns = $(Resolve-DnsName -Name $Json.hosts[$Line].ip -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost
            
            # Create New PSObject and add values to array
            $SessionsLine = New-Object -TypeName PSObject
            $SessionsLine | Add-Member -Name 'Host IP Address'             -MemberType Noteproperty -Value $Json.hosts[$Line].ip
            $SessionsLine | Add-Member -Name 'HostName'                    -MemberType Noteproperty -Value $dns
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

Function Get-WANDiagsAllActiveSessions {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Create array
    $Array = @()
    
    $NbPages = $(Get-BBoxInformation -UrlToGo $UrlToGo).pages + 1
    $Currentpage = 1
    $Choice = ''
    
    While ($Choice[0] -notmatch "Y|N") {
        
        $Temp = Show-WindowsFormDialogBox2Choices -MainFormTitle 'Program run - Choose Display HostName' -LabelMessageText "Do you want to resolve IP Address ? It takes time, around 1 to 3 minutes :`n- (Y) Yes`n- (N) No" -FirstOptionButtonText 'Y' -SecondOptionButtonText 'N'
        
        Switch ($Temp) {
                
            Y    {$Choice = 'Y';Break}
            N    {$Choice = 'N';Break}
        }
    }
    
    If ($Choice -match 'Y') {

        $Referential = @()
        $IPAdresses = @()
        $Line = 0
        
        While ($Currentpage -ne $NbPages) {
            
            $SessionPage = "$UrlToGo/$Currentpage"
            $Json = Get-BBoxInformation -UrlToGo $SessionPage
            
            While ($Line -lt $Json.Count) {
                
                $IPAdresses += $Json[$Line].srcip
                $IPAdresses += $Json[$Line].dstip
                $Line ++
            }
            $Currentpage ++
        }
        
        $IPAdresses = $IPAdresses | Select-Object -Unique
        
        $IPAdresses | ForEach-Object {
            
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
    
    $Currentpage = 1
    While ($Currentpage -ne $NbPages) {
        
        $SessionPage = "$UrlToGo/$Currentpage"
        $Date = Get-Date
        # Get information from BBOX API
        $Json = Get-BBoxInformation -UrlToGo $SessionPage
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

Function Get-WANDiagsAllActiveSessionsHost {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $AllActiveSessions = Get-WANDiagsAllActiveSessions -UrlToGo $UrlToGo
    $HostID = $AllActiveSessions | Select-Object 'Source IP Address','Source HostName' -Unique | Out-GridView -Title "Active Session Hosts List" -OutputMode Single
    $HostAllActiveSessions = $AllActiveSessions | Where-Object {($_.'Source IP Address' -ilike $HostID.'Source IP Address') -or ($_.'Destination IP Address' -ilike $HostID.'Source IP Address')}
    
    Return $HostAllActiveSessions
}

Function Get-WANFTTHStats {
    
    Param (
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
    $FTTHLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'FTTH'
    $FTTHLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $FTTHLine | Add-Member -Name 'Mode'    -MemberType Noteproperty -Value $Json.mode
    
    # Add lines to $Array
    $Array += $FTTHLine
    
    Return $Array
}

Function Get-WANIP {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Select $JSON header
    $Json = $Json.wan
    
    $dnsIP = $(Resolve-DnsName -Name $Json.ip.address -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost
    $dnsgateway = $(Resolve-DnsName -Name $Json.ip.gateway -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).NameHost -join ","
    
    $dnsservers = @()
    $ipdnsservers = $Json.ip.dnsservers -split ","
    $ipdnsservers | ForEach-Object {$dnsservers += $(Resolve-DnsName -Name $_).NameHost}
    $dnsservers =  $dnsservers -join ","
    
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

Function Get-WANIPStats {
    
    Param (
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

Function Get-WANXDSL {
    
    Param (
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

Function Get-WANXDSLStats {
    
    Param (
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

function Get-WANSFF {
    
    Param (
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
    $WanLine = New-Object -TypeName PSObject
    $WanLine | Add-Member -Name 'Enable'            -MemberType Noteproperty -Value (Get-State -State $Json.enable)
    $WanLine | Add-Member -Name 'Type'              -MemberType Noteproperty -Value $Json.pon_mode.type
    $WanLine | Add-Member -Name 'Module Class'      -MemberType Noteproperty -Value $Json.pon_mode.moduleclass
    $WanLine | Add-Member -Name 'Internal Status'   -MemberType Noteproperty -Value $Json.pon_mode.internalstatus
    $WanLine | Add-Member -Name 'SFF Serial'        -MemberType Noteproperty -Value $Json.sffserial
    $WanLine | Add-Member -Name 'SFF Vendor id'     -MemberType Noteproperty -Value $Json.sff_vendor_id
    $WanLine | Add-Member -Name 'OLT Vendor id'     -MemberType Noteproperty -Value $Json.olt_vendor_id
    $WanLine | Add-Member -Name 'Serial Number'     -MemberType Noteproperty -Value $Json.serial_number
    $WanLine | Add-Member -Name 'Receive Power'     -MemberType Noteproperty -Value $Json.receive_power
    $WanLine | Add-Member -Name 'Transmit Power'    -MemberType Noteproperty -Value $Json.transmit_power
    $WanLine | Add-Member -Name 'Temperature'       -MemberType Noteproperty -Value $Json.temperature
    $WanLine | Add-Member -Name 'Tension'           -MemberType Noteproperty -Value $Json.voltage
    $WanLine | Add-Member -Name 'Firmware 1'        -MemberType Noteproperty -Value $Json.firmware_vers_1
    $WanLine | Add-Member -Name 'Firmware Status 1' -MemberType Noteproperty -Value (Get-Status -Status $Json.status_firmware_v1)
    $WanLine | Add-Member -Name 'Firmware 2'        -MemberType Noteproperty -Value $Json.firmware_vers_2
    $WanLine | Add-Member -Name 'Firmware Status 2' -MemberType Noteproperty -Value (Get-Status -Status $Json.status_firmware_v2)
    
    # Add lines to $Array
    $Array += $WanLine
    
    Return $Array
}

#endregion WAN

#region WIRELESS

Function Get-WIRELESS {
    
    Param (
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
    $WIRELESSLine | Add-Member -Name '2,4Ghz Status'                -MemberType Noteproperty -Value (Get-State -State  $Json.radio.'24'.enable)
    $WIRELESSLine | Add-Member -Name '2,4Ghz State'                 -MemberType Noteproperty -Value (Get-State -State $Json.radio.'24'.state)
    $WIRELESSLine | Add-Member -Name '2,4Ghz Radio Type List'       -MemberType Noteproperty -Value $($Json.standard.'24'.value -join ',')
    $WIRELESSLine | Add-Member -Name '2,4Ghz Type'                  -MemberType Noteproperty -Value $Json.radio.'24'.standard
    $WIRELESSLine | Add-Member -Name '2,4Ghz Current Channel'       -MemberType Noteproperty -Value $Json.radio.'24'.current_channel
    $WIRELESSLine | Add-Member -Name '2,4Ghz Channel'               -MemberType Noteproperty -Value $Json.radio.'24'.channel
    $WIRELESSLine | Add-Member -Name '2,4Ghz Channel Width'         -MemberType Noteproperty -Value $Json.radio.'24'.htbw
    
    $WIRELESSLine | Add-Member -Name '2,4Ghz SSID State'            -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'24'.enable)
    $WIRELESSLine | Add-Member -Name '2,4Ghz SSID Name'             -MemberType Noteproperty -Value $Json.ssid.'24'.id
    $WIRELESSLine | Add-Member -Name '2,4Ghz SSID Hidden ?'         -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'24'.hidden)
    $WIRELESSLine | Add-Member -Name '2,4Ghz DSSID'                 -MemberType Noteproperty -Value $Json.ssid.'24'.bssid
    $WIRELESSLine | Add-Member -Name '2,4Ghz Default Security ?'    -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'24'.security.isdefault)
    $WIRELESSLine | Add-Member -Name '2,4Ghz Encryption method'     -MemberType Noteproperty -Value $Json.ssid.'24'.security.encryption
    $WIRELESSLine | Add-Member -Name '2,4Ghz Password'              -MemberType Noteproperty -Value $Json.ssid.'24'.security.passphrase
    $WIRELESSLine | Add-Member -Name '2,4Ghz Protocol'              -MemberType Noteproperty -Value $Json.ssid.'24'.security.protocol
    $WIRELESSLine | Add-Member -Name '2,4Ghz Multimedia QoS Status' -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'24'.wmmenable)
    $WIRELESSLine | Add-Member -Name '2,4Ghz WPS State'             -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'24'.wps.enable)
    $WIRELESSLine | Add-Member -Name '2,4Ghz WPS Avalability'       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'24'.wps.available)
    $WIRELESSLine | Add-Member -Name '2,4Ghz WPS Status'            -MemberType Noteproperty -Value (Get-Status -Status $Json.ssid.'24'.wps.status)
    
    # 5,2 Ghz
    $WIRELESSLine | Add-Member -Name '5,2Ghz Status'                -MemberType Noteproperty -Value (Get-State -State $Json.radio.'24'.enable)
    $WIRELESSLine | Add-Member -Name '5,2Ghz State'                 -MemberType Noteproperty -Value (Get-State -State $Json.radio.'24'.state)
    $WIRELESSLine | Add-Member -Name '5,2Ghz Radio Type List'       -MemberType Noteproperty -Value $($Json.standard.'5'.value -join ',')
    $WIRELESSLine | Add-Member -Name '5,2Ghz Type'                  -MemberType Noteproperty -Value $Json.radio.'5'.standard
    $WIRELESSLine | Add-Member -Name '5,2Ghz Current Channel'       -MemberType Noteproperty -Value $Json.radio.'5'.current_channel
    $WIRELESSLine | Add-Member -Name '5,2Ghz Channel'               -MemberType Noteproperty -Value $Json.radio.'5'.channel
    $WIRELESSLine | Add-Member -Name '5,2Ghz Channel Width'         -MemberType Noteproperty -Value $Json.radio.'5'.htbw
    $WIRELESSLine | Add-Member -Name '5,2Ghz DFS'                   -MemberType Noteproperty -Value $Json.radio.'5'.dfs
    $WIRELESSLine | Add-Member -Name '5,2Ghz GreenAP'               -MemberType Noteproperty -Value $Json.radio.'5'.greenap
    
    $WIRELESSLine | Add-Member -Name '5,2Ghz SSID State'            -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'5'.enable)
    $WIRELESSLine | Add-Member -Name '5,2Ghz SSID Name'             -MemberType Noteproperty -Value $Json.ssid.'5'.id
    $WIRELESSLine | Add-Member -Name '5,2Ghz SSID Hidden ?'         -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'5'.hidden)
    $WIRELESSLine | Add-Member -Name '5,2Ghz DSSID'                 -MemberType Noteproperty -Value $Json.ssid.'5'.bssid
    $WIRELESSLine | Add-Member -Name '5,2Ghz Default Security ?'    -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'5'.security.isdefault)
    $WIRELESSLine | Add-Member -Name '5,2Ghz Encryption method'     -MemberType Noteproperty -Value $Json.ssid.'5'.security.encryption
    $WIRELESSLine | Add-Member -Name '5,2Ghz Password'              -MemberType Noteproperty -Value $Json.ssid.'5'.security.passphrase
    $WIRELESSLine | Add-Member -Name '5,2Ghz Protocol'              -MemberType Noteproperty -Value $Json.ssid.'5'.security.protocol
    $WIRELESSLine | Add-Member -Name '5,2Ghz Multimedia QoS Status' -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'5'.wmmenable)
    $WIRELESSLine | Add-Member -Name '5,2Ghz WPS State'             -MemberType Noteproperty -Value (Get-State -State $Json.ssid.'5'.wps.enable)
    $WIRELESSLine | Add-Member -Name '5,2Ghz WPS Avalability'       -MemberType Noteproperty -Value (Get-YesNoAsk -YesNoAsk $Json.ssid.'5'.wps.available)
    $WIRELESSLine | Add-Member -Name '5,2Ghz WPS Status'            -MemberType Noteproperty -Value (Get-Status -Status $Json.ssid.'5'.wps.status)
    
    $WIRELESSLine | Add-Member -Name '5,2Ghz Capabilities'          -MemberType Noteproperty -Value $(Get-WIRELESS5GHCAPABILITIES -Capabilities $Json.capabilities.'5')
    
    # Add lines to $Array
    $Array += $WIRELESSLine
    
    Return $Array
}

Function Get-WIRELESS24Ghz {
    
    Param (
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

Function Get-WIRELESS5Ghz {
    
    Param (
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
    $WIRELESSLine | Add-Member -Name 'Capabilities'          -MemberType Noteproperty -Value $(Get-WIRELESS5GHCAPABILITIES -Capabilities $Json.capabilities.'5')
    $WIRELESSLine | Add-Member -Name 'Advanced'              -MemberType Noteproperty -Value $Json.Advanced
    
    # Add lines to $Array
    $Array += $WIRELESSLine
    
    Return $Array
}

Function Get-WIRELESS5GHCAPABILITIES {
    
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

Function Get-WIRELESSStats {
    
    Param (
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

Function Get-WIRELESSACL {
    
    Param (
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
    $RuleLine | Add-Member -Name 'Service'     -MemberType Noteproperty -Value 'Mac Address Filtering'
    $RuleLine | Add-Member -Name 'Status'      -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    
    # Add lines to $Array
    $Array += $RuleLine
    
    Return $Array
}

Function Get-WIRELESSACLRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-WIRELESSACLRulesID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    $WIRELESSACLIDs = Get-WIRELESSACLRules -UrlToGo $UrlToGo
    $WIRELESSACLID = $WIRELESSACLIDs | Select-Object ID,'Mac Address' | Out-GridView -Title "Wireless ACL Rules List" -OutputMode Single
    $WIRELESSACLHost = $WIRELESSACLIDs | Where-Object {$_.ID -ilike $WIRELESSACLID.id}
    
    Return $WIRELESSACLHost
}

Function Get-WIRELESSFastScanMe {

    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )

    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()

    # Create New PSObject and add values to array
    $Line = New-Object -TypeName PSObject
    $Line | Add-Member -Name 'link'       -MemberType Noteproperty -Value $Json.band
    $Line | Add-Member -Name 'MACAddress' -MemberType Noteproperty -Value $Json.macaddress
    $Line | Add-Member -Name 'RSSI'       -MemberType Noteproperty -Value $Json.rssi
    $Line | Add-Member -Name 'Rate'       -MemberType Noteproperty -Value $Json.rate
    $Line | Add-Member -Name 'RxRate'     -MemberType Noteproperty -Value $Json.rxrate
    $Line | Add-Member -Name 'MCS'        -MemberType Noteproperty -Value $Json.mcs
    
    # Add lines to $Array
    $Array += $Line
        
    Return $Array
}

Function Get-WIRELESSFrequencyNeighborhoodScanID {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-WIRELESSScheduler {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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
    $SchedulerLine | Add-Member -Name 'Date'           -MemberType Noteproperty -Value $Json.now
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

Function Get-WIRELESSSchedulerRules {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-WIRELESSRepeater {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
    # Create array
    $Array = @()
    
    # Create New PSObject and add values to array
    $RepeaterLine = New-Object -TypeName PSObject
    $RepeaterLine | Add-Member -Name 'Service'       -MemberType Noteproperty -Value 'WIRELESS Repeater'
    $RepeaterLine | Add-Member -Name 'Station Count' -MemberType Noteproperty -Value $Json.stationscount
    $RepeaterLine | Add-Member -Name 'Station List'  -MemberType Noteproperty -Value $($Json.list -join ',')
    $RepeaterLine | Add-Member -Name 'ZeroTouch'     -MemberType Noteproperty -Value $($Json.zerotouch.list -join ',') # Since version 20.6.8
    
    # Add lines to $Array
    $Array += $RepeaterLine
    
    Return $Array
}

function Get-WIRELESSVideoBridgeSetTopBoxes {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

function Get-WIRELESSVideoBridgeRepeaters {
    
    Param (
        [Parameter(Mandatory=$True)]
        [String]$UrlToGo
    )
    
    # Get information from BBOX API
    $Json = Get-BBoxInformation -UrlToGo $UrlToGo
    
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

Function Get-WIRELESSWPS {
    
    Param (
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
    $WPSLine | Add-Member -Name 'Service' -MemberType Noteproperty -Value 'WPS'
    $WPSLine | Add-Member -Name 'State'   -MemberType Noteproperty -Value (Get-State -State $Json.state)
    $WPSLine | Add-Member -Name 'Status'  -MemberType Noteproperty -Value (Get-Status -Status $Json.enable)
    $WPSLine | Add-Member -Name 'Timeout' -MemberType Noteproperty -Value $json.timeout
    
    # Add lines to $Array
    $Array += $WPSLine
    
    Return $Array
}

#endregion WPS

#endregion
