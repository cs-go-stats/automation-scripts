clean_folders() {
	rm -rf `cat ./../scripting/folders_to_remove | sed 's/\\r//g'`
}

read_nuget_key() {
	cat ./nuget-key
}

clean_nuget_artifacts() {
	subfolder=$1
	rm -rf ./../../../../target/$subfolder/*
}

project_context=$1
project_name=$2
package_version=$3
pack_nuget=$4
pack_objects=$5
pack_docker=$6

objects_project_name=$project_name-objects

nuget_key=$(read_nuget_key)
nuget_registry="http://localhost:8081/repository/nuget-default"
docker_registry="localhost:8082"

if [ "$#" -ne "6" ]; then
	echo "Script should be executed with <project_context> <project_name> <package_version> <pack_nuget> <pack_objects> <pack_docker> parameters." 1>&2
	exit 64
fi

cd ./../$project_context/$project_name/src/

if [ $pack_nuget = "yes" ]; then
	 clean_nuget_artifacts $project_name && 
		dotnet pack -v m -c Release -o ./../../../../target/$project_name/$package_version/ ./$project_name/$project_name.csproj && 
		(dotnet nuget push ./../../../../target/$project_name/$package_version/*.nupkg -k $nuget_key -n true -t 10 -s $nuget_registry || true) &&
		clean_nuget_artifacts $project_name
fi

if [ $pack_objects = "yes" ]; then
	clean_nuget_artifacts $project_name && 
		dotnet pack -v m -c Release -o ./../../../../target/$project_name/$package_version/ ./$objects_project_name/$objects_project_name.csproj && 
		(dotnet nuget push ./../../../../target/$project_name/$package_version/*.nupkg -k $nuget_key -n true -t 10 -s $nuget_registry || true) &&
		clean_nuget_artifacts $project_name
fi

if [ $pack_docker = "yes" ]; then
	docker login $docker_registry -u docker-user -p dotFive1
	rm -rf ./out &&
		mkdir ./out &&
		clean_folders &&
		cp -R ./$project_name ./out/$project_name &&
		(cp -R ./$objects_project_name ./out/$objects_project_name || true) &&
		cd ./out/$project_name &&
		dotnet restore -r linux-musl-x64 -v m && dotnet publish -c Release -o ./../pub -r linux-musl-x64 -v m &&
		cd ./../../.. &&
		docker build -t $project_name:$package_version -f ./docker/Dockerfile . &&
		docker tag $project_name:$package_version $docker_registry/$project_name:$package_version &&
		(docker push $docker_registry/$project_name:$package_version || true) &&
		docker image rm $(docker images -q $project_name:$package_version) -f &&
		rm -rf ./src/out
	docker logout $docker_registry
fi