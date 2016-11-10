### refarch-cloudnative-netflix-hystrix

This is a version of the Netflix Hystrix component that will be used to monitor the What's for Dinner microservice application.   The documentation within this component will walk you through the entire process to startup your What's for Dinner environment and use the Hystrix dashboard.  The other components referenced here have their own README.md files, but you can use this one as a sample guide for an end to end setup.

## Using Turbine Stream with the CloudAMQP service on Bluemix Public

High level overview of setup (note, spring-config, netflix-eureka, and netflix-zuul not shown):
![Hystrix with Turbine Stream and RabbitMQ](static/imgs/HystrixTurbineStreamRabbitMQ.png?raw=true)

Currently there is a known issue related to getting Hystrix data through Zuul.  For this reason, we will create a public route to view our Hystrix dashboard. The containers listed in this scenario were built from these GitHub repos:

- RESILIENCY branch from these repos

-- https://github.com/dbellagio/refarch-cloudnative-netflix-turbine
-- https://github.com/dbellagio/refarch-cloudnative-wfd-menu
-- https://github.com/dbellagio/refarch-cloudnative-wfd-ui
-- https://github.com/ibm-cloud-architecture/refarch-cloudnative-wfd-appetizer
-- https://github.com/ibm-cloud-architecture/refarch-cloudnative-wfd-dessert
-- https://github.com/ibm-cloud-architecture/refarch-cloudnative-wfd-entree
-- https://github.com/ibm-cloud-architecture/refarch-cloudnative-spring-config
-- https://github.com/ibm-cloud-architecture/refarch-cloudnative-netflix-eureka
-- https://github.com/ibm-cloud-architecture/refarch-cloudnative-netflix-zuul

- MASTER branch from these repos

-- https://github.com/dbellagio/refarch-cloudnative-netflix-hystrix 
-- https://github.com/dbellagio/wfd-menu-config

## CloudAMQP Bluemix service

From Bluemix Public, create an instance of the CloudAMQP service and leave it unbound.

![CloudAMQP service in Bluemix](static/imgs/CloudAMQP.png?raw=true)

Under the Manage tab, open the CloudAMQP dashboard to view your credentials for the service.  You are interested in the value of the URL field.  Also note the username and password fields for checking later that your microservices are connecting to this service.  The value of URL will be injected into the netflix-turbine, wfd-menu, and wfd-ui containers as they startup through this environment variable (example shown here):

- spring_rabbitmq_addresses=amqp://blahblah:more-encrypted-stuff@white-swan.rmq.cloudamqp.com/blahblah

![CloudAMQP Credentials](static/imgs/RabbitMQDashboard.png?raw=true)

### Startup services and test locally using Docker

This section describes how to start up the microservices locally using local Docker commands.   It is always a good idea to be able to setup and debug environments locally before committing them to a Bluemix space if you can.  We assume you have everything built that is needed to standup the What's For Dinner application.   You can look at the script located in the file startlocal_microservices.sh.   This shows examples of how to run all the containers locally.  Note, if using this script, you must startup eureka first, and get the container IP of Eureka to pass into the Config Server and other services.   You will also need to set this value into your Config Server's application.yml file as some of the microservices in this example get their Eureka value from the Config Server through its configured GitHub repository.  This example sets that to: https://github.com/dbellagio/wfd-menu-config
You will want to use a different configuration for your setup.

The following sections are taken from the above noted script.  You will have to adjust the IP addresses to match your environment.   A few notes:

- Use "docker ps -a" to get a list of running containers
- Use "docker inspect" on a container to get its assigned IP address
- When using Bluemix and container groups, use the IP address of the load balancer IP of the container groups
- When using Bluemix container groups, give some time for certain container groups to be completely started (Eureka, Config Server) to avoid errors in the log files

To run this scenario below, I used a 10GB Linux Ubuntu image running Docker.  I left most of the services using the default container image of 1GB, as I ran into problems when I adjust the memory lower, except for the services where I used 756M in the commands below.  I believe this is due to my Docker environment, as I get a warning that swap is not enabled when I set the memory lower, which may explain why it fails when I set it too low.   When running in Bluemix, this limitation is not present, but, you still have to have it not be too low.

## Startup Eureka first and set the Eureka container IP address

- docker run --name netflix-eureka -p 8761:8761 -d netflix-eureka:latest

Validate everything is ok by checking the logs:

- docker logs netflix-eureka

Now, inspect the netflix-eureka container and set the IP in the correct environment files:
- env-eureka-only-local
- env-zuul-local
- env-spring-config-local

Also make sure you update this value in your Config Server's GitHub's application.yml file, or any other yml file being used as part of a Config Profile.

## Startup the Config Server and set the Config Server container IP Address

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name spring-config -p 8888:8888 --env-file env-spring-config-local -d spring-config:latest

Validate everything is ok by checking the logs:

- docker logs spring-config

Now, inspect the spring-config container and set the IP in the correct environment file:
- env-only-spring-config-local

