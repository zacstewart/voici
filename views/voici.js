(function() {
  var __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    _this = this;

  this.Invoice = (function(_super) {

    __extends(Invoice, _super);

    function Invoice() {
      Invoice.__super__.constructor.apply(this, arguments);
    }

    Invoice.prototype.defaults = {
      date: new Date()
    };

    return Invoice;

  })(Backbone.Model);

  this.LineItem = (function(_super) {

    __extends(LineItem, _super);

    function LineItem() {
      LineItem.__super__.constructor.apply(this, arguments);
    }

    return LineItem;

  })(Backbone.Model);

  this.Invoices = (function(_super) {

    __extends(Invoices, _super);

    function Invoices() {
      Invoices.__super__.constructor.apply(this, arguments);
    }

    Invoices.prototype.model = Invoice;

    return Invoices;

  })(Backbone.Collection);

  this.LineItems = (function(_super) {

    __extends(LineItems, _super);

    function LineItems() {
      LineItems.__super__.constructor.apply(this, arguments);
    }

    LineItems.prototype.model = LineItem;

    return LineItems;

  })(Backbone.Collection);

  this.InvoiceView = (function(_super) {

    __extends(InvoiceView, _super);

    function InvoiceView() {
      InvoiceView.__super__.constructor.apply(this, arguments);
    }

    InvoiceView.prototype.tagName = 'li';

    InvoiceView.prototype.template = _.template($('#invoice_template').html());

    InvoiceView.prototype.initialize = function() {
      var _this = this;
      this.model.on('change', function() {
        return _this.render();
      });
      return this.model.on('destroy', function() {
        return _this.remove();
      });
    };

    InvoiceView.prototype.render = function() {
      this.$el.html(this.template(this.model.toJSON()));
      return this;
    };

    return InvoiceView;

  })(Backbone.View);

  this.EditInvoiceView = (function(_super) {

    __extends(EditInvoiceView, _super);

    function EditInvoiceView() {
      EditInvoiceView.__super__.constructor.apply(this, arguments);
    }

    EditInvoiceView.prototype.template = _.template($('#edit_invoice').html());

    EditInvoiceView.prototype.render = function() {
      return this.template(this.model.toJSON());
    };

    return EditInvoiceView;

  })(Backbone.View);

  this.InvoicesView = (function(_super) {

    __extends(InvoicesView, _super);

    function InvoicesView() {
      InvoicesView.__super__.constructor.apply(this, arguments);
    }

    InvoicesView.prototype.initialize = function() {
      var _this = this;
      return this.collection.on('all', function() {
        return _this.render();
      });
    };

    return InvoicesView;

  })(Backbone.View);

  this.BaseView = (function(_super) {

    __extends(BaseView, _super);

    function BaseView() {
      BaseView.__super__.constructor.apply(this, arguments);
    }

    BaseView.prototype.initialize = function() {
      return this.render();
    };

    BaseView.prototype.template = _.template($('#app').html());

    BaseView.prototype.render = function() {
      return $('body').html(this.template());
    };

    return BaseView;

  })(Backbone.View);

  this.AppRouter = (function(_super) {

    __extends(AppRouter, _super);

    function AppRouter() {
      AppRouter.__super__.constructor.apply(this, arguments);
    }

    AppRouter.prototype.initialize = function() {};

    AppRouter.prototype.routes = {
      '': 'default'
    };

    AppRouter.prototype["default"] = function() {
      return baseView.render();
    };

    return AppRouter;

  })(Backbone.Router);

  this.initApp = function(args) {
    if (args == null) args = {};
    _this.invoices = new Invoices(args.invoices);
    _this.baseView = new BaseView();
    _this.invoicesView = new InvoicesView({
      collection: _this.invoices
    });
    _this.router = new AppRouter();
    return Backbone.history.start();
  };

}).call(this);
