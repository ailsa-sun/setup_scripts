# To the extent possible under law, the author(s) have dedicated all 
# copyright and related and neighboring rights to this software to the 
# public domain worldwide. This software is distributed without any warranty. 
# You should have received a copy of the CC0 Public Domain Dedication along 
# with this software. 
# If not, see <https://creativecommons.org/publicdomain/zero/1.0/>. 

# ~/.bashrc: executed by bash(1) for interactive shells.

# The copy in your home directory (~/.bashrc) is yours, please
# feel free to customise it to create a shell
# environment to your liking.  If you feel a change
# would be benifitial to all, please feel free to send
# a patch to the msys2 mailing list.

# User dependent .bashrc file

# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

# Shell Options
#
# See man bash for more options...
#
# Don't wait for job termination notification
# set -o notify
#
# Don't use ^D to exit
# set -o ignoreeof
#
# Use case-insensitive filename globbing
# shopt -s nocaseglob
#
# Make bash append rather than overwrite the history on disk
# shopt -s histappend
#
# When changing directory small typos can be ignored by bash
# for example, cd /vr/lgo/apaache would find /var/log/apache
# shopt -s cdspell

# Completion options
#
# These completion tuning parameters change the default behavior of bash_completion:
#
# Define to access remotely checked-out files over passwordless ssh for CVS
# COMP_CVS_REMOTE=1
#
# Define to avoid stripping description in --option=description of './configure --help'
# COMP_CONFIGURE_HINTS=1
#
# Define to avoid flattening internal contents of tar files
# COMP_TAR_INTERNAL_PATHS=1
#
# Uncomment to turn on programmable completion enhancements.
# Any completions you add in ~/.bash_completion are sourced last.
# [[ -f /etc/bash_completion ]] && . /etc/bash_completion

# History Options
#
# Don't put duplicate lines in the history.
# export HISTCONTROL=$HISTCONTROL${HISTCONTROL+:}ignoredups
#
# Ignore some controlling instructions
# HISTIGNORE is a colon-delimited list of patterns which should be excluded.
# The '&' is a special pattern which suppresses duplicate entries.
# export HISTIGNORE=$'[ \t]*:&:[fb]g:exit'
# export HISTIGNORE=$'[ \t]*:&:[fb]g:exit:ls' # Ignore the ls command as well
#
# Whenever displaying the prompt, write the previous line to disk
# export PROMPT_COMMAND="history -a"

# Aliases
#
# Some people use a different file for aliases
# if [ -f "${HOME}/.bash_aliases" ]; then
#   source "${HOME}/.bash_aliases"
# fi
#
# Some example alias instructions
# If these are enabled they will be used instead of any instructions
# they may mask.  For example, alias rm='rm -i' will mask the rm
# application.  To override the alias instruction use a \ before, ie
# \rm will call the real rm not the alias.
#
# Interactive operation...
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'
#
# Default to human readable figures
# alias df='df -h'
# alias du='du -h'
#
# Misc :)
# alias less='less -r'                          # raw control characters
# alias whence='type -a'                        # where, of a sort
# alias grep='grep --color'                     # show differences in colour
# alias egrep='egrep --color=auto'              # show differences in colour
# alias fgrep='fgrep --color=auto'              # show differences in colour
#
# Some shortcuts for different directory listings
# alias ls='ls -hF --color=tty'                 # classify files in colour
# alias dir='ls --color=auto --format=vertical'
# alias vdir='ls --color=auto --format=long'
# alias ll='ls -l'                              # long list
# alias la='ls -A'                              # all but . and ..
# alias l='ls -CF'                              #

# Umask
#
# /etc/profile sets 022, removing write perms to group + others.
# Set a more restrictive umask: i.e. no exec perms for others:
# umask 027
# Paranoid: neither group nor others have any perms:
# umask 077

# Functions
#
# Some people use a different file for functions
# if [ -f "${HOME}/.bash_functions" ]; then
#   source "${HOME}/.bash_functions"
# fi
#
# Some example functions:
#
# a) function settitle
# settitle () 
# { 
#   echo -ne "\e]2;$@\a\e]1;$@\a"; 
# }
# 
# b) function cd_func
# This function defines a 'cd' replacement function capable of keeping, 
# displaying and accessing history of visited directories, up to 10 entries.
# To use it, uncomment it, source this file and try 'cd --'.
# acd_func 1.0.5, 10-nov-2004
# Petar Marinov, http:/geocities.com/h2428, this is public domain
# cd_func ()
# {
#   local x2 the_new_dir adir index
#   local -i cnt
# 
#   if [[ $1 ==  "--" ]]; then
#     dirs -v
#     return 0
#   fi
# 
#   the_new_dir=$1
#   [[ -z $1 ]] && the_new_dir=$HOME
# 
#   if [[ ${the_new_dir:0:1} == '-' ]]; then
#     #
#     # Extract dir N from dirs
#     index=${the_new_dir:1}
#     [[ -z $index ]] && index=1
#     adir=$(dirs +$index)
#     [[ -z $adir ]] && return 1
#     the_new_dir=$adir
#   fi
# 
#   #
#   # '~' has to be substituted by ${HOME}
#   [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"
# 
#   #
#   # Now change to the new dir and add to the top of the stack
#   pushd "${the_new_dir}" > /dev/null
#   [[ $? -ne 0 ]] && return 1
#   the_new_dir=$(pwd)
# 
#   #
#   # Trim down everything beyond 11th entry
#   popd -n +11 2>/dev/null 1>/dev/null
# 
#   #
#   # Remove any other occurence of this dir, skipping the top of the stack
#   for ((cnt=1; cnt <= 10; cnt++)); do
#     x2=$(dirs +${cnt} 2>/dev/null)
#     [[ $? -ne 0 ]] && return 0
#     [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
#     if [[ "${x2}" == "${the_new_dir}" ]]; then
#       popd -n +$cnt 2>/dev/null 1>/dev/null
#       cnt=cnt-1
#     fi
#   done
# 
#   return 0
# }
# 
# alias cd=cd_func
REMOTE_HOST="cmuwin"
REMOTE_PORT="22"

