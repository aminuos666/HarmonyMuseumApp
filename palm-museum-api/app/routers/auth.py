from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.user import RegisterRequest, LoginRequest, UserOut, TokenOut
from app.utils.auth import hash_password, verify_password, create_access_token

router = APIRouter(prefix="/api/auth", tags=["认证"])


@router.post("/register", response_model=TokenOut)
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    """用户注册"""
    existing = db.query(User).filter(User.account == body.account).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="该账号已被注册")

    user = User(
        account=body.account,
        password=hash_password(body.password),
        nickname=body.nickname or body.account,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token({"user_id": user.id, "account": user.account})
    return TokenOut(
        access_token=token,
        user=UserOut.model_validate(user),
    )


@router.post("/login", response_model=TokenOut)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    """用户登录"""
    user = db.query(User).filter(User.account == body.account).first()
    if not user or not verify_password(body.password, user.password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="账号或密码错误")

    token = create_access_token({"user_id": user.id, "account": user.account})
    return TokenOut(
        access_token=token,
        user=UserOut.model_validate(user),
    )


@router.post("/huawei", response_model=TokenOut)
def huawei_login(db: Session = Depends(get_db)):
    """
    华为一键登录（模拟）
    真实场景下应使用华为账号 SDK 获取到用户信息后，查找或创建用户
    """
    user = User(
        account=f"huawei_{User.__table__.columns.id.autoincrement or 0}",
        password=hash_password("huawei_default"),
        nickname="华为用户",
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token({"user_id": user.id, "account": user.account})
    return TokenOut(
        access_token=token,
        user=UserOut.model_validate(user),
    )
