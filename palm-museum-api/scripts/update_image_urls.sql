-- ============================================================
-- 更新文物封面图片 URL 为相对路径
-- 后端返回时会自动拼接当前服务器地址
-- 换网络后只需改 HttpClient.ets，数据库不需要动
-- ============================================================

UPDATE artworks SET cover_image = CONCAT('/images/', id, '.jpg');
UPDATE artwork_images SET url = CONCAT('/images/', artwork_id, '.jpg');
UPDATE artwork_images SET thumbnail_url = CONCAT('/images/', artwork_id, '.jpg');
