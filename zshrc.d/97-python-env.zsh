# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/junyi/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/home/junyi/miniconda3/etc/profile.d/conda.sh" ]; then
#         . "/home/junyi/miniconda3/etc/profile.d/conda.sh"
#     else
#         export PATH="/home/junyi/miniconda3/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# <<< conda initialize <<<

# source $HOME/.venv/bin/activate
export MAMBA_ROOT_PREFIX="$HOME/micromamba"

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'micromamba shell init' !!
# export MAMBA_EXE='/usr/bin/micromamba';
# export MAMBA_ROOT_PREFIX='/home/junyi/micromamba';
# __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__mamba_setup"
# else
#     alias micromamba="$MAMBA_EXE"  # Fallback on help from micromamba activate
# fi
# unset __mamba_setup
# <<< mamba initialize <<<
