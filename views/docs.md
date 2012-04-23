Voici just does invoicing. My goal is to provide a simple app that does one thing well while exploring the concepts of REST, [self-describing APIs](http://zacstewart.com/2012/04/14/http-options-method.html) and single-page apps with Backbone.

The Backbone client is still yet to come, but the API is at MVP status. **This is still alpha!** Please share your feedback: zgstewart [at] gmail.

All parameters may be sent as JSON payloads or request params.

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

### Example

<pre>
  {
    "email": "joe@example.com",
    "password": "wombats",
    "password_confirmation": "wombats",
    "name": "Joe Wombats",
    "address": "123 Wombat Ln, Atlanta, GA 30303",
    "phone": "(404) 555-1234"
  }
</pre>

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

### Example

<pre>
  {
    "email": "joe@example.com",
    "password": "wombats"
  }
</pre>

## Sign out
`DELETE /session`

- - -

# Invoices
Resources are stateful and can transition through the following states during their lifecycle: `saved`, `enqueued`, `failed_to_send`, `sent`, `deliered`, `opened`, `settled`.

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
- **line\_items\_attributes**
  - required: true
  - type: array
  - items: **line item**

### Example

<pre>
  {
    "date": "2012-04-23",
    "number": "Apr2012-Kenny",
    "notes": "Pay on time this month, please!",
    "client_attributes": {
      "name": "Kenny Client",
      "email": "kenny@example.com",
      "address": "123 Client St, Atlanta, GA 30303",
      "phone": "(404) 555-1234"
    },
    "line_items_attributes": {
      "description": "Cat sitting",
      "quantity": 1,
      "unit_price": 99.99
    }
  }
</pre>

## Get an invoice
`GET /invoices/:invoice_id`

Returns a representation of the invoice with id `:invoice_id`.

## Modify an existing invoice
`PATCH /invoices/:invoice_id`

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
- **line\_items\_attributes**
  - required: true
  - type: array
  - items: **line item**

### Example

<pre>
  {
    "date": "2012-04-23",
    "number": "Apr2012-Kenny",
    "notes": "Pay on time this month, please!",
    "client_attributes": {
      "name": "Kenny Client",
      "email": "kenny@example.com",
      "address": "123 Client St, Atlanta, GA 30303",
      "phone": "(404) 555-1234"
    },
    "line_items_attributes": {
      "description": "Cat sitting",
      "quantity": 1,
      "unit_price": 99.99,
      "_destroy": true
    }
    "line_items_attributes": {
      "description": "Cat and dog sitting combo",
      quantity: 1
      "unit_price": 150.00
    }
  }
</pre>

## Delete an invoice
`DELETE /invoices/:invoice_id`

## Send an invoice
`POST /invoices/:invoice_id/events` with parameter `type=enqueue` or payload `{"type":"enqueue"}`.

- - -

# Clients
Clients are an attribute of invoices. They are an embedded document in an invoice document.  In the future, I plan to make them also a first-order resource so that they can be used to aggregate invoices. E.g. "three outstanding invoices for Mr X." 

To delete an existing client from an invoice set the `_destroy` parameter to true.

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

<pre>
  {
    "name": "Joe Client",
    "email": "joe@example.com",
    "address": "123 Client St, Atlanta, GA 30303",
    "phone": "(404) 555-1234"
  }
</pre>

- - -

# Line Items
Line items are attributes of invoices. They are for one billable "line" on an invoice. The total of the invoice equals the sum of each line's unit_price times quantity.

To delete an existing line item from an invoice set the `_destroy` parameter to true.

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

<pre>
  {
    "description": "Cat sitting",
    "quantity": 1,
    "unit_price": 99.99
  }
</pre>
