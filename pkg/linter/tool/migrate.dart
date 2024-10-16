// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:linter/src/rules/analyzer_use_new_elements.dart';
import 'package:path/path.dart' as path;

import 'checks/driver.dart';

/// Lists files yet to be migrated to the new element model.
main(List<String> args) async {
  var parser = ArgParser()
    ..addFlag('write',
        abbr: 'w', help: 'Write updated `analyzer_use_new_elements.txt` file.');

  var errors =
      await getOldElementModelAccesses(directoryToMigrate.absolute.path);

  var errorFiles = <String>{};
  for (var error in errors) {
    errorFiles.add(error.source.fullName);
  }

  var migratedFilesSet = filesToMigrate
      .where((file) => !errorFiles.any((f) => f.endsWith(file)))
      .toSet();
  var migratedFilesSorted = migratedFilesSet.map(asRelativePosix).sorted();
  var unmigratedFilesSorted = filesToMigrate
      .where((file) => !migratedFilesSet.contains(file))
      .map(asRelativePosix)
      .sorted();

  var options = parser.parse(args);
  if (options['write'] == true) {
    print("Writing to 'analyzer_use_new_elements.txt'...");
    print('-' * 20);
    File('analyzer_use_new_elements.txt')
        .writeAsStringSync('${migratedFilesSorted.join('\n')}\n');
  } else {
    print('Migrated files:\n');
    print(migratedFilesSorted.join('\n'));
    print('-' * 20);
    print('-' * 20);
    print('\n');
  }

  print('Unmigrated files:\n\n');
  print(unmigratedFilesSorted.join('\n'));
}

final Directory directoryToMigrate = Directory.current;

final List<String> filesToMigrate = directoryToMigrate
    .listSync(recursive: true)
    .where((f) => f.path.endsWith('.dart'))
    .map((r) => r.path)
    .toList();

String asRelativePosix(String fullPath) => path.posix.joinAll(
    path.split(path.relative(fullPath, from: directoryToMigrate.path)));

Future<List<AnalysisError>> getOldElementModelAccesses(String directory) async {
  var results = await Driver([AnalyzerUseNewElements(useOptInFile: false)])
      .analyze([directory]);
  return results;
}
