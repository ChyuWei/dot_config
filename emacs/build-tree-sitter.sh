#!/bin/sh
# Build the tree-sitter grammars `markdown-ts-mode' needs into
# var/treesit/ beside this script: markdown, markdown-inline (one repo, two
# src dirs) and python (for highlighting fenced python code).
#
# Emacs 31's built-in installer fails on the two-language markdown
# repository (it looks for parser.c in the wrong directory), so the
# compile is done by hand here, exactly like `treesit-install-language-grammar'
# would do for a single-language repository.
set -e

CONFIG_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
TS="$CONFIG_DIR/var/treesit"
mkdir -p "$TS"

build () {
  lang="$1"; repo="$2"; dir="$3"
  echo "== $lang"
  rm -rf "/tmp/ts-build-$lang"
  git clone --depth 1 "$repo" "/tmp/ts-build-$lang" >/dev/null
  cd "/tmp/ts-build-$lang/$dir/src"
  cc -O2 -fPIC -I. -c parser.c -o parser.c.o
  cc -O2 -fPIC -I. -c scanner.c -o scanner.c.o
  cc -bundle -o "$TS/libtree-sitter-$lang.so" parser.c.o scanner.c.o
}

build markdown "https://github.com/tree-sitter-grammars/tree-sitter-markdown" tree-sitter-markdown
build markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" tree-sitter-markdown-inline
build python "https://github.com/tree-sitter/tree-sitter-python" .

echo "done: $TS"
