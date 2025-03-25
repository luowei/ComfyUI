#!/bin/bash

# 当前脚本目录
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# echo "当前脚本目录: $SCRIPT_DIR"

# 如果当前目录存在 venv 虚拟目录，则激活虚拟环境
if [ -d $SCRIPT_DIR/venv ]; then
    source $SCRIPT_DIR/venv/bin/activate
fi

python $SCRIPT_DIR/main.py

