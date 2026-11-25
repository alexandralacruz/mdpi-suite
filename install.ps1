# =============================================================================
# MDPI Review Suite - PowerShell Installer for Windows
# =============================================================================
#
# Compatible with: pi-coding-agent / Claude Code / OpenAI Codex CLI
# Requires: Windows PowerShell 5.1+ or PowerShell 7+
#
# Usage from PowerShell (local clone):
#   .\install.ps1                          # Interactive menu
#   .\install.ps1 -All                     # Install all skills (pi)
#   .\install.ps1 -All -Agent codex        # Install all for Codex
#   .\install.ps1 -All -Agent claude       # Install all for Claude
#   .\install.ps1 -All -Agent all          # Install into all agents
#   .\install.ps1 -Skill reviewer-mdpi-journal  # Install one skill
#   .\install.ps1 -List                    # List skills
#   .\install.ps1 -Status                  # Show status
#   .\install.ps1 -Uninstall reviewer-mdpi-perspective  # Uninstall one skill
#   .\install.ps1 -UninstallAll            # Uninstall all
#
# Remote usage (no clone needed):
#   irm https://raw.githubusercontent.com/alexandralacruz/mdpi-suite/main/install.ps1 | iex
#
# If the script is run without local skills (e.g. piped through `iex`), it
# downloads the repository to a temporary folder and re-runs itself there.
# =============================================================================

param(
    [switch]$All,
    [string]$Agent = "pi",
    [string]$Skill,
    [switch]$List,
    [switch]$Status,
    [string]$Uninstall,
    [switch]$UninstallAll,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Snapshot of the parameters this script was called with. $PSBoundParameters is
# scope-local, so inside a function it would not see the script's parameters.
$ScriptBoundParameters = @{}
foreach ($key in $PSBoundParameters.Keys) { $ScriptBoundParameters[$key] = $PSBoundParameters[$key] }

# --- Configuration -----------------------------------------------------------

# Where this script lives. When piped into `iex` there is no path at all.
$ScriptPath = $null
if ($PSScriptRoot) {
    $ScriptPath = Join-Path $PSScriptRoot "install.ps1"
} elseif ($PSCommandPath) {
    $ScriptPath = $PSCommandPath
} elseif ($MyInvocation.MyCommand.Path) {
    $ScriptPath = $MyInvocation.MyCommand.Path
}
$ScriptDir = if ($ScriptPath) { Split-Path -Parent $ScriptPath } else { $null }

$RepoUrl = if ($env:MDPI_SUITE_REPO_URL) { $env:MDPI_SUITE_REPO_URL } else { "https://github.com/alexandralacruz/mdpi-suite.git" }
$ZipUrl  = if ($env:MDPI_SUITE_ZIP_URL) { $env:MDPI_SUITE_ZIP_URL } else { "https://codeload.github.com/alexandralacruz/mdpi-suite/zip/refs/heads/main" }

$UserHome = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($HOME) { $HOME } else { [Environment]::GetFolderPath("UserProfile") }

function Expand-HomePath($path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return $path }
    if ($path -eq "~") { return $UserHome }
    if ($path -like "~/*" -or $path -like "~\*") { return (Join-Path $UserHome $path.Substring(2)) }
    return $path
}

$PiSkillsDir = if ($env:PI_SKILLS_DIR) { Expand-HomePath $env:PI_SKILLS_DIR } else { Join-Path $UserHome ".pi\agent\skills" }

# Paths per agent
$AgentDirs = @{
    pi     = $PiSkillsDir
    claude = Join-Path $UserHome ".claude\skills"
    codex  = Join-Path $UserHome ".codex\skills"
}

# --- Remote bootstrap --------------------------------------------------------

function Test-RepoDir($dir) {
    if ([string]::IsNullOrWhiteSpace($dir)) { return $false }
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { return $false }
    foreach ($child in @(Get-ChildItem -LiteralPath $dir -Directory -ErrorAction SilentlyContinue)) {
        if (Test-Path -LiteralPath (Join-Path $child.FullName "SKILL.md")) { return $true }
    }
    return $false
}

