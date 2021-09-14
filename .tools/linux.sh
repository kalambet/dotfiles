### Linux start ###

# Update PATH
export PATH=${HOME}/go/bin:${PATH}:/usr/local/go/bin:${HOME}/.local/bin

# Rust setup
if [ -f $HOME/.cargo/env ]; then
    source $HOME/.cargo/env;
fi

export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

# nvm setup
export NVM_DIR="$HOME/.nvm"

if [ -f ~/Developer/shell/exercism_completion.zsh ]; then 
    source ~/Developer/shell/exercism_completion.zsh ; 
fi

### Linux end ###
