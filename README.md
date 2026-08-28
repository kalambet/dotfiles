# macOS dotfiles

Personal macOS configuration managed with [yadm](https://yadm.io/). The
repository stores user-level configuration, a Homebrew package manifest, and a
portable agent-harness setup. It does not contain a complete macOS image or
install every declared tool when cloned.

## What the repository contains

### Shell and command-line environment

- Zsh startup and aliases: `.zshrc`, `.zsh_aliases`
- Starship prompt: `.config/starship.toml`
- Git configuration: `.gitconfig`, `.gitignore`
- tmux configuration: `.config/tmux/tmux.conf`
- 1Password CLI shell integration: `.config/op/plugins.sh`

### Applications

- Ghostty: `.config/ghostty/config`
- Zed: `.config/zed/settings.json`
- `Brewfile`: Homebrew formulae, casks, and npm packages used by this setup

The `Brewfile` includes tools such as Neovim, tmux, mosh, eza, fzf, Starship,
uv, yadm, Claude Code, and the 1Password CLI. A package being listed does not
mean its application-specific configuration is tracked here.

### Universal agent configuration

`~/.agents/` is the source of truth shared across supported coding-agent
harnesses:

- `AGENTS.md` — universal instructions
- `skills/` — portable skills
- `prompts/` — canonical agent-role prompts
- `commands/` — canonical research, plan, and implementation workflows
- `adapters.yaml` and `scripts/` — adapter generation and verification
- `records/` — durable research and implementation decisions

Tracked adapters expose that source through the native locations used by Claude
Code, Codex, Amp, JetBrains Junie, and OpenCode. Claude, Codex, and Amp are the
primary supported surfaces, although Codex custom-prompt discovery still needs
confirmation in a fresh interactive session. Junie and OpenCode adapters are
initial, experimental support and have not been live-validated with installed
CLIs.

Generated regular files are owned through
`.agents/generated-adapters.yaml`. Edit canonical files under `.agents/`, then
run:

```shell
~/.agents/scripts/sync-adapters.sh --apply
~/.agents/scripts/verify-setup.sh
```

## What `yadm clone` does

`yadm clone` clones the repository and attempts to check its tracked files out
directly into `$HOME`. If a local file already exists with different content,
yadm leaves it unchanged so the conflict can be reviewed. See the official
[getting-started documentation](https://yadm.io/docs/getting_started).

Cloning brings:

- the tracked dotfiles and application configuration listed above;
- the `Brewfile`, but not the software declared in it;
- canonical agent skills, prompts, commands, and records;
- tracked harness adapters, the adapter generator, validation scripts, bootstrap,
  and pre-push hook.

Cloning does not install Homebrew packages, configure macOS system preferences,
authenticate external services, or install the optional Junie/OpenCode CLIs.

After a successful clone, yadm detects `.config/yadm/bootstrap` and offers to run
it. This repository's bootstrap requires `uv`; it regenerates the agent adapters
and verifies their state. It does not run `brew bundle`. The prompt can be
controlled with `yadm clone --bootstrap` or `yadm clone --no-bootstrap`; see the
official [bootstrap documentation](https://yadm.io/docs/bootstrap).

## Install on a new Mac

Install Homebrew first, then install the two prerequisites needed to clone and
run this repository's bootstrap:

```shell
brew install yadm uv
yadm clone https://github.com/kalambet/dotfiles
yadm status
```

Accept the bootstrap prompt, or run it later:

```shell
yadm bootstrap
```

Install the broader toolset separately when wanted:

```shell
brew bundle --file ~/Brewfile
```

Review `yadm status` after cloning and before replacing any pre-existing local
configuration.
