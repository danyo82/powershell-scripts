# Backups all AWS Route 53 hosted zones and their ResourceRecordSets as JSON files.
# DS 2025-11-19

#Requires  -Modules AWS.Tools.Route53


[CmdletBinding(SupportsShouldProcess)]
param (
  [Parameter(Mandatory=$true,HelpMessage="Root-Folder where the json-backupsfiles should be stored")][ValidateNotNullOrEmpty()][string]$BackupRoot
)

# Ensure backup folder exists
if (-not (Test-Path $backupRoot)) {
    throw "backupRoot does not exist: $backupRoot"
}

# Get current UTC timestamp in a filename?safe format
$timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss-UTC")

# Get all hosted zones

try {
  $zones = Get-R53HostedZoneList -ErrorAction Stop
} catch {
  throw "failed to run Get-R53HostedZoneList: $_"
}
foreach ($zone in $zones) {
  $zoneIdRaw  = $zone.Id          # Typically like '/hostedzone/Z123456789ABCDEFG'
  $zoneId     = $zoneIdRaw.Split('/')[-1]
  $zoneName   = $zone.Name.TrimEnd('.') -replace '[^a-zA-Z0-9\-\.]', '_'
  
  # Build filename: route53_zoneId>_<zoneName>_<timestamp>.json
  $fileName   = "route53_{0}_{1}_{2}.json" -f $zoneId, $zoneName, $timestamp
  $filePath   = Join-Path $backupRoot $fileName
  
  Write-Host "Backing up zone $($zoneName) ($zoneId) to $filePath"
  
  # Get all record sets for this zone
  try {
    $records = Get-R53ResourceRecordSet -HostedZoneId $zoneId -ErrorAction Stop
  } catch {
    throw "failed to run Get-R53ResourceRecordSet: $_"
  }
  
  
  # Build an object containing some metadata + records (optional but handy)
  $backupObject = [PSCustomObject]@{
    HostedZoneId   = $zoneId
    HostedZoneName = $zoneName
    Config         = $zone.Config
    ResourceRecordSets = $records
    BackupTimestampUTC = (Get-Date).ToUniversalTime()
  }
  
  # Write JSON
  if ($PSCmdlet.ShouldProcess($filePath, "save")) {
    $backupObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8
  }
}

