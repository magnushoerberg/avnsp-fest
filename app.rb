require 'sinatra'

before do
  content_type :html, :charset => 'utf-8'
  halt 401 unless session[:email] or request.path == '/sso'
end

error 401 do
  redirect "https://avnsp-sso.herokuapp.com/?return_url=#{request.url}"
end

error 403 do
  redirect "https://avnsp-sso.herokuapp.com/forbidden"
end
get '/' do
  "hello"
end

get '/sso' do
  halt 401 if params[:time].to_i < Time.now.to_i - 120
  raise "SHARED SSO KEY is missing" unless ENV['SHARED_SSO_KEY']

  msg   = [params[:uuid], params[:time], params[:email],
    params[:first_name], params[:last_name], params[:nickname]].map(&:to_s).join(":")
  sha1  = OpenSSL::Digest::Digest.new('sha1')
  token = OpenSSL::HMAC.hexdigest(sha1, ENV['SHARED_SSO_KEY'], msg)

  halt 403 if params[:token] != token
  session[:uuid] = params[:uuid]
  session[:nickname] = params[:nickname]
  session[:email] = params[:email]
  redirect params[:return_url] || '/'
end
