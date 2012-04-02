require 'sinatra'
require 'json'
require 'mongoid'
require 'slim'

class Voici < Sinatra::Base
  Mongoid.load!("config/mongoid.yml")
  set :public_folder, File.dirname(__FILE__) + '/static'

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
    #embeds_many :line_items
    #accepts_nested_attributes_for :line_items
  end

  get '/' do
    @invoices = Invoice.all || []
    slim :index
  end

  get '/voici.js' do
    coffee :voici
  end

  get '/invoices.?:format?' do
    content_type :json
    Invoice.all.to_json
  end

  post '/invoices.?:format?' do
    invoice = JSON.parse(request.body.read)
    @invoice = Invoice.new(
      date: invoice['date'],
      number: invoice['number']
    )
    content_type :json
    if @invoice.save
      @invoice.to_json
    else
      'Fail!'
    end
  end

  get '/invoices/:id' do
    invoice = Invoice.find(params[:id])
    content_type :json
    invoice.to_json
  end
end
