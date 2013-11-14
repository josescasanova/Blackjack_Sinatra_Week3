require 'rubygems'
require 'sinatra'

set :sessions, true

get '/' do
  erb :new
end
