# Use GitHub + chezmoi.

Git should be the transport and history. chezmoi should be the configuration-management layer between the repo and $HOME. That separation matters once you have multiple Macs, machine-specific settings, .config trees, package installation, and eventually secrets.

## 1. The architecture

I recommend this model:

    GitHub
    └── dotfiles
        ↓ git clone/pull/push
    ~/.local/share/chezmoi/
        ↓ chezmoi apply
    $HOME
    ├── .zshrc
    ├── .zprofile
    ├── .gitconfig
    └── .config/
        ├── starship.toml
        ├── ghostty/
        ├── eza/
        ├── fzf/
        ├── zoxide/
        └── ...

Your real Git working tree lives at:

    ~/.local/share/chezmoi

Your applications continue using their normal files:

    ~/.zshrc
    ~/.zprofile
    ~/.config/starship.toml
    ...

chezmoi generates/manages those files from the Git-controlled source. This is its intended architecture.

This is better than putting `$HOME` itself under Git, and better than manually maintaining dozens of symlinks.

---

## 2. Install chezmoi on your first Mac

Since you’re already using Homebrew:

    brew install chezmoi

Then verify:

    chezmoi --version

Official installation documentation:  ⁠chezmoi installation

---

## 3. Connect chezmoi to your existing GitHub dotfiles repo

Assuming your GitHub username is `$GITHUB_USERNAME` and the repo is:

    github.com/$GITHUB_USERNAME/dotfiles

If the repository is currently empty:

    chezmoi init

That creates:

    ~/.local/share/chezmoi/

as a Git repository.  

Then enter it:

    chezmoi cd

and connect your GitHub repository:

    git remote add origin git@github.com:$GITHUB_USERNAME/dotfiles.git
    git branch -M main

Don’t push yet. Add some configuration first.

If your GitHub repo already contains useful files, initialize directly from it instead:

    chezmoi init --ssh $GITHUB_USERNAME/dotfiles

chezmoi recognizes the user/repo shorthand and will resolve --ssh to:

    git@github.com:$GITHUB_USERNAME/dotfiles.git

---

## 4. Start small: add .zshrc and .zprofile

Do not dump your entire $HOME or .config directory into the repo.

Start deliberately:

    chezmoi add ~/.zshrc
    chezmoi add ~/.zprofile

Now:

    chezmoi cd

You’ll see something roughly like:

    dot_zshrc
    dot_zprofile

chezmoi translates source names:

    dot_zshrc       → ~/.zshrc
    dot_zprofile    → ~/.zprofile

That naming convention is intentional.  

Check:

    git status

Then:

    git add .
    git commit -m "Add zsh configuration"
    git push -u origin main

---

## 5. Add your .config applications selectively

This is where chezmoi starts paying for itself.

For example:

    chezmoi add ~/.config/starship.toml
    chezmoi add ~/.config/ghostty
    chezmoi add ~/.config/television
    chezmoi add ~/.config/zellij

Directories are recursive by default.  

Your source repository could consequently look like:

    ~/.local/share/chezmoi/
    ├── dot_zshrc
    ├── dot_zprofile
    └── dot_config/
        ├── starship.toml
        ├── ghostty/
        │   └── config
        ├── television/
        │   └── ...
        └── zellij/
            └── ...

Git sees normal files. chezmoi knows where they belong.

---

## 6. Do NOT add all of .config

Avoid:

    chezmoi add ~/.config

That will capture application state, caches, transient metadata, credentials and junk you never intended to synchronize.

Instead, think of your dotfiles repository as declarative configuration, not a backup system.

Good candidates:

    .zshrc
    .zprofile
    .gitconfig
    .config/starship.toml
    .config/ghostty/
    .config/bat/
    .config/eza/
    .config/fzf/
    .config/zoxide/
    .config/television/
    .config/nvim/
    .config/yazi/
    .config/ripgrep/

Usually bad candidates:

    Caches
    history files
    logs
    session state
    SQLite databases
    application caches
    credentials
    tokens
    API keys
    machine-generated state

The distinction is:

Can this file recreate my preferred environment?

If yes, probably version it.

Is this file merely evidence of what I’ve been doing?

Probably don’t.

---

## 7. Your normal edit workflow

There are two legitimate ways to work.

### Approach A — edit your normal files

For your workflow, I’d use this.

Edit:

    ~/.zshrc

as you normally do.

