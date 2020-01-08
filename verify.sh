clean_folders() {
	rm -rf `cat ./../scripting/folders_to_remove | sed 's/\\r//g'`
}

project_context=$1
repository=$2

if [ "$#" -ne "2" ]; then
	echo "Script should be executed with <project_context> <repository> parameters." 1>&2
	exit 64
fi

cd ./../$project_context/$repository/src/

clean_folders &&
	dotnet restore -v m ./$repository.sln && 
	dotnet build -v diag -c Release --no-incremental --no-restore ./$repository.sln && 
	docker-compose -f ./../docker/docker-compose.yml -p cs-go-stats up --no-recreate -d &&
	dotnet test -v n -c Release --no-build ./$repository.sln