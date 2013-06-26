#!/bin/bash
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by
# BSD-style license that can be found in the LICENSE file.

# This is partly based on
# https://bitbucket.org/rmacnak/nsvm/src/
#   b2de52432a2baff9c4ada099430fb16a771d34ef/vm/onebuild/installer-Darwin.gmk

# Fail if a command failed
set -e

if [ $# -ne 4 ]; then
  echo "Usage $0 <output.dmg> <app-folder> <icon.icns> <volume-name>"
  exit 1
fi

OUTPUT_DMG_FILE=$1
INPUT_APP_FOLDER_PATH=$2
INPUT_ICON=$3
INPUT_VOLUME_NAME=$4

APP_FOLDER_NAME=$(basename "$INPUT_APP_FOLDER_PATH")
VOLUME_MOUNTPOINT="/Volumes/$INPUT_VOLUME_NAME"
SPARSEIMAGE="$OUTPUT_DMG_FILE.sparseimage"

# Input validations
if [ "${INPUT_APP_FOLDER_PATH##*.}" != "app" ]; then
  echo "Application folder has to end in '.app' " \
       "(but was $INPUT_APP_FOLDER_PATH)."
  exit 1
fi
if [ "${INPUT_ICON##*.}" != "icns" ]; then
  echo "Volume icon has to end in '.icns'."
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

# Create a new image and attach it
hdiutil create -size 300m -type SPARSE -volname "$INPUT_VOLUME_NAME" -fs \
  'Journaled HFS+' "$SPARSEIMAGE"
hdiutil attach "$SPARSEIMAGE"

# Add link to /Applications (so the user can drag-and-drop into it)
ln -s /Applications "$VOLUME_MOUNTPOINT/"
# Copy our application
ditto "$INPUT_APP_FOLDER_PATH" "$VOLUME_MOUNTPOINT/$APP_FOLDER_NAME"
# Make sure that the folder gets opened when mounting the image
bless --folder "$VOLUME_MOUNTPOINT" --openfolder "$VOLUME_MOUNTPOINT"
# Copy the volume icon
cp "$INPUT_ICON" "$VOLUME_MOUNTPOINT/.VolumeIcon.icns"

# Set the 'custom-icon' attribute on the volume
SetFile -a C "$VOLUME_MOUNTPOINT"

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
		set position of item "$APP_FOLDER_NAME" to {64, 64}
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

