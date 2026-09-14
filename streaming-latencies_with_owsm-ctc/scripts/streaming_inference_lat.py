from espnet2.bin.s2t_inference_ctc_mod_ssa import Speech2TextGreedySearch
from espnet2.bin.s2t_inference_ctc_mod_streaming import StreamRecogniser
import sys
import os
import librosa
import itertools
import numpy as np

if len(sys.argv) != 9:
    sys.exit('%s <audio_path> <odir_hyp> <model> <audio_buffer_size:seconds> <step:float:seconds> <la:float:seconds> <lla_pad:float:seconds> <language:eng|spa|cat>')
    
AUDIO_PATH = sys.argv[1]
ODIR_HYP = sys.argv[2]
MODEL = sys.argv[3]
BUFFER_SIZE = float(sys.argv[4])
STEP = float(sys.argv[5])
LA = float(sys.argv[6])
LLA_SHIFT = float(sys.argv[7])
LANG = sys.argv[8]

os.environ["HF_HUB_OFFLINE"] = "1"

#################
#
#  RECO
#
model = Speech2TextGreedySearch.from_pretrained(
    MODEL,
    device="cuda",
    use_flash_attn=False,   # set to True for better efficiency if flash attn is installed and dtype is float16 or bfloat16
    lang_sym=f'<{LANG}>',
    task_sym='<asr>',
)

model.s2t_model.eval()

speech, _ = librosa.load(AUDIO_PATH, sr=model.sample_rate)

if not os.path.exists(ODIR_HYP):
    os.makedirs(ODIR_HYP)
NFILE = AUDIO_PATH.split('/')[-1][:-4]

lf = ODIR_HYP + '/' + NFILE + '.lat'
sr = StreamRecogniser(model, STEP, LA, LLA_SHIFT, ignore_tokens=[',', '.'], return_latencies=True, log_file=lf)

res = []

for w in sr(speech):
    #print(w)
    res += w

hyp = " ".join(trip[0] for trip in res)

with open(ODIR_HYP + '/' + NFILE + '.txt', 'w') as f:
    f.write(hyp)
