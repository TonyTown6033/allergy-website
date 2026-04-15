# `new-api` + `Allergy` 会员账号体系改造设计

日期：2026-04-15

关联文档：

- [claude.md](../../claude.md)
- [TODO.md](../../TODO.md)
- [integration-design.md](../architecture/integration-design.md)
- [data-model-draft.md](../architecture/data-model-draft.md)
- [allergy-api-draft.md](../api/allergy-api-draft.md)

## 1. 范围

这份文档只定义会员账号体系改造，不涉及代码实现。

本轮目标是把当前“邮箱验证码登录 + 首次登录自动建号”的模式，收敛为可直接开发的传统账号体系方案，覆盖：

- 注册
- 登录
- 找回密码
- 会员准入校验
- 历史会员清理
- 前后端实施顺序

本轮明确不展开实现的内容：

- 退款 / 售后 / 对账
- 独立备注区
- 订单异常告警
- 操作审计 UI
- 履约备注流转

这些能力仍然重要，但排在账号体系之后。

## 2. 已锁定决策

以下方案已经确认，本设计不再重新讨论：

- 公共站主登录方式改为 `用户名/邮箱 + 密码`
- 注册时填写：`用户名 + 邮箱 + 密码 + 确认密码`
- 邮箱验证码只用于：
  - 注册前验证邮箱归属
  - 找回密码
  - 后续高风险安全操作预留
- 注册必须先完成邮箱验证，再创建账号
- 用户名必须唯一，且可以作为登录标识
- 找回密码通过邮箱验证码完成
- 公共站会员仍然挂在 `new-api.user` 主表
- 会员档案仍然使用 `member_profile`
- 公共站继续使用自己的 `member_session`
- 后台管理员入口和公共站会员入口必须分开
- 没有 `member_profile` 的后台管理员账号不能走公共站登录
- 现有验证码快捷登录在新体系上线后直接移除，不作为长期灰度入口
- 历史“验证码时代”的普通会员账号通过脚本清理，不做订单 / 报告 / 历史数据迁移
- 清理脚本不能影响管理员账号

## 3. 当前现状与主要问题

当前实现的实际状态如下：

- 前端公共站仍然使用邮箱验证码登录
- 登录接口仍然是：
  - `POST /api/auth/send-code`
  - `POST /api/auth/login`
- 首次登录时会自动创建会员账号
- 注册、登录、忘记密码没有拆成独立流程
- 前端交互仍以登录弹窗为核心，而不是独立页面
- `member_profile` 目前没有明确的邮箱验证完成时间字段
- 公共站登录准入依赖较弱，尚未完整校验：
  - 是否有有效 `member_profile`
  - 会员状态是否允许登录
  - 邮箱是否已验证

这会带来几个直接问题：

- 账号边界不清晰，无法稳定支持传统密码登录
- 首次登录自动建号会弱化注册入口和安全控制
- 忘记密码流程无法自然落地
- 老账号与新账号模型并存时，邮箱唯一性容易冲突
- 公共站与后台管理员身份边界不够硬

## 4. 目标态

账号体系改造完成后，目标态应满足以下要求：

### 4.1 用户视角

- 未注册用户先进入注册页
- 注册时先发送邮箱验证码
- 验证通过后填写用户名和密码完成注册
- 已注册用户通过用户名或邮箱 + 密码登录
- 忘记密码用户通过邮箱验证码重置密码
- 登录成功后进入订单中心

### 4.2 系统视角

- 会员主身份仍然使用 `user.id`
- `member_profile` 作为公共站会员准入档案
- `member_session` 继续承载公共站登录态
- `EmailLoginCodeStore` 继续复用，但用途改为：
  - `register_verify`
  - `password_reset`
- 公共站登录准入规则必须变成硬约束，而不是弱约定

### 4.3 准入规则

公共站密码登录只允许以下账号成功登录：

- `user` 存在
- `user` 匹配登录标识
- 密码校验通过
- 存在有效 `member_profile`
- `member_profile.status = active`
- `member_profile.email_verified_at` 不为空

以下账号必须被拒绝：

- 只有后台管理员身份、没有 `member_profile` 的账号
- 被禁用的会员账号
- 邮箱未验证完成的账号
- 历史验证码时代但已被清理的普通会员账号

## 5. 数据模型调整

### 5.1 继续复用的实体

