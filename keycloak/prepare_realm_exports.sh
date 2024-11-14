#!/bin/sh

# Directory containing realm folders
REALMS_DIR="/tmp/realms"

# Loop through each realm directory
for realm_dir in "$REALMS_DIR"/*; do
    if [ -d "$realm_dir" ]; then
        # Output file for each realm
        merged_template_file="$realm_dir/merged-realm-export-template.json"
        echo '{}' > "$merged_template_file"  # Initialize an empty JSON object

        # Check and merge realm-export.json file
        realm_export_file="$realm_dir/realm-export.json"
        if [ -f "$realm_export_file" ]; then
            echo "Merging $realm_export_file..."
            output=$(jq --argfile realm_export "$realm_export_file" '. += $realm_export' "$merged_template_file")
            echo "$output" > "$merged_template_file"
        else
            echo "Warning: $realm_export_file does not exist."
        fi

        # Check and merge users file
        users_file="$realm_dir/users.json"
        if [ -f "$users_file" ]; then
            echo "Merging $users_file..."
            output=$(jq --argfile users "$users_file" '.users += $users.users' "$merged_template_file")
            echo "$output" > "$merged_template_file"
        fi

        # TODO: configure SMTP based on some boolean environment variable
        # Check and merge SMTP file
        smtp_file="$realm_dir/smtp.json"
        if [ -f "$smtp_file" ]; then
            echo "Merging $smtp_file..."
            output=$(jq --argfile smtp "$smtp_file" '.smtpServer = $smtp.smtpServer' "$merged_template_file")
            echo "$output" > "$merged_template_file"
        fi

        # TODO: configure LDAP based on some boolean environment variable
        # Check and merge LDAP file
        ldap_file="$realm_dir/ldap.json"
        if [ -f "$ldap_file" ]; then
            echo "Merging $ldap_file..."
            output=$(jq --argfile ldap "$ldap_file" '.components += $ldap.components' "$merged_template_file")
            echo "$output" > "$merged_template_file"
        fi

        # Input template and output file
        output_file="$realm_dir/merged-realm-export.json"

        # Substitute values from environment variables and create realm-export.json
        envsubst < "$merged_template_file" > "$output_file"

        echo "Generated $output_file with environment variables."

        # Copy the merged output to the desired location
        cp "$output_file" "/shared/$(basename "$realm_dir")-realm-export.json"

#        cat "/shared/$(basename "$realm_dir")-realm-export.json"
        rm "$output_file"
        rm "$merged_template_file"
    fi
done
