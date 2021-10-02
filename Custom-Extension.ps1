param (
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$Password,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$UserName,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$ServiceName
)

function Set-ServiceCredentials {
    param (
        [String]$password,
        [String]$userName,
        [String]$serviceName
    )
    process {

        Stop-Service -Name $($serviceName)
        cmd /c sc config $Service obj= "$($env:COMPUTERNAME)\$($username)" password= $Password
        Start-Service -Name $($serviceName) 
    }
}

function New-LocalUser {
    param (
        [String]$password,
        [String]$userName,
    )
    process {
        $passwordSec = (ConvertTo-SecureString -String $($password) -AsPlainText -Force)
        New-LocalUser $($userName) -Password $($passwordSec)
        Add-LocalGroupMember -Group "Administrators" -Member $($userName)
        Set-LocalUser -Name $($userName) -PasswordNeverExpires 1
    }
}

function New-LocalUser {
    param (
        [String]$userName,
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

set-serviceCredentials -password $Password -userName $UserName -serviceName $ServiceName




