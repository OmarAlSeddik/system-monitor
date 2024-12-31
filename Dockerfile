FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bash \
    zenity \
    procps \
    lm-sensors \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    nvidia-utils-525 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/bin

COPY system-monitor.sh /usr/local/bin/system-monitor.sh

RUN chmod +x /usr/local/bin/system-monitor.sh

CMD ["bash", "/usr/local/bin/system-monitor.sh"]
