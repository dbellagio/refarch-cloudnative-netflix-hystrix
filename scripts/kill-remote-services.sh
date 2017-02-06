echo "Stopping zuul"
cf ic group rm netflix-zuul

echo "Stopping Hystrix Dashboard"
# cf ic group rm netflix-hystrix
cf ic stop netflix-hystrix
sleep 10
cf ic rm netflix-hystrix

echo "Stopping Turbine"
# cf ic group rm netflix-turbine
cf ic stop netflix-turbine
sleep 10
cf ic rm netflix-turbine

echo "Stopping menu service"
cf ic group rm menu 

echo "Stopping menu ui"
cf ic group rm wfd-ui

echo "Stopping entree service"
cf ic group rm entree

echo "Stopping appetizer service"
cf ic group rm appetizer

echo "Stopping dessert service"
cf ic group rm dessert

echo "Stopping config server"
cf ic group rm spring-config

echo "Stopping eureka"
cf ic group rm netflix-eureka
