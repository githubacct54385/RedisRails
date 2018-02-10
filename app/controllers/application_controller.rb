# Top level Application Controller.  Contains API Throttling code
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def throttled_api_message(client_ip)
    msg = "Whoa there!  "
    msg += "You've pinged the server way too many times.  "
    msg += "The cooldown period is #{blocking_timespan} seconds"
  end

  def remote_ip
    if request.remote_ip == '127.0.0.1'
      # Hard coded remote address
      '127.0.0.1'
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

  def blocking_timespan
    # "cool-down" period in seconds
    15
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

  def ExceededRequestsCount(num_requests, allowed_requests)
    num_requests > allowed_requests
  end

  def UserIsNotBlocked(blocked_user_key)
    $redis.get(blocked_user_key) != 1
  end


  # Returns true
  def track_api_usage(client_ip)
    # time-span to count the requests (in seconds)
    watching_timespan=60
    # maximum request allowed within the time-span
    allowed_requests=30

    #compose key for counting requests
    user_key="counting_#{client_ip}"
    # compose key for identifying blocked users
    blocked_user_key="locked_#{client_ip}"

    # check if the user already has a counter
    if $redis.get(user_key)
      # main action: increment counter
      num_requests=$redis.incr(user_key)
      print_details(client_ip, num_requests)

      # check limit
      if ExceededRequestsCount(num_requests, allowed_requests) && UserIsNotBlocked(blocked_user_key)
        # write something into the log file for alerting
        Rails.logger.warn "Overheat: User with id #{client_ip} is over usage limit."
        # mark the user as "blocked"
        $redis.set(blocked_user_key,1) if $redis.get(blocked_user_key) != 1
        # make the blocking expiring itself after the defined cool-down period
        $redis.expire(blocked_user_key,blocking_timespan)
      end

    else
      # no key for counting exists yet - so set a new one with ttl
      $redis.set(user_key,1)
      $redis.expire(user_key,watching_timespan)
      print_details(client_ip, 1)
    end
  end
end