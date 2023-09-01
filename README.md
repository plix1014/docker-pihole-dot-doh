# docker-pihole-dot-doh
Pi-hole with stubby and dnscrypt-proxy dockerized

Configuration is based on the c't article 21'04, page 134-139 "Doppelt verschlüsselt. Raspi mit DNS-Filter für Fritzbox & Co."

* [Heise c't 21'04](https://www.heise.de/select/ct/2021/4/2030412421734924519)


The configuration (.env, docker-compose.yml, 99-my-config.conf, ...) is generated by some ansible tasks. This is just a copy of the deployed files.


Docker images used:

* [Pi-hole docker](https://github.com/pi-hole/docker-pi-hole) - AD-Blocker
* [DNSCrypt-proxy docker](https://github.com/klutchell/dnscrypt-proxy-docker) - DoH Resolver
* [Stubby docker](https://github.com/MatthewVance/stubby-docker) - DoT Resolver


## configuration

### .env

Env file used by "docker compose" command.

you need to set at least the *PIHOLE_WEB_PASSWORD* variable.

Set all other parameters according to your needs


### .pihole-env

Env file used by optional pihole.sh script.

you need to set at least the *PIHOLE_WEB_PASSWORD* variable.

Set all other parameters according to your needs


### pihole.sh

pls. set the variable *PIHOLE_BASE* in the script to your installation path 

If you don't want to use .pihole-env you have to delete the source command from the script and set the *SERVER_NAME* variable in the script.


### 99-my-config.conf

in 99-my-config.conf edit the listen-address.

Replace the IP with yours


### stubby - DoT

The subdirectory *stubby* contains the modified Dockerfile from [Matthew Vance](https://github.com/TrojaForks/stubby-docker/tree/master/stubby) to build an arm64 docker image.

### config dir

original config
* config/dnscrypt-proxy-klutchell.toml
* config/stubby-clouldflare.yml

heise - ct suggestion
* config/dnscrypt-proxy.toml
* config/stubby-quad9.yml


## docker compose start/stop

Bevor the first startup, the directory "<install dir>/etc-pihole" has to be created.

start containers

```
$ cd <install dir>
$ docker compose up -d
```

stop containers
```
$ cd <install dir>
$ docker compose stop
```

## pihole.sh start/stop script


```
$ pihole.sh
Usage: /etc/init.d/pihole {start|stop|restart|status|backup}
```

starting the containers
```
$ pihole.sh start
Starting stubby         ... done
Starting dnscrypt-proxy ... done
Starting pihole         ... done
Waiting for pihole container to start up .......... OK
```

stopping the containers
```
$ pihole.sh stop
Waiting for pihole container to shutdown
Stopping pihole         ... done
Stopping stubby         ... done
Stopping dnscrypt-proxy ... done
```

backup pi-hole config
```
$ pihole.sh backup
Saving pihole config
  creating backup OK.
  copy backup /tmp/pi-hole-raspberrypi-docker-teleporter_2023-08-15_14-37-17.tar.gz to /opt/docker/pihole/backup OK.
```



### check DoT resolver

```
$ dig @172.18.0.1 -p 10053 ct.de

; <<>> DiG 9.18.16-1~deb12u1-Debian <<>> @172.18.0.1 -p 10053 ct.de
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 16387
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags: do; udp: 1232
; COOKIE: d72d64f171503ee70100000064db723c1929c0f318a940cf (good)
;; QUESTION SECTION:
;ct.de.				IN	A

;; ANSWER SECTION:
ct.de.			28698	IN	A	193.99.144.80

;; Query time: 1819 msec
;; SERVER: 172.18.0.1#10053(172.18.0.1) (UDP)
;; WHEN: Tue Aug 15 14:40:31 CEST 2023
;; MSG SIZE  rcvd: 78

```

### check DoH resolver

```
$ dig @172.18.0.1 -p 20053 ct.de

; <<>> DiG 9.18.16-1~deb12u1-Debian <<>> @172.18.0.1 -p 20053 ct.de
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 26056
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;ct.de.				IN	A

;; ANSWER SECTION:
ct.de.			43097	IN	A	193.99.144.80

;; Query time: 0 msec
;; SERVER: 172.18.0.1#20053(172.18.0.1) (UDP)
;; WHEN: Tue Aug 15 14:41:16 CEST 2023
;; MSG SIZE  rcvd: 50
```


## Author

* **plix1014** - [plix1014](https://github.com/plix1014)


## License

This project is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License - see the [LICENSE.md](LICENSE.md) file for details

