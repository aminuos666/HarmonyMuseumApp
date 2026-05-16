# 掌上博物馆 (Palm Museum) — HarmonyOS ArkTS 应用

## 项目概述

**掌上博物馆** 是一款基于 HarmonyOS 系统、使用 ArkTS 语言与 ArkUI 框架开发的沉浸式文物鉴赏与互动体验应用。本项目以 **中国瓷器** 为核心展示主题，涵盖 25 件横跨唐、宋、元、明、清等朝代的珍贵瓷器文物，为用户提供丰富的文物浏览、语音导览、以图搜图、社交互动等全方位体验。

## 技术架构

### 开发环境
- **操作系统**: HarmonyOS 3.0+ / OpenHarmony
- **开发框架**: ArkUI (声明式 UI)
- **编程语言**: ArkTS (TypeScript 超集)
- **目标设备**: Phone (手机)
- **SDK版本**: API 9+

### 项目结构

```
PalmMuseum/
├── AppScope/                          # 应用全局配置
│   ├── app.json5                      # 应用信息配置
│   └── resources/base/element/        # 全局资源
│
├── entry/src/main/
│   ├── module.json5                   # 模块配置（权限、页面注册）
│   ├── resources/                     # 资源文件
│   │   ├── base/element/              # 颜色、字符串等基础资源
│   │   ├── base/profile/              # 页面路由配置
│   │   ├── zh_CN/element/             # 中文字符串
│   │   └── en_US/element/             # 英文字符串
│   │
│   └── ets/                           # ArkTS 源代码
│       ├── entryability/              # 应用入口
│       │   └── EntryAbility.ts
│       │
│       ├── model/                     # 数据模型
│       │   ├── Artwork.ets            # 文物数据模型
│       │   ├── User.ets               # 用户数据模型
│       │   └── Comment.ets            # 评论数据模型
│       │
│       ├── data/                      # 模拟数据
│       │   ├── MockArtworks.ets       # 25件瓷器文物数据
│       │   ├── MockUsers.ets          # 用户相关模拟数据
│       │   └── MockComments.ets       # 评论模拟数据
│       │
│       ├── service/                   # 业务服务层
│       │   ├── ArtworkService.ets     # 文物数据服务
│       │   ├── UserService.ets        # 用户认证与数据服务
│       │   ├── SearchService.ets      # 文本搜索引擎
│       │   ├── ImageSearchService.ets # 以图搜图服务（核心）
│       │   ├── SpeechService.ets      # 语音合成与识别服务
│       │   ├── ReviewService.ets      # 内容审核服务
│       │   └── NotificationService.ets# 消息通知服务
│       │
│       ├── utils/                     # 工具类
│       │   ├── Constants.ets          # 常量与枚举定义
│       │   ├── ImageFeatureExtractor.ets # 图像特征提取引擎
│       │   └── VectorDatabase.ets     # 向量相似度搜索引擎
│       │
│       ├── component/                 # 可复用 UI 组件
│       │   ├── ArtworkCard.ets        # 文物卡片（含Loading/Empty状态）
│       │   ├── ImageViewer.ets        # 图片查看器（手势缩放/切换）
│       │   ├── AudioPlayer.ets        # 音频播放器（倍速控制）
│       │   └── SearchBar.ets          # 搜索栏组件（含语音入口）
│       │
│       └── pages/                     # 页面
│           ├── Index.ets              # 首页（瀑布流+推荐）
│           ├── ArtworkDetailPage.ets  # 文物详情页
│           ├── SearchPage.ets         # 搜索页（含语音搜索）
│           ├── ImageSearchPage.ets    # ★ 以图搜图页（核心功能）
│           ├── LoginPage.ets          # 登录注册页
│           ├── ProfilePage.ets        # 个人主页
│           ├── CollectionPage.ets     # 收藏夹管理
│           ├── CommentPage.ets        # 评论详情页
│           ├── UploadPage.ets         # 上传内容页
│           ├── UserDynamicPage.ets    # 用户动态页
│           ├── NotificationPage.ets   # 消息通知页
│           └── SettingsPage.ets       # 设置页
│
├── oh-package.json5                   # 包依赖配置
├── build-profile.json5                # 构建配置
└── hvigorfile.ts                      # 构建入口
```

