# class for testing redis
class MyController < ApplicationController
  def index
    # get the IP Address of the user who called this method
    @client_ip = remote_ip
    # check for API Throttling
    track_api_usage(@client_ip)
    # get the key of the user who would be blocked
    @blocked_user_key = "locked_#{@client_ip}"
    handle_response
  end
end

def block_msg
  msg = "Client #{@client_ip} /// "
  msg += 'Server Condition: Throttled By User /// '
  msg += "Curr Requests: #{current_requests} /// "
  msg + "Please wait #{blocked_key_pttl} more seconds"
end

def pass_msg
  msg = "Client #{@client_ip} /// Server Condition: Not Throtted. /// "
  msg + "Curr Requests: #{current_requests}"
end

# handles server response with redis throttling
def handle_response
  if RedisModule.redis.get(@blocked_user_key)
    render status: 429, json: { message: block_msg }
  else # everything is fine
    render status: 200, json: { message: pass_msg }
  end
end

def current_requests
  RedisModule.redis.get(user_key)
end

def blocked_key_pttl
  RedisModule.redis.pttl(blocked_user_key) / 1000
end
