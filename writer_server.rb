#!/usr/bin/env ruby
require 'bunny'
require 'thread'
require 'mongoid'
require 'mongoid_search'
require 'sinatra'
require 'byebug'
require 'time_difference'
require 'time'
require 'json'
require 'redis'
require_relative 'models/tweet'

Mongoid.load! "config/mongoid.yml"

num = 0

class WriterServer
  def initialize(id)
    @connection = Bunny.new(id)
    @connection.start
    @channel = @connection.create_channel
  end

  def start(queue_name)
    @queue = channel.queue(queue_name)
    @exchange = channel.default_exchange
    subscribe_to_queue
  end

  def stop
    channel.close
    connection.close
  end

  private

  attr_reader :channel, :exchange, :queue, :connection, :exchange2, :queue2

  def subscribe_to_queue
    queue.subscribe(block: true) do |_delivery_info, properties, payload|
      process(payload)
    end
  end

  def process(original)
    num = num++
    puts "started processing tweet: #{num}"
    hydrate_original = JSON.parse(original)
    tweet = Tweet.new(
      contents: hydrate_original["contents"],
      date_posted: hydrate_original["date_posted"],
      user: {username: hydrate_original["user"]["username"],
      id: hydrate_original["user"]["user_id"]
    },
      mentions: hydrate_original["mentions"]
    )
    tweet.save
    puts "finished processing tweet: #{num}"
  end

end


begin
  server = WriterServer.new(ENV["RABBITMQ_BIGWIG_RX_URL"])
  server.start('writer_queue')
rescue Interrupt => _
  server.stop
end
