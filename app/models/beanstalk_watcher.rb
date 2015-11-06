class BeanstalkWatcher

  def initialize
    @beanstalk = Beaneater.new(['localhost:11300'])
    @tube = @beanstalk.tubes["favicon_urls"]
  end

  def add_url(url)
    @tube.put url
  end

  def run
    puts "Watching for urls in Beanstalkd queue"
    begin
      while (job = @tube.reserve)
        url = job.body
        puts "Checking url: #{url}"
        begin
          FaviconSnapshot.lookup!(url)
        rescue => e
          puts "Failed to fetch for #{url}"
          puts "Error: #{e}"
          binding.pry
        end
        job.delete
      end
    ensure
      @beanstalk.close
    end
  end

end
