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
    total: @get 'total'
class @LineItem extends Backbone.Model
  defaults:
    description: ''
    quantity: 0
    unit_price: 0.00
    line_price: 0.00
  destroy: ->
    @set _destroy: true
    #@trigger 'destroy', this
class @User extends Backbone.Model

class @Invoices extends Backbone.Collection
  initialize: ->
    session.on 'destroy', =>
      @reset()
    session.on 'sync', =>
      @fetch() if session.has('_id')
  model: Invoice
  url: ->
    '/invoices'
class @LineItems extends Backbone.Collection
  model: LineItem
