# DeepFaceLab 2.0 – Vast.ai Complete Workflow Guide

A complete, battle-tested guide to run **DeepFaceLab 2.0** on a cloud **Vast.ai** GPU instance from start to finish.

> [!NOTE]
> All server commands assume you are in the `/workspace` directory after SSH login (default on Vast.ai).

---

## 0. Renting an Instance on Vast.ai

1. Go to [Vast.ai](https://cloud.vast.ai/create/).
2. Choose an instance with:
   * **GPU:** RTX 3090, RTX 4090, A5000, A6000, or A100 (at least 12–24 GB VRAM recommended).
   * **Disk Size:** At least **50 GB** (disk allocated to `/workspace`).
   * **Template / Image:** Default `vastai/base` or `pytorch/pytorch` or any Ubuntu 20.04/22.04 image.
3. Once the instance is running, copy the SSH command from the instance card:
   `ssh -p <PORT> root@<IP>`

---

## Step 1: Clone Repo & Run Auto-Setup (Once Per Instance)

SSH into your Vast.ai instance and run:

```bash
cd /workspace
git clone https://github.com/XeroDays/DeepFace-VastAi.git
cd DeepFace-VastAi/
bash setup_deepfacelab.sh
```

### What this setup script does automatically:
* Installs all system dependencies (`ffmpeg`, `git`, `tmux`, etc.).
* Creates a persistent Python 3.10 virtual environment at `/workspace/dfl_env`.
* Installs **TensorFlow 2.10.1** and the complete CUDA 11 runtime (`cublas`, `cudnn`, `cufft`, `cusparse`, `cusolver`, `curand`).
* Strictly pins **protobuf < 3.20** and **flatbuffers >= 2.0** to eliminate dependency conflicts.
* Automatically downloads the required pre-trained neural models (**`S3FD.npy`** ~89MB, **`2DFAN.npy`** ~95MB, and **`FaceEnhancer.npy`** ~66MB) into `facelib/`.
* Pre-configures `LD_LIBRARY_PATH` inside your `.bashrc` and venv activation script.
* Verifies TensorFlow recognizes your GPU before finishing.

---

## Step 2: Activate Python Environment & Navigate to Scripts

```bash
source /workspace/dfl_env/bin/activate
cd /workspace/DeepFace-VastAi/DeepFaceLab_Linux/scripts
```

*(You can verify your GPU anytime with:)*
```bash
python -c "import tensorflow as tf; print('GPUs detected:', tf.config.list_physical_devices('GPU'))"
```

---

## Step 3: Upload Videos (Run from your LOCAL machine)

Open a terminal on your **local machine** (Mac or PC) to transfer your input videos:

| Video | Description | Server Path |
|---|---|---|
| **Source** (`data_src.mp4`) | The face you want to use (donor) | `/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/data_src.mp4` |
| **Destination** (`data_dst.mp4`) | The target video where face is replaced | `/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/data_dst.mp4` |

**From Mac / Linux Terminal:**
```bash
# Upload Source video
scp -P <PORT> "/path/to/your/source.mp4" root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/data_src.mp4

# Upload Destination video
scp -P <PORT> "/path/to/your/destination.mp4" root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/data_dst.mp4
```

**From Windows PowerShell:**
```powershell
scp -P <PORT> "C:\path\to\source.mp4" root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/data_src.mp4
scp -P <PORT> "C:\path\to\destination.mp4" root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/data_dst.mp4
```

---

## Step 4: Clear Workspace (Optional – only if resetting)

```bash
bash 1_clear_workspace.sh
```

---

## Step 5: Extract Frames from Videos

Extract raw image frames from both videos:

```bash
# Extract frames from source video (press Enter to accept default FPS)
bash 2_extract_image_from_data_src.sh

# Extract frames from destination video (press Enter to accept default full FPS)
bash 3_extract_image_from_data_dst.sh
```

---

## Step 6: Extract Faces from Frames (GPU Accelerated)

Detect and crop faces using the S3FD GPU neural network:

```bash
# Extract faces from data_src (choose 'wf' for whole face or 'f' for full face)
bash 4_data_src_extract_faces_S3FD.sh

# Extract faces from data_dst
bash 5_data_dst_extract_faces_S3FD.sh
```
> [!TIP]
> Press **Enter** on prompts to accept recommended defaults (`wf`, 512 image size, 90 quality). It will automatically run on your GPU.

---

## Step 7: Sort & Clean Facesets (Recommended)

Sort faces so you can discard blurs, non-face objects, or wrong faces:

```bash
# Sort source faces by best alignment/histogram
bash 4.2_data_src_sort.sh

# Sort destination faces
bash 5.2_data_dst_sort.sh
```

---

## Step 8: Train the Model (Use tmux)

Training takes several hours to overnight. Always run inside `tmux` so it doesn't stop if your SSH disconnects:

```bash
# 1. Start a new tmux session
tmux new -s dfl

# 2. Inside tmux, activate environment and start training
source /workspace/dfl_env/bin/activate
cd /workspace/DeepFace-VastAi/DeepFaceLab_Linux/scripts
bash 6_train_SAEHD.sh
```

### Essential tmux & Training Shortcuts:
* **Detach from tmux (keep training in background):** Press **<kbd>Ctrl</kbd> + <kbd>B</kbd>**, release, then press **<kbd>D</kbd>**.
* **Re-attach to tmux anytime:** `tmux attach -t dfl`
* **Save model & exit training cleanly:** Press **<kbd>Enter</kbd>** in the training window.
* **Save model without exiting:** Press **<kbd>S</kbd>**.

---

## Step 9: Merge Deepfake onto Destination Frames

Once training loss has flattened and preview looks sharp:

```bash
bash 7_merge_SAEHD.sh
```
*(Follow the interactive merger prompts or use overlay mode).*

---

## Step 10: Export Result to Video

Convert the merged frames into the final output video:

```bash
bash 8_merged_to_mp4.sh
```
The output will be created at `/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/result.mp4`.

---

## Step 11: Download Result to Your Local Machine

Run this on your **local machine** (Mac or PC) terminal:

**On Mac / Linux:**
```bash
scp -P <PORT> root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/result.mp4 ~/Desktop/result.mp4
```

**On Windows PowerShell:**
```powershell
scp -P <PORT> root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/result.mp4 "C:\Users\<Username>\Desktop\result.mp4"
```

---

## Quick Troubleshooting Reference

* **TensorFlow GPU check:**
  ```bash
  python -c "import tensorflow as tf; print('GPUs:', tf.config.list_physical_devices('GPU'))"
  ```
* **Missing library or CUDA path warning:**
  ```bash
  export LD_LIBRARY_PATH=$(python -c "import site, glob; print(':'.join(glob.glob(site.getsitepackages()[0] + '/nvidia/*/lib')))"):$LD_LIBRARY_PATH
  ```
* **If instance was stopped/started:**
  Because everything is installed in `/workspace`, your files, environment, and trained models are preserved across restarts. Simply run:
  ```bash
  source /workspace/dfl_env/bin/activate
  cd /workspace/DeepFace-VastAi/DeepFaceLab_Linux/scripts
  ```
