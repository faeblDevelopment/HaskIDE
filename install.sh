#!/bin/bash

printHelp() {
  echo Installs HaskIDE with the specified settings
  echo Usage:
  echo "install.sh ([-g][-c][-v][-s][-n][-h][-a])+ [install_dir]"
  echo "()+ is regex for at least one of these flags"
  echo "-g: installs a bash git extension"
  echo "-c: copies a compose key file with greek letters to the system (compose key is set to [ALL-CAPS])"
  echo "-v: copies vim syntax files for Haskell and LiterateHaskell to the system"
  echo "-s: installs haskell stack"
  echo "-n: installs just the base system without anything"
  echo "-h: displays this help"
  echo "-a: all of the above without the help"
  echo "-d: adds debug information to the output"
}

# ======= system customization options ==========

git_bash_flag=false     # should the bash git extension be installed?
compose_key_flag=false  # should a greek letter compose key file be copied to ~/.XCompose
syntax_flag=false       # should Cabal, Haskell & LiterateHaskell vim syntax files be copied to ~/.vim/syntax/
stack_flag=false        # should haskell stack be installed

any_flags=false         # are any flags set or does the user wish to install no extensions? (otherwise print help)

debug=false             # should debug output be printed?
  
## detect flags given by user
params=$#
let "i=1"
while (("$i"<="$#")); do 
  case "${!i}" in
    -g) git_bash_flag=true && any_flags=true && let "params=params-1";;
    -c) compose_key_flag=true  && any_flags=true && let "params=params-1";;
    -v) syntax_flag=true && any_flags=true && let "params=params-1";;
    -s) stack_flag=true && any_flags=true && let "params=params-1";;
    -a) git_bash_flag=true && compose_key_flag=true && syntax_flag=true && stack_flag=true && any_flags=true && let "params=params-1" ;;
    -n) any_flags=true && let "params=params-1";;
    -d) debug=true && let "params=params-1";;
    -h) printHelp && exit 0;;
  esac
  let "i=i+1"
done

## check if flags are set properly
if ! $any_flags; then
  echo Nothing specified, aborting installation.
  printHelp
  exit 1
fi

## Display settings for user to cancel
echo "Settings:"
printf " Install git terminal extension: "; if $git_bash_flag; then echo " True"; else echo " False"; fi
printf " Install compose key extension:  "; if $compose_key_flag; then echo " True"; else echo " False"; fi
printf " Install Haskell syntax files:   "; if $syntax_flag; then echo " True"; else echo " False"; fi
printf " Install Haskell Stack:          "; if $stack_flag; then echo " True"; else echo " False"; fi
echo ""

## user review of settings
cont=false
read -p "Continue installation with these settings? (y|N) " cont
if ! [[ $cont =~ (y|Y|yes|YES) ]]; then
  echo Installation cancelled by user
  exit 0
fi


# ================ input checks ================

## get retrieve installation dir from input [first parameter without -
let "i=1"
while [[ -z "$install_dir" || $install_dir =~ -.* ]] && (("$i"<="$#")); do
  install_dir=${!i}
  let "i=i+1"
done

## if install_dir begins with -, no installation directory was specified by the
## user; set it to default
if [[ $install_dir =~ -.* ]]; then
  install_dir=""
fi

$debug && echo [debug] install_dir: $install_dir

## default installation dir or custom?
if [[ -z "$install_dir" ]]; then
  read -p "Install hide to ~/.hide/? (YES | [path to folder]) " install_dir
  echo ""
  if [[ $install_dir =~ (y|Y|yes|YES|Yes) || -z "$install_dir" ]]; then
    echo Installing to default location
    install_dir="$HOME/.hide" 
  else
    echo Installing to $install_dir
  fi
  $debug && echo [debug] creating install_dir $install_dir
  
  ## make sure installation dir exists
  mkdir -p $(realpath "$install_dir")
  install_dir=`realpath $install_dir`

  ## if installation directory could not be created
  if [[ -z "$install_dir" ]] || [[ -f $install_dir ]]; then
    echo "Could not create installation directory. Aborting installation"
    exit 1
  fi
fi

$debug && echo "[debug] install_dir before check: $install_dir"
## if installation directory is not standard dir, create .hiderc with pointer to location
if ! [[ "$install_dir" = `realpath $HOME/.hide` ]]; then
  mkdir -p $install_dir
  install_dir=`realpath $install_dir`
  echo "Creating .hiderc in ~ to point to $install_dir"
  echo -e "\e[1;33m[INFO] If you move your installation directory, update your ~/.hiderc\e[0m"
  $debug && echo "[debug] $install_dir >> $HOME/.hiderc"
  echo $install_dir >> $HOME/.hiderc 
