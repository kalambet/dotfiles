# Overview

This repository contains configuration files for the local setup of macOS environment. Setup is based on the following components:

- [Ghostty](https://ghostty.org/) - Nice terminal built with Zig
- [Z Shell](https://www.zsh.org/) - as a main Shell
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - Syntax highlighting for Z Shell
- [Starship](https://starship.rs/) - prompt for Z Shell
- [NeoVim](https://neovim.io/) - as a text editor
- [LazyVim](https://www.lazyvim.org/) - as a NeoVim plugin manager
- [Zed](https://zed.dev/) - as IDE
- [mosh](https://mosh.org/) - SSH Server friendly for mobile and unstable connections
- [1Password](https://developer.1password.com/docs/ssh/) - SSH agent and git commit signing (on `master`)

# Claude Code

The repository also carries a [Claude Code](https://claude.com/claude-code) setup under `.claude/`:

- `CLAUDE.md` - global instructions plus the roster of installed skills, teams, and agents
- `skills/` - custom skills: domain (ai-dev, apple-dev, reviewers), language suites (Python / Rust / TypeScript / Solidity architect-developer-reviewer), architecture (distributed systems, LLM systems, web3), process (research-plan-implement, pr-review, warp / pickup), and multi-agent team skills
- `agents/` - subagent definitions mirroring the skills for delegated and parallel work

# Branches

- `master` - the canonical setup, with 1Password handling the SSH agent and git commit signing
- `neurolambda` - machine-specific variant with the 1Password CLI abstraction removed (plain SSH keys for GitHub auth and commit signing)

# Install
To install dotfiles `yadm` needs to be installed before. More details on how to do it can be found in the [official `yadm` documentation](https://yadm.io/docs/install).

```shell
yadm clone https://github.com/kalambet/dotfiles
```

After repository is cloned, check `yadm status` to see potential conflicts.
