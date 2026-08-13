FROM node:18-alpine
WORKDIR /app
RUN npm init -y && npm install express cors
COPY server.js .
EXPOSE 3000
CMD ["node", "server.js"]