fi

# ========== get Package Manager ============
## guess installation command
install_cmd=""

## make array with distributions and standard package managers
## https://unix.stackexchange.com/a/46086/268817
declare -A osInfo;
osInfo[/etc/redhat-release]="yum install"
osInfo[/etc/arch-release]="pacman -S"
osInfo[/etc/gentoo-release]="emerge"
osInfo[/etc/SuSE-release]="zypper install"
osInfo[/etc/debian-version]="apt-get install"

for f in ${!osInfo[@]}; do
  if [[ -f $f ]]; then
    install_cmd=${osInfo[$f]}
  fi
done

echo "Using package installation command: $install_cmd"
# ============ base libraries ====================

echo Installing dependencies {vim git ruby tree ruby tmux gcc tmuxinator}
# vim: IDE editor
# git: for source control in IDE
# ruby: for gem package manager
# tree: option for viewing directory trees in IDE
# tmux: panes of IDE
# gcc: to compile vimproc
# tmuxinator: IDE UI
sudo $install_cmd vim git ruby tree tmux gcc 
gem install tmuxinator

echo Adding tmuxinator to path in $HOME/.bashrc
echo "export PATH=\"\$PATH:$HOME/.gem/ruby/2.6.0/bin\"" >> $HOME/.bashrc

echo Setting default editor to VIM in $HOME/.bashrc
echo "export EDITOR=\"/usr/bin/vim\"" >> $HOME/.bashrc

## get the directory with the sources for copying
source_dir=`dirname "$0"`
$debug && echo [debug] Source_Dir: $source_dir

echo "Copying sources from $source_dir to $install_dir"
cp -r $source_dir/hide/* $install_dir

## initialize .vim home directory if not already present
mkdir $HOME/.vim
## copying tested plugin versions to vim plugin dirs
cp -r $source_dir/autoload $HOME/.vim/ > /dev/null  # silent because files could exist and not being able to overwrite
cp -r $source_dir/plugged $HOME/.vim/  > /dev/null

echo Enabling executables
sudo chmod +x $install_dir/haskide
sudo chmod +x $install_dir/ivim

# add the IDE installation directory to the path
echo "Adding $install_dir to PATH in $HOME/.bashrc"
echo "export PATH=\"\$PATH:$install_dir\"" >> $HOME/.bashrc


if $stack_flag; then
  #install stack if wished
  echo Installing stack...
  sudo $install_cmd stack
fi

if $git_bash_flag; then
  #add git extension to bash if wished
  echo Adding git extension to bashrc...
  bc="bash_custom.sh"
  cat $source_dir/$bc >> $HOME/.bashrc
  echo -e "\e[1;33m[INFO]: Dont forget to execute 'source $HOME/.bashrc' to enable the git extension\e[0m"
fi

if $compose_key_flag; then
  #add compose key file and tell user to activate key if wished
  echo Adding compose key file...
  ck="XCompose"
  cat $source_dir/$ck >> $HOME/.XCompose
  echo -e "\e[1;33m[INFO]: Please activate the Compose Key feature via Tweaks-Keyboard and Mouse - Compose Key\e[0m"
fi

if $syntax_flag; then
  #add syntax files to .vim syntax directory if wished
  echo Adding Haskell Vim Syntax files...
  hask="haskell.vim"
  lhask="lhaskell.vim"
  cp -r $source_dir/syntax $HOME/.vim/ 
fi

## reload bash
source $HOME/.bashrc

## tell user about installation/update of vim plugins
echo -e "\e[1m"
echo VIM will be opened now to install the plugins that are needed for HaskIDE
echo If there is an error when opening VIM, just press enter and continue.
echo "Once in VIM type ':PlugInstall' and press enter"
echo "If an error is displayed, press 'R' as displayed"
echo -e "To close vim afterwards [type :q! and press enter]x2\e[0m"
echo ""
read -p "Press any key to continue" 

## Open vim for post installation updates
vim -u $install_dir/vimrc

## tell user about further post installation procedures
echo ""
echo -e "\e[1;33m[INFO]: Dont forget to reload your bashrc with the command"
echo -e "source $HOME/.bashrc\e[0m"
echo ""
echo Everything done\; hack away \;\)

# ============= installation finished ================
