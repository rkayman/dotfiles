# rp — Robpro app catalog (macOS)

**Goal:** one CSV tells every Mac what to install, and why. Brewfiles are generated, never hand-edited. Chezmoi carries terminal-app *configuration* across OSes; package management stays native to each OS.

**Artifacts in this folder**

| File | Role |
|---|---|
| `catalog.csv` | Source of truth, synced across Macs by chezmoi. Columns: `type,name,use,status,description,options,needed_by` |
| `rp` | zsh + awk tool: `bootstrap`, `create`, `sync`, `deps`, `prune`, `check`, `list`, `stats` (`./rp help`) |
| `Brewfile-base` | Generated (`rp create --for=base`). Installed on every Mac. |
| `Brewfile-main` | Raw `brew bundle dump` (no vscode), rewritten by every `rp sync`. History lives in chezmoi. |

**New Mac, day zero:** chezmoi brings `rp` → `./rp bootstrap` → `brew bundle --file=Brewfile-base` → `./rp create --for=<purpose> | brew bundle --file=-`

**Vocabulary** — *type* says how it installs; *use* says why it's here.

| Column | Values |
|---|---|
| `type` | The Brewfile verb: `tap` `brew` `cask` `mas` `cargo` `go` `uv` `npm` `krew` `flatpak` `whalebrew` |
| `use` | `base` `dev` `ai` `media` `fun` `misc`, and `lib` = a dependency of something else (rp forces `status=ignore`) — `**x**` means guessed |
| `status` | `keep` (install) · `review` (undecided) · `retire` (no longer favoured) · `ignore` (track, never install directly) |
| `needed_by` | Written by `rp sync` on `retire`/`ignore` rows only: the `keep`/`review` brews and casks that still depend on it. Don't edit by hand. |

---

## Requirements

Status key: ✅ done · 🟡 done with caveat · 🔵 proposed by Claude, accepted · ⏸ postponed · ⛔ superseded

### REQ-20260925-001 — Current inventory ✅
Get a current list of all installed apps, formulae, and utilities.
- `rp sync` runs `brew bundle dump --no-vscode` and merges into the catalog. Run it on each Mac.

### REQ-20260925-002 — Discard VS Code items ✅
Discard all VSCODE items. They are managed through VSCode's cloud sync feature.
- `rp sync` dumps with `--no-vscode` and also drops any `vscode` line it sees.
- *ID corrected 2026-09-26 (was mistyped as REQ-20260926-002).*

### REQ-20260925-003 — CSV catalog ✅ *(amended)*
Convert the list to a CSV that tracks the item, ~~the version~~, how I use it (e.g. base, dev, ai, media, fun, misc), and description.
- **Amended 2026-09-25:** versions dropped. They change per machine and per `brew upgrade`; the catalog should change only when *you* change your mind.
- Added `type`, `options` (2026-09-25) and `needed_by` (2026-09-28, REQ-018).

### REQ-20260925-004 — Reuse prior classification ✅
Use a prior version of the CSV DB to retrieve how I use it. If no use exists, make a guess surrounded by two asterisks on each side.
- Seeded from old Brewfile section headers. As of 2026-09-28 Rob has confirmed every guess: 0 remain.

### REQ-20260925-005 — Generate a Brewfile per use ✅
Provide an option to create a brewfile for a specific use (e.g. `rp create --for=dev`).
```sh
./rp create --for=dev                          # stdout
./rp create --for=dev,ai --out=Brewfile-dev-ai
./rp create --for=base --out=Brewfile-base
./rp create --for=ai --confirmed               # skip **guessed** uses
```

### REQ-20260925-006 — Requirements + work log ✅
Create a markdown file with all requirements and a log of the work performed, successful or not. *(This file.)*

### REQ-20260925-007 — Lifecycle status 🔵
Every item carries `status`: `keep` | `review` | `retire` | `ignore`. `rp create` defaults to `keep`.

### REQ-20260925-008 — Zero-dependency tool 🔵
`rp` runs on a freshly installed OS: zsh (POSIX-sh mode) + awk + coreutils. Only `rp sync` and `rp deps` need `brew`.

### REQ-20260925-009 — Non-destructive sync 🔵
`rp sync` never deletes rows. New installs arrive as `**misc**` / `review`; rows not installed on this Mac are only reported. A `.bak` is written each run; `--dry-run` previews.

