from espnet2.bin.s2t_inference_ctc import Speech2TextGreedySearch
import sys
import os

if len(sys.argv)!=5:
    sys.exit('%s <audio_list> <output_dir> <model> <lang>')
    
INPUT_LIST = sys.argv[1]
OUTPUT_DIR = sys.argv[2]
MODEL = sys.argv[3]
LANG = sys.argv[4]

f = open(INPUT_LIST, 'r')
audio_lst = f.read().split()
f.close()

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

res, timealig = s2t.batch_decode(
    audio_lst,
    batch_size=4,
    context_len_in_secs=4,
)   # res is a list of str

#################
#
#  OUTP
#
for i, SPL in enumerate(audio_lst):
    # Cuidao amb el format ;)
    ODIR = OUTPUT_DIR + '/'  + '/'.join(SPL.split('/')[1:-1])
    NFILE = SPL.split('/')[-1][:-4]

    if not os.path.exists(ODIR):
        os.makedirs(ODIR)

    with open(ODIR + '/' + NFILE + '.txt', 'w') as f:
        f.write(res[i])
    with open(ODIR + '/' + NFILE + '.nctm', 'w') as f:
        f.write('\n'.join(timealig[i]))
