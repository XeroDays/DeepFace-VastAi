#!/usr/bin/env bash
# No conda — use Python venv at /root/dfl_env
source /root/dfl_env/bin/activate
cd ..
export DFL_PYTHON="/root/dfl_env/bin/python"
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
