FROM nginx:1.27-alpine
LABEL org.opencontainers.image.source=https://github.com/arvid-persson1/m7011e-project
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
