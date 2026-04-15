# `new-api` + `Allergy` 会员认证 API 契约

日期：2026-04-15

关联文档：

- [member-auth-design.md](./member-auth-design.md)
- [allergy-api-draft.md](../api/allergy-api-draft.md)

## 1. 范围

这份文档只定义会员账号体系改造后的认证接口契约，供以下工作直接使用：

- 后端 controller / service 实现
- 前端 `AuthContext` 接线
- 登录 / 注册 / 找回密码页面联调
- API 测试用例编写

本文件不讨论数据库迁移与旧账号清理，相关内容见：

- [member-auth-migration-cleanup.md](./member-auth-migration-cleanup.md)

## 2. 总体约定

### 2.1 接口前缀

统一使用：

- `/api/auth/*`

### 2.2 鉴权方式

会员登录后继续使用：

- `Authorization: Bearer <member_session_token>`

这个 token 只代表公共站会员登录态，不代表后台管理员 `access_token`。

### 2.3 返回风格

认证接口继续兼容当前前端风格，统一返回对象：

```json
{
  "success": true,
  "message": "",
  "data": {}
}
```

兼容考虑：

- 若当前前端短期内仍依赖顶层 `token` 字段，可在过渡期同时返回顶层字段
- 新页面和新 `AuthContext` 建议统一读取 `data`

### 2.4 错误处理

失败时统一返回：

```json
{
  "success": false,
  "message": "错误说明",
  "code": "ERROR_CODE"
}
```

建议 `code` 取值保持稳定，方便前端区分错误类型。

### 2.5 时间字段

统一返回 ISO 8601 字符串。

例如：

- `2026-04-15T10:30:00+08:00`

## 3. 通用数据结构

### 3.1 MemberProfile

```json
{
  "id": 1001,
  "username": "allergy_user",
  "email": "user@example.com",
  "nickname": "",
  "phone": "",
  "status": "active",
  "emailVerified": true,
  "emailVerifiedAt": "2026-04-15T10:30:00+08:00",
  "createdAt": "2026-04-15T10:31:00+08:00"
}
```

说明：

- `emailVerified` 是前端友好字段
- `emailVerifiedAt` 是明细字段
- `status` 先暴露 `active` / `disabled`

### 3.2 AuthPayload

```json
{
  "token": "member_session_token",
  "user": {
    "id": 1001,
    "username": "allergy_user",
    "email": "user@example.com"
  },
  "profile": {
    "id": 1001,
    "username": "allergy_user",
    "email": "user@example.com",
    "nickname": "",
    "phone": "",
    "status": "active",
    "emailVerified": true,
    "emailVerifiedAt": "2026-04-15T10:30:00+08:00",
    "createdAt": "2026-04-15T10:31:00+08:00"
  }
}
```

## 4. 错误码建议

建议最少固定以下错误码：

| code | 含义 |
|---|---|
| `INVALID_REQUEST` | 参数不合法 |
| `INVALID_EMAIL` | 邮箱格式错误 |
| `EMAIL_ALREADY_EXISTS` | 邮箱已注册 |
| `USERNAME_ALREADY_EXISTS` | 用户名已存在 |
| `CODE_INVALID` | 验证码错误 |
| `CODE_EXPIRED` | 验证码过期 |
| `ACCOUNT_NOT_FOUND` | 账号不存在 |
| `PASSWORD_INCORRECT` | 密码错误 |
| `ACCOUNT_DISABLED` | 会员已禁用 |
| `EMAIL_NOT_VERIFIED` | 邮箱未验证 |
| `MEMBER_PROFILE_REQUIRED` | 非公共站会员账号 |
| `UNAUTHORIZED` | 未登录或登录态失效 |
| `RATE_LIMITED` | 发送过于频繁 |
| `SERVER_ERROR` | 服务端错误 |

说明：

- `MEMBER_PROFILE_REQUIRED` 用于拦截管理员账号直接走公共站登录
- `EMAIL_NOT_VERIFIED` 用于防止未验证账号登录

## 5. 接口定义

### 5.1 发送注册验证码

`POST /api/auth/register/send-code`

用途：

- 在正式注册前验证邮箱归属

请求体：

