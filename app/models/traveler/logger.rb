class Traveler::Logger

  def initialize
    @log_file = File.open(Rails.root.join("log/beanstalk.log"), "a+")
    # @error_file = File.open(Rails.root.join("log/beanstalk.log"), "a+")
  end

  def log(message)
    formatted = "[#{Time.now}] #{message}"
    puts formatted
    @log_file.write formatted + "\n"
    @log_file.flush
  end

  def error(error, options = {})
    message = "#{error.class}: #{error.message}\n"
    message = message + error.backtrace.join("\n") if options[:log_backtrace]
    log message
  end

end
