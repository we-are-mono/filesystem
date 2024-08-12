source /etc/profile.d/bash_completion.sh

case $- in
  *i*) ;;
    *) return;;
esac

export OSH=/usr/local/share/oh-my-bash

OSH_THEME="standard"
OMB_USE_SUDO=true

completions=(
  ssh
)

aliases=(
  general
)

plugins=(
  bashmarks
)

source "$OSH"/oh-my-bash.sh
