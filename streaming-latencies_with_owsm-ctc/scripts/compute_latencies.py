import ast
import sys
import numpy as np

if len(sys.argv) != 3:
    sys.exit('%s <log_file> [token|word]')
    
LOG_F = sys.argv[1]
FLAG = sys.argv[2].lower()
if FLAG != 'token' and FLAG != 'word':
    raise ValueError(f'Unknown flag: {FLAG}. Must be token or word.')

head = f"{FLAG:^15} | {'Audio Time':^15} | {'Emission Time':^15} | {'Word Latency':^18} | {'Et - At':^18}"
print(head)
print("-" * len(head))

lat_list = []
with open(LOG_F, 'r') as log_f:
    audio_acum = 0.0
    ts_real_prev = None
    t_simul_prev = 0.0
    for line in log_f:
        # event type, timestamp, dur 
        # ('audio', 1776857804.141456, 0.1)
        # event type, timestamp, word tuple=(word, ini_time, dur)
        # ('word', 1776857804.347225, ('observed', 103.36, 0.08))
        ev, ts_real_now, info = ast.literal_eval(line)
        if ev != 'audio' and ev != FLAG: continue

        if ts_real_prev is None:
            ts_real_prev = ts_real_now
            if ev == 'audio':
                audio_acum += info
                t_simul_prev = audio_acum 
            continue

        delta_ts = ts_real_now - ts_real_prev

        if ev == 'audio':
            audio_acum += info
            t_simul_now = max(audio_acum, t_simul_prev + delta_ts)
            
        elif ev == FLAG:
            word, ini_word, dur_word = info
            fin_word = ini_word + dur_word
            
            t_simul_now = t_simul_prev + delta_ts
            
            lat_word = t_simul_now - fin_word
            lat_sistema = t_simul_now - audio_acum

            lat_list.append(lat_word)
            
            print(f"{word:<15} | {audio_acum:<15.4f} | {t_simul_now:<15.4f} | {lat_word:<18.4f} | {lat_sistema:<18.4f}")
        else:
            # maybe new future events
            continue

        ts_real_prev = ts_real_now
        t_simul_prev = t_simul_now

medi = np.mean(lat_list)
stdd = np.std(lat_list)
print("-" * len(head))
print(f"{medi:.4f} += {2*stdd:.4f}")
