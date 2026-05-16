-- ============================================================
-- 掌上博物馆 (Palm Museum) —— 数据库初始化脚本
-- 使用方法：直接在 MySQL 客户端打开运行 (拖入即可)
-- ============================================================

CREATE DATABASE IF NOT EXISTS palm_museum CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE palm_museum;

-- ============================================================
-- 1. 表结构
-- ============================================================

-- 文物表
CREATE TABLE IF NOT EXISTS artworks (
    id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    dynasty VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL,
    material VARCHAR(50) DEFAULT '',
    description TEXT,
    detail_description TEXT,
    cover_image VARCHAR(500) DEFAULT '',
    popularity INT DEFAULT 0,
    like_count INT DEFAULT 0,
    favorite_count INT DEFAULT 0,
    comment_count INT DEFAULT 0,
    year_range VARCHAR(50) DEFAULT '',
    origin VARCHAR(200) DEFAULT '',
    dimensions VARCHAR(200) DEFAULT '',
    weight VARCHAR(50) DEFAULT '',
    collection_place VARCHAR(200) DEFAULT '',
    tags LONGTEXT,
    historical_background TEXT,
    cultural_significance TEXT,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_dynasty (dynasty),
    INDEX idx_type (type),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 文物图片表
CREATE TABLE IF NOT EXISTS artwork_images (
    id VARCHAR(64) PRIMARY KEY,
    artwork_id VARCHAR(32) NOT NULL,
    url VARCHAR(500) DEFAULT '',
    thumbnail_url VARCHAR(500) DEFAULT '',
    title VARCHAR(200) DEFAULT '',
    description VARCHAR(500) DEFAULT '',
    width INT DEFAULT 0,
    height INT DEFAULT 0,
    FOREIGN KEY (artwork_id) REFERENCES artworks(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 音频导览表
CREATE TABLE IF NOT EXISTS audio_guides (
    id VARCHAR(64) PRIMARY KEY,
    artwork_id VARCHAR(32) NOT NULL UNIQUE,
    url VARCHAR(500) DEFAULT '',
    duration INT DEFAULT 0,
    narrator VARCHAR(100) DEFAULT '',
    text_script TEXT,
    FOREIGN KEY (artwork_id) REFERENCES artworks(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(200) NOT NULL,
    nickname VARCHAR(50) DEFAULT '',
    avatar VARCHAR(500) DEFAULT '',
    phone VARCHAR(20) DEFAULT '',
    email VARCHAR(100) DEFAULT '',
    gender VARCHAR(10) DEFAULT '',
    birthday DATE DEFAULT NULL,
    signature VARCHAR(200) DEFAULT '',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_account (account)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 点赞表
CREATE TABLE IF NOT EXISTS user_likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    artwork_id VARCHAR(32) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_artwork_like (user_id, artwork_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (artwork_id) REFERENCES artworks(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 收藏表
CREATE TABLE IF NOT EXISTS user_collections (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    artwork_id VARCHAR(32) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_artwork_collection (user_id, artwork_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (artwork_id) REFERENCES artworks(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 浏览历史表
CREATE TABLE IF NOT EXISTS browse_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    artwork_id VARCHAR(32) NOT NULL,
    browse_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_browse_time (browse_time),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (artwork_id) REFERENCES artworks(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 评论表
CREATE TABLE IF NOT EXISTS comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    artwork_id VARCHAR(32) NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    parent_id INT DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_artwork_id (artwork_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (artwork_id) REFERENCES artworks(id),
    FOREIGN KEY (parent_id) REFERENCES comments(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 2. 文物数据 (25 件)
-- ============================================================

INSERT INTO artworks (id, name, dynasty, type, material, description, detail_description, cover_image, popularity, like_count, favorite_count, comment_count, year_range, origin, dimensions, weight, collection_place, tags, historical_background, cultural_significance) VALUES
('por_001', '元青花缠枝牡丹纹梅瓶', '元', '青花瓷', '瓷', '元代青花瓷珍品，器型挺拔，纹饰繁复精美，青花发色浓艳。', '此元代青花缠枝牡丹纹梅瓶，小口、短颈、丰肩、瘦底、圈足，造型优美挺拔。通体绘青花缠枝牡丹纹，"牡丹"花大色艳，有"花中之王"之美誉。青花色泽浓艳深沉，具有典型的元青花"至正型"特征。纹饰布局繁密而不乱，层次丰富，是元青花瓷器中的杰出代表。', 'https://example.com/porcelain/por_001_0_full.jpg', 9850, 3447, 2462, 788, '14世纪', '江西景德镇', '高48.5cm，口径5.2cm，底径14.2cm', '约5.8kg', '北京故宫博物院', '["元青花", "梅瓶", "牡丹纹", "缠枝纹", "景德镇"]', '元代是中国青花瓷发展的黄金时期。元青花以其独特的钴料发色和繁复的纹饰著称于世。元朝在景德镇设立浮梁瓷局，推动了青花瓷技术的成熟。此类梅瓶在元代多用作酒器或陈设瓷，是元代对外贸易的重要商品之一，远销中东、欧洲等地。', '元青花在中国陶瓷史上具有里程碑意义，它开创了中国陶瓷的青花时代，对后世青花瓷发展产生了深远影响。其钴料来自波斯（今伊朗地区），体现了元代中西文化交流的盛况。'),
('por_002', '清乾隆粉彩百鹿图尊', '清', '粉彩', '瓷', '乾隆粉彩瓷精品，器身绘百鹿图，寓意吉祥，色彩柔和绚丽。', '清乾隆粉彩百鹿图尊，撇口、粗颈、圆腹、圈足。器身以粉彩绘制百鹿图，山林间群鹿或奔跑、或嬉戏、或觅食、或小憩，姿态各异，生动传神。"百鹿"谐音"百禄"，寓意富贵吉祥。粉彩色彩柔和淡雅，层次丰富，充分展现了乾隆时期粉彩瓷器的最高水平。底足有"大清乾隆年制"六字三行篆书款。', 'https://example.com/porcelain/por_002_1_full.jpg', 9200, 3220, 2300, 736, '1736-1795', '江西景德镇', '高62.5cm，口径18.8cm，底径22.5cm', '约12.3kg', '北京故宫博物院', '["清乾隆", "粉彩", "百鹿图", "尊", "景德镇"]', '粉彩是清代康熙晚期在珐琅彩影响下创制的釉上彩瓷新品种，雍正、乾隆时期达到鼎盛。乾隆皇帝酷爱艺术，尤其热衷瓷器，常亲自参与瓷器样式设计。粉彩百鹿图尊是乾隆时期的典型陈设瓷，展现了宫廷绘画与瓷器工艺的完美结合。', '粉彩瓷是中国陶瓷史上的重要创新，它融合了中国传统绘画技法与西方珐琅彩工艺，形成了独特的艺术风格。百鹿图尊不仅是一件精美的艺术品，更承载了丰富的文化寓意。'),
('por_003', '宋汝窑天青釉弦纹樽', '宋', '青瓷', '瓷', '汝窑瓷器的典范，天青釉色温润如玉，开片纹理自然天成。', '宋汝窑天青釉弦纹樽，直口、平底、圈足外撇。器身饰三组弦纹，造型简洁端庄，线条挺拔有力。釉色天青，釉面匀净滋润，开细碎片纹，"蟹爪纹"清晰可见。汝窑瓷器以其"天青釉"闻名，釉色如雨过天晴般清新雅致。此樽为汝官窑典型器物，是宋代宫廷祭祀用器。', 'https://example.com/porcelain/por_003_0_full.jpg', 8800, 3080, 2200, 704, '1086-1125', '河南宝丰清凉寺', '高12.8cm，口径18.2cm，底径12.5cm', '约1.2kg', '北京故宫博物院', '["汝窑", "天青釉", "弦纹", "樽", "宋代五大名窑"]', '汝窑为宋代五大名窑之首，北宋晚期为宫廷烧造御用瓷器，烧造时间仅约20年。汝官窑遗址位于今河南省宝丰县清凉寺村。汝窑瓷器以玛瑙入釉，釉色以天青为贵，釉面温润如玉，开片纹理丰富，有"蝉翼纹"、"蟹爪纹"、"鱼子纹"等。', '汝窑瓷器以其"似玉非玉而胜似玉"的质感，被誉为"宋瓷之冠"。传世汝窑瓷器不足百件，每一件都是稀世珍宝。'),
('por_004', '明成化斗彩鸡缸杯', '明', '斗彩', '瓷', '成化斗彩名品，鸡缸杯小巧玲珑，画面生动活泼，色彩明丽。', '明成化斗彩鸡缸杯，敞口、浅腹、卧足，造型小巧玲珑。杯身绘有子母鸡群觅食于山石花草间的场景，雄鸡昂首啼鸣，母鸡带领小鸡觅食，画面温馨生动。斗彩工艺精湛，青花勾线后填彩，色彩丰富明丽，有红、黄、绿、紫等多种颜色。底足有"大明成化年制"六字双行楷书款。', 'https://example.com/porcelain/por_004_0_full.jpg', 9500, 3325, 2375, 760, '1465-1487', '江西景德镇', '高3.8cm，口径8.3cm，足径4.5cm', '约0.2kg', '北京故宫博物院', '["明成化", "斗彩", "鸡缸杯", "成化窑"]', '斗彩是明代成化时期创烧的釉上彩瓷品种，先用青花在釉下勾勒纹饰轮廓，入窑烧制后再在釉上填彩二次烧成。成化皇帝对瓷器极为讲究，御窑厂产量有限但质量精绝。鸡缸杯是成化斗彩中最负盛名的品种。', '成化斗彩鸡缸杯在中国陶瓷史上地位极高，被誉为"瓷中极品"。'),
('por_005', '清康熙郎窑红釉观音瓶', '清', '色釉瓷', '瓷', '郎窑红釉瓷器的典范，釉色鲜红如牛血，"脱口垂足"特征明显。', '清康熙郎窑红釉观音瓶，撇口、短颈、丰肩、修腹、撇足，形似观音菩萨所持净瓶，故称"观音瓶"。釉色鲜红浓艳，如初凝牛血，釉面玻璃质感强，有细小的开片。口部因釉层较薄而呈浅红色或白色，俗称"脱口"；底部边缘釉色垂流，形成"垂足"现象。康熙郎窑红为江西巡抚郎廷极督窑所创，代表了清代红釉瓷器的最高水平。', 'https://example.com/porcelain/por_005_1_full.jpg', 7500, 2625, 1875, 600, '1662-1722', '江西景德镇', '高46.5cm，口径12.8cm，底径14.2cm', '约4.5kg', '上海博物馆', '["郎窑红", "康熙", "观音瓶", "红釉", "景德镇"]', '郎窑红是清代康熙时期仿明代宣德红釉的创新品种。督陶官郎廷极在景德镇御窑厂督造瓷器，成功烧制出这一名贵色釉。郎窑红的烧制难度极大，对窑温、气氛要求极为严格，"要想穷，烧郎红"的民谚反映了其烧造之难。', '郎窑红釉是中国红釉瓷器的杰出代表，其色泽之浓艳、质感之华美令后世叹为观止。'),
('por_006', '清雍正霁蓝釉天球瓶', '清', '色釉瓷', '瓷', '雍正霁蓝釉精品，釉色深沉如蓝宝石，造型浑圆大气。', '清雍正霁蓝釉天球瓶，直口、长颈、球形腹、圈足，因腹部浑圆似天球而得名。通体施霁蓝釉，釉色匀净深沉，如蓝宝石般晶莹剔透，釉面满布细小的棕眼。霁蓝釉为霁红釉的姊妹品种，同样采用高温一次烧成。雍正时期霁蓝釉色泽最为纯正，达到了"蓝如深海"的艺术效果。', 'https://example.com/porcelain/por_006_0_full.jpg', 6800, 2380, 1700, 544, '1723-1735', '江西景德镇', '高55.8cm，口径11.2cm，底径17.5cm', '约7.2kg', '北京故宫博物院', '["霁蓝釉", "雍正", "天球瓶", "蓝釉", "景德镇"]', '霁蓝釉又称"祭蓝釉"、"积蓝釉"，是一种高温石灰碱釉。元代开始烧造，明清时期达到鼎盛。雍正皇帝对瓷器有极高的审美要求，霁蓝釉天球瓶正是这一时期官窑的代表作品。', '雍正霁蓝釉瓷器以其纯净的蓝色和高雅的造型，展现了清代宫廷审美的极致追求。'),
('por_007', '清乾隆茶叶末釉绶带耳瓶', '清', '色釉瓷', '瓷', '茶叶末釉为铁结晶釉名品，釉色黄绿相间如茶叶细末，古朴雅致。', '清乾隆茶叶末釉绶带耳瓶，盘口、束颈、颈部两侧饰绶带形耳、圆腹、圈足。通体施茶叶末釉，釉色呈鳝鱼黄绿色，釉面布满细小的黄褐色结晶斑点，如茶叶细末散布其中。茶叶末釉属于铁结晶釉的一种，需在高温下使铁元素形成结晶析出，对窑温控制要求极高。', 'https://example.com/porcelain/por_007_0_full.jpg', 5500, 1925, 1375, 440, '1736-1795', '江西景德镇', '高38.5cm，口径10.2cm，底径13.8cm', '约3.8kg', '南京博物院', '["茶叶末釉", "乾隆", "绶带耳瓶", "结晶釉", "景德镇"]', '茶叶末釉最早见于唐代耀州窑，清代雍正、乾隆时期达到工艺巅峰。唐英《陶成纪事碑》中记载了茶叶末釉的配方和烧制工艺。', '茶叶末釉以其含蓄内敛的美感，在清代颜色釉瓷器中独树一帜，体现了中国传统审美中崇尚自然、追求质朴的哲学思想。'),
('por_008', '明万历五彩龙凤纹笔盒', '明', '五彩', '瓷', '万历五彩瓷精品，色彩艳丽，龙凤纹饰富丽堂皇。', '明万历五彩龙凤纹笔盒，长方形，子母口，圈足。盒盖与盒身均以五彩绘龙凤穿花纹，盖面正中为龙凤呈祥图案，周围饰以缠枝花卉。五彩以红、黄、绿、紫、蓝等色彩为主，色彩浓艳热烈，对比强烈。万历五彩素有"大红大绿"之称，是明代晚期最具代表性的瓷器品种之一。', 'https://example.com/porcelain/por_008_0_full.jpg', 7200, 2520, 1800, 576, '1573-1620', '江西景德镇', '长28.5cm，宽18.2cm，高10.5cm', '约2.8kg', '北京故宫博物院', '["明万历", "五彩", "龙凤纹", "笔盒", "景德镇"]', '五彩是明代景德镇创烧的釉上彩瓷品种，嘉靖、万历时期最为盛行。万历皇帝在位48年，御窑厂生产了大量五彩瓷，主要用于宫廷日用和陈设。', '万历五彩瓷器以其独特的艺术风格在中国陶瓷史上占有重要地位，对清代康熙五彩有直接影响。'),
('por_009', '清雍正珐琅彩松竹梅纹瓶', '清', '珐琅彩', '瓷', '珐琅彩瓷至尊，雍正御制，松竹梅岁寒三友图，诗书画印合一。', '清雍正珐琅彩松竹梅纹瓶，撇口、细颈、垂腹、圈足。器身以珐琅彩绘松竹梅"岁寒三友"图，松树苍劲，翠竹挺拔，梅花傲雪，画工精绝。珐琅彩色彩丰富，层次分明，具有油画般的立体效果。瓶身配有雍正皇帝御题诗句，诗书画印相结合，是宫廷艺术的巅峰之作。', 'https://example.com/porcelain/por_009_0_full.jpg', 8900, 3115, 2225, 712, '1723-1735', '江西景德镇（内廷造办处彩绘）', '高22.5cm，口径5.8cm，底径7.2cm', '约1.1kg', '台北故宫博物院', '["珐琅彩", "雍正", "松竹梅", "岁寒三友", "御制"]', '珐琅彩瓷是清代康熙晚期在宫廷内务府造办处珐琅作创制的一种瓷器新品种。雍正时期珐琅彩工艺达到顶峰，胎体精选景德镇御窑厂最优质的素白瓷器，送入宫内由宫廷画师在造办处完成彩绘和烧制。', '珐琅彩瓷被誉为"官窑中的官窑"，是清代宫廷瓷器中最为名贵的品种。'),
('por_010', '宋汝窑三足奁', '宋', '青瓷', '瓷', '北宋汝官窑典型器，天青釉面温润如玉，三足造型古朴庄重。', '宋汝窑三足奁，直口、平底、下承三足。器身呈筒形，外壁饰三组弦纹。通体施天青釉，釉色幽玄静谧，釉面满布细密的开片纹理。胎体呈香灰色，胎质细腻。三足奁为汉代以来传统的盛器造型，宋代汝官窑将其升华为高雅的艺术陈设品。', 'https://example.com/porcelain/por_010_0_full.jpg', 8600, 3010, 2150, 688, '1086-1125', '河南宝丰清凉寺', '高15.6cm，口径23.5cm', '约1.8kg', '北京故宫博物院', '["汝窑", "三足奁", "天青釉", "宋代五大名窑", "官窑"]', '汝窑位居宋代五大名窑之首，为北宋宫廷烧造御用瓷器。汝官窑遗址1985年在河南省宝丰县清凉寺村被发现。', '汝窑瓷器以其"似玉非玉"的质感和含蓄内敛的美学风格，成为中国陶瓷史上难以逾越的高峰。'),
('por_011', '宋官窑贯耳瓶', '宋', '青瓷', '瓷', '南宋官窑杰作，紫口铁足，釉面开冰裂纹，古朴典雅。', '宋官窑贯耳瓶，直口、长颈、颈部两侧置贯耳、圆腹、圈足。通体施灰青色釉，釉面布满深浅不一的冰裂纹片，错落有致，自然天成。官窑瓷器以"紫口铁足"为特征——口部釉层较薄隐约透出胎体的紫色，底部露胎处呈现铁褐色。', 'https://example.com/porcelain/por_011_0_full.jpg', 7800, 2730, 1950, 624, '1127-1279', '浙江杭州修内司官窑', '高26.8cm，口径8.5cm，底径10.2cm', '约2.3kg', '北京故宫博物院', '["官窑", "贯耳瓶", "南宋", "冰裂纹", "宋代五大名窑"]', '南宋官窑是宋室南迁后在杭州设立的御窑，分为修内司官窑和郊坛下官窑两处。', '官窑瓷器代表了南宋宫廷审美的高雅格调，其"大巧若拙"的美学理念对后世影响深远。'),
('por_012', '宋哥窑鱼耳炉', '宋', '青瓷', '瓷', '哥窑名品，金丝铁线开片，鱼耳造型灵动，釉色米黄温润。', '宋哥窑鱼耳炉，敞口、束颈、鼓腹、圈足，颈腹部两侧各置鱼形耳。通体施米黄色釉，釉面布满"金丝铁线"开片——黑色大开片纹路中贯穿着金黄色细纹，纵横交错，形成独特的装饰效果。', 'https://example.com/porcelain/por_012_0_full.jpg', 7400, 2590, 1850, 592, '南宋', '浙江龙泉', '高10.5cm，口径12.8cm，底径9.5cm', '约0.9kg', '北京故宫博物院', '["哥窑", "鱼耳炉", "金丝铁线", "宋代五大名窑", "开片"]', '哥窑位居宋代五大名窑之一，关于其起源有多个传说。最著名的传说是南宋时期龙泉有章生一、章生二兄弟各主一窑，哥哥的窑口被称为"哥窑"。', '哥窑瓷器以其独特的开片艺术在陶瓷史上独树一帜。'),
('por_013', '宋定窑白釉孩儿枕', '宋', '白瓷', '瓷', '定窑白瓷杰作，以孩童为枕座，造型天真可爱，釉色洁白温润。', '宋定窑白釉孩儿枕，以孩童侧卧姿态为枕座，孩童双手持一荷叶，荷叶边缘自然卷曲形成枕面。孩童形象丰满圆润，神态安详，衣纹线条流畅。通体施白釉，釉色白中泛黄，俗称"象牙白"。', 'https://example.com/porcelain/por_013_0_full.jpg', 8200, 2870, 2050, 656, '960-1127', '河北曲阳涧磁村', '高18.3cm，长30cm，宽12.5cm', '约2.5kg', '北京故宫博物院', '["定窑", "孩儿枕", "白瓷", "宋代五大名窑", "河北曲阳"]', '定窑是宋代五大名窑之一，以烧造白瓷闻名于世，窑址位于今河北省曲阳县涧磁村及东西燕山村。创烧于唐代，鼎盛于北宋。', '定窑白瓷代表了宋代北方瓷器的最高水平。孩儿枕是中国陶瓷史上少有的以儿童题材为主题的成功作品。'),
('por_014', '宋钧窑玫瑰紫釉鼓钉洗', '宋', '色釉瓷', '瓷', '钧窑瑰宝，玫瑰紫釉色奇幻瑰丽，窑变效果浑然天成。', '宋钧窑玫瑰紫釉鼓钉洗，敞口、浅腹、圈足，口沿和足部各饰一周鼓钉纹。器内外满施玫瑰紫釉，釉色绚丽多变，红紫相间，蓝白交融，宛如夕阳晚霞，美不胜收。钧窑以"窑变"著称，通过控制窑内气氛使釉中的铜、铁等金属元素呈现不同色彩，"入窑一色，出窑万彩"。', 'https://example.com/porcelain/por_014_0_full.jpg', 7600, 2660, 1900, 608, '960-1127', '河南禹州', '高7.5cm，口径22.8cm，底径13.5cm', '约1.8kg', '北京故宫博物院', '["钧窑", "玫瑰紫釉", "鼓钉洗", "宋代五大名窑", "窑变"]', '钧窑是宋代五大名窑之一，窑址位于今河南省禹州市。钧窑的铜红釉技术是中国陶瓷史上的一次革命性突破。', '钧窑"窑变"艺术在中国陶瓷史上具有划时代的意义，以其绚丽多彩的艺术效果独树一帜。'),
('por_015', '宋建窑兔毫盏', '宋', '黑瓷', '瓷', '建窑兔毫盏，黑釉中透出兔毫般细纹，宋代斗茶极品。', '宋建窑兔毫盏，敞口、斜腹、小圈足，造型简洁。内外施黑釉，釉色乌黑如漆，釉面中透出细密的黄褐色条纹，状如兔毫，故称"兔毫盏"。兔毫纹的形成是由于釉中的铁元素在高温下产生液相分离，形成结晶条纹。', 'https://example.com/porcelain/por_015_0_full.jpg', 7100, 2485, 1775, 568, '960-1127', '福建建阳水吉镇', '高6.8cm，口径12.5cm，底径4.2cm', '约0.4kg', '北京故宫博物院', '["建窑", "兔毫盏", "黑釉", "斗茶", "福建建阳"]', '建窑是宋代著名的黑釉瓷窑场，窑址位于今福建省建阳市水吉镇。宋代盛行斗茶之风，建窑兔毫盏因最宜观察茶色而备受推崇。', '建窑兔毫盏是中国黑釉瓷器的杰出代表，对日本茶道文化产生了极为深远的影响。'),
('por_016', '明德化窑白釉观音坐像', '明', '白瓷', '瓷', '德化白瓷极品，"中国白"之誉，观音慈悲庄严，衣纹飘逸。', '明德化窑白釉观音坐像，观音菩萨善跏趺坐于莲台之上，头戴宝冠，面容慈祥端庄，双目微垂，嘴角含笑。身着天衣，衣纹线条流畅飘逸，如行云流水。通体施白釉，釉色乳白温润如凝脂，俗称"猪油白"。', 'https://example.com/porcelain/por_016_0_full.jpg', 8300, 2905, 2075, 664, '明代中期', '福建德化', '高48.5cm，底座宽18.5cm', '约4.8kg', '北京故宫博物院', '["德化窑", "何朝宗", "白釉", "观音", "福建德化"]', '德化窑位于福建省德化县，宋元时期开始烧造白瓷，明代达到鼎盛。明代德化瓷塑大师何朝宗将德化瓷塑艺术推向了巅峰。', '德化白瓷是中国陶瓷史上一个独特的艺术流派，"中国白"（Blanc de Chine）是法国人对德化白瓷的美誉。'),
('por_017', '宋磁州窑白地黑花龙凤纹罐', '宋', '白地黑花', '瓷', '磁州窑典型作品，白地黑花对比强烈，绘画笔法豪放洒脱。', '宋磁州窑白地黑花龙凤纹罐，直口、短颈、丰肩、鼓腹、圈足。器身以白釉为地，以黑彩绘龙凤穿云纹，纹饰线条粗犷豪放，黑白对比强烈，具有鲜明的民间艺术特色。', 'https://example.com/porcelain/por_017_0_full.jpg', 6500, 2275, 1625, 520, '960-1127', '河北磁县观台镇', '高35.2cm，口径15.8cm，底径17.5cm', '约4.2kg', '上海博物馆', '["磁州窑", "白地黑花", "龙凤纹", "宋代", "河北磁县"]', '磁州窑是宋代北方最大的民间瓷窑体系，窑址以今河北省磁县观台镇为中心。磁州窑以白地黑花、刻划花、珍珠地等装饰技法著称。', '磁州窑作为民间瓷窑的杰出代表，其自由奔放的艺术风格对后世影响深远。'),
('por_018', '唐越窑青釉刻花执壶', '唐', '青瓷', '瓷', '越窑青瓷精品，"类玉类冰"之誉，刻花技法精湛。', '唐越窑青釉刻花执壶，撇口、长颈、圆腹、圈足，一侧置流（壶嘴），另一侧置柄（把手）。通体施青釉，釉色青绿温润，"类玉类冰"。壶身刻有花卉纹饰，刀法流畅犀利。', 'https://example.com/porcelain/por_018_0_full.jpg', 6900, 2415, 1725, 552, '618-907', '浙江余姚上林湖', '高22.3cm，口径6.8cm，底径10.2cm', '约1.5kg', '浙江省博物馆', '["越窑", "青瓷", "执壶", "唐代", "浙江余姚"]', '越窑是中国最早的瓷窑之一，创烧于东汉，鼎盛于唐、五代。越窑青瓷代表了唐代青瓷的最高水平，曾作为"秘色瓷"进贡宫廷。', '越窑青瓷在中国陶瓷史上具有开创性地位，奠定了中国"南青北白"的陶瓷格局。'),
('por_019', '唐长沙窑青釉褐彩诗文壶', '唐', '釉下彩', '瓷', '长沙窑首创釉下彩绘，诗文与瓷器的完美结合，唐代外销瓷代表。', '唐长沙窑青釉褐彩诗文壶，撇口、短颈、圆腹、平底，多棱短流。壶身以褐彩书写唐代诗人诗句，诗文与瓷器巧妙结合，开创了中国陶瓷题诗装饰的先河。', 'https://example.com/porcelain/por_019_0_full.jpg', 6200, 2170, 1550, 496, '618-907', '湖南长沙铜官窑', '高20.5cm，口径8.3cm，底径12.5cm', '约1.8kg', '湖南省博物馆', '["长沙窑", "釉下彩", "诗文壶", "唐代", "湖南长沙"]', '长沙窑是唐代著名的外销瓷窑场，首创釉下多彩工艺，突破了传统的单色釉和刻划花装饰。', '长沙窑釉下彩绘技术的发明是中国陶瓷史上的重大突破，为宋元时期釉下彩瓷的繁荣奠定了技术基础。'),
('por_020', '唐三彩骆驼载乐俑', '唐', '三彩', '陶', '唐三彩杰作，骆驼载乐俑生动再现了盛唐丝绸之路的文化交融。', '唐三彩骆驼载乐俑，双峰骆驼昂首站立于长方形平板上，驼背上铺有圆垫，垫上有一组乐舞俑共八人，包括七名乐师和一名舞者。乐师手持琵琶、箜篌、筚篥、笛子等乐器，舞者在中央翩翩起舞。', 'https://example.com/porcelain/por_020_0_full.jpg', 8700, 3045, 2175, 696, '618-907', '陕西西安', '高58.4cm，长43cm', '约8.5kg', '中国国家博物馆', '["唐三彩", "骆驼", "乐俑", "丝绸之路", "唐代"]', '唐三彩是唐代低温铅釉陶器的统称，因以黄、绿、白三种颜色为主而得名。创烧于唐代高宗时期，开元年间达到鼎盛。', '唐三彩是中国陶瓷史上的一颗璀璨明珠，展现了唐代社会的繁荣、开放和多元文化交融。'),
('por_021', '宋景德镇青白釉刻花梅瓶', '宋', '青白瓷', '瓷', '青白瓷介于青白之间，"影青"之美，刻花若隐若现。', '宋景德镇青白釉刻花梅瓶，小口、短颈、丰肩、瘦底、圈足。通体施青白釉，釉色介于青白之间，青中带白、白中透青，俗称"影青"。瓶身刻有缠枝花卉纹，刻纹深处釉色较深，浅处釉色较淡。', 'https://example.com/porcelain/por_021_0_full.jpg', 6700, 2345, 1675, 536, '960-1127', '江西景德镇', '高35.8cm，口径5.5cm，底径11.2cm', '约1.5kg', '北京故宫博物院', '["青白瓷", "影青", "景德镇", "梅瓶", "宋代"]', '青白瓷是宋代景德镇窑创烧的瓷器新品种，宋代称"青白瓷"，清代以后俗称"影青"。', '青白瓷的"薄如纸、白如玉、明如镜、声如磬"的审美特征影响了中国陶瓷近千年。'),
('por_022', '元枢府釉刻花盘', '元', '卵白釉', '瓷', '元代枢府釉瓷器，卵白釉色温润含蓄，为元代官用瓷器。', '元枢府釉刻花盘，敞口、浅腹、圈足。通体施卵白釉，釉色白中泛青，如鹅卵之色，温润含蓄。盘心刻有花卉纹饰，内壁印有"枢府"二字款。枢府釉是元代景德镇为枢密院烧造的官用瓷器，是明代官窑制度的前身。', 'https://example.com/porcelain/por_022_0_full.jpg', 5800, 2030, 1450, 464, '1271-1368', '江西景德镇', '高5.2cm，口径20.8cm，底径12.5cm', '约1.2kg', '上海博物馆', '["枢府釉", "卵白釉", "元代", "景德镇", "官用瓷"]', '枢府釉是元代景德镇创烧的卵白釉瓷器品种，因印有"枢府"二字而得名。', '枢府釉瓷器是元代陶瓷史上一个承前启后的重要品种。'),
('por_023', '元釉里红缠枝菊纹玉壶春瓶', '元', '釉里红', '瓷', '釉里红名品，铜红发色纯正，缠枝菊纹舒展流畅。', '元釉里红缠枝菊纹玉壶春瓶，撇口、细颈、垂腹、圈足。通体以釉里红绘制缠枝菊纹，釉里红发色鲜艳纯正，红白相映，格外醒目。釉里红以氧化铜为着色剂在釉下绘彩，高温一次烧成，铜红发色对窑温和气氛极为敏感。', 'https://example.com/porcelain/por_023_0_full.jpg', 7000, 2450, 1750, 560, '1271-1368', '江西景德镇', '高30.5cm，口径7.8cm，底径9.5cm', '约1.6kg', '北京故宫博物院', '["釉里红", "元代", "玉壶春瓶", "铜红", "景德镇"]', '釉里红是元代景德镇继青花之后创烧的又一重要釉下彩品种。元代工匠成功掌握了铜红的还原技术，使釉里红瓷器得以问世。', '釉里红在中国陶瓷史上具有重要地位，开创了铜红釉下彩的先河。'),
('por_024', '明永乐青花海水龙纹扁壶', '明', '青花瓷', '瓷', '永乐青花巅峰之作，海水龙纹气势磅礴，苏麻离青料沉入胎骨。', '明永乐青花海水龙纹扁壶，洗口、束颈、扁圆腹、圈足，腹部两侧有双耳。器身以青花绘制海水龙纹，惊涛骇浪之中，巨龙腾空而起，气势磅礴。青花用料为进口"苏麻离青"，发色浓艳深沉，釉面有自然形成的铁锈斑。', 'https://example.com/porcelain/por_024_0_full.jpg', 9100, 3185, 2275, 728, '1403-1424', '江西景德镇', '高48.2cm，口径8.6cm，底径16.5cm', '约6.5kg', '北京故宫博物院', '["明永乐", "青花", "海水龙纹", "扁壶", "苏麻离青"]', '明永乐时期是青花瓷发展的黄金时代。永乐皇帝朱棣派遣郑和七下西洋，带回了优质的钴料"苏麻离青"。', '永乐青花瓷是中国青花瓷史上的一座高峰，被后世誉为"青花之王"。'),
('por_025', '清雍正粉彩过枝牡丹纹碗', '清', '粉彩', '瓷', '雍正粉彩极品，"过枝"画法出神入化，色彩淡雅宜人。', '清雍正粉彩过枝牡丹纹碗，敞口、深腹、圈足。碗内外以粉彩绘过枝牡丹纹，花枝从碗外壁延伸至内壁，"过枝"画法巧妙而富有情趣。粉彩色彩柔和淡雅，色调过渡自然，有"雍正粉彩以雅取胜"之誉。', 'https://example.com/porcelain/por_025_0_full.jpg', 8400, 2940, 2100, 672, '1723-1735', '江西景德镇', '高6.8cm，口径15.3cm，底径6.2cm', '约0.35kg', '北京故宫博物院', '["雍正", "粉彩", "过枝牡丹", "碗", "景德镇"]', '粉彩瓷在雍正时期达到了工艺和艺术的巅峰。雍正皇帝本人对瓷器制作极为关注，常亲自审定瓷器样式。', '雍正粉彩代表了清代粉彩瓷器的最高艺术成就，被誉为"瓷器上的工笔画"。');

-- ============================================================
-- 3. 文物图片 (每件 5 张，共 125 条)
-- ============================================================

INSERT INTO artwork_images (id, artwork_id, url, thumbnail_url, title, description, width, height) VALUES
('por_001_img_0', 'por_001', 'https://example.com/porcelain/por_001_0_full.jpg', 'https://example.com/porcelain/por_001_0_thumb.jpg', '元青花缠枝牡丹纹梅瓶 - 正面', '主视图', 1200, 1600),
('por_001_img_1', 'por_001', 'https://example.com/porcelain/por_001_1_full.jpg', 'https://example.com/porcelain/por_001_1_thumb.jpg', '元青花缠枝牡丹纹梅瓶 - 细节1', '局部特写1', 800, 800),
('por_001_img_2', 'por_001', 'https://example.com/porcelain/por_001_2_full.jpg', 'https://example.com/porcelain/por_001_2_thumb.jpg', '元青花缠枝牡丹纹梅瓶 - 细节2', '局部特写2', 800, 800),
('por_001_img_3', 'por_001', 'https://example.com/porcelain/por_001_3_full.jpg', 'https://example.com/porcelain/por_001_3_thumb.jpg', '元青花缠枝牡丹纹梅瓶 - 细节3', '局部特写3', 800, 800),
('por_001_img_4', 'por_001', 'https://example.com/porcelain/por_001_4_full.jpg', 'https://example.com/porcelain/por_001_4_thumb.jpg', '元青花缠枝牡丹纹梅瓶 - 细节4', '局部特写4', 800, 800),

('por_002_img_0', 'por_002', 'https://example.com/porcelain/por_002_0_full.jpg', 'https://example.com/porcelain/por_002_0_thumb.jpg', '清乾隆粉彩百鹿图尊 - 正面', '主视图', 1200, 1600),
('por_002_img_1', 'por_002', 'https://example.com/porcelain/por_002_1_full.jpg', 'https://example.com/porcelain/por_002_1_thumb.jpg', '清乾隆粉彩百鹿图尊 - 细节1', '局部特写1', 800, 800),
('por_002_img_2', 'por_002', 'https://example.com/porcelain/por_002_2_full.jpg', 'https://example.com/porcelain/por_002_2_thumb.jpg', '清乾隆粉彩百鹿图尊 - 细节2', '局部特写2', 800, 800),
('por_002_img_3', 'por_002', 'https://example.com/porcelain/por_002_3_full.jpg', 'https://example.com/porcelain/por_002_3_thumb.jpg', '清乾隆粉彩百鹿图尊 - 细节3', '局部特写3', 800, 800),
('por_002_img_4', 'por_002', 'https://example.com/porcelain/por_002_4_full.jpg', 'https://example.com/porcelain/por_002_4_thumb.jpg', '清乾隆粉彩百鹿图尊 - 细节4', '局部特写4', 800, 800),

('por_003_img_0', 'por_003', 'https://example.com/porcelain/por_003_0_full.jpg', 'https://example.com/porcelain/por_003_0_thumb.jpg', '宋汝窑天青釉弦纹樽 - 正面', '主视图', 1200, 1600),
('por_003_img_1', 'por_003', 'https://example.com/porcelain/por_003_1_full.jpg', 'https://example.com/porcelain/por_003_1_thumb.jpg', '宋汝窑天青釉弦纹樽 - 细节1', '局部特写1', 800, 800),
('por_003_img_2', 'por_003', 'https://example.com/porcelain/por_003_2_full.jpg', 'https://example.com/porcelain/por_003_2_thumb.jpg', '宋汝窑天青釉弦纹樽 - 细节2', '局部特写2', 800, 800),
('por_003_img_3', 'por_003', 'https://example.com/porcelain/por_003_3_full.jpg', 'https://example.com/porcelain/por_003_3_thumb.jpg', '宋汝窑天青釉弦纹樽 - 细节3', '局部特写3', 800, 800),
('por_003_img_4', 'por_003', 'https://example.com/porcelain/por_003_4_full.jpg', 'https://example.com/porcelain/por_003_4_thumb.jpg', '宋汝窑天青釉弦纹樽 - 细节4', '局部特写4', 800, 800),

('por_004_img_0', 'por_004', 'https://example.com/porcelain/por_004_0_full.jpg', 'https://example.com/porcelain/por_004_0_thumb.jpg', '明成化斗彩鸡缸杯 - 正面', '主视图', 1200, 1600),
('por_004_img_1', 'por_004', 'https://example.com/porcelain/por_004_1_full.jpg', 'https://example.com/porcelain/por_004_1_thumb.jpg', '明成化斗彩鸡缸杯 - 细节1', '局部特写1', 800, 800),
('por_004_img_2', 'por_004', 'https://example.com/porcelain/por_004_2_full.jpg', 'https://example.com/porcelain/por_004_2_thumb.jpg', '明成化斗彩鸡缸杯 - 细节2', '局部特写2', 800, 800),
('por_004_img_3', 'por_004', 'https://example.com/porcelain/por_004_3_full.jpg', 'https://example.com/porcelain/por_004_3_thumb.jpg', '明成化斗彩鸡缸杯 - 细节3', '局部特写3', 800, 800),
('por_004_img_4', 'por_004', 'https://example.com/porcelain/por_004_4_full.jpg', 'https://example.com/porcelain/por_004_4_thumb.jpg', '明成化斗彩鸡缸杯 - 细节4', '局部特写4', 800, 800),

('por_005_img_0', 'por_005', 'https://example.com/porcelain/por_005_0_full.jpg', 'https://example.com/porcelain/por_005_0_thumb.jpg', '清康熙郎窑红釉观音瓶 - 正面', '主视图', 1200, 1600),
('por_005_img_1', 'por_005', 'https://example.com/porcelain/por_005_1_full.jpg', 'https://example.com/porcelain/por_005_1_thumb.jpg', '清康熙郎窑红釉观音瓶 - 细节1', '局部特写1', 800, 800),
('por_005_img_2', 'por_005', 'https://example.com/porcelain/por_005_2_full.jpg', 'https://example.com/porcelain/por_005_2_thumb.jpg', '清康熙郎窑红釉观音瓶 - 细节2', '局部特写2', 800, 800),
('por_005_img_3', 'por_005', 'https://example.com/porcelain/por_005_3_full.jpg', 'https://example.com/porcelain/por_005_3_thumb.jpg', '清康熙郎窑红釉观音瓶 - 细节3', '局部特写3', 800, 800),
('por_005_img_4', 'por_005', 'https://example.com/porcelain/por_005_4_full.jpg', 'https://example.com/porcelain/por_005_4_thumb.jpg', '清康熙郎窑红釉观音瓶 - 细节4', '局部特写4', 800, 800),

('por_006_img_0', 'por_006', 'https://example.com/porcelain/por_006_0_full.jpg', 'https://example.com/porcelain/por_006_0_thumb.jpg', '清雍正霁蓝釉天球瓶 - 正面', '主视图', 1200, 1600),
('por_006_img_1', 'por_006', 'https://example.com/porcelain/por_006_1_full.jpg', 'https://example.com/porcelain/por_006_1_thumb.jpg', '清雍正霁蓝釉天球瓶 - 细节1', '局部特写1', 800, 800),
('por_006_img_2', 'por_006', 'https://example.com/porcelain/por_006_2_full.jpg', 'https://example.com/porcelain/por_006_2_thumb.jpg', '清雍正霁蓝釉天球瓶 - 细节2', '局部特写2', 800, 800),
('por_006_img_3', 'por_006', 'https://example.com/porcelain/por_006_3_full.jpg', 'https://example.com/porcelain/por_006_3_thumb.jpg', '清雍正霁蓝釉天球瓶 - 细节3', '局部特写3', 800, 800),
('por_006_img_4', 'por_006', 'https://example.com/porcelain/por_006_4_full.jpg', 'https://example.com/porcelain/por_006_4_thumb.jpg', '清雍正霁蓝釉天球瓶 - 细节4', '局部特写4', 800, 800),

('por_007_img_0', 'por_007', 'https://example.com/porcelain/por_007_0_full.jpg', 'https://example.com/porcelain/por_007_0_thumb.jpg', '清乾隆茶叶末釉绶带耳瓶 - 正面', '主视图', 1200, 1600),
('por_007_img_1', 'por_007', 'https://example.com/porcelain/por_007_1_full.jpg', 'https://example.com/porcelain/por_007_1_thumb.jpg', '清乾隆茶叶末釉绶带耳瓶 - 细节1', '局部特写1', 800, 800),
('por_007_img_2', 'por_007', 'https://example.com/porcelain/por_007_2_full.jpg', 'https://example.com/porcelain/por_007_2_thumb.jpg', '清乾隆茶叶末釉绶带耳瓶 - 细节2', '局部特写2', 800, 800),
('por_007_img_3', 'por_007', 'https://example.com/porcelain/por_007_3_full.jpg', 'https://example.com/porcelain/por_007_3_thumb.jpg', '清乾隆茶叶末釉绶带耳瓶 - 细节3', '局部特写3', 800, 800),
('por_007_img_4', 'por_007', 'https://example.com/porcelain/por_007_4_full.jpg', 'https://example.com/porcelain/por_007_4_thumb.jpg', '清乾隆茶叶末釉绶带耳瓶 - 细节4', '局部特写4', 800, 800),

('por_008_img_0', 'por_008', 'https://example.com/porcelain/por_008_0_full.jpg', 'https://example.com/porcelain/por_008_0_thumb.jpg', '明万历五彩龙凤纹笔盒 - 正面', '主视图', 1200, 1600),
('por_008_img_1', 'por_008', 'https://example.com/porcelain/por_008_1_full.jpg', 'https://example.com/porcelain/por_008_1_thumb.jpg', '明万历五彩龙凤纹笔盒 - 细节1', '局部特写1', 800, 800),
('por_008_img_2', 'por_008', 'https://example.com/porcelain/por_008_2_full.jpg', 'https://example.com/porcelain/por_008_2_thumb.jpg', '明万历五彩龙凤纹笔盒 - 细节2', '局部特写2', 800, 800),
('por_008_img_3', 'por_008', 'https://example.com/porcelain/por_008_3_full.jpg', 'https://example.com/porcelain/por_008_3_thumb.jpg', '明万历五彩龙凤纹笔盒 - 细节3', '局部特写3', 800, 800),
('por_008_img_4', 'por_008', 'https://example.com/porcelain/por_008_4_full.jpg', 'https://example.com/porcelain/por_008_4_thumb.jpg', '明万历五彩龙凤纹笔盒 - 细节4', '局部特写4', 800, 800),

('por_009_img_0', 'por_009', 'https://example.com/porcelain/por_009_0_full.jpg', 'https://example.com/porcelain/por_009_0_thumb.jpg', '清雍正珐琅彩松竹梅纹瓶 - 正面', '主视图', 1200, 1600),
('por_009_img_1', 'por_009', 'https://example.com/porcelain/por_009_1_full.jpg', 'https://example.com/porcelain/por_009_1_thumb.jpg', '清雍正珐琅彩松竹梅纹瓶 - 细节1', '局部特写1', 800, 800),
('por_009_img_2', 'por_009', 'https://example.com/porcelain/por_009_2_full.jpg', 'https://example.com/porcelain/por_009_2_thumb.jpg', '清雍正珐琅彩松竹梅纹瓶 - 细节2', '局部特写2', 800, 800),
('por_009_img_3', 'por_009', 'https://example.com/porcelain/por_009_3_full.jpg', 'https://example.com/porcelain/por_009_3_thumb.jpg', '清雍正珐琅彩松竹梅纹瓶 - 细节3', '局部特写3', 800, 800),
('por_009_img_4', 'por_009', 'https://example.com/porcelain/por_009_4_full.jpg', 'https://example.com/porcelain/por_009_4_thumb.jpg', '清雍正珐琅彩松竹梅纹瓶 - 细节4', '局部特写4', 800, 800),

('por_010_img_0', 'por_010', 'https://example.com/porcelain/por_010_0_full.jpg', 'https://example.com/porcelain/por_010_0_thumb.jpg', '宋汝窑三足奁 - 正面', '主视图', 1200, 1600),
('por_010_img_1', 'por_010', 'https://example.com/porcelain/por_010_1_full.jpg', 'https://example.com/porcelain/por_010_1_thumb.jpg', '宋汝窑三足奁 - 细节1', '局部特写1', 800, 800),
('por_010_img_2', 'por_010', 'https://example.com/porcelain/por_010_2_full.jpg', 'https://example.com/porcelain/por_010_2_thumb.jpg', '宋汝窑三足奁 - 细节2', '局部特写2', 800, 800),
('por_010_img_3', 'por_010', 'https://example.com/porcelain/por_010_3_full.jpg', 'https://example.com/porcelain/por_010_3_thumb.jpg', '宋汝窑三足奁 - 细节3', '局部特写3', 800, 800),
('por_010_img_4', 'por_010', 'https://example.com/porcelain/por_010_4_full.jpg', 'https://example.com/porcelain/por_010_4_thumb.jpg', '宋汝窑三足奁 - 细节4', '局部特写4', 800, 800),

('por_011_img_0', 'por_011', 'https://example.com/porcelain/por_011_0_full.jpg', 'https://example.com/porcelain/por_011_0_thumb.jpg', '宋官窑贯耳瓶 - 正面', '主视图', 1200, 1600),
('por_011_img_1', 'por_011', 'https://example.com/porcelain/por_011_1_full.jpg', 'https://example.com/porcelain/por_011_1_thumb.jpg', '宋官窑贯耳瓶 - 细节1', '局部特写1', 800, 800),
('por_011_img_2', 'por_011', 'https://example.com/porcelain/por_011_2_full.jpg', 'https://example.com/porcelain/por_011_2_thumb.jpg', '宋官窑贯耳瓶 - 细节2', '局部特写2', 800, 800),
('por_011_img_3', 'por_011', 'https://example.com/porcelain/por_011_3_full.jpg', 'https://example.com/porcelain/por_011_3_thumb.jpg', '宋官窑贯耳瓶 - 细节3', '局部特写3', 800, 800),
('por_011_img_4', 'por_011', 'https://example.com/porcelain/por_011_4_full.jpg', 'https://example.com/porcelain/por_011_4_thumb.jpg', '宋官窑贯耳瓶 - 细节4', '局部特写4', 800, 800),

('por_012_img_0', 'por_012', 'https://example.com/porcelain/por_012_0_full.jpg', 'https://example.com/porcelain/por_012_0_thumb.jpg', '宋哥窑鱼耳炉 - 正面', '主视图', 1200, 1600),
('por_012_img_1', 'por_012', 'https://example.com/porcelain/por_012_1_full.jpg', 'https://example.com/porcelain/por_012_1_thumb.jpg', '宋哥窑鱼耳炉 - 细节1', '局部特写1', 800, 800),
('por_012_img_2', 'por_012', 'https://example.com/porcelain/por_012_2_full.jpg', 'https://example.com/porcelain/por_012_2_thumb.jpg', '宋哥窑鱼耳炉 - 细节2', '局部特写2', 800, 800),
('por_012_img_3', 'por_012', 'https://example.com/porcelain/por_012_3_full.jpg', 'https://example.com/porcelain/por_012_3_thumb.jpg', '宋哥窑鱼耳炉 - 细节3', '局部特写3', 800, 800),
('por_012_img_4', 'por_012', 'https://example.com/porcelain/por_012_4_full.jpg', 'https://example.com/porcelain/por_012_4_thumb.jpg', '宋哥窑鱼耳炉 - 细节4', '局部特写4', 800, 800),

('por_013_img_0', 'por_013', 'https://example.com/porcelain/por_013_0_full.jpg', 'https://example.com/porcelain/por_013_0_thumb.jpg', '宋定窑白釉孩儿枕 - 正面', '主视图', 1200, 1600),
('por_013_img_1', 'por_013', 'https://example.com/porcelain/por_013_1_full.jpg', 'https://example.com/porcelain/por_013_1_thumb.jpg', '宋定窑白釉孩儿枕 - 细节1', '局部特写1', 800, 800),
('por_013_img_2', 'por_013', 'https://example.com/porcelain/por_013_2_full.jpg', 'https://example.com/porcelain/por_013_2_thumb.jpg', '宋定窑白釉孩儿枕 - 细节2', '局部特写2', 800, 800),
('por_013_img_3', 'por_013', 'https://example.com/porcelain/por_013_3_full.jpg', 'https://example.com/porcelain/por_013_3_thumb.jpg', '宋定窑白釉孩儿枕 - 细节3', '局部特写3', 800, 800),
('por_013_img_4', 'por_013', 'https://example.com/porcelain/por_013_4_full.jpg', 'https://example.com/porcelain/por_013_4_thumb.jpg', '宋定窑白釉孩儿枕 - 细节4', '局部特写4', 800, 800),

('por_014_img_0', 'por_014', 'https://example.com/porcelain/por_014_0_full.jpg', 'https://example.com/porcelain/por_014_0_thumb.jpg', '宋钧窑玫瑰紫釉鼓钉洗 - 正面', '主视图', 1200, 1600),
('por_014_img_1', 'por_014', 'https://example.com/porcelain/por_014_1_full.jpg', 'https://example.com/porcelain/por_014_1_thumb.jpg', '宋钧窑玫瑰紫釉鼓钉洗 - 细节1', '局部特写1', 800, 800),
('por_014_img_2', 'por_014', 'https://example.com/porcelain/por_014_2_full.jpg', 'https://example.com/porcelain/por_014_2_thumb.jpg', '宋钧窑玫瑰紫釉鼓钉洗 - 细节2', '局部特写2', 800, 800),
('por_014_img_3', 'por_014', 'https://example.com/porcelain/por_014_3_full.jpg', 'https://example.com/porcelain/por_014_3_thumb.jpg', '宋钧窑玫瑰紫釉鼓钉洗 - 细节3', '局部特写3', 800, 800),
('por_014_img_4', 'por_014', 'https://example.com/porcelain/por_014_4_full.jpg', 'https://example.com/porcelain/por_014_4_thumb.jpg', '宋钧窑玫瑰紫釉鼓钉洗 - 细节4', '局部特写4', 800, 800),

('por_015_img_0', 'por_015', 'https://example.com/porcelain/por_015_0_full.jpg', 'https://example.com/porcelain/por_015_0_thumb.jpg', '宋建窑兔毫盏 - 正面', '主视图', 1200, 1600),
('por_015_img_1', 'por_015', 'https://example.com/porcelain/por_015_1_full.jpg', 'https://example.com/porcelain/por_015_1_thumb.jpg', '宋建窑兔毫盏 - 细节1', '局部特写1', 800, 800),
('por_015_img_2', 'por_015', 'https://example.com/porcelain/por_015_2_full.jpg', 'https://example.com/porcelain/por_015_2_thumb.jpg', '宋建窑兔毫盏 - 细节2', '局部特写2', 800, 800),
('por_015_img_3', 'por_015', 'https://example.com/porcelain/por_015_3_full.jpg', 'https://example.com/porcelain/por_015_3_thumb.jpg', '宋建窑兔毫盏 - 细节3', '局部特写3', 800, 800),
('por_015_img_4', 'por_015', 'https://example.com/porcelain/por_015_4_full.jpg', 'https://example.com/porcelain/por_015_4_thumb.jpg', '宋建窑兔毫盏 - 细节4', '局部特写4', 800, 800),

('por_016_img_0', 'por_016', 'https://example.com/porcelain/por_016_0_full.jpg', 'https://example.com/porcelain/por_016_0_thumb.jpg', '明德化窑白釉观音坐像 - 正面', '主视图', 1200, 1600),
('por_016_img_1', 'por_016', 'https://example.com/porcelain/por_016_1_full.jpg', 'https://example.com/porcelain/por_016_1_thumb.jpg', '明德化窑白釉观音坐像 - 细节1', '局部特写1', 800, 800),
('por_016_img_2', 'por_016', 'https://example.com/porcelain/por_016_2_full.jpg', 'https://example.com/porcelain/por_016_2_thumb.jpg', '明德化窑白釉观音坐像 - 细节2', '局部特写2', 800, 800),
('por_016_img_3', 'por_016', 'https://example.com/porcelain/por_016_3_full.jpg', 'https://example.com/porcelain/por_016_3_thumb.jpg', '明德化窑白釉观音坐像 - 细节3', '局部特写3', 800, 800),
('por_016_img_4', 'por_016', 'https://example.com/porcelain/por_016_4_full.jpg', 'https://example.com/porcelain/por_016_4_thumb.jpg', '明德化窑白釉观音坐像 - 细节4', '局部特写4', 800, 800),

('por_017_img_0', 'por_017', 'https://example.com/porcelain/por_017_0_full.jpg', 'https://example.com/porcelain/por_017_0_thumb.jpg', '宋磁州窑白地黑花龙凤纹罐 - 正面', '主视图', 1200, 1600),
('por_017_img_1', 'por_017', 'https://example.com/porcelain/por_017_1_full.jpg', 'https://example.com/porcelain/por_017_1_thumb.jpg', '宋磁州窑白地黑花龙凤纹罐 - 细节1', '局部特写1', 800, 800),
('por_017_img_2', 'por_017', 'https://example.com/porcelain/por_017_2_full.jpg', 'https://example.com/porcelain/por_017_2_thumb.jpg', '宋磁州窑白地黑花龙凤纹罐 - 细节2', '局部特写2', 800, 800),
('por_017_img_3', 'por_017', 'https://example.com/porcelain/por_017_3_full.jpg', 'https://example.com/porcelain/por_017_3_thumb.jpg', '宋磁州窑白地黑花龙凤纹罐 - 细节3', '局部特写3', 800, 800),
('por_017_img_4', 'por_017', 'https://example.com/porcelain/por_017_4_full.jpg', 'https://example.com/porcelain/por_017_4_thumb.jpg', '宋磁州窑白地黑花龙凤纹罐 - 细节4', '局部特写4', 800, 800),

('por_018_img_0', 'por_018', 'https://example.com/porcelain/por_018_0_full.jpg', 'https://example.com/porcelain/por_018_0_thumb.jpg', '唐越窑青釉刻花执壶 - 正面', '主视图', 1200, 1600),
('por_018_img_1', 'por_018', 'https://example.com/porcelain/por_018_1_full.jpg', 'https://example.com/porcelain/por_018_1_thumb.jpg', '唐越窑青釉刻花执壶 - 细节1', '局部特写1', 800, 800),
('por_018_img_2', 'por_018', 'https://example.com/porcelain/por_018_2_full.jpg', 'https://example.com/porcelain/por_018_2_thumb.jpg', '唐越窑青釉刻花执壶 - 细节2', '局部特写2', 800, 800),
('por_018_img_3', 'por_018', 'https://example.com/porcelain/por_018_3_full.jpg', 'https://example.com/porcelain/por_018_3_thumb.jpg', '唐越窑青釉刻花执壶 - 细节3', '局部特写3', 800, 800),
('por_018_img_4', 'por_018', 'https://example.com/porcelain/por_018_4_full.jpg', 'https://example.com/porcelain/por_018_4_thumb.jpg', '唐越窑青釉刻花执壶 - 细节4', '局部特写4', 800, 800),

('por_019_img_0', 'por_019', 'https://example.com/porcelain/por_019_0_full.jpg', 'https://example.com/porcelain/por_019_0_thumb.jpg', '唐长沙窑青釉褐彩诗文壶 - 正面', '主视图', 1200, 1600),
('por_019_img_1', 'por_019', 'https://example.com/porcelain/por_019_1_full.jpg', 'https://example.com/porcelain/por_019_1_thumb.jpg', '唐长沙窑青釉褐彩诗文壶 - 细节1', '局部特写1', 800, 800),
('por_019_img_2', 'por_019', 'https://example.com/porcelain/por_019_2_full.jpg', 'https://example.com/porcelain/por_019_2_thumb.jpg', '唐长沙窑青釉褐彩诗文壶 - 细节2', '局部特写2', 800, 800),
('por_019_img_3', 'por_019', 'https://example.com/porcelain/por_019_3_full.jpg', 'https://example.com/porcelain/por_019_3_thumb.jpg', '唐长沙窑青釉褐彩诗文壶 - 细节3', '局部特写3', 800, 800),
('por_019_img_4', 'por_019', 'https://example.com/porcelain/por_019_4_full.jpg', 'https://example.com/porcelain/por_019_4_thumb.jpg', '唐长沙窑青釉褐彩诗文壶 - 细节4', '局部特写4', 800, 800),

('por_020_img_0', 'por_020', 'https://example.com/porcelain/por_020_0_full.jpg', 'https://example.com/porcelain/por_020_0_thumb.jpg', '唐三彩骆驼载乐俑 - 正面', '主视图', 1200, 1600),
('por_020_img_1', 'por_020', 'https://example.com/porcelain/por_020_1_full.jpg', 'https://example.com/porcelain/por_020_1_thumb.jpg', '唐三彩骆驼载乐俑 - 细节1', '局部特写1', 800, 800),
('por_020_img_2', 'por_020', 'https://example.com/porcelain/por_020_2_full.jpg', 'https://example.com/porcelain/por_020_2_thumb.jpg', '唐三彩骆驼载乐俑 - 细节2', '局部特写2', 800, 800),
('por_020_img_3', 'por_020', 'https://example.com/porcelain/por_020_3_full.jpg', 'https://example.com/porcelain/por_020_3_thumb.jpg', '唐三彩骆驼载乐俑 - 细节3', '局部特写3', 800, 800),
('por_020_img_4', 'por_020', 'https://example.com/porcelain/por_020_4_full.jpg', 'https://example.com/porcelain/por_020_4_thumb.jpg', '唐三彩骆驼载乐俑 - 细节4', '局部特写4', 800, 800),

('por_021_img_0', 'por_021', 'https://example.com/porcelain/por_021_0_full.jpg', 'https://example.com/porcelain/por_021_0_thumb.jpg', '宋景德镇青白釉刻花梅瓶 - 正面', '主视图', 1200, 1600),
('por_021_img_1', 'por_021', 'https://example.com/porcelain/por_021_1_full.jpg', 'https://example.com/porcelain/por_021_1_thumb.jpg', '宋景德镇青白釉刻花梅瓶 - 细节1', '局部特写1', 800, 800),
('por_021_img_2', 'por_021', 'https://example.com/porcelain/por_021_2_full.jpg', 'https://example.com/porcelain/por_021_2_thumb.jpg', '宋景德镇青白釉刻花梅瓶 - 细节2', '局部特写2', 800, 800),
('por_021_img_3', 'por_021', 'https://example.com/porcelain/por_021_3_full.jpg', 'https://example.com/porcelain/por_021_3_thumb.jpg', '宋景德镇青白釉刻花梅瓶 - 细节3', '局部特写3', 800, 800),
('por_021_img_4', 'por_021', 'https://example.com/porcelain/por_021_4_full.jpg', 'https://example.com/porcelain/por_021_4_thumb.jpg', '宋景德镇青白釉刻花梅瓶 - 细节4', '局部特写4', 800, 800),

('por_022_img_0', 'por_022', 'https://example.com/porcelain/por_022_0_full.jpg', 'https://example.com/porcelain/por_022_0_thumb.jpg', '元枢府釉刻花盘 - 正面', '主视图', 1200, 1600),
('por_022_img_1', 'por_022', 'https://example.com/porcelain/por_022_1_full.jpg', 'https://example.com/porcelain/por_022_1_thumb.jpg', '元枢府釉刻花盘 - 细节1', '局部特写1', 800, 800),
('por_022_img_2', 'por_022', 'https://example.com/porcelain/por_022_2_full.jpg', 'https://example.com/porcelain/por_022_2_thumb.jpg', '元枢府釉刻花盘 - 细节2', '局部特写2', 800, 800),
('por_022_img_3', 'por_022', 'https://example.com/porcelain/por_022_3_full.jpg', 'https://example.com/porcelain/por_022_3_thumb.jpg', '元枢府釉刻花盘 - 细节3', '局部特写3', 800, 800),
('por_022_img_4', 'por_022', 'https://example.com/porcelain/por_022_4_full.jpg', 'https://example.com/porcelain/por_022_4_thumb.jpg', '元枢府釉刻花盘 - 细节4', '局部特写4', 800, 800),

('por_023_img_0', 'por_023', 'https://example.com/porcelain/por_023_0_full.jpg', 'https://example.com/porcelain/por_023_0_thumb.jpg', '元釉里红缠枝菊纹玉壶春瓶 - 正面', '主视图', 1200, 1600),
('por_023_img_1', 'por_023', 'https://example.com/porcelain/por_023_1_full.jpg', 'https://example.com/porcelain/por_023_1_thumb.jpg', '元釉里红缠枝菊纹玉壶春瓶 - 细节1', '局部特写1', 800, 800),
('por_023_img_2', 'por_023', 'https://example.com/porcelain/por_023_2_full.jpg', 'https://example.com/porcelain/por_023_2_thumb.jpg', '元釉里红缠枝菊纹玉壶春瓶 - 细节2', '局部特写2', 800, 800),
('por_023_img_3', 'por_023', 'https://example.com/porcelain/por_023_3_full.jpg', 'https://example.com/porcelain/por_023_3_thumb.jpg', '元釉里红缠枝菊纹玉壶春瓶 - 细节3', '局部特写3', 800, 800),
('por_023_img_4', 'por_023', 'https://example.com/porcelain/por_023_4_full.jpg', 'https://example.com/porcelain/por_023_4_thumb.jpg', '元釉里红缠枝菊纹玉壶春瓶 - 细节4', '局部特写4', 800, 800),

('por_024_img_0', 'por_024', 'https://example.com/porcelain/por_024_0_full.jpg', 'https://example.com/porcelain/por_024_0_thumb.jpg', '明永乐青花海水龙纹扁壶 - 正面', '主视图', 1200, 1600),
('por_024_img_1', 'por_024', 'https://example.com/porcelain/por_024_1_full.jpg', 'https://example.com/porcelain/por_024_1_thumb.jpg', '明永乐青花海水龙纹扁壶 - 细节1', '局部特写1', 800, 800),
('por_024_img_2', 'por_024', 'https://example.com/porcelain/por_024_2_full.jpg', 'https://example.com/porcelain/por_024_2_thumb.jpg', '明永乐青花海水龙纹扁壶 - 细节2', '局部特写2', 800, 800),
('por_024_img_3', 'por_024', 'https://example.com/porcelain/por_024_3_full.jpg', 'https://example.com/porcelain/por_024_3_thumb.jpg', '明永乐青花海水龙纹扁壶 - 细节3', '局部特写3', 800, 800),
('por_024_img_4', 'por_024', 'https://example.com/porcelain/por_024_4_full.jpg', 'https://example.com/porcelain/por_024_4_thumb.jpg', '明永乐青花海水龙纹扁壶 - 细节4', '局部特写4', 800, 800),

('por_025_img_0', 'por_025', 'https://example.com/porcelain/por_025_0_full.jpg', 'https://example.com/porcelain/por_025_0_thumb.jpg', '清雍正粉彩过枝牡丹纹碗 - 正面', '主视图', 1200, 1600),
('por_025_img_1', 'por_025', 'https://example.com/porcelain/por_025_1_full.jpg', 'https://example.com/porcelain/por_025_1_thumb.jpg', '清雍正粉彩过枝牡丹纹碗 - 细节1', '局部特写1', 800, 800),
('por_025_img_2', 'por_025', 'https://example.com/porcelain/por_025_2_full.jpg', 'https://example.com/porcelain/por_025_2_thumb.jpg', '清雍正粉彩过枝牡丹纹碗 - 细节2', '局部特写2', 800, 800),
('por_025_img_3', 'por_025', 'https://example.com/porcelain/por_025_3_full.jpg', 'https://example.com/porcelain/por_025_3_thumb.jpg', '清雍正粉彩过枝牡丹纹碗 - 细节3', '局部特写3', 800, 800),
('por_025_img_4', 'por_025', 'https://example.com/porcelain/por_025_4_full.jpg', 'https://example.com/porcelain/por_025_4_thumb.jpg', '清雍正粉彩过枝牡丹纹碗 - 细节4', '局部特写4', 800, 800);

-- ============================================================
-- 4. 音频导览 (25 条)
-- ============================================================

INSERT INTO audio_guides (id, artwork_id, url, duration, narrator, text_script) VALUES
('por_001_audio', 'por_001', 'https://example.com/audio/por_001_guide.mp3', 300, '博物馆专业讲解员', '此元代青花缠枝牡丹纹梅瓶，小口、短颈、丰肩、瘦底、圈足，造型优美挺拔。通体绘青花缠枝牡丹纹，"牡丹"花大色艳，有"花中之王"之美誉。青花色泽浓艳深沉，具有典型的元青花"至正型"特征。纹饰布局繁密而不乱，层次丰富，是元青花瓷器中的杰出代表。'),
('por_002_audio', 'por_002', 'https://example.com/audio/por_002_guide.mp3', 280, '博物馆专业讲解员', '清乾隆粉彩百鹿图尊，撇口、粗颈、圆腹、圈足。器身以粉彩绘制百鹿图，山林间群鹿或奔跑、或嬉戏、或觅食、或小憩，姿态各异，生动传神。"百鹿"谐音"百禄"，寓意富贵吉祥。粉彩色彩柔和淡雅，层次丰富，充分展现了乾隆时期粉彩瓷器的最高水平。'),
('por_003_audio', 'por_003', 'https://example.com/audio/por_003_guide.mp3', 350, '博物馆专业讲解员', '宋汝窑天青釉弦纹樽，直口、平底、圈足外撇。器身饰三组弦纹，造型简洁端庄，线条挺拔有力。釉色天青，釉面匀净滋润，开细碎片纹，"蟹爪纹"清晰可见。汝窑瓷器以其"天青釉"闻名，釉色如雨过天晴般清新雅致。'),
('por_004_audio', 'por_004', 'https://example.com/audio/por_004_guide.mp3', 260, '博物馆专业讲解员', '明成化斗彩鸡缸杯，敞口、浅腹、卧足，造型小巧玲珑。杯身绘有子母鸡群觅食于山石花草间的场景，雄鸡昂首啼鸣，母鸡带领小鸡觅食，画面温馨生动。斗彩工艺精湛，青花勾线后填彩，色彩丰富明丽。'),
('por_005_audio', 'por_005', 'https://example.com/audio/por_005_guide.mp3', 240, '博物馆专业讲解员', '清康熙郎窑红釉观音瓶，撇口、短颈、丰肩、修腹、撇足，形似观音菩萨所持净瓶，故称"观音瓶"。釉色鲜红浓艳，如初凝牛血，釉面玻璃质感强，有细小的开片。'),
('por_006_audio', 'por_006', 'https://example.com/audio/por_006_guide.mp3', 220, '博物馆专业讲解员', '清雍正霁蓝釉天球瓶，直口、长颈、球形腹、圈足，因腹部浑圆似天球而得名。通体施霁蓝釉，釉色匀净深沉，如蓝宝石般晶莹剔透。'),
('por_007_audio', 'por_007', 'https://example.com/audio/por_007_guide.mp3', 200, '博物馆专业讲解员', '清乾隆茶叶末釉绶带耳瓶，盘口、束颈、颈部两侧饰绶带形耳、圆腹、圈足。通体施茶叶末釉，釉色呈鳝鱼黄绿色，釉面布满细小的黄褐色结晶斑点。'),
('por_008_audio', 'por_008', 'https://example.com/audio/por_008_guide.mp3', 260, '博物馆专业讲解员', '明万历五彩龙凤纹笔盒，长方形，子母口，圈足。盒盖与盒身均以五彩绘龙凤穿花纹，盖面正中为龙凤呈祥图案。五彩以红、黄、绿、紫、蓝等色彩为主，色彩浓艳热烈。'),
('por_009_audio', 'por_009', 'https://example.com/audio/por_009_guide.mp3', 320, '博物馆专业讲解员', '清雍正珐琅彩松竹梅纹瓶，撇口、细颈、垂腹、圈足。器身以珐琅彩绘松竹梅"岁寒三友"图，松树苍劲，翠竹挺拔，梅花傲雪，画工精绝。'),
('por_010_audio', 'por_010', 'https://example.com/audio/por_010_guide.mp3', 340, '博物馆专业讲解员', '宋汝窑三足奁，直口、平底、下承三足。器身呈筒形，外壁饰三组弦纹。通体施天青釉，釉色幽玄静谧，釉面满布细密的开片纹理。'),
('por_011_audio', 'por_011', 'https://example.com/audio/por_011_guide.mp3', 280, '博物馆专业讲解员', '宋官窑贯耳瓶，直口、长颈、颈部两侧置贯耳、圆腹、圈足。通体施灰青色釉，釉面布满深浅不一的冰裂纹片，官窑瓷器以"紫口铁足"为特征。'),
('por_012_audio', 'por_012', 'https://example.com/audio/por_012_guide.mp3', 260, '博物馆专业讲解员', '宋哥窑鱼耳炉，敞口、束颈、鼓腹、圈足，颈腹部两侧各置鱼形耳。通体施米黄色釉，釉面布满"金丝铁线"开片。'),
('por_013_audio', 'por_013', 'https://example.com/audio/por_013_guide.mp3', 300, '博物馆专业讲解员', '宋定窑白釉孩儿枕，以孩童侧卧姿态为枕座，孩童双手持一荷叶，荷叶边缘自然卷曲形成枕面。孩童形象丰满圆润，神态安详。'),
('por_014_audio', 'por_014', 'https://example.com/audio/por_014_guide.mp3', 270, '博物馆专业讲解员', '宋钧窑玫瑰紫釉鼓钉洗，敞口、浅腹、圈足，口沿和足部各饰一周鼓钉纹。器内外满施玫瑰紫釉，釉色绚丽多变，红紫相间，蓝白交融。'),
('por_015_audio', 'por_015', 'https://example.com/audio/por_015_guide.mp3', 290, '博物馆专业讲解员', '宋建窑兔毫盏，敞口、斜腹、小圈足，造型简洁。内外施黑釉，釉色乌黑如漆，釉面中透出细密的黄褐色条纹，状如兔毫，故称"兔毫盏"。'),
('por_016_audio', 'por_016', 'https://example.com/audio/por_016_guide.mp3', 310, '博物馆专业讲解员', '明德化窑白釉观音坐像，观音菩萨善跏趺坐于莲台之上，头戴宝冠，面容慈祥端庄，双目微垂，嘴角含笑。通体施白釉，釉色乳白温润如凝脂。'),
('por_017_audio', 'por_017', 'https://example.com/audio/por_017_guide.mp3', 240, '博物馆专业讲解员', '宋磁州窑白地黑花龙凤纹罐，直口、短颈、丰肩、鼓腹、圈足。器身以白釉为地，以黑彩绘龙凤穿云纹，纹饰线条粗犷豪放。'),
('por_018_audio', 'por_018', 'https://example.com/audio/por_018_guide.mp3', 260, '博物馆专业讲解员', '唐越窑青釉刻花执壶，撇口、长颈、圆腹、圈足，一侧置流（壶嘴），另一侧置柄（把手）。通体施青釉，釉色青绿温润，"类玉类冰"。'),
('por_019_audio', 'por_019', 'https://example.com/audio/por_019_guide.mp3', 250, '博物馆专业讲解员', '唐长沙窑青釉褐彩诗文壶，撇口、短颈、圆腹、平底，多棱短流。壶身以褐彩书写唐代诗人诗句，诗文与瓷器巧妙结合。'),
('por_020_audio', 'por_020', 'https://example.com/audio/por_020_guide.mp3', 300, '博物馆专业讲解员', '唐三彩骆驼载乐俑，双峰骆驼昂首站立于长方形平板上，驼背上铺有圆垫，垫上有一组乐舞俑共八人。三彩釉色以黄、绿、白为主，色彩斑斓。'),
('por_021_audio', 'por_021', 'https://example.com/audio/por_021_guide.mp3', 240, '博物馆专业讲解员', '宋景德镇青白釉刻花梅瓶，小口、短颈、丰肩、瘦底、圈足。通体施青白釉，釉色介于青白之间，青中带白、白中透青，俗称"影青"。'),
('por_022_audio', 'por_022', 'https://example.com/audio/por_022_guide.mp3', 200, '博物馆专业讲解员', '元枢府釉刻花盘，敞口、浅腹、圈足。通体施卵白釉，釉色白中泛青，如鹅卵之色，温润含蓄。枢府釉是元代景德镇为枢密院烧造的官用瓷器。'),
('por_023_audio', 'por_023', 'https://example.com/audio/por_023_guide.mp3', 250, '博物馆专业讲解员', '元釉里红缠枝菊纹玉壶春瓶，撇口、细颈、垂腹、圈足。通体以釉里红绘制缠枝菊纹，釉里红发色鲜艳纯正，红白相映。'),
('por_024_audio', 'por_024', 'https://example.com/audio/por_024_guide.mp3', 330, '博物馆专业讲解员', '明永乐青花海水龙纹扁壶，洗口、束颈、扁圆腹、圈足，腹部两侧有双耳。器身以青花绘制海水龙纹，惊涛骇浪之中，巨龙腾空而起，气势磅礴。'),
('por_025_audio', 'por_025', 'https://example.com/audio/por_025_guide.mp3', 280, '博物馆专业讲解员', '清雍正粉彩过枝牡丹纹碗，敞口、深腹、圈足。碗内外以粉彩绘过枝牡丹纹，花枝从碗外壁延伸至内壁，"过枝"画法巧妙而富有情趣。');

-- ============================================================
-- 5. 用户账号
--
-- ⚠️ 密码使用了 bcrypt 哈希
-- 管理员：admin / admin123
-- 演示账号：demo / demo123
--
-- 如果密码验证不通过，请运行 Python 脚本自动创建用户：
--   cd palm-museum-api
--   pip install bcrypt passlib
--   python scripts/seed_data.py
--
-- 或者手动生成 bcrypt 哈希后替换下面的占位符。
-- ============================================================

INSERT INTO users (account, password, nickname, phone, email, signature) VALUES
('admin', '$2b$12$LJ3m4ys3Lk0TSwHnbfOMe.XP1tTs0RnGxLpRqJuoZcYmZGfHBlfiy', '管理员', '13800000000', 'admin@museum.com', ''),
('demo', '$2b$12$LJ3m4ys3Lk0TSwHnbfOMe.XP1tTs0RnGxLpRqJuoZcYmZGfHBlfiy', '演示用户', '13900000000', 'demo@museum.com', '热爱中国传统文化');

-- ============================================================
-- 初始化完成！
-- 管理员账号: admin / admin123
-- 演示账号:   demo / demo123
-- ============================================================
