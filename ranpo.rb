require 'unirest'
require 'sinatra'
require 'sinatra/reloader'
require 'yaml'

consumer_key = YAML.load_file("config.yml")["consumer_key"]
Header = { "Content-Type" => "application/json", "X-Accept": "application/json" }

configure do
  enable :sessions
  register Sinatra::Reloader
end

get "/" do
  erb :index
end

get "/auth" do
  # リクエストトークンを発行してもらう
  json = Unirest.post("https://getpocket.com/v3/oauth/request",
          headers: { "Content-Type" => "application/json", "X-Accept" => "application/json" },
          parameters: { consumer_key: consumer_key, redirect_uri: "http://localhost:9299/token_callback" }).body

  session[:request_token] = json["code"]
  # 認証ページヘ
  redirect "https://getpocket.com/auth/authorize?request_token=#{session[:request_token]}&redirect_uri=http://localhost:9299/auth_callback"
end

get "/auth_callback" do # 認証ページから戻ってくる
  # こんどは"認証された"リクエストトークンでアクセストークンをもらう
  json = Unirest.post("https://getpocket.com/v3/oauth/authorize",
          headers: Header,
          parameters: { consumer_key: consumer_key, code: session[:request_token] }).body

  session[:access_token] = json["access_token"]
  session[:user] = json["username"]

  redirect "/random"
end

get "/random" do
  json = Unirest.post("https://getpocket.com/v3/get", headers: Header,
          parameters: { consumer_key: consumer_key, access_token: session[:access_token] }).body
  list = json["list"]

  @article = list[list.keys[rand(list.size)]]

  erb :random
end

get "/r" do
  json = Unirest.post("https://getpocket.com/v3/get", headers: Header,
          parameters: { consumer_key: consumer_key  , access_token: session[:access_token] }).body
  list = json["list"]
  @article = list[list.keys[rand(list.size)]]

  redirect @article["resolved_url"]
end
