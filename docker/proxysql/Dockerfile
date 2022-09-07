FROM proxysql/proxysql:latest

RUN apt-get update
RUN apt-get install vim --yes

COPY ./root_home/.bashrc /root/.bashrc
COPY ./root_home/.vimrc /root/.vimrc

COPY ./conf/proxysql.cnf /etc/proxysql.cnf
RUN chmod -R 644 /etc/proxysql.cnf

CMD ["proxysql", "-f", "-D", "/var/lib/proxysql", "-c", "/etc/proxysql.cnf"]

EXPOSE 6033
EXPOSE 6070
