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
    total: @get 'total'
