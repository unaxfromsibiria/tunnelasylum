FROM    dorowu/ubuntu-desktop-lxde-vnc

ARG     TOR_PROXY_HOST
ARG     TOR_PROXY_PORT

RUN     wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN     apt-get update && apt-get install -y telnet openssh-server gpg netcat iputils-ping curl mc htop aptitude
RUN     wget 'https://download.opera.com/download/get/?id=59109&location=424&nothanks=yes&sub=marine&utm_tryagain=yes' -O opera.deb
RUN     mkdir -p /opt/proxyuser/.ssh && mkdir /var/run/sshd
RUN     useradd -m -d /opt/proxyuser -s /bin/false -c "ssh tunnel user" proxyuser
RUN     tr -dc A-Za-z0-9 < /dev/urandom | head -c32 | xargs echo "proxyuser:$1" | chpasswd
RUN     mkdir /opt/external && cd /opt/external && ssh-keygen -b 2048 -t rsa -f /opt/external/id_rsa && ls -lah /opt/external
RUN     cat /opt/external/id_rsa.pub >> /opt/proxyuser/.ssh/authorized_keys && chown proxyuser:proxyuser -R /opt/proxyuser
RUN     echo 'test $(echo -n|telnet 0.0.0.0 22|grep -i Connected|wc -l) == 1 || exit 1' > /opt/test-port.sh && chmod 777 /opt/test-port.sh

RUN     echo '[program:server-sshd]' > /etc/supervisor/conf.d/run-sshd.conf
RUN     echo 'user=root' >> /etc/supervisor/conf.d/run-sshd.conf
RUN     echo 'command=/usr/sbin/sshd -D' >> /etc/supervisor/conf.d/run-sshd.conf

RUN     echo aptitude remove google-chrome-stable && aptitude install -y google-chrome-stable
RUN     dpkg -i opera.deb && rm *.deb && apt-get clean
RUN     echo '#!/bin/bash' > /usr/bin/opera-torproxy && chmod 777 /usr/bin/opera-torproxy
RUN     echo "opera --no-sandbox --proxy-server='http://${TOR_PROXY_HOST}:${TOR_PROXY_PORT}'" >> /usr/bin/opera-torproxy
RUN     echo '#!/bin/bash' > /usr/bin/chrome && chmod 777 /usr/bin/chrome
RUN     echo '/opt/google/chrome/chrome --no-sandbox' >> /usr/bin/chrome
RUN     echo ">>>>>>> Copy this key to client part:" && cat /opt/external/id_rsa && rm /opt/external/* && echo "<<<<<<<<<"

EXPOSE 22
