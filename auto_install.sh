#!/usr/bin/env bash
#install xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
mkdir -p /usr/local/etc/trojan-go/
mkdir -p /root/mine/renew/domain_certificate
mkdir -p /root/mine/telegram
read -p "请输入域名:" domain
read -p "该服务器名称(Euserv2):" server_name
uuid_xtls="$(cat '/proc/sys/kernel/random/uuid')"
uuid_ws="$(cat '/proc/sys/kernel/random/uuid')"
trojan_passwd="$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c $((10+$RANDOM%10)))"
path_vless="/$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c $((10+$RANDOM%10)))"
path_trojan="/$(cat '/proc/sys/kernel/random/uuid' | sed -e 's/-//g' | tr '[:upper:]' '[:lower:]' | head -c $((10+$RANDOM%10)))"
#xray config
cat > /usr/local/etc/xray/config.json <<-EOF
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid_xtls",
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "love@example.com"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": "3567"
                    },
                    {   
                        "path": "$path_trojan",
                        "dest": "3567"
                    },
                    {
                        "path": "$path_vless",
                        "dest": 1234,
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
                    "minVersion": "1.2",
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "/usr/local/etc/xray/ssl/fullchain.pem",
                            "keyFile": "/usr/local/etc/xray/ssl/privkey.pem"
                        }
                    ]
                }
            }
        },
        {
            "port": 1234,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid_ws",
                        "level": 0,
                        "email": "love@example.com"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true,
                    "path": "$path_vless" 
                }
            }
        }
    ],
    "outbounds": 
    [
        {"protocol": "freedom","tag": "direct","settings": {}},
        {"protocol": "freedom","tag": "directv6","settings": {"domainStrategy": "UseIPv6"}},
        {"protocol": "blackhole","tag": "blocked","settings": {}},
        {"protocol": "freedom","tag": "twotag","streamSettings": {"network": "domainsocket","dsSettings": {"path": "/usr/local/etc/xray/ss","abstract": true}}}
    ],

    "routing": 
    {
        "rules": 
        [
            {"type": "field","outboundTag": "directv6","domain": ["geosite:netflix","geosite:google","geosite:youtube"]},
            {"type": "field","inboundTag": ["onetag"],"outboundTag": "twotag"},
            {"type": "field","outboundTag": "blocked","ip": ["geoip:private"]},
            {"type": "field","outboundTag": "blocked","domain": ["geosite:private","geosite:category-ads-all"]}
        ]
    }
}
EOF
#ssl certificate
apt install snapd
snap install core; snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
certbot certonly --standalone --email cqlp2020@gmail.com -d $domain
read -p "please push enter to continue:" hi
cp /etc/letsencrypt/live/$domain/* /usr/local/etc/xray/ssl/
systemctl restart xray
#download website template
wget https://github.com/cqlp1314/storage/raw/main/html.tar.gz
tar -xzvf html.tar.gz 
mkdir -p /var/www/html
mv var/www/html/* /var/www/html/*
rm -r var/
#install and configure caddy
wget https://github.com/cqlp1314/storage/raw/main/auto_caddy.sh
./auto_caddy.sh $domain $trojan_passwd
#download trojan-go
wget -O /usr/local/etc/trojan-go/trojan-go-linux-adm64.zip https://github.com/p4gefau1t/trojan-go/releases/download/v0.8.2/trojan-go-linux-amd64.zip
unzip /usr/local/etc/trojan-go/trojan-go-linux-adm64.zip trojan-go -d /usr/local/etc/trojan-go/
rm /usr/local/etc/trojan-go/trojan-go-linux-adm64.zip
#configure trojan-go
cat > /etc/systemd/system/trojan-go.service <<-EOF
[Unit]
Description=Trojan-Go - An unidentifiable mechanism that helps you bypass GFW
Documentation=https://p4gefau1t.github.io/trojan-go/
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/etc/trojan-go/trojan-go -config /usr/local/etc/trojan-go/server.json
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
cat > /usr/local/etc/trojan-go/server.json <<-EOF
{
  "run_type": "server",
  "local_addr": "127.0.0.1",
  "local_port": 3567,
  "remote_addr": "127.0.0.1",
  "remote_port": 8080,
  "log_level": 3,
  "password": [
    "$trojan_passwd"
  ],
  "transport_plugin": {
    "enabled": true,
    "type": "plaintext"
  },
  "websocket": {
    "enabled": true,
    "path": "$path_trojan",
    "host": "$domain"
  },
  "router": {
    "enabled": false
  }
}
EOF
systemctl daemon-reload
systemctl enable trojan-go
systemctl start trojan-go
#crontab renew certificate twice every month and send message to telegram
wget -O /root/mine/renew/domain_certificate/renew.sh https://raw.githubusercontent.com/cqlp1314/storage/main/renew.sh
wget -O /root/mine/telegram/send_message.sh https://raw.githubusercontent.com/cqlp1314/storage/main/send_message.sh
chmod +x /root/mine/telegram/send_message.sh /root/mine/renew/domain_certificate/renew.sh
(crontab -l 2>/dev/null;echo "0 0 5,20 * * cd /root/mine/renew/domain_certificate; ./renew.sh $server_name > log.txt 2>&1")|crontab -
echo "uuid_xtls: $uuid_xtls"
echo "uuid_ws: $uuid_ws"
echo "trojan_passwd: $trojan_passwd"
echo "path_vless: $path_vless"
echo "path_trojan: $path_trojan"
ws_remote_addr="icook.tw"
cat > trojan-go_client.json <<-EOF
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 41155,
    "remote_addr": "$ws_remote_addr",
    "remote_port": 443,
    "password": [
        "$trojan_passwd"
    ],
    "ssl": {
        "sni": "$domain"
    },
    "mux": {
        "enabled": false,
        "concurrency":8,
        "idle_timeout":60
    },
    "router": {
        "enabled": false,
        "bypass": [
            "geoip:cn",
            "geoip:private",
            "geosite:cn",
            "geosite:geolocation-cn"
        ],
        "block": [
            "geosite:category-ads"
        ],
        "proxy": [
            "geosite:geolocation-!cn"
        ],
        "default_policy": "proxy",
        "geoip": "/usr/share/trojan-go/geoip.dat",
        "geosite": "/usr/share/trojan-go/geosite.dat"
    },
    "websocket":{
      "enabled":true,
      "path":"\$path_trojan",
      "host":"$domain"
    } 
}
EOF
cat > xray_ws.json <<-EOF
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 10807,
            "listen": "127.0.0.1",
            "protocol": "socks",
            "settings": {
                "udp": true
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "vless",
            "settings": {
                "vnext": [
                    {
                        "address": "$ws_remote_addr", // 换成你的域名或服务器 IP（发起请求时无需解析域名了）
                        "port": 443,
                        "users": [
                            {
                                "id": "$uuid_ws", // 填写你的 UUID
                                "encryption": "none",
                                "level": 0
                            }
                        ]
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "tls",
                "tlsSettings": {
                    "serverName": "$domain" // 换成你的域名
                },
                "wsSettings": {
                  "connectionReuse": true,
                  "path": "$path_vless",
                  "headers": {
                    "Host": "$domain"
                  }
                },
                "mux": {
                  "enabled": false,
                  "concurrency": 8
                }
            }
            }
    ]
}
EOF
cat > xray_xtls.json <<-EOF
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 10800,
            "listen": "127.0.0.1",
            "protocol": "socks",
            "settings": {
                "udp": true
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "vless",
            "settings": {
                "vnext": [
                    {
                        "address": "$domain", // 换成你的域名或服务器 IP（发起请求时无需解析域名了）
                        "port": 443,
                        "users": [
                            {
                                "id": "$uuid_xtls", // 填写你的 UUID
                                "flow": "xtls-rprx-direct",
                                "encryption": "none",
                                "level": 0
                            }
                        ]
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls", // 需要使用 XTLS
                "xtlsSettings": {
                    "serverName": "$domain" // 换成你的域名
                }
            }
        }
    ]
}
EOF
echo "trojan-go client configuration"
cat trojan-go_client.json
echo ""
echo "xray-ws client configuration"
cat xray_ws.json
echo "xray-xtls client configuration"
cat xray_xtls.json
rm trojan-go_client.json xray_ws.json xray_xtls.json



