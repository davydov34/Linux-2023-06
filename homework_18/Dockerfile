FROM alpine:3.18
LABEL maintainer="OTUS HomeWork | Davydov K."

RUN apk update 
RUN apk add nginx
RUN apk add curl 

COPY ./html/ /usr/share/nginx/html/
COPY ./nginx.conf /etc/nginx/

ENTRYPOINT ["nginx", "-g", "daemon off;"]

EXPOSE 80
    

