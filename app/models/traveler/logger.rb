class Traveler::Logger

  def initialize
    @log_file = File.open(Rails.root.join("log/beanstalk.log"), "a+")
    # @error_file = File.open(Rails.root.join("log/beanstalk.log"), "a+")
  end

  def log(message, options = {})
    log_to_file(message)
    log_to_stdout(message, options)
  end

  def log_to_file(message)
    @log_file.write "[#{Time.now}] #{message}\n"
    @log_file.flush
  end

  def log_to_stdout(message, options = {})
    timestamp = colorize("#{Time.now}", "1;37")
    if options[:color_code]
      formatted = "[#{timestamp}] #{colorize(message, options[:color_code])}"
    else
      formatted = "[#{timestamp}] #{message}"
    end
    puts formatted
  end

  def error(error, options = {})
    message = "#{error.class}: #{error.message}"
    message = message + error.backtrace.join("\n") if options[:log_backtrace]
    log message, :color_code => "1;33"
  end

  private

  def colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end

end
