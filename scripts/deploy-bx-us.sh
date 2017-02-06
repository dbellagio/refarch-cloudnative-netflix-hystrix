#----------------------------------------------
#  You need to run eureka first by hand, 
#  and then inspect the container and edit the
#  spring-config env file with the load balancer
#  IP address. Also put this in the eureka only
#  environment file.
#   
#  Then run the spring config
#  by hand, inspect the container and get the 
#  load balancer IP to set into the env files
#  that use spring config only.
#----------------------------------------------
# cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
# echo "create group for Eureka"
cf ic group create --name netflix-eureka -p 8761 -m 512 --min 1 --max 2 --desired 1 registry.ng.bluemix.net/supercontainers/netflix-eureka:dev

echo "Perform a 'cf ic ps -a' to get the container ID of Eureka."
echo "Perform a 'cf ic inspect' on the container ID to find the Load Balancer IP."
echo "Set this IP (Eureka's Load Balancer IP) into the following files, from the example entry loadbalancer_vip=172.31.1.28"
echo " --> env-spring-config-remote"
echo " --> env-eureka-only-remote"
echo " --> env-zuul-remote"
echo " as well as the Config Server's Git URL application.yml file"
echo "Also, set the service URL of your RabbitMQ into 'env-eureka-only-remote' file"
echo
echo "sleeping 120"
sleep 120

# echo "create group for the config server"
cf ic group create --name spring-config -p 8888 -m 512 --min 1 --max 2 --desired 1 --env-file env-spring-config-remote registry.ng.bluemix.net/supercontainers/spring-config:dev

echo "Perform a 'cf ic ps -a' to get the container ID of Config Server"
echo "Perform a 'cf ic inspect' on the container ID to find the Load Balancer IP."
echo "Set this IP (Config Server's Load Balancer IP) into the 'env-only-spring-config-remote' file"
echo "sleeping 120"
sleep 120

# echo "create group for the backend micro services and pass in config server load balancer IP, Config Server has Eureka info and everything else in it"
# echo "appetizer"
cf ic group create --name appetizer -p 8082 -m 512 --min 1 --max 2 --desired 1 --env-file env-only-spring-config-remote registry.ng.bluemix.net/supercontainers/wfd-appetizer:dev

echo "sleeping 10"
sleep 10 

echo "dessert"
cf ic group create --name dessert -p 8083 -m 256 --min 1 --max 2 --desired 1 --env-file env-only-spring-config-remote registry.ng.bluemix.net/supercontainers/wfd-dessert:dev

echo "sleeping 10"
sleep 10

echo "entree"
cf ic group create --name entree -p 8081 -m 256 --min 1 --max 2 --desired 1 --env-file env-only-spring-config-remote registry.ng.bluemix.net/supercontainers/wfd-entree:dev

echo "sleeping 120"
sleep 120

echo "create group for menu, pass in Eureka"
cf ic group create --name menu -p 8180 -m 512 --min 1 --max 2 --desired 1 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/wfd-menu:dev

echo "sleeping 60"
sleep 60

echo "create group for wfd-ui, pass in Eureka"
cf ic group create --name wfd-ui -p 8181 -m 512 --min 1 --max 2 --desired 1 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/wfd-ui:dev

echo "sleeping 60"
sleep 60

echo "Note: running one container for Turbine to bypass Cloud Foundry networking issues with Long Polling"
echo "create single container for turbine, pass in Eureka"
cf ic run --name netflix-turbine -p 8989 -m 512 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/netflix-turbine:dev
# cf ic group create --name netflix-turbine -p 8989 -m 512 --min 1 --max 2 --desired 1 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/netflix-turbine:dev

echo "sleeping 60"
sleep 60

echo "create group for zuul, pass in Eureka"
cf ic group create --name netflix-zuul -p 8080 -m 512 --auto --min 1 --max 2 --desired 1 --env-file env-zuul-remote registry.ng.bluemix.net/supercontainers/netflix-zuul:dev

echo "sleeping 60"
sleep 60

echo "Note: running one container for Hystrix to bypass Cloud Foundry networking issues with Long Polling"
echo "create single container for Hystrix, pass in Eureka"
# echo "create group for Hystrix, pass in Eureka"
# cf ic group create --name netflix-hystrix -p 8383 -m 512 --min 1 --max 2 --desired 1 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/netflix-hystrix:dev
cf ic run --name netflix-hystrix -p 8383 -m 512 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/netflix-hystrix:dev

echo "create a public route to zuul for WFD UI App endpoint"
cf create-route dev mybluemix.net --hostname super-zuul-dev --path whats-for-dinner
echo "Map route to zuul container group"
cf ic route map -n super-zuul-dev -d mybluemix.net netflix-zuul

echo "create a public IP for Hystrix to avoid Long Polling issue with CF route"
# cf create-route dev -n super-hystrix-dev mybluemix.net
# cf ic route map -n super-hystrix-dev -d mybluemix.net netflix-hystrix
#
echo "request public IP from Bluemix if you don't have one, (make sure your space has them allocated)"
# Bind IP to single container
echo "perform 'cf ic ip request' to ge the IP, if you already have one available, you just use it in the next step"
echo "bind the IP to the Hystrix container"
echo "example - 'cf ic ip bind 169.44.113.240 netflix-hystrix'"
cf ic ip bind 169.44.113.240 netflix-hystrix

echo "Look at these endpoints for your testing"
echo " --> super-zuul-dev.mybluemix.net/whats-for-dinner"
echo
echo "When looking at Hystrix (through the public IP), enter the IP of the Turbine container for the Turbine Stream"
echo " --> http://169.44.113.240:8383/hystrix/monitor?stream=http%3A%2F%2F172.31.1.22%3A8989%2Fturbine.stream"

# create public route for menu and map it
# cf create-route dev -n super-wfd-ui-dev mybluemix.net
# cf ic route map -n super-wfd-ui-dev -d mybluemix.net wfd-ui

# create a public route to eureka
# cf create-route dev -n super-eureka-dev mybluemix.net
# cf ic route map -n super-eureka-dev -d mybluemix.net netflix-eureka

# remove public route to Eureka after everything is OK
# cf ic route unmap -n super-eureka-dev -d mybluemix.net netflix-eureka
# cf ic route unmap -n super-turbine-dev -d mybluemix.net netflix-turbine
# cf ic route unmap -n super-menu-dev -d mybluemix.net wfd-ui
# cf ic route unmap -n super-zuul-dev -d mybluemix.net netflix-zuul

