kubectl create -f zipkin-deployment.yml
sleep 60
kubectl create -f spring-config-noeureka.yml
sleep 60
kubectl create -f wfd-appetizer-noeureka.yml
kubectl create -f wfd-dessert-noeureka.yml
kubectl create -f wfd-entree-noeureka.yml
sleep 60
kubectl create -f wfd-menu-paid2-dockerio-noribbon.yml
sleep 60
kubectl create -f wfd-ui-paid2-dockerio-noribbon.yml
sleep 60
kubectl create -f netflix-turbine-paid2-noeureka.yml
sleep 60
kubectl create -f netflix-hystrix-noeureka.yml
sleep 60
kubectl create -f wfd-ingress.yml