Then tell chezmoi to import the changed version:

    chezmoi re-add ~/.zshrc

Or import all modified managed files:

    chezmoi re-add

re-add updates chezmoi's source state from files you've modified in `$HOME`.

Then:

    chezmoi cd
    git diff
    git add .
    git commit -m "Update zsh configuration"
    git push

### Approach B — edit through chezmoi

Alternatively:

    chezmoi edit ~/.zshrc

Then:

    chezmoi diff
    chezmoi apply

I prefer A for you because your normal configuration files remain the place where you naturally work.

---

## 8. Learn these six commands

Most of your daily interaction will boil down to:

    chezmoi status

What differs?

    chezmoi diff

What would chezmoi change?

    chezmoi apply

Make $HOME match the repo.

    chezmoi re-add

Make the repo reflect changes you've made in `$HOME`.

    chezmoi cd

Go into the Git repo.

    chezmoi update

Pull from Git and apply the changes locally.  

One particularly useful safety combination is:

    chezmoi apply --dry-run --verbose

or:

    chezmoi -n -v apply

It shows what would happen without changing anything.  

---

## 9. Set up your second Mac

This is where the design proves itself.

Install Homebrew/chezmoi, then:

    brew install chezmoi

Assuming SSH access to GitHub is already configured:

    chezmoi init --ssh $GITHUB_USERNAME/dotfiles

Do not immediately use --apply the first time.

First inspect:

    chezmoi diff

Then:

    chezmoi apply -v

Now:

    ~/.zshrc
    ~/.zprofile
    ~/.config/starship.toml
    ...

are brought into the desired state.

From then on:

    chezmoi update

pulls the repository and applies it. This is the documented multi-machine workflow.  

Once you trust the repo, a brand-new machine can use:

    chezmoi init --apply --ssh $GITHUB_USERNAME/dotfiles

---

## 10. Handle machine-specific differences with templates

This is the main reason I’d choose chezmoi over GNU Stow.

Suppose your `.zshrc` needs something only on macOS:

    eval "$(/opt/homebrew/bin/brew shellenv)"

but someday you also have a Linux machine.

Turn the file into a template:

    chezmoi chattr +template ~/.zshrc

Now its source becomes something like:

    dot_zshrc.tmpl

and you can write:

    {{- if eq .chezmoi.os "darwin" }}
        eval "$(/opt/homebrew/bin/brew shellenv)"
    {{- end }}

Likewise:

    {{ if eq .chezmoi.arch "arm64" }}
        # Apple Silicon configuration
    {{ end }}

Inspect available variables with:

    chezmoi data

chezmoi explicitly supports generating machine-specific target files from a shared source repository.  

---

## 11. Distinguish machine roles, not just hostnames

This becomes important as your collection grows.

Avoid littering files with:

    if hostname == "MacBook-Pro"
    if hostname == "Mac-Mini"
    if hostname == "Mac-Studio"

That’s brittle.

Instead define semantic information such as:

    [data]
    role = "desktop"
    personal = true

versus:

    [data]
    role = "laptop"
    personal = true

The local chezmoi configuration normally lives at:

    ~/.config/chezmoi/chezmoi.toml

and is machine specific rather than shared.  

Then templates can say:

    {{ if eq .role "desktop" }}
        # desktop-specific configuration
    {{ end }}

This scales better.

---

## 12. Don’t put secrets in Git

Even if the repository is private.

A private Git repository is not a password manager.

Avoid committing:

    API keys
    GitHub tokens
    SSH private keys
    AWS credentials
    passwords
    OAuth credentials
    private certificates

Git remembers deleted secrets forever unless history is rewritten.

chezmoi can integrate secrets from password managers and can also maintain encrypted files. Its design explicitly supports public or private dotfiles repositories without requiring plaintext secrets to be stored in them.  

For example, chezmoi supports:

    chezmoi add ~/.ssh/id_ed25519 --encrypt

But I would go one step further:

Keep credentials in a proper secrets system and have dotfiles reference/retrieve them.

Your repo should contain configuration, not secrets.

---

## 13. Manage packages too

Eventually you’re going to want:

New Mac → one command → machine looks like mine.

Dotfiles alone don’t get you there.

You’ll also need software.

On macOS, make Homebrew part of the system.

Generate a starting Brewfile:

    brew bundle dump --file=~/Brewfile