function Get-ForwardArguments {
    $forward = @()
    if ($All) { $forward += "-All" }
    if ($ScriptBoundParameters.ContainsKey("Agent")) { $forward += @("-Agent", $Agent) }
    if ($ScriptBoundParameters.ContainsKey("Skill")) { $forward += @("-Skill", $Skill) }
    if ($List) { $forward += "-List" }
    if ($Status) { $forward += "-Status" }
    if ($ScriptBoundParameters.ContainsKey("Uninstall")) { $forward += @("-Uninstall", $Uninstall) }
    if ($UninstallAll) { $forward += "-UninstallAll" }
    if ($Help) { $forward += "-Help" }
    return ,$forward
}

function Invoke-RemoteBootstrap {
    Write-Host ""
    Write-Host "MDPI Review Suite - Windows installer" -ForegroundColor Blue
    Write-Host "No local skills found. Downloading the suite..." -ForegroundColor Cyan
    Write-Host ""

    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("mdpi-suite-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    $suiteDir = $null

    # --- Option 1: download and extract the repository ZIP -------------------
    try {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        } catch {
            # Older/newer runtimes may not need (or support) this assignment.
        }

        $zipFile = Join-Path $tmpDir "suite.zip"
        Write-Host "  -> Downloading ZIP..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $ZipUrl -OutFile $zipFile -UseBasicParsing

        Write-Host "  -> Extracting..." -ForegroundColor Cyan
        Expand-Archive -LiteralPath $zipFile -DestinationPath $tmpDir -Force

        # GitHub ZIPs contain a single top-level folder, but be tolerant of
        # archives that unpack install.ps1 directly into the temp folder.
        if (Test-Path -LiteralPath (Join-Path $tmpDir "install.ps1")) {
            $suiteDir = $tmpDir
        } else {
            $suiteDir = Get-ChildItem -LiteralPath $tmpDir -Directory |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "install.ps1") } |
                Select-Object -First 1 -ExpandProperty FullName
        }

        if (-not $suiteDir) {
            $foundScript = Get-ChildItem -LiteralPath $tmpDir -Filter "install.ps1" -File -Recurse -ErrorAction SilentlyContinue |
                Select-Object -First 1 -ExpandProperty FullName
            if ($foundScript) { $suiteDir = Split-Path -Parent $foundScript }
        }
    } catch {
        Write-Host "  [!] ZIP download/extract failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # --- Option 2: fall back to git clone -----------------------------------
    if (-not $suiteDir -and (Get-Command git -ErrorAction SilentlyContinue)) {
        try {
            $gitDir = Join-Path $tmpDir "repo"
            Write-Host "  -> Trying git clone..." -ForegroundColor Cyan
            & git clone --depth 1 $RepoUrl $gitDir 2>&1 | Out-Host
            if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath (Join-Path $gitDir "install.ps1"))) {
                $suiteDir = $gitDir
            }
        } catch {
            Write-Host "  [!] git clone failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    if (-not $suiteDir -or -not (Test-Path -LiteralPath (Join-Path $suiteDir "install.ps1"))) {
        Write-Host ""
        Write-Host "  [X] Could not download the MDPI Review Suite." -ForegroundColor Red
        Write-Host "      Download the ZIP manually and run install.ps1 from it:" -ForegroundColor Yellow
        Write-Host "      https://github.com/alexandralacruz/mdpi-suite/archive/refs/heads/main.zip" -ForegroundColor Yellow
        Write-Host ""
        Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        return 1
    }

    # --- Re-run the real installer from the downloaded copy ------------------
    $forward = Get-ForwardArguments
    # When invoked remotely without arguments (irm | iex), default to -All.
    if ($forward.Count -eq 0 -and -not $ScriptPath) { $forward = @("-All") }

    Write-Host "  -> Running installer from $suiteDir" -ForegroundColor Cyan
    Write-Host ""

    $childScript = Join-Path $suiteDir "install.ps1"
    $powershellExe = if (Get-Command powershell.exe -ErrorAction SilentlyContinue) { "powershell.exe" } else { "pwsh.exe" }

    # Pipe the child output to the host: otherwise it would be captured as the
    # return value of this function when the installer is run through `iex`.
    & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $childScript @forward 2>&1 | Out-Host
    $exitCode = $LASTEXITCODE

    Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    return $exitCode
}

