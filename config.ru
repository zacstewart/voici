require './voici'
use Rack::Session::Cookie, :secret => 'this is not a miror'
use Warden::Manager do |manager|
  manager.default_strategies :password
  manager.failure_app = Voici
end
Warden::Manager.serialize_into_session{|user| user.id }
Warden::Manager.serialize_from_session{|id| User.find(id) }
Warden::Manager.before_failure do |env,opts|
  # Sinatra is very sensitive to the request method
  # since authentication could fail on any type of method, we need
  # to set it for the failure app so it is routed to the correct block
  env['REQUEST_METHOD'] = "POST"
end
Warden::Strategies.add(:password) do
  def valid?
    payload[:email] && payload[:password]
  end

  def authenticate!
    return fail! unless user = User.first(conditions: {email: payload[:email]})
    if user.encrypted_password == payload[:password]
      success!(user)
    else
      errors.add(:login, "Username or Password incorrect")
      fail!
    end
  end

  def payload
    @_payload ||= JSON.parse(request.body.read).symbolize_keys
  end
end
map '/assets' do
  run Voici.sprockets
end
map '/' do
  run Voici
end
