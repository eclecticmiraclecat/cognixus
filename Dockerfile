FROM node:18-alpine
 
WORKDIR /app
 
COPY . .

RUN npm install ip

EXPOSE 5000
 
CMD [ "node", "app.js" ]
