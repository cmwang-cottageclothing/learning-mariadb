FROM ubuntu
RUN apt-get update
RUN apt-get install -y mariadb-client
RUN rm -rf /var/lib/apt
ENTRYPOINT [ "/bin/sh" ]