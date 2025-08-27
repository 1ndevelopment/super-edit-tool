#!/bin/bash
#
# Script Name: Super Editor
# Author: Jacy Kincade (1ndevelopment@protonmail.com)
# Modified for x86_64 Linux
#
# License: GPL
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.
#
# Description: Edit the partitions within the super.img
#

# Set script directory and binary paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin/x86_64"
IMG2SIMG="$BIN_DIR/img2simg"
SIMG2IMG="$BIN_DIR/simg2img"
MAKE_EXT4FS="$BIN_DIR/make_ext4fs"
PAYLOAD_DUMPER="$BIN_DIR/payload-dumper"

# Initialize variables
LOG_FILE="super_edit.log"
HASH_FILE="super_hash.txt"
STATUS=""
ARCH="x86_64"
DISPLAY_HASH=""
init_job=0

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if binaries exist
check_binaries() {
    local missing_bins=()
    
    if [ ! -x "$IMG2SIMG" ]; then
        missing_bins+=("img2simg")
    fi
    
    if [ ! -x "$SIMG2IMG" ]; then
        missing_bins+=("simg2img")
    fi
    
    if [ ! -x "$MAKE_EXT4FS" ]; then
        missing_bins+=("make_ext4fs")
    fi
    
    if [ ! -x "$PAYLOAD_DUMPER" ]; then
        missing_bins+=("payload-dumper")
    fi
    
    if [ ${#missing_bins[@]} -gt 0 ]; then
        echo "Error: Missing required binaries: ${missing_bins[*]}"
        echo "Please ensure all binaries are present in $BIN_DIR"
        exit 1
    fi
    
    ##echo -e "\nRequired binaries found."
}

# Function to extract super.img using alternative method
extract_super_alternative() {
    echo "Using alternative extraction method for super.img..."
    
    # Create extracted directory
    mkdir -p ./extracted
    
    # Try to use simg2img to convert sparse image to raw
    if [ -f "./super.img" ]; then
        echo "Converting super.img to raw format..."
        lpunpack ./super.img ./extracted/
        
        if [ $? -eq 0 ]; then
            echo "Successfully converted super.img to raw format"
            echo "Note: This creates a raw image that may need further processing"
            echo "You may need to use additional tools to extract individual partitions"
            init_job=1
        else
            echo "Failed to convert super.img"
            init_job=2
        fi
    else
        echo "No super.img found"
        init_job=2
    fi
}

# Function to create a new ext4 image
create_ext4_image() {
    echo "Creating new ext4 image..."
    echo -n "Enter image name (without .img extension): " && read -r img_name
    echo -n "Enter size in MB: " && read -r size_mb
    
    if [ -n "$img_name" ] && [ -n "$size_mb" ]; then
        local size_bytes=$((size_mb * 1024 * 1024))
        local output_file="./extracted/${img_name}.img"
        
        echo "Creating ${size_mb}MB ext4 image: $output_file"
        "$MAKE_EXT4FS" -l "${size_bytes}" "$output_file"
        
        if [ $? -eq 0 ]; then
            echo "Successfully created $output_file"
        else
            echo "Failed to create ext4 image"
        fi
    else
        echo "Invalid input"
    fi
}

# Function to convert between sparse and raw images
convert_image() {
    echo "Image conversion tools:"
    echo "1) Convert sparse to raw (simg2img)"
    echo "2) Convert raw to sparse (img2simg)"
    echo "b) Back to main menu"
    
    echo -n "Choice: " && read -r choice
    
    case "$choice" in
        1)
            echo -n "Enter sparse image path: " && read -r input_file
            if [ -f "$input_file" ]; then
                local output_file="${input_file%.*}_raw.img"
                echo "Converting $input_file to $output_file..."
                "$SIMG2IMG" "$input_file" "$output_file"
                if [ $? -eq 0 ]; then
                    echo "Conversion successful: $output_file"
                else
                    echo "Conversion failed"
                fi
            else
                echo "File not found: $input_file"
            fi
            ;;
        2)
            echo -n "Enter raw image path: " && read -r input_file
            if [ -f "$input_file" ]; then
                local output_file="${input_file%.*}_sparse.img"
                echo "Converting $input_file to $output_file..."
                "$IMG2SIMG" "$input_file" "$output_file"
                if [ $? -eq 0 ]; then
                    echo "Conversion successful: $output_file"
                else
                    echo "Conversion failed"
                fi
            else
                echo "File not found: $input_file"
            fi
            ;;
        b)
            return
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
}

cleanup() {
  echo -e "\nCleaning up workspace...\n"
  clean() { 
    local i="$1"
    for o in $i; do 
      [ -e "$o" ] && rm -rf "$o" 2>/dev/null
    done
  }
  
  clean "./$LOG_FILE ./$HASH_FILE ./.tmp.* ./._"
  clean "./extracted ./mounted ./out"
  echo -e "\nCleanup completed."
  main_menu
}

