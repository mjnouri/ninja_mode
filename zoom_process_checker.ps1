# This script detects if a current window has "zoom" in it and notifies me with sms and email if it does.

$current_processes_file = "./other/current_processes.txt"
$search_string = "zoom"
$log_file = "./other/log_zoom_process_checker.txt"
$hostname = $env:computername

# Function that sends SMS notification via TextBelt API key
function sms {
    $body = @{
        "phone"="8622269364"
        "message"="'zoom' was found in $current_processes_file on $hostname."
        "key"="TEXTBELT_API_KEY_HERE"}
    $submit = Invoke-WebRequest -Uri https://textbelt.com/text -Body $body -Method Post
}

# Function that sends email notification with browser_history.txt attached
function email {
    $From = "markjnouri@gmail.com"
    $To = "mjnouri@gmail.com"
    $Subject = "'zoom' was found in $current_processes_file on $hostname."
    $Body = "Email body"
    # Password is a Google app password if you have 2-factor-auth enabled
    $Password = "GOOGLE_APP_PASSWORD_HERE" | ConvertTo-SecureString -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $From, $Password
    Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SmtpServer "smtp.gmail.com" -port 587 -UseSsl -Credential $Credential
}

# If ./other folder is not there, make it
if (-Not (Test-Path ./other)) {
    $null = New-Item -ItemType Directory -Path ./other
}

# If $current_processes_file is there, delete it
if (Test-Path $current_processes_file) {
   Remove-Item $current_processes_file
}

# This only works correctly if you select "Run only when user is logged in" in the Scheduled Task config.
Get-Process | Where-Object {$_.MainWindowTitle -ne ""} | Select-Object MainWindowTitle | Out-File -FilePath $current_processes_file

# Perform search for "zoom" in the $current_processes_file
$zoom_found = Select-String -Path $current_processes_file -Pattern $search_string

# Check if "zoom" was found in $current_processes_file and notify
if ( $zoom_found )
{
    Get-Date -format G | Tee-Object -FilePath $log_file -Append
    Write-Output "'zoom' was found in $current_processes_file on $hostname." | Tee-Object -FilePath $log_file -Append
    Write-Output "----------------" | Tee-Object -FilePath $log_file -Append
    sms
    email
}
else
{
    Write-Output "'zoom' was NOT found in $current_processes_file on $hostname."
}
