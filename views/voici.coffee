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
class @Invoices extends Backbone.Collection
  model: Invoice
  url: ->
    '/invoices'
class @LineItems extends Backbone.Collection
  model: LineItem
class @EditLineItemView extends Backbone.View
  initialize: ->
    @model.on 'destroy', =>
      @close()
  tagName: 'tr'
  template: _.template($('#edit_line_item_template').html())
  events:
    'change': 'updateModel'
    'click [href="#remove_line_item"]': 'destroy'
  render: ->
    @setElement(@template(@model.toJSON()))
    this
  updateModel: ->
    @model.set
      description: @$el.find('input[name=description]').val()
      quantity: @$el.find('input[name=quantity]').val()
      unit_price: @$el.find('input[name=unit_price]').val()
  destroy: ->
    @model.destroy()
  close: ->
    @undelegateEvents()
    @remove()
class @ShowLineItemView extends Backbone.View
  tagName: 'tr'
  template: _.template($('#show_line_item_template').html())
  render: ->
    @setElement(@template(@model.toJSON()))
    this
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
    @addAllItems()
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
  addOneItem: (item) ->
    view = new ShowLineItemView
      model: item
    @$el.find('#line_items').append(view.render().$el)
  addAllItems: ->
    @model.lineItems.each (item) =>
      @addOneItem(item)
  close: ->
    @undelegateEvents()
    @remove()
class @EditInvoiceView extends Backbone.View
  initialize: ->
    @model.on 'sync', (trigger, etc) ->
    @model.lineItems.on 'add', (item) =>
      @addOneItem(item)
  template: _.template($('#edit_invoice_template').html())
  tagName: 'div'
  events:
    'click a[data-dismiss="modal"]': 'close'
    'click a[href="#save"]': 'save'
    'click a[href="#new_item"]': 'newItem'
  render: ->
    @$el.html(@template(@model.toJSON()))
    @addAllItems()
    this
  display: ->
    @render().$el.appendTo('body')
  close: (e) ->
    e.preventDefault() if e?
    @model.destroy if @model.isNew()
    @undelegateEvents()
    @remove()
  save: (e) ->
    e.preventDefault()
    @model.save({
        date: @$el.find('input[name=date]').val()
        number: @$el.find('input[name=number]').val()
      },
      success: =>
        invoices.add @model
        @close()
    )
  addOneItem: (item) ->
    view = new EditLineItemView
      model: item
    @$el.find('#line_items').append(view.render().$el)
  addAllItems: ->
    @model.lineItems.each (item) =>
      @addOneItem(item)
  newItem: (e) ->
    e.preventDefault()
    @model.lineItems.add new LineItem()
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
      model: new Invoice()
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
