server {
    listen 80;
    server_name serp.sdad.pro;

    location / {
        proxy_pass http://localhost:7777;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Once you have SSL certificate, uncomment this section
# server {
#     listen 443 ssl;
#     server_name serp.sdad.pro;
#
#     ssl_certificate /etc/letsencrypt/live/serp.sdad.pro/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/serp.sdad.pro/privkey.pem;
#     include /etc/letsencrypt/options-ssl-nginx.conf;
#     ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
#
#     location / {
#         proxy_pass http://localhost:7777;
#         proxy_set_header Host $host;
#         proxy_set_header X-Real-IP $remote_addr;
#         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto $scheme;
#     }
# }