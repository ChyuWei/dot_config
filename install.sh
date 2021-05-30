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

    SRC_PATH="$(pwd)/vimrc"
    DST_PATH="${HOME}/.vimrc"
    DST_DIR_PATH="${HOME}/.vim"

    check_already $DST_PATH $SRC_PATH
    if [ $? -eq 1 ]
    then 
        echo "already install"
        return
    fi

    backup_file $DST_PATH ".vimrc"
    backup_dir $DST_DIR_PATH ".vim"

    echo -e "\tinstall .vimrc"
    ln -s $SRC_PATH $DST_PATH
    echo -e "\tinstall .vim"
    _vim_plug=$GIT_RAW_URL/junegunn/vim-plug/master/plug.vim
    curl -sfLo $VIMDIR_PATH/autoload/plug.vim --create-dirs $_vim_plug
    echo "done"
}

install_emacs() {
    echo "install emacs"

    SRC_PATH="$(pwd)/emacs.d"
    DST_PATH="${HOME}/.emacs.d"

    check_already $DST_PATH $SRC_PATH
    if [ $? -eq 1 ]
    then 
        echo "already install"
        return
    fi

    backup_dir $DST_PATH ".emacs.d"

    echo -e "\tinstall .emacs.d"
    ln -s $SRC_PATH $DST_PATH
    echo "done"
}

install_all() {
    echo "install all"
    echo "####################"
    install_vim
    echo "####################"
    install_emacs
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
    "emacs")
        install_emacs
        ;;
    esac
}

main $@
