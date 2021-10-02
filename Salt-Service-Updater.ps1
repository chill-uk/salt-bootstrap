param (
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][SecureString]$Password,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$UserName,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$ServiceName
)

function set-serviceCredentials {
    param (
        [SecureString]$password,
        [String]$userName,
        [String]$serviceName
    )
    process {
        $Password = (ConvertTo-SecureString -String $($password) -AsPlainText -Force)
        New-LocalUser $($userName) -Password $($password)
        Add-LocalGroupMember -Group "Administrators" -Member $($userName)
        Set-LocalUser -Name $($userName) -PasswordNeverExpires 1
        
        Stop-Service -Name $($serviceName)
        $Svc = Get-WmiObject win32_service -filter "name='$($serviceName)'"
        $Svc.Change($Null, $Null, $Null, $Null, $Null, $Null, "$($env:COMPUTERNAME)\$($userName)", $($password))
        Start-Service -Name $($serviceName) 
    }
}

set-serviceCredentials -password $Password -userName $UserName -serviceName $ServiceName
