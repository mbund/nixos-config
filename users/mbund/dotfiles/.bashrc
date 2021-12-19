# Set zsh has the default shell if it isn't already
export SHELL=`which zsh`
[ -z "$ZSH_VERSION" ] && exec "$SHELL" -l