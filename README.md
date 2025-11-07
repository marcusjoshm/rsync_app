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

```sh
./rsync_app.sh [OPTIONS]
```

### Options

- `-t` &mdash; Transfer only mode
- `-v` &mdash; Validate only mode (no cleanup)
- `-d` &mdash; Cleanup mode (validate, then prompt for deletion)
- `-c <file>`, `--config <file>` &mdash; YAML config file (default: `rsync_config.yaml`)
- `-h`, `--help` &mdash; Show help message

#### Combined Options

- Options can be combined (e.g., `-tv`, `-vt`, `-ctvd`, `-td`, `-dt`)
- If both `-t` and `-d` are present (with or without `-v`), the full workflow is run: transfer, validate, and prompt for cleanup (default behavior)
- If only `-d` (or `-vd`, `-dv`) is present, only validation and cleanup are performed (no transfer)

#### Default Behavior

- **No arguments**: Transfer, validate, and prompt for cleanup (same as `-td` or `-dt`)

### Examples

```sh
./rsync_app.sh                      # Transfer, validate, and cleanup using default config
./rsync_app.sh -t                   # Transfer only
./rsync_app.sh -v                   # Validate only
./rsync_app.sh -d                   # Validate and prompt for cleanup only
./rsync_app.sh -td                  # Transfer, validate, and cleanup (same as default)
./rsync_app.sh -ctvd myconfig.yaml  # Transfer, validate, and cleanup with custom config
```

### Operation Modes

1. **Transfer Only Mode** (`-t`): Copies data from source to destination without validation
2. **Validate Only Mode** (`-v`): Checks if existing transfers are complete and accurate
3. **Both Mode** (`-b` or default): Transfers data and then validates the transfer

## Configuration

The script supports two configuration methods: **CSV (recommended for most users)** or **YAML (for advanced users)**.

### Method 1: CSV Configuration (Recommended)

**Perfect for users familiar with spreadsheets!** Edit transfers in Excel, Numbers, Google Sheets, or any spreadsheet application.

#### Quick Start with CSV

1. **Edit the CSV file** (`rsync_sources.csv`):
   ```csv
   source,destination
   /Volumes/SOURCE/data,/Volumes/BACKUP/data
   /Volumes/LAB/experiment,/Volumes/ARCHIVE/experiment
   ```

2. **Generate the config**:
   ```bash
   ./config_builder.sh
   ```

3. **Run the transfer**:
   ```bash
   ./rsync_app.sh
   ```

#### CSV Format

- **Header row required**: `source,destination`
- **One transfer per row**: Each row defines a source → destination transfer
- **Comments**: Rows starting with `#` are ignored
- **Empty rows**: Automatically skipped
- **Editing**: Open `rsync_sources.csv` in any spreadsheet application, save as CSV

#### CSV Configuration Builder

The `config_builder.sh` script converts your CSV file into the required YAML format:

```bash
./config_builder.sh [OPTIONS]

Options:
  -i, --input <file>    CSV input file (default: rsync_sources.csv)
  -o, --output <file>   YAML output file (default: rsync_config.yaml)
  -h, --help            Show help message
```

**Examples:**
```bash
# Use default files (rsync_sources.csv → rsync_config.yaml)
./config_builder.sh

# Use custom CSV file
./config_builder.sh -i my_transfers.csv

# Specify both input and output
./config_builder.sh -i transfers.csv -o custom_config.yaml
```

The builder will:
- ✓ Validate CSV format
- ✓ Check if source directories exist (warnings only)
- ✓ Show preview of generated configuration
- ✓ Prompt before overwriting existing config files

---

### Method 2: YAML Configuration (Advanced)

For advanced users who prefer direct YAML editing.

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

### CSV Workflow (Recommended for Most Users)
1. Open `rsync_sources.csv` in Excel, Numbers, or Google Sheets
2. Add your source and destination paths (one transfer per row)
3. Save as CSV
4. Generate config: `./config_builder.sh`
5. Run transfer: `./rsync_app.sh`
6. Review summary and optionally delete source files when prompted

### Spreadsheet-Based Batch Workflow
1. Create a spreadsheet with columns: `source`, `destination`
2. Fill in multiple transfers (as many rows as needed)
3. Export/Save as CSV (`rsync_sources.csv`)
4. Build config: `./config_builder.sh`
5. Run transfers: `./rsync_app.sh`
6. Script processes all transfers sequentially
7. Review summary and cleanup successful transfers

### YAML Workflow (Advanced Users)
1. Copy the example configuration: `cp rsync_config.example.yaml rsync_config.yaml`
2. Edit the configuration file with your transfer settings
3. Run transfer and validation: `./rsync_app.sh`
4. Review summary
5. Optionally delete source files when prompted

### Cautious Workflow
1. Set up your configuration (CSV or YAML method)
2. Transfer only: `./rsync_app.sh -t`
3. Manually verify some files
4. Validate: `./rsync_app.sh -v`
5. Delete sources if validation passes

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