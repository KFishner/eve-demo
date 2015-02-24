# install eve
sudo apt-get install -y python-pip
sudo apt-get install -y build-essential python-dev
sudo pip install eve
sudo apt-get install -y mongodb-clients

# eve upstart
sudo cp /ops/upstart/eve.conf /etc/init/eve.conf

# consul config
echo Configuring Consul....
echo '{"service": {"name": "web", "tags": ["eve"]}}' \
    >/etc/consul.d/eve.json
sudo cp /ops/upstart/consul_client.conf /etc/init/consul.conf

# install consul template
wget https://github.com/hashicorp/consul-template/releases/download/v0.6.5/consul-template_0.6.5_linux_amd64.tar.gz
tar xzf consul-template_0.6.5_linux_amd64.tar.gz
sudo mv consul-template_0.6.5_linux_amd64/consul-template /usr/bin
sudo rmdir consul-template_0.6.5_linux_amd64

# consul template upstart
sudo cp /ops/upstart/eve_consul_template.conf /etc/init/consul_template.conf