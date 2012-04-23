class @SessionSidebarView extends Backbone.View
  initialize: ->
    @model.on 'destroy', =>
      @close()
    @model.on 'signIn', (session) =>
      @render().display()
  template: _.template($('#session_sidebar_template').html())
  render: ->
    @$el.html(@template(@model.toJSON()))
    this
  display: ->
    $('#sidebar').html(@$el)
  close: ->
    @undelegateEvents()
    @remove()
