FROM osixia/openldap:stable

# Add the LDIF file to the container's assets directory
ADD sample.ldif /container/service/slapd/assets/config/bootstrap/ldif/sample.ldif

# You do not need to run /container/tool/run manually;
# the container will take care of it automatically
