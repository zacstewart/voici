class @Invoices extends Backbone.Collection
  initialize: ->
    session.on 'destroy', =>
      @reset()
    session.on 'sync', =>
      @fetch() if session.has('_id')
  model: Invoice
  url: ->
    '/invoices'
