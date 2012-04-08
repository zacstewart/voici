require 'bundler'
Bundler.require
set :logging, :true

class User
  include Mongoid::Document
  field :email,               type: String
  field :encrypted_password,  type: String
  has_many :invoices
  attr_accessor :password, :password_confirmation
  validates_confirmation_of :password
  validates_presence_of :encrypted_password

  def self.authenticate(email, pass)
    self.find_by_email_and_encry
  end

  def encrypted_password
    @encrypted_password ||= begin
      ep = read_attribute(:encrypted_password)
      ep.nil? ? nil : ::BCrypt::Password.new(ep)
    end
  end

  def password=(pass)
    self.encrypted_password = pass.nil? ? nil : ::BCrypt::Password.create(pass)
  end

  def serializable_hash(opts={})
    {
      _id: id,
      email: email
    }
  end
end

class LineItem
  include Mongoid::Document
  field :description, type: String
  field :quantity,    type: Float
  field :unit_price,  type: Float
  embedded_in :invoice

  def line_price
    self.unit_price * self.quantity
  end
end

class Invoice
  include Mongoid::Document
  include Mongoid::MultiParameterAttributes
  field :date,    type: Date
  field :number,  typw: String
  belongs_to :user
  embeds_many :line_items
  accepts_nested_attributes_for :line_items, allow_destroy: true
  validates_presence_of :date, :number

  def total
    line_items.reduce(0) { |sum, li| sum + li.line_price }
  end

  def serializable_hash(opts={})
    {
      _id: id,
      date: date,
      line_items: line_items,
      number: number,
      total: self.total,
      user_id: user.id
    }
  end
end

module AssetHelpers
  def asset_path(source)
    '/assets/' << settings.sprockets.find_asset(source).digest_path
  end
end

class Voici < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :public_folder, File.dirname(__FILE__) + '/static'
  set :sprockets, Sprockets::Environment.new(root)
  set :precompile, [ /\w+\.(?!js|css).+/, /application.(css|js)$/ ]
  set :assets_prefix, 'assets'
  set :assets_path, File.join(root, assets_prefix)
  Mongoid.load!('config/mongoid.yml')

  configure do
    sprockets.append_path(File.join(root, 'assets', 'stylesheets'))
    sprockets.append_path(File.join(root, 'assets', 'javascripts'))
    sprockets.append_path(File.join(root, 'assets', 'images'))
    sprockets.context_class.instance_eval { include AssetHelpers }
  end

  helpers do
    include AssetHelpers

    def current_user
      warden.user
    end
  end

  get '/' do
    bootstrap = {current_user: current_user}
    bootstrap[:invoices] = current_user.invoices if current_user
    slim :index, locals: {bootstrap: bootstrap}
  end

  get '/invoices' do
    invoices = current_user.invoices.all
    deliver invoices
  end

  post '/invoices' do
    invoice = current_user.invoices.new payload
    if invoice.save
      deliver invoice
    else
      raise "Failed to create invoice"
    end
  end

  get '/invoices/:invoice_id' do
    deliver find_invoice
  end

  put '/invoices/:invoice_id' do
    if find_invoice.update_attributes(payload)
      deliver find_invoice
    else
      raise "Failed to update invoice"
    end
  end

  delete '/invoices/:invoice_id' do
    if find_invoice.destroy
      deliver find_invoice
    else
      raise "Failed to delete invoice"
    end
  end

  post '/users' do
    user = User.new(payload)
    if user.save
      user
    else
      status 406
    end
  end

  post '/unauthenticated/?' do
    status 401
    deliver "Not authorized!"
  end

  post '/session' do
    warden.authenticate! :password
    deliver current_user
  end

  delete '/session' do
    warden.logout
    deliver "That's all folks!"
  end

  private
  # State
  def warden
    @_warden ||= env['warden']
  end

  # Request
  def payload
    @_payload ||= HashWithIndifferentAccess.new JSON.parse(request.body.read).symbolize_keys
  end

  # Response
  def deliver(content)
    content_type :json
    content.to_json
  end

  # Resources
  def all_invoices
    Invoice.all
  end

  def find_invoice
    #TODO: access control
    @_invoice ||= Invoice.find(params[:invoice_id])
  end
end
