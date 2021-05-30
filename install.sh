#!/bin/sh

GIT_URL="https://hub.fastgit.org"
GIT_RAW_URL="https://raw.fastgit.org"

VIMRC_PATH="$HOME/.vimrc"
VIMDIR_PATH="$HOME/.vim"

VIM_SRC="$(pwd)/vimrc"

check_vim() {
    # check already done
    if [ -L $VIMRC_PATH ]
    then 
        if [ $(readlink $VIMRC_PATH) = $VIM_SRC ]
        then 
            return 1
        fi
    fi
    return 0
}

backup_vim() {
    # backup config file
    if [ -f $VIMRC_PATH ]
    then 
        echo "Making .vimrc backup"
        mv $VIMRC_PATH ${VIMRC_PATH}.bak
    fi

    if [ -d $VIMDIR_PATH ] 
    then 
        echo "Making .vim backup"
        mv $VIMDIR_PATH ${VIMDIR_PATH}.bak
    fi
}


install_vim() {
    echo "install vim"

    check_vim
    if [ $? -eq 1 ]
    then 
        echo "already install"
        return
    fi

    backup_vim

    echo -e "\tinstall .vimrc"
    ln -s $VIM_SRC $VIMRC_PATH
    echo -e "\tinstall .vim"
    _vim_plug=$GIT_RAW_URL/junegunn/vim-plug/master/plug.vim
    curl -sfLo $VIMDIR_PATH/autoload/plug.vim --create-dirs $_vim_plug
    echo "done"
}

install_all() {
    echo "install all"
    echo "####################"
    install_vim
    echo "####################"
    echo "done"

}

main() {
    if [ $# -lt 1 ]
    then
        echo "need one arg"
    fi

    case $1 in 
    "all") 
        install_all
        ;;
    "vim")
        install_vim
        ;;
    esac
}

main $@
