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
        puts "Got url: #{url}"
        FaviconSnapshot.lookup!(url) rescue binding.pry
        job.delete
      end
    ensure
      @beanstalk.close
    end
  end

end
