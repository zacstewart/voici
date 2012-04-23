class @SessionlessSidebarView extends Backbone.View
  initialize: ->
    dispatch.on 'signOut', =>
      @render().display()
    dispatch.on 'signIn', (session) =>
      @close()
  tagName: 'div'
  template: _.template($('#sessionless_sidebar_template').html())
  events:
    'submit form#new_user': 'createUser'
  render: ->
    @$el.html(@template())
    this
  display: ->
    $('#sidebar').html(@$el)
  close: ->
    @undelegateEvents()
    @remove()
  createUser: (e) ->
    e.preventDefault()
    $form = $(e.currentTarget)
    @model.user.save(
      {
        email: $form.find('input[name=email]').val()
        password: $form.find('input[name=password]').val()
        password_confirmation: $form.find('input[name=password_confirmation]').val()
      },
      {
        success: => @model.trigger('sync', @model)
      }
    )
