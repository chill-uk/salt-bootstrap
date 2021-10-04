param (
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$Password,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$UserName,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$Master,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$ProjectUrl,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$ProjectName,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$AgentPAT,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$PoolName,
    [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][String]$ServiceName = "salt-minion",
    [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][String]$agentversion = "2.193.0"
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
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module -Name 'Carbon' -AllowClobber -Force
        Import-Module 'Carbon' -Force
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

function Install-DevopsAgent {
    param (
        [String]$agentversion,
        [String]$userName,
        [String]$password,
        [String]$projectUrl,
        [String]$projectName,
        [String]$agentPAT,
        [String]$poolName
    )  
    process {
        $vstsfilename = "vsts-agent-win-x64-$($agentversion).zip"
        Invoke-WebRequest -Uri "https://vstsagentpackage.azureedge.net/agent/$($agentversion)/$($vstsfilename)" -OutFile "$($HOME)\Downloads\$($vstsfilename)"

        mkdir agent
        Set-Location agent
        Expand-Archive -LiteralPath "$($HOME)\Downloads\$($vstsfilename)" -DestinationPath $PWD

        .\config.cmd --runasservice `
                --windowsLogonAccount "$($env:COMPUTERNAME)\$($userName)" `
                --windowsLogonPassword "$($password)" `
                --url "https://$($projectUrl).visualstudio.com/" `
                --projectname "$($projectName)" `
                --auth PAT `
                --token "$($agentPAT)" `
                --unattended `
                --pool "$($poolName)" `
                --agent "$($env:COMPUTERNAME)" `
                --acceptTeeEula 
    }
}

New-LocalSaltUser -password $Password -userName $UserName
Install-SaltMinion -master $Master
Set-ServiceCredentials -password $Password -userName $UserName -serviceName $ServiceName
Install-DevopsAgent -agentversion $Agentversion -password $Password -userName $UserName -projectUrl $ProjectUrl -projectName $ProjectName -agentPAT $AgentPAT -poolName $PoolName
