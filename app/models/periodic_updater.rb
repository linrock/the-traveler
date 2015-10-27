class PeriodicUpdater

  def initialize
    @spritesheet = Spritesheet.new
  end

  def run
    loop do
      puts "[#{Time.now}] Regenerating spritesheet..."
      @spritesheet.generate
      sleep 3600
    end
  end

end
