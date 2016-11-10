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
cd ~
# echo "create group for Eureka"
# cf ic group create --name netflix-eureka -p 8761 -m 512 --min 1 --max 2 --desired 1 registry.ng.bluemix.net/supercontainers/netflix-eureka:dev

# echo "sleeping 120"
# sleep 120

# echo "create group for the config server"
# cf ic group create --name spring-config -p 8888 -m 512 --min 1 --max 2 --desired 1 --env-file env-spring-config-remote registry.ng.bluemix.net/supercontainers/spring-config:dev

# echo "sleeping 120"
# sleep 120

echo "create group for aggregate services and pass in config server load balancer IP, config server has Eureka and everything else in it"
echo "appetizer"
cf ic group create --name appetizer -p 8082 -m 512 --min 1 --max 2 --desired 1 --env-file env-only-spring-config-remote registry.ng.bluemix.net/supercontainers/wfd-appetizer:dev

echo "sleeping 10"
sleep 10

echo "dessert"
cf ic group create --name dessert -p 8083 -m 512 --min 1 --max 2 --desired 1 --env-file env-only-spring-config-remote registry.ng.bluemix.net/supercontainers/wfd-dessert:dev

echo "sleeping 10"
sleep 10

echo "entree"
cf ic group create --name entree -p 8081 -m 512 --min 1 --max 2 --desired 1 --env-file env-only-spring-config-remote registry.ng.bluemix.net/supercontainers/wfd-entree:dev

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

echo "create group for turbine, pass in Eureka"
cf ic group create --name netflix-turbine -p 8989 -m 512 --min 1 --max 2 --desired 1 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/netflix-turbine:dev

echo "sleeping 60"
sleep 60

# echo "create group for zuul, pass in Eureka"
# cf ic group create --name netflix-zuul -p 8080 -m 256 --auto --min 1 --max 2 --desired 1 --env-file env-zuul-remote registry.ng.bluemix.net/supercontainers/netflix-zuul:dev

echo "create group for Hystrix, pass in Eureka"
cf ic group create --name netflix-hystrix -p 8383 -m 512 --min 1 --max 2 --desired 1 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/netflix-hystrix:dev

# echo "create a public route to zuul"
# cf create-route dev -n super-zuul-dev mybluemix.net
# cf ic route map -n super-zuul-dev -d mybluemix.net netflix-zuul

echo "create a public route to hystrix"
cf create-route dev -n super-hystrix-dev mybluemix.net
cf ic route map -n super-hystrix-dev -d mybluemix.net netflix-hystrix

create public route for menu and map it
cf create-route dev -n super-wfd-ui-dev mybluemix.net
cf ic route map -n super-wfd-ui-dev -d mybluemix.net wfd-ui

# create a public route to eureka
# cf create-route dev -n super-eureka-dev mybluemix.net
# cf ic route map -n super-eureka-dev -d mybluemix.net netflix-eureka

# remove public route to Eureka after everything is OK
# cf ic route unmap -n super-eureka-dev -d mybluemix.net netflix-eureka
# cf ic route unmap -n super-turbine-dev -d mybluemix.net netflix-turbine
# cf ic route unmap -n super-menu-dev -d mybluemix.net wfd-ui
# cf ic route unmap -n super-zuul-dev -d mybluemix.net netflix-zuul

