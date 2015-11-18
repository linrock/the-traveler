class Traveler::Logger

  COLORS = {
    :yellow  => "1;33",
    :cyan    => "1;36",
    :white   => "1;37",
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
    puts "[#{Time.now}] #{colorize(message, options[:color])}"
  end

  def error(error, options = {})
    message = "#{error.class}: #{error.message}"
    message = message + error.backtrace.join("\n") if options[:log_backtrace]
    log message, :color => :yellow
  end

  private

  def colorize(text, color)
    return text unless color
    "\e[#{COLORS[color]}m#{text}\e[0m"
  end

end
