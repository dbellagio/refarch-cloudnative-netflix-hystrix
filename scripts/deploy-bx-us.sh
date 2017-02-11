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

# set config files here
# these will get created and populated when you execute this script
# If you see any errors, check these files and adjust and re-run, etc

SPRING_ENV_FILE=env-spring-config-bmx
MICROSERVICE_ENV_FILE=env-microservice-bmx
AMQP_ENV_FILE=env-eureka-amqp-bmx
ONLY_EUREKA_FILE=env-eureka-bmx

cd ~/ibm-cloud-architecture/refarch-cloudnative-netflix-hystrix/scripts
echo "create group for Eureka"
cf ic group create --name netflix-eureka -p 8761 -m 512 --min 1 --max 2 --desired 1 registry.ng.bluemix.net/supercontainers/netflix-eureka:dev

# Note, all of this is automated in this script now
# echo "Perform a 'cf ic ps -a' to get the container ID of Eureka."
# echo "Perform a 'cf ic inspect' on the container ID to find the Load Balancer IP."
# echo "Set this IP (Eureka's Load Balancer IP) into the following files, from the example entry loadbalancer_vip=172.31.1.28"
# echo " --> env-spring-config-remote"
# echo " --> env-eureka-only-remote"
# echo " --> env-zuul-remote"
# echo " as well as the Config Server's Git URL application.yml file, the default is at: https://github.com/dbellagio/wfd-menu-config"
# echo "Also, set the service URL of your RabbitMQ into 'env-eureka-only-remote' file"

echo
echo "sleeping 120"
sleep 120

EUREKA_CONTAINER_ID=$(cf ic ps -a | grep netflix-eureka:dev | awk '{print $1;}' )
EUREKA_IP=$( cf ic inspect ${EUREKA_CONTAINER_ID} | grep loadbalancer_vip | awk -F"=" '{print $2}' | awk -F"\"" '{print $1}' )

echo "Eureka Load Balancer IP is: " ${EUREKA_IP} " from container " ${EUREKA_CONTAINER_ID}
echo "Creating env file to hold only Eureka: " ${ONLY_EUREKA_FILE}
echo "eureka_client_serviceUrl_defaultZone=http://${EUREKA_IP}:8761/eureka" > ${ONLY_EUREKA_FILE}

echo "create spring config env file just to be lazy: " ${SPRING_ENV_FILE} 
echo "# just pass in Eureka and where to get the config from" > ${SPRING_ENV_FILE}
echo "eureka_client_serviceUrl_defaultZone=http://${EUREKA_IP}:8761/eureka" >> ${SPRING_ENV_FILE}
echo "spring_cloud_config_server_git_uri=https://github.com/dbellagio/wfd-menu-config" >> ${SPRING_ENV_FILE}

# echo "create group for the config server"
cf ic group create --name spring-config -p 8888 -m 512 --min 1 --max 2 --desired 1 --env-file ${SPRING_ENV_FILE} registry.ng.bluemix.net/supercontainers/spring-config:dev

echo "sleeping 120"
sleep 120

SPRING_CONTAINER_ID=$(cf ic ps -a | grep spring-config:dev | awk '{print $1;}' )
SPRING_CONFIG_IP=$( cf ic inspect ${SPRING_CONTAINER_ID} | grep loadbalancer_vip | awk -F"=" '{print $2}' | awk -F"\"" '{print $1}' )

echo "create microservice env file for the backend services just to be lazy: " ${MICROSERVICE_ENV_FILE} 
echo "# just pass in Eureka and the Config Server info" > ${MICROSERVICE_ENV_FILE}
echo "eureka_client_serviceUrl_defaultZone=http://${EUREKA_IP}:8761/eureka" >> ${MICROSERVICE_ENV_FILE}
echo "spring_cloud_config_uri=http://${SPRING_CONFIG_IP}:8888" >> ${MICROSERVICE_ENV_FILE}

echo "create group for the backend micro services and pass in config server load balancer IP and the Eureka load balancer IP, I've removed Eureka from the Config Server"
echo "appetizer"
cf ic group create --name appetizer -p 8082 -m 256 --min 1 --max 2 --desired 1 --env-file ${MICROSERVICE_ENV_FILE} registry.ng.bluemix.net/supercontainers/wfd-appetizer:dev

echo "sleeping 20"
sleep 20 

echo "dessert"
cf ic group create --name dessert -p 8083 -m 256 --min 1 --max 2 --desired 1 --env-file ${MICROSERVICE_ENV_FILE} registry.ng.bluemix.net/supercontainers/wfd-dessert:dev

echo "sleeping 20"
sleep 20

echo "entree"
cf ic group create --name entree -p 8081 -m 256 --min 1 --max 2 --desired 1 --env-file ${MICROSERVICE_ENV_FILE} registry.ng.bluemix.net/supercontainers/wfd-entree:dev

echo "sleeping 60"
sleep 60

echo "create aggregation env file just to be lazy: " ${AMQP_ENV_FILE} 

# Note: Set the correct AMQP information here

