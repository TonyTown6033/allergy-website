# 检测项目目录与上架管理设计

日期：2026-04-16

## 目标

让后台可以新增、编辑、上架、下架“检测项目”，并定义：

- 检测项目编码
- 商品标题
- 商品详情
- 图片
- CTA 文案
- 标签
- 售价
- 原价与折后价
- 排序

前台商品列表和下单入口统一读取该目录；订单继续保存名称和价格快照；履约流程、支付语义、报告流程保持不变。

## 当前缺口

当前“检测项目”存在两套来源：

1. 前台 `GET /api/products` 仍走 `Option JSON`
2. 真正可下单的服务目录仍硬编码在 `new-api/controller/allergy_order.go`

这导致后台无法真正“上架新的检测项目”，也无法把商品详情、价格和下单校验统一到一个真源。

## 已锁定决策

- 卖的检测项目改用独立数据表，不继续使用 `Option JSON` 作为真实商品目录
- 后台提供独立“检测项目”管理页，不塞进通用系统设置
- 所有 `published` 项目都可下单
- 履约流程不按项目分叉，仍复用现有订单、采样盒、报告、时间线链路
- 订单必须保存项目名称和价格快照，项目后续改价不能回写历史订单
- 首轮仅支持单次检测项目，不引入套餐、购物车、订阅或加价项
- 币种固定为 `CNY`
- `service_code` 创建后不可修改，避免前台链接与历史订单引用漂移
- `price_cents` 是折后实际售价，订单创建、支付金额和订单价格快照均以它为准
- `original_price_cents` 是可选划线原价，仅用于展示；为空或不大于折后价时前台不展示划线原价

## 非目标

- 不做完整 CMS
- 不改首页 Hero、文章、Testimonials 的内容来源
- 不改支付渠道和支付成功语义
- 不做折扣率、活动时间、优惠券、会员价或多币种折扣
- 不新增新的履约状态机
- 不按不同项目定义不同的发货或报告流程

## 数据与状态

新增表：`allergy_service_product`

建议字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | bigint PK | 主键 |
| `service_code` | varchar(64) unique | 项目标识，供下单与前台路由使用 |
| `title` | varchar(255) | 商品标题 |
| `description` | text | 商品详情 |
| `image_url` | varchar(1024) | 商品图片 |
| `cta_text` | varchar(64) | 商品 CTA 文案 |
| `tag` | varchar(64) | 商品标签 |
| `price_cents` | int | 折后实际售价，单位分 |
| `original_price_cents` | int | 可选划线原价，单位分；`0` 表示无原价 |
| `currency` | varchar(16) | 默认 `CNY` |
| `sort_order` | int | 前台排序，越小越靠前 |
| `status` | varchar(32) | `draft` / `published` / `archived` |
| `created_at` | datetime | 创建时间 |
| `updated_at` | datetime | 更新时间 |

状态规则：

- `draft`：后台可编辑，前台不可见，不可下单
- `published`：前台可见，可下单
- `archived`：前台不可见，不可下单，但不影响历史订单查看

订单表继续沿用：

- `service_code`
- `service_name_snapshot`
- `service_price_cents`

折扣价规则：

- 后台录入“原价 + 折后价”，不按折扣率自动计算
- `original_price_cents = 0` 表示无划线原价
- 若填写原价，则必须大于 `price_cents`
- 历史订单不新增原价快照，仍只保存实际支付价格快照 `service_price_cents`

## API 与页面影响

### 公共接口

- 保留 `GET /api/products`
- 数据源改为 `allergy_service_product`
- 仅返回 `published` 项目

### 下单接口

- `POST /api/orders` 的 `service_code` 改为查表校验
- 创建订单时从项目表写入名称与价格快照

### 后台接口

- `GET /api/admin/service-products`
- `GET /api/admin/service-products/:id`
- `POST /api/admin/service-products`
- `PATCH /api/admin/service-products/:id`
- `POST /api/admin/service-products/:id/publish`
- `POST /api/admin/service-products/:id/archive`

### 后台页面

- 新增独立“检测项目”管理页
- 支持列表、创建、编辑、发布、下架

### 前台页面

- 商品页展示所有已上架检测项目
- 商品 CTA 进入对应项目下单页
- 当 `/orders/new` 未指定 `service` 参数时，默认使用第一个已上架项目

## 验收标准

- 后台可新增一个新的检测项目并设置价格、详情、图片和 CTA 文案
- 后台可设置折后价和可选划线原价，原价必须大于折后价
- 新项目发布后可出现在前台商品页并进入下单页
- 前台商品页和下单页在有有效原价时展示原价删除线和折后主价格
- 新项目下单成功后，订单写入正确的 `service_code`、名称快照和价格快照
- 折扣项目下单后，订单 `service_price_cents` 等于折后价 `price_cents`
- 项目改价后，历史订单的 `service_price_cents` 不变化
- 项目下架后不再出现在前台，也不可继续新下单
- 现有支付、履约、报告链路回归通过

## 文档优先级说明

如果本设计与早期 `docs/api/allergy-api-draft.md` 或 `docs/architecture/*` 中关于商品目录的描述冲突，以本文为准。
