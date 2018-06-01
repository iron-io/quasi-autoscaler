# WARNING: this approach is tending to waste your money!
require_relative 'bundle/bundler/setup'
require 'rest-client'
require 'uber_config'

APIURL='https://worker-aws-us-east-1.iron.io'

payload = UberConfig.load file: ENV['PAYLOAD_FILE'] rescue {}
num_runners_to_spinup = ENV['runners_to_spin'] || 1000 rescue 1000 #1000 runners to spin up simultaneously
shutdown_delay = ENV['shutdown_delay'] || 1200 rescue 1200 #seconds
@token = ENV['token']

HEADERS = {'Authorization': "OAuth #{@token}"}
POSTHEADERS = HEADERS.merge('Content-Type': 'application/json')

CLUSTERS = payload['clusters']

RestClient.log = 'stdout'

def resize_cluster(cluster, min_size)
  data = '{"autoscale": {"runners_min":' + min_size.to_s + '}}'
  result = RestClient.put("#{APIURL}/2/clusters/#{cluster}", data, POSTHEADERS)
end

def is_queued_task_in_cluster(cluster)
  begin
    result = RestClient.get("#{APIURL}/2/clusters/#{cluster}/tasks?queued=1&per_page=2", HEADERS)
    tasks = JSON.parse(result)['tasks']
    @last_task_queue_time = tasks[0]['created_at'] rescue nil
    tasks.length > 0
  rescue Exception => e
    STDERR.puts "Error: #{e.inspect}"
  end
end

def get_cluster_autoscale_params(cluster)
  begin
    result = RestClient.get("#{APIURL}/2/clusters/#{cluster}", HEADERS)
    JSON.parse(result)['cluster']['autoscale']
  rescue Exception => e
    STDERR.puts "Error: #{e.inspect}"
  end
end

CLUSTERS.each do |cluster|
  autoscale_params = get_cluster_autoscale_params(cluster)
  if is_queued_task_in_cluster(cluster)
    if autoscale_params != nil && autoscale_params['runners_min'] != num_runners_to_spinup
      resize_cluster(cluster, num_runners_to_spinup)
    end
  else
    if autoscale_params != nil && autoscale_params['runners_min'] != 0
      if @last_task_queue_time != nil && (DateTime.now.to_time - DateTime.parse(@last_task_queue_time).to_time > shutdown_delay)
        resize_cluster(cluster, 0)
      else
        puts "Last task was queued less than 20 minutes ago. Waiting..."
      end
    end
  end
end
