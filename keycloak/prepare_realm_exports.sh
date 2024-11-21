#!/bin/sh

# If you face script not found error even though the script does exist, then it'll more likely be due to the fact that
# the script has CRLF line terminators (Windows-style). Run the following command to convert CRLF to LF to fix it:
# dos2unix keycloak/prepare_realm_exports.sh
# You can run the following to check the line terminators:
# file keycloak/prepare_realm_exports.sh
# If the output contains something like below, then it'd mean that it needs fixing to run on unix systems:
# ASCII text executable, with CRLF line terminators

# Directory containing realm folders
REALMS_DIR="/tmp/realms"

# File paths for JSON files to be merged
SMTP_FILE="smtp.json"
LDAP_FILE="ldap.json"
USERS_FILE="users.json"
CLIENTS_FILE="clients.json"
REALM_EXPORT_FILE="realm-export.json"

# Temporary and output file names
SHARED_DIR="/shared"
OUTPUT_FILE="merged-realm-export.json"
MERGED_TEMPLATE_FILE="merged-realm-export-template.json"

# Check if required commands available
for cmd in jq envsubst; do
    command -v "$cmd" >/dev/null 2>&1 || { echo >&2 "Error: $cmd command is required but not found."; exit 1; }
done

# Function to merge JSON files based on environment variable
merge_if_enabled() {
    setup_var_value="$1"
    json_file="$2"
    json_path="$3"

    # Check for the exact string "true", accounting for potential leading/trailing spaces
    if [ "$setup_var_value" = "true" ] || [ "$setup_var_value" = "TRUE" ]; then
        merge_json "$merged_template_path" "$realm_dir/$json_file" "$json_path"
    else
        echo "Skipping $json_file setup: environment variable is not true."
    fi
}

# Function to merge JSON files
merge_json() {
    target_file="$1"
    source_file="$2"
    jq_command="$3"

    if [ -f "$source_file" ]; then
        echo "Merging $source_file into $target_file..."
        output=$(jq --argfile source "$source_file" "$jq_command" "$target_file") || {
            echo "Error: Failed to merge $source_file"; exit 1;
        }
        echo "$output" > "$target_file"
    else
        echo "Warning: $source_file does not exist."
    fi
}

# Loop through each realm directory
for realm_dir in "$REALMS_DIR"/*; do
    if [ -d "$realm_dir" ]; then
        realm_name=$(basename "$realm_dir")
        merged_template_path="$realm_dir/$MERGED_TEMPLATE_FILE"
        output_path="$realm_dir/$OUTPUT_FILE"
        shared_output_path="$SHARED_DIR/${realm_name}-$OUTPUT_FILE"

        # Initialize an empty JSON object in the template file
        echo '{}' > "$merged_template_path" || { echo "Error: Failed to initialize $merged_template_path"; exit 1; }

        # Merge JSON files with appropriate commands
        merge_json "$merged_template_path" "$realm_dir/$REALM_EXPORT_FILE" ". += \$source"
        merge_if_enabled "$SETUP_CLIENTS" "$CLIENTS_FILE" ".clients = \$source.clients"
        merge_if_enabled "$SETUP_USERS" "$USERS_FILE" ".users = \$source.users"
        merge_if_enabled "$SETUP_SMTP" "$SMTP_FILE" ".smtpServer = \$source.smtpServer"
        merge_if_enabled "$SETUP_LDAP" "$LDAP_FILE" ".components += \$source.components"

        # Substitute environment variables and output final merged file
        envsubst < "$merged_template_path" > "$output_path" || {
            echo "Error: Failed to substitute environment variables in $merged_template_path"; exit 1;
        }
        echo "Generated $output_path with environment variables."

        # Copy the merged output to the shared directory
        cp "$output_path" "$shared_output_path" || {
            echo "Error: Failed to copy $output_path to $shared_output_path"; exit 1;
        }

        # Clean up temporary files
        rm "$output_path" "$merged_template_path" || {
            echo "Error: Failed to clean up temporary files"; exit 1;
        }
    fi
done
