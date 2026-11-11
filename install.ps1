# =============================================================================
# MDPI Review Suite - PowerShell Installer for Windows
# =============================================================================
#
# Compatible with: pi-coding-agent / Claude Code / OpenAI Codex CLI
#
# Usage from PowerShell:
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

# --- Configuration -----------------------------------------------------------

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsDir = if ($env:PI_SKILLS_DIR) { $env:PI_SKILLS_DIR } else { "$env:USERPROFILE\.pi\agent\skills" }

# Paths per agent
$AgentDirs = @{
    pi     = "$env:USERPROFILE\.pi\agent\skills"
    claude = "$env:USERPROFILE\.claude\skills"
    codex  = "$env:USERPROFILE\.codex\skills"
}

$RepoUrl = "https://github.com/alexandralacruz/mdpi-suite.git"

# --- Functions ---------------------------------------------------------------

function Get-AgentDir($agentName) {
    if ($agentName -eq "pi") {
        # pi uses $SkillsDir to respect the PI_SKILLS_DIR variable
        return $SkillsDir
    }
    if ($AgentDirs.ContainsKey($agentName)) {
        return $AgentDirs[$agentName]
    }
    Write-Host "Error: Agent '$agentName' not recognized. Use: pi, claude, codex, all" -ForegroundColor Red
    exit 1
}

function Get-AvailableSkills {
    Get-ChildItem -Path $ScriptDir -Directory | Where-Object {
        ($_.Name -notlike ".*") -and
        ($_.Name -ne "scripts") -and
        ($_.Name -ne "node_modules") -and
        (Test-Path (Join-Path $_.FullName "SKILL.md"))
    } | ForEach-Object { $_.Name } | Sort-Object
}

function Get-SkillDescription($skillName) {
    $skillFile = Join-Path $ScriptDir $skillName "SKILL.md"
    if (Test-Path $skillFile) {
        $content = Get-Content $skillFile -Raw
        if ($content -match "description:\s*(.+?)(\r?\n|$)") {
            return $Matches[1].Substring(0, [Math]::Min(120, $Matches[1].Length))
        }
    }
    return "(no description)"
}

function Install-Skill($skillName, $destDir) {
    $src = Join-Path $ScriptDir $skillName
    $dst = Join-Path $destDir $skillName

    if (-not (Test-Path (Join-Path $src "SKILL.md"))) {
        Write-Host "  [X] $skillName - not a valid skill" -ForegroundColor Red
        return $false
    }

    if (Test-Path $dst) {
        Write-Host "  [!] $skillName already installed" -ForegroundColor Yellow
        return $true
    }

    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Copy-Item -Recurse $src $dst
    Write-Host "  [OK] $skillName -> $dst" -ForegroundColor Green
    return $true
}

function Uninstall-Skill($skillName, $destDir) {
    $dst = Join-Path $destDir $skillName
    if (-not (Test-Path $dst)) {
        Write-Host "  [-] $skillName - not installed" -ForegroundColor Yellow
        return $false
    }
    Remove-Item -Recurse -Force $dst
    Write-Host "  [OK] $skillName uninstalled" -ForegroundColor Green
    return $true
}

function Test-IsInstalled($skillName, $destDir) {
    return (Test-Path (Join-Path $destDir $skillName "SKILL.md"))
}

# --- Commands ----------------------------------------------------------------

function Show-List {
    Write-Host ""
    Write-Host "MDPI Review Suite - Available skills" -ForegroundColor Blue
    Write-Host "------------------------------------" -ForegroundColor Blue
    Write-Host ""
    Write-Host ("  {0,-28} {1}" -f "SKILL", "DESCRIPTION")
    Write-Host ("  {0,-28} {1}" -f "-----", "----------")

    $skills = Get-AvailableSkills
    foreach ($s in $skills) {
        $desc = Get-SkillDescription $s
        Write-Host ("  {0,-28} {1}" -f $s, $desc.Substring(0, [Math]::Min(85, $desc.Length)))
    }
    Write-Host ""
    Write-Host "  Total: $($skills.Count) skills"
    Write-Host ""
}

function Show-Status {
    $destDir = Get-AgentDir $Agent
    Write-Host ""
    Write-Host "Installation status ($Agent)" -ForegroundColor Blue
    Write-Host "------------------------" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  Destination: $destDir" -ForegroundColor Cyan
    Write-Host ""

    $installed = 0
    $total = 0
    foreach ($s in Get-AvailableSkills) {
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
    foreach ($s in Get-AvailableSkills) {
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
    Write-Host "---------------------------" -ForegroundColor Blue
    Write-Host ""

    foreach ($agentName in $AgentDirs.Keys) {
        Write-Host "  -> $agentName -> $($AgentDirs[$agentName])" -ForegroundColor Cyan
        $destDir = $AgentDirs[$agentName]
        foreach ($s in Get-AvailableSkills) {
            Install-Skill $s $destDir | Out-Null
        }
        Write-Host ""
    }
    Write-Host "  [OK] Multi-agent installation complete." -ForegroundColor Green
    Write-Host ""
}

function Install-One($skillName) {
    $matches = @(Get-AvailableSkills | Where-Object { $_ -like "*$skillName*" })
    if ($matches.Count -eq 0) {
        Write-Host "Error: Skill '$skillName' not found." -ForegroundColor Red
        exit 1
    }
    if ($matches.Count -gt 1) {
        Write-Host "Multiple skills match '$skillName':" -ForegroundColor Yellow
        $matches | ForEach-Object { Write-Host "  - $_" }
        exit 1
    }

    $skill = $matches[0]
    $destDir = Get-AgentDir $Agent
    Write-Host ""
    Write-Host "Installing: $skill" -ForegroundColor Blue
    Write-Host ""
    Install-Skill $skill $destDir
    Write-Host ""
    Write-Host "  [OK] Done. Use /skill:$skill in your agent." -ForegroundColor Green
    Write-Host ""
}

function Uninstall-One($skillName) {
    $matches = @(Get-AvailableSkills | Where-Object { $_ -like "*$skillName*" })
    if ($matches.Count -eq 0) {
        Write-Host "Error: Skill '$skillName' not found." -ForegroundColor Red
        exit 1
    }
    $skill = $matches[0]
    $destDir = Get-AgentDir $Agent
    Write-Host ""
    Uninstall-Skill $skill $destDir
    Write-Host ""
}

function Uninstall-AllSkills {
    $destDir = Get-AgentDir $Agent
    Write-Host ""
    Write-Host "Uninstalling all MDPI Review Suite skills ($Agent)" -ForegroundColor Red
    Write-Host "---------------------------------------------------" -ForegroundColor Red
    Write-Host ""
    foreach ($s in Get-AvailableSkills) {
        Uninstall-Skill $s $destDir
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