## 功能模块

### 1. 文物浏览 (Artwork Browsing)

| 功能 | 描述 |
|------|------|
| 首页展示 | 两列网格卡片布局，支持按推荐/最热/年代/分类排序 |
| 朝代筛选 | 唐、宋、元、明、清快速筛选标签栏 |
| 每日推荐 | 首页顶部展示每日精选文物推荐 |
| 文物详情 | 高清大图(手势缩放)、基本信息、详细介绍、历史背景、文化价值 |
| 多图切换 | 支持多张文物图片缩略图导航与全屏查看 |
| 音视频播放 | 内嵌语音讲解播放器(支持0.75x-2.0x倍速)与视频讲解 |

### 2. 语音导览 (Voice Guide)

| 功能 | 描述 |
|------|------|
| 语音讲解 | 每件文物提供标准普通话讲解，一键播放 |
| 语音搜索 | 按住话筒按钮语音输入关键词搜索文物 |
| 语音问答 | 用户提问文物相关问题，返回智能语音答案 |

### 3. 用户交互 (User Interaction)

| 功能 | 描述 |
|------|------|
| 点赞收藏 | 对文物点赞和收藏，收藏支持分组管理 |
| 评论系统 | 发表文字评论、回复他人评论(需审核后显示) |
| 上传照片 | 上传文物相关照片(含拍摄地点与说明，需审核) |
| 上传讲解 | 支持上传音频讲解(选做) |
| 上传视频 | 支持上传文物短视频(选做) |

### 4. ★ 以图搜图 (Image Search) — 核心功能

| 功能 | 描述 |
|------|------|
| 相册上传搜索 | 从相册选择图片，系统提取特征检索相似文物 |
| 实时拍照搜索 | 调用摄像头拍摄文物，即时返回匹配结果 |
| 相似度评分 | 按相似度排序展示结果，含进度条可视化评分 |
| 技术实现 | 图像特征提取 → 向量检索 → 余弦相似度计算 |

### 5. 用户系统 (User System)

| 功能 | 描述 |
|------|------|
| 注册登录 | 手机号/邮箱注册、密码登录、华为账号一键登录 |
| 个人主页 | 展示收藏/点赞/上传/浏览历史 |
| 隐私设置 | 公开/仅关注者/私密三级可见性控制 |
| 关注系统 | 关注其他用户，查看关注人动态 |

### 6. 社交功能 (Social Features)

| 功能 | 描述 |
|------|------|
| 用户动态 | 发布图文动态，关联文物，支持跳转详情 |
| 动态互动 | 点赞、评论他人动态 |
| 关注流 | 首页展示关注用户的最新动态 |

### 7. 消息通知 (Notifications)

| 功能 | 描述 |
|------|------|
| 审核通知 | 上传内容通过/未通过审核时推送通知 |
| 关注动态 | 关注用户发布新动态时通知 |
| 每日推荐 | 定时推送文物今日推荐 |
| 通知管理 | 自定义通知类型与频率开关 |

## ★ 以图搜图核心技术实现

### 实现流程

```
用户选择图片/拍照
       ↓
图像预处理 (resize→224x224, 归一化)
       ↓
特征提取 (预训练CNN模型 → 128维特征向量)
       ↓
向量检索 (余弦相似度计算)
       ↓
结果排序 (≥50%相似度阈值过滤)
       ↓
展示 Top-K 结果
```

### 技术方案

| 组件 | 推荐方案 | 当前实现 |
|------|---------|---------|
| 特征提取模型 | ResNet-50 / ViT-B / MobileNetV3 | 模拟特征提取(128维) |
| 向量数据库 | FAISS / Milvus / Qdrant | 内存Map暴力搜索 |
| 相似度计算 | 余弦相似度 / L2距离 | 余弦相似度 |
| 图像预处理 | Image.createImageSource() | 模拟实现 |

