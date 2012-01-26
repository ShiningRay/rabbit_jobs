# -*- encoding : utf-8 -*-

require 'json'
require 'amqp'
require 'eventmachine'

module RabbitJobs
  module Publisher
    extend self
    extend Helpers

    def enqueue(klass, *params)
      key = RabbitJobs.config.routing_keys.first
      enqueue_to(key, klass, *params)
    end

    def enqueue_to(routing_key, klass, *params)
      raise ArgumentError unless klass && routing_key

      payload = ([klass.to_s] + params).to_json

      with_queue(routing_key) do |connection, exchange, queue|
        exchange.publish(payload, RabbitJobs.config.publish_params.merge({routing_key: routing_key})) {
          connection.close { EM.stop }
        }
      end
    end

    def purge_queue(routing_key)
      raise ArgumentError unless routing_key

      with_queue(routing_key) do |connection, exchange, queue|
        queue.status do |number_of_messages, number_of_consumers|
          queue.purge {
            connection.close {
              EM.stop
              return number_of_messages
            }
          }
        end
      end
    end
  end
end