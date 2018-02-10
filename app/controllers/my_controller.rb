# class for testing redis
class MyController < ApplicationController
  def index
    client_ip = remote_ip

    puts client_ip
    # Check for API Throttling
    track_api_usage(client_ip)

    blocked_user_key="locked_#{client_ip}"
    if $redis.get(blocked_user_key)
      render status: 429,
             json: { message: throttled_api_message(client_ip) }
    else
      render html: "Client IP: #{client_ip}.  You have not yet throttled the server."
    end
  end
end
