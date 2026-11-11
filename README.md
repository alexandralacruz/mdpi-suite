# MDPI Review Suite

Skills for reviewing academic papers against the **MDPI journal rubric** and for simulating the **official MDPI peer-review form** — ideal for pre-submission dry-runs, actual reviews, and rebuttal preparation.

## Included skills

| Skill | Purpose | When to use |
|---|---|---|
| `reviewer-mdpi-journal` | Scores a manuscript with the weighted MDPI journal rubric (scope/fit, novelty, significance, soundness, presentation, reader interest, references, ethics) and issues an MDPI verdict with an improvement plan | Dry-run the journal rubric before submitting, or act as an external reviewer |
| `reviewer-mdpi-perspective` | Produces a complete report in the official MDPI review form (recommendations for authors, English quality, editor-only ethics checks, ratings, reference check, comments, overall recommendation) | Fill in the MDPI reviewer interface, or anticipate MDPI reviewer questions before submitting |

## Recommended workflow

```
1. reviewer                     → deep 8-dimension technical analysis
2. reviewer-mdpi-journal        → weighted MDPI rubric score + verdict + improvement plan
3. reviewer-mdpi-perspective    → official MDPI review form (ready to paste/submit)
```

Both MDPI skills run in **two passes**: they invoke the `reviewer` skill for the deep technical analysis, then map its findings onto the MDPI rubric/form.

## Dependency

The two skills in this suite reuse the `reviewer` skill (the 8-dimension pre-submission reviewer) as their deep-analysis engine.

| Dependency | Where to get it |
|---|---|
| `reviewer` | [Academic Research Suite](https://github.com/alexandralacruz/academic-research-suite) — included in the `academic-research-suite` package |

> If `reviewer` is not installed, each MDPI skill falls back to an equivalent 8-dimension analysis before applying the MDPI rubric/form. For best results, install the Academic Research Suite first.

## Installation

There are multi-agent installers (pi, Claude Code, Codex CLI):

**Linux / macOS:**
```bash
./install.sh --all                 # install everything into pi
./install.sh --all --agent claude  # install into Claude Code
./install.sh --all --agent codex   # install into Codex CLI
./install.sh --all --agent all     # install into all detected agents
./install.sh                       # interactive menu
./install.sh --list                # list skills
```

**Windows (PowerShell):**
```powershell
.\install.ps1 -All                 # install everything into pi
.\install.ps1 -All -Agent claude   # install into Claude Code
.\install.ps1 -All -Agent codex    # install into Codex CLI
.\install.ps1 -All -Agent all      # install into all agents
.\install.ps1                      # interactive menu
```

**One-liner (Linux / macOS, from any machine):**
```bash
curl -sSL https://raw.githubusercontent.com/alexandralacruz/mdpi-suite/main/install.sh | bash
curl -sSL https://raw.githubusercontent.com/alexandralacruz/mdpi-suite/main/install.sh | bash -s -- --all --agent codex
```

Destinations by agent:

| Agent | Directory |
|---|---|
| pi | `~/.pi/agent/skills/` (override with `PI_SKILLS_DIR`) |
| claude | `~/.claude/skills/` |
| codex | `~/.codex/skills/` |

**Manual alternative** (without installer): add the path in `.pi/settings.json`:

```json
{
  "skills": ["~/Documentos/Dev/pi-skills/mdpi-suite"]
}
```

## Fundamental rule

**Never invent evidence.** Both skills are designed to detect, flag, and rate based on real evidence (sections, figures, tables, lines). They do not fabricate findings, citations, or ratings.

## License

MDPI Review Suite — Non-Commercial Academic License. See [`LICENSE`](LICENSE).
