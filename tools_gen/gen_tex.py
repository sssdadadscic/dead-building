# -*- coding: utf-8 -*-
"""《死楼》3D 版贴图生成器 — 灰度可染色贴图 + 彩色细节贴图，全部原创"""
import math, random
from PIL import Image, ImageDraw, ImageFilter

random.seed(4444)
OUT = "dead_building/assets/tex"
import os
os.makedirs(OUT, exist_ok=True)

def noise(img, strength=10, seed=0, density=0.5):
    rnd = random.Random(seed)
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            if rnd.random() < density:
                v = px[x,y]
                if isinstance(v, int):
                    px[x,y] = max(0, min(255, v + rnd.randint(-strength, strength)))
                else:
                    d = rnd.randint(-strength, strength)
                    if len(v) == 3:
                        r,g,b = v; a = 255
                    else:
                        r,g,b,a = v
                    px[x,y] = (max(0,min(255,r+d)), max(0,min(255,g+d)), max(0,min(255,b+d)), a)
    return img

# ---------- 墙纸（灰度，游戏内染色）----------
def wallpaper():
    img = Image.new("L", (256,256), 210)
    d = ImageDraw.Draw(img)
    for x in range(0, 256, 32):                        # 竖条纹
        d.rectangle([x,0,x+16,256], fill=196)
    for x in range(8, 256, 32):                        # 暗纹菱形
        for y in range(8, 256, 32):
            d.polygon([(x,y-5),(x+5,y),(x,y+5),(x-5,y)], fill=178)
    d.rectangle([0,0,256,10], fill=170)                # 顶部压边
    noise(img, 8, 1)
    img.save(f"{OUT}/wallpaper.png")

# ---------- 木地板（灰度）----------
def woodfloor():
    img = Image.new("L", (256,256), 150)
    d = ImageDraw.Draw(img)
    rnd = random.Random(2)
    row = 0
    for y in range(0, 256, 42):
        d.rectangle([0,y,256,y+2], fill=110)
        off = (row*97) % 180
        for x in range(-off, 256, 180):
            d.line([(x,y),(x-8,y+42)], fill=112, width=2)
        for _ in range(14):                            # 木纹
            gx = rnd.randint(0,255); gy = rnd.randint(y+4, y+38)
            ln = rnd.randint(10, 40)
            d.line([(gx,gy),(min(255,gx+ln),gy)], fill=140, width=1)
        row += 1
    noise(img, 9, 3)
    img.save(f"{OUT}/woodfloor.png")

# ---------- 天花板（灰度方板）----------
def ceiling():
    img = Image.new("L", (256,256), 190)
    d = ImageDraw.Draw(img)
    for x in range(0,256,64): d.line([(x,0),(x,256)], fill=150, width=2)
    for y in range(0,256,64): d.line([(0,y),(256,y)], fill=150, width=2)
    noise(img, 7, 4)
    img.save(f"{OUT}/ceiling.png")

# ---------- 木门（彩色）----------
def door():
    img = Image.new("RGB", (128,256), (112,76,46))
    d = ImageDraw.Draw(img)
    d.rectangle([0,0,127,255], outline=(58,40,24), width=4)
    for box in ([16,20,112,110], [16,140,112,236]):
        d.rectangle(box, fill=(96,64,38), outline=(58,40,24), width=3)
        d.rectangle([box[0]+6,box[1]+6,box[2]-6,box[3]-6], fill=(126,88,54))
    d.rectangle([4,4,10,252], fill=(140,100,62))       # 左高光
    d.ellipse([100,120,112,132], fill=(220,200,140), outline=(90,70,40), width=2)  # 把手
    noise(img, 8, 5)
    img.save(f"{OUT}/door.png")

# ---------- 门牌（彩色 128x64）----------
def doorplate(num):
    img = Image.new("RGB", (128,64), (236,230,214))
    d = ImageDraw.Draw(img)
    d.rectangle([0,0,127,63], outline=(120,100,70), width=4)
    from PIL import ImageFont
    try:
        f = ImageFont.truetype("dead_building/assets/fonts/NotoSansSC-Bold.ttf", 36)
    except Exception:
        f = ImageFont.load_default()
    w = d.textlength(num, font=f)
    d.text(((128-w)/2, 10), num, font=f, fill=(60,44,30))
    img.save(f"{OUT}/plate_{num}.png")

