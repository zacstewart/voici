class @Invoice extends Backbone.Model
  defaults:
    date: new Date()
    number: ''
class @LineItem extends Backbone.Model

class @Invoices extends Backbone.Collection
  model: Invoice
  url: ->
    '/invoices'
class @LineItems extends Backbone.Collection
  model: LineItem

class @InvoiceView extends Backbone.View
  tagName: 'li'
  template: _.template $('#invoice_template').html()
  initialize: ->
    @model.on 'change', =>
      @render()
    @model.on 'destroy', =>
      @remove()
  render: ->
    @$el.html @template(@model.toJSON())
    this

class @EditInvoiceView extends Backbone.View
  template: _.template($('#edit_invoice').html())
  events:
    'change': 'updateModel'
    'click a[data-dismiss="modal"]': 'close'
    'click a[href="#save"]': 'save'
  render: ->
    @$el.html(@template(@model.toJSON())).appendTo('body')
  updateModel: (e) ->
    console.log e
    @model.set
      date: @$el.find('input[name=date]').val()
      number: @$el.find('input[name=number]').val()
  close: (e) ->
    e.preventDefault()
    @remove()
  save: (e) ->
    e.preventDefault()
    invoices.add(@model)
    @model.save()

class @InvoicesView extends Backbone.View
  initialize: ->
    @collection.on 'all', =>
      @render()
  render: ->
    @$el.html()
    @collection.each (invoice) ->
      $('#main').append @make('li')

class @BaseView extends Backbone.View
  template: _.template($('#app').remove().html())
  events:
    'click #new_invoice_btn': 'newInvoice'
  render: ->
    @$el.html(@template()).appendTo('body')
  newInvoice: (e) ->
    e.preventDefault()
    view = new EditInvoiceView
      model: new Invoice
    view.render()
class @AppRouter extends Backbone.Router
  initialize: ->
  routes:
    '': 'default'
  default: ->
    baseView.render()

@initApp = (args={}) =>
  # Collections
  @invoices = new Invoices(args.invoices)
  # Views
  @baseView = new BaseView()
  @invoicesView = new InvoicesView
    collection: @invoices
  @router = new AppRouter()
  Backbone.history.start()
