#!/bin/bash
# Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by
# BSD-style license that can be found in the LICENSE file.

# Fail if a command failed
set -e

if [ $# -ne 5 ]; then
  echo "Usage $0 <app-folder> <editor-build-directory> <dart-sdk> " \
       "<Chromium.app> <icon.icns>"
  exit 1
fi

OUTPUT_APP_FOLDER=$1
INPUT_EDITOR_BUILD_DIRECTORY=$2
INPUT_DART_SDK_DIRECTORY=$3
INPUT_CHROMIUM_APP_DIRECTORY=$4
INPUT_ICON_PATH=$5

# Input validations
if [ "${OUTPUT_APP_FOLDER##*.}" != "app" ]; then
  echo "Application folder has to end in '.app' " \
       "(but was $APP_FOLDER_NAME)."
  exit 1
fi
if [ "${INPUT_ICON_PATH##*.}" != "icns" ]; then
  echo "Application icon has to end in '.icns'."
  exit 1
fi

function ensure_exists {
  if [ ! -e "$1" ]; then
    echo "Directory or file does not exist: $1."
    exit 1
  fi
}
ensure_exists "$INPUT_EDITOR_BUILD_DIRECTORY"
ensure_exists "$INPUT_DART_SDK_DIRECTORY"

# Remove old directory if present
if [ -e "$OUTPUT_APP_FOLDER" ]; then
  rm -r "$OUTPUT_APP_FOLDER"
fi

# Make directory structure and copy necessary files
mkdir -p "$OUTPUT_APP_FOLDER/Contents/MacOS"
LAUNCHER_SUBPATH="DartEditor.app/Contents/MacOS/DartEditor"
cp "$INPUT_EDITOR_BUILD_DIRECTORY/$LAUNCHER_SUBPATH" \
   "$OUTPUT_APP_FOLDER/Contents/MacOS/"
cp "$INPUT_EDITOR_BUILD_DIRECTORY/$LAUNCHER_SUBPATH.ini" \
   "$OUTPUT_APP_FOLDER/Contents/MacOS/"
mkdir -p "$OUTPUT_APP_FOLDER/Contents/Resources"
cp "$INPUT_ICON_PATH" "$OUTPUT_APP_FOLDER/Contents/Resources/dart.icns"
cp -R "$INPUT_DART_SDK_DIRECTORY" \
      "$OUTPUT_APP_FOLDER/Contents/Resources/dart-sdk"
cp -R "$INPUT_CHROMIUM_APP_DIRECTORY" \
   "$OUTPUT_APP_FOLDER/Contents/Resources/Chromium.app"
for dirname in $(echo configuration plugins features samples); do
  cp -R "$INPUT_EDITOR_BUILD_DIRECTORY/$dirname" \
        "$OUTPUT_APP_FOLDER/Contents/Resources/"
done

EQUINOX_LAUNCHER_JARFILE=$(cd "$OUTPUT_APP_FOLDER"; \
  ls Contents/Resources/plugins/org.eclipse.equinox.launcher_*.jar);

EQUINOX_LAUNCHER_LIBRARY=$(cd "$OUTPUT_APP_FOLDER"; ls \
  Contents/Resources/plugins/org.eclipse.equinox.launcher.cocoa.*/eclipse_*.so);

cat > "$OUTPUT_APP_FOLDER/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
          "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>NSHighResolutionCapable</key>
      <true/>
    <key>CFBundleExecutable</key>
      <string>DartEditor</string>
    <key>CFBundleGetInfoString</key>
      <string>Eclipse 3.7 for Mac OS X, Copyright IBM Corp. and others 2002,
              2011. All rights reserved.</string>
    <key>CFBundleIconFile</key>
      <string>dart.icns</string>
    <key>CFBundleIdentifier</key>
      <string>org.eclipse.eclipse</string>
    <key>CFBundleInfoDictionaryVersion</key>
      <string>6.0</string>
    <key>CFBundleName</key>
      <string>DartEditor</string>
    <key>CFBundlePackageType</key>
      <string>APPL</string>
    <key>CFBundleShortVersionString</key>
      <string>3.7</string>
    <key>CFBundleSignature</key>
      <string>????</string>
    <key>CFBundleVersion</key>
      <string>3.7</string>
    <key>CFBundleDevelopmentRegion</key>
      <string>English</string>
    <key>CFBundleLocalizations</key>
      <array>
        <string>en</string>
        <key>WorkingDirectory</key>
        <string>\$APP_PACKAGE/Contents/Resources</string>
      </array>
    <key>Eclipse</key>
      <array>
        <string>-startup</string>
        <string>\$APP_PACKAGE/$EQUINOX_LAUNCHER_JARFILE</string>
        <string>--launcher.library</string>
        <string>\$APP_PACKAGE/$EQUINOX_LAUNCHER_LIBRARY</string>
        <string>-keyring</string><string>~/.eclipse_keyring</string>
        <string>-showlocation</string>
        <key>WorkingDirectory</key>
        <string>\$APP_PACKAGE/Contents/Resources</string>
      </array>
  </dict>
</plist>
EOF

