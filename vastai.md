# DeepFaceLab 2.0 – Vast.ai Complete Workflow Guide

A complete guide to run **DeepFaceLab 2.0** on a cloud **Vast.ai** GPU instance from start to finish.

> [!NOTE]
> All server commands assume you are in the `/workspace` directory after SSH login.

---

## 0. Renting an Instance on Vast.ai

1. Go to [Vast.ai](https://cloud.vast.ai/create/).
2. Filter & choose an instance with:
   * **GPU:** RTX 3090, RTX 4090, A5000, A6000, or A100 (12–24 GB VRAM)
   * **Disk Size:** At least **50 GB**
   * **Template / Image:** Default `vastai/base` or `pytorch/pytorch` or any Ubuntu 20.04/22.04 image
3. Copy the SSH command from your instance card:
   `ssh -p <PORT> root@<IP>`

---

## Step 1: Clone Repo & Run Setup (Once per instance)

```bash
cd /workspace
git clone https://github.com/XeroDays/DeepFace-VastAi.git
cd DeepFace-VastAi/
bash setup_deepfacelab.sh
```

The setup script auto-installs Python 3.10 if needed (Ubuntu 24.04 ships 3.12) and shows progress during pip installs.

---

## Step 2: Activate Python Environment & Navigate to Scripts

```bash
source /workspace/dfl_env/bin/activate
cd /workspace/DeepFace-VastAi/DeepFaceLab_Linux/scripts
```

Verify GPU anytime:
```bash
python -c "import tensorflow as tf; print('GPUs detected:', tf.config.list_physical_devices('GPU'))"
```

---

## Step 3: Upload Videos (Run from your LOCAL machine)

| Video | Description | Server Path |
|---|---|---|
| **Source** (`data_src.mp4`) | Face to use as the deepfake | `/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/data_src.mp4` |
| **Destination** (`data_dst.mp4`) | Video to swap face into | `/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/data_dst.mp4` |

**Mac / Linux Terminal:**
```bash
scp -P <PORT> "/path/to/source.mp4" root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/data_src.mp4
scp -P <PORT> "/path/to/destination.mp4" root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/data_dst.mp4
```

**Windows PowerShell:**
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

```bash
bash 2_extract_image_from_data_src.sh
bash 3_extract_image_from_data_dst.sh
```

---

## Step 6: Extract Faces from Frames (GPU Accelerated)

```bash
bash 4_data_src_extract_faces_S3FD.sh
bash 5_data_dst_extract_faces_S3FD.sh
```

> [!TIP]
> Press **Enter** on prompts to accept recommended defaults (`wf`, 512, 90).

---

## Step 7: Sort & Clean Facesets (Recommended)

```bash
bash 4.2_data_src_sort.sh
bash 5.2_data_dst_sort.sh
```

---

## Step 8: Train the Model

```bash
source /workspace/dfl_env/bin/activate
cd /workspace/DeepFace-VastAi/DeepFaceLab_Linux/scripts
bash 6_train_SAEHD_no_preview.sh
```

### Shortcuts:
* **Save & Exit training:** Press <kbd>Enter</kbd>
* **Save without exiting:** Press <kbd>S</kbd>

---

## Step 9: Merge Deepfake onto Destination Frames

```bash
bash 7_merge_SAEHD.sh
```

### Recommended Merge Options:
* **Use interactive merger?** `n`
* **Choose mode:** `1`
* **Choose mask mode:** `4`
* **Choose erode mask modifier:** `5`
* **Choose blur mask modifier:** `15`
* **Choose motion blur power:** `Enter` (0)
* **Choose output face scale modifier:** `Enter` (0)
* **Color transfer to predicted face:** `rct`
* **Choose sharpen mode:** `Enter` (0)
* **Choose super resolution power:** `0`
* **Choose image degrade by denoise power:** `Enter` (0)
* **Choose image degrade by bicubic rescale power:** `Enter` (0)
* **Degrade color power of final image:** `Enter` (0)
* **Number of workers?** `Enter`

---

## Step 10: Export Result to Video

```bash
bash 8_merged_to_mp4.sh
```

### Recommended Export Options:
* **Input image format (extension):** `png` (or `jpg` if extracted as jpg)
* **Use lossless codec?** `n`
* **Bitrate of output file in MB/s:** `16` (or `Enter` for default)

---

## Step 11: Create Zip File of Workspace

```bash
bash 9_create_workspace_zip.sh
```

---

## Step 12: Download Result or Workspace to Your Local Machine

**Download Result Video:**

Mac / Linux:
```bash
scp -P <PORT> root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/result.mp4 ~/Desktop/result.mp4
```

Windows PowerShell:
```powershell
scp -P <PORT> root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace/result.mp4 "C:\Users\<Username>\Desktop\result.mp4"
```

**Download Workspace Archive:**

Mac / Linux:
```bash
scp -P <PORT> root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace.zip ~/Desktop/workspace.zip
```

Windows PowerShell:
```powershell
scp -P <PORT> root@<IP>:/workspace/DeepFace-VastAi/DeepFaceLab_Linux/workspace.zip "C:\Users\<Username>\Desktop\workspace.zip"
```

---

## Quick Troubleshooting Reference

**Check GPU access:**
```bash
python -c "import tensorflow as tf; print('GPUs:', tf.config.list_physical_devices('GPU'))"
```

**Fix missing CUDA path:**
```bash
export LD_LIBRARY_PATH=$(python -c "import site, glob; print(':'.join(glob.glob(site.getsitepackages()[0] + '/nvidia/*/lib')))"):$LD_LIBRARY_PATH
```

**Resume after instance restart:**
```bash
source /workspace/dfl_env/bin/activate
cd /workspace/DeepFace-VastAi/DeepFaceLab_Linux/scripts
```

**Kill hanging or zombie processes:**
```bash
pkill -9 -f python
```