# ---------- 便利贴墙（带 alpha）----------
def stickywall():
    img = Image.new("RGBA", (256,256), (0,0,0,0))
    d = ImageDraw.Draw(img)
    rnd = random.Random(6)
    for _ in range(46):
        x, y = rnd.randint(4,220), rnd.randint(4,220)
        w, h = rnd.randint(18,34), rnd.randint(18,34)
        col = rnd.choice([(240,228,150,255),(236,214,160,255),(226,200,170,255),(240,220,200,255)])
        d.rectangle([x,y,x+w,y+h], fill=col, outline=(60,40,30,255))
        for i in range(3):
            d.line([(x+4,y+6+i*6),(x+w-4,y+6+i*6)], fill=(120,50,45,255), width=1)
    img.save(f"{OUT}/stickywall.png")

# ---------- 血痕（带 alpha，从顶部流下）----------
def blood_drips():
    img = Image.new("RGBA", (256,256), (0,0,0,0))
    d = ImageDraw.Draw(img)
    rnd = random.Random(7)
    for _ in range(18):
        x = rnd.randint(0,255); ln = rnd.randint(60, 240); w = rnd.randint(3,10)
        d.line([(x,0),(x+rnd.randint(-10,10),ln)], fill=(70,8,8,230), width=w)
        d.ellipse([x-w, ln-6, x+w, ln+6], fill=(70,8,8,230))
    img = img.filter(ImageFilter.GaussianBlur(1))
    img.save(f"{OUT}/blood_drips.png")

