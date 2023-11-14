# Add reference to the Windows.Forms assembly for OpenFileDialog
Add-Type -AssemblyName System.Windows.Forms

# Start Transcript for logging
$logFileName = "CSV2AD_LOG.txt"
$logFilePath = Join-Path $env:USERPROFILE $logFileName
Start-Transcript -Path $logFilePath -Append

# Function to show the open file dialog box
function Show-OpenFileDialog {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    $openFileDialog.Filter = 'CSV Files (*.csv)|*.csv|All Files (*.*)|*.*'
    $openFileDialog.ShowDialog() | Out-Null
    $openFileDialog.FileName
}

# Function to list available OUs
function Get-OrganizationalUnits {
    Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty Name
}

# Function to create a user
# Function to create a user with a unique UPN
function Create-User {
    param (
        [string]$username,
        [string]$firstName,
        [string]$lastName,
        [string]$email,
        [string]$ou
    )

    # Attempt to create the user account
    try {
        # Generate a unique UPN by appending a unique identifier
        $uniqueIdentifier = Get-Date -Format "yyyyMMddHHmmss"
        $userParams = @{
            SamAccountName        = $username
            GivenName             = $firstName
            Surname               = $lastName
            EmailAddress          = $email
            Path                  = "OU=$ou,DC=$domain,DC=$tld"
            Enabled               = $true
            UserPrincipalName     = "$username$uniqueIdentifier@$domain$tld"
            ChangePasswordAtLogon = $true
            AccountPassword       = (ConvertTo-SecureString "Password123" -AsPlainText -Force)
            Name                  = "$firstName $lastName"  # Combine first and last name for the Name attribute
            DisplayName           = $username  # Set the display name to the username
        }

        New-ADUser @userParams

        # Increment the number of users added
        $script:usersAdded++

        # Display a message with the username and OU name
        Write-Host "User '$username' created successfully in OU: $ou."
    }
    catch {
        # Handle the case where the user creation fails
        Write-Host "Error creating user '$username': $_"
        $script:usersSkipped++
    }
}

# Prompt for the domain, TLD
$domain = Read-Host "Enter the domain name (e.g., example)"
$tld = Read-Host "Enter the top-level domain (e.g., com)"

# List available OUs
$availableOUs = Get-OrganizationalUnits
Write-Host "Available Organizational Units:"
$availableOUs | ForEach-Object { Write-Host "- $_" }

# Prompt for the OU
do {
    $ou = Read-Host "Enter the Organizational Unit (OU) name"
} while ($availableOUs -notcontains $ou)

# Construct the default OU path
$defaultOU = "OU=$ou,DC=$domain,DC=$tld"

# Test connectivity with the domain controller (unchanged)

# Prompt for the CSV file path using the open file dialog box
$csvPath = Show-OpenFileDialog

# Import users from CSV
$users = Import-Csv -Path $csvPath

# Track the number of users added and skipped (unchanged)
$usersAdded = 0
$usersSkipped = 0

# Record the start time
$startTime = Get-Date

# Create users
foreach ($user in $users) {
    $username = ($user.firstname.Substring(0, 1) + $user.lastname).ToLower()
    Create-User -username $username -firstName $user.firstname -lastName $user.lastname -email $user.email -ou $ou
}

# Record the end time
$endTime = Get-Date

# Calculate the duration in seconds
$duration = [math]::Round(($endTime - $startTime).TotalSeconds)

# Display a message with the number of users added, skipped, and the duration
Write-Host "User import completed successfully. Added $usersAdded users, Skipped $usersSkipped users. Duration: $duration seconds."

# Stop Transcript for logging
Stop-Transcript
