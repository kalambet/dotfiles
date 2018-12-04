# Setting ZSH
export ZSH=~/.oh-my-zsh

# Load some secrets
if [ -f ~/.tools/secrets.sh ]; then source ~/.tools/secrets.sh; fi

# Attach os detector, now OS var constains either "macos" or "linux"
source ~/.tools/os_detector.sh

# Depending on OS type set ZSH plugins
if [[ "$OS_TYPE" == "macos" ]]; then
  # Need to do it here prior loading "virtualenv" plugins
  export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3

  plugins=(git ssh-agent docker docker-compose osx vagrant iterm2)
elif [[ "$OS_TYPE" == "linux" ]]; then
  plugins=(git ssh-agent docker docker-compose)
fi

# Set visual theme
POWERLEVEL9K_MODE='awesome-fontconfig'
ZSH_THEME="powerlevel9k/powerlevel9k"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status load time)
POWERLEVEL9K_PROMPT_ON_NEWLINE=true

# Loading 
source $ZSH/oh-my-zsh.sh

# PGP configuration
#if test -f ~/.gnupg/.gpg-agent-info -a -n "$(pgrep gpg-agent)"; then
#  source ~/.gnupg/.gpg-agent-info
#  export GPG_AGENT_INFO
#  GPG_TTY=$(tty)
#  export GPG_TTY
#else
#  eval $(gpg-agent --daemon --write-env-file ~/.gnupg/.gpg-agent-info)
#fi

# You may need to manually set your language environment
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR='vim'
export TERM="xterm-256color"

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="~/.ssh/rsa_id"
export DEVPATH=$HOME/Developer
export PATH=/usr/local/sbin:$PATH

# Rust setup
source $HOME/.cargo/env
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

# Aliases
alias t="tree -a -L 1"
alias d="cd $DEVPATH"
alias zshconfig="vim -n ~/.zshrc"
alias ohmyzsh="vim -n ~/.oh-my-zsh"

alias l="exa -al"

# Beggining of OS dependednt sections

if [[ "$OS_TYPE" == "macos" ]]; then
  source ~/.tools/macos.sh
elif [[ "$OS_TYPE" == "linux" ]]; then
  source ~/.tools/linux.sh
fi