### REQ-20260926-010 — Purpose, not host ✅
No host tracking: each machine has a purpose (dev, server hosting, AI model dev, multimedia hosting …) and the `use` column selects what it installs.
- `rp` has no host column. A machine = `rp create --for=<its uses>`.
- *Amended 2026-09-28:* chezmoi syncs configuration across OSes; this catalog is macOS-only (REQ-017).

### REQ-20260926-011 — Capture new apps from any machine ✅
When I try an app on any machine and keep it, it must land in the catalog. Chezmoi keeps the catalog in sync across machines.
- `rp sync` on any Mac appends new items as `**misc**` / `review`; commit via chezmoi.

### REQ-20260926-012 — Dependencies: `type=brew`, `use=lib`, `status=ignore` ✅ *(amended 2026-09-29)*
Keep dependency formulae in the catalog. `use=lib` is the only marker; `type` stays the Brewfile verb (`brew`).
- *Amended 2026-09-29 (OQ-16):* `type=lib` dropped as redundant. One fact, one column.
- 22 rows today. `rp create` never writes them; brew installs them with their dependents.
- `rp sync` forces `status=ignore` on every `use=lib` row, heals any legacy `type=lib` row, and files *new* dependencies as `brew` / `lib` / `ignore`.
- `rp check` warns on legacy `type=lib`, `use=lib` without `ignore`, and `use=lib` on a non-brew row.

### REQ-20260926-013 — Brewfile-base ✅
`Brewfile-base` is always installed on all machines.
- *Amended 2026-09-28:* macOS only, no OS guards (REQ-017). 108 entries as of 2026-09-29. Regenerate after editing the catalog.

### ~~REQ-20260926-014 — Different package managers per OS~~ ⛔
Superseded by REQ-20260928-017.

### REQ-20260926-015 — Chezmoi drives installs ⏸ Postponed
A chezmoi `run_onchange_` script regenerates and applies the machine's Brewfile(s) whenever `catalog.csv` changes. When picked up, also add this folder to `.chezmoiignore` on non-macOS hosts.
- *Also postponed 2026-09-29 (OQ-18):* a chezmoi `run_once_` script that calls `rp bootstrap` on a new Mac. Not ready to automate that much of machine setup.

### REQ-20260926-016 — Deterministic output 🔵
Generated Brewfiles contain no timestamp or hostname, so an unchanged catalog produces a byte-identical file and chezmoi sees no churn.

### REQ-20260928-017 — Package management is per-OS ✅
Package management is unique to each OS (all macOS, all Linux, all Windows). This catalog and `rp` cover macOS. Cross-OS consistency comes from chezmoi-managed configuration, not a shared app list.
- `rp create` still accepts `--os=linux|any`; unused, harmless. A Linux catalog, if ever wanted, would be a separate file (`RP_DB=…`).

### REQ-20260928-018 — Track retired / ignored items that are still needed ✅
`retire` means "I no longer favour this". If something retired or ignored is still needed as a dependency, call it out and track it so I can decide.
- **Tracked:** `needed_by` column, rewritten by each `rp sync`. It is computed from the dependency graph of every `keep`/`review` brew and cask in the catalog (`brew deps --for-each`), not from what one Mac happens to have installed, so every Mac computes the same value.
- **Called out** by `rp sync` and `rp deps`:
  - `^` retired but still needed (e.g. `ffmpeg <- auto-editor`)
  - `!` ignored libs nothing you keep needs (retire candidates)
  - `x` retired but still installed on this Mac
  - `~` (`rp deps` only) kept brews that other kept items depend on
- If `brew deps --for-each` fails (e.g. a formula was removed from Homebrew), `rp` warns and falls back to `brew deps --installed`. If no dependency data is available at all, `needed_by` is left untouched.
- **`brew deps` output format** (confirmed by Rob, 2026-09-29): one line per formula or cask, `name: [dep list]`, where the list is space-delimited formula names and may be empty, one, or very long. `rp` parses `name:`, `name: ` and 400-item lists identically.

### REQ-20260928-019 — Brewfile-main is the raw dump, with history ✅
Every live `rp sync` rewrites `Brewfile-main` with that Mac's dump (minus vscode). Chezmoi keeps the history. `--from` and `--dry-run` never touch it.
- *2026-09-29 (OQ-14):* the last Mac to sync wins, and history will flip between Macs. Accepted as-is.

