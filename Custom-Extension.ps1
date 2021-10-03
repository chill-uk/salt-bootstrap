param (
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$Password,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$UserName,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$Master,
    [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][String]$ServiceName = "salt-minion"
)

function Set-ServiceCredentials {
    param (
        [String]$password,
        [String]$userName,
        [String]$serviceName
    )
    process {

        Stop-Service -Name $($serviceName)
        cmd /c sc config $ServiceName obj= "$($env:COMPUTERNAME)\$($username)" password= $Password
        Start-Sleep -Seconds 5
        Start-Service -Name $($serviceName) 
    }
}

function Set-LogOnPrivilege {
    param (
        [String]$userName
    )
    begin {
        Install-Module -Name 'Carbon' -AllowClobber
        Import-Module 'Carbon'
    }    
    process {
        $privilege = "SeServiceLogonRight"
        $CarbonDllPath = "C:\Program Files\WindowsPowerShell\Modules\Carbon\2.10.2\bin\fullclr\Carbon.dll"
        [Reflection.Assembly]::LoadFile($CarbonDllPath)
        [Carbon.Security.Privilege]::GrantPrivileges($userName, $privilege)
    }
}

function New-LocalSaltUser {
    param (
        [String]$password,
        [String]$userName
    )
    process {
        Write-Host "Creating user $($username)"
        $passwordSec = (ConvertTo-SecureString -String $($password) -AsPlainText -Force)
        New-LocalUser $($userName) -Password $($passwordSec)
        Add-LocalGroupMember -Group "Administrators" -Member $($userName)
        Set-LocalUser -Name $($userName) -PasswordNeverExpires 1
        Set-LogOnPrivilege -userName $userName
    }
}

function Install-SaltMinion {
    param (
        [String]$master
    )  
    process {
        New-Item -ItemType Directory -Path "C:\Temp" -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri https://winbootstrap.saltproject.io -OutFile C:\Temp\bootstrap-salt.ps1
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
        C:\Temp\bootstrap-salt.ps1 -minion $env:COMPUTERNAME -master $master
        Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser -Force 
    }
}

New-LocalSaltUser -password $Password -userName $UserName
Install-SaltMinion -master $Master
Set-ServiceCredentials -password $Password -userName $UserName -serviceName $ServiceName
