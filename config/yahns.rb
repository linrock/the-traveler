worker_processes(1) do

  # these names are based on pthread_atfork(3) documentation
  atfork_child do
    defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
    puts "#$$ yahns worker is running"
  end

  atfork_prepare do
    defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
    puts "#$$ yahns parent about to spawn"
  end

  atfork_parent do
    # puts "#$$ this is probably not useful"
  end

end


# working_directory "/path/to/my_app"

# stdout_path               "log/yahns.out.log"
stderr_path               "log/yahns.err.log"
pid                       "tmp/pids/yahns.pid"
client_expire_threshold    0.5

app(:rack, "config.ru", preload: false) do
  listen                   3000
  client_max_body_size     1024 * 1024
  input_buffering          true
  output_buffering         true # this lazy by default
  client_timeout           5
  persistent_connections   true
end
