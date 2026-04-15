# 会员账号体系测试计划

日期：2026-04-15

状态：

- draft

关联文档：

- [member-auth-design.md](./member-auth-design.md)
- [member-auth-api-contract.md](./member-auth-api-contract.md)
- [member-auth-migration-cleanup.md](./member-auth-migration-cleanup.md)

## 1. 范围

这份文档定义会员账号体系改造的最低测试与验收范围。

覆盖：

- 注册
- 登录
- 找回密码
- 会员准入校验
- 旧会员清理后的重新注册

不覆盖：

- 2FA
- Passkey
- 社交登录

## 2. 后端测试

- 注册验证码发送成功
- 已注册邮箱不可重复发送注册验证码
- 注册成功后创建 `user + member_profile + member_session`
- 用户名重复时注册失败
- 邮箱重复时注册失败
- 用户名登录成功
- 邮箱登录成功
- 未验证邮箱不可登录
- `member_profile.status=disabled` 不可登录
- 无 `member_profile` 的管理员账号不可走公共站登录
- 找回密码验证码发送成功
- 使用新密码登录成功，旧密码失效

## 3. 前端联调

- `/register` 可完成邮箱验证注册
- `/login` 支持用户名登录
- `/login` 支持邮箱登录
- `/forgot-password` 可完成重置密码
- 未登录访问订单中心会被拦截
- 登录成功后进入订单中心

## 4. 清理脚本验证

- `dry-run` 不删除数据
- 正式执行只删除旧普通会员
- 管理员账号不受影响
- 旧邮箱在清理后可重新注册

## 5. 回归重点

- 现有订单中心登录态校验
- 报告预览与下载权限
- 公共站登录入口与后台管理员入口边界
