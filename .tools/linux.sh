### Linux start ###

# Setup Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Update PATH
# export PATH=${HOME}/go/bin:${PATH}:/usr/local/go/bin:${HOME}/.local/bin
export PATH=$PATH:$HOME/Applications/JetBrains

# Rust setup
if [ -f $HOME/.cargo/env ]; then
    source $HOME/.cargo/env;
fi

export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

# nvm setup
export NVM_DIR="$HOME/.nvm"

### Linux end ###
