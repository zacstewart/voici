class @Session extends Backbone.Model
  url: '/session'
  destroy: ->
    super()
    @clear()
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
    template = if @model.has('_id')
      @currentUserTemplate
    else
      @signInTemplate
    @$el.html(template(@model.toJSON()))
    this
  signIn: (e) ->
    e.preventDefault() if e?
    @model.save
      email: @$el.find('input[name=email]').val()
      password: @$el.find('input[name=password]').val()
  signOut: (e) ->
    e.preventDefault() if e?
    @model.destroy
      sucess: ->
        @model.clear()
  toggleDropdown: (e) ->
    e.preventDefault()
    @$el.find('.btn-group').toggleClass('open')

class @BaseView extends Backbone.View
  initialize: ->
    @setElement($('#voici'))
    @$el.find('#session').html(sessionView.render().$el)
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

@initApp = (args={}) =>
  # Models
  @session = new Session()
  # Collections
  @invoices = new Invoices()
  # Views
  @sessionView = new SessionView({model: @session})
  @baseView = new BaseView()
  @invoicesView = new InvoicesView
    collection: @invoices
  @session.set args.current_user
  @invoices.reset args.invoices
  @router = new AppRouter()
  Backbone.history.start()