def blood_pool():
    img = Image.new("RGBA", (256,256), (0,0,0,0))
    d = ImageDraw.Draw(img)
    rnd = random.Random(8)
    for _ in range(24):
        x, y = rnd.randint(40,216), rnd.randint(60,216)
        r = rnd.randint(8, 36)
        d.ellipse([x-r,y-r//2,x+r,y+r//2], fill=(64,8,8,220))
    img = img.filter(ImageFilter.GaussianBlur(2))
    img.save(f"{OUT}/blood_pool.png")

# ---------- 日历（彩色）----------
def calendar():
    img = Image.new("RGB", (128,160), (244,238,222))
    d = ImageDraw.Draw(img)
    d.rectangle([0,0,127,159], outline=(90,70,50), width=4)
    d.rectangle([0,0,127,36], fill=(186,64,52))
    from PIL import ImageFont
    try:
        f1 = ImageFont.truetype("dead_building/assets/fonts/NotoSansSC-Bold.ttf", 22)
        f2 = ImageFont.truetype("dead_building/assets/fonts/NotoSansSC-Bold.ttf", 52)
    except Exception:
        f1 = f2 = ImageFont.load_default()
    d.text((34,6), "十二月", font=f1, fill=(255,240,230))
    d.text((24,56), "第1天", font=f2, fill=(150,30,26))
    for i in range(3):
        d.line([(14,124+i*10),(114,124+i*10)], fill=(200,190,165), width=1)
    img.save(f"{OUT}/calendar.png")

# ---------- 合影海报（管理员室公告板用）----------
def poster():
    img = Image.new("RGB", (192,144), (58,50,44))
    d = ImageDraw.Draw(img)
    d.rectangle([4,4,188,140], fill=(220,208,180))
    rnd = random.Random(9)
    for i in range(8):                                  # 一排人影
        x = 24 + i*19
        d.ellipse([x,50,x+14,64], fill=(90,78,64))      # 头
        d.rectangle([x-2,64,x+16,108], fill=(100,86,70)) # 身
    d.rectangle([4,112,188,140], fill=(180,164,134))
    from PIL import ImageFont
    try:
        f = ImageFont.truetype("dead_building/assets/fonts/NotoSansSC-Regular.ttf", 14)
    except Exception:
        f = ImageFont.load_default()
    d.text((38,118), "幸福苑全体住户合影", font=f, fill=(70,56,40))
    noise(img, 6, 9)
    img.save(f"{OUT}/poster.png")

# ---------- 镜子（竖长，带反光渐变）----------
def mirror():
    img = Image.new("RGB", (128,256), (190,196,200))
    d = ImageDraw.Draw(img)
    for i in range(256):
        t = i/255
        v = int(170 + 50*t)
        d.line([(0,i),(128,i)], fill=(v-20, v-10, v+6))
    d.polygon([(0,0),(50,0),(0,256)], fill=(215,222,228))   # 斜反光
    d.polygon([(60,0),(90,0),(20,256),(0,256),(0,220)], fill=(205,212,218))
    noise(img, 5, 10)
    img.save(f"{OUT}/mirror.png")

# ---------- 王大妈身体（128x256，带 alpha：花纹上衣+围裙）----------
def wang_body():
    img = Image.new("RGBA", (128,256), (0,0,0,0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([18,10,110,246], 40, fill=(122,58,66,255))          # 上衣
    rnd = random.Random(12)
    for i in range(40):                                                     # 碎花
        x, y = rnd.randint(24,104), rnd.randint(20,150)
        d.ellipse([x-3,y-3,x+3,y+3], fill=(150,80,88,255))
        d.ellipse([x-1,y-1,x+1,y+1], fill=(190,120,110,255))
    d.polygon([(40,60),(88,60),(98,240),(30,240)], fill=(216,210,196,255))  # 围裙
    d.line([(40,60),(88,60)], fill=(180,172,156,255), width=3)
    d.rectangle([52,150,76,196], fill=(196,188,172,255))                    # 口袋
    d.line([(52,150),(76,150)], fill=(160,152,138,255), width=2)
    d.line([(20,66),(108,66)], fill=(100,48,54,255), width=4)               # 腰带
    img.save(f"{OUT}/wang_body.png")

# ---------- 王大妈脸（128x128，带 alpha）----------
def _wang_base():
    img = Image.new("RGBA", (128,128), (0,0,0,0))
    d = ImageDraw.Draw(img)
    d.ellipse([22,18,106,116], fill=(235,200,168,255))      # 脸
    d.ellipse([18,8,110,62], fill=(158,152,148,255))        # 花白头发
    d.arc([24,14,104,66], 150, 30, fill=(120,114,110,255), width=3)  # 发缝
    for sx in range(30, 100, 10):                            # 发丝
        d.line([(sx,12),(sx+4,42)], fill=(140,134,130,255), width=2)
    d.ellipse([34,66,48,80], fill=(255,190,170,90))         # 腮红
    d.ellipse([80,66,94,80], fill=(255,190,170,90))
    return img, d

def wang_faces():
    img, d = _wang_base()
    d.arc([40,52,56,66], 200, 340, fill=(70,50,44,255), width=3)    # 笑眼（弯）
    d.arc([72,52,88,66], 200, 340, fill=(70,50,44,255), width=3)
    d.arc([38,46,58,58], 200, 340, fill=(120,96,88,255), width=2)   # 眉
    d.arc([70,46,90,58], 200, 340, fill=(120,96,88,255), width=2)
    d.arc([54,84,74,100], 20, 160, fill=(150,70,62,255), width=3)   # 微笑
    d.arc([26,70,44,96], 60, 160, fill=(200,160,140,180), width=2)  # 法令纹
    d.arc([84,70,102,96], 20, 120, fill=(200,160,140,180), width=2)
    img.save(f"{OUT}/wang_face.png")
    img, d = _wang_base()
    d.arc([40,52,56,66], 200, 340, fill=(70,50,44,255), width=3)
    d.arc([72,52,88,66], 200, 340, fill=(70,50,44,255), width=3)
    d.arc([38,46,58,58], 200, 340, fill=(120,96,88,255), width=2)
    d.arc([70,46,90,58], 200, 340, fill=(120,96,88,255), width=2)
    d.ellipse([56,84,72,102], fill=(120,54,48,255))                 # 说话（嘴张开）
    d.ellipse([58,94,70,100], fill=(170,90,84,255))
    img.save(f"{OUT}/wang_face_talk.png")

# ---------- 红裙子 / 白睡衣裙（128x256，带 alpha，裹在锥形裙上）----------
def _dress(base, hem, stain=None):
    dark = (max(0,base[0]-50), max(0,base[1]-50), max(0,base[2]-50), 255)
    img = Image.new("RGBA", (128,256), dark)                 # 不透明底色（避免透明像素渲染成黑色）
    d = ImageDraw.Draw(img)
    for y in range(256):
        t = y/255
        w = int(30 + 66*t)                                   # 上窄下宽
        cx = 64
        shade = int(26*t)
        col = (max(0,base[0]-shade), max(0,base[1]-shade), max(0,base[2]-shade), 255)
        d.line([(cx-w,y),(cx+w,y)], fill=col)
    rnd = random.Random(7)
    for i in range(9):                                       # 纵向褶皱
        x0 = 30 + i*9 + rnd.randint(-3,3)
        d.line([(x0,40),(x0+rnd.randint(-10,10),250)], fill=(0,0,0,60), width=3)
    d.rectangle([0,236,128,256], fill=hem)                   # 裙摆深色边
    if stain:
        for i in range(14):                                  # 褐色污渍
            x, y = rnd.randint(20,100), rnd.randint(190,246)
            r = rnd.randint(4,12)
            d.ellipse([x-r,y-r,x+r,y+r], fill=stain)
    return img

def ghost_dresses():
    _dress((178,36,38), (120,20,22,255), (96,52,30,160)).save(f"{OUT}/ghost_dress.png")
    _dress((238,234,226), (206,198,186,255)).save(f"{OUT}/ghost_gown.png")

# ---------- 鬼魂脸部贴图（128x128，带 alpha，精致版）----------
def _ghost_base(skin):
    img = Image.new("RGBA", (128,128), (0,0,0,0))
    d = ImageDraw.Draw(img)
    d.ellipse([24,16,104,116], fill=skin)                   # 脸
    d.ellipse([16,2,112,58], fill=(16,10,12,255))           # 发顶
    rnd = random.Random(5)
    for i in range(26):                                     # 发丝
        x0 = 20 + i*3.4
        d.line([(x0,8),(x0+rnd.randint(-8,8),rnd.randint(60,96))], fill=(24,15,17,255), width=2)
    d.rectangle([12,40,34,128], fill=(16,10,12,255))        # 左垂发
    d.rectangle([94,40,116,128], fill=(16,10,12,255))       # 右垂发
    return img, d

def ghost_faces():
    # 0 发遮面
    img, d = _ghost_base((232,222,212,255))
    for i in range(20):                                     # 遮面乱发
        x0 = 34 + i*3.2
        d.line([(x0,20),(x0+((i*7)%13-6),110)], fill=(18,12,14,255), width=3)
    img.save(f"{OUT}/ghost_face_hair.png")
    # 1 微笑（空洞眼+咧嘴，不安）
    img, d = _ghost_base((230,218,208,255))
    d.ellipse([38,52,54,72], fill=(10,8,8,255))             # 空洞眼
    d.ellipse([74,52,90,72], fill=(10,8,8,255))
    d.ellipse([42,56,48,62], fill=(60,20,22,255))           # 眼底暗红
    d.ellipse([80,56,86,62], fill=(60,20,22,255))
    d.arc([42,78,86,110], 10, 170, fill=(120,22,26,255), width=4)   # 咧嘴笑
    d.arc([46,80,82,106], 20, 160, fill=(60,12,14,255), width=2)
    img.save(f"{OUT}/ghost_face_smile.png")
    # 2 安详（闭眼+睫毛+浅笑）
    img, d = _ghost_base((238,232,224,255))
    d.arc([36,54,56,70], 200, 340, fill=(52,40,38,255), width=3)    # 闭眼
    d.arc([72,54,92,70], 200, 340, fill=(52,40,38,255), width=3)
    for lx in [38,44,50]:
        d.line([(lx,64),(lx-3,70)], fill=(52,40,38,255), width=1)   # 睫毛
    for lx in [76,82,88]:
        d.line([(lx,64),(lx+3,70)], fill=(52,40,38,255), width=1)
    d.arc([52,82,76,100], 20, 160, fill=(190,110,100,255), width=3) # 浅笑
    d.ellipse([34,72,46,82], fill=(250,200,190,80))                 # 腮红
    d.ellipse([82,72,94,82], fill=(250,200,190,80))
    img.save(f"{OUT}/ghost_face_calm.png")

wallpaper(); woodfloor(); ceiling(); door()
for n in ["101","102","103","104"]: doorplate(n)
stickywall(); blood_drips(); blood_pool(); calendar(); poster(); mirror(); ghost_faces()
wang_body(); wang_faces(); ghost_dresses()
print("tex done")
