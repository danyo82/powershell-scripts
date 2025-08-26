# Anmeldung und Abmeldung für den aktuellen User aus dem Eventlog auslesen und als Grid-View darstellen
# der Timestamp des ausgewählten Eintrag wird ins Clipboard übernommen (im Kimai-Uhrzeit-Format)
# DS 2019

$logStartTime =(Get-Date).addDays(-5)
$logUserID = $env:UserName

# 1 - Benutzeranmeldebenachrichtigung für Sitzung N empfangen.
$events = Get-WinEvent -FilterHashTable @{
  LogName = "Microsoft-Windows-User Profile Service/Operational"
  ID = 1
  StartTime = $logStartTime
  UserID = $logUserID
}
# 3 - Benutzerabmeldebenachrichtigung für Sitzung N empfangen.
$events += Get-WinEvent -FilterHashTable @{
  LogName = "Microsoft-Windows-User Profile Service/Operational"
  ID = 3
  StartTime = $logStartTime
  UserID = $logUserID
}
# Bildschirmsperre klappt nur mit erhöhten Rechten :-(
# # 4800 - Die Arbeitsstation wurde gesperrt.
# $events += Get-WinEvent -FilterHashTable @{
#   LogName = "Security"
#   ID = 4800
#   StartTime = $logStartTime
#   UserID = $logUserID
# }
# #4801 - Die Arbeitsstation wurde entsperrt.
# $events += Get-WinEvent -FilterHashTable @{
#   LogName = "Security"
#   ID = 4801
#   StartTime = $logStartTime
#   UserID = $logUserID
# }

$selectedLogontimestamp = $events | Sort-Object timecreated -Descending | Out-GridView -PassThru -Title "Letze Anmeldungen" | Select-Object -ExpandProperty timecreated
Set-Clipboard -Verbose -Value $selectedLogontimestamp.ToString('HH:mm:ss')
