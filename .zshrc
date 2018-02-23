# Setting ZSH
export ZSH=~/.oh-my-zsh

# Load some secrets
if [ -f ~/.tools/secrets.sh ]; then source ~/.tools/secrets.sh; fi

# Attach os detector, now OS var constains either "macos" or "linux"
source ~/.tools/os_detector.sh

# Depending on OS type set ZSH plugins
if [[ "$OS" == "macos" ]]; then
  # Need to do it here prior loading "virtualenv" plugins
  export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3

  plugins=(git ssh-agent docker docker-compose osx vagrant iterm2 virtualenvwrapper virtualenv)
elif [[ "$OS" == "macos" ]]; then
  plugins=(git ssh-agent docker docker-compose virtualenvwrapper virtualenv)
fi

# Set visual theme
ZSH_THEME="dracula"

# Loading 
source $ZSH/oh-my-zsh.sh

# PGP configuration
if test -f ~/.gnupg/.gpg-agent-info -a -n "$(pgrep gpg-agent)"; then
  source ~/.gnupg/.gpg-agent-info
  export GPG_AGENT_INFO
  GPG_TTY=$(tty)
  export GPG_TTY
else
  eval $(gpg-agent --daemon --write-env-file ~/.gnupg/.gpg-agent-info)
fi

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

# Aliases
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias t="tree -a -L 1"
alias d="cd $DEVPATH"

# Beggining of OS dependednt sections

if [[ "$OS" == "macos" ]]; then
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
  if [ -f ~/Developer/bin/google-cloud-sdk/path.zsh.inc ]; then source ~/Developer/bin/google-cloud-sdk/path.zsh.inc; fi
  # The next line enables shell command completion for gcloud.
  if [ -f ~/Developer/bin/google-cloud-sdk/completion.zsh.inc ]; then source ~/Developer/bin/google-cloud-sdk/completion.zsh.inc; fi

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
  export MAVEN_OPTS="-Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.http.ssl.ignore.validity.dates=true -DskipTests=true"

  # Python configuration
  export PYTHONPATH="~/.venv/"

  # TravisCI configuration
  [ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh
  
  # vagrant settings
  export NOKOGIRI_USE_SYSTEM_LIBRARIES=true
  export VAGRANT_DEFAULT_PROVIDER="parallels"

  # Sodium configuration
  export SODIUM_LIB_DIR=/usr/local/Cellar/libsodium/1.0.13/lib

  ### MacOS end ###
fi

