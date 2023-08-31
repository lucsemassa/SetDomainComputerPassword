function Set-DomainComputerPassword {
<#
.SYNOPSIS

Sets the password for a given computer identity.

Author: Will Schroeder (@harmj0y)  
License: BSD 3-Clause  
Required Dependencies: Get-PrincipalContext  

.DESCRIPTION

First binds to the specified domain context using Get-PrincipalContext.
The bound domain context is then used to search for the specified computer -Identity,
which returns a DirectoryServices.AccountManagement.ComputerPrincipal object. The
SetPassword() function is then invoked on the computer, setting the password to -AccountPassword.

.PARAMETER Identity

A computer SamAccountName (e.g. Computer1), DistinguishedName (e.g. CN=computer1,CN=Computers,DC=testlab,DC=local),
SID (e.g. S-1-5-21-890171859-3433809279-3366196753-1113), or GUID (e.g. 4c435dd7-dc58-4b14-9a5e-1fdb0e80d201)
specifying the computer to reset the password for.

.PARAMETER AccountPassword

Specifies the password to reset the target computer's to. Mandatory.

.PARAMETER Domain

Specifies the domain to use to search for the computer identity, defaults to the current domain.

.PARAMETER Credential

A [Management.Automation.PSCredential] object of alternate credentials
for connection to the target domain.

.EXAMPLE

$ComputerPassword = ConvertTo-SecureString 'Password123!' -AsPlainText -Force
Set-DomainComputerPassword -Identity andy-computer$ -AccountPassword $ComputerPassword

Resets the password for 'andy-computer$' to the password specified.

.EXAMPLE

$SecPassword = ConvertTo-SecureString 'Password123!' -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential('TESTLAB\dfm.a', $SecPassword)
$ComputerPassword = ConvertTo-SecureString 'Password123!' -AsPlainText -Force
Set-DomainComputerPassword -Identity andy-computer$ -AccountPassword $ComputerPassword -Credential $Cred

Resets the password for 'andy-computer$' computering the alternate credentials specified.

.OUTPUTS

DirectoryServices.AccountManagement.ComputerPrincipal

.LINK

http://richardspowershellblog.wordpress.com/2008/05/25/system-directoryservices-accountmanagement/
#>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
    [OutputType('DirectoryServices.AccountManagement.ComputerPrincipal')]
    Param(
        [Parameter(Position = 0, Mandatory = $True)]
        [Alias('ComputerName', 'ComputerIdentity', 'Computer')]
        [String]
        $Identity,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Alias('Password')]
        [Security.SecureString]
        $AccountPassword,

        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,

        [Management.Automation.PSCredential]
        [Management.Automation.CredentialAttribute()]
        $Credential = [Management.Automation.PSCredential]::Empty
    )

    $ContextArguments = @{ 'Identity' = $Identity }
    if ($PSBoundParameters['Domain']) { $ContextArguments['Domain'] = $Domain }
    if ($PSBoundParameters['Credential']) { $ContextArguments['Credential'] = $Credential }
    $Context = Get-PrincipalContext @ContextArguments

    if ($Context) {
        $Computer = [System.DirectoryServices.AccountManagement.ComputerPrincipal]::FindByIdentity($Context.Context, $Identity)

        if ($Computer) {
            Write-Verbose "[Set-DomainComputerPassword] Attempting to set the password for computer '$Identity'"
            try {
                $TempCred = New-Object System.Management.Automation.PSCredential('a', $AccountPassword)
                $Computer.SetPassword($TempCred.GetNetworkCredential().Password)

                $Null = $Computer.Save()
                Write-Verbose "[Set-DomainComputerPassword] Password for computer '$Identity' successfully reset"
            }
            catch {
                Write-Warning "[Set-DomainComputerPassword] Error setting password for computer '$Identity' : $_"
            }
        }
        else {
            Write-Warning "[Set-DomainComputerPassword] Unable to find computer '$Identity'"
        }
    }
}
