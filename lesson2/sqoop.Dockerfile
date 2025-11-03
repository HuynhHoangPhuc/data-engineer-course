FROM alpine:latest

ARG BUILDARCH

RUN apk update --no-cache && apk add --no-cache bash

RUN apk add --no-cache openjdk8-jdk

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk
ENV PATH=$PATH:$JAVA_HOME/bin

ENV HADOOP_VERSION=2.10.2
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_INSTALL=$HADOOP_HOME
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV YARN_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
ENV SQOOP_HOME=/usr/local/sqoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SQOOP_HOME/bin

RUN apk add --no-cache wget tar
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz && \
    wget https://archive.apache.org/dist/sqoop/1.4.7/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz && \
    wget https://cdn.mysql.com//Downloads/Connector-J/mysql-connector-j-9.5.0.tar.gz && \
    apk del wget  && \
    tar -zxf hadoop-$HADOOP_VERSION.tar.gz && \
    tar -zxf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz && \
    tar -zxf mysql-connector-j-9.5.0.tar.gz && \
    apk del tar && \
    rm hadoop-$HADOOP_VERSION.tar.gz && \
    rm sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz && \
    rm mysql-connector-j-9.5.0.tar.gz && \
    mv hadoop-$HADOOP_VERSION $HADOOP_HOME && \
    mv sqoop-1.4.7.bin__hadoop-2.6.0 $SQOOP_HOME && \
    mv mysql-connector-j-9.5.0/mysql-connector-j-9.5.0.jar $SQOOP_HOME/lib/mysql-connector-j-9.5.0.jar && \
    mkdir -p $HADOOP_HOME/logs

COPY conf $HADOOP_HOME/etc/hadoop/
# RUN mkdir -p /data/hdfs/data /data/hdfs/name /data/hdfs/namesecondary
# RUN hdfs namenode -format
# VOLUME [ "/data" ]

# EXPOSE 9000 9870 9866 9867 9864 9868 8088

# CMD ["hdfs"]

CMD ["bash"]