Inspect it carefully, then:

    chezmoi add ~/Brewfile

You might eventually manage:

    brew "chezmoi"
    brew "eza"
    brew "fzf"
    brew "zoxide"
    brew "starship"
    brew "ripgrep"
    brew "bat"
    brew "git"
    brew "gh"
    cask "ghostty"

Then bootstrap with:

    brew bundle --file=~/Brewfile

I would not blindly dump your installed packages and keep them all. Cull it down to things you intentionally want on every machine.

---

## 14. Let chezmoi bootstrap machines

chezmoi supports scripts in the repo.

For example:

    run_once_before_install-packages.sh.tmpl

or:

    run_onchange_after_brew-bundle.sh.tmpl

Scripts can run:

* every apply: run_
* once for a particular script content: run_once_
* when their content changes: run_onchange_

For example, a run_onchange_... script could run:

    brew bundle --file="$HOME/Brewfile"

whenever your package definition changes.

Use scripts sparingly. The chezmoi documentation makes the same point: configuration should stay predominantly declarative.  

---

## 15. Consider macOS preferences separately

There is another category you’ll eventually want:

    defaults write ...

For example:

    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

These aren’t dotfiles, but they’re absolutely part of your desired machine configuration.

I’d create something like:

    run_onchange_after_macos-defaults.sh.tmpl

containing intentional defaults write commands.

This lets your repository capture:

    dotfiles
    +
    application configuration
    +
    Homebrew software
    +
    macOS preferences

That turns dotfiles into a genuine workstation definition.

---

## 16. Recommended repository structure

I’d work toward this:

    dotfiles/
    │
    ├── .chezmoi.toml.tmpl
    ├── .chezmoiignore
    │
    ├── dot_zshrc
    ├── dot_zprofile
    ├── dot_gitconfig.tmpl
    │
    ├── dot_config/
    │   ├── starship.toml
    │   ├── ghostty/
    │   │   └── config
    │   ├── television/
    │   ├── bat/
    │   ├── yazi/
    │   └── ...
    │
    ├── Brewfile
    │
    ├── run_once_before_install-homebrew.sh.tmpl
    ├── run_onchange_after_brew-bundle.sh.tmpl
    └── run_onchange_after_macos-defaults.sh.tmpl

I’d also put a good README in the repo explaining the bootstrap process.

---

## 17. A useful .chezmoiignore

As your repo grows, you may have source files that should not be deployed into `$HOME`.

For example:

    README.md
    LICENSE
    docs/

`.chezmoiignore` tells chezmoi not to treat those as managed home-directory files.

Thus the repository can contain documentation and supporting material without accidentally generating:

    ~/README.md

---

## 18. Git itself creates a chicken-and-egg problem

Your `.gitconfig` is worth managing, but values can differ across machines.

For example:

    [user]
    name = Rob
    email = ...

along with:

    [core]
    editor = zed --wait
    [init]
    defaultBranch = main
    [pull]
    rebase = true
    [fetch]
    prune = true

I would make `.gitconfig` a chezmoi template:

    chezmoi add --template ~/.gitconfig

Then machine-specific identities or work/personal distinctions don’t require separate copies of the whole file.

---

## 19. SSH deserves special treatment

Don’t treat:

    ~/.ssh/

like another config folder.

You might version:

    ~/.ssh/config

if it contains no sensitive information.

But do not casually commit:

    id_ed25519
    id_rsa
    *.pem
    private keys

For GitHub authentication on each Mac, GitHub’s SSH configuration documentation is the appropriate source:

**GitHub: Connecting to GitHub with SSH**

I would normally let macOS Keychain / 1Password / your chosen secrets solution own the key material.

---

## 20. Use Git branches sparingly

Don’t create:

    macbook
    macmini
    macstudio

branches.

That sounds neat initially and becomes a synchronization nightmare.

You want:

    main

to describe your environment.

Machine differences belong in chezmoi templates/data, not permanent Git branches.

Use ordinary short-lived Git branches only when making significant experimental changes.

---

## 21. One subtle but important rule

You have two directions of synchronization:

Repo → machine

    chezmoi update

Conceptually:

    GitHub
        ↓
    chezmoi source
        ↓
    $HOME

Machine → repo

If you edited the live files:

    chezmoi re-add
    chezmoi cd
    git diff
    git add .
    git commit
    git push

