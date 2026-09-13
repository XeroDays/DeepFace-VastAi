#!/usr/bin/env bash
source env.sh

EXTRA_ARGS=""
if [ -z "${DISPLAY:-}" ]; then
    EXTRA_ARGS="--no-preview"
fi

$DFL_PYTHON "$DFL_SRC/main.py" train \
    --training-data-src-dir "$DFL_WORKSPACE/data_src/aligned" \
    --training-data-dst-dir "$DFL_WORKSPACE/data_dst/aligned" \
    --pretraining-data-dir "$DFL_SRC/pretrain_CelebA" \
    --model-dir "$DFL_WORKSPACE/model" \
    --model SAEHD \
    $EXTRA_ARGS

