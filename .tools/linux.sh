### Linux start ###
if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
        source /etc/profile.d/vte.sh
fi

export PATH=${PATH}:/usr/local/go/bin

if [ -f ~/Developer/shell/exercism_completion.zsh ]; then 
    source ~/Developer/shell/exercism_completion.zsh ; 
fi

### Linux end ###
