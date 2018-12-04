### MacOS start ###

alias l="exa -al"

# GNU utilities
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

# AWS Region
export AWS_REGION=us-east-1

# Google configuration
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/application_default_credentials.json
# The next line updates PATH for the Google Cloud SDK.
if [ -f ~/Developer/usr/local/google-cloud-sdk/path.zsh.inc ]; then 
    source ~/Developer/usr/local/google-cloud-sdk/path.zsh.inc; 
fi

# The next line enables shell command completion for gcloud.
if [ -f ~/Developer/usr/local/google-cloud-sdk/completion.zsh.inc ]; then 
    source ~/Developer/usr/local/google-cloud-sdk/completion.zsh.inc; 
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
export GOPATH=$HOME/Developer
export GOBIN=$GOPATH/bin
export PATH=$GOBIN:$PATH

# Java configuration
export JAVA_HOME=$(/usr/libexec/java_home)

# Python configuration
export PYTHONPATH="~/.venv/"

# TravisCI configuration
[ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh

# vagrant settings
export NOKOGIRI_USE_SYSTEM_LIBRARIES=true
export VAGRANT_DEFAULT_PROVIDER="parallels"

# OpenSSL setup
export PATH=/usr/local/opt/openssl/bin:$PATH
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"

### MacOS end ###
