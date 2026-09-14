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

REQUIRED_PY_MAJOR=3
REQUIRED_PY_MINOR_MAX=10
REQUIRED_PY_MINOR_MIN=9

# ── Helper functions ─────────────────────────────────────

log_step() {
    echo "" >&2
    echo "[$(date +%H:%M:%S)] $*" >&2
}

get_python_minor() {
    local py_bin="$1"
    "$py_bin" -c 'import sys; print(sys.version_info.minor)' 2>/dev/null
}

python_version_ok() {
    local py_bin="$1"
    local major minor
    major=$("$py_bin" -c 'import sys; print(sys.version_info.major)' 2>/dev/null) || return 1
    minor=$(get_python_minor "$py_bin") || return 1
    [ "$major" -eq "$REQUIRED_PY_MAJOR" ] && [ "$minor" -ge "$REQUIRED_PY_MINOR_MIN" ] && [ "$minor" -le "$REQUIRED_PY_MINOR_MAX" ]
}

find_compatible_python() {
    local candidate
    for candidate in python3.10 python3.9; do
        if command -v "$candidate" &>/dev/null && python_version_ok "$(command -v "$candidate")"; then
            command -v "$candidate"
            return 0
        fi
    done
    return 1
}

install_python310_apt() {
    log_step "Trying apt install for Python 3.10..."
    if apt-get install -y python3.10 python3.10-venv python3.10-dev >&2; then
        command -v python3.10
        return 0
    fi
    return 1
}

install_python310_deadsnakes() {
    log_step "Trying deadsnakes PPA for Python 3.10 (Ubuntu 24.04)..."
    apt-get install -y software-properties-common >&2
    add-apt-repository -y ppa:deadsnakes/ppa >&2
    apt-get update >&2
    if apt-get install -y python3.10 python3.10-venv python3.10-dev python3.10-distutils >&2; then
        command -v python3.10
        return 0
    fi
    if apt-get install -y python3.10-full >&2; then
        command -v python3.10
        return 0
    fi
    return 1
}

install_python310_pyenv() {
    log_step "Trying pyenv fallback for Python 3.10.14 (this may take several minutes)..."
    apt-get install -y build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev curl \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev >&2

    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    export PATH="$PYENV_ROOT/bin:$PATH"

    if [ ! -d "$PYENV_ROOT" ]; then
        curl -fsSL https://pyenv.run | bash >&2
    fi

    # shellcheck disable=SC1091
    eval "$(pyenv init -)" >&2
    pyenv install -s 3.10.14 >&2
    echo "$PYENV_ROOT/versions/3.10.14/bin/python"
}

ensure_compatible_python() {
    local py_bin
    if py_bin="$(find_compatible_python)"; then
        log_step "Compatible Python found: $py_bin ($($py_bin --version))"
        echo "$py_bin"
        return 0
    fi

    log_step "Compatible Python not found. Installing Python 3.10..."
    if py_bin="$(install_python310_apt)" && python_version_ok "$py_bin"; then
        log_step "Python installed via apt: $py_bin"
        echo "$py_bin"
        return 0
    fi

    if py_bin="$(install_python310_deadsnakes)" && python_version_ok "$py_bin"; then
        log_step "Python installed via deadsnakes: $py_bin"
        echo "$py_bin"
        return 0
    fi

    if py_bin="$(install_python310_pyenv)" && python_version_ok "$py_bin"; then
        log_step "Python installed via pyenv: $py_bin"
        echo "$py_bin"
        return 0
    fi

    echo "ERROR: Could not install Python 3.9 or 3.10. TensorFlow 2.10.1 requires Python <= 3.10." >&2
    echo "See fix-python310-ubuntu24.md for manual steps." >&2
    exit 1
}

venv_python_ok() {
    [ -x "$VENV_PATH/bin/python" ] && python_version_ok "$VENV_PATH/bin/python"
}