### REQ-20260928-020 — Catalog lint 🔵
`rp check` validates hand edits: unknown type/status (errors, non-zero exit), lib consistency, unconfirmed uses/descriptions, stray `needed_by`, and the same app kept under two types. Useful later as a chezmoi pre-apply check.

### REQ-20260929-021 — Prune retired items ✅
`rp prune` uninstalls retired items that nothing needs, keeping each Mac clean and consistent with my preferred tools.
- Candidates: `status=retire`, installed on this Mac, and `needed_by` empty, recomputed live, never read from a stale CSV.
- Retired items still needed are listed as kept, with what needs them.
- Preview by default; `--yes` acts. `--autoremove` adds `brew autoremove` for orphaned dependencies.
- Order: apps and tools, then formulae, then taps. Failures don't stop the run; failed items get one retry (a retired item another retired item depends on can only go second), then are listed. Exit code 1 if anything is left.
- Uninstallers: `brew uninstall --formula`, `brew untap`, `cargo uninstall`, `uv tool uninstall`, `npm uninstall -g`, `kubectl krew uninstall`, `whalebrew uninstall`. `go` has none, so it's listed for manual removal.
- **Apps are never uninstalled** *(amended 2026-09-29, OQ-17)*: retired `cask` and `mas` items are listed under "Apps to remove yourself", so an app cleaner (AppCleaner, mole …) can catch remnants first. Casks show the follow-up `brew uninstall --cask <name>`; mas apps show their App Store id. Listing apps is not a failure (exit 0).
- Refuses to run with no dependency data: it can't prove nothing needs an item.
- Never uses `--ignore-dependencies` or `sudo`: if Homebrew says something else still needs an item, that wins.

### REQ-20260929-022 — Bootstrap Homebrew on a new Mac ✅
`rp bootstrap` makes it easy to install the latest Homebrew on a new Mac with a single command.
- Missing: runs the official installer (`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`). It asks for your password and installs the Xcode Command Line Tools if needed.
- Present (in PATH, `/opt/homebrew`, or `/usr/local`): `brew update` to the latest.
- Loads `brew shellenv` for the current run. If `~/.zprofile` lacks it, prints the line to add, but doesn't edit the file because chezmoi owns dotfiles.
- Homebrew only (decision: Rob). Prints the next commands rather than running them. `--dry-run` shows the plan. macOS only.

---

## Resolved questions

| # | Answer |
|---|---|
| OQ-1 hosts | No host tracking; `use` = machine purpose → REQ-010 *(09-26)* |
| OQ-2 misfiled `dev` | torrra, cinecli, subliminal → `media`; bulletty → `misc` / `retire` *(09-26)* |
| OQ-3 dependency libs | Keep as `lib` / `ignore` → REQ-012 *(09-26)* |
| OQ-4 legacy Brewfiles | Removed; `Brewfile-base` created → REQ-013 *(09-26)* |
| OQ-5 `xan` twice | Keep `brew`; `cargo` → `retire` *(09-26)* |
| OQ-6 Linux | → REQ-017 *(09-28)* |
| OQ-7 confirming guesses | Rob edits the CSV directly; done *(09-28)* |
| OQ-8 chezmoi wiring | Postponed → REQ-015 *(09-26)* |
| OQ-9 pacman/AUR | Out of scope: package management is per-OS → REQ-017 *(09-28)* |
| OQ-10 dav1d, jpeg-turbo, jpeg-xl | `lib` / `lib` / `ignore` *(09-28)* |
| OQ-11 retired but still needed | Keep `retire`; call out and track dependents → REQ-018 *(09-28)* |
| OQ-12 Brewfile-main | `rp sync` rewrites it; chezmoi keeps history → REQ-019 *(09-28)* |
| OQ-13 lib `use` | Normalized to `lib` for all lib rows *(09-28)* |
| OQ-14 Brewfile-main churn | Keep as-is → REQ-019 note *(09-29)* |
| OQ-15 prune | Yes → REQ-021 *(09-29)* |
| OQ-16 lib marker | `type=brew`, `use=lib` → REQ-012 amended *(09-29)*. Cause of the earlier flip-back unknown; not the CSV tool, not `rp`. |

