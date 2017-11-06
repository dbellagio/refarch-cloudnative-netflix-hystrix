# refarch-cloudnative-netflix-hystrix

This is a version of the Netflix Hystrix component that will be used to monitor the What's For Dinner (WFD) microservice application.   The documentation within this component will walk you through the entire process to startup your What's For Dinner environment and use the Hystrix dashboard.  The other components referenced here have been built from the noted branch.  You can refer to their README.md file for more info.  

Important Note: This repo has been updated to reflect the new IBM Cloud Container service, based on Kubernetes.  The 
What's for Dinner app can run as-is with Kubernetes as described here.  But, the deployment is easier as we have removed
the need for Zuul and Eureka.  Instead we use the native Kubernetes networking to allow ingress and service discovery.

## Using Turbine Stream with the Compose RabbitMQ or CloudAMQP service on IBM Cloud Public

Logical Architecture
![Hystrix with Turbine Stream and RabbitMQ](static/imgs/WhatsForDinner-Netflix-OSS.png?raw=true)

Currently there is a known issue related to getting Hystrix data through Zuul.  For this reason, we will create a public route to view our Hystrix dashboard. The containers listed in this scenario were built from these GitHub repos:

### RESILIENCY branch from these repos

- https://github.com/dbellagio/refarch-cloudnative-netflix-turbine
- https://github.com/dbellagio/refarch-cloudnative-wfd-menu
- https://github.com/dbellagio/refarch-cloudnative-wfd-ui
- https://github.com/ibm-cloud-architecture/refarch-cloudnative-wfd-appetizer
- https://github.com/ibm-cloud-architecture/refarch-cloudnative-wfd-dessert
- https://github.com/ibm-cloud-architecture/refarch-cloudnative-wfd-entree
- https://github.com/ibm-cloud-architecture/refarch-cloudnative-spring-config
- https://github.com/ibm-cloud-architecture/refarch-cloudnative-netflix-eureka
- https://github.com/ibm-cloud-architecture/refarch-cloudnative-netflix-zuul
- https://github.com/ibm-cloud-architecture/refarch-cloudnative-zipkin

### MASTER branch from these repos

- https://github.com/dbellagio/refarch-cloudnative-netflix-hystrix 
- https://github.com/dbellagio/wfd-menu-config

## CloudAMQP IBM Cloud service

From IBM Cloud Public, create an instance of the CloudAMQP service and leave it unbound.

![CloudAMQP service in IBM Cloud](static/imgs/CloudAMQP.png?raw=true)

Under the Manage tab, open the CloudAMQP dashboard to view your credentials for the service.  You are interested in the value of the URL field.  Also note the username and password fields for checking later that your microservices are connecting to this service.  The value of URL will be injected into the netflix-turbine, wfd-menu, and wfd-ui containers as they startup through this environment variable (example shown here):

- spring_rabbitmq_addresses=amqp://blahblah:more-encrypted-stuff@white-swan.rmq.cloudamqp.com/blahblah

Note: The free service of the CloudAMQP will fill up and lock if you leave this application running overnight. After your testing, you may want to bring down the menu, ui, and turbine service to save your free AMQP from filling up.

![CloudAMQP Credentials](static/imgs/RabbitMQDashboard.png?raw=true)

## Updates for Compose RabbitMQ and using IBM Cloud GitHub Enterprise with your Spring Config Server

Note: If using the Compose RabbitMQ service as part of IBM Cloud, you should use these properties instead of the spring_rabbitmq_addresses set above. These values can be deduced from your connection credentials for the service:

- spring.rabbitmq.host=abcdef-dal22-tr0.0.compose.direct
- spring.rabbitmq.port=15130
- spring.rabbitmq.virtual-host=bmx_rmq_17feb03t1955_b33_be9f
- spring.rabbitmq.username=admin
- spring.rabbitmq.password=XYZXYZ
- spring.rabbitmq.ssl.enabled=true
- spring.rabbitmq.ssl.algorithm=TLSv1.2

One other update Note.  When starting your Spring Config server, if you have it backed by a IBM Cloud GitHub Enterprise, you need to add in additional setting for Spring to login. To do this, grant a token for you GitHub Enterprise, and assign the token to the Spring git username property as follows:

- spring_cloud_config_server_git_uri=https://github.ibm.com/someorg/wfd-menu-cfg
- spring_cloud_config_server_git_username=662b86dca94a59AGITTOKENdde1a40a6e340bc920
- spring_cloud_config_server_git_password=x-oauth-basic

# Startup services and test locally using Docker

