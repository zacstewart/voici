class @SessionView extends Backbone.View
  initialize: ->
    @model.on 'all', (trigger) =>
      @render()
  tagName: 'div'
  signInTemplate: _.template($('#sign_in_template').html())
  currentUserTemplate: _.template($('#current_user_template').html())
  events:
    'click a.dropdown-toggle': 'toggleDropdown'
    'submit #new_session': 'signIn'
    'click [href="#sign_out"]': 'signOut'
  render: ->
    template = if @model.signedIn()
      @currentUserTemplate
    else
      @signInTemplate
    @$el.html(template(user_email: @model.user.get('email')))
    this
  signIn: (e) ->
    e.preventDefault() if e?
    @model.save
      email: @$el.find('input[name=email]').val()
      password: @$el.find('input[name=password]').val()
  signOut: (e) ->
    e.preventDefault() if e?
    @model.destroy()
  toggleDropdown: (e) ->
    e.preventDefault()
    @$el.find('.btn-group').toggleClass('open')
