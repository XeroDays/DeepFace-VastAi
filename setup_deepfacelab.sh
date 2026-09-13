#!/bin/bash
# ============================================================
#  DeepFaceLab 2.0 – Vast.ai Auto-Setup Script
#  Run this ONCE on a fresh Vast.ai instance via SSH:
#    git clone <your-repo> /root/DeepFaceLab
#    cd /root/DeepFaceLab
#    bash setup_deepfacelab.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DFL_BASE="$SCRIPT_DIR"
if [ -d "/workspace" ]; then
    VENV_PATH="/workspace/dfl_env"
else
    VENV_PATH="/root/dfl_env"
fi
WORKSPACE="$DFL_BASE/DeepFaceLab_Linux/workspace"
REQUIREMENTS="$DFL_BASE/DeepFaceLab_Linux/DeepFaceLab/requirements-cuda.txt"

echo "======================================================"
echo " DeepFaceLab 2.0 – Vast.ai Setup"
echo "======================================================"

# ── 1. Detect GPU & CUDA ─────────────────────────────────
echo ""
echo "[1/6] Detecting GPU & CUDA..."
nvidia-smi || { echo "ERROR: No NVIDIA GPU found. Make sure your Vast.ai instance has a GPU."; exit 1; }

CUDA_VER=$(nvcc --version 2>/dev/null | grep "release" | awk '{print $6}' | cut -c2-) || true
echo "    CUDA version detected: ${CUDA_VER:-unknown}"

# ── 2. System dependencies ───────────────────────────────
echo ""
echo "[2/6] Installing system dependencies..."
apt-get update -qq
apt-get install -y -qq \
    git \
    wget \
    curl \
    ffmpeg \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    python3 \
    python3-pip \
    python3-venv \
    tmux \
    htop \
    ncdu

echo "    System dependencies installed."

# ── 3. Create Python venv ────────────────────────────────
echo ""
echo "[3/6] Creating Python virtual environment at $VENV_PATH..."

if [ -d "$VENV_PATH" ]; then
    echo "    Existing venv found, reusing it."
else
    python3 -m venv "$VENV_PATH"
    echo "    Virtual environment created."
fi

source "$VENV_PATH/bin/activate"
pip install --quiet --upgrade pip setuptools wheel

echo "    Python: $($VENV_PATH/bin/python --version)"

# ── 4. Install Python packages ───────────────────────────
echo ""
echo "[4/6] Installing Python packages..."

# TensorFlow 2.10.1 (last version with native GPU support, works on CUDA 11.2+)
pip install --quiet tensorflow==2.10.1

# Protobuf must be <= 3.20.3 for TensorFlow 2.10 (fixes "Descriptors cannot be created directly")
pip install --quiet "protobuf<=3.20.3"

# Install compatible versions for Python 3.10
pip install --quiet \
    numpy==1.23.5 \
    opencv-python==4.7.0.72 \
    ffmpeg-python==0.2.0 \
    scikit-image==0.19.3 \
    scipy==1.9.3 \
    h5py==3.7.0 \
    colorama==0.4.6 \
    pyqt5==5.15.9 \
    tqdm \
    Pillow \
    psutil \
    numexpr \
    tf2onnx==1.9.3

# Install CUDA 11 runtime libraries in venv (ensures libcudart.so.11.0 & libcudnn.so.8 are available)
pip install --quiet nvidia-cuda-runtime-cu11 nvidia-cudnn-cu11

echo "    Python packages installed."

# ── 5. Create workspace structure ────────────────────────
echo ""
echo "[5/6] Creating workspace folder structure..."

mkdir -p \
    "$WORKSPACE/data_src/aligned" \
    "$WORKSPACE/data_src/aligned_debug" \
    "$WORKSPACE/data_dst/aligned" \
    "$WORKSPACE/data_dst/aligned_debug" \
    "$WORKSPACE/model"

echo "    Workspace created at: $WORKSPACE"

# ── 6. Configure CUDA Library Paths & Verify GPU ─────────
echo ""
echo "[6/6] Verifying GPU access via TensorFlow..."
echo "======================================================"

