from ubuntu:22.04

run apt-get update && apt-get upgrade -y --no-install-recommends && apt-get install -y curl ca-certificates
run install -d /usr/share/postgresql-common/pgdg
run curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
run . /etc/os-release && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main" > /etc/apt/sources.list.d/pgdg.list
run apt-get update
run apt-get install -y postgresql-client-14
run apt-get install -y iproute2

# this requires prompts; if you want it, do it manually afterwards
#RUN apt-get install -y dnsutils

run mkdir /dump
workdir /dump