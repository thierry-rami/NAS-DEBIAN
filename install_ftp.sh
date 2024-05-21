#/bin/bash
# maj des paquets
apt update && apt upgrade -y
apt-get install proftpd-core  proftpd-mod-crypto wget clamav clamav-daemon -y
service proftpd stop
 
##### Partie 1) FTP
#création de la clé et du certificat
mkdir /etc/proftpd/ssl
openssl req -new -x509 -keyout /etc/proftpd/ssl/proftpd.key.pem -days 365 -nodes -out /etc/proftpd/ssl/proftpd.cert.pem
chmod 740 /etc/proftpd/ssl/*

#on supprime les fichiers de base
rm /etc/proftpd/proftpd.conf
rm /etc/proftpd/tls.conf
rm /etc/proftpd/modules.conf

#récupeation des fichiers de config sur github 
cd /etc/proftpd/
wget https://raw.githubusercontent.com/thierry-rami/FTP/main/config/proftpd.conf
wget https://raw.githubusercontent.com/thierry-rami/FTP/main/config/modules.conf
wget https://raw.githubusercontent.com/thierry-rami/FTP/main/config/tls.conf

# on relance le service proftpd
service proftpd start

# X-Team
# on active le lancement de proftpd au boot
systemctl enable proftpd

##### Partie 2) Antivirus ( protection /home et /mnt )
sed -i 's/OnAccessMaxFileSize 5M/#OnAccessMaxFileSize 5M/g' /etc/clamav/clamd.conf

#configuration pour l'analyse à l'accès
cat <<'EOF' >> /etc/clamav/clamd.conf
OnAccessMaxFileSize 6000M
OnAccessPrevention yes
OnAccessIncludePath /mnt
OnAccessIncludePath /home
OnAccessExcludeUname clamav
EOF

#creation du service
cat <<'EOF' > /etc/systemd/system/antivirus.service
[Unit]
Description=Clamonacc Service
After=network.target
[Service]
ExecStart=/usr/sbin/clamonacc --remove --fdpass --stream --foreground
User=root
[Install]
WantedBy=multi-user.target
EOF

#gestion des services
systemctl daemon-reload
systemctl enable clamav-daemon
systemctl enable antivirus

systemctl start clamav-daemon
systemctl start antivirus

systemctl status clamav-daemon
systemctl status antivirus


