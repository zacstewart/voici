class @AppRouter extends Backbone.Router
  initialize: ->
  routes:
    '': 'default'
  default: ->
    if session.signedIn()
      invoicesView.render().display()
      sessionSidebarView.render().display()
    else
      welcomeView.render().display()
      sessionlessSidebarView.render().display()

@initApp = (args={}) =>
  # Dispatch
  @dispatch = _({}).extend(Backbone.Events)
  # Models
  @session = new Session()
  # Collections
  @invoices = new Invoices()
  # Views
  @welcomeView = new WelcomeView()
  @sessionlessSidebarView = new SessionlessSidebarView
    model: @session
  @sessionView = new SessionView
    model: @session
  @sessionSidebarView = new SessionSidebarView
    model: @session
  @baseView = new BaseView()
  @invoicesView = new InvoicesView
    collection: @invoices

  # Bootstrap
  @session.set args.session
  @invoices.reset args.invoices if args.invoices

  # Start
  @router = new AppRouter()
  Backbone.history.start()
