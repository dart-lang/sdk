// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'result_models.dart';
import 'util.dart';

/// Calls test.py with arguments gathered from a specific [configuration] and
/// lists all tests included for that particular configuration.
Future<Iterable<String>> testLister(Configuration configuration) async {
  var args = configuration.toArgs()..add("--list");
  var testPyPath = path.absolute(PathHelper.testPyPath());
  var result = await Process.run(testPyPath, args);
  if (result.exitCode != 0) {
    throw "Failed to list tests: "
        "'${PathHelper.testPyPath()} ${args.join(' ')}'. "
        "Process exited with ${result.exitCode}";
  }
  return (result.stdout as String)
      .split('\n')
      .skip(1)
      .map((line) => line.trim())
      .where((name) => name.isNotEmpty);
}

/// Calls test.py with arguments gathered from a specific [configuration] and
/// lists all status files included for that particular configuration.
Future<Iterable<String>> statusFileLister(Configuration configuration) async {
  var args = configuration.toArgs()..add("--list-status-files");
  var testPyPath = path.absolute(PathHelper.testPyPath());
  var result = await Process.run(testPyPath, args);
  if (result.exitCode != 0) {
    throw "Failed to list tests: "
        "'${PathHelper.testPyPath()} ${args.join(' ')}'. "
        "Process exited with ${result.exitCode}";
  }
  return (result.stdout as String)
      .split('\n')
      .skip(1)
      .where((name) => name.isNotEmpty);
}

/// Calls test.py with arguments gathered from a specific [configuration] and
/// returns a map from test-suite to a list of status-files.
Future<Map<String, Iterable<String>>> statusFileListerMap(
    Configuration configuration) async {
  Map<String, List<String>> returnMap = {};
  var suitesWithStatusFiles = await statusFileLister(configuration);
  String currentSuite = "";
  for (var line in suitesWithStatusFiles) {
    bool isSuiteLine = !line.startsWith("\t");
    if (isSuiteLine) {
      currentSuite = line;
      returnMap[currentSuite] = [];
    }
    if (!isSuiteLine) {
      returnMap[currentSuite].add(line.trim());
    }
  }
  return returnMap;
}
