# 《死楼》新增贴图生成：Day2-7 角色脸 / 门牌 / 符咒 / 蝴蝶 / 彩蛋
from PIL import Image, ImageDraw, ImageFont
import os, math, random

OUT = "dead_building/assets/tex"
os.makedirs(OUT, exist_ok=True)

FONT = None
FONT_B = None
def _fonts():
    global FONT, FONT_B
    if FONT: return
    for p in ["dead_building/assets/fonts/NotoSansSC-Regular.ttf",
              "C:/Windows/Fonts/msyh.ttc", "C:/Windows/Fonts/simhei.ttf"]:
        if os.path.exists(p):
            FONT = p; break
    for p in ["dead_building/assets/fonts/NotoSansSC-Bold.ttf",
              "C:/Windows/Fonts/msyhbd.ttc", "C:/Windows/Fonts/simhei.ttf"]:
        if os.path.exists(p):
            FONT_B = p; break
def fnt(size, bold=False):
    _fonts()
    return ImageFont.truetype(FONT_B if bold else FONT, size)

def ctext(d, xy, s, size, fill, bold=False, anchor="mm"):
    d.text(xy, s, font=fnt(size, bold), fill=fill, anchor=anchor)

# ---------- 门牌 ----------
def doorplate(num):
    img = Image.new("RGBA", (96, 48), (38, 32, 26, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([3, 3, 92, 44], outline=(180, 150, 90, 255), width=2)
    ctext(d, (48, 25), num, 26, (235, 215, 170), True)
    img.save(f"{OUT}/plate_{num}.png")

# ---------- 角色脸（64x64，透明底，Q版） ----------
def face_base(skin=(242, 214, 190, 255)):
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([6, 6, 58, 58], fill=skin)
    return img, d

def chen_face(smile=False):
    # 外卖员小陈：晒黑、胡茬、亮眼睛
    img, d = face_base((205, 165, 128, 255))
    d.ellipse([18, 26, 26, 33], fill=(20, 20, 25, 255))   # 眼
    d.ellipse([38, 26, 46, 33], fill=(20, 20, 25, 255))
    d.ellipse([20, 27, 23, 30], fill=(255, 255, 255, 255)) # 高光（眼睛很亮）
    d.ellipse([40, 27, 43, 30], fill=(255, 255, 255, 255))
    for x in range(16, 50, 3):                              # 胡茬
        d.line([x, 46, x, 49], fill=(120, 95, 70, 180), width=1)
    if smile:
        d.arc([22, 34, 42, 52], 20, 160, fill=(90, 40, 30, 255), width=3)  # 大笑
    else:
        d.arc([24, 36, 40, 48], 30, 150, fill=(90, 40, 30, 255), width=2)
    img.save(f"{OUT}/chen_face{'_smile' if smile else ''}.png")

def jia_face(cry=False):
    # 商人老贾：油光、小眼睛、永远在笑
    img, d = face_base((238, 205, 175, 255))
    d.ellipse([14, 10, 24, 16], fill=(255, 255, 255, 90))   # 油光
    d.ellipse([18, 26, 24, 30], fill=(25, 20, 20, 255))     # 小眼睛
    d.ellipse([40, 26, 46, 30], fill=(25, 20, 20, 255))
    d.arc([18, 30, 46, 54], 15, 165, fill=(120, 50, 40, 255), width=3)  # 笑
    d.arc([20, 33, 44, 52], 20, 160, fill=(150, 70, 55, 255), width=2)
    if cry:
        d.polygon([(20, 31), (23, 31), (21, 48)], fill=(200, 30, 30, 220))  # 红泪
        d.polygon([(42, 31), (45, 31), (43, 48)], fill=(200, 30, 30, 220))
    img.save(f"{OUT}/jia_face{'_cry' if cry else ''}.png")

def prev_face():
    # 前管理员：疲惫但善良（像玩家）
    img, d = face_base((235, 205, 180, 255))
    d.ellipse([17, 25, 26, 32], fill=(30, 30, 35, 255))
    d.ellipse([38, 25, 47, 32], fill=(30, 30, 35, 255))
    d.arc([16, 22, 27, 27], 180, 350, fill=(80, 60, 50, 255), width=2)  # 疲惫眉
    d.arc([37, 22, 48, 27], 190, 360, fill=(80, 60, 50, 255), width=2)
    d.ellipse([17, 33, 26, 36], fill=(150, 130, 120, 120))  # 眼袋
    d.ellipse([38, 33, 47, 36], fill=(150, 130, 120, 120))
    d.arc([24, 38, 40, 48], 40, 140, fill=(100, 60, 50, 255), width=2)  # 苦笑
    img.save(f"{OUT}/prev_face.png")

def wang_face_day4():
    pass

# ---------- 身体（正面贴片 96x192） ----------
def chen_body():
    img = Image.new("RGBA", (96, 192), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([14, 10, 82, 188], 16, fill=(225, 175, 40, 255))  # 黄外卖服
    d.rectangle([40, 10, 56, 60], fill=(240, 240, 235, 255))              # 衬衫领口
    for x, y, w in [(20, 90, 8), (66, 120, 10), (30, 150, 6)]:            # 油渍
        d.ellipse([x, y, x + w, y + w], fill=(120, 90, 40, 160))
    d.ellipse([60, 60, 82, 82], fill=(90, 60, 40, 120))                   # 褐色手印
    ctext(d, (48, 168), "五星好评", 13, (90, 60, 20), True)
    img.save(f"{OUT}/chen_body.png")

def jia_body():
    img = Image.new("RGBA", (96, 192), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([8, 10, 88, 188], 22, fill=(105, 105, 110, 255))  # 灰西装
    d.polygon([(42, 12), (54, 12), (50, 70), (46, 70)], fill=(235, 230, 215, 255))  # 发黄衬衫
    d.line([48, 14, 48, 60], fill=(150, 60, 50, 255), width=4)            # 领带
    d.ellipse([26, 120, 70, 186], fill=(112, 112, 118, 255))              # 大肚子
    d.arc([30, 100, 66, 160], 300, 240, fill=(80, 80, 85, 255), width=3)  # 绷不住的扣子线
    img.save(f"{OUT}/jia_body.png")

def prev_body():
    img = Image.new("RGBA", (96, 192), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([16, 10, 80, 188], 14, fill=(45, 60, 85, 255))    # 深蓝工装
    d.rectangle([38, 10, 58, 50], fill=(120, 120, 125, 255))              # 灰卫衣
    d.rectangle([20, 40, 38, 56], outline=(150, 140, 110, 200), width=2)  # 褪色logo框
    ctext(d, (29, 48), "幸福苑", 8, (150, 140, 110))
    for i in range(30):                                                    # 旧脏
        x, y = random.randint(18, 78), random.randint(60, 185)
        d.point((x, y), fill=(30, 35, 45, 120))
    img.save(f"{OUT}/prev_body.png")

def doorgod_body():
    # 无头门神：深绿保安制服 + 44把钥匙 + 优秀员工徽章
    img = Image.new("RGBA", (96, 192), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([12, 4, 84, 190], 12, fill=(40, 70, 48, 255))
    d.rectangle([12, 20, 84, 26], fill=(30, 55, 36, 255))                 # 肩章线
    d.rectangle([58, 12, 78, 20], fill=(70, 95, 65, 255))
    d.ellipse([18, 30, 34, 46], fill=(200, 170, 60, 255))                 # 徽章
    ctext(d, (26, 38), "优", 10, (90, 60, 20), True)
    random.seed(44)
    for i in range(44):                                                    # 44 把钥匙
        x = 14 + (i % 11) * 6
        y = 120 + (i // 11) * 14
        d.ellipse([x, y, x + 4, y + 6], outline=(190, 180, 120, 220), width=1)
        d.line([x + 2, y + 6, x + 2, y + 10], fill=(190, 180, 120, 220), width=1)
    img.save(f"{OUT}/doorgod_body.png")

# ---------- 特效贴图 ----------
def butterfly():
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for sx in [0, 1]:  # 左右翅膀
        cx = 18 if sx == 0 else 46
        d.ellipse([cx - 14, 10, cx + 10, 36], fill=(60, 30, 80, 235))
        d.ellipse([cx - 12, 34, cx + 8, 52], fill=(45, 22, 60, 235))
        d.ellipse([cx - 8, 16, cx + 4, 30], fill=(220, 210, 190, 255))    # 眼睛图案
        d.ellipse([cx - 5, 19, cx + 1, 27], fill=(20, 10, 25, 255))
    d.line([32, 14, 32, 50], fill=(25, 15, 30, 255), width=3)
    d.line([32, 14, 26, 6], fill=(25, 15, 30, 255), width=1)
    d.line([32, 14, 38, 6], fill=(25, 15, 30, 255), width=1)
    img.save(f"{OUT}/butterfly.png")

def talisman():
    img = Image.new("RGBA", (48, 128), (215, 190, 120, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([2, 2, 45, 125], outline=(150, 40, 30, 255), width=2)
    ctext(d, (24, 26), "守门", 20, (150, 30, 25), True)
    ctext(d, (24, 56), "封邪", 20, (150, 30, 25), True)
    d.line([10, 80, 38, 80], fill=(150, 30, 25, 255), width=2)
    for i in range(3):
        d.arc([10 + i * 4, 88, 38 - i * 4, 112], 0, 300, fill=(150, 30, 25, 255), width=2)
    img.save(f"{OUT}/talisman.png")

def graffiti4():
    img = Image.new("RGBA", (256, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    random.seed(4)
    for i in range(18):
        x, y = random.randint(10, 220), random.randint(5, 100)
        s = random.randint(18, 44)
        ctext(d, (x, y), "4", s, (25, 22, 22, 220), True)
    ctext(d, (128, 96), "不要开门", 30, (120, 20, 18, 240), True)
    img.save(f"{OUT}/graffiti4.png")

def poster_missing():
    img = Image.new("RGBA", (96, 128), (225, 218, 200, 255))
    d = ImageDraw.Draw(img)
    ctext(d, (48, 14), "寻人启事", 16, (30, 30, 30), True)
    d.rectangle([28, 26, 68, 66], fill=(180, 175, 165, 255))              # 照片位
    d.ellipse([38, 32, 58, 52], fill=(140, 135, 125, 255))                # 人影
    d.rectangle([40, 52, 56, 66], fill=(140, 135, 125, 255))
    for i in range(4):
        d.line([12, 78 + i * 10, 84, 78 + i * 10], fill=(80, 80, 80, 255), width=2)
    ctext(d, (48, 122), "幸福苑管理处", 8, (100, 100, 100))
    img.save(f"{OUT}/poster_missing.png")

def receipts():
    # 214 冰箱外卖单墙
    img = Image.new("RGBA", (256, 192), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    random.seed(30)
    for i in range(30):
        x, y = (i % 6) * 42 + 4, (i // 6) * 38 + 4
        d.rectangle([x, y, x + 36, y + 32], fill=(240, 235, 220, 255), outline=(160, 150, 130, 255))
        ctext(d, (x + 18, y + 8), "外卖单", 8, (60, 60, 60))
        ctext(d, (x + 18, y + 18), "林先生", 8, (120, 40, 30))
        ctext(d, (x + 18, y + 27), "→404", 8, (120, 40, 30), True)
    img.save(f"{OUT}/receipts.png")

def moneywall():
    # 334 冥币堆
    img = Image.new("RGBA", (256, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    random.seed(9)
    for i in range(40):
        x, y = random.randint(0, 220), random.randint(0, 100)
        a = random.uniform(-0.3, 0.3)
        d.rectangle([x, y, x + 34, y + 16], fill=(200, 185, 130, 230), outline=(120, 100, 60, 255))
        ctext(d, (x + 17, y + 8), "冥通银行", 6, (90, 30, 30))
    img.save(f"{OUT}/moneywall.png")

def calendar_floor():
    # 404 地板日历 Day1-365
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i in range(12):
        ctext(d, (24 + (i % 4) * 60, 24 + (i // 4) * 60), f"D{i+1}", 18, (30, 28, 28, 200), True)
    ctext(d, (128, 220), "……第365天，然后重来", 14, (120, 25, 22, 230))
    img.save(f"{OUT}/calendar_floor.png")

# ---------- 彩蛋 ----------
def egg_4wd():
    # 迷你四驱车（四驱兄弟梗）：红蓝车身 + 冲锋战神
    img = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(14, 40), (30, 22), (98, 22), (114, 40)], fill=(200, 40, 40, 255))   # 车身
    d.polygon([(36, 22), (48, 12), (80, 12), (92, 22)], fill=(60, 90, 200, 255))    # 车盖
    for x in [24, 96]:                                                                # 轮
        d.ellipse([x, 38, x + 18, 56], fill=(30, 30, 30, 255))
        d.ellipse([x + 5, 43, x + 13, 51], fill=(160, 160, 160, 255))
    ctext(d, (64, 34), "冲锋战神", 11, (255, 240, 200), True)
    ctext(d, (64, 56), "冲吧——！", 9, (255, 255, 255))
    img.save(f"{OUT}/egg_4wd.png")

def egg_huawei():
    # 华为手机盒：花瓣 logo + HUAWEI
    img = Image.new("RGBA", (96, 96), (245, 245, 248, 255))
    d = ImageDraw.Draw(img)
    for i in range(8):  # 花瓣
        a = math.radians(i * 45)
        cx, cy = 48 + math.sin(a) * 14, 40 - math.cos(a) * 14
        d.ellipse([cx - 8, cy - 13, cx + 8, cy + 13], fill=(205, 30, 40, 255))
    ctext(d, (48, 76), "HUAWEI", 14, (60, 60, 65), True)
    img.save(f"{OUT}/egg_huawei.png")

def egg_vc():
    # 视觉中国水印照片
    img = Image.new("RGBA", (128, 96), (70, 75, 80, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([8, 8, 120, 88], fill=(150, 160, 165, 255))   # 楼的照片
    for i in range(6):
        for j in range(4):
            d.rectangle([20 + i * 16, 16 + j * 18, 30 + i * 16, 28 + j * 18], fill=(90, 95, 105, 255))
    ctext(d, (64, 48), "视觉中国", 22, (255, 255, 255, 200), True)
    ctext(d, (64, 68), "VCG.COM", 10, (255, 255, 255, 170))
    img.save(f"{OUT}/egg_vc.png")

def egg_combo():
    # 三 logo 合一的神秘传单
    img = Image.new("RGBA", (128, 128), (250, 245, 230, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 4, 124, 124], outline=(180, 60, 50, 255), width=3)
    ctext(d, (64, 16), "联合赞助", 14, (180, 60, 50), True)
    d.polygon([(20, 52), (30, 40), (56, 40), (64, 52)], fill=(200, 40, 40, 255))  # 四驱车
    ctext(d, (42, 60), "冲锋", 8, (255, 240, 200), True)
    for i in range(6):  # 花瓣
        a = math.radians(i * 60)
        cx, cy = 92 + math.sin(a) * 8, 48 - math.cos(a) * 8
        d.ellipse([cx - 4, cy - 7, cx + 4, cy + 7], fill=(205, 30, 40, 255))
    ctext(d, (64, 84), "视觉中国 水印", 12, (120, 120, 120))
    ctext(d, (64, 104), "平行宇宙广告位招租", 10, (90, 90, 90))
    ctext(d, (64, 118), "（这传单不该存在）", 9, (150, 40, 40))
    img.save(f"{OUT}/egg_combo.png")

def egg_miside():
    # 米塔游戏卡带
    img = Image.new("RGBA", (64, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([6, 6, 58, 90], 6, fill=(230, 225, 235, 255))
    d.rectangle([12, 14, 52, 54], fill=(180, 120, 160, 255))
    ctext(d, (32, 34), "米塔", 16, (255, 255, 255), True)
    ctext(d, (32, 66), "MiSide", 10, (120, 90, 110), True)
    ctext(d, (32, 80), "卡带", 9, (140, 130, 140))
    img.save(f"{OUT}/egg_miside.png")

def egg_cutie():
    # CALL OF CUTIE 海报
    img = Image.new("RGBA", (96, 128), (250, 230, 240, 255))
    d = ImageDraw.Draw(img)
    d.ellipse([28, 20, 68, 60], fill=(255, 205, 215, 255))   # Q版脸
    d.ellipse([36, 36, 42, 44], fill=(30, 30, 35, 255))
    d.ellipse([54, 36, 60, 44], fill=(30, 30, 35, 255))
    d.arc([40, 44, 56, 54], 20, 160, fill=(180, 80, 100, 255), width=2)
    d.polygon([(30, 22), (20, 8), (38, 16)], fill=(120, 60, 80, 255))  # 耳朵
    d.polygon([(66, 22), (76, 8), (58, 16)], fill=(120, 60, 80, 255))
    ctext(d, (48, 78), "CALL of CUTIE", 11, (160, 60, 90), True)
    ctext(d, (48, 96), "可爱即正义", 11, (120, 80, 100))
    ctext(d, (48, 114), "（但背景太黑了）", 9, (150, 130, 140))
    img.save(f"{OUT}/egg_cutie.png")

def clock333():
    img = Image.new("RGBA", (96, 96), (235, 230, 220, 255))
    d = ImageDraw.Draw(img)
    d.ellipse([8, 8, 88, 88], outline=(60, 50, 40, 255), width=4)
    ctext(d, (48, 46), "3:33", 22, (120, 30, 25), True)
    ctext(d, (48, 68), "（秒针在抖）", 9, (100, 90, 80))
    img.save(f"{OUT}/clock333.png")

def death_report():
    img = Image.new("RGBA", (192, 128), (20, 24, 30, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 4, 188, 124], outline=(80, 160, 200, 255), width=2)
    ctext(d, (96, 22), "死 亡 报 告", 18, (120, 200, 240), True)
    ctext(d, (96, 52), "死因：车祸 · 失血过多", 13, (200, 210, 220))
    ctext(d, (96, 74), "时间：7 天前 · 03:33", 13, (200, 210, 220))
    ctext(d, (96, 100), "第 48 号管理员 · 确认死亡", 12, (240, 120, 120))
    img.save(f"{OUT}/death_report.png")

if __name__ == "__main__":
    for n in ["214", "334", "404", "444"]:
        doorplate(n)
    chen_face(); chen_face(True)
    jia_face(); jia_face(True)
    prev_face()
    chen_body(); jia_body(); prev_body(); doorgod_body()
    butterfly(); talisman(); graffiti4(); poster_missing()
    receipts(); moneywall(); calendar_floor()
    egg_4wd(); egg_huawei(); egg_vc(); egg_combo(); egg_miside(); egg_cutie()
    clock333(); death_report()
    print("done ->", OUT)
