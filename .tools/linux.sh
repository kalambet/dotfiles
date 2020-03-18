### Linux start ###
export PATH=${PATH}:/usr/local/go/bin

if [ -f ~/Developer/shell/exercism_completion.zsh ]; then 
    source ~/Developer/shell/exercism_completion.zsh ; 
fi

# Initialize brew for linux
export PATH="/home/linuxbrew/.linuxbrew/bin":$PATH

export NVM_DIR="$HOME/.nvm"
# This loads nvm
if [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ]; then
	source "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"
fi

# This loads nvm bash_completion
if [ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ]; then
	source "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"
fi

### Linux end ###
