export TERM="xterm-256color"

# Setting ZSH
export ZSH=~/.oh-my-zsh
export TERM="xterm-256color"
export LC_ALL=en_US.UTF-8  
export LANG=en_US.UTF-8

# Set visual theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Loading Oh My Zsh settings
source $ZSH/oh-my-zsh.sh

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Theme init finish. Let's load OS dependednt code 

# Load some secrets
if [ -f ~/.tools/secrets.sh ]; then source ~/.tools/secrets.sh; fi

# Attach os detector, now OS var constains either "macos" or "linux"
source ~/.tools/os_detector.sh

# Depending on OS type set ZSH plugins
if [[ "$OS_TYPE" == "macos" ]]; then
  plugins=(git docker iterm2 gpg-agent) 
elif [[ "$OS_TYPE" == "linux" ]]; then
  plugins=(git gpg-agent docker)
fi

# Editor
export EDITOR='vim'

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"
export DEVPATH=$HOME/Developer
export PATH=$DEVPATH/bin:/usr/local/sbin:$PATH

# Rust setup
# source $HOME/.cargo/env
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

# Aliases
alias t="tree -a -L 1"
alias d="cd $DEVPATH"
alias zshconfig="code -n ~/.zshrc"
alias ohmyzsh="code -n ~/.oh-my-zsh"

alias l="exa -alh"
alias vim="nvim"

# Beggining of OS dependednt sections
if [[ "$OS_TYPE" == "macos" ]]; then
   source ~/.tools/macos.sh
elif [[ "$OS_TYPE" == "linux" ]]; then
  source ~/.tools/linux.sh
fi
