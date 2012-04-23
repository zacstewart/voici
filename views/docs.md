# User Accounts
An account is required to access all resources other than `/docs` and those exposed by `/public/*`

## Register an account
`POST /users`

Email is not shared with anyone but your clients. Passwords are bcrypted.

### Paramters
- **email**
  Your email address
  - required: true
  - type: string
- **password**
  Your password
  - required: true
  - type: string
- **password_confirmation**
  Confirm your password
  - required: true
  - type: string
- **name**
  Your name as you'd like it to appear on invoices
  - required: false
  - type: string
- **address**
  Your address as you'd like it to appear on invoices
  - required: false
  - type: string
- **phone**
  Your phone number as you'd like it to appear on invoices
  - required: false
  - type: string

## Sign in
`POST /session`

Session management is currently unRESTful :(. I will implement pub/private key authentication soon.

### Parameters
- **email**
  Your email address
  - required: true
  - type: string
- **password**
  Your password
  - required: true
  - type: string

## Sign out
`DELETE /session`

# Invoices
Resources are stateful and can transition through the following states during their lifecycle:
`saved`, `enqueued`, `failed_to_send`, `sent`, `deliered`, `opened`, `settled`.

## List all your invoices
`GET /invoices`

Currently, there is no pagination. Be careful!

## Create a new invoice
`POST /invoices`

### Parameters
- **date**
  Must be a string that will parse to a date in MongoDB
  - required: true
  - type: string
- **number**
  Can be a string of any format
  - required: true
  - type: string
- **notes**
  Can be a string of any format
  - required: false
  - type: string
- **client_attributes**
  - required: true
  - type: **client**
- **line_items_attributes**
  - required: true
  - type: array
  - items: **line item**

## Get an invoice
`GET /invoices/:invoice_id`

Returns a representation of the invoice with id `:invoice_id`.

## Modify an existing invoice
`PUT /invoices/:invoice_id`

- **date**
  Must be a string that will parse to a date in MongoDB
  - required: true
  - type: string
- **number**
  Can be a string of any format
  - required: true
  - type: string
- **notes**
  Can be a string of any format
  - required: false
  - type: string
- **client_attributes**
  - required: true
  - type: **client**
- **line_items_attributes**
  - required: true
  - type: array
  - items: **line item**

## Delete an invoice
`DELETE /invoices/:invoice_id`

## Send an invoice
`POST /invoices/:invoice_id/events` with parameter `type=enqueue` or payload `{"type":"enqueue"}`.

# Clients
Clients are an attribute of invoices. They are an embedded document in an invoice document.
In the future, I plan to make them also a first-order resource so that they can be used
to aggregate invoices. E.g. "three outstanding invoices for Mr X."

To delete an existing client from an invoice set the `_delete` parameter to true.

## Schema
- **name**
  - required: true
  - type: string
- **email**
  - required: true
  - type: string
- **address**
  - required: false
  - type: string
- **phone**
  - required: false
  - type: string
- **_destroy**
  - required: false
  - type: boolean

## Example

```
  {
    "name": "Joe Client",
    "email": "joe@example.com",
    "address": "123 Client St, Atlanta, GA 30303",
    "phone": "(404) 555-1234"
  }
```

# Line Items
Line items are attributes of invoices. They are for one billable "line" on an invoice.
The total of the invoice equals the sum of each line's unit_price times quantity.

To delete an existing line item from an invoice set the `_delete` parameter to true.

## Schema
- **description**
  - required: true
  - type: string
- **quantity**
  - required: true
  - type: number
- **unit_price**
  - required: true
  - type: number
- **_destroy**
  - required: false
  - type: boolean

## Example

```
  {
    "description": "Cat sitting",
    "quantity": 1,
    "unit_price": 99.99
  }
```
