$Password_sec = (ConvertTo-SecureString -String $($password) -AsPlainText -Force)
New-LocalUser $($userName) -Password $($Password_sec)
Add-LocalGroupMember -Group "Administrators" -Member $($userName)
Set-LocalUser -Name $($userName) -PasswordNeverExpires 1


Install-Module -Name 'Carbon' -AllowClobber
Import-Module 'Carbon'
$privilege = "SeServiceLogonRight"
$CarbonDllPath = "C:\Program Files\WindowsPowerShell\Modules\Carbon\2.10.2\bin\fullclr\Carbon.dll"
[Reflection.Assembly]::LoadFile($CarbonDllPath)
[Carbon.Security.Privilege]::GrantPrivileges($username, $privilege)

Stop-Service -Name $Service
cmd /c sc config $Service obj= "$($env:COMPUTERNAME)\$($username)" password= $Password
Start-Service -Name $Service 
