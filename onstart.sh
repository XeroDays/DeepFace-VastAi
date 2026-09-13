#!/bin/bash
# ============================================================
#  Vast.ai On-Start Script
#  Paste this into the "On-Start Script" field when renting
#  your Vast.ai instance. It runs automatically each time
#  the instance starts/restarts.
#
#  NOTE: This is SEPARATE from setup_deepfacelab.sh.
#  Run setup_deepfacelab.sh ONCE manually after first boot.
#  This script just re-activates the environment on restarts.
# ============================================================

# Activate Python venv in all new SSH sessions
if [ -f /workspace/dfl_env/bin/activate ]; then
    grep -q "source /workspace/dfl_env/bin/activate" /root/.bashrc 2>/dev/null || \
        echo "source /workspace/dfl_env/bin/activate" >> /root/.bashrc
elif [ -f /root/dfl_env/bin/activate ]; then
    grep -q "source /root/dfl_env/bin/activate" /root/.bashrc 2>/dev/null || \
        echo "source /root/dfl_env/bin/activate" >> /root/.bashrc
fi

# Ensure environment variables are set
grep -q "DeepFaceLab environment" /root/.bashrc 2>/dev/null || cat >> /root/.bashrc << 'EOF'

# DeepFaceLab environment
export TF_FORCE_GPU_ALLOW_GROWTH=true
export CUDA_VISIBLE_DEVICES=0
if [ -d "/workspace/DeepFaceLab" ]; then
    export DFL_ROOT="/workspace/DeepFaceLab/DeepFaceLab_Linux/"
    export DFL_SRC="/workspace/DeepFaceLab/DeepFaceLab_Linux/DeepFaceLab/"
else
    export DFL_ROOT="/root/DeepFaceLab/DeepFaceLab_Linux/"
    export DFL_SRC="/root/DeepFaceLab/DeepFaceLab_Linux/DeepFaceLab/"
fi
EOF

# Confirm GPU on startup
echo "=== GPU STATUS ===" >> /root/startup_log.txt
nvidia-smi >> /root/startup_log.txt 2>&1
date >> /root/startup_log.txt
