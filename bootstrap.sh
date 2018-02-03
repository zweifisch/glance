
sed -i "s|GLANCE_DB_PASSWORD|$GLANCE_DB_PASSWORD|g" /etc/glance/glance-api.conf /etc/glance/glance-registry.conf
sed -i "s|GLANCE_PASSWORD|$GLANCE_PASSWORD|g" /etc/glance/glance-api.conf /etc/glance/glance-registry.conf
sed -i "s|MYSQL_HOST|$MYSQL_HOST|g" /etc/glance/glance-api.conf /etc/glance/glance-registry.conf
sed -i "s|OS_AUTH_URL|$OS_AUTH_URL|g" /etc/glance/glance-api.conf /etc/glance/glance-registry.conf

cat <<EOF | mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD"
create database if not exists glance CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DB_PASSWORD';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DB_PASSWORD';
EOF

export OS_IDENTITY_API_VERSION=3
openstack user show --domain default glance \
    || openstack user create --domain default --password "$GLANCE_PASSWORD" glance
openstack project show --domain default service \
    || openstack project create service
openstack role add --project service --user glance admin
openstack service show glance \
    || openstack service create --name glance --description "OpenStack Image" image
openstack endpoint list --service glance | grep public \
    || openstack endpoint create image public http://${HOSTNAME}:9292
openstack endpoint list --service glance | grep internal \
    || openstack endpoint create image internal http://${HOSTNAME}:9292
openstack endpoint list --service glance | grep admin \
    || openstack endpoint create image admin http://${HOSTNAME}:9292

su -s /bin/sh -c "glance-manage db_sync" glance

glance-registry &
sleep 5
glance-api
