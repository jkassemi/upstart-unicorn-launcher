module SpecHelper
  def perform_request
    response = Curl::Easy.perform('http://localhost:7516')
  end

  def start_launcher
    @launcher_pid = Process.spawn "upstart-unicorn-launcher -v -s 1 -p spec/templates/test/unicorn.pid -- unicorn -p 7516 -c spec/templates/test/unicorn.rb spec/templates/test/config.ru"
    sleep 1
    puts "Launched upstart-unicorn-launcher with PID #{@launcher_pid}"
  end

  def send_to_launcher(signal)
    Process.kill signal, @launcher_pid
  end

  def kill_launcher
    puts "Killing #{@launcher_pid}"
    Process.kill "QUIT", @launcher_pid
  end

  RSpec.configure do |config|
    config.include self
  end
end

