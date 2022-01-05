# init tnt hosts
TNT_HOSTS="router-1 storage-1 storage-2 storage-3 storage-4"

# start waiting
for TNT_HOST in $TNT_HOSTS; do
  until nc -z -v -w30 ${TNT_HOST} 3301; do
    echo "Waiting for ${TNT_HOST}..."
    sleep 1
  done
  echo "${TNT_HOST} is up and running"
done

# You can do it manually in web ui at http://localhost:8081/
curl -X POST http://router-1:8081/admin/api -d@- <<'QUERY'
{"query":
    "mutation {
        j1: join_server(
            uri:\"router-1:3301\",
            instance_uuid: \"bbbbbbbb-bbbb-4000-b000-000000000001\",
            replicaset_uuid: \"bbbbbbbb-0000-4000-b000-000000000000\",
            roles: [\"vshard-router\",\"app.roles.key-value\"],
            timeout: 5
        )
        j2: join_server(
            uri:\"storage-1:3301\",
            instance_uuid: \"cccccccc-cccc-4000-b000-000000000001\",
            replicaset_uuid: \"cccccccc-0000-4000-b000-000000000000\",
            roles: [\"vshard-storage\",\"app.roles.storage\",\"app.roles.expiry-entries\"],
            timeout: 5
        )
        j3: join_server(
            uri:\"storage-2:3301\",
            instance_uuid: \"cccccccc-cccc-4000-b000-000000000002\",
            replicaset_uuid: \"cccccccc-0000-4000-b000-000000000000\",
            roles: [\"vshard-storage\",\"app.roles.storage\",\"app.roles.expiry-entries\"],
            timeout: 5
        )
        j4: join_server(
            uri:\"storage-3:3301\",
            instance_uuid: \"cccccccc-cccc-4000-b000-000000000003\",
            replicaset_uuid: \"cccccccc-0000-4000-b000-000000000000\",
            roles: [\"vshard-storage\",\"app.roles.storage\",\"app.roles.expiry-entries\"],
            timeout: 5
        )
        j5: join_server(
            uri:\"storage-4:3301\",
            instance_uuid: \"cccccccc-cccc-4000-b000-000000000004\",
            replicaset_uuid: \"cccccccc-0000-4000-b000-000000000001\",
            roles: [\"vshard-storage\",\"app.roles.storage\",\"app.roles.expiry-entries\"],
            timeout: 5
        )
        j6: join_server(
            uri:\"storage-5:3301\",
            instance_uuid: \"cccccccc-cccc-4000-b000-000000000005\",
            replicaset_uuid: \"cccccccc-0000-4000-b000-000000000001\",
            roles: [\"vshard-storage\",\"app.roles.storage\",\"app.roles.expiry-entries\"],
            timeout: 5
        )
        j7: join_server(
            uri:\"storage-6:3301\",
            instance_uuid: \"cccccccc-cccc-4000-b000-000000000006\",
            replicaset_uuid: \"cccccccc-0000-4000-b000-000000000001\",
            roles: [\"vshard-storage\",\"app.roles.storage\",\"app.roles.expiry-entries\"],
            timeout: 5
        )
        bootstrap_vshard
        cluster {
            failover(enabled:true)
        }
    }"
}
QUERY
