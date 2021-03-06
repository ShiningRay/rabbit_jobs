# -*- encoding : utf-8 -*-
require 'uri'

module RabbitJobs
  module AmqpHelpers

    # Calls given block with initialized amqp
    def amqp_with_exchange(&block)
      raise ArgumentError unless block

      connection = AMQP.connection
      if connection && connection.open?
        channel = AMQP::Channel.new(connection)
        exchange = channel.direct(RJ.config[:exchange], RJ.config[:exchange_params])
        # go work
        block.call(connection, exchange)

      else
        AMQP.start(RJ.config.connection_options) do |connection|

          channel = AMQP::Channel.new(connection)

          channel.on_error do |ch, channel_close|
            puts "Channel-level error: #{channel_close.reply_text}, shutting down..."
            connection.close { EM.stop }
          end

          exchange = channel.direct(RJ.config[:exchange], RJ.config[:exchange_params])
          # go work
          block.call(connection, exchange)
        end
      end
    end

    def amqp_with_queue(routing_key, &block)
      raise ArgumentError unless routing_key && block

      amqp_with_exchange do |connection, exchange|
        queue = make_queue(exchange, routing_key.to_s)

        # go work
        block.call(connection, queue)
      end
    end

    def make_queue(exchange, routing_key)
      queue = exchange.channel.queue(RJ.config.queue_name(routing_key), RJ.config[:queues][routing_key])
      queue.bind(exchange, :routing_key => routing_key)
      queue
    end
  end
end