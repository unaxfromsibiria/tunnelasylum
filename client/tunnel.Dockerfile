FROM debian:bullseye-slim

RUN     apt-get update && apt-get install -y ssh curl net-tools netcat iputils-ping && apt-get clean
ARG     KEY
ARG     HOST
ARG     PORT
ARG     DIST_PORT
ADD     .keys /opt/keys
RUN     tr -dc A-Za-z0-9 < /dev/urandom | head -c32 | xargs echo "root:$1" | chpasswd
RUN     mkdir /root/.ssh/ && cat "/opt/keys/${KEY}" > /root/.ssh/id_rsa && chmod 700 /root/.ssh/id_rsa
RUN     echo '#!/bin/bash' > /opt/run_tunnel.sh && chmod 777 /opt/run_tunnel.sh
RUN     echo "ssh -p ${PORT} -N -L 0.0.0.0:8000:127.0.0.1:${DIST_PORT} proxyuser@${HOST} -N" >> /opt/run_tunnel.sh
RUN     echo 'Host *' > /root/.ssh/config && echo ' StrictHostKeyChecking no' >> /root/.ssh/config
RUN     echo 'test $(curl \' > /opt/proxy_check.sh && echo "-x http://127.0.0.1:8000 https://api.myip.com/|grep ${HOST}|wc -l) == '1'||exit 1" >> /opt/proxy_check.sh && chmod 777 /opt/proxy_check.sh

EXPOSE 8000

CMD ["bash", "-c", "/opt/run_tunnel.sh"]
