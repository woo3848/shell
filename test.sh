#!/bin/bash

base='$basearch'

echo "[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/7/$base/
gpgcheck=0
enabled=1" > /etc/yum.repos.d/nginx.repo

yum install -y nginx

yum install https://repo.ius.io/ius-release-el7.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
yum install python36u python36u-libs python36u-devel python36u-pip python36u-mod_wsgi -y
yum install mariadb mariadb-server mariadb-devel gcc -y


python3.6 -m pip install --upgrade pip
pip3.6 install virtualenvwrapper

firewall-cmd --add-port=80/tcp --zone=public --permanent
firewall-cmd --add-port=8000/tcp --zone=public --permanent
firewall-cmd --reload
echo "export WORKON_HOME=~/Env" >> ~/.bashrc
echo "export VIRTUALENVWRAPPER_PYTHON=/bin/python3.6" >> ~/.bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc

source ~/.bashrc
mkvirtualenv test
workon test

pip3.6 install django~=2.1.15
pip3.6 install mysqlclient


alias mo='cd "/usr/local"'
source ~/.bashrc
mo

yum -y install git

git init
git remote add origin https://github.com/woo3848/djnago_pro.git
git clone https://github.com/woo3848/djnago_pro.git /usr/local/victolee/

pip3.6 install uwsgi

mkdir -p /etc/uwsgi/sites

echo "[uwsgi]
project = myproject
username = root
base = /root

### Django Settings
# base directory
chdir = /usr/local/victolee/project
# python path
home = /root/Env/test/bin/python
# virtualenv path
virtualenv = /root/Env/test
# wsgi.py path
module = project.wsgi:application

master = true
processes = 5

uid = root
socket = /run/uwsgi/project.sock
chown-socket = root:nginx
chmod-socket = 660
vacuum = true

logto = /var/log/uwsgi/projcect.log" > /etc/uwsgi/sites/project.ini

mkdir -p /var/log/uwsgi

echo "[Unit]
Description=uWSGI service

[Service]

ExecStartPre=/bin/mkdir -p /run/uwsgi

ExecStartPre=/bin/chown root:nginx /run/uwsgi

ExecStart=/root/Env/test/bin/uwsgi --emperor /etc/uwsgi/sites
Restart=always
Type=notify
NotifyAccess=all

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/uwsgi.service

systemctl daemon-reload

ips=`/sbin/ifconfig | grep '\<inet\>' | sed -n '1p' | tr -s ' ' | cut -d ' ' -f3 | cut -d ':' -f2`
echo -e "server{
        listen 8000;
        server_name $ips;
        root /usr/local/victolee/project;\n

        location /static/ {
        alias /usr/local/victolee/project/static/;
        }\n

        location / {
                include uwsgi_params;
                uwsgi_pass unix:/run/uwsgi/project.sock;
                autoindex on;
                autoindex_exact_size off;
        }
}" > /etc/nginx/conf.d/project.conf



# sed -i'' -r -e "/[찾는패턴],/a\[찾은줄다음줄에삽입할패턴]" [대상파일]
#sed -i'' -r -e "/'STATIC',/a\'STATIC_ROOT = os.path.join(BASE_DIR, 'static')'" /usr/local/victolee/project/project/settings.py
sed -i'' -r -e "/STATIC/a\STATIC_ROOT = os.path.join(BASE_DIR, 'static')" /usr/local/victolee/project/project/settings.py

alias mov='cd "victolee/project"'
source ~/.bashrc
mov

python3.6 manage.py collectstatic

#systemctl start nginx
#systemctl enable nginx

#systemctl start uwsgi
#systemctl enable uwsgi


#sed -i "s/ALLOWED$/ALLOWED_HOST = ['$ips']/g" /usr/local/victolee/project/project/settings.py (요 내용이 잘 안먹습니다 ㅠ..)
