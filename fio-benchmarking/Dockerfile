FROM ubuntu:24.04
RUN useradd -ms /bin/bash clc

USER root
# Install Sysbench/FIO/SpeedTest
RUN apt update
RUN apt -y install curl
RUN curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | bash
RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
RUN apt -y install speedtest
RUN apt -y install sysbench
RUN apt -y install fio

USER clc
COPY scripts/run.sh /home/clc
USER root
RUN mkdir /output
RUN mkdir /home/clc/fiotest
RUN chmod a+rw /output
RUN chmod +x /home/clc/run.sh
USER root
VOLUME /output
WORKDIR /home/clc
ENTRYPOINT ["./run.sh"]
