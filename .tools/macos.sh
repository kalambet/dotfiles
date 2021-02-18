### MacOS start ###
export PATH="$HOME/.cargo/bin:$PATH"

# macOS specific aliases
alias rm="trash"
alias code="code-insiders"

# Rust setup
if [ -f $HOME/.cargo/env ]; then 
    source $HOME/.cargo/env; 
fi
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

# GitHub CLI settings
if [ -f ~/.gh.inc ]; then 
    source ~/.gh.inc; 
fi

# AWS Region
export AWS_REGION=us-east-1

# Google configuration
# export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gcloud/application_default_credentials.json
# The next line updates PATH for the Google Cloud SDK.
if [ -f $DEVPATH/bin/google-cloud-sdk/path.zsh.inc ]; then 
    source $DEVPATH/bin/google-cloud-sdk/path.zsh.inc; 
fi

# # The next line enables shell command completion for gcloud.
if [ -f $DEVPATH/bin/google-cloud-sdk/completion.zsh.inc ]; then 
    source $DEVPATH/bin/google-cloud-sdk/completion.zsh.inc; 
fi

## Android SDK
export PATH=$PATH:$DEVPATH/bin/platform-tools

# nvm setup
export NVM_DIR="$HOME/.nvm";
if [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
	source /usr/local/opt/nvm/nvm.sh;
fi

if [ -f /usr/local/etc/bash_completion.d ]; then
	source /usr/local/etc/bash_completion.d;
fi

# Special stuff for the visual man page improvement
function gman {
    if [ $# -eq 1 ] ;
        then open x-man-page://$1 ;
    elif [ $# -eq 2 ] ;
        then open x-man-page://$1/$2 ;
    fi
}

# Go configuration
export PATH="/usr/local/opt/go@1.13/bin:$PATH"	
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

### MacOS end ###
