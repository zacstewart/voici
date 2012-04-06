require 'sinatra'
require 'json'
require 'mongoid'
require 'slim'
class LineItem
  include Mongoid::Document
  field :description, type: String
  field :quantity,    type: Float
  field :unit_price,  type: Float
  embedded_in :invoice

  def total_price
    self.unit_price * self.quantity
  end
end

class Invoice
  include Mongoid::Document
  include Mongoid::MultiParameterAttributes
  field :date,    type: Date
  field :number,  typw: String
  embeds_many :line_items
  accepts_nested_attributes_for :line_items
  validates_presence_of :date, :number
end

class Voici < Sinatra::Base
  Mongoid.load!("config/mongoid.yml")
  set :public_folder, File.dirname(__FILE__) + '/static'

  get '/' do
    slim :index, locals: {invoices: all_invoices}
  end

  get '/voici.js' do
    coffee :voici
  end

  get '/invoices' do
    invoices = Invoice.all
    deliver invoices
  end

  post '/invoices' do
    invoice = Invoice.new payload
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

  private

  def payload
    JSON.parse(request.body.read)
  end

  def deliver(content)
    content_type :json
    content.to_json
  end

  def all_invoices
    Invoice.all
  end

  def find_invoice
    #TODO: access control
    @_invoice ||= Invoice.find(params[:invoice_id])
  end
end
