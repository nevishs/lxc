

root@test-virtual-machine:~# cat API.rb 
require 'sinatra'

def random_int(min, max)
    rand(max - min) + min
end
 
def safeport()
    portcheck = true
    while portcheck == true
          port = random_int(10000, 60000)
          portcheck = system("iptables -L -vt nat | grep dpt | awk '{print $11}' | awk -F ':' '{print $2}' | grep #{port}")
    end
    return port
end

def getIP(deviceid)
    ip = `lxc-info -n #{deviceid} -iH`
    return ip
end

get '/enrol/:deviceid' do
deviceid = params['deviceid']
system( "lxc-create --template ubuntu --name #{params['deviceid']}" )
system( "lxc-start --name #{params['deviceid']} -d" )
sleep 30
Cip = getIP(deviceid).strip
Cport = safeport()
system( "iptables -t nat -A PREROUTING -p tcp -i eth0 --dport #{Cport} -j DNAT --to-destination #{Cip}:22") 
system ("/etc/init.d/iptables-persistent save")
system (` echo "# Autostart" >> /var/lib/lxc/#{params['deviceid']}/config `)
system (` echo "lxc.start.auto = 1" >> /var/lib/lxc/#{params['deviceid']}/config `)
system (` echo "lxc.start.delay = 5" >> /var/lib/lxc/#{params['deviceid']}/config `)
"Box " + params['deviceid'] + " created and started. IP: " + Cip.to_s + " Port: " + Cport.to_s 
end

get '/start/:deviceid' do
system( "lxc-start --name #{params['deviceid']}" )  
  "Box "+  params['deviceid'] + " started."
end

get '/stop/:deviceid' do
system( "lxc-stop --name #{params['deviceid']}" )
  "Box "+  params['deviceid'] + " stopped."
end

get '/destroy/:deviceid/:port' do
getRule = `iptables -L -vt nat --line-numbers | grep #{params['port']} | awk '{print $1}'`
Rule = getRule.strip
system("iptables -t nat -D PREROUTING #{Rule}")
system ("/etc/init.d/iptables-persistent save")
system( "lxc-stop --name #{params['deviceid']}" )
system( "lxc-destroy --name #{params['deviceid']}" )
  "Box " + params['deviceid'] + " destroyed. Iptables for " + params['port'] + " has been removed."
end

