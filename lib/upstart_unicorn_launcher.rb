require 'timeout'

class UpstartUnicornLauncher
  attr_accessor :command, :pidfile, :startup_period, :tick_period, :restarting

  def initialize(command, options = {})
    self.command = command
    self.pidfile = File.expand_path(options[:pidfile] || 'unicorn.pid')
    self.startup_period = options[:startup] || 60
    self.tick_period = options[:tick] || 0.1
  end

  def start
    debug "Starting server"
    restart_server_on :HUP
    quit_server_on :QUIT, :INT, :TERM
    forward_to_server :USR1, :USR2, :WINCH, :TTIN, :TTOU
    start_server
    wait_until_server_quits
  end

  private

  def start_server
    abort "The unicorn pidfile '#{pidfile}' already exists.  Is the server running already?" if File.exist?(pidfile)
    spawned_pid = Process.spawn command
    wait_for { File.exist?(pidfile) }
  rescue Timeout::Error
    Process.kill "QUIT", spawned_pid
    abort "Unable to find server running with pidfile #{pidfile}.  Exiting"
  end

  def restart_server_on(*signals)
    signals.each do |signal|
      trap(signal.to_s) { restart_server }
    end
  end

  def quit_server_on(*signals)
    signals.each do |signal|
      trap(signal.to_s) do
        Process.kill signal.to_s, pid
        wait_until_server_quits
        exit
      end
    end
  end

  def forward_to_server(*signals)
    signals.each do |signal|
      trap(signal.to_s) do
        debug "Forwarding #{signal} to #{pid}"
        Process.kill signal.to_s, pid
      end
    end
  end

  def wait_until_server_quits
    wait_for { !running? }
  end

  def restart_server
    reexecute_running_binary
    wait_for_server_to_start
    quit_old_master
  end

  def reexecute_running_binary
    Process.kill "USR2", pid
  end

  def wait_for_server_to_start
    sleep startup_period
  end

  def quit_old_master
    if old_pid
      Process.kill "QUIT", old_pid
    end
  end

  def pid
    File.exist?(pidfile) && File.read(pidfile).to_i
  end

  def old_pid
    old_pidfile = pidfile + ".oldbin"
    File.exist?(old_pidfile) && File.read(old_pidfile).to_i
  end

  def running?
    pid && Process.getpgid(pid)
  rescue Errno::ESRCH
    false
  end

  private

  def debug(message)
    puts message
  end

  def wait_for(timeout = 20, &block)
    Timeout::timeout timeout do
      until block.call
        sleep tick_period
      end
    end
  end
end
