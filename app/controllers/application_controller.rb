# Top level Application Controller.  Contains API Throttling code
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def throttled_api_message
    'You have fired too many requests. Please wait for a couple of minutes.'
  end

  def remote_ip
    if request.remote_ip == '127.0.0.1'
      # Hard coded remote address
      '123.45.67.89'
    else
      request.remote_ip
    end
  end

  def user_key_func(client_ip)
    # compose key for counting requests
    "counting_#{client_ip}"
  end

  def blocked_user_key_func(client_ip)
    # compose key for identifying blocked users
    "locked_#{client_ip}"
  end

  def print_details(client_ip, num_requests)
    puts "Client IP: #{client_ip} --  Number of Requests: #{num_requests}"
  end

  def watching_timespan
    # time-span to count the requests (in seconds)
    20
  end

  def allowed_requests
    # maximum request allowed within the time-span
    30
  end

  def blocking_timespan
    # "cool-down" period in seconds
    30
  end

  def rails_warning(client_ip)
    msg = "Overheat: User with id #{user_key_func(client_ip)} is over usage limit."
    Rails.logger.warn msg
  end

  def ShouldBlockUser(client_ip)
    blocked_user = blocked_user_key_func(client_ip)
    if $redis.get(blocked_user)
      return true
    else
      return false
    end
  end

  def track_api_usage(client_ip)
    return true if ShouldBlockUser(client_ip)
    user_key = user_key_func(client_ip)
    if $redis.get(user_key)
      num_requests = $redis.incr(user_key)
      print_details(client_ip, num_requests)
      if num_requests > allowed_requests
        rails_warning(client_ip)
        blocked_user_key = blocked_user_key_func(client_ip)
        $redis.set(blocked_user_key, 1)
        $redis.expire(blocked_user_key, blocking_timespan)
      end
    else
      $redis.set(user_key, 1)
      $redis.expire(user_key, watching_timespan)
    end
  end
end
