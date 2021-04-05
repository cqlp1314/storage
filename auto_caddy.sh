#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# Usage:  debian 9/10 one_key naiveproxy： https://github.com/klzgrad/naiveproxy
# install: bash <(curl -s https://raw.githubusercontent.com/mixool/across/master/naiveproxy/naiveproxy.sh) my.domain.com
# uninstall: apt purge caddy -y

# tempfile & rm it when exit
trap 'rm -f "$TMPFILE"' EXIT
TMPFILE=$(mktemp) || exit 1

########
[[ $# == 1 ]] && domain="$1" || { echo Err !!! Useage: bash this_script.sh my.domain.com; exit 1; }
########

# dpkg install caddy
caddyURL="$(wget -qO-  https://api.github.com/repos/caddyserver/caddy/releases | grep -E "browser_download_url.*linux_amd64\.deb" | cut -f4 -d\" | head -n1)"
wget -O $TMPFILE $caddyURL && dpkg -i $TMPFILE

# xcaddy build caddy with layer4 cloudflare-dns forwardproxy weekly automatic updates: https://github.com/mixool/caddys
naivecaddyURL="https://github.com/mixool/caddys/raw/master/caddy"
rm -rf /usr/bin/caddy
wget --no-check-certificate -O /usr/bin/caddy $naivecaddyURL && chmod +x /usr/bin/caddy

# secrets
username="$(tr -dc 'a-z0-9A-Z' </dev/urandom | head -c 16)"
password="$(tr -dc 'a-z0-9A-Z' </dev/urandom | head -c 16)"
probe_resistance="$(tr -dc 'a-z0-9' </dev/urandom | head -c 32).com"

# config caddy json
cat <<EOF >/etc/caddy/Caddyfile
http://$domain:80 {
  redir https://$domain{uri}
}
http://$domain:8080 {
  bind 127.0.0.1
  route {
    forward_proxy {
      basic_auth user $2
      hide_ip
      hide_via
      probe_resistance unsplash.com:443
      upstream http://127.0.0.1:8081
    }
    file_server { root /var/www/html }
  }
}
EOF

# systemctl service info
echo; echo $(date) caddy status:
systemctl daemon-reload && systemctl enable caddy && systemctl restart caddy && sleep 1 && systemctl status caddy | more | grep -A 2 "caddy.service"

# info
echo; echo $(date); echo username: $username; echo password: $password; echo probe_resistance: $probe_resistance; echo proxy: https://$username:$password@$domain
