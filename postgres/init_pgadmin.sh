#!/bin/sh

# Paths
TEMPLATE_PATH="/pgadmin4/servers.json.template"
SERVERS_JSON_PATH="/pgadmin4/servers.json"

# Check if the servers.json exists, if not, create it from the template
echo "Checking if $SERVERS_JSON_PATH exists..."
if [ ! -f "$SERVERS_JSON_PATH" ]; then
    echo "$SERVERS_JSON_PATH not found. Copying from template..."
    cp "$TEMPLATE_PATH" "$SERVERS_JSON_PATH"
fi

echo "Injecting environment variables into $SERVERS_JSON_PATH..."
sed -i "s#{{PGADMIN_SERVER_USER}}#${POSTGRES_USER}#g" "$SERVERS_JSON_PATH"
sed -i "s#{{PGADMIN_SERVER_HOST}}#postgres#g" "$SERVERS_JSON_PATH"
#sed -i "s#{{PGADMIN_SERVER_HOST}}#${KEYCLOAK_DB_HOST_NAME}#g" "$SERVERS_JSON_PATH"
sed -i "s#{{PGADMIN_SERVER_PORT}}#${POSTGRES_INTERNAL_PORT}#g" "$SERVERS_JSON_PATH"
sed -i "s#{{PGADMIN_SERVER_PASS_FILE}}#${PGADMIN_PASS_FILE}#g" "$SERVERS_JSON_PATH"

echo "Setting ownership for $SERVERS_JSON_PATH to pgAdmin user (UID:GID 5050:5050)..."
chown 5050:5050 "$SERVERS_JSON_PATH"
