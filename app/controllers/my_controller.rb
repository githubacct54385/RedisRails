# class for testing redis
class MyController < ApplicationController
  def index
    client_ip = remote_ip

    puts client_ip
    # Check for API Throttling
    is_blocked = track_api_usage(client_ip)

    if is_blocked
      render status: 429,
             json: { status: '429', message: throttled_api_message }
    else
      render html: " Hello World! #{client_ip}.  Is Blocked? #{is_blocked}"
    end
  end
end
