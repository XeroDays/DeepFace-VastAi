# DeepFaceLab 2.0 on Vast.ai — Complete Setup Guide

This repo bundles **DeepFaceLab Linux** (nagadit scripts + iperov core) with a Vast.ai setup script. Clone this repo on your GPU server, run one setup script, and start training — no conda required.

Based on the [DeepfakeVFX.com guide](https://www.deepfakevfx.com/guides/deepfacelab-2-0-guide/).

---

## Files in This Project

| File / Folder | Purpose |
|---|---|
| `DeepFaceLab_Linux/` | Linux wrapper scripts (from nagadit) |
| `DeepFaceLab_Linux/DeepFaceLab/` | Core DFL code (from iperov) |
| `setup_deepfacelab.sh` | **Run once** on the server — installs deps + Python venv |
| `onstart.sh` | Paste into Vast.ai "On-Start Script" field before renting |
| `README.md` | This guide |

---

## Step 1 — Push This Repo to GitHub

On your local machine:

```powershell
cd "D:\Projects\52. DeepFake"
git init
git add .
git commit -m "Initial DeepFaceLab 2.0 Linux + Vast.ai setup"
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin master
```

---

## Step 2 — Rent a GPU Instance on Vast.ai

1. Go to [vast.ai](https://vast.ai) and create an account.
2. Navigate to **Account → SSH Keys** and add your SSH public key.
3. Go to the **Search** page and filter for a GPU instance:
   | Setting | Recommended |
   |---|---|
   | GPU | RTX 3090, RTX 4090, A100, A6000 |
   | VRAM | ≥ 10 GB |
   | Disk | ≥ 50 GB |
   | Image | `vastai/pytorch` or `nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04` |
4. Before renting, paste the contents of `onstart.sh` into the **On-Start Script** field.
5. Click **Rent**.

---

## Step 3 — Clone & Setup on Vast.ai

SSH into the instance, then:

```bash
cd /workspace
git clone https://github.com/XeroDays/DeepFace-VastAi.git /workspace/DeepFaceLab
cd /workspace/DeepFaceLab
bash setup_deepfacelab.sh
```

This will:
- Detect your GPU and CUDA version
- Install system dependencies (FFmpeg, Git, etc.)
- Create a Python venv at `/workspace/dfl_env`
- Install TensorFlow 2.10.1 + all required packages
- Create the workspace folder structure
- Verify GPU access via TensorFlow

---

## Step 4 — Upload Your Videos
 
**Mac / Linux:**
```bash
# Source video (the face you want to use as the deepfake)
scp -P <PORT> "/path/to/source_face.mp4" root@<IP>:/workspace/DeepFaceLab/DeepFaceLab_Linux/workspace/data_src.mp4

# Destination video (the video you want to apply the deepfake to)
scp -P <PORT> "/path/to/destination_video.mp4" root@<IP>:/workspace/DeepFaceLab/DeepFaceLab_Linux/workspace/data_dst.mp4
```

**Windows (PowerShell):**
```powershell
# Source video (the face you want to use as the deepfake)
scp -P 12345 "C:\path\to\source_face.mp4" root@123.456.789.10:/workspace/DeepFaceLab/DeepFaceLab_Linux/workspace/data_src.mp4

# Destination video (the video you want to apply the deepfake to)
scp -P 12345 "C:\path\to\destination_video.mp4" root@123.456.789.10:/workspace/DeepFaceLab/DeepFaceLab_Linux/workspace/data_dst.mp4
```

---

## Step 5 — Run DeepFaceLab Scripts

```bash
source /workspace/dfl_env/bin/activate
cd /workspace/DeepFaceLab/DeepFaceLab_Linux/scripts
```

Run steps in order:

| Script | Purpose |
|---|---|
| `bash 1_clear_workspace.sh` | Clear workspace (optional) |
| `bash 2_extract_image_from_data_src.sh` | Extract frames from source video |
| `bash 3_extract_image_from_data_dst.sh` | Extract frames from destination video |
| `bash 4_data_src_extract_faces_S3FD.sh` | Detect & extract source faces |
| `bash 5_data_dst_extract_faces_S3FD.sh` | Detect & extract destination faces |
| `bash 6_train_SAEHD.sh` | **Train the deepfake model** |
| `bash 7_merge_SAEHD.sh` | Apply deepfake to destination frames |
| `bash 8_merged_to_mp4.sh` | Compile merged frames to video |

---

## Tip: Keep Training Running After Disconnect (tmux)

```bash
tmux new -s dfl
source /workspace/dfl_env/bin/activate
cd /workspace/DeepFaceLab/DeepFaceLab_Linux/scripts
bash 6_train_SAEHD.sh
# Detach: Ctrl+B then D
# Re-attach: tmux attach -t dfl
```

---

## Step 6 — Download Your Result

**Mac / Linux:**
```bash
scp -P <PORT> root@<IP>:/workspace/DeepFaceLab/DeepFaceLab_Linux/workspace/result.mp4 ~/Desktop/result.mp4
```

**Windows (PowerShell):**
```powershell
scp -P 12345 root@123.456.789.10:/workspace/DeepFaceLab/DeepFaceLab_Linux/workspace/result.mp4 "D:\Projects\52. DeepFake\result.mp4"
```

---

## Troubleshooting

**TensorFlow doesn't see the GPU:**
```bash
source /workspace/dfl_env/bin/activate
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

**Out of memory during training:** Reduce `batch_size` in the training menu.

**After instance restart:** SSH back in — `onstart.sh` auto-activates the venv via `.bashrc`.

---

## Resources

- [DeepfakeVFX Full Guide](https://www.deepfakevfx.com/guides/deepfacelab-2-0-guide/)
- [nagadit/DeepFaceLab_Linux](https://github.com/nagadit/DeepFaceLab_Linux)
- [iperov/DeepFaceLab](https://github.com/iperov/DeepFaceLab)
- [Vast.ai SSH Guide](https://docs.vast.ai/guides/instances/connect/ssh)
