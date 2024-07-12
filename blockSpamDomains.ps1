# Get latest SPAM Domains from Github page
$jsonUrl = "https://raw.githubusercontent.com/divox/SPAM-Domains/main/spam-domains.json"

# Fetch the JSON data from the URL
$response = Invoke-WebRequest -Uri $jsonUrl

# Remove the characters [ and ] from the response content
# $domainList = $response.Content -replace "\[|\]", ""
$domainList = $response.Content | ConvertFrom-Json

# Configure variables
$ruleName = "Block spamming domains"
$priority = "0" # Only when a new rule is created. Not effective on existing rules.

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

#Create a new array from domainList
$newDomainList = @()
$newDomainList += foreach ($domain in $domainList) { $domain.trim() }

#If the rule already exists update the existing Block rule, else create a new rule.
if (Get-TransportRule $ruleName -EA SilentlyContinue)
{
  "Updating existing rule..."
  $oldDomainList = Get-TransportRule $ruleName |select -ExpandProperty SenderDomainIs
  $completeList = $oldDomainList + $newDomainList
  $completeList = $completeList | select -uniq | sort    
  set-TransportRule $ruleName -SenderDomainIs $completeList 
}
else
{
  "Creating new rule..."
  $newDomainList = $newDomainList | sort    
  New-TransportRule $ruleName -SenderDomainIs $newDomainList –DeleteMessage $True –StopRuleProcessing $True -Priority $priority
}

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
