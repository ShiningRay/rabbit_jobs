# -*- encoding : utf-8 -*-
require 'spec_helper'

describe RabbitJobs::Configuration do
  it 'builds configuration from configure block' do
    RabbitJobs.configure do |c|
      c.host "somehost.lan"

      c.exchange 'my_exchange', durable: true, auto_delete: false

      c.queue 'durable_queue', durable: true,  auto_delete: false, ack: true, arguments: {'x-ha-policy' => 'all'}
      c.queue 'fast_queue',    durable: false, auto_delete: true,  ack: false
    end

    RabbitJobs.config.to_hash.should == {
      host: "somehost.lan",
      exchange: "my_exchange",
      exchange_params: {
        durable: true,
        auto_delete: false
      },
      queues: {
        "durable_queue" => {
          durable: true,
          auto_delete: false,
          ack: true,
          arguments: {"x-ha-policy"=>"all"}
        },
        "fast_queue" => {
          durable: false,
          auto_delete: true,
          ack: false
        },
      }
    }
  end

  it 'builds configuration from yaml' do
    RabbitJobs.config.load_file(File.expand_path('../../fixtures/config.yml', __FILE__))

    RabbitJobs.config.to_hash.should == {
      host: "example.com",
      exchange: "my_exchange",
      exchange_params: {
        durable: true,
        auto_delete: false
      },
      queues: {
        "durable_queue" => {
          durable: true,
          auto_delete: false,
          ack: true,
          arguments: {"x-ha-policy"=>"all"}
        },
        "fast_queue" => {
          durable: false,
          auto_delete: true,
          ack: false
        }
      }
    }
  end
end