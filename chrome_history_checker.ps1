# This script checks the last hour of Google Chrome browser history for "court" and "zoom" and notifies me with sms and email, with log attachment, if it does.
# I will be notified every 5 minutes until the search result is an hour old.

$browser_history_file = ".\other\browser_history.txt"
$log_file = ".\other\log_chrome_history_checker.txt"
$hostname = $env:computername

# Function that accepts $search_string param, and sends SMS notification via TextBelt API key
function sms {
    param(
        [string]$search_string
    )

    $body = @{
        "phone"="8622269364"
        "message"="'$search_string' was found on $hostname browser history!"
        "key"="TEXTBELT_API_KEY_HERE"}
    $submit = Invoke-WebRequest -Uri https://textbelt.com/text -Body $body -Method Post
}

# Function that accepts $search_string, and sends email notification with browser_history.txt attached
function email {
    param(
        [string]$search_string
    )

    $From = "markjnouri@gmail.com"
    $To = "mjnouri@gmail.com"
    $Subject = "'$search_string' was found on $hostname browser history!"
    $Body = "Email body"
    $Attachments = $browser_history_file
    # Password is a Google app password if you have 2-factor-auth enabled
    $Password = "GOOGLE_APP_PASSWORD_HERE" | ConvertTo-SecureString -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $From, $Password
    Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -Attachments $Attachments -SmtpServer "smtp.gmail.com" -port 587 -UseSsl -Credential $Credential
}

# If .\other folder is not there, make it
if (-Not (Test-Path .\other)) {
    $null = New-Item -ItemType Directory -Path ./other
}

# If browser_history.txt is there, delete it
if (Test-Path $browser_history_file) {
   Remove-Item $browser_history_file
}

# Run BrowsingHistoryView.exe which generates a new browser_history.txt of the last hours worth, wait for command to finish
.\BrowsingHistoryView.exe /cfg "BrowsingHistoryView.cfg" /stext $browser_history_file | Out-Null

# Perform searches for "court" and "zoom" in the $browser_history_file
$court_found = Select-String -Path $browser_history_file -Pattern "court"
$zoom_found = Select-String -Path $browser_history_file -Pattern "zoom"

# Make log file more readable
if ( $court_found -Or $zoom_found ) {
    Get-Date -format G | Tee-Object -FilePath $log_file -Append
}

# Check if "court" was found in browser history and notify
if ( $court_found )
{
    Write-Output "'court' was found on $hostname browser history!" | Tee-Object -FilePath $log_file -Append
    sms -search_string "court"
    email -search_string "court"
}
else
{
    Write-Output "'court' was NOT found on $hostname."
}

# Check if "zoom" was found in browser history and notify
if ( $zoom_found )
{
    Write-Output "'zoom' was found on $hostname browser history!" | Tee-Object -FilePath $log_file -Append
    sms -search_string "zoom"
    email -search_string "zoom"
}
else
{
    Write-Output "'zoom' was NOT found on $hostname."
}

# Make log file more readable
if ( $court_found -Or $zoom_found ) {
    Write-Output "----------------" | Tee-Object -FilePath $log_file -Append
}
