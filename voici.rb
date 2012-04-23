require 'bundler'
Bundler.require
set :logging, :true
require File.expand_path('../models.rb', __FILE__)

module AssetHelpers
  def asset_path(source)
    '/assets/' << settings.sprockets.find_asset(source).digest_path
  end
end

uri = URI.parse(ENV['REDISTOGO_URL'] || 'redis://localhost:6379/')
Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

class Unauthorized < Exception
  def code
    401
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

  error Unauthorized do
    env['sinatra.error'].message || 'Unauthorized!'
  end

  helpers do
    include AssetHelpers

    def current_user
      warden.user
    end

    def current_user?
      current_user.present?
    end
  end

  before do
    unless request.path_info =~ /^\// ||
      request.path_info =~ /^\/public/ ||
      request.path_info =~ /^\/docs/ ||
      (request.path_info =~ /^\/users/ && request.request_method == 'POST')
      require_authentication
    end
  end

  # /
  options '/' do
    deliver(
      {
        methods: {
          'GET' => {
            description: "Delivers the static Voici documentation"
          }
        }
      }
    )
  end

  get '/' do
    #bootstrap = {session: {_id: 1, user: current_user}}
    #bootstrap[:invoices] = current_user.invoices.all if current_user?
    #slim :index, locals: {bootstrap: bootstrap}
    redirect '/docs'
  end

  # /doc
  get '/docs' do
    slim :docs, :locals => {content: markdown(:docs)}
  end

  # /invoices
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

  get '/invoices' do
    invoices = current_user.invoices.all
    authorize! :read, invoices
    deliver invoices
  end

  post '/invoices' do
    invoice = current_user.invoices.new params
    if invoice.save
      status 201
      deliver invoice
    else
      raise "Failed to create invoice: #{invoice.errors.full_messages}"
    end
  end

  # /invoices/:invoice_id
  get '/invoices/:invoice_id' do
    invoice = find_invoice
    authorize! :read, invoice
    deliver invoice
  end

  patch '/invoices/:invoice_id' do
    invoice = find_invoice
    authorize! :edit, invoice
    if invoice.update_attributes(params)
      deliver invoice
    else
      raise "Failed to update invoice"
    end
  end

  delete '/invoices/:invoice_id' do
    invoice = find_invoice
    authorize! :delete, invoice
    if invoice.destroy
      deliver invoice
    else
      raise "Failed to delete invoice"
    end
  end

  #get '/invoices/:invoice_id/email.?:format?' do
    #invoice = find_invoice
    #authorize! invoice, :read
    #if params[:format] == 'txt'
      #Slim::Template.new('views/email.txt.slim').render(invoice)
    #else
      #Slim::Template.new('views/email.slim').render(invoice)
    #end
  #end

  post '?/invoices/:invoice_id/?events' do
    invoice = find_invoice
    result = case params[:type].to_sym
    when :enqueue   then invoice.enqueue
    when :delivered then invoice.deliver
    when :opened    then invoice.read
    end
    if result
      status 200
    else
      status 403
      "Inappropriate event #{params[:type]}"
    end
  end

  # /public/invoices/:invoice_key
  get '/public/invoices/:invoice_key' do
    invoice = find_invoice
    authorize! :public_read, invoice
    deliver invoice
  end

  # /users
  options '/users' do
    headers['Allows'] = 'POST,PUT,DELETE'
    deliver({
      methods: {
        'POST' => {
          description: 'Register a new account',
          parameters: {
            email: {
              description: 'Your email address',
              required: true,
              type: 'string'
            },
            password: {
              description: 'Your password',
              required: true,
              type: 'string'
            },
            password_confirmation: {
              description: 'Confirm your password',
              required: true,
              type: 'string'
            },
            name: {
              description: 'Your name as you want it to appear on invoices',
              required: false,
              type: 'string'
            },
            address: {
              description: "The mailing address you'd like to appear on invoices",
              required: false,
              type: 'string'
            },
            phone: {
              description: "The phone number you'd like to appear on invoices",
              required: false,
              type: 'string'
            }
          }
        }
      }
    })
  end

  post '/users' do
    user = User.new(
      email: payload[:email],
      password: payload[:password],
      password_confirmation: payload[:password_confirmation]
    )
    if user.save
      warden.set_user(user)
      status 201
      deliver user
    else
      status 406
      deliver user.errors.full_messages
    end
  end

  options '/me' do
    deliver({
      methods: {
        'PUT' => {
          description: 'Modify an existing account',
          parameters: {
            email: {
              description: 'Your email address',
              required: false,
              type: 'string'
            },
            password: {
              description: 'Your password',
              required: false,
              type: 'string'
            },
            password_confirmation: {
              description: 'Confirm your password',
              required: 'if password is set',
              type: 'string'
            },
            name: {
              description: 'Your name as you want it to appear on invoices',
              required: false,
              type: 'string'
            },
            address: {
              description: "The mailing address you'd like to appear on invoices",
              required: false,
              type: 'string'
            },
            phone: {
              description: "The phone number you'd like to appear on invoices",
              required: false,
              type: 'string'
            }
          }
        },
        'DELETE' => {
          description: 'Delete an account',
          parameters: {
            password: {
              description: 'Your password',
              required: true,
              type: 'string'
            }
          }
        }
      }
    })
  end

  put '/me' do
  end

  delete '/me' do
  end

  # /unauthenticated
  post '/unauthenticated/?' do
    raise Unauthorized
  end

  # /session
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

  def require_authentication
    raise Unauthorized unless current_user?
  end

  def require_no_authentication
    raise "You cannot be authenticated to do that!" if current_user?
  end

  def authorize!(level=:read, *resources)
    resources.each do |resource|
      case resource
      when Invoice
        if [:read, :edit, :delete].include? level
          raise Unauthorized unless resource.user == current_user
        elsif level == :public_read
          raise Unauthorized unless params[:invoice_key] == resource.key && resource.publicly_readable?
        end
      end
    end
  end

  # Request
  def payload
    @_payload ||= HashWithIndifferentAccess.new JSON.parse(request.body.read) rescue {}
  end

  def params
    super.merge(payload)
  end

  # Response
  def deliver(content)
    content_type :json
    content.to_json
  end

  # Resources
  def find_invoice
    #TODO: access control
    @_invoice ||=
      if current_user.present? && params[:invoice_id].present?
        current_user.invoices.find(params[:invoice_id])
      elsif params[:invoice_key].present?
        Invoice.where(key: params[:invoice_key]).first
      end
  end
end
