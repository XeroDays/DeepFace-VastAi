#!/usr/bin/env bash
# Activate Python venv (checks /workspace/dfl_env first, then /root/dfl_env)
if [ -f "/workspace/dfl_env/bin/activate" ]; then
    source /workspace/dfl_env/bin/activate
    export DFL_PYTHON="/workspace/dfl_env/bin/python"
elif [ -f "/root/dfl_env/bin/activate" ]; then
    source /root/dfl_env/bin/activate
    export DFL_PYTHON="/root/dfl_env/bin/python"
fi

# Ensure CUDA libraries are in LD_LIBRARY_PATH
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-11.8/lib64:/usr/local/cuda-11/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH:-}"
if [ -n "${VIRTUAL_ENV:-}" ]; then
    for _d in "$VIRTUAL_ENV"/lib/python*/site-packages/nvidia/*/lib; do
        [ -d "$_d" ] && export LD_LIBRARY_PATH="$_d:$LD_LIBRARY_PATH"
    done
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
