# Version less than .01 Beta
# Test version 1.

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }
else
   {
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   # Exit from the current, unelevated, process
   exit
   }
 
# Run your code that needs to be elevated here
write-host "Script launched in Elevated mode."
Write-Host -NoNewLine "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

cls
set-executionpolicy -ExecutionPolicy "Unrestricted"
$rPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$rName = "DisableWindowsUpdateAccess"
$rNewValue = "0"

$svcStatus = get-service -name "wuauserv"
if ($svcStatus.Status -ne "Running") {
    write-host "Windows Update Service is:" $svcStatus.Status
    $stSvc = read-host "Set service to Manual startup and start the service?[Y,N]"
    if ($stSvc -eq 'Y') {
        Set-Service -Name "wuauserv" -StartupType Manual
        Start-Service -Name "wuauserv"
    }
}

if (!(Test-Path $rPath)) {
    write-host "Registry key does not exist, nothing to do.  Exiting." -ForegroundColor Yellow
} else {
    write-host "Registry key DOES exist, checking DisableWindowsUpdateAccess value." -ForegroundColor Green
    $rValue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name $rName
    if (!($rValue)) {
        Write-host "$rName does not exist, unable to change what doesn't exist.  Exitting." -ForegroundColor yellow
    } else {
        $rCurrentValue = $rValue.DisableWindowsUpdateAccess
        write-host "$rName DOES exist, current value is: $rCurrentValue (1 = Disabled, 0 = Enabled)" -ForegroundColor Green

        # if / else current value is 0, then make the change otherwise notify
        if ($rCurrentValue -eq 1) {
            Write-Host "Changing value to 0 - Enable online updates." -ForegroundColor Yellow
            New-ItemProperty -Path $rPath -Name $rName -Value $rNewValue -PropertyType DWORD -Force | Out-Null
            write-host "Restarting Windows Update service..." -ForegroundColor Cyan
            Restart-Service -Name wuauserv -Confirm
        } else {
            Write-Host "Nothing to do, online updates already enabled." -ForegroundColor Yellow

        }
        write-host "`nScript done.  Verify Windows update is running on the line below, if not manually restart the service."
        get-service -Name "wuauserv"
        write-host "`n"
    }
}
Write-Host -NoNewLine "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
# EOF