## Startup the What's For Dinner microservices

These services can all start up without waiting for each other to finish.  They get their Eureka registry URL from the Config Server.

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name entree -p 8081:8081 --env-file env-only-spring-config-local -d wfd-entree:latest
- docker run --name appetizer -p 8082:8082 --env-file env-only-spring-config-local -d wfd-appetizer:latest
- docker run --name dessert -p 8083:8083 --env-file env-only-spring-config-local -d wfd-dessert:latest

Validate everything is ok by checking the logs

- docker logs entree
- docker logs appetizer
- docker logs dessert

## Startup the What's For Dinner menu

Before starting up the next three services, please make sure you have entered the correct RabbitMQ address into the environemnt file:
- env-eureka-only-local

Startup the service:

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name menu -p 8180:8180 -p 9180:9180 --env-file env-eureka-only-local -d wfd-menu:latest

Validate everything is ok by checking the logs

- docker logs menu

## Startup the What's For Dinner UI

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name wfd-ui -p 8181:8181 -p 9181:9181 --env-file env-eureka-only-local -d wfd-ui:latest

Validate everything is ok by checking the logs:

- docker logs wfd-ui

If you have not already, bring up a web browser and validate Eureka is up a running with the Config-Server and all other microservices registered:

- http://localhost:8761/

## Startup the Turbine Stream

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name netflix-turbine -p 8989:8989 -p 8990:8990 --env-file env-eureka-only-local -d netflix-turbine:latest

Validate the RabbitMQ connections.  You should have three connections in your RabbotMQ dashboard:

![RabbitMQ Dashboard Connections](static/imgs/RabbitMQ-Connections.png?raw=true)

## Startup the Hystrix dashboard and view the services

- cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- docker run --name netflix-hystrix -p 8383:8383 --env-file env-eureka-only-local -d netflix-hystrix:latest

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

### Running the same stack in Bluemix Public

This section will describe the process for running the same stack within Bluemix Public.

## Getting your images up to Bluemix

You need to initialize your Bluemix space for containers.  You normally get 2GB space setup in your initial space setup.  This may not be enough.  You can try to crank the memory down, but if you see failures its most likely due to not enough memory in the container.  I am using a space allocated with 8GB container memory for this test.  Thre are two ways to get your images up to Bluemix Public:

- first initialize your shell with "cf ic init"

then

- Tag your image with your Bluemix register namespace and then use "cf push" to push the entire container from your local Docker up to Bluemix

or

- Use "cf ic build" to build your image and give it a tag of your registery namespace.  This option will send up less info and build the container in Bluemix
- Example (this will send my build context to my registry in Bluemix public US, build the image and tag it "dev"):
-- cd ibm-cloud-architecture/refarch-cloudnative-wfd-appetizer/docker
-- cf ic build -t registry.ng.bluemix.net/supercontainers/wfd-appetizer:dev .

You can refer to the various GitHub repositories used here for more info.

![Bluemix images](static/imgs/BluemixImages.png?raw=true)

## Deploy to Bluemix Public

Normally, as we commit changes to our various repos, we would execute a Bluemix toolchain to automate the build, deployment, run tests, etc.  We will not cover toolchains here.  This section is just going to go through the commands and services in a similar fashion as described in the previous section on running it locally with Docker.  Here are some of the differences:

- We will be using Bluemix container groups to allow for easily running multiple instances of each service.  In this example, we just run one instance in a group, but you can adjust to play around as needed.

- We will create a public route to our Hystrix container group to view the dashboard as there are some known issues viewing this through zuul.  

- We will also create a public route to view the wfd-ui container group for our load testing and viewing the application.  

- When taking the container IP address for Eureka and Spring Config, use the load balancer IP from the container, rather than the specific container IP, since these are now in container groups

- We will be using the images with the "dev" tag that we built and pushed up to Bluemix public

Other than that, everything else is very similar to what was setup before.

## Startup Eureka  

There is a script called "deploy-bx-us.sh" located in the directory "~ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts" that has a complete startup sequence, with the eureka and spring config commented out to allow you to start those by hand.   Run Eureka:

- cf ic group create --name netflix-eureka -p 8761 -m 512 --min 1 --max 2 --desired 1 registry.ng.bluemix.net/supercontainers/netflix-eureka:dev

Use the "cf ic group list" command to notice how the container group gets deployed and goes through a lifecycle to get started.  Once the container is completely started, it will start executing.  You can then review the logs:

- cf ic ps -a 

Identify the container that was just started and inspect it for the load balancer IP.  Some commands that can help are:

- cf ic inspect <container-id>
- bx list containers

Once you get the IP address, set it into the remote environment files and also in the config server application.yml.  These files are used in this example:

- env-eureka-only-remote, env-spring-config-remote, env-zuul-remote
- adjust the application.yml if present in the config server GitHub

## Startup the Config Server

