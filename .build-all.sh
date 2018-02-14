#!/bin/sh
set -ex

gccvers=(
    '4.9.4'
    '5.5.0'
    '6.4.0'
    '7.2.0'
)

targets=(
  'x86_64-linux-musl'
  'i486-linux-musl'
  'arm-linux-musleabi'
  'arm-linux-musleabihf'
  'aarch64-linux-musl'
)

make clean
bash .travis.yml.script x86_64-linux-musl 4.9.4

mkdir -p tools

tar xf dist/gcc-4.9.4-x86_64-linux-musl.tar.xz -C tools
rm dist/gcc-4.9.4-x86_64-linux-musl.tar.xz
make clean
rm log/*

for gccver in "${gccvers[@]}"; do
  for target in "${targets[@]}"; do
      PATH="$(pwd)/tools/bin:$PATH" bash .travis.yml.script "${target}" "${gccver}" 'COMMON_CONFIG += CC="x86_64-linux-musl-gcc -static --static" CXX="x86_64-linux-musl-g++ -static --static"'
  done
done

