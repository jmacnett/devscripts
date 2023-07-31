FROM alpine:3.18

RUN apk update
RUN apk upgrade
RUN apk add --update --no-cache postgresql14-client

COPY udhcpc.conf /etc/udhcpc/udhcpc.conf
