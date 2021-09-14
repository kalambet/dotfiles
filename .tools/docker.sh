docker-prune () {
	docker stop $(docker ps -aq)
	docker rm $(docker ps -q --filter status=exited)
	docker volume rm $(docker volume ls -q)
	docker network rm $(docker network ls -q)
	docker rmi $(docker images -q --filter dangling=true)
}

docker-cleanup () {
	docker rm $(docker ps -aq -f "status=exited")
}
