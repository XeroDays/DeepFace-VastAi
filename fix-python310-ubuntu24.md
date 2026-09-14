# Fix: TensorFlow 2.10.1 fails on Ubuntu 24.04 (Python 3.12)

> **Note:** `setup_deepfacelab.sh` now handles this automatically — it detects Python version, installs 3.10 via apt / deadsnakes / pyenv, and recreates the venv if needed. Use this file only if the script's fallbacks all fail.

Use this when `setup_deepfacelab.sh` fails with:

```text
Python: Python 3.12.x
ERROR: No matching distribution found for tensorflow==2.10.1
```

Or when `apt-get install python3.10` fails with:

```text
E: Unable to locate package python3.10-venv
```

---

## Why this happens

| Item | Your Vast.ai image | What DeepFaceLab needs |
|---|---|---|
| OS | Ubuntu 24.04 (Noble) | OK |
| System Python | 3.12 | **3.9 or 3.10** |
| TensorFlow | 2.10.1 | Only installs on Python ≤ 3.10 |
| Host CUDA | 12.x | OK (pip CUDA 11 libs are used inside venv) |

**Fix:** install Python 3.10 from deadsnakes, recreate the venv with 3.10, rerun setup.

---

## Full fix (copy-paste)

Run on the Vast.ai server:

```bash
# 1. Install Python 3.10 (Ubuntu 24.04 does not ship it by default)
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python3.10 python3.10-venv python3.10-dev python3.10-distutils

# 2. Confirm Python 3.10 is available
python3.10 --version

# 3. Remove old venv (created with Python 3.12)
rm -rf /workspace/dfl_env

# 4. Create venv with Python 3.10
python3.10 -m venv /workspace/dfl_env
source /workspace/dfl_env/bin/activate

# 5. Verify — MUST show 3.10.x
which python
python --version

# 6. Rerun setup
cd /workspace/DeepFace-VastAi
bash setup_deepfacelab.sh
```

---

## Quick checks

```bash
# Are you inside the venv?
echo $VIRTUAL_ENV

# Which python is being used?
which python
python --version

# Is TensorFlow installed and GPU visible?
source /workspace/dfl_env/bin/activate
python -c "import tensorflow as tf; print(tf.__version__); print(tf.config.list_physical_devices('GPU'))"
```

Expected after fix:

```text
/workspace/dfl_env/bin/python
Python 3.10.x
2.10.1
[PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
```

---

## Every new SSH session

Always activate the venv before running DeepFaceLab scripts:

```bash
source /workspace/dfl_env/bin/activate
cd /workspace/DeepFace-VastAi/DeepFaceLab_Linux/scripts
```

---

## If deadsnakes install fails

Try installing the full package:

```bash
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python3.10-full
python3.10 --version
```

---

## Alternative: pyenv (if PPA is blocked)

```bash
apt-get update
apt-get install -y build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev curl \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

curl https://pyenv.run | bash

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
pyenv install 3.10.14
pyenv global 3.10.14

python --version

rm -rf /workspace/dfl_env
python -m venv /workspace/dfl_env
source /workspace/dfl_env/bin/activate
cd /workspace/DeepFace-VastAi
bash setup_deepfacelab.sh
```

---

## Do NOT do this

- Do **not** upgrade TensorFlow to 2.16+ to match Python 3.12 — DeepFaceLab will likely break.
- Do **not** keep using `/workspace/dfl_env` if it was created with Python 3.12 — delete and recreate it.
- Do **not** assume host CUDA 12.x is the problem — the pip error is almost always Python version.

---

## One-liner summary

```bash
add-apt-repository -y ppa:deadsnakes/ppa && apt-get update && apt-get install -y python3.10 python3.10-venv python3.10-dev && rm -rf /workspace/dfl_env && python3.10 -m venv /workspace/dfl_env && source /workspace/dfl_env/bin/activate && python --version && cd /workspace/DeepFace-VastAi && bash setup_deepfacelab.sh
```
