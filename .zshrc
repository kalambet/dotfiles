# General setting
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export EDITOR='nvim'

###
# zsh configuration
###

setopt COMPLETE_ALIASES
setopt GLOB_COMPLETE

# The following lines were added by compinstall
zstyle :compinstall filename '/Users/peter/.zshrc'

autoload -Uz compinit
compinit

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# End of lines added by compinstall

# zsh History
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

###
# Main paths definition
###
export DEVPATH=$HOME/Developer
export PATH=$DEVPATH/bin:$HOME/.local/bin:/usr/local/sbin:$PATH

###
# Aliases and env variables
####

# Load local variables
source ~/.env

alias t="eza --tree -a -L 1"
alias d="cd $DEVPATH"
alias l="eza -lhg --group-directories-first --icons"
alias la="l -a"
alias lt='eza --tree --level=2 --long --icons --git'
alias vim="nvim"
alias rm="trash"
alias rrm="rm"
alias cat="bat"
alias ports="netstat -anvp tcp | awk 'NR<3 || /LISTEN/'"

alias rmix="remixd -s $PWD -u https://remix.ethereum.org"

# Special stuff for the visual man page improvement
function gman {
  if [ $# -eq 1 ]; then
    open x-man-page://$1
  elif [ $# -eq 2 ]; then
    open x-man-page://$1/$2
  fi
}

###
# Tooling configuration
####
# Homebrew setup
export HOMEBREW_NO_ANALYTICS=1

brew-app-upgrade() {
  brew upgrade $(brew list --cask -1)
}

# .NET Setup
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# 1Password Setup
export OP_BIOMETRIC_UNLOCK_ENABLED=true
source /Users/peter/.config/op/plugins.sh

# Rust setup
if [ -f $HOME/.cargo/env ]; then
  source $HOME/.cargo/env
fi
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

# Foundry
if [ -d $HOME/.foundry ]; then
  export PATH="$PATH:/Users/peter/.foundry/bin"
fi

# GitHub CLI settings
if [ -f ~/.gh.inc ]; then
  source ~/.gh.inc
fi

# Bun settings
if [ -d $HOME/.bun ]; then
  export PATH=$PATH:$HOME/.bun/bin
  source $HOME/.bun/_bun
fi

# Google configuration
# export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gcloud/application_default_credentials.json
# The next line updates PATH for the Google Cloud SDK.
# if [ -f $DEVPATH/bin/google-cloud-sdk/path.zsh.inc ]; then
# 	source $DEVPATH/bin/google-cloud-sdk/path.zsh.inc
# fi

# # The next line enables shell command completion for gcloud.
# if [ -f $DEVPATH/bin/google-cloud-sdk/completion.zsh.inc ]; then
# 	source $DEVPATH/bin/google-cloud-sdk/completion.zsh.inc
# fi

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
fi

# Go configuration
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$GOBIN:$PATH

# Python configuration
export PYTHONPATH="~/.venv/"
# export VIRTUAL_ENV_DISABLE_PROMPT=1

# OpenSSL setup
export PATH=/usr/local/opt/openssl/bin:$PATH
export LDFLAGS="-L/usr/local/opt/openssl/lib -L/usr/local/lib -L/usr/local/opt/expat/lib"
export CFLAGS="-I/usr/local/opt/openssl/include -I/usr/local/include -I/usr/local/opt/expat/include"
export CPPFLAGS="-I/usr/local/opt/openssl/include -I/usr/local/include -I/usr/local/opt/expat/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"

# LLVM setup
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# Java setup
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# Android tools setup
if [ -d "$HOME/Developer/bin/android/platform-tools" ]; then
  export PATH="$HOME/Developer/bin/android/platform-tools:$PATH"
fi

# Added for LM Studio CLI support
if [ -d "$HOME/.cache/lm-studio" ]; then
  export PATH="$PATH:/Users/peter/.cache/lm-studio/bin"
fi
# End of LM Studio CLI section

# Docker setup
docker-prune () {
	docker stop $(docker ps -aq)
	docker rm $(docker ps -q --filter status=exited)
	docker volume rm $(docker volume ls -q)
	docker network rm $(docker network ls -q)
	docker rmi $(docker images -q --filter dangling=true)
}

docker-cleanup () {
	docker rm $(docker ps -aq -f "status=exited")
	docker rmi $(docker images -q --filter dangling=true)
}
#

# Daml setup
if [ -d "$HOME/.daml" ]; then
  export PATH="$PATH:$HOME/.daml/bin"
fi

# Added by Antigravity
export PATH="/Users/peter/.antigravity/antigravity/bin:$PATH"

# Setup starship
export STARSHIP_CACHE=~/.starship/cache
eval "$(starship init zsh)"
