#!/bin/sh

# Paths
TEMPLATE_PATH="/pgadmin4/servers.json.template"
SERVERS_JSON_PATH="/pgadmin4/servers.json"

# Check if the servers.json exists, if not, create it from the template
if [ ! -f "$SERVERS_JSON_PATH" ]; then
    cp "$TEMPLATE_PATH" "$SERVERS_JSON_PATH"
fi

# Inject environment variables into servers.json
sed -i "s#{{PGADMIN_SERVER_USER}}#${POSTGRES_USER}#g" "$SERVERS_JSON_PATH"
sed -i "s#{{PGADMIN_SERVER_HOST}}#postgres#g" "$SERVERS_JSON_PATH"
#sed -i "s#{{PGADMIN_SERVER_HOST}}#${KEYCLOAK_DB_HOST_NAME}#g" "$SERVERS_JSON_PATH"
sed -i "s#{{PGADMIN_SERVER_PORT}}#${POSTGRES_INTERNAL_PORT}#g" "$SERVERS_JSON_PATH"
sed -i "s#{{PGADMIN_SERVER_PASS_FILE}}#${PGADMIN_PASS_FILE}#g" "$SERVERS_JSON_PATH"

# Set the correct ownership for the pgAdmin user
chown 5050:5050 "$SERVERS_JSON_PATH"
