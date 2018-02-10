# class for testing redis
class MyController < ApplicationController
  def index
    # get the IP Address of the user who called this method
    client_ip = remote_ip
    # check for API Throttling
    track_api_usage(client_ip)
    # get the key of the user who would be blocked
    blocked_user_key = "locked_#{client_ip}"
    handle_response(blocked_user_key, client_ip)
  end
end

# handles server response with redis throttling
def handle_response(blocked_user_key, client_ip)
  # if user IP is blocked, show a message
  if RedisModule.redis.get(blocked_user_key)
    render status: 429,
           json: { message: throttled_api_message }
  else # everything is fine
    msg = "Client #{client_ip} /// Server Condition: Not Throtted."
    render html: msg
  end
end
