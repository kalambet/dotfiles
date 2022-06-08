### Linux start ###

export PATH="$HOME/.local/bin":$PATH 

alias cat="bat"

# Rust setup
if [ -f $HOME/.cargo/env ]; then
    source $HOME/.cargo/env;
fi

export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

# nvm setup
# export NVM_DIR="$HOME/.nvm"

### Linux end ###
