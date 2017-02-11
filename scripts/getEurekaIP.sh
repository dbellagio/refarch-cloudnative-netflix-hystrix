CONTAINER_ID=$(cf ic ps -a | grep netflix-eureka:dev | awk '{print $1;}' )
EUREKA_IP=$( cf ic inspect ${CONTAINER_ID} | grep loadbalancer_vip | awk -F"=" '{print $2}' | awk -F"\"" '{print $1}' )
echo "Eureka IP is: " ${EUREKA_IP}

CONFIG_CONTAINER_ID=$(cf ic ps -a | grep spring-config:dev | awk '{print $1;}' )
CONFIG_IP=$( cf ic inspect ${CONFIG_CONTAINER_ID} | grep loadbalancer_vip | awk -F"=" '{print $2}' | awk -F"\"" '{print $1}' )
echo "Config Server IP is: " ${CONFIG_IP}

# create input file just to be lazy
# echo "# just pass in Eureka and where to get the config from" > env-spring-config-remote
# echo "eureka_client_serviceUrl_defaultZone=http://${EUREKA_IP}:8761/eureka" >> env-spring-config-remote
# echo "spring_cloud_config_server_git_uri=https://github.com/dbellagio/wfd-menu-config" >> env-spring-config-remote

TURBINE_CONTAINER_ID=$(cf ic ps -a | grep netflix-turbine:dev | awk '{print $1;}' )
TURBINE_IP=$( cf ic inspect ${TURBINE_CONTAINER_ID} | grep IPAddress | awk -F\" '{print $(NF-1)}' )
TURBINE_IP=$( echo ${TURBINE_IP} | awk '{print $1;}' )


echo "Turbine container is : " ${TURBINE_CONTAINER_ID}
echo "Turbine IP is: " ${TURBINE_IP}

