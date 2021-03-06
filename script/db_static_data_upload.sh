#!/usr/bin/env ruby

# This script will upload the db/static.sql file to the api-sandbox database
#
# call with ./db_static_data_upload.sh <username>
#
# needs an entry in the /etc/hosts file called sandbox

require 'net/ssh' # gem install net-ssh
require 'net/scp' # gem install net-scp

#ENVIRONMENTS = {
#  'api-sandbox' => 'api'
#}

def ssh_user
  @ssh_user ||= (ARGV[0] || (raise 'Please specify the ssh username as the first argument'))
end

#def ssh_env
#  @ssh_env ||= begin
#    ENVIRONMENTS.keys.include?(ARGV[1]) ||
#        (raise 'Please specify the env name (%s) as the second argument and optionally the IP as the third argument' % ENVIRONMENTS.keys.join(','))
#    ARGV[1]
#  end
#end

def ssh_address
  'sandbox'
end

def dump_file_name
  'db/static.sql'
end

#def argument_is_file?(arg)
#  arg.to_s.end_with?('.psql') || arg.to_s.end_with?('.gz')
#end

def install_postgres(ssh)
  ssh.exec! 'sudo docker exec advocatedefencepayments apt-get update'
  ssh.exec! 'sudo docker exec advocatedefencepayments apt-get -y install postgresql-9.6'
end

begin
  puts 'Uploading dump file %s to host %s' % [dump_file_name, ssh_address]
  Net::SCP.upload!(ssh_address, ssh_user, dump_file_name, "/home/#{ssh_user}/#{dump_file_name}.uploading") do |_channel, _name, sent, total|
    puts "...uploading... #{sent}/#{total}" if sent % 512_000 == 0
  end

  ssh = Net::SSH.start ssh_address, ssh_user
  puts ssh.exec!("mv /home/#{ssh_user}/#{dump_file_name}.uploading /home/#{ssh_user}/#{dump_file_name}")

  # Note: Docker 1.8 supports cp command to copy a file from the host to the container, but we are using a lower version
  puts 'Copying dump file into container...'
  puts ssh.exec!("cat #{dump_file_name} | sudo docker exec -i advocatedefencepayments sh -c 'cat > /usr/src/app/#{dump_file_name}'")
  puts ssh.exec!("rm -f /home/#{ssh_user}/#{dump_file_name}")

  puts 'Installing postgresql in container...'
  install_postgres ssh

  puts 'Running task db:restore (this will take several minutes)...'
  puts ssh.exec!("sudo docker exec advocatedefencepayments rake db:static:restore[#{dump_file_name}]")

  puts 'Dump %s was successfully restored' % dump_file_name
  ssh.close
rescue Exception => e
  puts 'Usage: ./db_upload username environment'
  puts e
end