| OQ-17 mas/cask uninstall | Never uninstall apps; list them for the app cleaner → REQ-021 amended *(09-29)* |
| OQ-18 chezmoi calls `rp bootstrap` | Postponed → REQ-015 *(09-29)* |

## Open questions

None open. Postponed work lives in REQ-015.

---

## Work log

### 2026-09-25

| # | Step | Result |
|---|---|---|
| 1 | Inventoried folder: `Brewfile`, `Brewfile-all`, `Brewfile-extras`, `Brewfile-main`. No CSV found. | ✅ |
| 2 | Asked 4 grilling questions. Decisions: seed from headers; add `status` only; drop versions; zsh + awk. | ✅ |
| 3 | Parsed `Brewfile-main` → 307 items after dropping 168 `vscode`. | ✅ |
| 4 | `Brewfile-all`'s `ESSENTIAL APPS & UTILS` held every cask/mas; treated as dump ordering, not curation. | ⚠️ judgment call |
| 5 | Header → use mapping, precedence `Brewfile` > `Brewfile-all` > `Brewfile-extras`. `QUESTIONABLE` / `OLD` → `review`. | ✅ |
| 6 | 10 header conflicts resolved in favour of newer `Brewfile-all`. | ✅ |
| 7 | Guessed 130 uses; wrote mas/font/misc descriptions. | 🟡 14 uncertain |
| 8 | Giant shell heredoc failed (`spawn E2BIG`); moved to a script file. | ❌ → ✅ |
| 9 | Wrote `rp`; sandbox lacks zsh, tested under dash and bash. | 🟡 zsh untested |
| 10 | busybox awk parsed `d (…)` as a function call; rewrote. | ❌ → ✅ |
| 11 | Round-trip of `Brewfile-main` exact across 3 awks × 2 shells. | ✅ |
| 12 | Sync idempotent. | ✅ |
| 13 | `mv` failed replacing the catalog; switched to overwrite-in-place. | ❌ → ✅ |
| 14 | `--dry-run` and error exits verified. | ✅ |
| 15 | Not tested: macOS awk, live `brew bundle dump`. | ⬜ |

### 2026-09-26

| # | Step | Result |
|---|---|---|
| 16 | Found Rob's in-progress edits in `catalog.csv` (41 rows changed). Snapshotted first; all preserved. | ✅ |
| 17 | Converted 15 dependency formulae to `type=lib`, `status=ignore`. | ✅ |
| 18 | torrra, subliminal → `media`; cargo `xan` → `retire`. Exactly 18 rows changed. | ✅ |
| 19 | `rp`: `lib` type, `ignore` status, `--os=any`, flatpak, `rp deps`, dependency detection in `sync`. | ✅ |
| 20 | Removed timestamp/hostname from generated Brewfiles (REQ-016). | ✅ |
| 21 | Regression across gawk, mawk, busybox × dash, bash. | ✅ |
| 22 | Synthetic dump + fake `brew deps` tests. | ✅ |
| 23 | Generated `Brewfile-base` (114 entries). | ✅ |
| 24 | Couldn't permanently delete; moved old Brewfiles to `_archive/`. Rob trashed it. | ✅ |
| 25 | Not tested: zsh, macOS awk, real `brew deps` output. | ⬜ |

### 2026-09-28

