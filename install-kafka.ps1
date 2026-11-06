#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Automated Apache Kafka Installation Script for Windows

.DESCRIPTION
    This script automates the COMPLETE Apache Kafka installation on Windows, including:
    1. Pre-flight checks (Java, javac, existing C:\kafka folder, tar.exe)
    2. Kafka 3.4.0 download and extraction
    3. Environment variables configuration (KAFKA_HOME, PATH)
    4. ZooKeeper and Kafka broker configuration (zookeeper.properties, server.properties)
    5. Data and log directories creation (zookeeper-data, kafka-logs)
    6. WMIC compatibility check on the Windows batch scripts
    7. Optional start of ZooKeeper and Kafka broker (-Start switch)

.NOTES
    Author:  RAJAN SAHU
    Date:    2026-11-06
    Version: 1.0

    REQUIREMENTS:
    - Run as Administrator (right-click PowerShell > Run as Administrator)
    - Internet connection for downloads
    - Windows 10/11 (tar.exe available)
    - Java (JDK) already installed and available in PATH

    USAGE:
    1. Right-click PowerShell and "Run as Administrator"
    2. Run:  Set-ExecutionPolicy Bypass -Scope Process -Force
    3. Run:  .\install-kafka.ps1
       Optional (install and start both services):  .\install-kafka.ps1 -Start

    You can customize the variables below before running.
#>

param(
    [switch]$Start
)

# ============================================================================
#  CONFIGURATION - Modify these as needed before running
# ============================================================================

$ErrorActionPreference = "Stop"

$KafkaVersion = "3.4.0"
$ScalaVersion = "2.13"
$KafkaFolder = "C:\kafka"
$ArchiveName = "kafka_${ScalaVersion}-${KafkaVersion}.tgz"
$DownloadUrl = "https://archive.apache.org/dist/kafka/${KafkaVersion}/${ArchiveName}"
$WorkFolder = Join-Path $env:TEMP "kafka-install"
$ArchivePath = Join-Path $WorkFolder $ArchiveName
$ExtractFolder = Join-Path $WorkFolder "kafka_${ScalaVersion}-${KafkaVersion}"

# ============================================================================
#  HELPER FUNCTIONS
# ============================================================================

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-Property([string]$FilePath, [string]$Key, [string]$Value) {
    $content = Get-Content -LiteralPath $FilePath -Raw
    $pattern = "(?m)^\s*#?\s*" + [regex]::Escape($Key) + "\s*=.*$"
    if ([regex]::IsMatch($content, $pattern)) {
        $content = [regex]::Replace(
            $content,
            $pattern,
            "$Key=$Value",
            [System.Text.RegularExpressions.RegexOptions]::Multiline
        )
    } else {
        $content += "`r`n$Key=$Value`r`n"
    }
    Set-Content -LiteralPath $FilePath -Value $content -Encoding ASCII
}

# ============================================================================
#  MAIN
# ============================================================================

Write-Host "Apache Kafka $KafkaVersion installer" -ForegroundColor Green
Write-Host "Install location: $KafkaFolder"

if (-not (Test-Administrator)) {
    throw "Please close this window, open PowerShell using 'Run as administrator', and run the script again."
}

Write-Step "Checking Java"
$javaCommand = Get-Command java -ErrorAction SilentlyContinue
if (-not $javaCommand) {
    throw "Java was not found in PATH. Install a JDK and add its bin folder to PATH first."
}
java -version
$javacCommand = Get-Command javac -ErrorAction SilentlyContinue
if ($javacCommand) {
    javac -version
} else {
    Write-Warning "javac was not found. Kafka needs the Java runtime; however, fix your JDK PATH so javac is available too."
}

if (Test-Path $KafkaFolder) {
    throw "$KafkaFolder already exists. To avoid overwriting your existing Kafka files, rename or back up that folder, then run this installer again."
}

Write-Step "Preparing temporary download folder"
New-Item -ItemType Directory -Path $WorkFolder -Force | Out-Null

Write-Step "Downloading Kafka $KafkaVersion"
if (-not (Test-Path $ArchivePath)) {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ArchivePath
} else {
    Write-Host "Using existing download: $ArchivePath"
}

