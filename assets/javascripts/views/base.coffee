class @BaseView extends Backbone.View
  initialize: ->
    @setElement($('#voici'))
    @$el.find('#session').html(sessionView.render().$el)
  events:
    'click #new_invoice_btn': 'newInvoice'
  newInvoice: (e) ->
    e.preventDefault()
    view = new EditInvoiceView
      model: new Invoice()
    view.display()
