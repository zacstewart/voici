class @LineItem extends Backbone.Model
  defaults:
    description: ''
    quantity: 0
    unit_price: 0.00
    line_price: 0.00
  destroy: ->
    @set _destroy: true
