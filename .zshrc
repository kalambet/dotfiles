# Setting ZSH
export ZSH=~/.oh-my-zsh
export LC_ALL=en_US.UTF-8  
export LANG=en_US.UTF-8


# Set visual theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load some secrets
if [ -f ~/.tools/secrets.sh ]; then 
  source ~/.tools/secrets.sh; 
fi

# Attach os detector, now OS var constains either "macos" or "linux"
source ~/.tools/os_detector.sh

# Depending on OS type set ZSH plugins
if [[ "$OS_TYPE" == "macos" ]]; then
  plugins=(git docker iterm2 gpg-agent tmux kubectl)
elif [[ "$OS_TYPE" == "linux" ]]; then
  plugins=(git gpg-agent docker tmux)
fi

# Loading Oh My Zsh settings
source $ZSH/oh-my-zsh.sh

# Theme init finish. Let's load OS dependednt code 

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

