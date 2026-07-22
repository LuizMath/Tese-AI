# Site estático (landing + login) servido por nginx.
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
# Todas as paginas do site — novas paginas entram sem editar este arquivo.
COPY *.html /usr/share/nginx/html/

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -q --spider http://127.0.0.1:8080/health || exit 1
