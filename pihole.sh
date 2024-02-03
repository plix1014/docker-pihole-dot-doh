#!/usr/bin/sh
#
### BEGIN INIT INFO
# Provides:          pihole
# Required-Start:    $local_fs $remote_fs
# Required-Stop:
# X-Start-Before:    
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: start stop pihole container
# Description: https://github.com/pi-hole/docker-pi-hole/blob/master/README.md
### END INIT INFO

#NAME=pihole
#N="/etc/init.d/$NAME"

#. /lib/lsb/init-functions

# set installation directory
PIHOLE_BASE=/opt/docker/pihole

PIHOLE_ENV="$PIHOLE_BASE/.env"

BK_DIR=$PIHOLE_BASE/backup

CONTAINERS="pihole stubby dnscrypt"


# number of days to keep the backups
KEEP=30

#---------------------------------------------------------------
cd $PIHOLE_BASE 2>/dev/null
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
    el=0

    # starting pihole with stubby and dnscrypt-proxy
    docker compose up -d

    if [ "$1" = "wait" ]; then
	printf 'Waiting for pihole container to start up '
	for i in $(seq 1 20); do
	    if [ "$(docker inspect -f "{{.State.Health.Status}}" pihole)" == "healthy" ] ; then
		echo ' OK'
		WEBPW=$(docker logs pihole 2> /dev/null | grep 'New password')

		echo "WEBPW = '$WEBPW'"
		if [ -n "$WEBPW" ]; then
		    echo -e "\n$WEBPW for your pi-hole: http://${SERVER_IP}/admin/"
		else
		    docker logs pihole 2> /dev/null | grep 'Pi-hole version is' |tail -1
		    echo "pihole done"
		fi

		return $el
	    else
		sleep 3
		printf '.'
	    fi

	    if [ $i -eq 20 ] ; then
		echo -e "\nTimed out waiting for Pi-hole start, consult your container logs for more info (\`docker logs pihole\`)"
		exit 1
	    fi
	done;
    fi
    return $el
}


pihole_stop() {
    # stopping pihole with stubby and dnscrypt-proxy
    echo 'Waiting for pihole container to shutdown '
    docker compose stop

    return 0
}

pihole_status() {
    for n in $CONTAINERS; do
	docker ps -a --format '{{.Image}}|{{.Status}}|{{.Ports}}' -f name=$n | awk -F"|" '{printf("%-40s %-30s %s\n",$1,$2,$3)}'
    done
    
    return 0
}



pihole_backup() {

    if [ "$(docker inspect -f "{{.State.Health.Status}}" pihole)" = "healthy" ] ; then
	echo "Saving pihole config"
	DATE=$(date +'%Y-%m-%d_%H')

	printf "  creating backup "
	docker exec -i pihole bash -c "cd /tmp && pihole -a -t"
	if [ $? -eq 0 ]; then
	    echo "OK."
	else
	    echo "ERROR: failed to backup pihole config"
	    exit 4
	fi

	# get backup filename
	BK_NAME=$(docker exec -i pihole bash -c "ls -t /tmp/pi-hole-${SERVER_NAME}-teleporter_${DATE}-*.gz | head -1" | perl -pe 's/\r//')

	printf "  copy backup $BK_NAME to $BK_DIR "
	docker cp pihole:$BK_NAME $BK_DIR

	if [ $? -eq 0 ]; then
	    echo "OK."
	else
	    echo "ERROR: failed to copy $BK_NAME to host"
	fi

	echo "cleanup old backups"
	find $BK_DIR/ -type f -name "pi-hole-${SERVER_NAME}-teleporter_* -mtime +${KEEP}" -exec rm {} \;
    else
	echo "ERROR: pihole is down. Please start pihole"
	exit 3
    fi

}


pihole_enter() {
    docker exec -it pihole bash
}

#---------------------------------------------------------------

echo "DEBUG: `date +'%Y-%m-%d %H:%M:%S'` issued pihole '$1' command" >> $PIHOLE_BASE/log/pihole.restart.log 2>&1

case "$1" in
  start)
	pihole_start
	;;
  start_wait)
	pihole_start wait
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
  enter)
	pihole_enter
	;;
  *)
	echo "Usage: ${0##*/} {start|stop|restart|start_wait|status|backup|enter}" >&2
	exit 1
	;;
esac

exit 0