Conceptually:

    $HOME
        ↓
    chezmoi re-add
        ↓
    Git
        ↓
    GitHub

Keeping that distinction clear avoids most chezmoi confusion.

---

## 22. Add a few aliases/functions

Once you’re comfortable, these are reasonable:

    alias ccd='chezmoi cd'
    alias cza='chezmoi apply'
    alias czd='chezmoi diff'
    alias czs='chezmoi status'
    alias czu='chezmoi update'
    alias czr='chezmoi re-add'

I would not automate commits and pushes initially.

You want this friction:

    git diff

before putting configuration changes onto every computer you own.

Later, automation may make sense.

---

## 23. Your first migration sequence

Given the environment you’re already building, I’d migrate in roughly this order:

### 1. Shell:

    .zshrc
    .zprofile

### 2. Prompt:

    .config/starship.toml

### 3. Terminal:

    Ghostty configuration

### 4. CLI tools:

    eza
    fzf
    zoxide
    television
    bat
    ripgrep
    yazi

### 5. Git:

    .gitconfig
    .gitignore_global

### 6. Developer tooling.
### 7. Brewfile.
### 8. macOS defaults.
### 9. Secrets integration.

Do one category at a time. Commit each independently:

    Add zsh configuration
    Add Starship configuration
    Add Ghostty configuration
    Add CLI tool configuration
    Add Git configuration
    Add Homebrew package manifest
    Add macOS preferences

That gives you meaningful history instead of an initial 5,000-file blob.

---

## 24. Why not GNU Stow?

Stow is a perfectly respectable simpler option. It maintains a tree of files and creates symlinks into the target directory; GNU explicitly describes it as useful for managing configuration files in conjunction with version control.  

A Stow repo might look like:

    dotfiles/
    ├── zsh/
    │   ├── .zshrc
    │   └── .zprofile
    ├── starship/
    │   └── .config/
    │       └── starship.toml
    └── ghostty/
        └── .config/
            └── ghostty/
                └── config

Then:

    stow zsh
    stow starship
    stow ghostty

works well.

But Stow’s core abstraction is symlink management.

chezmoi’s abstraction is desired machine configuration.

That’s the distinction that matters.

For one Unix machine, Stow’s simplicity is compelling.

For several Macs today, potentially different machine roles tomorrow, templates, package bootstrapping, secrets, and OS settings, I would choose chezmoi.

---

## The end state

The goal shouldn’t merely be:

“My .zshrc is backed up.”

It should be:

    Fresh Mac
       │
       ├── Install/obtain chezmoi
       │
       ├── Authenticate GitHub
       │
       └── chezmoi init --apply ...
             │
             ├── shell configured
             ├── CLI apps configured
             ├── applications installed
             ├── Git configured
             ├── macOS preferences applied
             └── machine-specific differences resolved

At that point, the GitHub repo is the authoritative description of how you want a machine configured. That’s a much stronger model than “dotfiles synchronization.”

For your existing Macs, I would start with chezmoi and migrate `.zshrc`, `.zprofile`, `starship.toml`, and your Ghostty configuration first. Then run that exact configuration on your second Mac before expanding the scope. That validates the architecture while the blast radius is still tiny.

*Confidence: 98% on the architecture and commands; the remaining uncertainty is around exactly which individual applications on your Macs expose stable, portable configuration files.*

---

# FOLLOW-UP PROMPT
Based on past work, plus Homebrew prerequisites (eg, Brewfile creation and management), create a list of files I need to generate and/or add to chezmoi.


## 1. Chezmoi foundation

* `~/.local/share/chezmoi/.chezmoi.toml.tmpl`
    * Generate.
    * Defines machine-specific data during chezmoi init.
    * Use this to distinguish desktop vs laptop, personal vs work, etc.

* `~/.local/share/chezmoi/.chezmoiignore`
    * Generate.
    * Exclude repo-only files such as:
        ```
        README.md
        LICENSE
        docs/
        ```

* `~/.local/share/chezmoi/README.md`
    * Generate.
    * Document bootstrap, update, and machine-setup procedures.
    * Repo documentation only; exclude via .chezmoiignore.

---

## 2. Zsh

Core shell files

* `~/.zshrc`
    * Add.
    * Keep this relatively thin: initialize Homebrew and source modular configuration.
    * Starship should own the prompt.

* `~/.zprofile`
    * Add.
    * Login-shell environment initialization.

