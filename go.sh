#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <username> <password>"
    exit 1
fi

username=$1
password=$2
user_home="/srv/NAS/$username"

if id "$username" &>/dev/null; then
    echo "L'utilisateur $username existe déjà."
else
    mkdir -p $user_home
    useradd -d $user_home -s /usr/sbin/nologin $username
    usermod -aG public_share $username
    usermod -aG sftpjail $username
    echo -e "$password\n$password" | passwd $username
    (echo "$password"; echo "$password") | sudo smbpasswd -a -s $username

fi

mkdir -p $user_home/{Documents,Downloads,Public,Templates}
# Attribution des permissions sur le home de l'utilisateur
chown -R root: $user_home
chown -R $username:$username $user_home/*
chmod -R 755 $user_home/

# Ajout dans /etc/fstab si l'entrée n'existe pas
if ! grep -q "$user_home/Public" /etc/fstab; then
    echo "$user_home/Public /srv/NAS_Public none bind 0 0" >> /etc/fstab
fi
systemctl daemon-reload
mount -a
echo "L'utilisateur $username a été configuré avec succès."


