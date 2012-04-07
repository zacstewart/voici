Backbone.Model::idAttribute = '_id'
class @Invoice extends Backbone.Model
  initialize: ->
    @lineItems = new LineItems(@get('line_items') || new LineItem())
  defaults:
    date: new Date()
    number: ''
  urlRoot: ->
    '/invoices'
  toJSON: ->
    _id: @get 'id'
    date: @get 'date'
    number: @get 'number'
    line_items_attributes: @lineItems.map((line_item) -> line_item.toJSON())
class @LineItem extends Backbone.Model
  defaults:
    description: ''
    quantity: 0
    unit_price: 0.00
    line_price: 0.00
  destroy: ->
    @collection.remove this
    @trigger 'destroy', this
class @User extends Backbone.Model

class @Invoices extends Backbone.Collection
  model: Invoice
  url: ->
    '/invoices'
class @LineItems extends Backbone.Collection
  model: LineItem
