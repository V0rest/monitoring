docker_compose_path="/etc/monitoring"
running="$(docker-compose --project-directory $docker_compose_path --file $docker_compose_path/docker-compose.yml ps --services --filter "status=running")"
services="$(docker-compose --project-directory $docker_compose_path --file $docker_compose_path/docker-compose.yml ps --services)"
if [ "$running" != "$services" ]; then
  echo "Following services are not running:"
    # Bash specific
    comm -13 <(sort <<<"$running") <(sort <<<"$services")
docker-compose --project-directory $docker_compose_path --file $docker_compose_path/docker-compose.yml restart
elif [ "$running" != "$services" ]; then
docker-compose --project-directory $docker_compose_path --file $docker_compose_path/docker-compose.yml down
docker-compose --project-directory $docker_compose_path --file $docker_compose_path/docker-compose.yml up -d
else
    echo "All services are running"
fi
