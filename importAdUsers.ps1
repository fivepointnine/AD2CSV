# Prompt for the domain, TLD, and OU
$domain = Read-Host "Enter the domain name (e.g., example)"
$tld = Read-Host "Enter the top-level domain (e.g, com)"
$ou = Read-Host "Enter the Organizational Unit (OU) name (e.g., corp-users)"

# Construct the default OU path
$defaultOU = "OU=$ou,DC=$domain,DC=$tld"

# Test connectivity with the domain controller
try {
    $domainController = (Get-ADDomainController -Discover -Service "PrimaryDC").HostName
    Write-Host "Connected to domain controller: $domainController"
}
catch {
    Write-Host "Error connecting to domain controller: $_"
    return
}

# Check if the OU exists
$ouExists = Get-ADOrganizationalUnit -Filter {Name -eq $ou} -ErrorAction SilentlyContinue

if ($ouExists -eq $null) {
    Write-Host "Error: Organizational Unit '$ou' does not exist."
    return
}

# Prompt for the CSV file path
$csvPath = Read-Host "Enter the path to the CSV file"

# Import users from CSV
$users = Import-Csv -Path $csvPath

# Track the number of users added and skipped
$usersAdded = 0
$usersSkipped = 0

# Record the start time
$startTime = Get-Date

# Function to create a user
function Create-User {
    param (
        [string]$username,
        [string]$firstName,
        [string]$lastName,
        [string]$email
    )

    # Create user account with default password, ChangePasswordAtLogon flag, and set display name to username
    $userParams = @{
        SamAccountName        = $username
        GivenName             = $firstName
        Surname               = $lastName
        EmailAddress          = $email
        Path                  = "OU=$ou,DC=$domain,DC=$tld"
        Enabled               = $true
        UserPrincipalName     = "$username@$domain$tld"
        ChangePasswordAtLogon = $true
        AccountPassword       = (ConvertTo-SecureString "Password123" -AsPlainText -Force)
        Name                  = "$firstName $lastName"  # Combine first and last name for the Name attribute
        DisplayName           = $username  # Set the display name to the username
    }

    # Create the user account
    New-ADUser @userParams

    # Increment the number of users added
    $script:usersAdded++

    # Display a message with the username and OU name
    Write-Host "User '$username' created successfully in OU: $ou."
}

# Create users
foreach ($user in $users) {
    $username = ($user.firstname.Substring(0, 1) + $user.lastname).ToLower()
    Create-User -username $username -firstName $user.firstname -lastName $user.lastname -email $user.email
}

# Record the end time
$endTime = Get-Date

# Calculate the duration in seconds
$duration = [math]::Round(($endTime - $startTime).TotalSeconds)

# Display a message with the number of users added, skipped, and the duration
Write-Host "User import completed successfully. Added $usersAdded users, Skipped $usersSkipped users. Duration: $duration seconds."
