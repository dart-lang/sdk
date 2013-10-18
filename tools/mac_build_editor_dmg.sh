#!/bin/bash
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by
# BSD-style license that can be found in the LICENSE file.

# This is partly based on
# https://bitbucket.org/rmacnak/nsvm/src/
#   b2de52432a2baff9c4ada099430fb16a771d34ef/vm/onebuild/installer-Darwin.gmk

# Fail if a command failed
set -e
set -o errexit
set -o nounset

if [ $# -ne 4 ]; then
  echo "Usage $0 <output.dmg> <raw-editor-bundle> <folder-icon> <volume-name>"
  exit 1
fi

OUTPUT_DMG_FILE=$1
INPUT_FOLDER_PATH=$2
FOLDER_ICON=$3
INPUT_VOLUME_NAME=$4

FOLDER_NAME="Dart"
VOLUME_MOUNTPOINT="/Volumes/$INPUT_VOLUME_NAME"
SPARSEIMAGE="$OUTPUT_DMG_FILE.sparseimage"

# Input validations
if [ ! -d "$INPUT_FOLDER_PATH" ]; then
  echo "Editor bundle folder does not exist ($INPUT_FOLDER_PATH)"
  exit 1
fi

# If an old image is still mounted, umount it
if [ -e "$VOLUME_MOUNTPOINT" ]; then
  hdiutil eject "$VOLUME_MOUNTPOINT"
fi

# Remove old output files
if [ -f "$SPARSEIMAGE" ]; then
  rm "$SPARSEIMAGE"
fi
if [ -f "$OUTPUT_DMG_FILE" ]; then
  rm "$OUTPUT_DMG_FILE"
fi

# This function will set (or replace) the icon of a folder.
# Finder displays a default folder icon. Since the installer
# will consist of a folder and a link to "/Applications", we want
# the folder to have a nice icon.
# In order to make Finder display a custom icon, we need to
#  - Have a "FOLDER/Icon\r" file which contains the icon resource
#    (i.e. the metadata of this file will contain an icon)
#  - Have the 'custom icon' attribute set on "FOLDER"
# Additionally we mark the "FOLDER/Icon\r" file as invisible, so it
# is not shown in Finder (although it's visible on the commandline).
replace_folder_icon() {
  FOLDER="$1"
  ICON="$2"
  TEMP_ICON_RESOURCE='/tmp/icns.rsrc'
  ICON_RESOURCE="$FOLDER"/$'Icon\r'

  # Add finder icon to the image file
  sips -i "$ICON" > /dev/null

  # Extract the finder icon resource
  DeRez -only icns "$ICON" > "$TEMP_ICON_RESOURCE"

  # Create the icon resource
  rm -f "$ICON_RESOURCE"
  Rez -append "$TEMP_ICON_RESOURCE" -o "$ICON_RESOURCE"
  rm "$TEMP_ICON_RESOURCE"

  # Set the 'custom icon' attribute on $FOLDER
  SetFile -a C "$FOLDER"

  # Make the $ICON_RESOURCE invisible for finder
  SetFile -a V "$ICON_RESOURCE"
}


# Create a new image and attach it
hdiutil create -size 400m -type SPARSE -volname "$INPUT_VOLUME_NAME" -fs \
  'Journaled HFS+' "$SPARSEIMAGE"
hdiutil attach "$SPARSEIMAGE"

# Add link to /Applications (so the user can drag-and-drop into it)
ln -s /Applications "$VOLUME_MOUNTPOINT/"
# Copy our application
ditto "$INPUT_FOLDER_PATH" "$VOLUME_MOUNTPOINT/$FOLDER_NAME"
# Set custom icon on this folder
replace_folder_icon "$VOLUME_MOUNTPOINT/$FOLDER_NAME" "$FOLDER_ICON"
# Make sure that the dmg gets opened when mounting the image
bless --folder "$VOLUME_MOUNTPOINT" --openfolder "$VOLUME_MOUNTPOINT"

# Use an applescript to setup the layout of the folder.
osascript << EOF
tell application "Finder"
  tell disk "$INPUT_VOLUME_NAME"
    open
    tell container window
      set current view to icon view
      set toolbar visible to false
      set statusbar visible to false
      set position to {100, 100}
      set bounds to {100, 100, 512, 256}
    end tell
    tell icon view options of container window
      set arrangement to not arranged
      set icon size to 128
    end tell
    set position of item "$FOLDER_NAME" to {64, 64}
    set position of item "Applications" to {320, 64}
    eject
  end tell
end tell
EOF

# Wait until the script above has umounted the image
while [ -e "$VOLUME_MOUNTPOINT" ]; do
  echo "Waiting for Finder to eject $VOLUME_MOUNTPOINT"
  sleep 2
done

# Compress the sparse image
hdiutil convert "$SPARSEIMAGE" -format UDBZ -o "$OUTPUT_DMG_FILE"

# Remove sparse image
rm "$SPARSEIMAGE"

