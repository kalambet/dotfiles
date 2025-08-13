# Setting ZSH
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Zsh History
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Load some secrets
if [ -f ~/.tools/secrets.sh ]; then
  source ~/.tools/secrets.sh;
fi

# Editor
export EDITOR='nvim'

# ssh
export DEVPATH=$HOME/Developer
export PATH=$DEVPATH/bin:/usr/local/sbin:$PATH

# Aliases
alias t="eza --tree -a -L 1"
alias d="cd $DEVPATH"
alias l="eza -lhg --group-directories-first --icons"
alias la="l -a"
alias lt='eza --tree --level=2 --long --icons --git'
alias vim="nvim"
alias rmix="remixd -s $PWD -u https://remix.ethereum.org"

# Load all the zsh-completions
autoload -U compinit && compinit

# Beggining of OS dependednt sections
# Attach os detector, now OS var constains either "macos" or "linux"
source ~/.tools/os_detector.sh

if [[ "$OS_TYPE" == "macos" ]]; then
   source $HOME/.tools/macos.sh
elif [[ "$OS_TYPE" == "linux" ]]; then
  source $HOME/.tools/linux.sh
fi

if [[ -f $HOME/.tools/projects.sh ]]; then
	source $HOME/.tools/projects.sh
fi

if [[ -f $HOME/.tools/docker.sh ]]; then
	source $HOME/.tools/docker.sh
fi

if [[ -f $HOME/.tools/hosts.sh ]]; then
	source $HOME/.tools/hosts.sh
fi

# Setup starship
export STARSHIP_CACHE=~/.starship/cache
eval "$(starship init zsh)"