if (-not (Test-RepoDir $ScriptDir)) {
    # Running through `irm | iex`, or from a lone copy of install.ps1.
    # Use `return` (not `exit`) so an interactive PowerShell session survives.
    $bootstrapExit = Invoke-RemoteBootstrap
    if ($null -ne $bootstrapExit -and $bootstrapExit -is [int]) {
        $global:LASTEXITCODE = $bootstrapExit
    }
    return
}

# --- Functions ---------------------------------------------------------------

function Get-AgentDir($agentName) {
    if ($AgentDirs.ContainsKey($agentName)) {
        return $AgentDirs[$agentName]
    }
    Write-Host "Error: Agent '$agentName' not recognized. Use: pi, claude, codex, all" -ForegroundColor Red
    exit 1
}

function Get-AgentNames($agentName) {
    if ($agentName -eq "all") { return @($AgentDirs.Keys | Sort-Object) }
    if (-not $AgentDirs.ContainsKey($agentName)) {
        Write-Host "Error: Agent '$agentName' not recognized. Use: pi, claude, codex, all" -ForegroundColor Red
        exit 1
    }
    return @($agentName)
}

function Get-AvailableSkills {
    Get-ChildItem -LiteralPath $ScriptDir -Directory | Where-Object {
        ($_.Name -notlike ".*") -and
        ($_.Name -ne "scripts") -and
        ($_.Name -ne "node_modules") -and
        (Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md"))
    } | ForEach-Object { $_.Name } | Sort-Object
}

function Get-SkillDescription($skillName) {
    $skillFile = Join-Path (Join-Path $ScriptDir $skillName) "SKILL.md"
    if (Test-Path -LiteralPath $skillFile) {
        $content = Get-Content -LiteralPath $skillFile -Raw -Encoding UTF8

        $frontMatter = [regex]::Match($content, '(?ms)\A---\s*\r?\n(.*?)\r?\n---')
        if ($frontMatter.Success) {
            $descMatch = [regex]::Match($frontMatter.Groups[1].Value, '(?m)^description:\s*(.*(?:\r?\n[ \t]+.*)*)')
            if ($descMatch.Success) {
                $desc = ($descMatch.Groups[1].Value -replace '\r?\n[ \t]*', ' ').Trim()
                if ($desc -and $desc -ne ">" -and $desc -ne "|") {
                    return $desc.Substring(0, [Math]::Min(120, $desc.Length))
                }
            }
        }
    }
    return "(no description)"
}

function Install-Skill($skillName, $destDir) {
    $src = Join-Path $ScriptDir $skillName
    $dst = Join-Path $destDir $skillName

    if (-not (Test-Path -LiteralPath (Join-Path $src "SKILL.md"))) {
        Write-Host "  [X] $skillName - not a valid skill" -ForegroundColor Red
        return $false
    }

    if (Test-Path -LiteralPath $dst) {
        Write-Host "  [!] $skillName already installed" -ForegroundColor Yellow
        return $true
    }

    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
    Write-Host "  [OK] $skillName -> $dst" -ForegroundColor Green
    return $true
}

function Uninstall-Skill($skillName, $destDir) {
    $dst = Join-Path $destDir $skillName
    if (-not (Test-Path -LiteralPath $dst)) {
        Write-Host "  [-] $skillName - not installed" -ForegroundColor Yellow
        return $false
    }
    Remove-Item -LiteralPath $dst -Recurse -Force
    Write-Host "  [OK] $skillName uninstalled" -ForegroundColor Green
    return $true
}

function Test-IsInstalled($skillName, $destDir) {
    return (Test-Path -LiteralPath (Join-Path (Join-Path $destDir $skillName) "SKILL.md"))
}

# --- Commands ----------------------------------------------------------------

function Show-List {
    Write-Host ""
    Write-Host "MDPI Review Suite - Available skills" -ForegroundColor Blue
    Write-Host "------------------------------------" -ForegroundColor Blue
    Write-Host ""
    Write-Host ("  {0,-28} {1}" -f "SKILL", "DESCRIPTION")
    Write-Host ("  {0,-28} {1}" -f "-----", "----------")

    $skills = @(Get-AvailableSkills)
    foreach ($s in $skills) {
        $desc = Get-SkillDescription $s
        Write-Host ("  {0,-28} {1}" -f $s, $desc.Substring(0, [Math]::Min(85, $desc.Length)))
    }
    Write-Host ""
    Write-Host "  Total: $($skills.Count) skills"
    Write-Host ""
}

function Show-Status {
    Write-Host ""
    Write-Host "Installation status ($Agent)" -ForegroundColor Blue
    Write-Host "---------------------------" -ForegroundColor Blue

    foreach ($agentName in (Get-AgentNames $Agent)) {
        $destDir = Get-AgentDir $agentName
        Write-Host ""
        Write-Host "  $agentName -> $destDir" -ForegroundColor Cyan
        Write-Host ""

        $installed = 0
        $total = 0
        foreach ($s in (Get-AvailableSkills)) {
            $total++
            if (Test-IsInstalled $s $destDir) {
                $installed++
                Write-Host "  [OK] $s" -ForegroundColor Green
            } else {
                Write-Host "  [X] $s" -ForegroundColor Red
            }
        }
        Write-Host ""
        Write-Host "  $installed / $total skills installed"
    }
    Write-Host ""
}

function Install-All {
    $destDir = Get-AgentDir $Agent
    Write-Host ""
    Write-Host "Installing MDPI Review Suite (all skills)" -ForegroundColor Blue
    Write-Host "-----------------------------------------" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  Destination: $destDir" -ForegroundColor Cyan
    Write-Host "  Agent:       $Agent" -ForegroundColor Cyan
    Write-Host ""

    $count = 0
    $errors = 0
    foreach ($s in (Get-AvailableSkills)) {
        if (Install-Skill $s $destDir) { $count++ } else { $errors++ }
    }

    Write-Host ""
    Write-Host "  Result: $count installed" -ForegroundColor Green
    if ($errors -gt 0) { Write-Host "  Errors: $errors" -ForegroundColor Red }
    Write-Host ""
}

function Install-AllAgents {
    Write-Host ""
    Write-Host "Installing into all agents" -ForegroundColor Blue
    Write-Host "--------------------------" -ForegroundColor Blue
    Write-Host ""

    foreach ($agentName in (Get-AgentNames "all")) {
        $destDir = Get-AgentDir $agentName
        Write-Host "  -> $agentName -> $destDir" -ForegroundColor Cyan
        foreach ($s in (Get-AvailableSkills)) {
            Install-Skill $s $destDir | Out-Null
        }
        Write-Host ""
    }
    Write-Host "  [OK] Multi-agent installation complete." -ForegroundColor Green
    Write-Host ""
}

function Install-One($skillName) {
    $found = @(Get-AvailableSkills | Where-Object { $_ -like "*$skillName*" })
    if ($found.Count -eq 0) {
        Write-Host "Error: Skill '$skillName' not found." -ForegroundColor Red
        exit 1
    }
    if ($found.Count -gt 1) {
        Write-Host "Multiple skills match '$skillName':" -ForegroundColor Yellow
        $found | ForEach-Object { Write-Host "  - $_" }
        exit 1
    }

    $skill = $found[0]
    $destDir = Get-AgentDir $Agent
    Write-Host ""
    Write-Host "Installing: $skill" -ForegroundColor Blue
    Write-Host ""
    Install-Skill $skill $destDir | Out-Null
    Write-Host ""
    Write-Host "  [OK] Done. Use /skill:$skill in your agent." -ForegroundColor Green
    Write-Host ""
}

function Uninstall-One($skillName) {
    $found = @(Get-AvailableSkills | Where-Object { $_ -like "*$skillName*" })
    if ($found.Count -eq 0) {
        Write-Host "Error: Skill '$skillName' not found." -ForegroundColor Red
        exit 1
    }
    if ($found.Count -gt 1) {
        Write-Host "Multiple skills match '$skillName':" -ForegroundColor Yellow
        $found | ForEach-Object { Write-Host "  - $_" }
        exit 1
    }

    $skill = $found[0]
    $destDir = Get-AgentDir $Agent
    Write-Host ""
    Uninstall-Skill $skill $destDir | Out-Null
    Write-Host ""
}

function Uninstall-AllSkills {
    Write-Host ""
    Write-Host "Uninstalling all MDPI Review Suite skills ($Agent)" -ForegroundColor Red
    Write-Host "---------------------------------------------------" -ForegroundColor Red

    foreach ($agentName in (Get-AgentNames $Agent)) {
        $destDir = Get-AgentDir $agentName
        Write-Host ""
        Write-Host "  $agentName -> $destDir" -ForegroundColor Cyan
        foreach ($s in (Get-AvailableSkills)) {
            Uninstall-Skill $s $destDir | Out-Null
        }
    }
    Write-Host ""
}

function Show-HelpText {
    Write-Host ""
    Write-Host "MDPI Review Suite - PowerShell Installer" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  USAGE:"
    Write-Host "    .\install.ps1                          Interactive menu"
    Write-Host "    .\install.ps1 -All                     Install all (pi)"
    Write-Host "    .\install.ps1 -All -Agent codex        Install all for Codex"
    Write-Host "    .\install.ps1 -All -Agent claude       Install all for Claude"
    Write-Host "    .\install.ps1 -All -Agent all          All agents"
    Write-Host "    .\install.ps1 -Skill reviewer-mdpi-journal  Install one"
    Write-Host "    .\install.ps1 -List                    List skills"
    Write-Host "    .\install.ps1 -Status                  Show status"
    Write-Host "    .\install.ps1 -Uninstall reviewer-mdpi-perspective  Uninstall one"
    Write-Host "    .\install.ps1 -UninstallAll            Uninstall all"
    Write-Host ""
    Write-Host "  REMOTE (no clone needed):"
    Write-Host "    irm https://raw.githubusercontent.com/alexandralacruz/mdpi-suite/main/install.ps1 | iex"
    Write-Host ""
    Write-Host "  NOTE:"
    Write-Host "    If PowerShell blocks the script, run:"
    Write-Host "    powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -All"
    Write-Host ""
}

# --- Entrypoint ---------------------------------------------------------------

if ($Help) { Show-HelpText; exit 0 }
if ($List) { Show-List; exit 0 }
if ($Status) { Show-Status; exit 0 }

if ($All) {
    if ($Agent -eq "all") {
        Install-AllAgents
    } else {
        Install-All
    }
    exit 0
}

if ($UninstallAll) {
    Uninstall-AllSkills
    exit 0
}

if ($Uninstall) {
    Uninstall-One $Uninstall
    exit 0
}

if ($Skill) {
    Install-One $Skill
    exit 0
}

# Interactive menu
Show-List
$choice = Read-Host "  Enter a skill name (or 'all'/'q')"
if ($choice -eq "q") { exit 0 }
if ($choice -eq "all") { Install-All; exit 0 }
if ($choice) { Install-One $choice }
