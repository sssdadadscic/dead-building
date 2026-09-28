# -*- coding: utf-8 -*-
"""《死楼》像素资产生成器 v2 — 画风升级
参考 CALL OF CUTIE：Q版二头身角色 + 粗描边 + 柔和高光，与黑暗场景形成反差
全部原创像素画，无版权风险
"""
import math, random
from PIL import Image, ImageDraw, ImageFilter

random.seed(4444)
OUT = "dead_building/assets/sprites"
W, H = 640, 360

# ---------- 调色板（扩展：高光/描边/点缀） ----------
DAY = dict(wall=(222,186,130), wall_d=(184,146,94), wall_l=(238,208,152),
           floor=(134,98,62), floor_d=(110,80,50), floor_l=(152,114,74),
           trim=(92,64,38), outline=(58,40,24),
           light=(255,238,180), door=(118,80,48), door_d=(96,64,38), door_l=(140,98,60),
           paper=(242,234,210), ink=(62,50,38))
NIGHT = dict(wall=(52,66,98), wall_d=(38,50,78), wall_l=(66,82,118),
             floor=(34,42,64), floor_d=(26,32,50), floor_l=(42,52,76),
             trim=(18,24,40), outline=(10,14,24),
             light=(160,200,240), door=(42,54,82), door_d=(32,42,64), door_l=(54,68,100),
             paper=(130,150,190), ink=(20,26,44))
RED = dict(wall=(126,30,30), wall_d=(94,18,18), wall_l=(148,42,40),
           floor=(70,16,16), floor_d=(54,12,12), floor_l=(84,22,20),
           trim=(40,9,9), outline=(24,5,5),
           light=(238,130,118), door=(86,18,18), door_d=(66,13,13), door_l=(104,26,24),
           paper=(230,200,190), ink=(94,12,12))
WHITE = dict(wall=(232,226,214), wall_d=(206,198,184), wall_l=(244,240,230),
             floor=(154,132,104), floor_d=(130,110,86), floor_l=(170,148,118),
             trim=(100,84,64), outline=(64,52,40),
             light=(255,250,236), door=(144,114,84), door_d=(120,94,68), door_l=(164,132,98),
             paper=(248,244,236), ink=(72,62,50))

# ================= 基础工具 =================
def noise_overlay(img, strength=10, seed=0, density=0.5):
    rnd = random.Random(seed)
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            if rnd.random() < density:
                r,g,b,a = px[x,y]
                d = rnd.randint(-strength, strength)
                px[x,y] = (max(0,min(255,r+d)), max(0,min(255,g+d)), max(0,min(255,b+d)), a)
    return img

def vgrad(d, box, c1, c2):
    x0,y0,x1,y1 = box
    h = max(1, y1-y0)
    for yy in range(y0, y1):
        t = (yy-y0)/(h-1) if h>1 else 0
        d.line([(x0,yy),(x1,yy)], fill=tuple(int(c1[k]+(c2[k]-c1[k])*t) for k in range(3)))

def dither(d, box, c, density=0.25, seed=1):
    """稀疏杂点增加质感"""
    rnd = random.Random(seed)
    x0,y0,x1,y1 = box
    for y in range(y0,y1,2):
        for x in range(x0,x1,2):
            if rnd.random() < density:
                d.point([(x,y),(x+1,y+1)], fill=c)

def orr(d, box, fill, outline=None, r=2):
    """圆角矩形 + 可选描边"""
    x0,y0,x1,y1 = box
    if outline:
        d.rounded_rectangle([x0,y0,x1,y1], radius=r, fill=outline)
        d.rounded_rectangle([x0+1,y0+1,x1-1,y1-1], radius=max(0,r-1), fill=fill)
    else:
        d.rounded_rectangle([x0,y0,x1,y1], radius=r, fill=fill)

