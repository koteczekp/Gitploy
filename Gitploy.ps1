$ErrorActionPreference = "Stop"

# 1. Require GitHub CLI
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
    Write-Host "Error: GitHub CLI (gh) is not installed." -ForegroundColor Red
    exit
}

# --- TUI Helper Function ---
function Show-TuiMenu {
    param([string]$Title, [string[]]$Options)
    $selectedIndex = 0
    while ($true) {
        Clear-Host
        Write-Host "`n  $Title" -ForegroundColor Cyan
        Write-Host "  Use Up/Down arrows to move, Enter to select.`n" -ForegroundColor DarkGray

        for ($i = 0; $i -lt $Options.Count; $i++) {
            if ($i -eq $selectedIndex) {
                Write-Host "  > $($Options[$i]) " -ForegroundColor Black -BackgroundColor Cyan
            } else {
                Write-Host "    $($Options[$i]) "
            }
        }

        $key = [System.Console]::ReadKey($true)
        if ($key.Key -eq 'UpArrow') {
            $selectedIndex = [math]::Max(0, $selectedIndex - 1)
        } elseif ($key.Key -eq 'DownArrow') {
            $selectedIndex = [math]::Min($Options.Count - 1, $selectedIndex + 1)
        } elseif ($key.Key -eq 'Enter') {
            return $selectedIndex
        }
    }
}

# --- Configuration Phase ---
$GithubAccount = "koteczekp"

# Get script filename (e.g., "Gitploy" or "OrbitalFronts")
$DefaultName = if ($PSCommandPath) { 
    [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath) 
} else { 
    [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name) 
}

# TUI Step 1: Does it exist?
$actionOptions = @(
    "Create a NEW repository on GitHub",
    "Link to an EXISTING repository on GitHub"
)
$actionIndex = Show-TuiMenu -Title "GitHub Repository Setup" -Options $actionOptions
$CreateNew = ($actionIndex -eq 0)

# TUI Step 2: Repo Name Prompt
Clear-Host
Write-Host "`n  Target Repository Setup" -ForegroundColor Cyan
$InputName = Read-Host "  Input repo name (leave blank for $DefaultName)"
$RepoName = if ([string]::IsNullOrWhiteSpace($InputName)) { $DefaultName } else { $InputName.Trim() }

# TUI Step 3: Visibility (Only if creating new)
$VisibilityFlag = ""
$CleanVisibility = "Existing Repository"
if ($CreateNew) {
    $visibilityOptions = @("Private (Only you can see this repository)", "Public (Anyone on the internet can see this repository)")
    $choiceIndex = Show-TuiMenu -Title "Set visibility for $GithubAccount/$RepoName" -Options $visibilityOptions
    $VisibilityFlag = if ($choiceIndex -eq 0) { "--private" } else { "--public" }
    $CleanVisibility = $visibilityOptions[$choiceIndex].Split('(')[0].Trim()
}

# TUI Step 4: Commit Message
Clear-Host
Write-Host "`n  Configuration Summary" -ForegroundColor Cyan
Write-Host "  Target: $GithubAccount/$RepoName" -ForegroundColor Yellow
if ($CreateNew) {
    Write-Host "  Action: Create New ($CleanVisibility)`n" -ForegroundColor Green
} else {
    Write-Host "  Action: Link Existing`n" -ForegroundColor Green
}

$CommitMsg = Read-Host "  Enter commit message (Leave blank for 'Initial commit')"
if ([string]::IsNullOrWhiteSpace($CommitMsg)) { $CommitMsg = "Initial commit" }

# --- Execution Phase ---
Clear-Host
Write-Host "🚀 Publishing to '$GithubAccount/$RepoName'..." -ForegroundColor Cyan

git config --global http.postBuffer 1048576000
git config --global core.compression 0

# Initialize local repo if it doesn't exist
if (-not (Test-Path -Path ".git")) {
    Write-Host "-> Initializing local Git repository..." -ForegroundColor DarkGray
    git init | Out-Null
}

# Enforce the branch name
git branch -M main

# Create remote if requested
if ($CreateNew) {
    Write-Host "-> Creating new repository on GitHub..." -ForegroundColor DarkGray
    $Script:ErrorActionPreference = "Continue"
    $ghOutput = gh repo create "$GithubAccount/$RepoName" $VisibilityFlag --source="." --remote="origin" 2>&1
    $Script:ErrorActionPreference = "Stop"
} else {
    Write-Host "-> Linking to existing repository on GitHub..." -ForegroundColor DarkGray
}

# Force the remote URL link
$RemoteUrl = "https://github.com/$GithubAccount/$RepoName.git"
git remote remove origin 2>$null
git remote add origin $RemoteUrl

Write-Host "-> Staging files..." -ForegroundColor DarkGray
git add .

# Check if there are uncommitted changes
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "-> Committing..." -ForegroundColor DarkGray
    git commit -m $CommitMsg
} else {
    Write-Host "-> No new changes to commit (Files are already committed locally)." -ForegroundColor DarkGray
}

Write-Host "-> Pushing to GitHub..." -ForegroundColor DarkGray
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Successfully published to https://github.com/$GithubAccount/$RepoName" -ForegroundColor Green
} else {
    Write-Host "`n❌ Push failed. Read the red error message from Git above." -ForegroundColor Red
}