"""Generate original, quiet UI chimes. Standard library only; no external audio."""
import math, struct, wave
from pathlib import Path
RATE=24000
OUT=Path('assets/audio/effects');OUT.mkdir(parents=True,exist_ok=True)
patterns={
 'tap':[(880,0,.045,.13)],
 'correct':[(659.25,0,.18,.32),(880,.10,.19,.28)],
 'retry':[(392,0,.15,.20),(329.63,.09,.16,.17)],
 'streak':[(523.25,0,.20,.28),(659.25,.10,.20,.28),(783.99,.20,.25,.30),(1046.5,.32,.23,.23)],
 'hot_streak':[(659.25,0,.22,.26),(783.99,.11,.22,.26),(1046.5,.22,.24,.28),(1318.5,.36,.31,.26)],
 'complete':[(523.25,0,.24,.25),(659.25,.12,.25,.25),(783.99,.24,.31,.27)],
 'perfect':[(523.25,0,.22,.24),(659.25,.10,.22,.24),(783.99,.20,.25,.24),(1046.5,.33,.27,.26),(1318.5,.48,.38,.24)],
}
for name,notes in patterns.items():
 duration=max(start+length for _,start,length,_ in notes)+.03
 samples=[0.0]*int(duration*RATE)
 for freq,start,length,level in notes:
  for n in range(int(length*RATE)):
   t=n/RATE;attack=min(1,t/.006);release=(1-t/length)**2
   tone=math.sin(2*math.pi*freq*t)+.12*math.sin(2*math.pi*freq*2*t)
   samples[int(start*RATE)+n]+=tone*attack*release*level
 peak=max(abs(x) for x in samples);gain=min(1,.58/max(peak,.001))
 with wave.open(str(OUT/(name+'.wav')),'wb') as out:
  out.setparams((1,2,RATE,len(samples),'NONE','not compressed'))
  out.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x*gain))*32767)) for x in samples))
print('Generated seven original feedback sounds.')
