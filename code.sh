#!/bin/bash

# Check if project path is provided and if output path provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-laravel-project>"
    exit 1
fi

# Set project path and validate
PROJECT_PATH=$(realpath "$1")
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Directory $PROJECT_PATH does not exist"
    exit 1
fi

# Debug information
echo "Debug: Full project path: $PROJECT_PATH"
echo "Debug: Checking directory contents:"
ls -la "$PROJECT_PATH"

# Change to project directory
cd "$PROJECT_PATH" || exit 1
echo "Debug: Current working directory: $(pwd)"

# Output file definition with full path
OUTPUT_FILE="$(pwd)/laravel_codebase_dump_$(date +%Y%m%d_%H%M%S).txt"

# Define exclusion patterns
EXCLUDE_PATTERNS="-not -path '*/vendor/*' -not -path '*/storage/*' -not -path '*/node_modules/*' -not -path '*/bootstrap/cache/*' -not -path '*/.git/*' -not -path '*/public/build/*'"

# Function to add section headers
add_section_header() {
    echo -e "\n\n==============================================" >> "$OUTPUT_FILE"
    echo "=== $1 ===" >> "$OUTPUT_FILE"
    echo "==============================================\n" >> "$OUTPUT_FILE"
}

# Function to parse PHP files
parse_php_file() {
    if [ -f "$1" ]; then
        echo -e "\n--- ${1#./} ---\n" >> "$OUTPUT_FILE"
        echo "Debug: Processing file: $1"
        cat "$1" >> "$OUTPUT_FILE"
    fi
}

# Function to process directory if it exists
process_directory() {
    local dir=$1
    local section=$2
    echo "Debug: Checking directory: $dir"
    if [ -d "$dir" ]; then
        echo "Debug: Processing directory: $dir"
        add_section_header "$section"
        while IFS= read -r -d '' file; do
            echo "Debug: Found file: $file"
            parse_php_file "$file"
        done < <(find "$dir" -type f -name "*.php" -print0)
    else
        echo "Debug: Directory not found: $dir"
    fi
}

# Initialize output file with metadata
echo "Laravel Codebase Analysis - Generated on $(date)" > "$OUTPUT_FILE"
echo "Project: $(basename "$PROJECT_PATH")" >> "$OUTPUT_FILE"
echo "Project Path: $PROJECT_PATH" >> "$OUTPUT_FILE"
echo "=============================================" >> "$OUTPUT_FILE"

# Process core Laravel directories
DIRECTORIES=(
    "app/Http/Controllers:CONTROLLERS"
    "app/Http/Middleware:MIDDLEWARE"
    "app/Models:MODELS"
    "app/Services:SERVICES"
    "app/Providers:PROVIDERS"
    "app/Repositories:REPOSITORIES"
    "app/Events:EVENTS"
    "app/Exceptions:EXCEPTIONS"
    "config:CONFIGURATION"
    "routes:ROUTES"
    "database/migrations:MIGRATIONS"
    "tests:TESTS"
)

# Process each directory
for dir_entry in "${DIRECTORIES[@]}"; do
    IFS=':' read -r dir_path section_name <<< "$dir_entry"
    echo "Debug: Processing $section_name in $dir_path"
    process_directory "$dir_path" "$section_name"
done

# Add codebase statistics
add_section_header "CODEBASE STATISTICS"
echo "Debug: Calculating statistics..."

# Count total PHP files
total_files=$(find . -type f -name "*.php" ! -path "*/vendor/*" ! -path "*/storage/*" ! -path "*/node_modules/*" | wc -l)
echo "Total PHP Files: $total_files" >> "$OUTPUT_FILE"

# Count files by type
for dir_entry in "${DIRECTORIES[@]}"; do
    IFS=':' read -r dir_path section_name <<< "$dir_entry"
    if [ -d "$dir_path" ]; then
        count=$(find "$dir_path" -type f -name "*.php" | wc -l)
        echo "$section_name Files: $count" >> "$OUTPUT_FILE"
    fi
done

# Add framework information
add_section_header "FRAMEWORK INFORMATION"
if [ -f "artisan" ]; then
    php artisan --version >> "$OUTPUT_FILE" 2>/dev/null || echo "Laravel version could not be determined" >> "$OUTPUT_FILE"
fi
php -v | head -n1 >> "$OUTPUT_FILE"

# Create compressed version
echo "Debug: Creating compressed version..."
gzip -c "$OUTPUT_FILE" > "${OUTPUT_FILE}.gz"

echo "Code extraction complete. Output saved to: $OUTPUT_FILE"
echo "Total size: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo "Compressed version saved to: ${OUTPUT_FILE}.gz"
echo "Compressed size: $(du -h "${OUTPUT_FILE}.gz" | cut -f1)"

# Print summary of processed files
echo "Debug: Summary of processed files:"
echo "Total PHP files found: $total_files"
for dir_entry in "${DIRECTORIES[@]}"; do
    IFS=':' read -r dir_path section_name <<< "$dir_entry"
    if [ -d "$dir_path" ]; then
        count=$(find "$dir_path" -type f -name "*.php" | wc -l)
        echo "$section_name: $count files"
    fi
done
