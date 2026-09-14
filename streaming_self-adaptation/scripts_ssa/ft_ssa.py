import sys
import os
from glob import glob

import numpy as np
import librosa

import torch
from espnet2.bin.s2t_inference_ctc import Speech2Text
from espnet2.layers.create_adapter_fn import create_lora_adapter
import espnetez as ez

if len(sys.argv) != 11:
    sys.exit(f"{sys.argv[0]} <train_csv> <valid_csv> <outdir> <model> <LR> <lora_rank> <lora_alpha> <epoch> <conf.yaml> <lang>") 

TRAIN_CSV=sys.argv[1]
VALID_CSV=sys.argv[2]
DEXP=sys.argv[3]
MODEL=sys.argv[4]
LR=float(sys.argv[5])
LORA_RANK=int(sys.argv[6])
LORA_ALPHA=int(sys.argv[7])
EPOCH=int(sys.argv[8])
CONF_FILE=sys.argv[9]
LANGUAGE=sys.argv[10]


print("[ii] STEP 1 - PREP")
####################################
#
#  Prep
#
DUMP_DIR = f"./dump"
EXP_DIR = f"./{DEXP}/finetune"
STATS_DIR = f"./{DEXP}/stats_finetune"

FINETUNE_MODEL = MODEL
LORA_TARGET = [
    "linear_q", "linear_v"
]
BEAMSIZE=10




print("[ii] STEP 2 - MODEL")
####################################
#
#  Model
#
pretrained_model = Speech2Text.from_pretrained(
    FINETUNE_MODEL,
    beam_size=BEAMSIZE,
    lang_sym=f'<{LANGUAGE}>',
    task_sym='<asr>',
) # Load model to extract configs.
pretrain_config = vars(pretrained_model.s2t_train_args)
tokenizer = pretrained_model.tokenizer
converter = pretrained_model.converter
del pretrained_model

finetune_config = ez.config.update_finetune_config(
	's2t',
	pretrain_config,
        CONF_FILE
)

# define model loading function
def count_parameters(model):
    return sum(p.numel() for p in model.parameters() if p.requires_grad)

def freeze_parameters(model):
    for p in model.parameters():
        if p.requires_grad:
            p.requires_grad = False

def build_model_fn(args):
    pretrained_model = Speech2Text.from_pretrained(
        FINETUNE_MODEL,
        beam_size=BEAMSIZE,
        lang_sym=f'<{LANGUAGE}>',
        task_sym='<asr>',
    )
    model = pretrained_model.s2t_model
    model.train()
    print(f'Trainable parameters: {count_parameters(model)}')
    freeze_parameters(model)

    return model



print("[ii] STEP 3 - DATSET")
####################################
#
#  Dataset format
#
# Before initiating the training process, it is crucial to adapt the dataset to
# the ESPnet format. The dataset class should output tokenized text and audio
# files in np.array format.

# custom dataset class
class CustomDataset(torch.utils.data.Dataset):
    def __init__(self, data_list):
        # data_list is a list of tuples (audio_path, text, text_ctc)
        self.data = data_list

    def __len__(self):
        return len(self.data)

    def __getitem__(self, idx):
        return self._parse_single_data(self.data[idx])

    def _parse_single_data(self, d):
        d = d.split('|')
        text = f"<{LANGUAGE}><asr> {d[1]}"
        return {
            "audio_path": d[0],
            "text": text,
            "text_prev": "<na>",
            "text_ctc": d[2],
            "prefix": f"<{LANGUAGE}><asr>",
        }


train_list = []
with open(TRAIN_CSV, "r", encoding="utf-8") as f:
    train_list += f.readlines()


valid_list = []
with open(VALID_CSV, "r", encoding="utf-8") as f:
    valid_list += f.readlines()

train_dataset = CustomDataset(train_list)
valid_dataset = CustomDataset(valid_list)

def tokenize(text):
    return np.array(converter.tokens2ids(tokenizer.text2tokens(text)))

# The output of CustomDatasetInstance[idx] will be converted to np.array
# with the functions defined in the data_info dictionary.
data_info = {
    "speech": lambda d: librosa.load(d["audio_path"], sr=16000)[0],
    "text": lambda d: tokenize(d["text"]),
    "text_prev": lambda d: tokenize(d["text_prev"][1:]),
    "text_ctc": lambda d: tokenize(d["text_ctc"]),
    "prefix" : lambda d: tokenize(d["prefix"])[1:]
}

# Convert into ESPnet-EZ dataset format
train_dataset = ez.dataset.ESPnetEZDataset(train_dataset, data_info=data_info)
valid_dataset = ez.dataset.ESPnetEZDataset(valid_dataset, data_info=data_info)





print("[ii] STEP 4 - TRAIN")
####################################
#
#  Train!
#
ACCUM_GRAD = min(20, len(train_list))

trainer = ez.Trainer(
    task='s2t',
    train_config=finetune_config,
    train_dataset=train_dataset,
    valid_dataset=valid_dataset,
    build_model_fn=build_model_fn, # provide the pre-trained model
    data_info=data_info,
    output_dir=EXP_DIR,
    stats_dir=STATS_DIR,
    ngpu=1,
    allow_variable_data_keys=True,
    init_param = [],
    accum_grad = ACCUM_GRAD,
    max_epoch=EPOCH,
    save_strategy="adapter_only",
    use_adapter=True,
    adapter_conf = {
        "rank" : LORA_RANK,
        "alpha" : LORA_ALPHA,
        "dropout_rate" : 0.05,
        "target_modules" : LORA_TARGET,
        "bias_type" : "none"
    },
    optim_conf = {
        "lr" : LR,
        "weight_decay" : 0.000001
    }
)
print("  `-> Collect stats")
trainer.collect_stats()
print("  `-> Train !!!")
trainer.train()
