class @WelcomeView extends Backbone.View
  initialize: ->
    dispatch.on 'signIn', =>
      @close()
    dispatch.on 'signOut', =>
      @render().display()
  tagName: 'div'
  template: _.template($('#welcome_view').html())
  render: ->
    @$el.html(@template())
    this
  display: ->
    $('#main').html(@$el)
  close: ->
    @undelegateEvents()
    @remove()
