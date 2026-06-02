"""
尝试从多个公开源下载文物图片
"""
import requests
import os
import sys

SAVE_DIR = "/sessions/quirky-blissful-tesla/mnt/museum/palm-museum-api/images"
os.makedirs(SAVE_DIR, exist_ok=True)

# 25件文物，尝试多个搜索源
artifacts = [
    ("por_001", "元青花缠枝牡丹纹梅瓶"),
    ("por_002", "清乾隆粉彩百鹿图尊"),
    ("por_003", "宋汝窑天青釉弦纹樽"),
    ("por_004", "明成化斗彩鸡缸杯"),
    ("por_005", "清康熙郎窑红釉观音瓶"),
    ("por_006", "清雍正霁蓝釉天球瓶"),
    ("por_007", "清乾隆茶叶末釉绶带耳瓶"),
    ("por_008", "明万历五彩龙凤纹笔盒"),
    ("por_009", "清雍正珐琅彩松竹梅纹瓶"),
    ("por_010", "宋汝窑三足奁"),
    ("por_011", "宋官窑贯耳瓶"),
    ("por_012", "宋哥窑鱼耳炉"),
    ("por_013", "宋定窑白釉孩儿枕"),
    ("por_014", "宋钧窑玫瑰紫釉鼓钉洗"),
    ("por_015", "宋建窑兔毫盏"),
    ("por_016", "明德化窑白釉观音坐像"),
    ("por_017", "宋磁州窑白地黑花龙凤纹罐"),
    ("por_018", "唐越窑青釉刻花执壶"),
    ("por_019", "唐长沙窑青釉褐彩诗文壶"),
    ("por_020", "唐三彩骆驼载乐俑"),
    ("por_021", "宋景德镇青白釉刻花梅瓶"),
    ("por_022", "元枢府釉刻花盘"),
    ("por_023", "元釉里红缠枝菊纹玉壶春瓶"),
    ("por_024", "明永乐青花海水龙纹扁壶"),
    ("por_025", "清雍正粉彩过枝牡丹纹碗"),
]

# Test: try fetching a known freely-available image
# Wikimedia Commons direct image URLs
test_urls = {
    "por_003": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1e/Ru_Ware.JPG/800px-Ru_Ware.JPG",
}

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
}

success = 0
fail = 0

for art_id, art_name in artifacts:
    filename = f"{art_id}.jpg"
    filepath = os.path.join(SAVE_DIR, filename)

    # Skip if already exists
    if os.path.exists(filepath) and os.path.getsize(filepath) > 1000:
        print(f"  ✅ {art_name} — already exists, skipping")
        success += 1
        continue

    # Try known URLs first
    if art_id in test_urls:
        try:
            resp = requests.get(test_urls[art_id], headers=headers, timeout=15)
            if resp.status_code == 200 and len(resp.content) > 1000:
                with open(filepath, "wb") as f:
                    f.write(resp.content)
                print(f"  ✅ {art_name} — downloaded from known URL ({len(resp.content)} bytes)")
                success += 1
                continue
        except Exception as e:
            pass

    # Try DuckDuckGo image search redirect (free API)
    search_terms = [
        f"{art_name} site:commons.wikimedia.org",
        f"{art_name} 故宫博物院",
        f"{art_name} museum",
    ]

    downloaded = False
    for term in search_terms:
        if downloaded:
            break
        try:
            # Try to get image via DuckDuckGo
            ddg_url = f"https://duckduckgo.com/?q={requests.utils.quote(term)}&iax=images&ia=images"
            # This won't directly give images, skip for now
            pass
        except:
            pass

    if not downloaded:
        print(f"  ❌ {art_name} — no image found")
        fail += 1

print(f"\nDone: {success} succeeded, {fail} failed")
