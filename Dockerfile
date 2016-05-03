# To build image :
# docker build -t image-sdk-builder .
# To launch Build :
# docker run -it -v [PATH to SDK]:/sdk image-sdk-builder

FROM ubuntu:15.10

ENV MODE release
ENV ARCH x64
ENV ACTION create_sdk

RUN apt-get update && \
    apt-get install -y \
      python \
      g++ \
      git \
      make

VOLUME /sdk
WORKDIR /sdk

ENTRYPOINT ["./docker_startup.sh"]