Write-Step "Extracting Kafka archive"
if (-not (Get-Command tar.exe -ErrorAction SilentlyContinue)) {
    throw "Windows tar.exe was not found. Install 7-Zip or use a current Windows 10/11 installation with tar.exe."
}
if (Test-Path $ExtractFolder) {
    Remove-Item $ExtractFolder -Recurse -Force
}
tar.exe -xzf $ArchivePath -C $WorkFolder
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $ExtractFolder)) {
    throw "Kafka archive extraction failed."
}

Write-Step "Installing Kafka into C:\kafka"
Move-Item -LiteralPath $ExtractFolder -Destination $KafkaFolder

Write-Step "Configuring ZooKeeper and Kafka storage"
$ZooKeeperConfig = Join-Path $KafkaFolder "config\zookeeper.properties"
$BrokerConfig = Join-Path $KafkaFolder "config\server.properties"

Set-Property -FilePath $ZooKeeperConfig -Key "dataDir" -Value "C:/kafka/zookeeper-data"
Set-Property -FilePath $BrokerConfig -Key "log.dirs" -Value "C:/kafka/kafka-logs"

New-Item -ItemType Directory -Path "C:\kafka\zookeeper-data" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\kafka\kafka-logs" -Force | Out-Null

Write-Step "Setting user environment variable KAFKA_HOME"
[Environment]::SetEnvironmentVariable("KAFKA_HOME", $KafkaFolder, "User")
$currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$kafkaBin = "%KAFKA_HOME%\bin\windows"
if (($currentUserPath -split ";") -notcontains $kafkaBin) {
    $newUserPath = if ([string]::IsNullOrWhiteSpace($currentUserPath)) {
        $kafkaBin
    } else {
        "$currentUserPath;$kafkaBin"
    }
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
}

Write-Host "`nKafka installation and configuration completed." -ForegroundColor Green
Write-Host "KAFKA_HOME = $KafkaFolder"
Write-Host "ZooKeeper data = C:\kafka\zookeeper-data"
Write-Host "Kafka logs = C:\kafka\kafka-logs"

Write-Step "Checking Windows Kafka scripts for WMIC references"
$wmicFiles = Get-ChildItem (Join-Path $KafkaFolder "bin\windows") -Filter "*.bat" |
    Select-String -Pattern "\bwmic\b" -List
if ($wmicFiles) {
    Write-Warning "This Kafka distribution contains a batch-script reference to WMIC:"
    $wmicFiles | ForEach-Object { Write-Host $_.Path }
    Write-Host "The installer has not modified Kafka batch files automatically. If startup reports that WMIC is missing, send the exact error and the named batch-file lines so the compatibility fix can be applied safely."
} else {
    Write-Host "No WMIC reference was found in the Windows batch scripts."
}

if ($Start) {
    Write-Step "Starting ZooKeeper in a separate CMD window"
    $zkCommand = 'cd /d C:\kafka && bin\windows\zookeeper-server-start.bat config\zookeeper.properties'
    Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $zkCommand

    Start-Sleep -Seconds 5

    Write-Step "Starting Kafka broker in a separate CMD window"
    $brokerCommand = 'cd /d C:\kafka && bin\windows\kafka-server-start.bat config\server.properties'
    Start-Process -FilePath "cmd.exe" -ArgumentList "/k", $brokerCommand

    Write-Host "`nTwo CMD windows were opened. Keep both running." -ForegroundColor Green
} else {
    Write-Host "`nTo start ZooKeeper, open CMD and run:" -ForegroundColor Yellow
    Write-Host "cd /d C:\kafka"
    Write-Host "bin\windows\zookeeper-server-start.bat config\zookeeper.properties"
    Write-Host "`nOpen a SECOND CMD window and run:" -ForegroundColor Yellow
    Write-Host "cd /d C:\kafka"
    Write-Host "bin\windows\kafka-server-start.bat config\server.properties"
    Write-Host "`nTo install and start both services in one go next time, use: .\install-kafka.ps1 -Start"
}

Write-Host "`nAfter installation, close and reopen CMD/PowerShell for the updated user PATH to take effect." -ForegroundColor Gray
