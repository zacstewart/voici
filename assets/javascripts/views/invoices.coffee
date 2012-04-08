class @InvoiceListView extends Backbone.View
  tagName: 'tr'
  template: _.template $('#invoice_template').html()
  events:
    'click' : 'show'
  initialize: ->
    @model.on 'change', =>
      @render()
    @model.on 'destroy', =>
      @remove()
  render: ->
    @$el.html(@template(@model.toJSON()))
    this
  show: (e) ->
    view = new ShowInvoiceView
      model: @model
    view.display()
class @ShowInvoiceView extends Backbone.View
  initialize: ->
    @model.on 'change', =>
      @render()
    @model.on 'destroy', =>
      @close()
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
    @model.destroy()
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
    @$el.find('[data-role="date"]').datepicker()
    this
  display: ->
    @render().$el.appendTo('body')
  close: (e) ->
    e.preventDefault() if e?
    @model.destroy() if @model.isNew()
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
    @setElement $('#main table tbody')
    @collection.on 'reset', =>
      @render()
      @addAll()
    @collection.on 'add', (invoice) =>
      @addOne(invoice)
  render: ->
    @$el.empty()
  addOne: (invoice) ->
    view = new InvoiceListView
      model: invoice
    @$el.append view.render().el
  addAll: ->
    invoices.each (invoice) =>
      @addOne invoice