create_or_recreate_venv() {
    local python_bin="$1"
    if [ -d "$VENV_PATH" ]; then
        if venv_python_ok; then
            log_step "Existing venv at $VENV_PATH is compatible, reusing."
            return 0
        fi
        log_step "Existing venv has incompatible Python — removing and recreating."
        rm -rf "$VENV_PATH"
    fi
    log_step "Creating virtual environment at $VENV_PATH..."
    "$python_bin" -m venv "$VENV_PATH"
    log_step "Virtual environment created."
}

pip_install_batch() {
    local label="$1"
    shift
    log_step "Installing: $label"
    echo "    Packages: $*"
    PIP_PROGRESS_BAR=on "$VENV_PATH/bin/pip" install "$@" || {
        echo "ERROR: Failed to install: $label" >&2
        exit 1
    }
    log_step "Done: $label"
}

pip_install_batch_if_missing() {
    local check_cmd="$1"
    local label="$2"
    shift 2
    if "$VENV_PATH/bin/python" -c "$check_cmd" 2>/dev/null; then
        log_step "$label already installed, skipping..."
    else
        pip_install_batch "$label" "$@"
    fi
}

# ── Main setup ───────────────────────────────────────────

echo "======================================================"
echo " DeepFaceLab 2.0 – Vast.ai Setup"
echo "======================================================"

# ── 1. Detect GPU & CUDA ─────────────────────────────────
echo ""
echo "[1/7] Detecting GPU & CUDA..."
nvidia-smi || { echo "ERROR: No NVIDIA GPU found. Make sure your Vast.ai instance has a GPU."; exit 1; }

CUDA_VER=$(nvcc --version 2>/dev/null | grep "release" | awk '{print $6}' | cut -c2-) || true
echo "    CUDA version detected: ${CUDA_VER:-unknown}"

# ── 2. System dependencies ───────────────────────────────
echo ""
echo "[2/7] Installing system dependencies..."
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
    software-properties-common \
    tmux \
    htop \
    ncdu

echo "    System dependencies installed."

# ── 3. Ensure compatible Python & create venv ────────────
echo ""
echo "[3/7] Ensuring compatible Python and creating virtual environment..."
PYTHON_BIN="$(ensure_compatible_python)"
create_or_recreate_venv "$PYTHON_BIN"
source "$VENV_PATH/bin/activate"
echo "    Python: $($VENV_PATH/bin/python --version)"

# ── 4. Install Python packages ───────────────────────────
echo ""
echo "[4/7] Installing Python packages..."

pip_install_batch "pip / setuptools / wheel" --upgrade pip setuptools wheel

pip_install_batch_if_missing \
    "import tensorflow; assert tensorflow.__version__.startswith('2.10')" \
    "TensorFlow 2.10.1 (this may take 5-10 minutes)" \
    tensorflow==2.10.1

pip_install_batch_if_missing \
    "import numpy, cv2, scipy, skimage" \
    "Core dependencies" \
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
    tf2onnx

pip_install_batch_if_missing \
    "import nvidia.cudnn" \
    "NVIDIA CUDA libraries (this may take several minutes)" \
    nvidia-cuda-runtime-cu11 \
    nvidia-cudnn-cu11==8.6.0.163 \
    nvidia-cublas-cu11 \
    nvidia-cufft-cu11 \
    nvidia-curand-cu11 \
    nvidia-cusolver-cu11 \
    nvidia-cusparse-cu11

log_step "Installing: Protobuf fix"
echo "    Packages: protobuf<3.20,>=3.9.2 flatbuffers>=2.0"
PIP_PROGRESS_BAR=on "$VENV_PATH/bin/pip" install --force-reinstall "protobuf<3.20,>=3.9.2" "flatbuffers>=2.0" || {
    echo "ERROR: Failed to install: Protobuf fix" >&2
    exit 1
}
log_step "Done: Protobuf fix"

echo "    Python packages installed."

