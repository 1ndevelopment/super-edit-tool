# Super Edit Tool - Linux x86_64 Version

This is a converted version of the Super Edit tool designed to run on Linux x86_64 systems.

## Overview

The Super Edit tool allows you to work with Android super.img files on Linux systems. It provides functionality to:
- Extract and convert super.img files
- Mount and unmount partition images
- Create new ext4 images
- Convert between sparse and raw image formats
- Remove bloatware from mounted partitions

## Prerequisites

- Linux x86_64 system
- sudo access (for mounting/unmounting operations)
- ext4 filesystem support

## Installation

1. Ensure the script is executable:
   ```bash
   chmod +x super_edit.sh
   ```

2. Verify all required binaries are present in `bin/x86_64/`:
   - img2simg
   - simg2img
   - make_ext4fs
   - payload-dumper

## Usage

### Basic Usage

```bash
./super_edit.sh
```

### Debug Mode

```bash
./super_edit.sh debug
```

## Available Functions

1. **extract_img** - Extract partitions from super.img
2. **mount_img** - Mount extracted partition images
3. **unmount_img** - Unmount mounted partition images
4. **remove_bloat** - Remove applications from mounted partitions
5. **cleanup** - Clean up workspace and temporary files
6. **create_ext4_image** - Create new ext4 partition images
7. **convert_image** - Convert between sparse and raw image formats

## Working with super.img

1. Place your `super.img` file in the current directory
2. Run the script: `./super_edit.sh`
3. Choose option 1 to extract partitions
4. Use the available functions to work with the extracted partitions

## Image Conversion

The tool supports converting between sparse and raw image formats:
- **simg2img**: Converts sparse images to raw images
- **img2simg**: Converts raw images to sparse images

## Creating New Images

You can create new ext4 partition images with custom sizes using the `create_ext4_image` function.

## Limitations

- Boot image editing functionality is not implemented in the Linux version
- Some advanced super.img manipulation features require the original Android version
- The tool focuses on basic partition extraction, mounting, and image conversion

## Troubleshooting

- Ensure all binaries in `bin/x86_64/` are executable
- Check that you have sudo privileges for mount operations
- Verify that your system supports ext4 filesystems
- Make sure you have sufficient disk space for image operations

## Original Tool

This is a modified version of the original Super Edit tool by Jacy Kincade. The original Android version provides additional functionality for boot image editing and advanced super.img manipulation.

## License

GPL v3 - Same as the original tool
