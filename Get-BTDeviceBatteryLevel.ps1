
# print battery level of (bluetooth) device (and connection-state)
# DS 2025-08-26

param (
  [Parameter(Mandatory = $false, HelpMessage = "Name of the device (i.e. 'Jabra Evolve 65')")]
  [string]$devicename = "Jabra Evolve 65"
)

function Find-PNPDevices {
  param (
    [string]$friendlyName
  )
  return Get-PnpDevice -FriendlyName "*$friendlyName*" -PresentOnly | Where-Object Status -eq "OK"
}


function Get-ConnectionState {
  param (
    [Object]$PNPDevice
  )
  If ((Get-PnpDeviceProperty -InstanceID $PNPDevice.InstanceID -KeyName '{83DA6326-97A6-4088-9453-A1923F573B29} 15').Data -eq "True") {
    return $true
  }
  return $false
}


function Get-BatteryLevel {
  param (
    [Object]$PNPDevice
  )
  if($PNPDevice.Class -eq "System") {
    $deviceProperty = Get-PnpDeviceProperty -InstanceID $PNPDevice.InstanceID -KeyName "{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2" | Where-Object Type -ne Empty
    return $deviceProperty.Data
  }
  return 0
}

function Write-FormattedBatteryLevel {
  param (
    [int]$BatteryLevel
  )
  If ($BatteryLevel -ge 90) {
    $batteryLevelFormat = @{
      BackgroundColor = "Green"
      ForegroundColor = "Black"
      Icon            = "$([char]::ConvertFromUtf32(0xf240))"
    }
  }
  elseif ($BatteryLevel -ge 70) {
    $batteryLevelFormat = @{
      BackgroundColor = "DarkGreen"
      ForegroundColor = "DarkGray"
      Icon            = "$([char]::ConvertFromUtf32(0xf241))"
    }
  }
  elseif ($BatteryLevel -ge 50) {
    $batteryLevelFormat = @{
      BackgroundColor = "DarkGreen"
      ForegroundColor = "DarkGray"
      Icon            = "$([char]::ConvertFromUtf32(0xf242))"
    }
  }
  elseif ($BatteryLevel -ge 30) {
    $batteryLevelFormat = @{
      BackgroundColor = "DarkYellow"
      ForegroundColor = "DarkGray"
      Icon            = "$([char]::ConvertFromUtf32(0xf243))"
    }
  }
  elseif ($BatteryLevel -ge 10) { 
    $batteryLevelFormat = @{
      BackgroundColor = "DarkRed"
      ForegroundColor = "White"
      Icon            = "$([char]::ConvertFromUtf32(0xf244))"
    }
  }
  else {
    $batteryLevelFormat = @{
      BackgroundColor = "Red"
      ForegroundColor = "White"
      Icon            = "$([char]::ConvertFromUtf32(0xf244))"
    }
  }
  $params = @{
    Message = "$($batteryLevelFormat.Icon)  $BatteryLevel%"
    ForegroundColor = $batteryLevelFormat.ForegroundColor
    BackgroundColor = $batteryLevelFormat.BackgroundColor
  }
  
  # use write-bubble if present
  if (Get-Command 'Write-Bubble' -errorAction SilentlyContinue) {
    Write-Bubble @params
  } else {
    Write-Host @params
  }
  
}


function main {
  param (
    [string]$devicename
  )
  $Script:BatteryLevel = 0
  $Script:IsConnected = $false
  
  $Script:percentComplete = 0
  
  Write-Progress -Activity "getting battery-level for >>$devicename<<" -PercentComplete $PercentComplete
  
  $PNPDevices = Find-PNPDevices -friendlyName $devicename
  foreach ($PNPDevice in $PNPDevices) {
    $i = $i + 1
    $PercentComplete = ($i / $PNPDevices.count) * 100
    Write-Progress -Activity "getting battery-level for >>$devicename<<" -Status "querying $($PNPDevice.Class)/$($PNPDevice.FriendlyName)" -PercentComplete $PercentComplete
    If (!$IsConnected) {
      $IsConnected = Get-ConnectionState -PNPDevice $PNPDevice
    }
    
    if (!($BatteryLevel -gt 0)) {
      $BatteryLevel = Get-BatteryLevel -PNPDevice $PNPDevice
    }
    
  }
  
  if (!$IsConnected) {
    Write-Host "Device >>$devicename<< seems not to be connected, but last batterylevel was: " -NoNewline
  }
  Write-FormattedBatteryLevel $BatteryLevel
}

main -devicename $devicename