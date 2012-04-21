require 'bundler'
Bundler.require
set :logging, :true

class User
  include Mongoid::Document
  field :email,               type: String
  field :name,                type: String
  field :phone,               type: String
  field :address,             type: String
  field :encrypted_password,  type: String
  has_many :invoices
  attr_accessor :password, :password_confirmation
  attr_accessible :email
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
    @password = pass
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

class Client
  include Mongoid::Document
  field :name,    type: String
  field :email,   type: String
  field :phone,   type: String
  field :address, type: String
  validates_presence_of :email
  embedded_in :invoice
end

class Invoice
  include Mongoid::Document
  include Mongoid::MultiParameterAttributes
  field :date,    type: Date
  field :number,  type: String
  field :status,  type: String
  belongs_to :user
  embeds_one :client
  embeds_many :line_items
  accepts_nested_attributes_for :client, :line_items, allow_destroy: true
  validates_presence_of :date, :number
  after_save :send_if_sent

  def total
    line_items.reduce(0) { |sum, li| sum + li.line_price }
  end

  def serializable_hash(opts={})
    {
      _id: id,
      user_id: user.id,
      date: date,
      status: status,
      number: number,
      total: total,
      client: client,
      line_items: line_items,
    }
  end

  def send_if_sent
    Resque.enqueue(InvoiceMailer, self.id) if status == 'sent'
  end
end

class InvoiceMailer
  @queue = :invoice_send
  def self.perform(invoice_id)
    invoice = Invoice.find(invoice_id)
    Pony.mail(
      :to => invoice.client.email,
      :from => "#{invoice.user.name} <#{invoice.user.email}>",
      :subject => "Invoice #{invoice.number}",
      :html_body => Slim::Template.new('views/email.slim').render(invoice),
      :via => :smtp,
      :via_options => {
        :address              => 'smtp.sendgrid.net',
        :port                 => '587',
        :enable_starttls_auto => true,
        :user_name            => ENV['SENDGRID_USERNAME'],
        :password             => ENV['SENDGRID_PASSWORD'],
        :authentication       => :plain,
        :domain               => "herokuapp.com"
      }
    )
    invoice.update_attribute(:status, 'delivered')
  end
end

module AssetHelpers
  def asset_path(source)
    '/assets/' << settings.sprockets.find_asset(source).digest_path
  end
end

uri = URI.parse(ENV['REDISTOGO_URL'])
Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

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

    def authorize!(level, resource)
      case level
      when :public_read
        return
      end
    end
  end

  get '/' do
    bootstrap = {session: {_id: 1, user: current_user}}
    bootstrap[:invoices] = current_user.invoices.all if current_user
    slim :index, locals: {bootstrap: bootstrap}
  end

  # /invoices
  get '/invoices' do
    invoices = current_user.invoices.all
    deliver invoices
  end

  options '/invoices' do
    if current_user
      headers['Allows'] = 'HEAD,GET,POST,OPTIONS'
    else
      headers['Allows'] = 'HEAD,GET,OPTIONS'
    end
    deliver(
      'GET' => {
        descripion: 'Returns a list of invoices for the currently authenticated user.'
      },
      'POST' => {
        description: 'Create a new invoice.',
        parameters: {
          'date' => {
            type: 'string',
          },
          'date' => {
            type: 'date'
          }
        }
      }
    )
  end

  post '/invoices' do
    invoice = current_user.invoices.new payload
    if invoice.save
      deliver invoice
    else
      raise "Failed to create invoice"
    end
  end

  # /invoices/:invoice_id
  get '/invoices/:invoice_id' do
    invoice = find_invoice
    authorize! invoice, :read
    deliver invoice
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
    user = User.new
    user.email = payload[:email]
    user.password = payload[:password]
    user.password_confirmation = payload[:password_confirmation]
    if user.save
      warden.set_user(user)
      deliver user
    else
      status 406
      deliver user.errors
    end
  end

  post '/unauthenticated/?' do
    status 401
    deliver "Not authorized!"
  end

  post '/session' do
    warden.authenticate! :password
    deliver(
      _id: 1,
      user: current_user
    )
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
    @_payload ||= HashWithIndifferentAccess.new JSON.parse(request.body.read)
  end

  # Response
  def deliver(content)
    content_type :json
    content.to_json
  end

  # Resources

  def find_invoice
    #TODO: access control
    @_invoice ||= current_user.invoices.find(params[:invoice_id])
  end
end