This section describes how to start up the microservices locally using local Docker commands.   It is always a good idea to be able to setup and debug environments locally before committing them to a IBM Cloud space if you can.  We assume you have everything built that is needed to standup the What's For Dinner application.   You can look at the script located in the file startlocal_microservices.sh.   This shows examples of how to run all the containers locally.  Note, if using this script, you must startup eureka first, and get the container IP of Eureka to pass into the Config Server and other services.   You will also need to set this value into your Config Server's application.yml file as some of the microservices in this example get their Eureka value from the Config Server through its configured GitHub repository.  This example sets that to: https://github.com/dbellagio/wfd-menu-config
You will want to use a different configuration for your setup.

The following sections are taken from the above noted script.  You will have to adjust the IP addresses to match your environment.   A few notes:

- Use "docker ps -a" to get a list of running containers
- Use "docker inspect" on a container to get its assigned IP address
- When using IBM Cloud and container groups, use the IP address of the load balancer IP of the container groups
- When using IBM Cloud container groups, give some time for certain container groups to be completely started (Eureka, Config Server) to avoid errors in the log files

To run this scenario below, I used a 10GB Linux Ubuntu image running Docker.  I left most of the services using the default container image of 1GB, as I ran into problems when I adjust the memory lower, except for the services where I used 756M in the commands below.  I believe this is due to my Docker environment, as I get a warning that swap is not enabled when I set the memory lower, which may explain why it fails when I set it too low.   When running in IBM Cloud, this limitation is not present.

## Startup Eureka first and set the Eureka container IP address

- docker run --name netflix-eureka -p 8761:8761 -d netflix-eureka:latest

Validate everything is ok by checking the logs:

- docker logs netflix-eureka

Now, inspect the netflix-eureka container and set the IP Address of Eureka in the correct environment files:
- env-eureka-amqp-local
- env-eureka-local
- env-microservice-local
- env-spring-config-local

Note: I use environment files in these examples to hold the environment variables.  You could have easily used the -e option to set each environment key=value pair on the command line.
Note: I removed the Eureka IP Address from the Config Server's GitHub application.yml file. So, we pass it in everywhere to all services.

## Startup the Config Server and set the Config Server container IP Address

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name spring-config -p 8888:8888 --env-file env-spring-config-local -d spring-config:latest

Validate everything is ok by checking the logs:

- docker logs spring-config

Now, inspect the spring-config container and set the IP in the correct environment file:
- env-microservice-local

## Startup the What's For Dinner microservices

These services can all start up without waiting for each other to finish.  They get their Eureka registry URL from the Config Server.

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name entree -p 8081:8081 --env-file env-microservice-local -d wfd-entree:latest
- docker run --name appetizer -p 8082:8082 --env-file env-microservice-local -d wfd-appetizer:latest
- docker run --name dessert -p 8083:8083 --env-file env-microservice-local -d wfd-dessert:latest

Validate everything is ok by checking the logs

- docker logs entree
- docker logs appetizer
- docker logs dessert

## Startup the What's For Dinner menu

Before starting up the next three services, please make sure you have entered the correct RabbitMQ address into the environemnt file:
- env-eureka-amqp-local

Startup the service:

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name menu -p 8180:8180 -p 9180:9180 --env-file env-eureka-amqp-local -d wfd-menu:latest

Validate everything is ok by checking the logs

- docker logs menu

## Startup the What's For Dinner UI

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name wfd-ui -p 8181:8181 -p 9181:9181 --env-file env-eureka-amqp-local -d wfd-ui:latest

Validate everything is ok by checking the logs:

- docker logs wfd-ui

## Startup Zuul

This version of zuul does not enforce any security through shared secret tokens.  It will simply proxy to the exposed service endpoints of the registered microservices.

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name netflix-zuul -p 8080:8080 --env-file env-eureka-local -d netflix-zuul:latest

Validate everything is ok by checking the logs:

- docker logs netflix-zuul

You should be able to see the What's For Dinner UI through the zuul proxy, by bringing up a browser at the following URL:

- http://localhost:8080/whats-for-dinner

If you have not already, bring up a web browser and validate Eureka is up a running with the Config-Server and all other microservices registered:

- http://localhost:8761/

![Eureka registered services](static/imgs/Eureka-Instances.png?raw=true)

## Startup the Turbine Stream

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name netflix-turbine -p 8989:8989 -p 8990:8990 --env-file env-eureka-amqp-local -d netflix-turbine:latest

Validate the RabbitMQ connections.  You should have three connections in your RabbotMQ dashboard:

![RabbitMQ Dashboard Connections](static/imgs/RabbitMQ-Connections.png?raw=true)

## Startup the Hystrix dashboard and view the services

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name netflix-hystrix -p 8383:8383 --env-file env-eureka-local -d netflix-hystrix:latest