# Build comprehensive LD_LIBRARY_PATH
CUDA_PATHS="/usr/local/cuda/lib64:/usr/local/cuda-11.8/lib64:/usr/local/cuda-11/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64"
NVIDIA_VENV_PATH="$VENV_PATH/lib/python3.10/site-packages/nvidia"
VENV_CUDA_PATHS=""
if [ -d "$NVIDIA_VENV_PATH" ]; then
    for p in "$NVIDIA_VENV_PATH"/*/lib; do
        if [ -d "$p" ]; then
            VENV_CUDA_PATHS="$p:$VENV_CUDA_PATHS"
        fi
    done
fi

export LD_LIBRARY_PATH="${VENV_CUDA_PATHS}${CUDA_PATHS}:${LD_LIBRARY_PATH:-}"

# Persist LD_LIBRARY_PATH into venv activate script
if [ -f "$VENV_PATH/bin/activate" ]; then
    grep -q "DeepFaceLab CUDA paths" "$VENV_PATH/bin/activate" 2>/dev/null || cat >> "$VENV_PATH/bin/activate" << 'EOF'

# DeepFaceLab CUDA paths
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-11.8/lib64:/usr/local/cuda-11/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH:-}"
if [ -d "$VIRTUAL_ENV/lib/python3.10/site-packages/nvidia" ]; then
    for _d in "$VIRTUAL_ENV/lib/python3.10/site-packages/nvidia"/*/lib; do
        [ -d "$_d" ] && export LD_LIBRARY_PATH="$_d:$LD_LIBRARY_PATH"
    done
fi
EOF
fi

# Persist LD_LIBRARY_PATH into /root/.bashrc
grep -q "DeepFaceLab CUDA paths" /root/.bashrc 2>/dev/null || cat >> /root/.bashrc << 'EOF'

# DeepFaceLab CUDA paths
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-11.8/lib64:/usr/local/cuda-11/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH:-}"
EOF

"$VENV_PATH/bin/python" -c "
import tensorflow as tf
gpus = tf.config.list_physical_devices('GPU')
print(f'TensorFlow version: {tf.__version__}')
if gpus:
    print(f'GPU(s) detected: {len(gpus)}')
    for g in gpus:
        print(f'  - {g}')
else:
    print('WARNING: No GPU detected by TensorFlow!')
    print('Check CUDA version compatibility.')
"

# ── Print summary ────────────────────────────────────────
echo ""
echo "======================================================"
echo " SETUP COMPLETE!"
echo "======================================================"
echo ""
echo "  Repo:       $DFL_BASE"
echo "  Workspace:  $WORKSPACE"
echo "  Scripts:    $DFL_BASE/DeepFaceLab_Linux/scripts/"
echo "  Python:     $VENV_PATH/bin/python"
echo ""
echo "  Next steps:"
echo "  1. Activate the environment:"
echo "       source $VENV_PATH/bin/activate"
echo "  2. Go to the scripts directory:"
echo "       cd $DFL_BASE/DeepFaceLab_Linux/scripts"
echo "  3. Upload your source/destination videos:"
echo "       scp -P <PORT> data_src.mp4 root@<IP>:$WORKSPACE/data_src.mp4"
echo "       scp -P <PORT> data_dst.mp4 root@<IP>:$WORKSPACE/data_dst.mp4"
echo "  4. Run scripts in order:"
echo "       bash 2_extract_image_from_data_src.sh"
echo "       bash 3_extract_image_from_data_dst.sh"
echo "       bash 4_data_src_extract_faces_S3FD.sh"
echo "       bash 5_data_dst_extract_faces_S3FD.sh"
echo "       bash 6_train_SAEHD.sh"
echo "       ...etc"
echo ""
echo "  TIP: Use 'tmux' to keep training running after SSH disconnect:"
echo "       tmux new -s dfl"
echo "       (inside tmux) bash 6_train_SAEHD.sh"
echo "       (detach with) Ctrl+B then D"
echo ""
