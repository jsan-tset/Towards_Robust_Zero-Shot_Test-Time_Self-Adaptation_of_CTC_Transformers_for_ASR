from espnet2.bin.s2t_inference_ctc_jsj import Speech2TextGreedySearch
import sys
import os

if len(sys.argv)!=5:
    sys.exit('%s <audio_path> <output_dir> <model> <lang>')
    
AUDIO_PATH = sys.argv[1]
OUTPUT_DIR = sys.argv[2]
MODEL = sys.argv[3]
LANG = sys.argv[4]

#################
#
#  RECO
#
s2t = Speech2TextGreedySearch.from_pretrained(
    MODEL,
    device="cuda",
    use_flash_attn=False,   # set to True for better efficiency if flash attn is installed and dtype is float16 or bfloat16
    lang_sym=f'<{LANG}>',
    task_sym='<asr>',
)

res = s2t.batch_decode(
    [AUDIO_PATH],
    batch_size=4,
    context_len_in_secs=4,
)   # res is a list of str

#################
#
#  OUTP
#
for i, SPL in enumerate(res):
    # Cuidao amb el format ;)
    ODIR = OUTPUT_DIR + '/'  + '/'.join(AUDIO_PATH.split('/')[1:])[:-4]
    NFILE = AUDIO_PATH.split('/')[-1][:-4] + '.{:03d}.txt'.format(i)

    if not os.path.exists(ODIR):
        os.makedirs(ODIR)
    with open(ODIR + '/' + NFILE, 'w') as f:
        f.write(SPL)
