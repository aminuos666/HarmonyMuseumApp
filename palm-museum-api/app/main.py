from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.database import engine, Base
from app.routers import artworks, auth, users, interactions, history, comments, image_search


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动时：创建数据库表
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="掌上博物馆 API",
    description="Palm Museum - 沉浸式文物鉴赏与互动体验",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS 配置（允许 HarmonyOS 前端跨域访问）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(artworks.router)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(interactions.router)
app.include_router(history.router)
app.include_router(comments.router)
app.include_router(image_search.router)

# 挂载静态文件（音频、图片等）
audio_dir = Path(__file__).resolve().parent.parent / "audio"
audio_dir.mkdir(parents=True, exist_ok=True)
app.mount("/audio", StaticFiles(directory=str(audio_dir)), name="audio")

images_dir = Path(__file__).resolve().parent.parent / "images"
images_dir.mkdir(parents=True, exist_ok=True)
app.mount("/images", StaticFiles(directory=str(images_dir)), name="images")


@app.get("/")
def root():
    return {"message": "掌上博物馆 API 运行中", "docs": "/docs"}
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
