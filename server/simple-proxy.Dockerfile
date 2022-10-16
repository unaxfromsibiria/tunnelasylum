FROM    debian:buster-slim

RUN     apt-get update && apt-get install -y squid telnet openssh-server curl && apt-get clean
RUN     useradd -m -s /bin/false -c "ssh tunnel user" proxyuser
RUN     tr -dc A-Za-z0-9 < /dev/urandom | head -c32 | xargs echo "proxyuser:$1" | chpasswd
RUN     mkdir /home/proxyuser/.ssh && mkdir /var/run/sshd
RUN     mkdir /opt/external && cd /opt/external && ssh-keygen -b 2048 -t rsa -f /opt/external/id_rsa && ls -lah /opt/external
RUN     cat /opt/external/id_rsa.pub >> /home/proxyuser/.ssh/authorized_keys && chown proxyuser:proxyuser -R /home/proxyuser
RUN     echo 'test $(echo -n|telnet 0.0.0.0 22|grep -i Connected|wc -l) == 1 || exit 1' > /opt/test-port.sh && chmod 777 /opt/test-port.sh
RUN     cat /etc/squid/squid.conf | grep -v '^#' > /etc/squid/main.squid.conf
RUN     echo 'access_log none' >> /etc/squid/main.squid.conf
RUN     echo 'cache_log /dev/null' >> /etc/squid/main.squid.conf
RUN     echo 'logfile_rotate 0' >> /etc/squid/main.squid.conf
RUN     echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
RUN     echo '#!/bin/bash' > /bin/tunproxy_run.sh
RUN     echo 'squid -f /etc/squid/main.squid.conf && /usr/sbin/sshd -D' >> /bin/tunproxy_run.sh
RUN     chmod 700 /bin/tunproxy_run.sh
RUN     echo ">>>>>>> Copy this key to client part:" && cat /opt/external/id_rsa && rm /opt/external/* && echo "<<<<<<<<<"

EXPOSE 22

ENTRYPOINT /bin/tunproxy_run.sh