- cd ~ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- cf ic group create --name spring-config -p 8888 -m 512 --min 1 --max 2 --desired 1 --env-file env-spring-config-remote registry.ng.bluemix.net/supercontainers/spring-config:dev

Just as before, get the load balancer IP address from this container after it starts and set it into this file:

- env-only-spring-config-local

## Startup the 3 menu microservices

Make sure the Config Server container group has started completely before starting up these microservices.

- cd ~ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- cf ic group create --name appetizer -p 8082 -m 512 --min 1 --max 2 --desired 1 --env-file env-only-spring-config-remote registry.ng.bluemix.net/supercontainers/wfd-appetizer:dev
- cf ic group create --name dessert -p 8083 -m 512 --min 1 --max 2 --desired 1 --env-file env-only-spring-config-remote registry.ng.bluemix.net/supercontainers/wfd-dessert:dev
- cf ic group create --name entree -p 8081 -m 512 --min 1 --max 2 --desired 1 --env-file env-only-spring-config-remote registry.ng.bluemix.net/supercontainers/wfd-entree:dev

## Startup the menu aggregation service

After the 3 menu microservices startup, start the menu aggregration service.  Use "cf ic group list" to monitor the progress.

- cd ~ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- cf ic group create --name menu -p 8180 -m 512 --min 1 --max 2 --desired 1 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/wfd-menu:dev

Note, after this container gets created, you should have a connection out to your RabbitMQ service as before.

## Startup the What's For Dinner UI service

Make sure the menu service has started ok and has connected to RabbitMQ, and continue starting the rest of the stack.

- cd ~ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- cf ic group create --name wfd-ui -p 8181 -m 512 --min 1 --max 2 --desired 1 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/wfd-ui:dev

## Startup Turbine

After the menu services have started, create the Turbine service.

- cd ~ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- cf ic group create --name netflix-turbine -p 8989 -m 512 --min 1 --max 2 --desired 1 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/netflix-turbine:dev

Make sure you have the three connections to RabbitMQ after this service starts up.

## Startup Hystrix

Lastly, lets start up Hystrix.

- cd ~ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
- cf ic group create --name netflix-hystrix -p 8383 -m 512 --min 1 --max 2 --desired 1 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/netflix-hystrix:dev

Take a look at the container groups we have started.

- cf ic group list

![Container Group List](static/imgs/BluemixContainerGroups.png?raw=true)

As stated before, we are not going to deploy zuul in this example.  Instead, we will create two public routes to get at both the Hystrix dashboard and also the What's For Dinner UI.  We create the route using Cloud Foundry commands and then map the route to the container group as follows (use your own route names to make them unique):

- cf create-route dev -n super-wfd-ui-dev mybluemix.net
- cf ic route map -n super-wfd-ui-dev -d mybluemix.net wfd-ui
- cf create-route dev -n super-hystrix-dev mybluemix.net
- cf ic route map -n super-hystrix-dev -d mybluemix.net netflix-hystrix 

At this point, we now have public routes to both the What's For Dinner menu and also the Hystrix dashboard.   We can now bring up the Hystrix dashboard and configure it to monitor our Turbine stream.  We will need to inspect the container for turbine and pass in its IP to give to Hystrix, similar to what we did when running locally (do not use the load balancer IP of the group for this configuration):

- cf ic ps -a
- cf ic inspect <container id of turbine>

Bring up a browser to Hystrix and configure to monitor the Turbine stream.  Note that since we mapped a route to a container group, we don't have to specify the port in the URL as we did with local Docker.  Example: 

- http://super-hystrix-dev.mybluemix.net/hystrix 

![Hystrix dashboard in Bluemix](static/imgs/BluemixHystrixConfigure.png?raw=true)

Bring up a browser to the WFD UI.  Again, since we map a route to a container group, we do not need to specify a port in the URL.  Example:

- http://super-wfd-ui-dev.mybluemix.net/ 

![WFD in Bluemix](static/imgs/Bluemix-wfd-ui.png?raw=true)

Put some load on the menu route by adjusting the script "loadMenu-remote.sh" and running it in a shell window.  You can now view the Hystrix dashboard in Bluemix with some load on the services.  If you have some delay in seeing the dashboard, try Firefox browser to the URL and make sure you put some load on the route.

![Hystrix dashboard in Bluemix](static/imgs/BluemixHystrixLoad.png?raw=true)

Feel free to now experiment with failing services and checking the dashboard, etc.   To bring down the container groups, you just need to issue this command:

- cf ic group rm wfd-entree

The above command will bring down the entree service.  This also removes the container.

After your testing, you may want to remove the public route to your service.  You can leave the route in your CF space and simply unmap it from the container group.  You can also delete the route after unmapping.   Removing the container group will unmap the route as the container group is gone.

- cf ic route unmap -n super-hystrix-dev -d mybluemix.net netflix-hystrix
- cf ic route unmap -n super-wfd-ui-dev -d mybluemix.net wfd-ui
 
You can also look a the script "kill-remote-services.sh" to bring down the entire stack.




