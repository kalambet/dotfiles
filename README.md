# Overview

This repository contains configuration files for the local setup of Linux/macOS environment. Setup is baes on the following components:

- [Ghostty](https://ghostty.org/) - Nice terminal built with Zig
- [Z Shell](https://www.zsh.org/) - as a main Shell
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - Auto suggestions for Z Shell
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - Syntax highlighting for Z Shell
- [Starship](https://starship.rs/) - prompt for Z Shell
- [NeoVim](https://neovim.io/) - as a text editor
- [LazyVim](https://www.lazyvim.org/) - as a NeoVim plugin manager
- [Zed](https://zed.dev/) - as IDE
- [Zellij](https://zellij.dev/) - as a terminal session manager
- [mosh](https://mosh.org/) - SSH Server friendly for mobile and unstable connections

# Install
To install dotfiles `yadm` needs to be installed before. More detatils on how to it can be found in the [official `yadm` documentation](https://yadm.io/docs/install).

```shell
yadm clone https://github.com/kalambet/dotfiles
```

After repository is cloned, check `yadm status` to see potential conflicts.
