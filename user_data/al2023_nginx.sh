#!/bin/bash
set -euxo pipefail
dnf -y update
dnf -y install nginx
echo "OK - devops-it" > /usr/share/nginx/html/index.html
systemctl enable nginx
systemctl restart nginx