### 扩展建议

当文物数据量超过10,000件时，推荐：
1. 使用 FAISS IVF (倒排文件索引) 替代暴力搜索
2. 使用 HNSW (分层可导航小图) 图索引优化召回率
3. 采用 PQ (乘积量化) 压缩特征向量，减少内存占用
4. 在 HarmonyOS 端使用 MindSpore Lite 进行模型推理

## 用户系统说明

用户系统与海外文物知识服务子系统**共用同一用户体系**，理由如下：

1. **一致性**: 用户只需注册一次即可使用全部功能，避免多系统账户割裂
2. **数据共享**: 收藏、点赞、浏览历史等用户数据可在各子系统间共享
3. **成本效益**: 统一认证中心降低开发和维护成本
4. **推荐优化**: 统一用户画像有助于提供更精准的文物推荐

## 数据模型

### 文物 (Artwork)
```
id, name, dynasty, type, material, description, detailDescription,
images[], coverImage, audioGuide, videoGuide, popularity, likeCount,
favoriteCount, commentCount, isLiked, isFavorited, tags[],
historicalBackground, culturalSignificance, imageFeature[](128维)
```

### 用户 (User)
```
id, username, nickname, avatar, phone, email, bio,
followerCount, followingCount, privacyLevel, isVip
```

### 评论 (Comment)
```
id, artworkId, userId, username, userAvatar, content,
likeCount, replies[], reviewStatus
```

## 权限配置

| 权限 | 用途 |
|------|------|
| ohos.permission.INTERNET | 网络通信 |
| ohos.permission.READ_MEDIA | 相册选择图片 |
| ohos.permission.CAMERA | 拍照识别 |
| ohos.permission.MICROPHONE | 语音搜索与导览 |
| ohos.permission.WRITE_MEDIA | 保存图片 |
| ohos.permission.NOTIFICATION_CONTROLLER | 消息通知 |

## 主题配色方案

- **主色**: #8B4513 (棕色/古铜色) — 呼应陶瓷质感
- **辅色**: #D4A574 — 暖金色点缀
- **背景**: #F8F0E6 (米白/宣纸色)
- **强调色**: #E53935 (点赞红)、#FF8F00 (收藏金)
- **文字**: #2C1810 (深棕) / #6B5B4E (辅助)

配色灵感来源于中国传统瓷器釉色与古画卷轴色调。

## 模拟文物数据

项目内置 25 件精美瓷器文物数据，涵盖：

- **唐代**: 越窑青釉刻花执壶、长沙窑诗文壶、唐三彩骆驼载乐俑
- **宋代**: 汝窑天青釉弦纹樽、汝窑三足奁、官窑贯耳瓶、哥窑鱼耳炉、定窑孩儿枕、钧窑玫瑰紫釉鼓钉洗、建窑兔毫盏、磁州窑龙凤罐、景德镇青白瓷梅瓶
- **元代**: 元青花缠枝牡丹纹梅瓶、枢府釉刻花盘、釉里红玉壶春瓶
- **明代**: 成化斗彩鸡缸杯、万历五彩笔盒、德化窑白釉观音像、永乐青花海水龙纹扁壶
- **清代**: 乾隆粉彩百鹿图尊、康熙郎窑红观音瓶、雍正霁蓝釉天球瓶、乾隆茶叶末釉瓶、雍正珐琅彩松竹梅瓶、雍正粉彩过枝牡丹碗

## 运行指南

1. 安装 **DevEco Studio** (HarmonyOS 官方 IDE)
2. 打开项目根目录 `PalmMuseum/`
3. 配置 SDK (API 9+)
4. 连接 HarmonyOS 设备或使用模拟器
5. 点击 Run 构建并运行

> **注意**: 由于项目使用模拟数据，部分功能（如网络请求、摄像头、语音识别、推送通知）在真机调试时需要配置对应的 HarmonyOS API 和华为云服务。
