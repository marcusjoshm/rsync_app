# Data Transfer Script

A robust bash script for transferring, validating, and managing data transfers between directories with support for batch operations and YAML configuration.

## Features

- **Flexible Transfer Modes**: Transfer only, validate only, or both
- **YAML Configuration**: Easy-to-read configuration format
- **Grouped Transfers**: Transfer multiple sources to a common destination
- **Progress Tracking**: Real-time transfer progress with rsync
- **Transfer Validation**: Verify transfers by comparing file counts and sizes
- **Safe Cleanup**: Optional source deletion after successful validation
- **Colored Output**: Clear, color-coded status messages
- **Batch Processing**: Handle multiple transfers in a single run

## Prerequisites

- **Bash**: Version 4.0 or higher
- **rsync**: For efficient file transfers
- **yq**: For parsing YAML configuration files

### Installing yq

**macOS:**
```bash
brew install yq
```

**Linux:**
```bash
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
chmod +x /usr/bin/yq
```

## Installation

1. Download the script and make it executable:
```bash
chmod +x rsync_app.sh
```

2. Create a configuration file named `rsync_config.yaml` in the same directory as the script:
```bash
# Copy the example configuration file as a template
cp rsync_config.example.yaml rsync_config.yaml

# Edit the configuration file with your transfer settings
nano rsync_config.yaml  # or use your preferred editor
```

The `rsync_config.example.yaml` file includes examples of both individual and grouped transfers to help you get started.

## Usage

### Basic Commands

```bash
# Transfer and validate (default mode) - uses rsync_config.yaml
./rsync_app.sh

# Transfer only - uses rsync_config.yaml
./rsync_app.sh -t
./rsync_app.sh --transfer

# Validate only - uses rsync_config.yaml
./rsync_app.sh -v
./rsync_app.sh --validate

# Use custom configuration file
./rsync_app.sh -c my_config.yaml

# Show help
./rsync_app.sh -h
./rsync_app.sh --help
```

### Operation Modes

1. **Transfer Only Mode** (`-t`): Copies data from source to destination without validation
2. **Validate Only Mode** (`-v`): Checks if existing transfers are complete and accurate
3. **Both Mode** (`-b` or default): Transfers data and then validates the transfer

## Configuration

The script uses YAML configuration files to define transfer operations. By default, it looks for `rsync_config.yaml` in the current directory. 

**Getting Started**: Use the included `rsync_config.example.yaml` as a template:
```bash
cp rsync_config.example.yaml rsync_config.yaml
```

You can use two approaches for defining transfers:

### Approach 1: Individual Transfers

For explicit source-to-destination mappings:

```yaml
transfers:
  - source: /Volumes/SOURCE/project_A
    destination: /Volumes/BACKUP/projects/project_A_backup
    
  - source: /Volumes/DATA/experiment_001
    destination: /Volumes/ARCHIVE/2025/experiment_001_archived
```

### Approach 2: Grouped Transfers

For multiple sources going to a common destination:

```yaml
transfer_groups:
  # Example 1: Multiple experiments to archive
  - destination_base: /Volumes/ARCHIVE/2025_experiments
    preserve_source_name: true
    sources:
      - /Volumes/LAB/exp_20250101
      - /Volumes/LAB/exp_20250115
      - /Volumes/LAB/exp_20250201
  
  # Example 2: Consolidate from multiple locations
  - destination_base: /Volumes/CENTRAL/all_data
    preserve_source_name: true
    sources:
      - /Volumes/DRIVE_A/data
      - /Volumes/DRIVE_B/data
      - /Volumes/DRIVE_C/data
```

### Mixed Configuration

You can combine both approaches in a single file:

```yaml
# Individual transfers
transfers:
  - source: /Volumes/OLD/special_case
    destination: /Volumes/NEW/renamed_special_case

# Grouped transfers
transfer_groups:
  - destination_base: /Volumes/BACKUP/bulk_transfer
    preserve_source_name: true
    sources:
      - /Volumes/DATA/folder1
      - /Volumes/DATA/folder2
```

### Configuration Options

- **`preserve_source_name`**: 
  - `true` (default): Appends the source directory name to the destination base
  - `false`: All sources in the group transfer directly into the destination base

## Examples

### Example 1: Simple Backup

**Config file (`rsync_config.yaml`):**
```yaml
transfers:
  - source: /Users/john/Documents/important_project
    destination: /Volumes/BACKUP/john_backup/important_project
```

**Setup and Command:**
```bash
# Copy the example template
cp rsync_config.example.yaml rsync_config.yaml

# Edit with your paths
nano rsync_config.yaml

# Run the transfer
./rsync_app.sh
```

**Or with custom config file:**
```bash
./rsync_app.sh -c backup.yaml
```

### Example 2: Lab Data Organization

