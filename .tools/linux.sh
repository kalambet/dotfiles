### Linux start ###

# Global gitconfig setup
export GIT_CONFIG_GLOBAL=$HOME/.tools/gitconfig-linux

# zsh-autosuggestions activation
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

export PATH="$HOME/.local/bin":$PATH

alias cat="bat"

# Rust setup
if [ -f $HOME/.cargo/env ]; then
  source $HOME/.cargo/env
fi

export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

### Linux end ###
