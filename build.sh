#!/bin/sh

set -e # Exit on error

cmake -S . -B build -G Ninja
cmake --build build --verbose
