// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show exit;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import 'log.dart';

void main(List<String> args) {
  if (args.length != 2) {
    print(
      'Expected exactly two arguments, an input log path a output log path',
    );
    exit(1);
  }
  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  var inputFile = resourceProvider.getFile(
    Uri.base.resolve(args[0]).toFilePath(),
  );
  var outputFile = resourceProvider.getFile(
    Uri.base.resolve(args[1]).toFilePath(),
  );
  if (!inputFile.exists) {
    print('Input file ${args[0]} does not exist');
    exit(1);
  }
  print('normalizing log at ${inputFile.path}');
  var normalized = normalizeLog(inputFile);
  outputFile.writeAsStringSync(normalized);
  print('wrote normalized log to ${outputFile.path}');
}

/// Reads an [input] log file, and attempts to normalize it so that it can work
/// across multiple environments.
///
/// Specifically, this:
///   - Replaces all occurences of the "rootPath" value with {{workspaceRoot}}
///
/// Returns the new file contents after normalization.
//
// TODO(somebody): Replace all other absolute paths.
// TODO(somebody): Support legacy protocol.
String normalizeLog(File input) {
  var content = input.readAsStringSync();
  var original = Log.fromString(content, {});
  var initializeMessage = original.entries.firstWhere(
    (log) => log.isMessage && log.message.isInitialize,
  );
  var workspaceFolders =
      ((initializeMessage.message.map['params']
                  as Map<String, Object?>)['workspaceFolders']
              as List)
          .cast<Map<String, Object?>>();
  for (var i = 0; i < workspaceFolders.length; i++) {
    var folder = workspaceFolders[i];
    var uri = folder['uri'] as String;
    content = content.replaceAll(uri, '{{workspaceFolder-$i}}');
  }
  return content;
}