```json
{
  "email": "user@example.com"
}
```

成功响应：

```json
{
  "success": true,
  "message": "验证码已发送",
  "data": {
    "email": "user@example.com",
    "purpose": "register_verify",
    "expiresInSeconds": 300
  }
}
```

失败示例：

```json
{
  "success": false,
  "message": "邮箱已注册",
  "code": "EMAIL_ALREADY_EXISTS"
}
```

服务端要求：

- 校验邮箱格式
- 校验邮箱未被占用
- 对同一邮箱增加发送频率限制
- 写入 `purpose=register_verify`
- 不返回验证码明文

### 5.2 注册

`POST /api/auth/register`

请求体：

```json
{
  "email": "user@example.com",
  "code": "123456",
  "username": "allergy_user",
  "password": "StrongPassword123",
  "confirmPassword": "StrongPassword123"
}
```

成功响应：

```json
{
  "success": true,
  "message": "注册成功",
  "data": {
    "token": "member_session_token",
    "user": {
      "id": 1001,
      "username": "allergy_user",
      "email": "user@example.com"
    },
    "profile": {
      "id": 1001,
      "username": "allergy_user",
      "email": "user@example.com",
      "nickname": "",
      "phone": "",
      "status": "active",
      "emailVerified": true,
      "emailVerifiedAt": "2026-04-15T10:30:00+08:00",
      "createdAt": "2026-04-15T10:31:00+08:00"
    }
  },
  "token": "member_session_token"
}
```

失败示例：

```json
{
  "success": false,
  "message": "用户名已存在",
  "code": "USERNAME_ALREADY_EXISTS"
}
```

服务端要求：

- 校验邮箱验证码有效且用途匹配
- 校验 `password == confirmPassword`
- 校验用户名唯一
- 校验邮箱唯一
- 创建 `user`
- 创建 `member_profile`
- 设置 `member_profile.status=active`
- 设置 `member_profile.email_verified_at`
- 创建 `member_session`
- 返回登录态

### 5.3 密码登录

`POST /api/auth/login`

请求体：

```json
{
  "identifier": "allergy_user",
  "password": "StrongPassword123"
}
```

说明：

- `identifier` 可为用户名或邮箱

成功响应：

```json
{
  "success": true,
  "message": "登录成功",
  "data": {
    "token": "member_session_token",
    "user": {
      "id": 1001,
      "username": "allergy_user",
      "email": "user@example.com"
    },
    "profile": {
      "id": 1001,
      "username": "allergy_user",
      "email": "user@example.com",
      "nickname": "",
      "phone": "",
      "status": "active",
      "emailVerified": true,
      "emailVerifiedAt": "2026-04-15T10:30:00+08:00",
      "createdAt": "2026-04-15T10:31:00+08:00"
    }
  },
  "token": "member_session_token"
}
```

失败示例：

```json
{
  "success": false,
  "message": "邮箱未验证",
  "code": "EMAIL_NOT_VERIFIED"
}
```

服务端要求：

- 先按用户名查，未命中再按邮箱查，或统一封装查询
- 密码校验失败时返回稳定错误码
- 非会员账号直接拒绝
- 禁用会员直接拒绝
- 邮箱未验证直接拒绝
- 成功后创建新的 `member_session`

### 5.4 发送找回密码验证码

`POST /api/auth/forgot-password/send-code`

请求体：

```json
{
  "email": "user@example.com"
}
```

成功响应：

```json
{
  "success": true,
  "message": "验证码已发送",
  "data": {
    "email": "user@example.com",
    "purpose": "password_reset",
    "expiresInSeconds": 300
  }
}
```

失败示例：

```json
{
  "success": false,
  "message": "账号不存在",
  "code": "ACCOUNT_NOT_FOUND"
}
```

服务端要求：

- 必须是现有会员邮箱
- 必须具备有效 `member_profile`
- 建议对禁用账号也允许发码与否在实现时统一，但文档建议：
  - 禁用账号直接拒绝
- 写入 `purpose=password_reset`

### 5.5 重置密码

`POST /api/auth/forgot-password/reset`

请求体：

```json
{
  "email": "user@example.com",
  "code": "123456",
  "password": "NewStrongPassword123",
  "confirmPassword": "NewStrongPassword123"
}
```

