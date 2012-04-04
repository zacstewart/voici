class @Invoice extends Backbone.Model
  idAttribute: "_id"
  defaults:
    date: new Date()
    number: ''
  urlRoot: ->
    '/invoices'
class @LineItem extends Backbone.Model

class @Invoices extends Backbone.Collection
  model: Invoice
  url: ->
    '/invoices'
class @LineItems extends Backbone.Collection
  model: LineItem

class @InvoiceListView extends Backbone.View
  tagName: 'li'
  template: _.template $('#invoice_template').html()
  events:
    'click' : 'show'
  initialize: ->
    @model.on 'change', =>
      @render()
    @model.on 'destroy', =>
      @remove()
  render: ->
    @$el.html(@template(@model.toJSON())).data('id', @model.id)
    this
  show: (e) ->
    view = new ShowInvoiceView
      model: @model
    view.display()
class @ShowInvoiceView extends Backbone.View
  initialize: ->
    @model.on 'change', =>
      @render()
  tagName: 'div'
  template: _.template($('#show_invoice_template').html())
  events:
    'click a[data-dismiss="modal"]': 'close'
    'click a[href="#delete"]': 'delete'
    'click a[href="#edit"]': 'edit'
  render: ->
    @$el.html(@template(@model.toJSON()))
    this
  display: ->
    @render().$el.appendTo('body')
    this
  delete: (e) ->
    e.preventDefault()
    @model.destroy
      success: =>
        @close()
  edit: (e) ->
    e.preventDefault() if e?
    view = new EditInvoiceView
      model: @model
    view.display()
    @close()
  close: ->
    @remove()
class @EditInvoiceView extends Backbone.View
  initialize: ->
    @model.on 'sync', (trigger, etc) ->
  template: _.template($('#edit_invoice_template').html())
  tagName: 'div'
  events:
    'change': 'updateModel'
    'click a[data-dismiss="modal"]': 'close'
    'click a[href="#save"]': 'save'
  render: ->
    @$el.html(@template(@model.toJSON()))
    this
  display: ->
    @render().$el.appendTo('body')
  updateModel: (e) ->
    @model.set
      date: @$el.find('input[name=date]').val()
      number: @$el.find('input[name=number]').val()
  close: (e) ->
    e.preventDefault() if e?
    @model.destroy if @model.isNew()
    @remove()
  save: (e) ->
    e.preventDefault()
    @model.save null,
      success: =>
        invoices.add @model
        @close()
class @InvoicesView extends Backbone.View
  initialize: ->
    @collection.on 'reset', =>
      @addAll()
    @collection.on 'add', (invoice) =>
      @addOne(invoice)
  render: ->
    @$el.html()
  addOne: (invoice) ->
    view = new InvoiceListView
      model: invoice
    $('#main').append view.render().el
  addAll: ->
    invoices.each (invoice) =>
      @addOne invoice
class @BaseView extends Backbone.View
  initialize: ->
    @setElement($('#voici'))
  events:
    'click #new_invoice_btn': 'newInvoice'
  newInvoice: (e) ->
    e.preventDefault()
    view = new EditInvoiceView
      model: new Invoice
    view.display()
class @AppRouter extends Backbone.Router
  initialize: ->
  routes:
    '': 'default'
  default: ->
    baseView.render()

@initApp = (args={}) =>
  # Collections
  @invoices = new Invoices()
  # Views
  @baseView = new BaseView()
  @invoicesView = new InvoicesView
    collection: @invoices
  @invoices.reset args.invoices
  @router = new AppRouter()
  Backbone.history.start()
