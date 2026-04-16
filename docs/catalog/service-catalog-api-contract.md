# 检测项目目录接口契约

日期：2026-04-16

## 1. 公共接口

### `GET /api/products`

用途：

- 获取当前所有已上架的检测项目

响应：

```json
[
  {
    "id": "allergy-test-basic",
    "title": "埃勒吉居家过敏原检测服务",
    "description": "通过一滴指尖血，精准检测 100+ 种过敏原。",
    "image": "https://cdn.example.com/allergy/basic.jpg",
    "ctaText": "立即购买",
    "tag": "推荐",
    "price_cents": 19900,
    "currency": "CNY"
  }
]
```

规则：

- 仅返回 `published` 项目
- 按 `sort_order asc, id desc` 排序

## 2. 会员下单接口

### `POST /api/orders`

请求：

```json
{
  "service_code": "allergy-test-basic",
  "recipient_name": "张三",
  "recipient_phone": "13800000000",
  "recipient_email": "member@example.com",
  "shipping_address": {
    "province": "上海市",
    "city": "上海市",
    "district": "浦东新区",
    "address_line": "世纪大道 100 号"
  }
}
```

新增规则：

- `service_code` 必须命中 `published` 项目
- 订单创建时写入项目当前名称和价格快照

失败语义：

- 项目不存在、未上架或已下架：返回业务错误 `服务不存在`

## 3. 后台接口

### `GET /api/admin/service-products`

用途：

- 获取检测项目列表

响应：

```json
{
  "page": 1,
  "page_size": 20,
  "total": 2,
  "items": [
    {
      "id": 1,
      "service_code": "allergy-test-basic",
      "title": "埃勒吉居家过敏原检测服务",
      "price_cents": 19900,
      "currency": "CNY",
      "status": "published",
      "sort_order": 10,
      "updated_at": "2026-04-16T10:00:00+08:00"
    }
  ]
}
```

支持查询参数：

- `p`
- `page_size`

### `GET /api/admin/service-products/:id`

用途：

- 获取单个检测项目详情

响应：

```json
{
  "id": 1,
  "service_code": "allergy-test-basic",
  "title": "埃勒吉居家过敏原检测服务",
  "description": "通过一滴指尖血，精准检测 100+ 种过敏原。",
  "image_url": "https://cdn.example.com/allergy/basic.jpg",
  "cta_text": "立即购买",
  "tag": "推荐",
  "price_cents": 19900,
  "currency": "CNY",
  "sort_order": 10,
  "status": "published",
  "created_at": "2026-04-16T10:00:00+08:00",
  "updated_at": "2026-04-16T10:00:00+08:00"
}
```

### `POST /api/admin/service-products`

用途：

- 创建新的检测项目

请求：

```json
{
  "service_code": "allergy-test-plus",
  "title": "儿童专项过敏原检测",
  "description": "面向儿童常见吸入与食物过敏原的检测项目。",
  "image_url": "https://cdn.example.com/allergy/children.jpg",
  "cta_text": "立即下单",
  "tag": "新品",
  "price_cents": 29900,
  "sort_order": 20,
  "status": "draft"
}
```

规则：

- `service_code` 必填，3-64 位，仅允许小写字母、数字和 `-`
- `service_code` 唯一
- `title` 必填
- `description` 必填
- `price_cents` 必须大于 0
- `currency` 固定由服务端写为 `CNY`
- `cta_text` 为空时由服务端补默认值 `立即购买`

### `PATCH /api/admin/service-products/:id`

用途：

- 编辑检测项目

请求：

```json
{
  "title": "儿童专项过敏原检测（升级版）",
  "description": "新增更多儿童常见过敏原覆盖。",
  "image_url": "https://cdn.example.com/allergy/children-v2.jpg",
  "cta_text": "立即预约",
  "tag": "热门",
  "price_cents": 32900,
  "sort_order": 30,
  "status": "draft"
}
```

规则：

- `service_code` 不允许修改
- 其他字段按提交值更新

### `POST /api/admin/service-products/:id/publish`

用途：

- 发布检测项目

响应：

```json
{
  "id": 2,
  "status": "published"
}
```

### `POST /api/admin/service-products/:id/archive`

用途：

- 下架检测项目

响应：

```json
{
  "id": 2,
  "status": "archived"
}
```