| # | Step | Result |
|---|---|---|
| 26 | **Bug (reported by Rob):** `rp sync` failed: *"Calling the `--describe` switch is disabled! Use the default behaviour instead."* Homebrew removed the flag; descriptions are now the default. Removed `--describe`, added the documented `--no-vscode`. Verified against the current `brew` manpage. | ❌ → ✅ |
| 27 | Snapshotted Rob's latest catalog (135 lines changed since 09-26: every guess confirmed, 9 items now retired, descriptions filled). All preserved. | ✅ |
| 28 | Found all 15 lib rows with `type=brew`. Set `type=lib` on every `use=lib` row; dav1d, jpeg-turbo, jpeg-xl → `lib`/`lib`/`ignore`. Added empty `needed_by` column. Exactly 18 rows changed vs Rob's snapshot. | ✅ (see OQ-16) |
| 29 | `rp`: `needed_by` tracking with four call-outs, `Brewfile-main` rewrite on live sync, `rp check`, `rp deps` = read-only sync report. | ✅ |
| 30 | Fixed a latent bug: the CSV parser reused a field array between rows, so a short row could inherit the previous row's 7th field. Now cleared per row. | ❌ → ✅ |
| 31 | Tested with a fake `brew` on PATH: live sync writes catalog + `Brewfile-main` (0 vscode lines); second sync byte-identical; offline (`--from/--deps`) result identical to live; missing dependency data leaves `needed_by` untouched; `--for-each` failure warns and falls back; new dependency auto-filed as lib with `needed_by`. | ✅ |
| 32 | Same results across gawk, mawk, busybox × dash, bash; round-trip of `Brewfile-main` (minus 18 libs) exact; `rp check` exits 1 on bad rows. | ✅ |
| 33 | `rp check` first flagged brew `xan` vs retired cargo `xan`; changed it to ignore retired/ignored rows. Real catalog: 0 errors, 0 warnings. | ✅ |
| 34 | Regenerated `Brewfile-base` for macOS (no OS guards): 110 entries. | ✅ |
| 35 | Not verified: exact `brew deps --for-each` output on your Mac (the parser expects `name: dep dep`), zsh, macOS awk. | ✅ verified 09-29 (see 36) |

### 2026-09-29

| # | Step | Result |
|---|---|---|
| 36 | **First real run on the Mac.** Rob's `rp sync` wrote `Brewfile-main` (0 vscode lines) and populated `needed_by` for all 22 ignore rows, including cask parents (`mactex`). That proves zsh, macOS awk and the real `brew deps` output end to end. Retired items no longer appear in the dump, so the uninstalls took. | ✅ |
| 37 | Asked 4 questions. Decisions: OQ-14 keep as-is; OQ-16 `type=brew` + `use=lib`; command named `rp bootstrap`; Homebrew only. | ✅ |
| 38 | Snapshotted Rob's catalog. Since 09-28: ffmpeg, ghostscript, psutils, tesseract became `lib`; midnight-commander, mdfried retired. | ✅ |
| 39 | `rp`: `use=lib` is the lib marker (`islib`); sync heals legacy `type=lib` and forces `status=ignore`; new deps filed as `brew`/`lib`/`ignore`; `rp check` rules updated. | ✅ |
| 40 | Migrated the catalog by running `rp sync` offline with no graph (`--deps=/dev/null`, so `needed_by` untouched). Python diff: exactly 22 rows changed, type column only. `Brewfile-main` untouched. | ✅ |
| 41 | `rp prune` built on the sync engine (`RP_PLAN`), with no second dependency engine. Tested with fake `brew`/`mas`/`cargo`: preview runs no commands and leaves the catalog untouched; `--yes` removes in order; a dependency-order failure succeeds on retry; a persistent `mas` failure is reported, exit 1; still-needed item kept; no dependency data → refuses; nothing to prune → exit 0. | ✅ |
| 42 | `rp bootstrap` tested with a fake `uname`/`brew`: non-macOS refuses; no brew + `--dry-run` prints the official installer command; brew present → `update`, `shellenv`, version; `.zprofile` hint only when missing. The real installer was not run (sandbox). | 🟡 |
| 43 | Graph parser tested on `name:`, `name: ` (empty lists, 169 lines) and a 400-dependency line: result identical to Rob's real `needed_by`. | ✅ |
| 44 | Regression: gawk, mawk, busybox × dash, bash give identical `create` and `check` output. Migration changes no generated output. `Brewfile-base` regenerated: 108 entries (catalog edits since 09-28). | ✅ |
| 45 | Checked Homebrew's installer URL (Homebrew/install README), `uninstall --formula/--cask`, `autoremove`, `untap` and `update` against current docs. brew.sh and docs.brew.sh timed out; used the GitHub README and the cached manpage. | 🟡 |
| 46 | OQ-17: `rp prune` no longer uninstalls `cask` or `mas`. It lists them as "Apps to remove yourself", with the `brew uninstall --cask` follow-up or the App Store id. `uninstall_one` refuses both types as a second guard. Formulae unchanged. Tested with fakes: preview and `--yes` never call `brew uninstall --cask` or `mas`; apps-only prune exits 0 with zero commands run; identical output across 3 awks × 2 shells; catalog untouched. | ✅ |
| 47 | OQ-18 postponed into REQ-015. No open questions remain. | ✅ |