* `~/.zshenv`
    * Add only if one currently exists and contains intentional configuration.
    * Avoid putting interactive-shell configuration here.

Modular Zsh configuration

Based on the shell structure we previously developed:

* `~/.config/zsh/options.zsh`
    * Shell options and behavior.

* `~/.config/zsh/aliases.zsh`
    * General aliases.
    * Include your eza, Git, chezmoi, navigation, etc. aliases here.

* `~/.config/zsh/functions.zsh`
    * Helper functions.

* `~/.config/zsh/fzf.zsh`
    * fzf shell integration and keybindings.

* `~/.config/zsh/television.zsh`
    * Television integration.

Potentially add later:

    ~/.config/zsh/completions.zsh
    ~/.config/zsh/environment.zsh
    ~/.config/zsh/macos.zsh

I would not version:

    ~/.zsh_history
    ~/.zcompdump*

Those are state, not configuration.

---

## 3. Starship

* `~/.config/starship.toml`
    * Add.
    * This is one of the most important files in the repo.

Our target design was:

LEFT
user → directory → git/jj → language/runtime

RIGHT
status → duration → time

with Catppuccin Mocha-derived styling and appropriate macOS/Linux icons.

I would keep the complete Starship configuration in this one file rather than creating a separate Starship theme file unless it becomes unwieldy.

---

## 4. Ghostty

* `~/.config/ghostty/config`
    * Add.

If you have separate Ghostty fragments, add the complete configuration tree:

`~/.config/ghostty/`

Good candidates include intentional settings for:

    font
    theme
    window
    tabs
    shell integration
    keybindings
    cursor
    working-directory behavior

Do not include transient Ghostty state.

---

## 5. Television

From the configuration structure we previously discussed:

* `~/.config/television/config.toml`
    * Add.
* `~/.config/television/themes/...`
    * Add your Catppuccin Mocha theme if it is locally maintained.
* `~/.config/television/cable/...`
    * Add only custom channels you created or materially customized.
    * Don’t copy vendor-generated/default channels merely because they exist.

---

## 6. FZF

fzf generally needs little persistent configuration because much of its configuration belongs in the shell.

Primary managed file:

* `~/.config/zsh/fzf.zsh`

If you later create an actual:

`~/.config/fzf/`

configuration tree, add it selectively.

Your intended division is useful:

`fzf` owns shell-native fuzzy keybindings; Television handles richer interactive selection.

---

## 7. Zoxide

Usually no dedicated configuration file is needed.

Manage initialization through:

* `~/.zshrc`
    * or `~/.config/zsh/...`

Do not put zoxide’s database in Git.

That database describes where you’ve been; it isn’t configuration.

---

## 8. eza

Again, most `eza` configuration will probably live in:

* `~/.config/zsh/aliases.zsh`

For example, your preferred replacements for:

    ls
    ll
    la
    tree

If you later create explicit `eza` theme/configuration files, add those separately.

Do not version generated caches.

---

##9. Bat

Check whether you have:

`~/.config/bat/config`

If so:

* `~/.config/bat/config`
    * Add.

Potentially:

* `~/.config/bat/themes/`
    * Add custom themes only.

Do not version bat’s generated cache:

`~/.cache/bat/`

---

## 10. Ripgrep

Check for:

`~/.config/ripgrep/ripgreprc`

or whatever you’ve assigned to:

`RIPGREP_CONFIG_PATH`

If present:

* `~/.config/ripgrep/ripgreprc`
    * Add.

The environment-variable declaration itself belongs in your Zsh configuration.

---

## 11. Git

* `~/.gitconfig`
    * Add as a chezmoi template.

Recommended:

`chezmoi add --template ~/.gitconfig`

This gives us room for machine/work/personal differences later.

* `~/.gitignore_global`
    * Add if you use one.

Potentially:

* `~/.config/git/attributes`
* `~/.config/git/ignore`

If you’re already using XDG Git configuration instead, don’t maintain duplicate legacy files.

I would eventually consolidate Git configuration around:

`~/.config/git/config`
`~/.config/git/ignore`
`~/.config/git/attributes`

but don’t migrate just for aesthetic purity. If .gitconfig works well, manage it first.

---

## 12. Jujutsu

Because we specifically designed the prompt to understand Git or jj, include your Jujutsu configuration if you’ve started customizing it.

Likely:

* `~/.config/jj/config.toml`

