# 检测项目图片上传接口契约

日期：2026-04-19

## 1. 范围

这份文档定义检测项目图片上传接口，以及检测项目创建/编辑接口如何继续消费 `image_url`。

本次不改动前台 `GET /api/products` 字段结构。

## 2. 新增后台上传接口

### `POST /api/admin/service-products/upload-image`

用途：

- 上传检测项目图片文件

请求：

- `Content-Type: multipart/form-data`
- 文件字段：`file`

成功响应示例：

```json
{
  "image_url": "/uploads/allergy-product-images/1730000000_children.jpg"
}
```

规则：

- 仅允许管理员调用
- 一次只处理一个文件
- 仅允许图片类型文件
- 成功后返回最终可用于检测项目 `image_url` 的站内路径

失败语义：

- 缺少文件：返回业务错误，例如 `请上传图片文件`
- 文件类型不合法：返回业务错误，例如 `仅支持图片文件`
- 保存失败：返回通用上传失败错误

## 3. 现有检测项目创建接口

### `POST /api/admin/service-products`

请求结构保持 JSON，不改为 multipart：

```json
{
  "service_code": "allergy-test-plus",
  "title": "儿童专项过敏原检测",
  "description": "面向儿童常见吸入与食物过敏原的检测项目。",
  "image_url": "/uploads/allergy-product-images/1730000000_children.jpg",
  "cta_text": "立即下单",
  "tag": "新品",
  "price_cents": 29900,
  "sort_order": 20,
  "status": "draft"
}
```

兼容要求：

- `image_url` 可以是外链 URL
- `image_url` 也可以是上传接口返回的站内相对路径

## 4. 现有检测项目编辑接口

### `PATCH /api/admin/service-products/:id`

请求结构保持 JSON，不改为 multipart：

```json
{
  "title": "儿童专项过敏原检测（升级版）",
  "description": "新增更多儿童常见过敏原覆盖。",
  "image_url": "/uploads/allergy-product-images/1730000001_children-v2.jpg",
  "cta_text": "立即预约",
  "tag": "热门",
  "price_cents": 32900,
  "sort_order": 30,
  "status": "draft"
}
```

规则：

- `service_code` 仍不允许修改
- `image_url` 同时兼容外链 URL 与站内相对路径

## 5. 图片访问约定

上传后的图片需要通过公开静态路径直接访问，例如：

- `/uploads/allergy-product-images/<file-name>`

前台拿到该路径后，继续按现有图片 URL 拼接逻辑渲染。
