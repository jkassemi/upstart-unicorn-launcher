require 'timeout'

class UpstartUnicornLauncher
  attr_accessor :command, :pidfile, :startup_period, :tick_period, :restarting, :verbose

  def initialize(command, options = {})
    self.command = command
    self.pidfile = File.expand_path(options[:pidfile] || 'unicorn.pid')
    self.startup_period = options[:startup] || 60
    self.tick_period = options[:tick] || 0.1
    self.verbose = options[:verbose] || false
  end

  def start
    debug "Starting server"
    restart_server_on :HUP
    quit_server_on :QUIT, :INT, :TERM
    forward_to_server :USR1, :USR2, :WINCH, :TTIN, :TTOU
    start_server

    wait_for_server_to_quit
  end

  private

  def start_server
    abort "The unicorn pidfile '#{pidfile}' already exists.  Is the server running already?" if File.exist?(pidfile)
    spawned_pid = Process.spawn command
    wait_for_with_timeout { File.exist?(pidfile) }
  rescue Timeout::Error
    Process.kill "QUIT", spawned_pid
    abort "Unable to find server running with pidfile #{pidfile}.  Exiting"
  end

  def restart_server_on(*signals)
    trap_signals("restarting server", *signals) do
      restart_server
    end
  end

  def quit_server_on(*signals)
    trap_signals("quitting server", *signals) do |signal|
      Process.kill signal, pid
      wait_until_server_quits
      exit
    end
  end

  def forward_to_server(*signals)
    trap_signals("forwarding", *signals) do |signal|
      Process.kill signal, pid
    end
  end

  def wait_until_server_quits
    wait_for_with_timeout { !running? }
  end

  def wait_for_server_to_quit
    until !running?
      sleep 1
    end
  end

  def restart_server
    reexecute_running_binary
    wait_for_with_timeout { old_pid }
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
    if verbose
      puts message
    end
  end

  def wait_for(&block)
    until block.call
      sleep tick_period
    end
  end

  def wait_for_with_timeout(timeout = 20, &block)
    Timeout::timeout timeout do
      wait_for(&block)
    end
  end

  def trap_signals(message, *signals, &block)
    signals.map(&:to_s).each do |signal|
      trap(signal) do
        debug "Received #{signal}, #{message}"
        block.call signal
      end
    end
  end
end