Do not version jj repository state.

---

## 13. Homebrew

This should become a first-class component of the dotfiles system.

Package manifest

* `~/.Brewfile`
    * Generate, then aggressively curate.

Start with:

    brew bundle dump --global --force

Homebrew explicitly supports a global Brewfile and brew bundle dump for capturing installed formulae, casks, taps, and other supported packages. (_Homebrew Documentation_)

Do not blindly commit the generated result.

Your Mac has accumulated software over time. A raw dump answers:

*What happens to be installed?*

Your dotfiles repo needs to answer:

*What should be installed on a new machine?*

Those are different questions.

Initially expected Homebrew CLI packages

Based on the environment we’ve built, I would expect the curated Brewfile to include at least:

    brew "chezmoi"
    brew "eza"
    brew "fzf"
    brew "zoxide"
    brew "starship"
    brew "television"
    brew "bat"
    brew "ripgrep"
    brew "git"
    brew "gh"

Potential candidates from our other work:

    pandoc
    docling
    yt-dlp
    ffmpeg
    jq
    yq
    tree
    fd
    tmux
    sesh

but only put them into the base Brewfile if you really want them on every machine.

Homebrew bootstrap

* `run_once_before_10-install-homebrew.sh.tmpl`
    * Generate.
    * Install Homebrew only if brew isn’t available.
    * macOS-only via chezmoi templating.

Brew bundle application

* `run_onchange_after_20-brew-bundle.sh.tmpl`
    * Generate.
    * Runs brew bundle when its effective content changes.

`chezmoi` specifically supports `run_once_` and `run_onchange_` scripts for this sort of bootstrapping; `run_onchange_` is rerun only when its generated content changes. (_Chezmoi_)

---

## 14. macOS preferences

Create:

* `run_onchange_after_30-macos-defaults.sh.tmpl`

Use it for intentional macOS settings that you want reproduced across machines.

Likely candidates from our prior work:

Finder:
  - show hidden files
  - show extensions
  - preferred Finder behavior

Dock:
  - size
  - autohide
  - minimize behavior

Keyboard:
  - repeat rate
  - initial repeat delay

Trackpad/mouse:
  - intentional preferences

Screenshots:
  - location
  - file format

Terminal-related:
  - appropriate system settings

Do not dump hundreds of defaults read values and put them under source control. Most are opaque application state.

Hand-curate this script.

---

## 15. SSH

Potentially:

* `~/.ssh/config`
    * Add only after reviewing it for sensitive host information.

Possible chezmoi representation:

`private_dot_ssh/config`

or:

`private_dot_ssh/config.tmpl`

if hosts/users vary by machine.

Do not Git-store:

    id_rsa
    id_ed25519
    *.pem
    private keys
    known_hosts
    authorized_keys

unless we deliberately design an encrypted/secrets-management strategy.

---

## 16. GitHub CLI

Check:

`~/.config/gh/config.yml`

Potentially:

* `~/.config/gh/config.yml`

But inspect it first.

Do **not** version authentication data/tokens.

The modern gh credential mechanism normally keeps sensitive auth outside this configuration, but verify the actual file before adding it.

---

## 17. Zed

Because Zed is becoming part of your core development/Markdown environment:

Check:

`~/.config/zed/settings.json`
`~/.config/zed/keymap.json`

If those are your active locations:

* Zed settings.json
* Zed keymap.json

Include intentional editor preferences.

Don’t include workspaces, telemetry, caches, or transient application data.

---

## 18. tmux / sesh / cmux / rmux

We’ve discussed several terminal/session architectures. Don’t preemptively add all of them.

If tmux + sesh remains part of your actual environment:

* `~/.tmux.conf`
    * or `~/.config/tmux/tmux.conf`
* `~/.config/sesh/sesh.toml`
    * if present.

If you settle on cmux/rmux instead, version their actual configuration and drop unused alternatives.

The dotfiles repo should describe the environment you’ve chosen, not preserve evidence of every experiment.

---

## 19. Obsidian-related command-line tooling

Do not put your Obsidian vault into the dotfiles repo.

But configuration for tools supporting the workflow belongs here where appropriate:

Potential examples:

    pandoc defaults
    Markdown conversion scripts
    Docling/Marker wrappers
    Instagram archival CLI configuration
    vault maintenance helper scripts

I would create:

`~/.local/bin/`

and selectively manage your own reusable utilities there.

