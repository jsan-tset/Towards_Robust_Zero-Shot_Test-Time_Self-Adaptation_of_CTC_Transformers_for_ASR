import os
import sys

import torch
from espnet2.bin.s2t_inference_ctc import Speech2TextGreedySearch
#from espnet2.bin.s2t_inference_ctc_jsj import Speech2TextGreedySearch
from espnet2.layers.create_adapter_fn import create_lora_adapter
import espnetez as ez

if len(sys.argv)!=8:
    sys.exit("%s <audio_path> <chkp_path:path/to/5epoch.pth> <output_dir> <model> <lora_rank> <lora_alpha> <language>")
    
AUDIO_PATH = sys.argv[1]
CHKP_PATH = sys.argv[2]
OUTPUT_DIR = sys.argv[3]
MODEL = sys.argv[4]
LORA_RANK=int(sys.argv[5])
LORA_ALPHA=int(sys.argv[6])
LANG = sys.argv[7]

EPOCH_NUM = CHKP_PATH.split('/')[-1].split('epoch')[0]


LORA_TARGET = [
    "linear_q", "linear_v"
]

# Load original model
print("[ii] Loading original model")
model = Speech2TextGreedySearch.from_pretrained(
    MODEL,
    device="cuda",
    use_flash_attn=False,   # set to True for better efficiency if flash attn is installed and dtype is float16 or bfloat16
    lang_sym=f'<{LANG}>',
    task_sym='<asr>',
)

# Apply LoRA
print("[ii] Applying adapter")
create_lora_adapter(model.s2t_model, rank=LORA_RANK, alpha=LORA_ALPHA, dropout_rate=0.1, target_modules=LORA_TARGET)
model.s2t_model.train()
d = torch.load(CHKP_PATH)
model.s2t_model.load_state_dict(d, strict=False)
model.s2t_model.eval()

print("[ii] Start inference")
res = model.batch_decode(
    [AUDIO_PATH],
    batch_size=4,
    context_len_in_secs=4,
) 


NFILE = OUTPUT_DIR + '/'  + '/'.join(AUDIO_PATH.split('/')[1:])[:-4]+f".ep{EPOCH_NUM}.txt"
if not os.path.exists(os.path.dirname(NFILE)):
    os.makedirs(os.path.dirname(NFILE))
with open(NFILE, 'w') as f:
    f.write(res[0])
print(f"[ii] - {NFILE} saved ")
