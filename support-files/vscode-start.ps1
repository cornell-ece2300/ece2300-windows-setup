# ========================================================================
# ECE 2300 VS Code Launcher
# ========================================================================

$Root        = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserData    = Join-Path $env:LOCALAPPDATA "ece2300\vscode-user-data"
$Settings    = Join-Path $Root "vscode-settings"
$RemoteHome  = "/home/$env:USERNAME/ece2300"

Write-Host @"

This is the the ECE 2300 VS Code setup script for the 225 Upson 
Workstations which will do the following steps:

 - install the following three VS Code extensions
    + Remote SSH
    + Verilog HDL
    + Surfer
 - configure SSH for ecelinux
 - start VS Code connected to ecelinux
 - open the file explorer at your ECE 2300 directory
 - install the Verilog HDL extension on the server
 - open a terminal

"@

# ------------------------------------------------------------------------
# Get ecelinux server number
# ------------------------------------------------------------------------

# Ask which ecelinux server to use
$ServerNum = Read-Host "Enter ecelinux server number (1-20)"

# Validate the input
if ($ServerNum -notmatch '^\d+$' -or
  [int]$ServerNum -lt 1 -or
  [int]$ServerNum -gt 20) {

  Write-Host "Please enter a number from 1 to 20."
  exit 1
}

# Convert 1 -> 01, 7 -> 07, etc.
$Server = "{0:D2}" -f [int]$ServerNum

# Build the full hostname
$HostName = "ecelinux-$Server.ece.cornell.edu"

Write-Host ""
Write-Host "Using $HostName"
Write-Host ""

# ------------------------------------------------------------------------
# Install required VS Code extensions
# ------------------------------------------------------------------------

code --install-extension ms-vscode-remote.remote-ssh
code --install-extension mshr-h.VerilogHDL
code --install-extension surfer-project.surfer

# ------------------------------------------------------------------------
# Recreate VS Code user-data directory from scratch
# ------------------------------------------------------------------------

if (Test-Path $UserData) {
  Remove-Item $UserData -Recurse -Force
}

Copy-Item $Settings $UserData -Recurse

# ------------------------------------------------------------------------
# Create SSH configuration
# ------------------------------------------------------------------------

$SshDir = Join-Path $env:USERPROFILE ".ssh"

if (-not (Test-Path $SshDir)) {
  New-Item -ItemType Directory -Path $SshDir | Out-Null
}

@"
Host ecelinux-*.ece.cornell.edu
  User $env:USERNAME
"@ | Set-Content -Encoding ascii (Join-Path $SshDir "config")

if (-not (Test-Path $SshDir)) {
    New-Item -ItemType Directory -Path $SshDir | Out-Null
}

$KnownHostsSrc = Join-Path $Root "known_hosts"
$KnownHostsDst = Join-Path $SshDir "known_hosts"

Copy-Item $KnownHostsSrc $KnownHostsDst -Force

# ------------------------------------------------------------------------
# Start VS Code
# ------------------------------------------------------------------------

code `
  --disable-workspace-trust `
  --user-data-dir "$UserData" `
  --remote "ssh-remote+$HostName" `
  "$RemoteHome"
