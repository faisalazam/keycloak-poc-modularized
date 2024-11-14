#!/bin/sh

# Directory containing realm folders
REALMS_DIR="/tmp/realms"

# Function to merge JSON files
merge_json() {
    local target_file="$1"
    local source_file="$2"
    local jq_command="$3"

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
        # Output file for each realm
        merged_template_file="$realm_dir/merged-realm-export-template.json"
        echo '{}' > "$merged_template_file"  # Initialize an empty JSON object

        # Merge files with the appropriate jq command
        merge_json "$merged_template_file" "$realm_dir/realm-export.json" ". += \$source"
        merge_json "$merged_template_file" "$realm_dir/users.json" ".users += \$source.users"
        merge_json "$merged_template_file" "$realm_dir/smtp.json" ".smtpServer = \$source.smtpServer"
        merge_json "$merged_template_file" "$realm_dir/ldap.json" ".components += \$source.components"

        # Substitute environment variables and output final merged file
        output_file="$realm_dir/merged-realm-export.json"
        envsubst < "$merged_template_file" > "$output_file"

        echo "Generated $output_file with environment variables."

        # Copy the merged output to the shared directory
        cp "$output_file" "/shared/$(basename "$realm_dir")-realm-export.json"

        # Clean up temporary files
        rm "$output_file" "$merged_template_file"
    fi
done
