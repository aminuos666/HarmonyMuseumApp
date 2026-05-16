# 数据库配置 - 修改为你自己的 MySQL 连接信息
DATABASE_CONFIG = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "123456",
    "database": "palm_museum",
}

DATABASE_URL = (
    f"mysql+pymysql://{DATABASE_CONFIG['user']}:{DATABASE_CONFIG['password']}"
    f"@{DATABASE_CONFIG['host']}:{DATABASE_CONFIG['port']}"
    f"/{DATABASE_CONFIG['database']}?charset=utf8mb4"
)

# JWT 配置
SECRET_KEY = "palm-museum-secret-key-change-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7天

# 图片存储路径（本地开发用）
UPLOAD_DIR = "uploads"
