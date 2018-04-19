# server.rb
require 'sinatra'
require_relative 'writer_server'

# DB Setup
Mongoid.load! "config/mongoid.yml"

#set binding


