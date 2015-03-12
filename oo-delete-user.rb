#!/usr/bin/env oo-ruby
#American Express Specific delete user(Not for other Openshift engagements)
require 'rubygems'
require 'json'
require "#{ENV['OPENSHIFT_BROKER_DIR'] || '/var/www/openshift/broker'}/config/environment"
brokerhost="localhost"
logfile="/var/log/openshift/broker/ose-utils.log"
def usage()
  puts "Usage: oo-delete-user {username} {token}"
end

def json(code,message)
  puts "{
    \"returnCode\" : \"#{code}\",
    \"returnDesc\" : \"#{message}\"
}"
end
def error_code(json)
  result= JSON.parse(json)
  code =result["messages"][0]["exit_code"]
  return code
end

if ARGV.size < 1
  puts "Invalid usage"
  usage()
end

username=ARGV[0]
token=ARGV[1]

begin
  user_obj=CloudUser::find_by_identity(username)
  response=`curl -k -H "Authorization: Bearer #{token}" -X DELETE https://#{brokerhost}/broker/rest/domain/#{username} --data-urlencode force=true  2>> #{logfile} | tee -a #{logfile}`
rescue Exception =>e
  puts "Delete Failed with #{e}"
  exit 255
end
code = error_code(response)

if code != 127 && code != 0
    puts "Delete Failed! Openshift Exit code #{code}")
    exit code
else
 user_obj.force_delete
end

puts "Success!")
exit 0
