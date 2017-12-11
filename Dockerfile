FROM ubuntu:16.04
MAINTAINER Paul Ganzon <paul.ganzon@gmail.com>

LABEL "name"="Airflow"

ARG AIRFLOW_VERSION
ARG TINI_VERSION=v0.16.1
ARG SPARK_URL=http://mirror.intergrid.com.au/apache/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz
ARG SPARK_DIR=/opt/spark-2.2.0-bin-hadoop2.7
ARG TIME_ZONE=Australia/Sydney

ENV AIRFLOW_HOME=/opt/airflow \
  SPARK_HOME=/opt/spark \
  PYTHONPATH=/opt/spark/python:/opt/spark/python/lib/py4j-0.10.4-src.zip:${PYTHONPATH}

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
COPY conf/init /.

RUN apt-get update \
  && apt-get -y install \
      apt-transport-https \
      build-essential \
      curl \
      git \
      libblas-dev \
      libevent-dev \
      libffi-dev \
      libkrb5-dev \
      liblapack-dev \
      libsasl2-dev \
      libssl-dev \
      libpq-dev \
      python \
      python-pip \
      python-dev \
      software-properties-common \
      sudo \
      tzdata \
      vim \
  && echo "${TIME_ZONE}" > /etc/timezone \
  && dpkg-reconfigure -f noninteractive tzdata \
  && useradd -ms /bin/bash -G sudo airflow \
  && echo "airflow ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/airflow \
  && pip install --upgrade pip \
  && pip install \
         airflow[celery,hdfs,hive,jdbc,password,postgres]==${AIRFLOW_VERSION} \
         celery \
         psycopg2 \
         pyasn1 \
         pyOpenSSL \
         pytz \
  && chmod +x /tini \
  && curl -fsS -o /tmp/spark.tgz ${SPARK_URL} \
  && tar -xvf /tmp/spark.tgz  -C /opt \
  && ln -s ${SPARK_DIR} /opt/spark \
  && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

USER airflow

EXPOSE 8080 8793 5555

ENTRYPOINT ["/tini", "--", "/init"]
CMD ["airflow","master"]
