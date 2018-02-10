# class for testing redis
class MyController < ApplicationController
  def index
    client_ip = remote_ip

    puts client_ip
    # Check for API Throttling
    track_api_usage(client_ip)

    blocked_user_key="locked_#{client_ip}"
    if RedisModule.redis.get(blocked_user_key)
      render status: 429,
             json: { message: throttled_api_message(client_ip) }
    else
      msg = "Client #{client_ip} /// Server Condition: Not Throtted."
      render html: msg
    end
  end
end
