#!/bin/bash

# Data Transfer Script with Verification and Cleanup
# Supports individual and grouped transfers via YAML configuration

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration file
CONFIG_FILE="rsync_config.yaml"

# Script modes
MODE_TRANSFER_ONLY="transfer"
MODE_VALIDATE_ONLY="validate"
MODE_BOTH="both"
SCRIPT_MODE=""

# Arrays to store transfer mappings
declare -a SOURCES
declare -a DESTINATIONS

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --transfer          Transfer only mode (default)"
    echo "  -v, --validate          Validate only mode"
    echo "  -b, --both              Transfer and validate mode"
    echo "  -c, --config <file>     YAML config file (default: rsync_config.yaml)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -t                      # Transfer only using default config"
    echo "  $0 -v -c myconfig.yaml     # Validate only using custom config"
    echo "  $0 -b                      # Both transfer and validate"
    echo ""
    echo "Config file supports two formats:"
    echo ""
    echo "1. Individual transfers:"
    echo "   transfers:"
    echo "     - source: /path/to/source"
    echo "       destination: /path/to/destination"
    echo ""
    echo "2. Grouped transfers:"
    echo "   transfer_groups:"
    echo "     - destination_base: /base/destination/path"
    echo "       preserve_source_name: true"
    echo "       sources:"
    echo "         - /path/to/source1"
    echo "         - /path/to/source2"
    exit 1
}

# Function to check if yq is installed
check_yq() {
    if ! command -v yq &> /dev/null; then
        print_status $RED "ERROR: yq is not installed. Please install yq to parse YAML files."
        print_status $YELLOW "Install yq using:"
        print_status $YELLOW "  - macOS: brew install yq"
        print_status $YELLOW "  - Linux: wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq"
        exit 1
    fi
}

# Function to get basename (last directory name)
get_basename() {
    local path=$1
    echo "${path##*/}"
}

