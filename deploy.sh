service_name=$1
version=$2

if [ "$#" -ne "2" ]; then
	echo "Script should be executed with <service_name> <version> parameters." 1>&2
	exit 64
fi

docker_registry="localhost:8082"
image_name=$docker_registry/$service_name:$version

(docker stop $service_name || true) &&
	(docker container rm $service_name || true) &&
	(docker images -q $service_name | xargs docker image rm || true) &&
	docker login $docker_registry -u docker-user -p dotFive1 &&
	docker pull $image_name &&
	docker create --name $service_name --network cs-go-stats_prime $image_name &&
	docker start $service_name

docker logout $docker_registry