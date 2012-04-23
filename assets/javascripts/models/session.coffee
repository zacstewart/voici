class @Session extends Backbone.Model
  initialize: ->
    @user = new User()
    @on 'sync change', (session) =>
      @user.set(session.get('user'))
      dispatch.trigger 'signIn', this
    @on 'destroy', (session) =>
      @clear()
      dispatch.trigger 'signOut', this
  url: '/session'
  signedIn: ->
    @user.has('_id')