def cracks(d, box, pal, n=3, seed=2):
    rnd = random.Random(seed)
    x0,y0,x1,y1 = box
    for _ in range(n):
        cx, cy = rnd.randint(x0,x1), rnd.randint(y0,y0+(y1-y0)//3)
        pts = [(cx,cy)]
        for _s in range(rnd.randint(3,6)):
            cx += rnd.randint(-4,4); cy += rnd.randint(2,7)
            pts.append((cx,cy))
        d.line(pts, fill=pal["outline"], width=1)

def stains(d, box, color, n=20, seed=1):
    rnd = random.Random(seed)
    x0,y0,x1,y1 = box
    for _ in range(n):
        cx, cy = rnd.randint(x0,x1), rnd.randint(y0,y1)
        r = rnd.randint(2, 10)
        for i in range(r, 0, -2):
            v = tuple(max(0, c-int(6*i/r)) for c in color)
            d.ellipse([cx-i, cy-i//2, cx+i, cy+i//2], fill=v)

# ================= 房间基底 =================
def base_room(pal, seed=1):
    img = Image.new("RGBA", (W,H), (0,0,0,255))
    d = ImageDraw.Draw(img)
    vgrad(d, (0,0,W,232), pal["wall_l"], pal["wall_d"])        # 墙：亮到暗
    vgrad(d, (0,0,W,20), tuple(v//3 for v in pal["wall_d"]), pal["wall_l"])  # 顶部暗角
    # 护墙板
    d.rectangle([0,196,W,232], fill=pal["wall_d"])
    d.line([(0,196),(W,196)], fill=pal["outline"], width=1)
    d.line([(0,200),(W,200)], fill=pal["wall_l"], width=1)
    for x in range(0, W, 40):
        d.line([(x,202),(x,230)], fill=pal["outline"], width=1)
    # 踢脚线
    d.rectangle([0,228,W,238], fill=pal["trim"])
    d.line([(0,228),(W,228)], fill=pal["outline"], width=1)
    d.line([(0,230),(W,230)], fill=pal["wall_l"], width=1)
    # 木地板
    vgrad(d, (0,238,W,H), pal["floor_l"], pal["floor_d"])
    yy = 238
    row = 0
    while yy < H:
        d.line([(0,yy),(W,yy)], fill=pal["outline"], width=1)
        off = (row*53) % 96
        for x in range(-off, W, 96):
            d.line([(x,yy),(x-14,min(H,yy+22))], fill=pal["floor_d"], width=1)
        yy += 22; row += 1
    dither(d, (0,240,W,H), pal["floor_d"], 0.2, seed+50)
    stains(d, (0,30,W,190), pal["wall_d"], n=18, seed=seed)
    cracks(d, (0,24,W,190), pal, n=3, seed=seed+1)
    return img, d

def draw_window(d, pal, x, y, w, h, night=False, curtain=True):
    d.rectangle([x-8,y-8,x+w+8,y+h+8], fill=pal["outline"])
    d.rectangle([x-6,y-6,x+w+6,y+h+6], fill=pal["trim"])
    vgrad(d, (x,y,x+w,y+h), pal["light"], pal["wall_d"])
    # 窗外远景
    if night:
        vgrad(d, (x,y,x+w,y+h), (30,34,54), (14,16,28))
        d.ellipse([x+w-30,y+10,x+w-12,y+28], fill=(220,214,190))
    d.rectangle([x+w//2-2,y,x+w//2+2,y+h], fill=pal["trim"])
    d.rectangle([x,y+h//2-2,x+w,y+h//2+2], fill=pal["trim"])
    d.rectangle([x-8,y+h+6,x+w+8,y+h+12], fill=pal["trim"])  # 窗台
    if curtain:
        for cx in (x-12, x+w+2):
            d.polygon([(cx,y-10),(cx+10,y-10),(cx+8,y+h+8),(cx,y+h+2)], fill=(128,52,46) if not night else (40,48,72))
            d.line([(cx+3,y-4),(cx+2,y+h)], fill=pal["outline"], width=1)
        d.rectangle([x-14,y-12,x+w+14,y-6], fill=pal["trim"])

def draw_door(d, x, pal, y=84, w=64, h=154):
    d.rectangle([x-6, y-6, x+w+6, 238], fill=pal["outline"])
    d.rectangle([x-4, y-4, x+w+4, 238], fill=pal["trim"])
    d.rectangle([x, y, x+w, 238], fill=pal["door"])
    # 门板嵌板 + 高光
    orr(d, [x+9, y+12, x+w-9, y+72], pal["door_l"], pal["door_d"], 3)
    orr(d, [x+9, y+86, x+w-9, 224], pal["door_l"], pal["door_d"], 3)
    d.line([(x+2,y+2),(x+2,236)], fill=pal["door_l"], width=1)   # 左高光
    d.ellipse([x+w-16, 160, x+w-8, 168], fill=pal["light"], outline=pal["outline"])
    # 门牌底座
    d.rectangle([x+w//2-15, y-24, x+w//2+15, y-6], fill=pal["outline"])
    d.rectangle([x+w//2-13, y-22, x+w//2+13, y-8], fill=pal["paper"])

# ================= 场景 =================
def corridor(pal, name, seed, flicker=False):
    img, d = base_room(pal, seed=seed)
    for x, num in [(40,"101"), (170,"102"), (430,"103"), (560,"104")]:
        draw_door(d, x, pal)
    # 挂画/电表箱等细节
    orr(d, [262, 96, 316, 150], pal["paper"], pal["outline"], 2)          # 挂画
    d.polygon([(270,142),(288,112),(306,142)], fill=pal["wall_d"])       # 画中远山
    d.ellipse([296,104,306,114], fill=pal["light"])                       # 画中太阳
    orr(d, [346, 100, 386, 140], pal["trim"], pal["outline"], 2)          # 电表箱
    d.line([(352,112),(380,112)], fill=pal["outline"], width=1)
    d.line([(352,124),(380,124)], fill=pal["outline"], width=1)
    # 顶灯
    night = "night" in name
    for lx in (160, 320, 480):
        d.rectangle([lx-2, 0, lx+2, 16], fill=pal["outline"])
        d.polygon([(lx-18,32),(lx+18,32),(lx+9,16),(lx-9,16)], fill=pal["trim"])
        d.polygon([(lx-16,32),(lx+16,32),(lx+8,18),(lx-8,18)], outline=pal["outline"])
        on = not (flicker and lx==320)
        if on:
            d.ellipse([lx-9, 26, lx+9, 42], fill=pal["light"], outline=pal["outline"])
        else:
            d.ellipse([lx-9, 26, lx+9, 42], fill=pal["wall_d"], outline=pal["outline"])
    # 灯光光晕
    glow = Image.new("RGBA", (W,H), (0,0,0,0))
    gd = ImageDraw.Draw(glow)
    for lx in (160,320,480):
        on = not (flicker and lx==320)
        a = 34 if on else 8
        gd.ellipse([lx-80,18,lx+80,170], fill=pal["light"]+(a,))
        gd.ellipse([lx-46,20,lx+46,120], fill=pal["light"]+(a+14,))
    # 地面光池
    for lx in (160,320,480):
        on = not (flicker and lx==320)
        gd.ellipse([lx-60,246,lx+60,300], fill=pal["light"]+(26 if on else 6,))
    img = Image.alpha_composite(img, glow)
    noise_overlay(img, 8, seed)
    img.save(f"{OUT}/bg_{name}.png")

def admin_room():
    pal = DAY
    img, d = base_room(pal, seed=7)
    draw_window(d, pal, 470, 56, 110, 122)
    # 地毯
    orr(d, [120, 268, 420, 330], (146,74,58), pal["outline"], 6)
    orr(d, [136, 276, 404, 322], (168,92,70), (120,58,44), 4)
    for x in range(150, 400, 24):
        d.line([(x,282),(x,316)], fill=(146,74,58), width=2)
    # 办公桌
    d.rectangle([66,186,264,196], fill=pal["outline"])
    d.rectangle([68,184,262,194], fill=(104,70,42))
    d.rectangle([70,186,260,190], fill=(126,88,54))          # 桌面高光
    for lx in (76, 244):
        d.rectangle([lx,196,lx+10,268], fill=(86,56,34), outline=pal["outline"])
    d.rectangle([80,234,250,242], fill=(86,56,34), outline=pal["outline"])
    # 桌上物品：台灯/文件/电话/茶杯
    d.rectangle([96,168,106,184], fill=(44,40,36), outline=pal["outline"])
    d.polygon([(88,168),(114,168),(108,150),(94,150)], fill=(56,90,64))
    d.polygon([(88,168),(114,168),(108,150),(94,150)], outline=pal["outline"])
    d.ellipse([94,142,108,156], fill=(255,240,160))
    orr(d, [146,176,202,190], pal["paper"], pal["outline"], 1) # 文件堆
    d.line([(150,181),(198,181)], fill=(190,180,155))
    d.line([(150,185),(194,185)], fill=(190,180,155))
    orr(d, [212,164,246,188], (36,36,42), pal["outline"], 3)   # 电话
    d.rectangle([216,156,242,168], fill=(52,52,60), outline=pal["outline"])
    d.ellipse([218,170,240,184], outline=(80,80,90), width=2)
    d.ellipse([124,174,140,188], fill=(230,226,214), outline=pal["outline"])  # 茶杯
    d.arc([138,176,148,186], 300, 60, fill=pal["outline"], width=2)
    # 椅子（正面）
    d.rectangle([150,242,196,250], fill=(76,50,30), outline=pal["outline"])
    for lx in (154, 186):
        d.rectangle([lx,250,lx+6,282], fill=(62,40,26), outline=pal["outline"])
    d.rectangle([150,214,196,224], fill=(76,50,30), outline=pal["outline"])
    d.rectangle([156,224,160,242], fill=(62,40,26))
    d.rectangle([186,224,190,242], fill=(62,40,26))
    # 挂钟
    d.ellipse([298,58,346,106], fill=pal["outline"])
    d.ellipse([300,60,344,104], fill=(238,232,216))
    d.ellipse([303,63,341,101], outline=pal["trim"], width=1)
    d.line([(322,82),(322,66)], fill=pal["ink"], width=3)
    d.line([(322,82),(335,89)], fill=pal["ink"], width=2)
    d.ellipse([319,79,325,85], fill=pal["ink"])
    for ang in range(0,360,30):
        rad = math.radians(ang)
        d.line([(322+16*math.cos(rad),82+16*math.sin(rad)),(322+19*math.cos(rad),82+19*math.sin(rad))], fill=pal["trim"], width=1)
    # 日历
    d.rectangle([378,56,432,118], fill=pal["outline"])
    d.rectangle([380,58,430,116], fill=pal["paper"])
    d.rectangle([380,58,430,74], fill=(186,64,52))
    d.rectangle([380,74,430,76], fill=pal["outline"])
    for i in range(3):
        d.line([(386,84+i*9),(424,84+i*9)], fill=(200,190,165), width=1)
    # 文件柜
    d.rectangle([56,80,114,232], fill=pal["outline"])
    d.rectangle([58,82,112,230], fill=(100,82,60))
    for yy in range(88,224,36):
        orr(d, [64,yy,106,yy+30], (112,94,70), pal["outline"], 2)
        d.rectangle([78,yy+12,92,yy+17], fill=(160,140,108), outline=pal["outline"])
    # 公告板
    d.rectangle([248,126,342,192], fill=pal["outline"])
    d.rectangle([250,128,340,190], fill=(154,114,72))
    rnd = random.Random(5)
    for _ in range(8):
        nx, ny = rnd.randint(256,320), rnd.randint(134,172)
        col = rnd.choice([(240,230,200),(232,222,150),(220,235,225),(235,215,215)])
        d.rectangle([nx,ny,nx+15,ny+13], fill=col, outline=pal["outline"])
        d.ellipse([nx+6,ny+1,nx+9,ny+4], fill=(160,50,40))       # 图钉
    # 书架（右侧）
    d.rectangle([586,120,636,232], fill=pal["outline"])
    d.rectangle([588,122,634,230], fill=(96,66,40))
    for yy in (150, 180, 210):
        d.rectangle([588,yy,634,yy+4], fill=(76,52,32))
    rnd2 = random.Random(8)
    for yy,hh in ((128,20),(158,20),(188,20)):
        x = 592
        while x < 626:
            bw = rnd2.randint(5,9)
            col = rnd2.choice([(150,60,50),(60,90,130),(90,120,70),(180,140,60),(120,70,110)])
            d.rectangle([x,yy+20-hh+ (20-hh), x+bw, yy+20], fill=col, outline=pal["outline"])
            x += bw+1
    noise_overlay(img, 8, 7)
    img.save(f"{OUT}/bg_admin_room.png")

def room104(pal, name, seed):
    red = "red" in name
    img, d = base_room(pal, seed=seed)
    draw_window(d, pal, 500, 46, 100, 116, night=red)
    # 血迹从天花板流下（仅红版）
    if red:
        rnd3 = random.Random(seed+30)
        for _ in range(16):
            bx = rnd3.randint(10, 630)
            ln = rnd3.randint(20, 120)
            wd = rnd3.randint(2, 6)
            d.line([(bx, 0), (bx+ rnd3.randint(-6,6), ln)], fill=(60,8,8), width=wd)
            d.ellipse([bx-2, ln-3, bx+3, ln+3], fill=(60,8,8))
    # 床（带床头板、被子褶皱、高光）
    d.rectangle([36,148,50,238], fill=pal["outline"])                      # 床头板
    d.rectangle([38,150,48,236], fill=pal["door"])
    d.rectangle([50,178,232,238], fill=pal["outline"])
    d.rectangle([52,180,230,238], fill=pal["door_d"])
    orr(d, [56,162,96,190], pal["paper"], pal["outline"], 4)               # 枕头
    d.line([(60,176),(92,176)], fill=pal["wall_d"], width=1)
    d.rectangle([56,192,228,232], fill=pal["wall_d"])                      # 被子
    d.rectangle([56,192,228,196], fill=pal["wall_l"])
    for i in range(6):                                                     # 褶皱
        x = 68+i*26
        d.line([(x,198),(x-4,228)], fill=pal["outline"], width=1)
        d.line([(x+2,198),(x-2,228)], fill=pal["wall_l"], width=1)
    if red:                                                                 # 被子上的血渍
        stains(d, (120,196,220,230), (70,10,10), n=8, seed=seed+40)
    # 床头柜 + 收音机 + 病历
    d.rectangle([240,190,292,238], fill=pal["outline"])
    d.rectangle([242,192,290,238], fill=pal["door"])
    orr(d, [246,198,286,214], pal["door_l"], pal["door_d"], 2)
    d.ellipse([262,220,272,228], fill=pal["light"], outline=pal["outline"])
    d.rectangle([246,166,284,190], fill=(42,38,36), outline=pal["outline"])   # 收音机
    d.ellipse([250,170,262,182], fill=(96,92,86), outline=(20,18,16))
    d.rectangle([266,172,280,180], fill=(70,66,62))
    d.line([(278,166),(290,148)], fill=(120,116,110), width=2)                # 天线
    # 衣柜（带顶线脚、镜面高光）
    d.rectangle([326,64,434,238], fill=pal["outline"])
    d.rectangle([328,66,432,238], fill=pal["door"])
    d.rectangle([324,60,436,70], fill=pal["outline"])                        # 顶线脚
    d.rectangle([326,62,434,68], fill=pal["door_l"])
    d.line([(380,68),(380,238)], fill=pal["outline"], width=2)
    for xx in (334, 386):                                                     # 柜门面板
        orr(d, [xx, 84, xx+40, 150], pal["door_l"], pal["door_d"], 2)
        orr(d, [xx, 164, xx+40, 226], pal["door_l"], pal["door_d"], 2)
    d.ellipse([368,152,376,160], fill=pal["light"], outline=pal["outline"])
    d.ellipse([386,152,394,160], fill=pal["light"], outline=pal["outline"])
    # 穿衣镜（雕花边框感）
    d.rectangle([448,74,490,238], fill=pal["outline"])
    d.rectangle([450,76,488,238], fill=(120,88,50) if not red else (60,14,14))
    vgrad(d, (456,84,482,232), pal["paper"], pal["wall_d"])
    d.line([(456,84),(482,232)], fill=pal["wall_l"], width=2)               # 镜面反光
    d.line([(462,84),(482,180)], fill=pal["wall_l"], width=1)
    # 浴室门（虚掩，透出黑暗）
    d.rectangle([552,172,636,238], fill=pal["outline"])
    d.rectangle([554,174,634,238], fill=(10,6,6) if red else (30,26,24))
    d.rectangle([556,176,600,238], fill=pal["door_d"])                       # 半开的门扇
    d.line([(600,176),(600,238)], fill=pal["outline"], width=2)
    # 满墙便利贴
    rnd2 = random.Random(seed+9)
    for _ in range(26):
        nx = rnd2.randint(100, 312); ny = rnd2.randint(42, 150)
        nw, nh = rnd2.randint(8,15), rnd2.randint(8,15)
        col = rnd2.choice([(196,120,110),(186,105,100),(206,132,112)]) if red else \
              rnd2.choice([(240,228,170),(236,220,190),(230,214,178)])
        d.rectangle([nx,ny,nx+nw,ny+nh], fill=col, outline=pal["outline"])
        d.line([(nx+2,ny+3),(nx+nw-2,ny+3)], fill=(90,50,45), width=1)
        d.line([(nx+2,ny+6),(nx+nw-3,ny+6)], fill=(90,50,45), width=1)
    # 地面血泊轨迹（红版：从床到浴室）
    if red:
        rnd4 = random.Random(seed+60)
        for i in range(10):
            t = i/9
            cx = int(200 + (580-200)*t) + rnd4.randint(-14,14)
            cy = int(250 + (292-250)*t) + rnd4.randint(-8,8)
            r = rnd4.randint(3, 9) + (4 if i>7 else 0)
            d.ellipse([cx-r,cy-r//2,cx+r,cy+r//2], fill=(64,8,8))
    # 杂物
    rnd = random.Random(seed+3)
    for _ in range(12):
        cx, cy = rnd.randint(60,600), rnd.randint(252,336)
        w2, h2 = rnd.randint(6,18), rnd.randint(4,10)
        col = rnd.choice([pal["paper"], pal["wall_d"], pal["door_d"]])
        d.rectangle([cx,cy,cx+w2,cy+h2], fill=col, outline=pal["outline"])
    noise_overlay(img, 9, seed)
    img.save(f"{OUT}/bg_{name}.png")

def title_bg():
    img = Image.new("RGBA", (W,H), (0,0,0,255))
    d = ImageDraw.Draw(img)
    vgrad(d,(0,0,W,H), (56,42,76), (16,12,28))
    # 星星
    rnd = random.Random(9)
    for _ in range(60):
        x, y = rnd.randint(0,W), rnd.randint(0,200)
        d.point([(x,y)], fill=(200,200,220) if rnd.random()<0.7 else (255,240,200))
    # 月亮 + 光晕
    d.ellipse([496,36,568,108], fill=(240,234,210))
    d.ellipse([508,46,544,84], fill=(222,216,192))
    d.ellipse([530,70,552,94], fill=(230,224,200))
    glow = Image.new("RGBA",(W,H),(0,0,0,0))
    ImageDraw.Draw(glow).ellipse([460,0,604,144], fill=(240,234,210,26))
    img = Image.alpha_composite(img, glow)
    # 楼体
    bx0, bx1, by = 210, 430, 330
    d.rectangle([bx0-8,52,bx1+8,by], fill=(8,7,12))
    d.rectangle([bx0,60,bx1,by], fill=(14,12,20))
    d.rectangle([bx0,60,bx1,64], fill=(24,20,30))
    for fy in range(6):
        for fx in range(4):
            x = bx0+18+fx*50; y = 78+fy*44
            lit = rnd.random() < 0.3
            col = (214,176,96) if lit else (30,28,40)
            d.rectangle([x-2,y-2,x+28,y+26], fill=(6,5,10))
            d.rectangle([x,y,x+26,y+24], fill=col)
            if lit:
                d.line([(x,y+12),(x+26,y+12)], fill=(160,128,70), width=1)
                d.line([(x+13,y),(x+13,y+24)], fill=(160,128,70), width=1)
    # 104 红光窗
    d.rectangle([bx0+18+3*50, 78+4*44, bx0+18+3*50+26, 78+4*44+24], fill=(198,46,40))
    d.rectangle([bx0+18+3*50-2, 78+4*44-2, bx0+18+3*50+28, 78+4*44+26], outline=(120,20,18), width=2)
    rglow = Image.new("RGBA",(W,H),(0,0,0,0))
    ImageDraw.Draw(rglow).ellipse([bx0+18+3*50-26, 78+4*44-26, bx0+18+3*50+52, 78+4*44+52], fill=(198,46,40,40))
    img = Image.alpha_composite(img, rglow)
    # 地面与树
    d.rectangle([0,by,W,H], fill=(7,6,11))
    for tx in (110, 520):
        d.line([(tx,by),(tx+10,234)], fill=(6,6,10), width=8)
        d.ellipse([tx-30,198,tx+48,256], fill=(9,9,14))
        d.ellipse([tx-18,186,tx+36,228], fill=(11,11,17))
    # 门前路灯
    d.line([(320,by),(320,282)], fill=(20,18,26), width=4)
    d.ellipse([312,272,328,288], fill=(230,210,140))
    lglow = Image.new("RGBA",(W,H),(0,0,0,0))
    ImageDraw.Draw(lglow).ellipse([280,260,360,340], fill=(230,210,140,30))
    img = Image.alpha_composite(img, lglow)
    noise_overlay(img, 7, 11)
    img.save(f"{OUT}/bg_title.png")

# ================= Q版角色 =================
def chibi_head(d, x, y, skin, hair, face, outline):
    """24宽画幅内 x=0 起：头14宽12高。face: down/left/right/up"""
    hx, hy = x+5, y+1
    # 头形（圆角）
    d.rounded_rectangle([hx-1,hy-1,hx+15,hy+13], radius=4, fill=outline)
    d.rounded_rectangle([hx,hy,hx+14,hy+12], radius=3, fill=skin)
    # 头发
    if face == "up":
        d.rounded_rectangle([hx,hy,hx+14,hy+10], radius=3, fill=hair)
        d.rectangle([hx,hy+8,hx+14,hy+11], fill=hair)
    else:
        d.rounded_rectangle([hx,hy,hx+14,hy+6], radius=3, fill=hair)
        d.rectangle([hx,hy+4,hx+2,hy+9], fill=hair)      # 鬓角
        d.rectangle([hx+12,hy+4,hx+14,hy+9], fill=hair)
        if face == "down":
            d.rectangle([hx+2,hy+5,hx+12,hy+6], fill=hair)   # 刘海
    # 眼睛
    if face == "down":
        for ex in (hx+3, hx+9):
            d.rectangle([ex,hy+7,ex+2,hy+9], fill=(26,22,20))
            d.point([(ex+2,hy+7)], fill=(255,255,255))       # 高光
        d.point([(hx+6,hy+11),(hx+8,hy+11)], fill=(180,120,110))  # 嘴
    elif face == "left":
        d.rectangle([hx+2,hy+7,hx+4,hy+9], fill=(26,22,20))
        d.point([(hx+4,hy+7)], fill=(255,255,255))
    elif face == "right":
        d.rectangle([hx+10,hy+7,hx+12,hy+9], fill=(26,22,20))
        d.point([(hx+12,hy+7)], fill=(255,255,255))

def player_frames():
    """24x32 Q版 4方向x4帧"""
    FW, FH = 24, 32
    sheet = Image.new("RGBA", (FW*4, FH*4), (0,0,0,0))
    skin=(236,198,160); hair=(40,32,30); jacket=(78,102,84); jacket_d=(60,80,66)
    jacket_l=(96,122,100); pants=(56,60,72); shoes=(34,32,30); outline=(30,26,24)
    dirs = ["down","left","right","up"]
    for dr, face in enumerate(dirs):
        for f in range(4):
            ox, oy = f*FW, dr*FH
            s, d = new_sprite(FW,FH)
            # 步态：0/2 交替抬腿，1/3 过渡
            swing = [-2, 0, 2, 0][f]
            bob = [0, -1, 0, -1][f]
            y0 = bob
            # 腿
            leg_l = 7 - swing; leg_r = 13 + swing
            d.rectangle([leg_l-2,24+y0,leg_l+1,29+y0+ (1 if f==1 else 0)], fill=outline)
            d.rectangle([leg_l-1,24+y0,leg_l,29+y0], fill=pants)
            d.rectangle([leg_r,24+y0,leg_r+3,29+y0+(1 if f==3 else 0)], fill=outline)
            d.rectangle([leg_r+1,24+y0,leg_r+2,29+y0], fill=pants)
            # 鞋
            d.rectangle([leg_l-3,29+y0,leg_l+2,31+y0], fill=shoes)
            d.rectangle([leg_r-1,29+y0,leg_r+4,31+y0], fill=shoes)
            # 身体（管理员夹克）
            d.rounded_rectangle([4,13+y0,20,25+y0], radius=3, fill=outline)
            d.rounded_rectangle([5,14+y0,19,24+y0], radius=2, fill=jacket)
            d.rectangle([5,14+y0,7,24+y0], fill=jacket_d)      # 左阴影
            d.rectangle([8,15+y0,16,16+y0], fill=jacket_l)     # 胸高光
            d.rectangle([11,16+y0,13,24+y0], fill=jacket_d)    # 前襟
            # 手臂摆动
            arm = [-1, 0, 1, 0][f]
            d.rectangle([2,15+y0+arm,4,22+y0+arm], fill=outline)
            d.rectangle([3,15+y0+arm,4,21+y0+arm], fill=jacket_d)
            d.rectangle([20,15+y0-arm,22,22+y0-arm], fill=outline)
            d.rectangle([20,15+y0-arm,21,21+y0-arm], fill=jacket)
            d.point([(3,22+y0+arm)], fill=skin)
            d.point([(20,22+y0-arm)], fill=skin)
            chibi_head(d, 0, y0, skin, hair, face, outline)
            sheet.paste(s, (ox,oy))
    sheet.save(f"{OUT}/player_walk.png")

def ghost_red_dress():
    """红裙子 Q版 24x36：常态/转头微笑/治愈白衣鞠躬"""
    FW, FH = 24, 36
    sheet = Image.new("RGBA", (FW*3, FH), (0,0,0,0))
    hair=(20,14,16); dress=(176,36,38); dress_d=(136,22,24); dress_l=(200,56,56)
    skin=(232,222,212); outline=(24,16,16)
    for state in range(3):
        s, d = new_sprite(FW,FH)
        dr_ds, dr_dl = dress, dress_l
        sk = skin
        if state == 2:
            dr_ds, dr_dl = (240,236,228), (250,246,240)
            dress_d = (216,210,200)
        # 裙摆
        d.polygon([(7,16),(17,16),(21,34),(3,34)], fill=outline)
        d.polygon([(8,16),(16,16),(20,33),(4,33)], fill=dr_ds)
        d.polygon([(11,16),(13,16),(10,33),(7,33)], fill=dress_d)     # 裙褶
        d.polygon([(15,16),(16,16),(17,33),(14,33)], fill=dr_dl)      # 褶高光
        # 上身
        d.rounded_rectangle([7,11,17,18], radius=2, fill=outline)
        d.rounded_rectangle([8,12,16,17], radius=1, fill=dr_ds)
        # 手臂
        if state == 2:   # 鞠躬：双手在身前交叠
            d.rectangle([9,14,15,21], fill=sk)
            d.rectangle([9,14,15,16], fill=outline)
            d.rectangle([10,15,14,20], fill=sk)
        else:
            d.rectangle([4,13,6,22], fill=outline)
            d.rectangle([5,13,6,21], fill=sk)
            d.rectangle([18,13,20,22], fill=outline)
            d.rectangle([18,13,19,21], fill=sk)
        # 头
        d.rounded_rectangle([5,1,19,12], radius=4, fill=outline)
        d.rounded_rectangle([6,2,18,11], radius=3, fill=sk)
        # 长发
        d.rounded_rectangle([5,0,19,6], radius=3, fill=hair)
        d.rectangle([4,4,7,20], fill=hair)      # 左侧垂发
        d.rectangle([17,4,20,20], fill=hair)    # 右侧
        if state == 0:                          # 前发遮面
            d.rectangle([7,4,17,10], fill=hair)
            d.rectangle([8,10,16,11], fill=hair)
        elif state == 1:                        # 转头微笑
            d.rectangle([8,6,10,8], fill=(12,10,10))
            d.rectangle([14,6,16,8], fill=(12,10,10))
            d.rectangle([10,9,14,10], fill=(150,30,34))
            d.point([(9,8),(15,8)], fill=(150,30,34))
        else:                                   # 治愈：安详
            d.rectangle([8,6,10,8], fill=(12,10,10))
            d.rectangle([14,6,16,8], fill=(12,10,10))
            d.point([(11,10),(13,10)], fill=(190,130,120))
        sheet.paste(s, (FW*state, 0))
    sheet.save(f"{OUT}/ghost_104.png")

def npc_wang():
    """王大妈 Q版 24x32"""
    s, d = new_sprite(24,32)
    skin=(232,196,162); hair=(158,154,148); coat=(152,92,100); coat_d=(124,72,80)
    apron=(226,220,204); pants=(74,66,60); outline=(34,28,26)
    # 腿鞋
    d.rectangle([8,24,11,29], fill=outline); d.rectangle([9,24,10,29], fill=pants)
    d.rectangle([13,24,16,29], fill=outline); d.rectangle([14,24,15,29], fill=pants)
    d.rectangle([7,29,12,31], fill=(44,40,36)); d.rectangle([12,29,17,31], fill=(44,40,36))
    # 身体
    d.rounded_rectangle([4,13,20,26], radius=3, fill=outline)
    d.rounded_rectangle([5,14,19,25], radius=2, fill=coat)
    d.rectangle([5,14,7,25], fill=coat_d)
    # 围裙
    d.polygon([(9,16),(15,16),(17,25),(7,25)], fill=apron)
    d.line([(8,21),(16,21)], fill=(190,184,168), width=1)
    # 手臂
    d.rectangle([2,15,4,22], fill=outline); d.rectangle([3,15,4,21], fill=coat_d)
    d.rectangle([20,15,22,22], fill=outline); d.rectangle([20,15,21,21], fill=coat)
    # 头 + 发髻
    d.rounded_rectangle([5,1,19,13], radius=4, fill=outline)
    d.rounded_rectangle([6,2,18,12], radius=3, fill=skin)
    d.rounded_rectangle([6,1,18,6], radius=3, fill=hair)
    d.ellipse([9,-1,15,5], fill=hair, outline=outline)      # 发髻
    d.rectangle([6,4,7,9], fill=hair); d.rectangle([17,4,18,9], fill=hair)
    for ex in (9, 14):
        d.rectangle([ex,7,ex+1,9], fill=(30,24,20))
    d.point([(11,11),(13,11)], fill=(170,110,100))
    s.save(f"{OUT}/npc_wang.png")

# ================= 物品图标 =================
def item_icons():
    def save(img, name): img.save(f"{OUT}/item_{name}.png")
    OL = (40,32,28)
    s,d = new_sprite(24,24)
    d.rectangle([4,3,20,21], fill=(240,230,150), outline=OL); d.rectangle([4,3,20,6], fill=(220,205,120))
    for i in range(4): d.line([(7,9+i*3),(17,9+i*3)], fill=(120,60,60), width=1)
    save(s,"sticky")
    s,d = new_sprite(24,24)
    d.rectangle([5,2,19,22], fill=(238,236,230), outline=OL); d.rectangle([5,2,19,6], fill=(200,220,235))
    d.rectangle([10,8,14,16], fill=(200,60,60)); d.rectangle([8,10,16,14], fill=(200,60,60))
    for i in range(2): d.line([(8,18+i*2),(16,18+i*2)], fill=(120,120,120))
    save(s,"medical")
    s,d = new_sprite(24,24)
    d.line([(12,2),(12,5)], fill=(150,150,150), width=1); d.line([(7,5),(17,5)], fill=(150,150,150), width=1)
    d.polygon([(7,5),(17,5),(20,21),(4,21)], fill=(168,32,34), outline=OL)
    d.polygon([(11,5),(13,5),(15,21),(9,21)], fill=(128,20,22))
    d.rectangle([5,19,10,21], fill=(110,50,30))
    save(s,"dress")
    s,d = new_sprite(24,24)
    d.rectangle([8,3,16,21], fill=(30,30,34), outline=OL); d.rectangle([9,5,15,17], fill=(70,110,140))
    d.ellipse([11,18,13,20], fill=(90,90,96))
    save(s,"phone")
    s,d = new_sprite(24,24)
    d.ellipse([5,5,19,19], fill=(190,40,40), outline=OL); d.ellipse([7,7,17,17], fill=(160,28,28))
    for px,py in [(10,10),(14,10),(10,14),(14,14)]: d.ellipse([px-1,py-1,px+1,py+1], fill=(240,220,210))
    save(s,"button")
    s,d = new_sprite(24,24)
    d.rectangle([6,8,18,16], fill=(60,140,70), outline=OL); d.rectangle([18,10,21,14], fill=(90,90,90), outline=OL)
    d.rectangle([8,10,14,14], fill=(220,220,90))
    save(s,"battery")
    s,d = new_sprite(24,24)
    d.ellipse([4,8,12,16], outline=(210,190,120), width=2)
    d.line([(12,12),(20,12)], fill=(210,190,120), width=2)
    d.line([(17,12),(17,15)], fill=(210,190,120), width=2); d.line([(20,12),(20,15)], fill=(210,190,120), width=2)
    save(s,"key")
    # 互动提示 E（圆角气泡）
    s,d = new_sprite(20,20)
    d.rounded_rectangle([1,1,19,17], radius=5, fill=(16,20,30,235), outline=(220,222,230))
    d.polygon([(8,17),(12,17),(10,19)], fill=(16,20,30,235))
    save(s,"prompt_e")

# ================= UI =================
def ui_assets():
    img = Image.new("RGBA",(420,300),(0,0,0,255))
    d = ImageDraw.Draw(img)
    vgrad(d,(0,0,420,300),(234,224,198),(214,202,172))
    d.rectangle([0,0,420,300], outline=(120,100,70), width=4)
    d.rectangle([4,4,416,296], outline=(180,160,120), width=1)
    d.line([(210,6),(210,294)], fill=(180,168,138), width=2)
    for y in range(40,290,18):
        d.line([(16,y),(196,y)], fill=(190,180,150))
        d.line([(224,y),(404,y)], fill=(190,180,150))
    # 书脊装订环
    for y in range(30, 290, 30):
        d.ellipse([204,y,216,y+10], outline=(120,100,70), width=2)
    noise_overlay(img, 7, 21)
    img.save(f"{OUT}/ui_journal.png")

def new_sprite(w, h):
    img = Image.new("RGBA", (w,h), (0,0,0,0))
    return img, ImageDraw.Draw(img)

if __name__ == "__main__":
    corridor(DAY, "corridor_day", 101)
    corridor(NIGHT, "corridor_night", 102, flicker=True)
    admin_room()
    room104(RED, "room104_red", 201)
    room104(WHITE, "room104_white", 202)
    title_bg()
    player_frames()
    ghost_red_dress()
    npc_wang()
    item_icons()
    ui_assets()
    print("v2 done")
