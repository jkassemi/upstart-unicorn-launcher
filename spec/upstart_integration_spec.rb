require 'spec_helper'
require 'curl'

describe 'Upstart integration' do
  after :each do
    kill_launcher
  end

  it 'starts server' do
    start_launcher
    expect {perform_request}.to_not raise_error
  end

  it 'stops server when sent QUIT' do
    start_launcher
    send_to_launcher 'QUIT'
    sleep 1
    expect {perform_request}.to raise_error
  end

  it 'stops server when sent INT' do
    start_launcher
    send_to_launcher 'INT'
    sleep 1
    expect {perform_request}.to raise_error
  end

  it 'stops server when sent TERM' do
    start_launcher
    send_to_launcher 'INT'
    sleep 1
    expect {perform_request}.to raise_error
  end

  it 'restarts server when sent HUP' do
    start_launcher
    original_response = perform_request.body_str
    send_to_launcher 'HUP'
    sleep 1
    expect(perform_request.body_str).to_not eql(original_response)
  end

  it 'continues to serve requests during restart' do
    start_launcher
    start = Time.now
    send_to_launcher 'HUP'
    responses = []
    while Time.now < (start + 2)
      expect {responses << perform_request.body_str}.to_not raise_error
    end
    expect(responses.uniq.size).to eql(2)
  end
end
