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
  for (var entity in Directory(directoryPath).listSync()) {
    if (entity is File) {
      var fileName = context.basename(entity.path);
      if (fileName.endsWith('.dart') && !excludedNames.contains(fileName)) {
        fileNames.add(fileName);
      }
    }
  }
  return fileNames..sort();
}
