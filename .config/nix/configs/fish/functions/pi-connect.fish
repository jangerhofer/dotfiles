# Pi SSH tunnel and connection management
# Usage:
#   pi-connect hostname [port]    - Start tunnel + shell (default port: 8001)
#   pi-disconnect hostname [port] - Kill tunnel only

function pi-connect
    set -l host $argv[1]
    set -l port $argv[2]
    if test -z "$port"
        set port 8001
    end
    
    # Kill any existing tunnel on this port
    set -l existing_pid (ps aux | grep "ssh.*-L $port:localhost:$port.*$host" | grep -v grep | awk '{print $2}')
    if test -n "$existing_pid"
        echo "Killing existing tunnel (PID: $existing_pid)..."
        kill $existing_pid
        sleep 1
    end
    
    echo "Starting tunnel on port $port..."
    ssh -N -f -L $port:localhost:$port pi@$host -o PreferredAuthentications=password -o PubkeyAuthentication=no 2>/dev/null
    
    if test $status -eq 0
        echo "Tunnel established! Now connecting to shell..."
        ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no pi@$host
    else
        echo "Failed to establish tunnel"
        return 1
    end
end

function pi-disconnect
    set -l host $argv[1]
    set -l port $argv[2]
    if test -z "$port"
        set port 8001
    end
    
    set -l existing_pid (ps aux | grep "ssh.*-L $port:localhost:$port.*$host" | grep -v grep | awk '{print $2}')
    if test -n "$existing_pid"
        echo "Killing tunnel to $host:$port (PID: $existing_pid)..."
        kill $existing_pid
    else
        echo "No tunnel found for $host:$port"
    end
end