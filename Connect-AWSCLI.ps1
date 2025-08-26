<#
        .SYNOPSIS
        obtain temporary aws-credentials using an mfa-device and automatically set them as environment variables
        
        .DESCRIPTION
        This PowerShell script enables you to generate temporary AWS credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN)
        using an MFA (multi-factor authentication) device and automatically set them as environment variables.
        The script uses the AWS CLI and a configured AWS profile for this purpose.
        After successful authentication, the new access credentials are set in the current PowerShell session
        so that subsequent AWS CLI commands can be executed with these temporary permissions.
        The script is particularly suitable for users who regularly work with MFA-protected AWS accounts
        and want to update their access credentials securely and conveniently.
        
        .EXAMPLE
        PS> Connect-AWSCLI.ps1 -MfADeviceARN "arn:aws:iam::<account>:mfa/<virtual-device-name-with-path>"
    #>
param (
  [Parameter(Mandatory=$false,HelpMessage="AWS MFA Device ARN like arn:aws:iam::<account>:mfa/<virtual-device-name-with-path>")]
  [string]$MfADeviceARN,
  
  [Parameter(Mandatory=$true,HelpMessage="current MFA Code")]
  [string]$TokenCode,
  
  [Parameter(Mandatory=$false,HelpMessage="aws-cli-profile (uses profile [default] if ommited)")]
  [string]$ProfileName="default",
  
  [Parameter(Mandatory=$false,HelpMessage="duration how long the token will be valid in seconds (default is 43200sec = 12h)")]
  [int]$TokenDurationSeconds = 43200
)
$AWSSessionInfo = aws sts get-session-token --serial-number $($MfADeviceARN) --token-code $($TokenCode) --duration-seconds $TokenDurationSeconds --profile $($ProfileName) --output json | ConvertFrom-Json
If ($AWSSessionInfo.Credentials.SessionToken) {
  #Set Session Token
  try{$env:AWS_SESSION_TOKEN=$($AWSSessionInfo.Credentials.SessionToken)}
  catch{"An SESSION_TOKEN Error occurred"}
  #Set Access Key
  try{$env:AWS_ACCESS_KEY_ID=$($AWSSessionInfo.Credentials.AccessKeyID)}
  catch{"An ACCESS_KEY_ID Error occurred"}
  #Set Secret access key
  try{$env:AWS_SECRET_ACCESS_KEY=$($AWSSessionInfo.Credentials.SecretAccessKey)}
  catch{"An AWS_SECRET_ACCESS_KEY Error occurred"}

  #notify
  Write-Host "✔  AWS credentials have now been set in the environment as AWS_SESSION_TOKEN, AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
  Write-Host "🔑 AWS_ACCESS_KEY_ID: $($AWSSessionInfo.Credentials.AccessKeyID)"
  Write-Host "📅 Session-Expiration: $($AWSSessionInfo.Credentials.Expiration)"
}