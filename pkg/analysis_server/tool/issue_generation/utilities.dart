// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart';

/// Returns the absolute path to the analysis_server directory.
String get serverPath {
  var scriptPath = Platform.script.toFilePath();
  var serverPath = scriptPath;
  while (!serverPath.endsWith('/analysis_server')) {
    serverPath = context.dirname(serverPath);
  }
  return serverPath;
}

/// Returns a sorted list of the names of the files in the given [directoryPath]
/// that have a `.dart` extension and are not in the list of [excludedNames].
List<String> filesInDirectory(
  String directoryPath,
  List<String> excludedNames,
) {
  var fileNames = <String>[];
  _addFilesInDirectory(
    directory: Directory(directoryPath),
    excludedNames: excludedNames,
    fileNames: fileNames,
  );
  return fileNames..sort();
}

/// Adds the names of the files in the given [directoryPath] that have a `.dart`
/// extension and are not in the list of [excludedNames] to the list of
/// [fileNames].
///
/// Files in subdirectories
void _addFilesInDirectory({
  required Directory directory,
  required List<String> excludedNames,
  required List<String> fileNames,
  String suffix = '',
}) {
  for (var entity in directory.listSync()) {
    if (entity is File) {
      var fileName = context.basename(entity.path);
      if (fileName.endsWith('.dart') && !excludedNames.contains(fileName)) {
        if (suffix.isNotEmpty) {
          fileNames.add('$fileName ($suffix)');
        } else {
          fileNames.add(fileName);
        }
      }
    } else if (entity is Directory) {
      var dirName = context.basename(entity.path);
      _addFilesInDirectory(
        directory: entity,
        excludedNames: excludedNames,
        fileNames: fileNames,
        suffix: suffix.isEmpty ? dirName : '$suffix/$dirName',
      );
    }
  }
}