list_partitions() { 
  echo "Listing partitions is not available on Linux without device connection"
  echo "Use 'lsblk' or 'fdisk -l' to see available block devices"
}

extract_img() {
## Extract super or sub-partitions of super
  if [ -f "./super.img" ]; then
      [ "$start_option" = debug ] && { STATUS="\nInitialized in Debug Mode.\n\nFound super.img" ; } || STATUS="\nInitialized.\n\nFound super.img."
      if ls ./extracted/*.img 2>/dev/null; then
          STATUS+="\nImages are located in ./extracted \n" && [ "$init_job" -eq 1 ] && { init_job=0 && main_menu ; }
      else
          STATUS+="\nNo partitions have been extracted.\n" && [ "$init_job" -eq 2 ] && { init_job=0 && main_menu ; }
      fi
      echo -n -e "Extract partitions from super.img ? [y/N]: " && read -r input && echo ""
      case "$input" in
          y) echo -e "\nExtracting partitions from super.img...\n" && extract_super_alternative ;;
          n) init_job=2 ; main_menu ;;
          *) main_menu ;;
      esac
  else
      [ "$start_option" = debug ] && { STATUS="\nInitialized in Debug Mode.\n\nNo super.img found." ; } || STATUS="\nInitialized.\n\nNo super.img found."
      echo -e "\nNo super.img found in current directory."
      echo -e "Please place a super.img file in the current directory to continue."
      main_menu
  fi
}

mount_img() {
## Mount images from ./extracted/ onto ./mounted/system
  mkdir -p ./mounted/system/vendor ./mounted/system/product ./extracted 2>/dev/null
  mount() {
    LOOP_DEVICE=$(losetup -f)
    sudo losetup "$LOOP_DEVICE" "./extracted/$IMG_NAME.img"
    sudo mount -t ext4 -o rw "$LOOP_DEVICE" "$MOUNT_POINT"
    if mountpoint -q "$MOUNT_POINT"; then
      echo -e "\n$IMG_NAME mounted successfully at: $MOUNT_POINT\n"
      main_menu
    else
      printf '\nFailed to mount the image\n'
      mount_img
    fi
  }
  
  echo "What partition would you like to mount?"
  echo -e "\nMountable partitions:\n" && ls -1 ./extracted 2>/dev/null | sed -e 's/\.img$//'
  echo -n -e "\nb) Main Menu\n\n>> " && read -r IMG_NAME && echo ""
  case "$IMG_NAME" in
    system*) MOUNT_POINT="./mounted/system" && mount ;;
    vendor*) MOUNT_POINT="./mounted/system/vendor" && mount ;;
    product*) MOUNT_POINT="./mounted/system/product" && mount ;;
    [qb]) echo -e "\nHeading back to Main Menu...\n" && main_menu ;;
    *) echo -e "\nUnknown image name: $IMG_NAME\n" && mount_img ;;
  esac
}

remove_bloat() {
## Remove apps from super sub-partitions
  func() {
    apps() { ls -1 "./mounted/system/$INPUT/app" 2>/dev/null; } && APPS=$(apps)
    echo "What apps would you like to remove from $INPUT?" && echo "" && apps
    echo -n -e "\nb) Change Partition\nq) Main Menu\n\n>> "
    read -r APP_NAME && echo ""
    
    case "$APP_NAME" in
      b) remove_bloat ;; 
      q) echo "Heading back to Main Menu..." && main_menu ;;
      *) 
        if [ -d "./mounted/system/$INPUT/app/$APP_NAME" ]; then
          echo -e "\nRemoving $APP_NAME..."
          rm -rf "./mounted/system/$INPUT/app/$APP_NAME"
          echo "Successfully removed $APP_NAME"
          func
        else
          echo "App '$APP_NAME' not found. Please try again."
          func
        fi
        ;;
    esac
  }
  
  # Get mounted images
  MOUNTED_IMGS=""
  if mountpoint -q "./mounted/system"; then MOUNTED_IMGS+="system "; fi
  if mountpoint -q "./mounted/system/vendor"; then MOUNTED_IMGS+="vendor "; fi
  if mountpoint -q "./mounted/system/product"; then MOUNTED_IMGS+="product "; fi
  
  echo "What partition would you like to remove bloat from?"
  echo -n -e "\nCurrently mounted:\n\n$MOUNTED_IMGS\n\nb) Main Menu\n\n>> "
  read -r INPUT && echo ""
  case "$INPUT" in
    system*) func ;; vendor*) func ;; product*) func ;;
    [qb]) echo -e "\nHeading back to Main Menu...\n" && main_menu ;;
    *) echo -e "\nUnknown image name: $INPUT\n" && remove_bloat ;;
  esac
}

unmount_img() {
## Unmount chosen .img from mount point
  unmount() {
    while ! sudo umount "$MOUNT_POINT" 2>/dev/null; do 
      echo -e "\nAttempting to unmount $IMG_NAME from $MOUNT_POINT\n"
      sleep 1
    done
    echo -e "\nSuccessfully unmounted $IMG_NAME from $MOUNT_POINT\n"
    main_menu
  }
  
  echo "What partition would you like to unmount?"
  echo -e "\nCurrently mounted:\n"
  
  # Get mounted images
  MOUNTED_IMGS=""
  if mountpoint -q "./mounted/system"; then MOUNTED_IMGS+="system "; fi
  if mountpoint -q "./mounted/system/vendor"; then MOUNTED_IMGS+="vendor "; fi
  if mountpoint -q "./mounted/system/product"; then MOUNTED_IMGS+="product "; fi
  
  echo "$MOUNTED_IMGS"
  echo -n -e "\nb) Main Menu\n\n>> " && read -r IMG_NAME
  case "$IMG_NAME" in
    system*) export MOUNT_POINT="$(pwd)/mounted/system" && unmount ;;
    vendor*) export MOUNT_POINT="$(pwd)/mounted/system/vendor" && unmount ;;
    product*) export MOUNT_POINT="$(pwd)/mounted/system/product" && unmount ;;
    [qb]) echo -e "\nHeading back to Main Menu...\n" && main_menu ;;
    *) echo -e "\nUnknown mount directory:\n$IMG_NAME" && unmount_img ;;
  esac
}

make_super() {
## Generate lpmake command from super & its sub-partitions
  echo "make_super function not implemented for Linux version"
  echo "Please use the original Android version for this functionality"
  main_menu
}

edit_boot_img() {
  RPWD="$(pwd)/extracted/AIK"
  unpack() {
    echo "Boot image editing not implemented for Linux version"
    echo "Please use the original Android version for this functionality"
    prompt
  }

  repack() {
    echo "Boot image repacking not implemented for Linux version"
    echo "Please use the original Android version for this functionality"
    prompt
  }
  
  prompt() {
    echo "" && echo "AIK Boot Image Editor"
    echo -n -e "\n1] Unpack ramdisk from boot.img\n2] Repack ramdisk into boot.img\n3] List contents of boot.img\n\nb] Main Menu\n\n>> " && read -r i && echo ""
    case "$i" in
        1) unpack ;; 2) repack ;;
        3) ls -1 "$RPWD/split/" "$RPWD/ramdisk/" 2>/dev/null && prompt ;;
        b) echo "Heading back to Main Menu...\n" && main_menu ;;
        q) echo "Quitting..." && exit 0 ;;
        *) echo "Invalid choice, try again.\n" && prompt ;;
    esac
  }
  prompt
}

options_list() {
  func_acl() {
    ## Function access control - simplified for Linux version
    echo "extract_img mount_img unmount_img remove_bloat cleanup create_ext4_image convert_image"
  }
  options=$($1) ; user_input="true"
  echo -e "\nAvailable options:\n"
  i=1
  for option in $options; do { echo "$i) $option" && i=$((i + 1)) ; } done
  echo -n -e "\nq) Quit\n\n>> "
  read -r func_name && echo ""
  [ "$func_name" = "q" ] && { echo -e "\nExiting..." && exit 0 ; }
  if [ "$func_name" -eq "$func_name" ] 2>/dev/null; then
    if [ "$func_name" -ge 1 ] && [ "$func_name" -le "$i" ]; then
      j=1
      for option in $options; do
      [ "$j" = "$func_name" ] && { func_name=$option && break ; }
      j=$((j + 1))
      done
    fi
  fi
  for option in $options; do [ "$func_name" = "$option" ] && { run_function "$func_name" && return ; } done
  echo "Invalid choice. Please try again.\n"
  user_input="false"
}

main_menu() {
  run_function() { func_name="$1" ; shift ; "$func_name" "$@" ; }
  echo -e "\nSuper Edit v0.2 - Main Menu (Linux $ARCH)"
  options_list func_acl
  if [ "$user_input" = "false" ]; then
    echo "Invalid choice. Please try again."
    main_menu
  fi
}

file_check() {
  if [ -f "./super.img" ]; then
    if ls ./extracted/*.img >/dev/null 2>&1; then
      init_job=1
    else
      init_job=2
    fi
    extract_img
    return 0
  else
    echo -n -e "\nNo super.img found within super-edit !\n\n1] Continue without using a super.img\n2] Pull or use super.img from device\nq] Quit super-edit\n\nChoice: " && read -r i
    echo "" && case "$i" in
        1) main_menu ;; 2) extract_img ;; q) exit 0 ;; esac
  fi
}

init() { 
  check_binaries
  [ "$start_option" = debug ] && { start_option="debug" ; echo "Debug mode enabled" ; }
  file_check 
  main_menu 
}

## Start Options
start_option="$1"
## Run Super Edit
init

##
## ./super_edit.sh debug
##
## init -> check_binaries -> file_check -> extract_img -> main_menu
##