- `user`
- `member_profile`
- `member_session`
- `email_login_code_store`

### 5.2 `user` 使用约束

`user` 继续作为账号主表，但公共站会员相关约束改为：

- `email` 作为会员邮箱
- `username` 作为可见登录标识之一
- 普通会员注册时必须同时保证：
  - 邮箱唯一
  - 用户名唯一

### 5.3 `member_profile` 建议新增字段

建议新增：

- `email_verified_at`

建议继续复用：

- `status`

含义约定如下：

| 字段 | 说明 |
|---|---|
| `status` | 会员状态，至少支持 `active` / `disabled` |
| `email_verified_at` | 邮箱验证完成时间，为空表示未验证 |

### 5.4 `email_login_code_store` 用途调整

当前该表主要承载登录验证码。改造后不再承担日常登录功能，而是承载以下用途：

| purpose | 用途 |
|---|---|
| `register_verify` | 注册前邮箱验证 |
| `password_reset` | 找回密码验证 |

不再建议继续使用：

| purpose | 说明 |
|---|---|
| `login` | 新体系上线后移除公共站验证码登录 |

### 5.5 会员状态关系

建议把公共站准入判断统一收敛为一个明确规则：

`允许公共站登录 = user 可用 + member_profile 存在 + member_profile.active + email_verified_at 非空`

不要再在多个 controller 里散落一套“差不多”的判断。

## 6. 目标接口

建议将公共站认证接口收敛为以下集合。

### 6.1 注册验证码

`POST /api/auth/register/send-code`

用途：

- 发送注册邮箱验证码

请求：

```json
{
  "email": "user@example.com"
}
```

行为要求：

- 校验邮箱格式
- 若邮箱已被占用，直接失败
- 写入 `purpose=register_verify` 的验证码记录

### 6.2 注册

`POST /api/auth/register`

请求：

```json
{
  "email": "user@example.com",
  "code": "123456",
  "username": "allergy_user",
  "password": "StrongPassword123",
  "confirmPassword": "StrongPassword123"
}
```

行为要求：

- 校验验证码有效且用途匹配
- 校验用户名唯一
- 校验邮箱未被占用
- 创建 `user`
- 创建 `member_profile`
- 写入 `email_verified_at`
- 创建 `member_session`
- 返回登录态

### 6.3 密码登录

`POST /api/auth/login`

请求：

```json
{
  "identifier": "allergy_user",
  "password": "StrongPassword123"
}
```

说明：

- `identifier` 可以是用户名，也可以是邮箱

行为要求：

- 根据用户名或邮箱查账号
- 校验密码
- 校验公共站会员准入条件
- 创建 `member_session`
- 返回登录态

### 6.4 找回密码验证码

`POST /api/auth/forgot-password/send-code`

请求：

```json
{
  "email": "user@example.com"
}
```

行为要求：

- 仅允许已存在的有效会员邮箱使用
- 写入 `purpose=password_reset` 的验证码记录

### 6.5 重置密码

`POST /api/auth/forgot-password/reset`

请求：

```json
{
  "email": "user@example.com",
  "code": "123456",
  "password": "NewStrongPassword123",
  "confirmPassword": "NewStrongPassword123"
}
```

行为要求：

- 校验验证码有效且用途匹配
- 更新密码
- 建议失效该用户现有公共站登录态

### 6.6 保留接口

以下接口建议保留，但语义按新体系收敛：

- `GET /api/auth/me`
- `POST /api/auth/logout`
- `PATCH /api/auth/profile`

其中：

- `GET /api/auth/me` 应返回公共站可用的会员信息
- `POST /api/auth/logout` 继续注销 `member_session`
- `PATCH /api/auth/profile` 只更新会员资料，不处理登录安全事务

## 7. 前端页面与交互调整

### 7.1 页面路由

建议新增独立页面，而不是继续堆叠在登录弹窗里：

- `/login`
- `/register`
- `/forgot-password`

### 7.2 页面职责

`/login`

- 输入用户名或邮箱
- 输入密码
- 支持跳转注册页
- 支持跳转忘记密码页

`/register`

- 输入邮箱
- 发送验证码
- 输入验证码
- 输入用户名
- 输入密码和确认密码
- 注册成功后直接进入订单中心

`/forgot-password`

