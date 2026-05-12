FROM nginx:1.27-alpine

COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf
COPY frontend/source /usr/share/nginx/html
COPY backend/data /usr/share/nginx/backend-data-seed
