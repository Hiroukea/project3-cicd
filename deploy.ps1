param(
  [Parameter(Mandatory=$true)][string]$Bucket,
  [Parameter(Mandatory=$true)][string]$InstanceId,
  [string]$Region = "us-east-2",
  [string]$RollbackVersion = ""
)

$ErrorActionPreference = "Stop"

function Send-DeployCommand([string]$S3Key, [string]$Label) {
  Write-Host "==> Sending SSM command ($Label) to instance: $InstanceId"
  $Cmd = @(
    "set -e",
    "cd /tmp",
    "rm -rf oneclick && mkdir oneclick && cd oneclick",
    "aws s3 cp s3://$Bucket/$S3Key release.zip",
    "unzip -o release.zip -d app",
    "chmod +x app/scripts/remote-deploy.sh",
    "app/scripts/remote-deploy.sh $Bucket $S3Key"
  )

  $SendJson = aws ssm send-command `
    --region $Region `
    --instance-ids $InstanceId `
    --document-name "AWS-RunShellScript" `
    --comment "$Label ($S3Key)" `
    --parameters commands="$(($Cmd | ConvertTo-Json -Compress))" `
    --output json

  $Send = $SendJson | ConvertFrom-Json
  $CommandId = $Send.Command.CommandId
  Write-Host "==> CommandId: $CommandId"
  Write-Host "==> Waiting for result..."
  aws ssm wait command-executed --region $Region --command-id $CommandId --instance-id $InstanceId

  Write-Host "==> Output:"
  aws ssm get-command-invocation --region $Region --command-id $CommandId --instance-id $InstanceId `
    --query "StandardOutputContent" --output text

  Write-Host "✅ $Label complete."
}

if ($RollbackVersion -ne "") {
  $S3Key = "releases/release-$RollbackVersion.zip"
  Write-Host "==> Rollback requested: $RollbackVersion"
  Write-Host "==> Using: s3://$Bucket/$S3Key"
  aws s3 ls "s3://$Bucket/$S3Key" --region $Region | Out-Null
  Send-DeployCommand -S3Key $S3Key -Label "ROLLBACK"
  exit 0
}

$Version = (Get-Date -Format "yyyyMMdd-HHmmss")
$ZipName = "release-$Version.zip"
$S3Key = "releases/$ZipName"

Write-Host "==> Creating release zip (linux-safe): $ZipName"
if (Test-Path $ZipName) { Remove-Item $ZipName -Force }
tar -a -c -f $ZipName ec2-app scripts

Write-Host "==> Uploading to S3: s3://$Bucket/$S3Key"
aws s3 cp $ZipName "s3://$Bucket/$S3Key" --region $Region | Out-Null

Send-DeployCommand -S3Key $S3Key -Label "DEPLOY $Version"
