class Traveler::Logger

  COLORS = {
    :white   => "1;37",
    :yellow  => "1;33"
  }

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
    timestamp = colorize("#{Time.now}", :white)
    if options[:color]
      formatted = "[#{timestamp}] #{colorize(message, options[:color])}"
    else
      formatted = "[#{timestamp}] #{message}"
    end
    puts formatted
  end

  def error(error, options = {})
    message = "#{error.class}: #{error.message}"
    message = message + error.backtrace.join("\n") if options[:log_backtrace]
    log message, :color => :yellow
  end

  private

  def colorize(text, color)
    "\e[#{COLORS[color]}m#{text}\e[0m"
  end

end
