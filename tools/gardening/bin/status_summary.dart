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

void help(ArgParser argParser) {
  print('Prints all status-file entries for the given tests.');
  print('The test-names must be a substring (or full match) of the lines in ');
  print('the status file. They can not be fully qualified');
  print('Usage: status_summary [options] <test-name1> [<test-name2> ...]');
  print('where options are:');
  print(argParser.usage);
}

Future main(List<String> args) async {
  ArgParser argParser = createArgParser();
  ArgResults argResults = argParser.parse(args);
  processArgResults(argResults);
  if (argResults.rest.length == 0 || argResults['help']) {
    help(argParser);
    if (argResults['help']) return;
    exit(1);
  }
  int maxStatusWidth = 0;
  int maxConfigWidth = 0;

  Directory testDirectory = findTestDirectory('tests');
  List<Uri> statusFiles = await findStatusFiles(testDirectory);
  Directory pkgDirectory = findTestDirectory('pkg');
  statusFiles.addAll(await findStatusFiles(pkgDirectory));
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

/// Finds the test directory.
///
/// First looks at a test-directory that is relative to the current
Directory findTestDirectory(String directoryName) {
  var directory = new Directory(directoryName);
  if (directory.existsSync()) return directory;
  return new Directory.fromUri(
      Platform.script.resolve("../../../$directoryName"));
}

/// Returns the [Uri]s for all `.status` files in [path] and subdirectories.
Future<List<Uri>> findStatusFiles(Directory testDirectory) async {
  List<Uri> statusFiles = <Uri>[];
  await for (FileSystemEntity entity in testDirectory.list(recursive: true)) {
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
