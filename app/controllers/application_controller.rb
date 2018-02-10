# Top level Application Controller.  Contains API Throttling code
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def client_ip_val(client_ip)
    @client_ip = client_ip
  end

  def throttled_api_message
    msg = 'Whoa there!  '
    msg += "You've pinged the server way too many times.  "
    msg + "The cooldown period is #{blocking_timespan} seconds"
  end

  def remote_ip
    if request.remote_ip == '127.0.0.1'
      # Hard coded remote address
      '127.0.0.1'
    else
      request.remote_ip
    end
  end

  def user_key_func
    # compose key for counting requests
    "counting_#{@client_ip}"
  end

  def blocked_user_key_func
    # compose key for identifying blocked users
    "locked_#{@client_ip}"
  end

  def print_details(num_requests)
    puts "Client IP: #{@client_ip} --  Number of Requests: #{num_requests}"
  end

  def watching_timespan
    # time-span to count the requests (in seconds)
    60
  end

  def allowed_requests
    # maximum request allowed within the time-span
    30
  end

  def blocking_timespan
    # "cool-down" period in seconds
    15
  end

  def rails_warning
    msg = 'Overheat: User with id '
    msg += "#{user_key_func} is over usage limit."
    Rails.logger.warn msg
  end

  def exceeded_requests_count(num_requests)
    num_requests > allowed_requests
  end

  def user_is_not_blocked(blocked_user_key)
    RedisModule.redis.get(blocked_user_key) != 1
  end

  def user_key
    # compose key for counting requests
    "counting_#{@client_ip}"
  end

  def blocked_user_key
    # compose key for identifying blocked users
    "locked_#{@client_ip}"
  end

  def redis_module_not_set
    RedisModule.redis.get(blocked_user_key) != 1
  end

  def redis_module_set
    RedisModule.redis.set(blocked_user_key, 1)
  end

  def redis_blocked_flag_set
    # mark the user as "blocked"
    redis_module_set if redis_module_not_set
  end

  def check_limits(num_requests)
    # check limit
    if exceeded_requests_count(num_requests) &&
       user_is_not_blocked(blocked_user_key)
      # write something into the log file for alerting
      rails_warning
      redis_blocked_flag_set
      # make the blocking expiring itself after the defined cool-down period
      RedisModule.redis.expire(blocked_user_key, blocking_timespan)
    end
  end

  def handle_found_user_counter
    # main action: increment counter
    num_requests = RedisModule.redis.incr(user_key)
    print_details(num_requests)
    check_limits(num_requests)
  end

  def handle_not_found_user_counter
    # no key for counting exists yet - so set a new one with ttl
    RedisModule.redis.set(user_key, 1)
    RedisModule.redis.expire(user_key, watching_timespan)
    print_details(1)
  end

  def track_api_usage(client_ip)
    client_ip_val(client_ip)
    # check if the user already has a counter
    if RedisModule.redis.get(user_key)
      handle_found_user_counter
    else
      handle_not_found_user_counter
    end
  end
end
