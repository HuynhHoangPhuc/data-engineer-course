FROM ubuntu:25.04

RUN apt-get update && \
    apt-get upgrade -y

RUN apt-get install openssh-server openssh-client -y

RUN mkdir -p /var/run/sshd

RUN echo "root:password" | chpasswd

RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

CMD ["/usr/sbin/sshd", "-D"]

