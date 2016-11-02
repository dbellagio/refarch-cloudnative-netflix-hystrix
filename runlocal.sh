echo "Starting hystrix dashboard ........... listening on port 8383"
docker run --name netflix-hysrix -p 8383:8383 --env-file ~/ibm-cloud-architecture/refarch-cloudnative-container-utils/env/env-eureka-only-local -d netflix-hystrix:latest
