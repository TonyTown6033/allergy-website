# 检测项目目录测试计划

日期：2026-04-16

## 目标

验证检测项目目录的建表、后台管理、前台展示、下单快照和归档行为。

## 后端测试

### 模型与迁移

- `allergy_service_product` 可成功迁移
- `original_price_cents` 默认值为 `0`
- `service_code` 唯一约束生效
- 默认项目可被幂等补齐

### 公共接口

- `GET /api/products` 只返回 `published` 项目
- 返回顺序符合 `sort_order asc, id desc`
- 返回折后售价 `price_cents` 和可选划线原价 `original_price_cents`

### 后台接口

- 可创建 `draft` 项目
- 可更新标题、详情、图片、CTA、标签、折后价、划线原价、排序
- 拒绝 `original_price_cents` 不大于 `price_cents` 的折扣配置
- 不允许修改 `service_code`
- 可发布 `draft` 项目
- 可归档已发布项目

### 下单链路

- 会员只能对 `published` 项目下单
- 下单后订单写入正确的：
  - `service_code`
  - `service_name_snapshot`
  - `service_price_cents`
- 折扣项目下单后，`service_price_cents` 等于折后售价 `price_cents`
- 项目改价后，历史订单快照不变化
- 项目归档后不可继续新下单

### 回归

- 支付回调仍可把订单改为 `paid`
- 时间线仍写入 `payment_completed`
- 履约、报告上传、预览、下载链路不受影响

## 前端验证

### 前台 Allergy

- 商品页可展示多个已上架项目
- 有效折扣项目显示原价删除线和折后主价格
- 无折扣项目只显示现有售价
- 点击商品 CTA 可进入对应下单页
- `/orders/new` 无 `service` 参数时可自动选择第一个已上架项目
- 下单页可展示当前项目标题、详情、折后售价和可选划线原价

### 后台 new-api

- 管理员可进入“检测项目”页面
- 可创建、编辑、发布、下架项目
- 列表页状态、折后价与可选划线原价展示正确

## 建议执行顺序

1. 后端控制器测试
2. 后台页面构建验证
3. 前台页面构建验证
4. 联调下单回归
