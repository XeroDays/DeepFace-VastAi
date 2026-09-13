#!/usr/bin/env bash
# Activate Python venv (checks /workspace/dfl_env first, then /root/dfl_env)
if [ -f "/workspace/dfl_env/bin/activate" ]; then
    source /workspace/dfl_env/bin/activate
    export DFL_PYTHON="/workspace/dfl_env/bin/python"
elif [ -f "/root/dfl_env/bin/activate" ]; then
    source /root/dfl_env/bin/activate
    export DFL_PYTHON="/root/dfl_env/bin/python"
fi
cd ..
export DFL_WORKSPACE="workspace/"

if [ ! -d "$DFL_WORKSPACE" ]; then
    mkdir "$DFL_WORKSPACE"
    mkdir "$DFL_WORKSPACE/data_src"
    mkdir "$DFL_WORKSPACE/data_src/aligned"
    mkdir "$DFL_WORKSPACE/data_src/aligned_debug"
    mkdir "$DFL_WORKSPACE/data_dst"
    mkdir "$DFL_WORKSPACE/data_dst/aligned"
    mkdir "$DFL_WORKSPACE/data_dst/aligned_debug"
    mkdir "$DFL_WORKSPACE/model"
fi

export DFL_ROOT="./"
export DFL_SRC="./DeepFaceLab"
