from ubuntu:focal

RUN apt-get update && apt-get upgrade -y --no-install-recommends && apt-get install -y curl
RUN echo "deb http://apt.postgresql.org/pub/repos/apt focal-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN curl -o /etc/apt/trusted.gpg.d/pgdg.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc 
RUN apt-get update
RUN apt-get install -y postgresql-client-15
RUN apt-get install -y iproute2

# this requires prompts; if you want it, do it manually afterwards
#RUN apt-get install -y dnsutils

RUN mkdir /dump
WORKDIR /dump