# ── 5. Create workspace structure ────────────────────────
echo ""
echo "[5/7] Creating workspace folder structure..."

mkdir -p \
    "$WORKSPACE/data_src/aligned" \
    "$WORKSPACE/data_src/aligned_debug" \
    "$WORKSPACE/data_dst/aligned" \
    "$WORKSPACE/data_dst/aligned_debug" \
    "$WORKSPACE/model"

echo "    Workspace created at: $WORKSPACE"

# ── 6. Download pre-trained face models if missing ───────
echo ""
echo "[6/7] Downloading pre-trained face models (if missing)..."

FACELIB_DIR="$DFL_BASE/DeepFaceLab_Linux/DeepFaceLab/facelib"
mkdir -p "$FACELIB_DIR"

if [ ! -f "$FACELIB_DIR/S3FD.npy" ]; then
    log_step "Downloading S3FD.npy (Face detector model ~89MB)..."
    curl -L --progress-bar --retry 3 "https://github.com/iperov/DeepFaceLab/raw/master/facelib/S3FD.npy" -o "$FACELIB_DIR/S3FD.npy"
    log_step "Done: S3FD.npy"
fi

if [ ! -f "$FACELIB_DIR/2DFAN.npy" ]; then
    log_step "Downloading 2DFAN.npy (Face landmarks model ~95MB)..."
    curl -L --progress-bar --retry 3 "https://github.com/iperov/DeepFaceLab/raw/master/facelib/2DFAN.npy" -o "$FACELIB_DIR/2DFAN.npy"
    log_step "Done: 2DFAN.npy"
fi

if [ ! -f "$FACELIB_DIR/FaceEnhancer.npy" ]; then
    log_step "Downloading FaceEnhancer.npy (Face enhancer model ~66MB)..."
    curl -L --progress-bar --retry 3 "https://github.com/iperov/DeepFaceLab/raw/master/facelib/FaceEnhancer.npy" -o "$FACELIB_DIR/FaceEnhancer.npy"
    log_step "Done: FaceEnhancer.npy"
fi

# ── 7. Configure CUDA Library Paths & Verify GPU ─────────
echo ""
echo "[7/7] Verifying GPU access via TensorFlow..."
echo "======================================================"

VENV_CUDA_PATHS=$("$VENV_PATH/bin/python" -c "import site, glob; print(':'.join(glob.glob(site.getsitepackages()[0] + '/nvidia/*/lib')))" 2>/dev/null)
CUDA_PATHS="/usr/local/cuda/lib64:/usr/local/cuda-11.8/lib64:/usr/local/cuda-11/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64"

export LD_LIBRARY_PATH="${VENV_CUDA_PATHS}:${CUDA_PATHS}:${LD_LIBRARY_PATH:-}"

if [ -f "$VENV_PATH/bin/activate" ]; then
    grep -q "DeepFaceLab CUDA paths" "$VENV_PATH/bin/activate" 2>/dev/null || cat >> "$VENV_PATH/bin/activate" << 'EOF'

# DeepFaceLab CUDA paths & thread limits
_NV_LIBS=$(python -c "import site, glob; print(':'.join(glob.glob(site.getsitepackages()[0] + '/nvidia/*/lib')))" 2>/dev/null)
export LD_LIBRARY_PATH="${_NV_LIBS}:/usr/local/cuda/lib64:/usr/local/cuda-11.8/lib64:/usr/local/cuda-11/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH:-}"
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
ulimit -u 65535 2>/dev/null || true
ulimit -n 65535 2>/dev/null || true
EOF
fi

grep -q "DeepFaceLab CUDA paths" /root/.bashrc 2>/dev/null || cat >> /root/.bashrc << 'EOF'

# DeepFaceLab CUDA paths & thread limits
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda-11.8/lib64:/usr/local/cuda-11/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH:-}"
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export VECLIB_MAXIMUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
ulimit -u 65535 2>/dev/null || true
ulimit -n 65535 2>/dev/null || true
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
