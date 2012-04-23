class User
  include Mongoid::Document
  field :email,               type: String
  field :encrypted_password,  type: String
  field :name,                type: String
  field :address,             type: String
  field :phone,               type: String
  has_many :invoices
  attr_accessor :password, :password_confirmation
  attr_accessible :email, :name, :phone, :address
  validates :email, presence: true, uniqueness: true
  validates_confirmation_of :password

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
      address: address,
      email: email,
      name: name,
      phone: phone
    }
  end
end

class LineItem
  include Mongoid::Document
  field :description, type: String
  field :quantity,    type: Float, default: 1
  field :unit_price,  type: Float, default: 0
  embedded_in :invoice

  def line_price
    self.unit_price * self.quantity rescue 0
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
  field :key,     type: String
  field :date,    type: Date
  field :number,  type: String
  field :state,   type: String
  field :notes,   type: String
  belongs_to :user
  embeds_one :client
  embeds_many :line_items
  accepts_nested_attributes_for :client, :line_items, allow_destroy: true
  validates :key, presence: true, uniqueness: true
  validates_presence_of :date, :number
  before_validation :generate_key

  state_machine :state, :initial => :saved do
    event :enqueue do
      transition any - :enqueued => :enqueued
    end

    event :fail_to_send do
      transition :enqueued => :failed_to_send
    end

    event :transmit do # Would prefer +send+, but for obvious reasons, transmit
      transition :enqueued => :sent
    end

    event :deliver do
      transition :sent => :delivered
    end

    event :read do
      transition :delivered => :opened
    end

    state all - [:sent, :delivered, :opened] do
      def publicly_readable?; false; end
    end

    state :sent, :delivered, :opened do
      def publicly_readable?; true; end
    end

    before_transition any => :enqueued, :do => :queue_mailer_job
  end

  def generate_key(opts={})
    self.key = UUID.generate(:compact) unless key.present? || opts[:force]
  end

  def queue_mailer_job
    Resque.enqueue(InvoiceMailer, self.id)
  end

  def total
    line_items.reduce(0) { |sum, li| sum + li.line_price }
  end

  def serializable_hash(opts={})
    {
      _id: id,
      key: key,
      client: client,
      date: date,
      line_items: line_items,
      notes: notes,
      number: number,
      state: state,
      total: total,
      user: user,
    }
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
      :body => Slim::Template.new('views/email.txt.slim').render(invoice),
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
    invoice.transmit
  rescue => e
    invoice.fail_to_send
    raise e
  end
end
