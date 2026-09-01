# repo-cloner

Interactively pick GitHub repositories and clone them into per-project folders.

Cloning a working set one `git clone` at a time is tedious and easy to get
wrong, and a hardcoded list of repositories goes stale the moment someone
creates a new one. This script asks GitHub what exists, shows you a checklist,
and clones only what you tick — into the folder layout you defined.

## Why

- **Live inventory.** Repositories come from `gh` on every run, so new ones
  appear without editing anything.
- **Safe to re-run.** Anything already cloned is detected and excluded from the
  picker, so the script never duplicates or overwrites work.
- **Grouped layout.** Repositories land in `<folder>/<repo>` instead of one flat
  pile, which keeps unrelated projects apart.
- **No personal data in the repo.** Owners and groups live in your own config
  file, outside version control.

## Requirements

- [`gh`](https://cli.github.com/), authenticated (`gh auth login`)
- [`gum`](https://github.com/charmbracelet/gum) or
  [`fzf`](https://github.com/junegunn/fzf) for the picker

## Setup

```sh
mkdir -p ~/.config/repo-cloner
cp groups.example.conf ~/.config/repo-cloner/groups.conf
$EDITOR ~/.config/repo-cloner/groups.conf
```

Each line maps a group of repositories to a destination folder:

```
# <folder>|<owner>|<name filter regex, empty = every repo>
work|acme-inc|
client|my-user|clientname
labs|my-user|^lab-
```

## Usage

```sh
# Clone into the current directory
./clone-repos.sh

# Clone into a specific working directory
./clone-repos.sh --dest ~/Work

# See what would be cloned without touching the disk
./clone-repos.sh --dest ~/Work --dry-run

# Use an alternative config
./clone-repos.sh --config ~/.config/repo-cloner/other.conf
```

In the picker, **space** toggles a repository (**tab** under `fzf`), **enter**
confirms, **esc** aborts.

Resulting layout:

```
~/Work
├── work/
│   ├── api
│   └── web-app
├── client/
│   └── clientname-integration
└── labs/
    └── lab-scraper
```

## Configuration reference

| Setting | Flag | Environment variable | Default |
| --- | --- | --- | --- |
| Config file | `--config` | `REPO_CLONER_CONFIG` | `~/.config/repo-cloner/groups.conf` |
| Destination | `--dest` | `REPO_CLONER_DEST` | current directory |
| Dry run | `--dry-run` | — | off |
| Picker | — | `REPO_CLONER_PICKER` | `gum`, else `fzf` |
