FROM node:9.8.0-alpine
WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install
COPY public ./public
COPY server.js .
RUN mkdir pac
ADD entrypoint.sh ./entrypoint.sh
RUN ls -a && pwd
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