Potentially:

* `~/.local/bin/...`
    * Your macOS location/weather helper
    * PDF/EPUB conversion wrappers
    * Obsidian utility scripts
    * Instagram archival tooling wrappers
    * shell helpers worth using across machines

`chezmoi` supports executable source-state attributes, so these can become:

`executable_dot_local/bin/...`

(_Chez Moi_)

This is cleaner than cramming substantial logic into .zshrc.

---

## 20. Custom themes

You want Catppuccin Mocha consistently across the CLI environment.

Manage custom/local theme assets, not themes automatically installed by package managers.

Likely:

`~/.config/television/themes/catppuccin-mocha.toml`

Potentially custom themes for:

    bat
    fzf
    Ghostty

when they’re files you control.

If an application already ships Catppuccin, configure its theme name instead of duplicating the theme file.

---

## 21. Fonts

Do not put font binaries into this repo.

Instead use Homebrew casks or another installer mechanism where possible.

For example, if Nerd Fonts are needed for Starship icons, make font installation part of the Brewfile.

Configuration belongs in Git. Large third-party binary assets generally don’t.

---

## 22. Machine-local chezmoi configuration

There will also be:

`~/.config/chezmoi/chezmoi.toml`

This is generated per machine from:

`.chezmoi.toml.tmpl`

and should contain machine-specific answers such as:

    [data]
    machineType = "desktop"
    personal = true

Possible future values:

    macbook
    macmini
    macstudio
    laptop
    desktop
    personal
    work

Prefer capability/role distinctions such as desktop and laptop over hostname checks wherever possible.

---

Recommended initial repository

After this migration, I would expect your source tree to converge toward:

    dotfiles/
    ├── .chezmoi.toml.tmpl
    ├── .chezmoiignore
    ├── README.md
    │
    ├── dot_zshrc
    ├── dot_zprofile
    ├── dot_gitconfig.tmpl
    ├── dot_gitignore_global
    ├── dot_Brewfile
    │
    ├── dot_config/
    │   ├── zsh/
    │   │   ├── options.zsh
    │   │   ├── aliases.zsh
    │   │   ├── functions.zsh
    │   │   ├── fzf.zsh
    │   │   └── television.zsh
    │   │
    │   ├── starship.toml
    │
    │   ├── ghostty/
    │   │   └── config
    │
    │   ├── television/
    │   │   ├── config.toml
    │   │   └── themes/
    │
    │   ├── bat/
    │   │   └── config
    │
    │   ├── ripgrep/
    │   │   └── ripgreprc
    │
    │   ├── jj/
    │   │   └── config.toml
    │
    │   ├── gh/
    │   │   └── config.yml
    │
    │   └── zed/
    │       ├── settings.json
    │       └── keymap.json
    │
    ├── private_dot_ssh/
    │   └── config.tmpl
    │
    ├── executable_dot_local/
    │   └── bin/
    │       └── ...
    │
    ├── run_once_before_10-install-homebrew.sh.tmpl
    ├── run_onchange_after_20-brew-bundle.sh.tmpl
    └── run_onchange_after_30-macos-defaults.sh.tmpl

### Migration order

* Create .chezmoi.toml.tmpl
* Create .chezmoiignore
* Add .zshrc
* Add .zprofile
* Add .config/zsh/
* Add starship.toml
* Add Ghostty
* Add Television
* Add Git configuration
* Generate and curate .Brewfile
* Create Homebrew bootstrap script
* Create Brew bundle run_onchange script
* Add bat/ripgrep/jj/etc. configs that actually exist
* Add Zed settings/keymap
* Add reusable ~/.local/bin scripts
* Review and add safe SSH configuration
* Add deliberate macOS preferences script
* Only then tackle secrets/encryption

The important filter throughout is:

Version desired state, not accumulated state.

A Brewfile containing 150 things that happened to get installed is almost as bad as no Brewfile. A `.config` directory copied wholesale is worse. Your repo should be small enough that every item answers the question: “Do I want a clean machine to get this?”

Confidence: 96%. The architecture and chezmoi/Homebrew mechanics are high-confidence; the remaining uncertainty is which optional configuration files currently exist on your Macs and which of the tools we’ve discussed are still part of your chosen stack.

Sources: ⁠chezmoi source-state attributes, ⁠chezmoi scripts, and ⁠Homebrew Bundle/Brewfile.
