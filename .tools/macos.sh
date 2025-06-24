### MacOS start ###

# Global gitconfig setup
export GIT_CONFIG_GLOBAL=$HOME/.tools/gitconfig-macos

# zsh-autosuggestions activation
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Zsh Syntax Highlight
if [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Homebrew setup
export HOMEBREW_NO_ANALYTICS=1

# .NET Setup
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# 1Password Setup
export OP_BIOMETRIC_UNLOCK_ENABLED=true
source /Users/peter/.config/op/plugins.sh

# iTerm2 setup
# test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# macOS specific aliases
alias rm="trash"
alias rrm="rm"
alias ports="netstat -anvp tcp | awk 'NR<3 || /LISTEN/'"

brew-app-upgrade() {
  brew upgrade $(brew list --cask -1)
}

# Rust setup
if [ -f $HOME/.cargo/env ]; then
  source $HOME/.cargo/env
fi
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

# Foundry
export PATH="$PATH:/Users/peter/.foundry/bin"

# GitHub CLI settings
if [ -f ~/.gh.inc ]; then
  source ~/.gh.inc
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
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Special stuff for the visual man page improvement
function gman {
  if [ $# -eq 1 ]; then
    open x-man-page://$1
  elif [ $# -eq 2 ]; then
    open x-man-page://$1/$2
  fi
}

# Go configuration
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$GOBIN:$PATH

# Python configuration
# export PYTHONPATH="~/.venv/"
export VIRTUAL_ENV_DISABLE_PROMPT=1

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

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/peter/.cache/lm-studio/bin"

# Android tools setup
# if [ -d "$HOME/Developer/bin/android/platform-tools" ] ; then
#  export PATH="$HOME/Developer/bin/android/platform-tools:$PATH"
# fi

### MacOS end ###