- 输入邮箱
- 发送验证码
- 输入验证码
- 输入新密码和确认密码
- 重置成功后跳转登录页，或按最终实现直接登录

### 7.3 现有入口改造方向

现有基于弹窗的验证码登录入口建议按以下方式替换：

- `Navbar` 中的登录入口跳转到 `/login`
- `MemberAccessPanel` 中的入口跳转到 `/login`
- 原 `LoginModal` 不再作为主流程

### 7.4 登录成功后的跳转

登录或注册成功后统一进入：

- `/orders`

这样能保持公共站的任务闭环一致，不必新增额外会员首页。

## 8. 历史会员清理方案

由于旧体系曾经允许“首次验证码登录自动建号”，而新体系要求邮箱唯一、注册前验证，因此需要在切换前清理旧普通会员账号。

### 8.1 目标

- 清除旧普通会员数据，避免与新注册流程冲突
- 不迁移旧订单 / 报告 / 会员历史
- 不影响后台管理员账号

### 8.2 清理范围

建议至少覆盖：

- 旧普通会员 `user`
- 对应的 `member_profile`
- 对应的 `member_session`
- 对应的 `email_login_code_store`

### 8.3 明确不能清理的对象

- 任何后台管理员账号
- 任何明确标记为运营 / 管理用途的账号

### 8.4 脚本要求

建议提供一个可重复执行的清理命令，至少支持：

- `dry-run`
- 输出将被删除的账号数量
- 输出样例邮箱
- 正式执行删除

### 8.5 推荐上线顺序

1. 先部署支持新账号体系的后端和前端
2. 在切流前执行旧普通会员清理脚本
3. 确认管理员账号未受影响
4. 再正式切换公共站入口到新登录体系

## 9. 实施顺序

建议按下面顺序开发，避免前后端反复返工。

### 9.1 第一阶段：后端模型与准入收敛

- 扩展 `member_profile`
- 收敛公共站登录准入判断
- 扩展验证码用途枚举
- 停止“首次登录自动建号”逻辑

### 9.2 第二阶段：后端认证接口

- 新增注册验证码接口
- 新增注册接口
- 改造密码登录接口
- 新增找回密码接口
- 保持 `me/logout/profile` 可用

### 9.3 第三阶段：清理脚本

- 先实现 `dry-run`
- 再实现正式删除
- 补齐“不会删管理员”的保护测试

### 9.4 第四阶段：前端公共站

- 重构 `AuthContext`
- 新增登录 / 注册 / 找回密码页面
- 替换现有弹窗入口
- 移除验证码登录主流程

### 9.5 第五阶段：联调与回归

- 注册闭环
- 登录闭环
- 找回密码闭环
- 登录态过期 / 注销
- 订单中心访问校验

## 10. TDD 验收清单

以下内容建议作为开发完成前的最低验收标准。

### 10.1 后端

- 注册验证码发送成功
- 已占用邮箱无法发送注册验证码
- 注册成功后创建 `user + member_profile + member_session`
- 未验证邮箱不能注册成功
- 用户名重复时注册失败
- 邮箱重复时注册失败
- 用户名登录成功
- 邮箱登录成功
- 无 `member_profile` 的管理员账号不能登录公共站
- `member_profile.status=disabled` 时不能登录
- `email_verified_at` 为空时不能登录
- 找回密码发送验证码成功
- 找回密码后旧密码失效
- 找回密码后新密码可登录
- 注销后当前 `member_session` 失效

### 10.2 前端

- `/login` 可完成用户名登录
- `/login` 可完成邮箱登录
- `/register` 可完成验证码注册
- `/forgot-password` 可完成重置密码
- 未登录访问 `/orders` 会跳到登录流程
- 登录成功后会进入 `/orders`

### 10.3 清理脚本

- `dry-run` 只输出结果，不删除数据
- 正式执行只删除普通会员
- 管理员账号不会被误删

## 11. 非目标与后续阶段

本设计完成后，不代表账号体系之外的运营后台问题已经解决。

建议下一阶段继续推进：

- 订单详情页的独立备注区
- 订单操作审计日志区
- 列表页快捷履约动作
- 退款 / 售后 / 对账

其中“备注 + 操作日志”建议直接放在订单详情页，拆成两个独立区块：

- 备注区
- 操作日志区

但这部分不属于当前账号体系改造的实施范围。