echo "# just pass in Eureka and the AMQP info" > ${AMQP_ENV_FILE}
echo "eureka_client_serviceUrl_defaultZone=http://${EUREKA_IP}:8761/eureka" >> ${AMQP_ENV_FILE}
echo "" >> ${AMQP_ENV_FILE}
echo "# uncomment this out for CloudAMQP: (or any RabbitMQ that is not based on SSL)" >> ${AMQP_ENV_FILE}
echo "# spring_rabbitmq_addresses=amqp://fqqsbyyd:Zn_Z1fgUPbvEiw7rKvV37k-S-Q1OcSNn@white-swan.rmq.cloudamqp.com/fqqsbyyd" >> ${AMQP_ENV_FILE}
echo "" >> ${AMQP_ENV_FILE}
echo "# Settings for Compose RabbitMQ (or any RabbitMQ based on SSL)" >> ${AMQP_ENV_FILE} 
echo "# comment these below out if not using a SSL version of RabbitMQ" >> ${AMQP_ENV_FILE}
echo "spring.rabbitmq.host=bluemix-sandbox-dal-9-portal.4.dblayer.com" >> ${AMQP_ENV_FILE}
echo "spring.rabbitmq.port=22893" >> ${AMQP_ENV_FILE}
echo "spring.rabbitmq.virtual-host=bmix_dal_yp_b52a3706_e068_45f4_8cc5_678efa10c2e7" >> ${AMQP_ENV_FILE}
echo "spring.rabbitmq.username=admin" >> ${AMQP_ENV_FILE}
echo "spring.rabbitmq.password=ACJWGEULVXHQUZIL" >> ${AMQP_ENV_FILE}
echo "spring.rabbitmq.ssl.enabled=true" >> ${AMQP_ENV_FILE}
echo "spring.rabbitmq.ssl.algorithm=TLSv1.2" >> ${AMQP_ENV_FILE}

echo "create group for menu, pass in Eureka and the Compose AMQPS info, using env file: " ${AMQP_ENV_FILE}
cf ic group create --name menu -p 8180 -m 512 --min 1 --max 2 --desired 1 --env-file ${AMQP_ENV_FILE} registry.ng.bluemix.net/supercontainers/wfd-menu:dev

echo "sleeping 60"
sleep 60

echo "create group for wfd-ui, pass in Eureka and AMQP info, using file: " ${AMQP_ENV_FILE}
cf ic group create --name wfd-ui -p 8181 -m 512 --min 1 --max 2 --desired 1 --env-file ${AMQP_ENV_FILE} registry.ng.bluemix.net/supercontainers/wfd-ui:dev

echo "sleeping 60"
sleep 60

echo "Note: running one container for Turbine to bypass Cloud Foundry networking issues with Long Polling"
echo "create single container for turbine, pass in Eureka and AMQP, using file: " ${AMQP_ENV_FILE}
cf ic run --name netflix-turbine -p 8989 -p 8990 -m 512 --env-file ${AMQP_ENV_FILE} registry.ng.bluemix.net/supercontainers/netflix-turbine:dev

echo "sleeping 120"
sleep 120

TURBINE_CONTAINER_ID=$(cf ic ps -a | grep netflix-turbine:dev | awk '{print $1;}' )
TURBINE_IP=$( cf ic inspect ${TURBINE_CONTAINER_ID} | grep IPAddress | awk -F\" '{print $(NF-1)}' )
TURBINE_IP=$( echo ${TURBINE_IP} | awk '{print $1;}' )

echo "create group for zuul, pass in Eureka, using file: " ${ONLY_EUREKA_FILE}
cf ic group create --name netflix-zuul -p 8080 -m 512 --auto --min 1 --max 2 --desired 1 --env-file ${ONLY_EUREKA_FILE} registry.ng.bluemix.net/supercontainers/netflix-zuul:dev

echo "sleeping 60"
sleep 60

echo "Note: running one container for Hystrix to bypass Cloud Foundry networking issues with Long Polling"
echo "create single container for Hystrix, pass in Eureka, using env file: " ${ONLY_EUREKA_FILE}
# echo "create group for Hystrix, pass in Eureka"
# cf ic group create --name netflix-hystrix -p 8383 -m 512 --min 1 --max 2 --desired 1 --env-file env-eureka-only-remote registry.ng.bluemix.net/supercontainers/netflix-hystrix:dev
cf ic run --name netflix-hystrix -p 8383 -m 512 --env-file ${ONLY_EUREKA_FILE} registry.ng.bluemix.net/supercontainers/netflix-hystrix:dev

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
echo "Turbine IP is: " ${TURBINE_IP}
echo " --> http://169.44.113.240:8383/hystrix/monitor?stream=http%3A%2F%2F"${TURBINE_IP}"%3A8989%2Fturbine%2Fturbine.stream"

# create public route for menu and map it
# cf create-route dev -n super-wfd-ui-dev mybluemix.net
# cf ic route map -n super-wfd-ui-dev -d mybluemix.net wfd-ui

echo "create a public route to eureka if needed for debug"
echo "cf create-route dev -n super-eureka-dev mybluemix.net"
echo "cf ic route map -n super-eureka-dev -d mybluemix.net netflix-eureka"

echo "remove public route to Eureka after everything is OK"
echo "cf ic route unmap -n super-eureka-dev -d mybluemix.net netflix-eureka"
# cf ic route unmap -n super-turbine-dev -d mybluemix.net netflix-turbine
# cf ic route unmap -n super-menu-dev -d mybluemix.net wfd-ui
# cf ic route unmap -n super-zuul-dev -d mybluemix.net netflix-zuul

