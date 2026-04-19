# 检测项目目录迁移方案

日期：2026-04-16

## 目标

把“可售检测项目目录”从早期的：

- 前台 `Option JSON`
- 后端硬编码服务目录

迁移为数据库表 `allergy_service_product`。

## 迁移内容

### 1. 建表

新增表：

- `allergy_service_product`

字段见：

- [service-catalog-design.md](./service-catalog-design.md)

### 2. 默认数据

迁移后自动补一条默认记录：

| 字段 | 值 |
|---|---|
| `service_code` | `allergy-test-basic` |
| `title` | `埃勒吉居家过敏原检测服务` |
| `description` | 当前默认居家检测服务说明 |
| `cta_text` | `立即购买` |
| `price_cents` | `19900` |
| `original_price_cents` | `0` |
| `currency` | `CNY` |
| `status` | `published` |

要求：

- 仅在该 `service_code` 不存在时插入
- 如果已存在同编码记录，不覆盖管理员后来修改的内容

### 3. 折扣原价字段

新增字段：

- `allergy_service_product.original_price_cents`

默认值：

- `0`

规则：

- `0` 表示无划线原价
- 旧检测项目迁移后默认不显示折扣
- 不回填历史订单，订单仍只保存实际支付价格快照 `service_price_cents`

### 4. 旧数据口径

- `AllergyProducts` 旧 `Option JSON` 不再作为真实可售目录
- 历史订单不做回填
- `allergy_order` 继续保留已有快照字段，不受迁移影响

## 发布顺序

1. 部署包含新表和默认数据的后端
2. 确认后台可以看到默认检测项目
3. 再部署依赖新目录接口的前台与后台页面

## 回滚口径

- 如果仅前端/后台页异常，可先回滚前端与管理页版本，保留表结构
- 不删除 `allergy_service_product` 表
- 不删除已创建的检测项目记录
- 不回滚历史订单快照字段

## 风险与控制

风险：

- 新版本前台发布早于后端迁移，可能拿不到目录数据
- 管理员误下架唯一已发布项目，前台将无可售项目

控制：

- 先后端、后前台发布
- 后台至少保留一个 `published` 项目后再切流