# Copy a local file TO the remote machine
scpto() {
    if [ -z "$1" ]; then
        echo "Usage: scpto <local_file> [remote_dir]"
        return 1
    fi
    local dest="${2:-$REMOTE_DIR}"
    scp -P "$REMOTE_PORT" "$1" "${REMOTE_HOST}:$2"
}

# Copy a file FROM the remote machine
scpfrom() {
    if [ -z "$1" ]; then
        echo "Usage: scpfrom <remote_file> [local_dir]"
        return 1
    fi
    local dest="${2:-.}"
    scp -P "$REMOTE_PORT" "${REMOTE_HOST}:$1" "$2"
}

export scpland="/c/Users/Computer/Documents/scpland"
export bwrcintellaptop="10.44.95.242"
alias bklogin="ssh alan@100.106.64.31"
alias cmulogin="ssh -i C:/Users/Computer/.ssh/cmuwindows -J ailsa@wire.pdl.cmu.edu jjshe@172.24.33.177"
alias kvmlogin="ssh -L8080:172.24.33.15:443 ailsa@wire.pdl.cmu.edu"
# User/App Paths
export APPDATA="/c/Users/Computer/AppData/Roaming"
export LOCALAPPDATA="/c/Users/Computer/AppData/Local"
export USERPROFILE="/c/Users/Computer"
export HOMEPATH="/c/Users/Computer"
export PUBLIC="/c/Users/Public"
export TEMP="/c/Users/Computer/AppData/Local/Temp"
export TMP="/c/Users/Computer/AppData/Local/Temp"

# System
export COMPUTERNAME="DESKTOP-JVPJPLE"
export OS="Windows_NT"
export SystemRoot="/c/Windows"
export SystemDrive="/c"
export NUMBER_OF_PROCESSORS="16"
export PROCESSOR_ARCHITECTURE="AMD64"

# Chocolatey
export ChocolateyInstall="/c/ProgramData/chocolatey"

# Conda
export CONDA_BAT="/c/ProgramData/miniconda3/condabin/conda.bat"
export CONDA_EXE="/c/ProgramData/miniconda3/Scripts/conda.exe"
export CONDA_SHLVL="0"

# ESP / Espressif
export IDF_TOOLS_PATH="/c/Espressif"

# Misc
export ZES_ENABLE_SYSMAN="1"

# PATH
export PATH="$PATH:\
/c/ProgramData/miniconda3/condabin:\
/c/Program Files/Eclipse Adoptium/jdk-21.0.4.7-hotspot/bin:\
/c/Program Files (x86)/VMware/VMware Workstation/bin:\
/c/Users/Computer/AppData/Roaming/Python/Scripts:\
/c/Windows/system32:\
/c/Windows:\
/c/Windows/System32/Wbem:\
/c/Windows/System32/WindowsPowerShell/v1.0:\
/c/Windows/System32/OpenSSH:\
/c/Program Files/Git/cmd:\
/c/Program Files/MATLAB/R2024b/runtime/win64:\
/c/Program Files/MATLAB/R2024b/bin:\
/c/Users/Computer/AppData/Local/Programs/Python/Python312/Scripts:\
/c/Users/Computer/AppData/Local/Microsoft/WindowsApps:\
/c/Program Files/scala-cli-x86_64-pc-win32:\
/c/Users/Computer/Documents/curl-8.11.1_3-win64-mingw/curl-8.11.1_3-win64-mingw/bin:\
/c/Users/Computer/Documents:\
/c/Program Files/PuTTY:\
/c/Users/Computer/AppData/Local/Programs/Python/Python311:\
/c/ProgramData/chocolatey/bin:\
/c/Program Files/Amazon/AWSCLIV2:\
/c/Program Files/dotnet:\
/c/Strawberry/c/bin:\
/c/Strawberry/perl/site/bin:\
/c/Strawberry/perl/bin:\
/c/Program Files/Neovim/bin:\
/c/Users/Computer/.cargo/bin:\
/c/Users/Computer/AppData/Local/Programs/Python/Python312/Scripts:\
/c/Users/Computer/AppData/Local/Programs/Python/Launcher:\
/c/Users/Computer/AppData/Local/Programs/Microsoft VS Code/bin:\
/c/Users/Computer/arduino-cli_1.1.1_Windows_64bit:\
/c/Users/Computer/AppData/Local/Programs/MiKTeX/miktex/bin/x64:\
/c/msys64/ucrt64/bin:\
/c/Users/Computer/AppData/Local/Android/Sdk/platform-tools:\
/c/Users/Computer/AppData/Local/Programs/Python/Python312/Lib/site-packages:\
/c/ProgramData/miniconda3:\
/c/ProgramData/miniconda3/Scripts:\
/c/Users/Computer/Documents/vcpkg:\
/c/Users/Computer/Documents/Procdump:\
/c/Users/Computer/.local/bin:\
/c/Users/Computer/.dotnet/tools:\
/c/ProgramData/Computer/GitHubDesktop/bin:\
/c/Users/Computer/AppData/Local/GitHubDesktop/bin"
