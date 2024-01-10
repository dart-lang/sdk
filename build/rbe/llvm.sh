#!/bin/sh
os=$(uname -s | tr '[A-Z]' '[a-z'])
arch=$(uname -m | tr '[A-Z]' '[a-z'] | sed -E 's/^x86_64$/x64/')
cp "../../buildtools/$os-$arch/clang/bin/llvm" "$1"
"$@"
