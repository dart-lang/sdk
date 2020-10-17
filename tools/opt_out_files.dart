#!/usr/bin/env dart

// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

final commentLine = RegExp(r'^///?');
final scriptLine = RegExp(r'^#\!');
final languageMarker = RegExp(r"^\s*//\s*@dart\s*=");

void main(List<String> args) {
  if (args.length < 1) {
    print('Mark files passed on the command line or under a directory');
    print(' passed on the command line as opted out of null safety.  Does');
    print(' not mark files under directories containing a pubspec.yaml file');
    print(' unless the file is specified explicitly in the argument list.');
    print(' Ignores files not ending in ".dart".');
    print('Usage: opt_files_out.dart <files or directories>');
    return;
  }
  for (var name in args) {
    switch (FileSystemEntity.typeSync(name)) {
      case FileSystemEntityType.directory:
        markDirectory(Directory(name));
        break;
      case FileSystemEntityType.file:
        markFile(File(name));
        break;
      default:
        print("Ignoring unknown object $name");
        break;
    }
  }
}

bool isPubSpec(FileSystemEntity entity) =>
    entity is File && entity.path.endsWith("pubspec.yaml");

void markEntity(FileSystemEntity entity) {
  if (entity is File) {
    markFile(entity);
  } else if (entity is Directory) {
    markDirectory(entity);
  } else {
    print("Ignoring unknown object ${entity.path}");
  }
}

void markDirectory(Directory dir) {
  var children = dir.listSync();
  if (children.any(isPubSpec)) {
    print("Skipping files under ${dir.path}");
    return;
  }
  for (var child in children) {
    markEntity(child);
  }
}

void markFile(File file) {
  if (!file.path.endsWith(".dart")) {
    return;
  }

  List<String> lines;
  try {
    lines = file.readAsLinesSync();
  } catch (e) {
    print("Failed to read file ${file.path}: $e");
    return;
  }
  if (lines.any((line) => line.startsWith(languageMarker))) {
    print("Skipping already marked file ${file.path}");
    return;
  }
  var marked = markContents(lines);
  try {
    file.writeAsStringSync(marked);
  } catch (e) {
    print("Failed to write file ${file.path}: $e");
    return;
  }
  print("Marked ${file.path}");
}

String markContents(List<String> lines) {
  var buffer = StringBuffer();
  var marked = false;

  for (var line in lines) {
    // If the file has not yet been marked, and we have reached the
    // first non-comment line, insert an opt out marker.
    if (!marked &&
        (!commentLine.hasMatch(line)) &&
        (!scriptLine.hasMatch(line))) {
      buffer.write('\n// @dart = 2.9\n');
      marked = true;
    }
    buffer.write('$line\n');
  }

  // In case of empty file, or file of all comments (who does that!?).
  if (!marked) {
    buffer.write('\n// @dart = 2.9\n');
  }
  return buffer.toString();
}