# Function to load configuration from YAML file
load_yaml_config() {
    local config_file=$1
    
    if [ ! -f "$config_file" ]; then
        print_status $RED "ERROR: Configuration file $config_file not found!"
        return 1
    fi
    
    print_status $BLUE "Loading configuration from $config_file..."
    
    # Check if yq is available
    check_yq
    
    # Clear arrays
    SOURCES=()
    DESTINATIONS=()
    
    # First, load individual transfers if they exist
    local individual_count=$(yq eval '.transfers | length' "$config_file" 2>/dev/null || echo "0")
    
    if [ "$individual_count" != "0" ] && [ "$individual_count" != "null" ]; then
        print_status $CYAN "Loading individual transfers..."
        
        for ((i=0; i<$individual_count; i++)); do
            local source=$(yq eval ".transfers[$i].source" "$config_file")
            local dest=$(yq eval ".transfers[$i].destination" "$config_file")
            
            if [ "$source" != "null" ] && [ "$dest" != "null" ]; then
                SOURCES+=("$source")
                DESTINATIONS+=("$dest")
            fi
        done
    fi
    
    # Then, load grouped transfers if they exist
    local group_count=$(yq eval '.transfer_groups | length' "$config_file" 2>/dev/null || echo "0")
    
    if [ "$group_count" != "0" ] && [ "$group_count" != "null" ]; then
        print_status $CYAN "Loading grouped transfers..."
        
        for ((g=0; g<$group_count; g++)); do
            local dest_base=$(yq eval ".transfer_groups[$g].destination_base" "$config_file")
            local preserve_name=$(yq eval ".transfer_groups[$g].preserve_source_name" "$config_file")
            local source_count=$(yq eval ".transfer_groups[$g].sources | length" "$config_file")
            
            if [ "$dest_base" = "null" ]; then
                print_status $RED "ERROR: destination_base missing in group $((g+1))"
                continue
            fi
            
            # Default to preserving source name if not specified
            if [ "$preserve_name" = "null" ]; then
                preserve_name="true"
            fi
            
            # Process each source in the group
            for ((s=0; s<$source_count; s++)); do
                local source=$(yq eval ".transfer_groups[$g].sources[$s]" "$config_file")
                
                if [ "$source" != "null" ]; then
                    if [ "$preserve_name" = "true" ]; then
                        # Append the source directory name to the destination base
                        local source_name=$(get_basename "$source")
                        local dest="$dest_base/$source_name"
                    else
                        # Use destination base as-is (all sources merge into same directory)
                        local dest="$dest_base"
                    fi
                    
                    SOURCES+=("$source")
                    DESTINATIONS+=("$dest")
                fi
            done
        done
    fi
    
    if [ ${#SOURCES[@]} -eq 0 ]; then
        print_status $RED "ERROR: No transfers defined in configuration file"
        return 1
    fi
    
    print_status $GREEN "✓ Loaded ${#SOURCES[@]} transfer mappings"
    return 0
}

# Function to check if a directory exists
check_directory() {
    local dir_path=$1
    if [ ! -d "$dir_path" ]; then
        print_status $RED "ERROR: Directory $dir_path does not exist!"
        return 1
    fi
    return 0
}

# Function to verify transfer integrity
verify_transfer() {
    local source_dir=$1
    local dest_dir=$2
    
    print_status $BLUE "Verifying transfer integrity..."
    
    # Check if both directories exist
    if ! check_directory "$source_dir"; then
        print_status $RED "Source directory does not exist for validation"
        return 1
    fi
    
    if ! check_directory "$dest_dir"; then
        print_status $RED "Destination directory does not exist for validation"
        return 1
    fi
    
    # Compare directory sizes
    local source_size=$(du -s "$source_dir" 2>/dev/null | cut -f1)
    local dest_size=$(du -s "$dest_dir" 2>/dev/null | cut -f1)
    
    # Count files
    local source_files=$(find "$source_dir" -type f 2>/dev/null | wc -l)
    local dest_files=$(find "$dest_dir" -type f 2>/dev/null | wc -l)
    
    print_status $BLUE "Source size: $source_size blocks, Files: $source_files"
    print_status $BLUE "Destination size: $dest_size blocks, Files: $dest_files"
    
    if [ "$source_size" -eq "$dest_size" ] && [ "$source_files" -eq "$dest_files" ]; then
        print_status $GREEN "✓ Verification passed"
        return 0
    else
        print_status $RED "✗ Verification failed"
        return 1
    fi
}

# Function to transfer directory
transfer_directory() {
    local source_path=$1
    local dest_path=$2
    
    print_status $CYAN "→ Transferring: $(get_basename "$source_path")"
    print_status $BLUE "  From: $source_path"
    print_status $BLUE "  To: $dest_path"
    
    # Check if source directory exists
    if ! check_directory "$source_path"; then
        return 1
    fi
    
    # Create destination parent directory if it doesn't exist
    local dest_parent=$(dirname "$dest_path")
    mkdir -p "$dest_parent"
    
    # Transfer using rsync with progress and verification
    if rsync -av --progress "$source_path/" "$dest_path/"; then
        print_status $GREEN "✓ Transfer completed"
        return 0
    else
        print_status $RED "✗ Transfer failed"
        return 1
    fi
}

# Function to perform cleanup after successful transfer and validation
cleanup_source() {
    local source_path=$1
    
    print_status $YELLOW "Preparing to delete source directory: $source_path"
    
    read -p "Delete $source_path? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$source_path"
        print_status $GREEN "✓ Deleted $source_path"
        return 0
    else
        print_status $YELLOW "Skipped deletion of $source_path"
        return 1
    fi
}

# Function to process all transfers
process_transfers() {
    local mode=$1
    local successful_transfers=()
    local failed_transfers=()
    
    # Process each transfer mapping
    for ((i=0; i<${#SOURCES[@]}; i++)); do
        local source="${SOURCES[$i]}"
        local dest="${DESTINATIONS[$i]}"
        
        echo
        print_status $YELLOW "=== Transfer $((i+1)) of ${#SOURCES[@]} ==="
        
        local transfer_success=false
        local validation_success=false
        
        # Handle based on mode
        case $mode in
            $MODE_TRANSFER_ONLY)
                if transfer_directory "$source" "$dest"; then
                    transfer_success=true
                    successful_transfers+=("$source → $dest")
                else
                    failed_transfers+=("$source → $dest")
                fi
                ;;
                
            $MODE_VALIDATE_ONLY)
                if verify_transfer "$source" "$dest"; then
                    validation_success=true
                    successful_transfers+=("$source → $dest")
                else
                    failed_transfers+=("$source → $dest")
                fi
                ;;
                
            $MODE_BOTH)
                if transfer_directory "$source" "$dest"; then
                    transfer_success=true
                    echo
                    if verify_transfer "$source" "$dest"; then
                        validation_success=true
                        successful_transfers+=("$source → $dest")
                    else
                        failed_transfers+=("$source → $dest (validation failed)")
                    fi
                else
                    failed_transfers+=("$source → $dest (transfer failed)")
                fi
                ;;
        esac
    done
    
    # Summary
    echo
    print_status $BLUE "=== Summary ==="
    if [ ${#successful_transfers[@]} -gt 0 ]; then
        print_status $GREEN "Successful: ${#successful_transfers[@]}"
        for item in "${successful_transfers[@]}"; do
            print_status $GREEN "  ✓ $item"
        done
    fi
    
    if [ ${#failed_transfers[@]} -gt 0 ]; then
        print_status $RED "Failed: ${#failed_transfers[@]}"
        for item in "${failed_transfers[@]}"; do
            print_status $RED "  ✗ $item"
        done
    fi
    
    # Cleanup phase for successful transfers (validation mode or both mode)
    if [ "$mode" = "$MODE_VALIDATE_ONLY" ] || [ "$mode" = "$MODE_BOTH" ]; then
        if [ ${#successful_transfers[@]} -gt 0 ]; then
            echo
            print_status $YELLOW "=== Cleanup Phase ==="
            
            read -p "Do you want to delete successfully transferred source directories? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                for ((i=0; i<${#SOURCES[@]}; i++)); do
                    local source="${SOURCES[$i]}"
                    local dest="${DESTINATIONS[$i]}"
                    local mapping="$source → $dest"
                    
                    # Check if this transfer was successful
                    if [[ " ${successful_transfers[@]} " =~ " ${mapping} " ]]; then
                        if verify_transfer "$source" "$dest"; then
                            cleanup_source "$source"
                        fi
                    fi
                done
            else
                print_status $YELLOW "Cleanup skipped by user"
            fi
        fi
    fi
}

# Parse command line arguments
parse_arguments() {
    # Default mode
    SCRIPT_MODE=$MODE_BOTH
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--transfer)
                SCRIPT_MODE=$MODE_TRANSFER_ONLY
                shift
                ;;
            -v|--validate)
                SCRIPT_MODE=$MODE_VALIDATE_ONLY
                shift
                ;;
            -b|--both)
                SCRIPT_MODE=$MODE_BOTH
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                print_status $RED "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Main execution
main() {
    print_status $BLUE "=== Data Transfer Script ==="
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Load configuration
    if ! load_yaml_config "$CONFIG_FILE"; then
        exit 1
    fi
    
    # Display mode and transfer count
    print_status $BLUE "Mode: $SCRIPT_MODE"
    print_status $BLUE "Transfers to process: ${#SOURCES[@]}"
    echo
    
    # Show all mappings
    print_status $CYAN "Transfer mappings:"
    for ((i=0; i<${#SOURCES[@]}; i++)); do
        print_status $CYAN "  $((i+1)). ${SOURCES[$i]}"
        print_status $CYAN "      → ${DESTINATIONS[$i]}"
    done
    echo
    
    # Process transfers based on mode
    case $SCRIPT_MODE in
        $MODE_TRANSFER_ONLY)
            print_status $YELLOW "=== Transfer Only Mode ==="
            process_transfers $MODE_TRANSFER_ONLY
            echo
            print_status $YELLOW "Note: Run with -v option to validate the transfers"
            ;;
            
        $MODE_VALIDATE_ONLY)
            print_status $YELLOW "=== Validate Only Mode ==="
            process_transfers $MODE_VALIDATE_ONLY
            ;;
            
        $MODE_BOTH)
            print_status $YELLOW "=== Transfer and Validate Mode ==="
            process_transfers $MODE_BOTH
            ;;
    esac
    
    echo
    print_status $BLUE "=== Script Completed ==="
}

# Run the main function
main "$@"