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
  destroy: (e) ->
    e.preventDefault() if e?
    @model.destroy()
    @remove()
  close: ->
    @undelegateEvents()
    @remove()
class @ShowLineItemView extends Backbone.View
  tagName: 'tr'
  template: _.template($('#show_line_item_template').html())
  render: ->
    @setElement(@template(@model.toJSON()))
    this
