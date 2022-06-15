FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y python3 python3-pip
RUN pip3 install 'gdtoolkit==3.*'

WORKDIR /workdir
