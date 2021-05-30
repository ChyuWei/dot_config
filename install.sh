#!/bin/sh

GIT_URL="https://hub.fastgit.org"
GIT_RAW_URL="https://raw.fastgit.org"


check_already() {
    ck_file=$1
    src_file=$2

    # check already done
    if [ -L $ck_file ]
    then 
        if [ $(readlink $ck_file) = $src_file ]
        then 
            return 1
        fi
    fi
    return 0
}

backup_file() {
    bk_file=$1
    bk_alias=$2

    # backup config file
    if [ -f $bk_file ]
    then 
        echo "Making $bk_alias backup"
        mv $bk_file ${bk_file}.bak
    fi
}

backup_dir() {
    bk_dir=$1
    bk_alias=$2

    if [ -d $bk_dir ] 
    then 
        echo "Making $bk_alias backup"
        mv $bk_dir ${bk_dir}.bak
    fi
}


install_vim() {
    echo "install vim"

    VIMRC_PATH="$HOME/.vimrc"
    VIMDIR_PATH="$HOME/.vim"
    VIM_SRC="$(pwd)/vimrc"

    check_already $VIMRC_PATH $VIM_SRC
    if [ $? -eq 1 ]
    then 
        echo "already install"
        return
    fi

    backup_file $VIMRC_PATH ".vimrc"
    backup_dir $VIMDIR_PATH ".vim"

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
