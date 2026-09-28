# -*- coding: utf-8 -*-
"""补充贴图（光源渐变/寒霜边框）+ 程序化音效（全部原创合成）"""
import math, random, struct, wave, os
from PIL import Image, ImageDraw, ImageFilter

random.seed(4444)
SPR = "dead_building/assets/sprites"
SFX = "dead_building/assets/sfx"
os.makedirs(SFX, exist_ok=True)

# ---------- 手电光渐变 256x256 ----------
img = Image.new("RGBA", (256,256), (0,0,0,0))
px = img.load()
for y in range(256):
    for x in range(256):
        d = math.hypot(x-128, y-128) / 128.0
        if d < 1.0:
            a = int(255 * max(0.0, (1-d))**1.6)
            px[x,y] = (255, 244, 214, a)
img.save(f"{SPR}/light_grad.png")

# ---------- 寒霜边框 640x360（低温效果） ----------
img = Image.new("RGBA", (640,360), (0,0,0,0))
px = img.load()
rnd = random.Random(3)
for y in range(360):
    for x in range(640):
        edge = min(x, 639-x, y, 359-y)
        if edge < 70:
            t = 1 - edge/70.0
            a = int(150 * t*t) + rnd.randint(0, 30)
            px[x,y] = (205, 228, 245, min(200, a))
img = img.filter(ImageFilter.GaussianBlur(3))
img.save(f"{SPR}/fx_frost.png")

# ---------- 音效合成 ----------
SR = 22050
def write_wav(name, samples):
    samples = [max(-1.0, min(1.0, s)) for s in samples]
    with wave.open(f"{SFX}/{name}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s*32767)) for s in samples))

def env(i, n, attack=0.01, decay=None):
    t = i/n
    a = min(1.0, i/(attack*n+1))
    d = math.exp(-4*t) if decay is None else math.exp(-t/decay)
    return a*d

def paper():
    n = int(SR*0.35); rnd = random.Random(1)
    out=[]; prev=0.0
    for i in range(n):
        w = rnd.uniform(-1,1)
        prev = 0.7*prev + 0.3*w          # 低通噪声
        out.append(prev*env(i,n)*0.9)
    return out

def chime():
    notes = [523.25, 659.25, 783.99, 1046.5]  # C5 E5 G5 C6
    n = int(SR*2.2); out=[0.0]*n
    for k,f in enumerate(notes):
        start = int(k*SR*0.22)
        for i in range(n-start):
            t = i/SR
            out[start+i] += math.sin(2*math.pi*f*t)*math.exp(-2.2*t)*0.22
            out[start+i] += math.sin(2*math.pi*f*2*t)*math.exp(-3.5*t)*0.06
    return out

def static_():
    n = int(SR*1.0); rnd = random.Random(2)
    return [rnd.uniform(-0.25,0.25)*(0.6+0.4*math.sin(i/SR*40)) for i in range(n)]

def door():
    n = int(SR*0.8); out=[]; phase=0.0
    for i in range(n):
        t=i/SR
        f = 90 + 60*math.sin(t*9)         # 门轴呻吟：颤动低频
        phase += 2*math.pi*f/SR
        v = math.tanh(math.sin(phase)*2.5)  # 锯齿感
        out.append(v*env(i,n,attack=0.15,decay=0.5)*0.4)
    return out

def footstep():
    n = int(SR*0.12); rnd = random.Random(4); out=[]; prev=0.0
    for i in range(n):
        w = rnd.uniform(-1,1)
        prev = 0.5*prev + 0.5*w
        out.append(prev*env(i,n,attack=0.005,decay=0.12)*0.8)
    return out

def heartbeat():
    n = int(SR*1.2); out=[0.0]*n
    for k,at in enumerate([0.0, 0.28, 0.8, 1.08]):   # 咚-咚 咚-咚
        start = int(at*SR)
        for i in range(n-start):
            t=i/SR
            out[start+i] += math.sin(2*math.pi*55*t)*math.exp(-9*t)*0.5
    return out

def drone(freqs, dur, wob=0.3, seed=5):
    n = int(SR*dur); rnd = random.Random(seed); out=[0.0]*n
    phases=[0.0]*len(freqs)
    for i in range(n):
        t=i/SR; v=0.0
        for k,f in enumerate(freqs):
            phases[k] += 2*math.pi*(f + wob*math.sin(t*0.7+k))/SR
            v += math.sin(phases[k])*(0.16/(k+1))
        v += rnd.uniform(-0.012,0.012)      # 轻微底噪
        # 首尾淡入淡出避免爆音
        fade = min(1.0, i/(SR*1.5), (n-i)/(SR*1.5))
        out[i] = v*fade
    return out

def day_pad():
    # 温暖大三和弦垫 156 175 196 Hz 区间
    return drone([130.8, 164.8, 196.0, 261.6], 24, wob=0.15, seed=6)

def night_drone():
    return drone([55.0, 55.7, 82.4, 110.3], 24, wob=0.5, seed=7)

write_wav("paper", paper())
write_wav("chime", chime())
write_wav("static", static_())
write_wav("door", door())
write_wav("footstep", footstep())
write_wav("heartbeat", heartbeat())
write_wav("day_pad", day_pad())
write_wav("night_drone", night_drone())
print("sfx done:", os.listdir(SFX))