**Config file (`rsync_config.yaml`):**
```yaml
transfer_groups:
  # Raw data to NX-01-A/1
  - destination_base: /Volumes/NX-01-A/1
    preserve_source_name: true
    sources:
      - /Volumes/LEELAB/JM_Data/raw_data/2025-06-24_export
      - /Volumes/LEELAB/JM_Data/raw_data/2025-06-21_export/U2OS_TAOK2_transfection_As
      
  # Processed data to NX-01-A/2
  - destination_base: /Volumes/NX-01-A/2
    preserve_source_name: true
    sources:
      - /Volumes/LEELAB/JM_Data/processed/2025-06-10_analysis
      - /Volumes/LEELAB/JM_Data/processed/2025-06-10_analysis_v2
```

**Setup and Command:**
```bash
# Copy the example template
cp rsync_config.example.yaml rsync_config.yaml

# Edit with your lab data paths
nano rsync_config.yaml

# Run the transfer
./rsync_app.sh
```

### Example 3: Validation After Manual Transfer

If you've already transferred files manually or with another tool:

```bash
# Just validate existing transfers using default config
./rsync_app.sh -v

# Or with custom config file
./rsync_app.sh -v -c previous_transfer.yaml
```

## Workflow Examples

### Standard Workflow
1. Copy the example configuration: `cp rsync_config.example.yaml rsync_config.yaml`
2. Edit the configuration file with your transfer settings
3. Run transfer and validation: `./rsync_app.sh`
4. Review summary
5. Optionally delete source files when prompted

### Cautious Workflow
1. Copy the example configuration: `cp rsync_config.example.yaml rsync_config.yaml`
2. Edit the configuration file with your transfer settings
3. Transfer only: `./rsync_app.sh -t`
4. Manually verify some files
5. Validate: `./rsync_app.sh -v`
6. Delete sources if validation passes

### Batch Processing Workflow
1. Copy the example configuration: `cp rsync_config.example.yaml rsync_config.yaml`
2. Edit the configuration file with multiple transfer groups
3. Run: `./rsync_app.sh`
4. Script processes all transfers sequentially
5. Review summary of all successes/failures
6. Cleanup successful transfers

## Output and Logging

The script provides color-coded output:
- 🔵 **Blue**: Information messages
- 🟨 **Yellow**: Processing steps
- 🟢 **Green**: Success messages
- 🔴 **Red**: Error messages
- 🔷 **Cyan**: Transfer details

### Sample Output
```
=== Data Transfer Script ===
Mode: both
Transfers to process: 3

Transfer mappings:
  1. /Volumes/SOURCE/data1
      → /Volumes/DEST/backup/data1
  2. /Volumes/SOURCE/data2
      → /Volumes/DEST/backup/data2

=== Transfer 1 of 3 ===
→ Transferring: data1
  From: /Volumes/SOURCE/data1
  To: /Volumes/DEST/backup/data1
[rsync progress output]
✓ Transfer completed

Verifying transfer integrity...
Source size: 1024 blocks, Files: 42
Destination size: 1024 blocks, Files: 42
✓ Verification passed
```

## Safety Features

1. **Pre-transfer Validation**: Checks if source directories exist
2. **Transfer Verification**: Compares file counts and sizes
3. **Cleanup Confirmation**: Always asks before deleting source files
4. **Individual File Cleanup**: Option to selectively delete sources
5. **Error Handling**: Script stops on critical errors

## Troubleshooting

### Common Issues

**"yq is not installed"**
- Install yq using the instructions in Prerequisites

**"Directory does not exist"**
- Verify the source path is correct and accessible
- Check if external drives are mounted

**"Verification failed"**
- Check available space on destination
- Ensure no files were modified during transfer
- Try running validation again

**"Permission denied"**
- Run with appropriate permissions
- Check file ownership and permissions

### Tips

1. **Test First**: Use a small test directory to verify your configuration
2. **Check Space**: Ensure destination has enough free space
3. **Preserve Paths**: Use full absolute paths in configuration
4. **Incremental Transfers**: The script uses rsync, so interrupted transfers can be resumed

## Advanced Usage

### Custom Configuration Location
Store configurations in a dedicated directory:
```bash
mkdir ~/transfer_configs
cp rsync_config.example.yaml ~/transfer_configs/weekly_backup.yaml
# Edit the copied file
nano ~/transfer_configs/weekly_backup.yaml
./rsync_app.sh -c ~/transfer_configs/weekly_backup.yaml
```

### Scheduling with Cron
Add to crontab for automated transfers:
```bash
# Weekly backup every Sunday at 2 AM
0 2 * * 0 /path/to/rsync_app.sh -c /path/to/weekly_backup.yaml
```

### Integration with Other Scripts
```bash
#!/bin/bash
# Pre-transfer tasks
echo "Preparing for transfer..."

# Run transfer
/path/to/rsync_app.sh -t -c config.yaml

# Post-transfer tasks
if [ $? -eq 0 ]; then
    echo "Transfer successful, running post-processing..."
fi
```

## License

This script is provided as-is for data transfer operations. Use at your own risk and always maintain backups.

## Contributing

Feel free to submit issues, fork, and create pull requests for any improvements.