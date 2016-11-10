#----------------------------------------------
#  You need to run eureka first by hand,
#  and then inspect the container and edit the
#  spring-config env file with the 
#  IP address of Eureka. Also put this in the eureka only
#  environment file.
#
#  Then run the spring config
#  by hand, inspect the container and get the
#  to set into the env files
#  that use spring config only.
#----------------------------------------------
#
# Note: the -p 9080 lines are the Liberty container options, which are not in use
#
# To run this all locally in Docker, I used a 10GB VirtualBox image running Ubuntu

# this assumes all the needed containers have already been built
# this effort was created on the RESILIENCY branch of the refarch-cloudnative-* stuff
# within the ibm-cloud-architecture GitHub repos

# Do Eureka and Config Server by hand, that is why they are commented out here

# TODO: Insert pause/prompt instead

# run the eureka container
# echo "Running eureka"
# docker run --name netflix-eureka -p 8761:8761 -d netflix-eureka:latest

# echo "waitng 60 sec for eureka to get running"
# sleep 60

# run the config server
# echo "Running config server"
# docker run --name spring-config -p 8888:8888 --env-file env-spring-config-local -d spring-config:latest

# echo "waitng 90 sec for config server to get running"
# sleep 90

# run the rest which are runnable JARs in the Java 8 base image

# docker run --name entree -p 9080 -m 700M --env-file env-only-spring-config-local -d wfd-entree:latest
echo "Running entree service"
docker run --name entree -m 756M -p 8081:8081 --env-file env-only-spring-config-local -d wfd-entree:latest

# docker run --name appetizer -p 9080 -m 700M --env-file env-only-spring-config-local -d wfd-appetizer:latest
echo "Running appetizer service"
docker run --name appetizer -m 756M -p 8082:8082 --env-file env-only-spring-config-local -d wfd-appetizer:latest

# docker run --name dessert -p 9080 -m 700M --env-file env-only-spring-config-local -d wfd-dessert:latest
echo "Running dessert service"
docker run --name dessert -m 756M -p 8083:8083 --env-file env-only-spring-config-local -d wfd-dessert:latest

echo "waitng 45 sec for wfd services to get running"
sleep 45

# docker run --name menu -p 9080 -m 700M --env-file env-eureka-only-local -d wfd-menu:latest
echo "Running menu service"
docker run --name menu -p 8180:8180 -p 9180:9180 --env-file env-eureka-only-local -d wfd-menu:latest

echo "waitng 45 sec for wfd menu to get running"
sleep 45

echo "Running menu ui"
docker run --name wfd-ui -p 8181:8181 -p 9181:9181 --env-file env-eureka-only-local -d wfd-ui:latest

echo "waitng 45 sec for wfd ui to get running"
sleep 45

echo "Running Netflix Turbine"
docker run --name netflix-turbine -p 8989:8989 -p 8990:8990 --env-file env-eureka-only-local -d netflix-turbine:latest

echo "Running Netflix Hystrix Dashboard"
docker run --name netflix-hystrix -p 8383:8383 --env-file env-eureka-only-local -d netflix-hystrix:latest

# echo "Running zuul"
# docker run --name netflix-zuul -p 8080:8080 --env-file env-zuul-local -d netflix-zuul:latest