To validate, bring up a browser and point it at the Hystrix URL (use the Docker container IP of the netflix-hystrix container):

- http://172.17.0.10:8383/hystrix

![Hystrix Dashboard Configuration](static/imgs/HystrixDashboardConfiguration.png?raw=true)

## Put load onto the What's For Dinner UI service to see the Hystrix dashboard in application

In order for the Hystrix Dashboard to show better statistics, put a load on the wdf-ui interface by running the following script (make adjustments as needed).  You can also run this script in multiple windows, adjust the delay time, etc.

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- ./loadMenu.sh script

Look again at the Hystrix Dashboard while the load is being generated.

![Hystrix Dashboard with services under load](static/imgs/HystrixDashboardServiceLoad.png?raw=true)

## Fail services for more experimentation

At this time, you can play around with failing various services to see how it effects the Hystrix dashboard.  The following dashboard shows the result of stopping the wfd-menu container, which supplies the wfd-ui with the menu.

![Hystrix Dashboard - failure of menu service](static/imgs/HystrixDashboardServiceFailure.png?raw=true)

The default menu entries are shown here.  That is, if any of the backend microservices are down, the menu will default to these entries (i.e.: if Desserts is down, we will just show Cookies, Candy, Cake).  If the service is up, it will present the value from the Config Server's configured GitHub url.

![Circuit Breaker menu items](static/imgs/WFD-CircuitBreakEntries.png?raw=true)

# Running the same stack in IBM Cloud Public

This section will describe the process for running the same stack within IBM Cloud Public.

## Getting your images up to IBM Cloud

This section has been update to reflect deployment into Kubernetes.  It also assumes your images are pushed up to your IBM Cloud registry or some other place where they can be pulled from the IBM Cloud contatiner service.

You can refer to the various GitHub repositories used here for more info.

![IBM Cloud images](static/imgs/BluemixImages.png?raw=true)

## Deploy to IBM Cloud Public

This section will describe the commands used to deploy the services on IBM Cloud.  Here are some of the differences from running local in Docker:

- We will be using IBM Cloud container service to allow for easily running multiple instances of each service.  In this example, we use Kubernetes deployments to dictate the number of instances of each service that will be run.

- We will use a single container for Turbine as this single container's Kubernetes service is used in the Hystrix dashboard's turbine stream entry.

- We will access the public route to view the wfd-ui service through the Kubernetes Ingress

- We will be using the images from an IBM Cloud public registry as well as the Docker's public registry.   You will need to build your own images and make substitutions as appropriate

Other than that, everything else is very similar to what was setup before.

# Kubernetes Deploy Scripts

I've placed all the deployment scripts in the folder deployk8s.  In this folder, there are example yaml files and a script to deploy the workloads.

cd deployk8s

kubectl create -f zipkin-deployment.yml
sleep 30
kubectl create -f spring-config-noeureka.yml
sleep 30
kubectl create -f wfd-appetizer-noeureka.yml
kubectl create -f wfd-dessert-noeureka.yml
kubectl create -f wfd-entree-noeureka.yml
sleep 30
kubectl create -f wfd-menu-paid2-dockerio-noribbon.yml
sleep 30
kubectl create -f wfd-ui-paid2-dockerio-noribbon.yml
sleep 30
kubectl create -f netflix-turbine-paid2-noeureka.yml
sleep 30
kubectl create -f netflix-hystrix-noeureka.yml
sleep 30
kubectl create -f wfd-ingress.yml

# Hystrix

Bring up a browser to Hystrix and configure to monitor the Turbine stream.  Note that since we bound a public IP to the container, we still need to port in the URL.  Example: 

- http://<custer-public-ip>:30383/hystrix/monitor?stream=http%3A%2F%2Fnetflix-turbine-service%3A8989%2Fturbine%2Fturbine.stream

![Hystrix dashboard in IBM Cloud](static/imgs/BluemixHystrixConfigure.png?raw=true)

Bring up a browser to the WFD UI.  Since we mapped a route though the Kubernetes ingess we do not need to specify a port in the URL.  Example:

- http://your-ibm-cloud-cluster/whats-for-dinner 
- http://your-ibm-cloud-cluster/menu
- http://your-ibm-cloud-cluster/entrees
- http://your-ibm-cloud-cluster/appetizers
- http://your-ibm-cloud-cluster/desserts

![WFD in IBM Cloud](static/imgs/Bluemix-wfd-ui.png?raw=true)

Put some load on the menu route by adjusting the script "loadMenu-remote.sh" and running it in a shell window.  You can now view the Hystrix dashboard in IBM Cloud with some load on the services.

![Hystrix dashboard in IBM Cloud](static/imgs/BluemixHystrixLoad.png?raw=true)

