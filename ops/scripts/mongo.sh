# install mongo and create user
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get install -y mongodb-org
echo Mongo status...
sudo service mongod start
sleep 20
sudo mongo --eval "db.createUser({'user':'user','pwd':'user','roles':[ ]})"

# consul config
echo '{"service": {"name": "database", "tags": ["mongo"]}}' \
    >/etc/consul.d/mongo.json
sudo cp /ops/upstart/consul_client.conf /etc/init/consul.conf

# install consul template
wget https://github.com/hashicorp/consul-template/releases/download/v0.6.5/consul-template_0.6.5_linux_amd64.tar.gz
tar xzf consul-template_0.6.5_linux_amd64.tar.gz
sudo mv consul-template_0.6.5_linux_amd64/consul-template /usr/bin
sudo rmdir consul-template_0.6.5_linux_amd64

# consul template upstart
sudo cp /ops/upstart/mongo_consul_template.conf /etc/init/consul_template.conf