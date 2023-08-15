#!/bin/bash
#
### BEGIN INIT INFO
# Provides:          sudo
# Required-Start:    $local_fs $remote_fs
# Required-Stop:
# X-Start-Before:    
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: start stop pihole container
# Description: https://github.com/pi-hole/docker-pi-hole/blob/master/README.md
### END INIT INFO

NAME=pihole
N="/etc/init.d/$NAME"

. /lib/lsb/init-functions

# set installation directory
PIHOLE_BASE=/opt/docker/pihole

PIHOLE_ENV=$PIHOLE_BASE/.pihole-env

BK_DIR=$PIHOLE_BASE/backup

CONTAINERS="pihole stubby dnscrypt"

#---------------------------------------------------------------
cd $PIHOLE_BASE
if [ $? -ne 0 ]; then
    echo "ERROR: PIHOLE_BASE '$PIHOLE_BASE' does not exist. Aborting...."
    exit 1
fi

if [ ! -r $PIHOLE_ENV ]; then
    echo "ERROR: PIHOLE_ENV '$PIHOLE_ENV' does not exist. Aborting...."
    exit 2
else
    . $PIHOLE_ENV
fi


pihole_start() {

    # starting pihole with stubby and dnscrypt-proxy
    docker-compose up -d

    printf 'Waiting for pihole container to start up '
    for i in $(seq 1 20); do
	if [ "$(docker inspect -f "{{.State.Health.Status}}" pihole)" == "healthy" ] ; then
	    echo ' OK'
	    WEBPW=$(docker logs pihole 2> /dev/null | grep 'password:')

	    if [ -n "$WEBPW" ]; then
		echo -e "\n$WEBPW for your pi-hole: http://${SERVER_IP}/admin/"
	    fi

	    exit 0
	else
	    sleep 3
	    printf '.'
	fi

	if [ $i -eq 20 ] ; then
	    echo -e "\nTimed out waiting for Pi-hole start, consult your container logs for more info (\`docker logs pihole\`)"
	    exit 1
	fi
    done;
}


pihole_stop() {
    # stopping pihole with stubby and dnscrypt-proxy
    echo 'Waiting for pihole container to shutdown '
    docker-compose stop
}

pihole_status() {
    for n in $CONTAINERS; do
	docker ps -a --format '{{.Image}}|{{.Status}}|{{.Ports}}' -f name=$n | awk -F"|" '{printf("%-40s %-30s %s\n",$1,$2,$3)}'
    done
}



pihole_backup() {

    if [ "$(docker inspect -f "{{.State.Health.Status}}" pihole)" == "healthy" ] ; then
	echo "Saving pihole config"
	DATE=$(date +'%Y-%m-%d_%H')

	printf "  creating backup "
	docker exec -it pihole bash -c "cd /tmp && pihole -a -t"
	if [ $? -eq 0 ]; then
	    echo "OK."
	else
	    echo "ERROR: failed to backup pihole config"
	    exit 4
	fi

	# get backup filename
	BK_NAME=$(docker exec -it pihole bash -c "ls -t /tmp/pi-hole-${SERVER_NAME}-teleporter_${DATE}-*.gz | head -1" | perl -pe 's/\r//')

	printf "  copy backup $BK_NAME to $BK_DIR "
	docker cp pihole:$BK_NAME $BK_DIR

	if [ $? -eq 0 ]; then
	    echo "OK."
	else
	    echo "ERROR: failed to copy $BK_NAME to host"
	fi
    else
	echo "ERROR: pihole is down. Please start pihole"
	exit 3
    fi

}


#---------------------------------------------------------------
set -e

case "$1" in
  start)
	pihole_start
	;;
  stop)
	pihole_stop
	;;
  status)
	pihole_status
	;;
  restart)
	pihole_stop
	sleep 5
	pihole_start
	;;
  backup)
	pihole_backup
	;;
  *)
	echo "Usage: $N {start|stop|restart|status|backup}" >&2
	exit 1
	;;
esac

exit 0
