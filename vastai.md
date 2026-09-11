# DeepFaceLab 2.0 – Full Vast.ai Workflow

## Step 1: Clone repo & run setup (once per instance)

```bash
git clone https://github.com/<your-username>/<your-repo>.git /root/DeepFaceLab
cd /root/DeepFaceLab
bash setup_deepfacelab.sh
```

## Step 2: Activate Python environment

```bash
source /root/dfl_env/bin/activate
cd /root/DeepFaceLab/DeepFaceLab_Linux/scripts
```

## Step 3: Upload videos (run from your LOCAL Windows machine)

| Video | Description | Server path |
|---|---|---|
| **Source** | The face you want to use as the deepfake | `/root/DeepFaceLab/DeepFaceLab_Linux/workspace/data_src.mp4` |
| **Destination** | The video you want to swap the face into | `/root/DeepFaceLab/DeepFaceLab_Linux/workspace/data_dst.mp4` |

```powershell
scp -P <PORT> "C:\path\to\source_face.mp4" root@<IP>:/root/DeepFaceLab/DeepFaceLab_Linux/workspace/data_src.mp4
scp -P <PORT> "C:\path\to\destination_video.mp4" root@<IP>:/root/DeepFaceLab/DeepFaceLab_Linux/workspace/data_dst.mp4
```

## Step 4: Clear workspace (optional – only if starting fresh)

```bash
bash 1_clear_workspace.sh
```

## Step 5: Extract frames from videos

```bash
bash 2_extract_image_from_data_src.sh
bash 3_extract_image_from_data_dst.sh
```

## Step 6: Extract faces from frames

```bash
bash 4_data_src_extract_faces_S3FD.sh
bash 5_data_dst_extract_faces_S3FD.sh
```

## Step 7: Sort & clean facesets (optional but recommended)

```bash
bash 4.2_data_src_sort.sh
bash 5.2_data_dst_sort.sh
```

## Step 8: Train the model (can take hours – use tmux)

```bash
tmux new -s dfl
source /root/dfl_env/bin/activate
cd /root/DeepFaceLab/DeepFaceLab_Linux/scripts
bash 6_train_SAEHD.sh
```

- **Detach from tmux:** `Ctrl+B` then `D`
- **Re-attach later:** `tmux attach -t dfl`

## Step 9: Merge deepfake onto destination frames

```bash
bash 7_merge_SAEHD.sh
```

## Step 10: Export result video

```bash
bash 8_merged_to_mp4.sh
```

## Step 11: Download result (run from your LOCAL Windows machine)

```powershell
scp -P <PORT> root@<IP>:/root/DeepFaceLab/DeepFaceLab_Linux/workspace/result.mp4 "D:\Projects\52. DeepFake\result.mp4"
```
