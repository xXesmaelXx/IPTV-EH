# Push IPTV App to GitHub so Actions can build the APK
# Run this script from inside the iptv_player_app folder

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "   IPTV App -> GitHub -> APK Builder  " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "STEP 1: Create a FREE GitHub account (if you don't have one)" -ForegroundColor Yellow
Write-Host "  -> https://github.com/signup" -ForegroundColor White
Write-Host ""
Write-Host "STEP 2: Create a new repository on GitHub:" -ForegroundColor Yellow
Write-Host "  -> https://github.com/new" -ForegroundColor White
Write-Host "  - Repository name: iptv-player-app" -ForegroundColor White
Write-Host "  - Set it to Public" -ForegroundColor White
Write-Host "  - Do NOT add README or .gitignore (leave them unchecked)" -ForegroundColor White
Write-Host "  - Click 'Create repository'" -ForegroundColor White
Write-Host ""

$username = Read-Host "Enter your GitHub username"
$repoName = Read-Host "Enter the repository name you created (default: iptv-player-app)"
if ([string]::IsNullOrWhiteSpace($repoName)) { $repoName = "iptv-player-app" }

$repoUrl = "https://github.com/$username/$repoName.git"
Write-Host ""
Write-Host "Will push to: $repoUrl" -ForegroundColor Cyan
Write-Host ""

# Initialize git if not already
if (-not (Test-Path ".git")) {
    git init
    git branch -M main
}

# Configure git user if not set
$gitUser = git config user.name 2>&1
if ([string]::IsNullOrWhiteSpace($gitUser)) {
    $gitName = Read-Host "Enter your name for git commits"
    $gitEmail = Read-Host "Enter your email for git commits"
    git config user.name $gitName
    git config user.email $gitEmail
}

# Stage and commit
git add -A
git commit -m "Add IPTV Player app source"

# Set remote and push
$existingRemote = git remote 2>&1
if ($existingRemote -match "origin") {
    git remote set-url origin $repoUrl
} else {
    git remote add origin $repoUrl
}

Write-Host ""
Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
Write-Host "(A browser window may open asking you to sign in to GitHub)" -ForegroundColor Yellow
Write-Host ""
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "   Code pushed successfully!          " -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "GitHub Actions is now building your APK." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To download the APK (takes about 5-8 minutes):" -ForegroundColor Yellow
    Write-Host "  1. Go to: https://github.com/$username/$repoName/actions" -ForegroundColor White
    Write-Host "  2. Click the latest workflow run" -ForegroundColor White
    Write-Host "  3. Scroll down to 'Artifacts'" -ForegroundColor White
    Write-Host "  4. Click 'IPTV-Player-APK' to download" -ForegroundColor White
    Write-Host "  5. Unzip it and install the .apk file on your Android phone" -ForegroundColor White
    Write-Host ""
    Write-Host "To install the APK on your phone:" -ForegroundColor Yellow
    Write-Host "  - Enable 'Install from Unknown Sources' in Android Settings > Security" -ForegroundColor White
    Write-Host "  - Transfer the APK to your phone and tap to install" -ForegroundColor White
    Write-Host ""
    Start-Process "https://github.com/$username/$repoName/actions"
} else {
    Write-Host ""
    Write-Host "Push failed. Common fixes:" -ForegroundColor Red
    Write-Host "  - Make sure the GitHub repo exists and is empty" -ForegroundColor Yellow
    Write-Host "  - Sign in to GitHub when the browser opens" -ForegroundColor Yellow
    Write-Host "  - Or use a Personal Access Token: https://github.com/settings/tokens" -ForegroundColor Yellow
}
