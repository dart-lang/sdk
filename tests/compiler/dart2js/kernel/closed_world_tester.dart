// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper application to run `closed_world2_test` on multiple files or
/// directories.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:compiler/src/filenames.dart';
import 'closed_world2_test.dart';

const String ERROR_MARKER = '---';

main(List<String> args) async {
  ArgParser parser = new ArgParser();
  parser.addOption('log');

  ArgResults argsResults = parser.parse(args);
  String logName = argsResults['log'];
  IOSink log;
  Map<String, Result> results;
  if (logName != null) {
    if (FileSystemEntity.isFileSync(logName)) {
      // Log a previous log file if it exists and use it to only test files that
      // previously failed.
      results = readLogResults(logName);
    }
    log = new File(logName).openWrite();
  }

  if (results != null) {
    for (String fileName in results.keys) {
      Result result = results[fileName];
      if (result.kind == ResultKind.failure) {
        if (FileSystemEntity.isFileSync(fileName)) {
          await testFile(new File(fileName), log);
        } else {
          print("$fileName doesn't exist");
        }
      } else {
        log?.writeln('${fileName}: ${result.kind}');
      }
    }
  }

  for (String arg in argsResults.rest) {
    String path = nativeToUriPath(arg);
    if (FileSystemEntity.isDirectorySync(path)) {
      Directory dir = new Directory(path);
      for (FileSystemEntity file in dir.listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          if (results == null || !results.containsKey(file.path)) {
            await testFile(file, log);
          }
        }
      }
    } else if (FileSystemEntity.isFileSync(path)) {
      if (results == null || !results.containsKey(path)) {
        await testFile(new File(path), log);
      }
    } else {
      print("$arg doesn't exist");
    }
  }

  await log?.close();
}

/// Read the log file in [logName] and returns the map from test file name to
/// [Result] stored in the log file.
Map<String, Result> readLogResults(String logName) {
  Map<String, Result> results = <String, Result>{};
  String text = new File(logName).readAsStringSync();
  // Make a backup of the log file.
  new File('$logName~').writeAsStringSync(text);
  List<String> lines = text.split('\n');
  int index = 0;
  while (index < lines.length) {
    String line = lines[index];
    int colonPos = line.lastIndexOf(':');
    if (colonPos == -1) {
      if (!line.isEmpty) {
        print('Invalid log line @ $index: $line');
      }
    } else {
      String fileName = line.substring(0, colonPos);
      String kindName = line.substring(colonPos + 1).trim();
      ResultKind kind =
          ResultKind.values.firstWhere((kind) => '$kind' == kindName);
      String error;
      if (kind == ResultKind.failure) {
        assert(lines[index + 1] == ERROR_MARKER);
        index += 2;
        StringBuffer sb = new StringBuffer();
        while (lines[index] != ERROR_MARKER) {
          sb.writeln(lines[index]);
          index++;
        }
        error = sb.toString();
      }
      results[fileName] = new Result(kind, error);
    }
    index++;
  }
  return results;
}

Future testFile(File file, IOSink log) async {
  print('====================================================================');
  print('testing ${file.path}');
  ResultKind kind;
  String error;
  try {
    kind =
        await mainInternal([file.path], skipWarnings: true, skipErrors: true);
  } catch (e, s) {
    kind = ResultKind.failure;
    error = '$e:\n$s';
    print(error);
  }
  log?.writeln('${file.path}: ${kind}');
  if (error != null) {
    log?.writeln(ERROR_MARKER);
    log?.writeln(error);
    log?.writeln(ERROR_MARKER);
  }
  await log.flush();
}

class Result {
  final ResultKind kind;
  final String error;

  Result(this.kind, [this.error]);
}
