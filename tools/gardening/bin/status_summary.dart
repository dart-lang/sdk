// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Collects the configurations for all status files in the 'tests' folder that
/// mention one of the test names given as argument.

import 'dart:async';
import 'dart:math' hide log;
import 'dart:io';

import 'package:args/args.dart';
import 'package:gardening/src/util.dart';

main(List<String> args) async {
  ArgParser argParser = createArgParser();
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);
  if (argResults.rest.length == 0) {
    print('Usage: status_summary [options] <test-name1> [<test-name2> ...]');
    print('where options are:');
    print(argParser.usage);
    exit(1);
  }
  int maxStatusWidth = 0;
  int maxConfigWidth = 0;

  List<Uri> statusFiles = await findStatusFiles('tests');
  Map<String, List<StatusFile>> statusMap = <String, List<StatusFile>>{};
  for (Uri uri in statusFiles) {
    Map<String, StatusFile> currentMap = <String, StatusFile>{};
    log('Scanning $uri');
    String currentConfig = '';
    for (String line in new File.fromUri(uri).readAsLinesSync()) {
      if (line.startsWith('[')) {
        currentConfig = line;
      } else {
        int colonIndex = line.indexOf(':');
        if (colonIndex != -1) {
          String testName = line.substring(0, colonIndex).trim();
          int hashIndex = line.indexOf('#', colonIndex + 1);
          String status;
          String comment;
          if (hashIndex != -1) {
            status = line.substring(colonIndex + 1, hashIndex).trim();
            comment = line.substring(hashIndex + 1).trim();
          } else {
            status = line.substring(colonIndex + 1).trim();
            comment = '';
          }

          for (String arg in argResults.rest) {
            if (testName.contains(arg) || arg.contains(testName)) {
              StatusFile statusFile =
                  currentMap.putIfAbsent(testName, () => new StatusFile(uri));
              statusFile.entries
                  .add(new StatusEntry(currentConfig, status, comment));

              maxStatusWidth = max(maxStatusWidth, status.length);
              maxConfigWidth = max(maxConfigWidth, currentConfig.length);
            }
          }
        }
      }
    }
    currentMap.forEach((String testName, StatusFile configFile) {
      statusMap.putIfAbsent(testName, () => <StatusFile>[]).add(configFile);
    });
  }
  statusMap.forEach((String arg, List<StatusFile> statusFiles) {
    print('$arg');
    for (StatusFile statusFile in statusFiles) {
      print('  ${statusFile.uri}');
      statusFile.entries.forEach((StatusEntry entry) {
        print('    ${padRight(entry.status, maxStatusWidth)}'
            ' ${padRight(entry.config, maxConfigWidth)} ${entry.comment}');
      });
    }
  });
}

/// Returns the [Uri]s for all `.status` files in [path] and subdirectories.
Future<List<Uri>> findStatusFiles(String path) async {
  List<Uri> statusFiles = <Uri>[];
  await for (FileSystemEntity entity
      in new Directory(path).list(recursive: true)) {
    if (entity.path.endsWith('.status')) {
      statusFiles.add(entity.uri);
    }
  }
  return statusFiles;
}

/// The entries collected for a single status file.
class StatusFile {
  final Uri uri;
  final List<StatusEntry> entries = <StatusEntry>[];

  StatusFile(this.uri);
}

/// A single entry in a status file.
class StatusEntry {
  /// The preceding config line, if any. I.e. the `[...]` line that contained
  /// this entry, or the empty string otherwise.
  final String config;

  /// The status of the entry, e.g. `Pass, Slow`.
  final String status;

  /// The comment after the status, if any.
  final String comment;

  StatusEntry(this.config, this.status, this.comment);

  String toString() => '$status $config $comment';
}
