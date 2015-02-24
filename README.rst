Eve-Demo
========

A fully featured RESTful Web API powered by Eve_. With Eve setting up an API is
very simple. You just need a launch script (run.py_) and a configuration file
(settings.py_). Check out the settings.py_ module in this repo to get an idea
of how configuration is handled. Don't forget to visit Eve_ website for
a complete list of features and examples. 

If you need a gentle introduction to the wondeful world of RESTful WEB APIs,
check out my EuroPython 2012 talk: `Developing RESTful Web APIs with Python,
Flask and MongoDB
<https://speakerdeck.com/nicola/developing-restful-web-apis-with-python-flask-and-mongodb>`_

There is also a sample client application available. It uses the Requests
library to consume the demo. In fact it has been quickly hacked together to
reset the API every once in a while. Check it out at
https://github.com/nicolaiarocci/eve-demo-client.
 
*Note*. The demo is currently running v0.0.4 of the Eve framework. Eve-Demo is
only updated when major Eve updates are released. Please refer to the official
Eve repository for an up-to-date features list. 

Deploy Eve on AWS
=============
Introduction
------------
To deploy Eve on Amazon Web Services, we're using Atlas_ by HashiCorp. The first step is building AMIs with Eve and MongoDB installed, and the second step is simply deploying those to AWS. 

General setup
-------------
1. Clone this repository
2. Create an Atlas account
3. Generate an `Atlas token<https://atlas.hashicorp.com/settings/tokens>` and save as environment variable. 
``
export ATLAS_TOKEN=<your_token>
``
4. In the Vagrantfile, Packer files `eve.json` and `mongo.json`, Terraform file `infrastructure.tf`, and Consul upstart script `consul_client.conf` you need to replace all instances of `<username>`,  `YOUR_ATLAS_TOKEN`, `YOUR_SECRET_HERE`, and `YOUR_KEY_HERE` with your Atlas username, Atlas token, and AWS keys.

Configuring Eve Python API and MongoDB
--------------------------------------
Before jumping into configuration steps, it's helpful to have a mental model for how services connect and how the Atlas workflow fits in. 

For the Eve REST API to work properly, it needs to connect to the MongoDB instance. Additionally, the MongoDB instance must be able to accept remote requests. Both Eve and Mongo have configuration files that should be dynamically updated with proper IP values. To accomplish this, we use `Consul<https://consul.io>` and `Consul Template<https://github.com/hashicorp/consul-template>. Any time a server is created, destroyed, or changes in health state, both the Eve and MongoDB configurations update to match by using the Consul Templates "settings.ctmpl" and "mongod.ctmpl". For MongoDB, we set the bind_ip equal to the instance's private IP:

``
{{range service "database"}}
bind_ip = {{.Address}}{{end}}
``

For Eve, set the MONGO_HOST IP equal to the private IP of the MongoDB instance.

```
{{range service "database"}}
MONGO_HOST = '{{.Address}}'{{end}}
```

In both configurations, Consul Template will query Consul for all nodes with the service "database", and then iterate through the list to populate the configuration file with the correct value. In our example, we only have one "database" instance, but it's possible you could have many.

This dyanamic setup allows us to destroy and create Eve API servers at scale with confidence that the Eve configuration will always be up-to-date. You can think of Consul and Consul Template as the connective webbing between services. 

Step 1: Create a Consul Cluster
-------------------------------
1. For Consul Template to work for with this setup, we first need to create a Consul cluster. You can follow `this walkthrough<https://github.com/hashicorp/atlas-examples/tree/master/consul>` to guide you through that process.

Step 2: Build an MongoDB AMI
----------------------------
1. Build an AMI with MongoDB installed. To do this, run ``packer push -create mongo.json`` in the ops directory. This will send the build configuration to Atlas so it can build your MongoDB AMI remotely. 
2. View the status of your build in the Operations tab of your `Atlas account<atlas.hashicorp.com/operations>`.

Step 3: Build an Eve AMI
------------------------
1. Build an AMI with Eve installed. To do this, run ``packer push -create eve.json`` in the ops directory. This will send the build configuration to Atlas so it can build your Eve AMI remotely. 
2. View the status of your build in the Operations tab of your `Atlas account<atlas.hashicorp.com/operations>`.
3. This creates an AMI with Eve installed, and now you need to send the actual Eve application code to Atlas and link it to the build configuration. To do this, simply run ``vagrant push`` in the app directory. This will send your Eve application, which is just the ``run.py`` file for now. Then link the Eve application with the Eve build configuration by clicking on your build configuration, then 'Links' in the left navigation. Complete the form with your username, 'eve' as the application name, and '/app' as the destination path.
4. Now that your application and build configuration are linked, simply rebuild the Eve configuration and you will have a fully-baked AMI with Eve installed and your application code in place.

Step 4: Deploy Eve and MongoDB
--------------------------
1. To deploy Eve and MongoDB, all you need to do is run ``terraform apply`` in the ops/terraform folder. Be sure to run ``terraform apply`` only on the artifacts first. The easiest way to do this is comment out the `aws_instance` resources and then run ``terraform apply``. Once the artifacts are created, just uncomment the ``aws_instance`` resources and run ``terraform apply`` on the full configuration. Watch Terraform provision three instances — two with Eve and one with MongoDB! 

```
provider "aws" {
    access_key = "YOUR_KEY_HERE"
    secret_key = "YOUR_SECRET_HERE"
    region = "us-east-1"
}

resource "atlas_artifact" "eve" {
    name = "<username>/eve"
    type = "aws.ami"
}

resource "atlas_artifact" "mongo" {
    name = "<username>/mongo"
    type = "aws.ami"
}

// resource "aws_security_group" "allow_all" {
//   name = "allow_all"
//     description = "Allow all inbound traffic"

//   ingress {
//       from_port = 0
//       to_port = 65535
//       protocol = "tcp"
//       cidr_blocks = ["0.0.0.0/0"]
//   }
// }

// resource "aws_instance" "eve" {
//     instance_type = "t2.small"
//     ami = "${atlas_artifact.eve.metadata_full.region-us-east-1}"
//     security_groups = ["${aws_security_group.allow_all.name}"]

//     # This will create 2 instances
//     count = 2
//     lifecycle = {
//       create_before_destroy = true
//     }
// }

// resource "aws_instance" "mongo" {
//     instance_type = "t2.small"
//     ami = "${atlas_artifact.mongo.metadata_full.region-us-east-1}"
//     security_groups = ["${aws_security_group.allow_all.name}"]

//     # This will create 1 instances
//     count = 1
//     lifecycle = {
//       create_before_destroy = true  
//     }
// }
```

Final Step: Test Eve
------------------------
1. SSH into one of your Eve instances
2. Run `curl -d '[{"firstname": "barack", "lastname": "obama"}' -H 'Content-Type: application/json'  http://127.0.0.1:5000/people` to write a record to your database
3. That's it! You just deployed a fully-functional Python REST API!
4. Navigate to the `Runtime tab<https://atlas.hashicorp.com/runtime>` in your Atlas account and click on the newly created infrastructure. You'll now see the real-time health of all your nodes and services!


.. _Eve: http://python-eve.org
.. _run.py: https://github.com/nicolaiarocci/eve-demo/blob/master/run.py
.. _settings.py: https://github.com/nicolaiarocci/eve-demo/blob/master/settings.py
.. _Atlas: https://atlas.hashicorp.com