成功响应：

```json
{
  "success": true,
  "message": "密码已重置",
  "data": {
    "reset": true
  }
}
```

推荐增强响应：

```json
{
  "success": true,
  "message": "密码已重置",
  "data": {
    "reset": true,
    "sessionsRevoked": true
  }
}
```

服务端要求：

- 校验邮箱验证码有效且用途匹配
- 校验两次密码输入一致
- 更新密码哈希
- 建议作废该用户已有 `member_session`

### 5.6 获取当前会员

`GET /api/auth/me`

请求头：

```http
Authorization: Bearer member_session_token
```

成功响应：

```json
{
  "success": true,
  "message": "",
  "data": {
    "user": {
      "id": 1001,
      "username": "allergy_user",
      "email": "user@example.com"
    },
    "profile": {
      "id": 1001,
      "username": "allergy_user",
      "email": "user@example.com",
      "nickname": "",
      "phone": "",
      "status": "active",
      "emailVerified": true,
      "emailVerifiedAt": "2026-04-15T10:30:00+08:00",
      "createdAt": "2026-04-15T10:31:00+08:00"
    }
  }
}
```

失败示例：

```json
{
  "success": false,
  "message": "未登录",
  "code": "UNAUTHORIZED"
}
```

服务端要求：

- 校验 `member_session`
- 校验会员准入条件仍然满足
- 若会员已被禁用，直接返回未授权或禁用错误

### 5.7 注销

`POST /api/auth/logout`

请求头：

```http
Authorization: Bearer member_session_token
```

成功响应：

```json
{
  "success": true,
  "message": "已退出登录",
  "data": {
    "revoked": true
  }
}
```

服务端要求：

- 将当前 `member_session` 标记为失效
- 重复调用允许幂等成功

### 5.8 更新会员资料

`PATCH /api/auth/profile`

请求头：

```http
Authorization: Bearer member_session_token
```

请求体示例：

```json
{
  "nickname": "Tom",
  "phone": "13800138000",
  "defaultRecipientName": "Tom",
  "defaultRecipientPhone": "13800138000",
  "defaultAddress": {
    "province": "Shanghai",
    "city": "Shanghai",
    "district": "Pudong",
    "addressLine1": "XX Road 88"
  }
}
```

成功响应：

```json
{
  "success": true,
  "message": "资料已更新",
  "data": {
    "profile": {
      "id": 1001,
      "username": "allergy_user",
      "email": "user@example.com",
      "nickname": "Tom",
      "phone": "13800138000",
      "status": "active",
      "emailVerified": true,
      "emailVerifiedAt": "2026-04-15T10:30:00+08:00",
      "createdAt": "2026-04-15T10:31:00+08:00"
    }
  }
}
```

限制要求：

- 不允许通过该接口改邮箱
- 不允许通过该接口改用户名
- 不允许通过该接口改密码

## 6. 兼容与切换策略

### 6.1 旧接口状态

旧体系接口：

- `POST /api/auth/send-code`
- `POST /api/auth/login` with `email + code`

新体系上线后建议策略：

- 直接停用 `POST /api/auth/send-code`
- `POST /api/auth/login` 改为 `identifier + password`

### 6.2 前端切换约束

前端在切换到新页面后，应同步停止以下依赖：

- 发送登录验证码
- 邮箱验证码直接登录
- 首次登录自动补资料

### 6.3 过渡兼容建议

如果需要短时间兼容，可允许登录响应同时返回：

- `data.token`
- 顶层 `token`

这样可以降低 `AuthContext` 切换时的破坏面。

## 7. 最低联调用例

建议最少覆盖以下接口联调：

1. 发送注册验证码
2. 使用验证码注册并自动登录
3. 使用用户名登录
4. 使用邮箱登录
5. 获取 `me`
6. 更新资料
7. 注销
8. 发起找回密码
9. 重置密码
10. 使用新密码重新登录

## 8. 非目标

这份 API 契约不覆盖：

- 后台管理员登录接口
- 会员邮箱更换
- 二次验证
- Passkey
- 2FA
- 社交登录

这些能力后续可加，但不应阻塞当前会员账号体系改造。
