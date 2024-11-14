#!/bin/sh

# Directory containing realm folders
REALMS_DIR="/tmp/realms"

# File paths for JSON files to be merged
SMTP_FILE="smtp.json"
LDAP_FILE="ldap.json"
USERS_FILE="users.json"
REALM_EXPORT_FILE="realm-export.json"

# Temporary and output file names
SHARED_DIR="/shared"
OUTPUT_FILE="merged-realm-export.json"
MERGED_TEMPLATE_FILE="merged-realm-export-template.json"

# Function to merge JSON files
merge_json() {
    target_file="$1"
    source_file="$2"
    jq_command="$3"

    if [ -f "$source_file" ]; then
        echo "Merging $source_file..."
        output=$(jq --argfile source "$source_file" "$jq_command" "$target_file")
        echo "$output" > "$target_file"
    else
        echo "Warning: $source_file does not exist."
    fi
}

# Loop through each realm directory
for realm_dir in "$REALMS_DIR"/*; do
    if [ -d "$realm_dir" ]; then
        # Initialize an empty JSON object in the template file
        echo '{}' > "$realm_dir/$MERGED_TEMPLATE_FILE"

        # Merge files with the appropriate jq command
        merge_json "$realm_dir/$MERGED_TEMPLATE_FILE" "$realm_dir/$REALM_EXPORT_FILE" ". += \$source"
        merge_json "$realm_dir/$MERGED_TEMPLATE_FILE" "$realm_dir/$USERS_FILE" ".users += \$source.users"
        merge_json "$realm_dir/$MERGED_TEMPLATE_FILE" "$realm_dir/$SMTP_FILE" ".smtpServer = \$source.smtpServer"
        merge_json "$realm_dir/$MERGED_TEMPLATE_FILE" "$realm_dir/$LDAP_FILE" ".components += \$source.components"

        # Substitute environment variables and output final merged file
        envsubst < "$realm_dir/$MERGED_TEMPLATE_FILE" > "$realm_dir/$OUTPUT_FILE"
        echo "Generated $realm_dir/$OUTPUT_FILE with environment variables."

        # Copy the merged output to the shared directory
        cp "$realm_dir/$OUTPUT_FILE" "$SHARED_DIR/$(basename "$realm_dir")-$OUTPUT_FILE"

        # Clean up temporary files
        rm "$realm_dir/$OUTPUT_FILE" "$realm_dir/$MERGED_TEMPLATE_FILE"
    fi
done
