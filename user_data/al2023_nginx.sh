#!/bin/bash
set -euxo pipefail
dnf -y update
dnf -y install nginx
echo "OK - video Expolicativo" > /usr/share/nginx/html/index.html
systemctl enable nginx
systemctl restart nginx