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
  return (await callTestPy(args))
      .map((line) => line.trim())
      .where((name) => name.isNotEmpty);
}

/// Calls test.py with arguments gathered from a specific [configuration] and
/// lists all status files included for that particular configuration.
Future<Iterable<String>> statusFileLister(Configuration configuration) async {
  List<String> args = configuration.toArgs()..add("--list-status-files");
  return (await callTestPy(args)).where((name) => name.isNotEmpty);
}

/// Calls test.py with arguments and returns the result.
Future<Iterable<String>> callTestPy(List<String> args) async {
  var testPyPath = path.absolute(PathHelper.testPyPath());
  var result = await Process.run(testPyPath, args);
  if (result.exitCode != 0) {
    throw "Failed to call test.py: "
        "'${PathHelper.testPyPath()} ${args.join(' ')}'. "
        "Process exited with ${result.exitCode}";
  }
  return (result.stdout as String).split('\n').skip(1);
}

/// Calls test.py with arguments gathered from a specific [configuration] and
/// returns a map from test-suite to a list of status-files.
Future<Map<String, Iterable<String>>> statusFileListerMap(
    Configuration configuration) {
  return statusFileListerMapFromArgs(configuration.toArgs());
}

/// Calls test.py with arguments [args] and returns a map from test-suite to a
/// list of status-files.
Future<Map<String, Iterable<String>>> statusFileListerMapFromArgs(
    List<String> args) async {
  args.add("--list-status-files");
  Map<String, List<String>> returnMap = {};
  var suitesWithStatusFiles = await callTestPy(args);
  String currentSuite = "";
  for (var line in suitesWithStatusFiles) {
    if (line.isEmpty) {
      continue;
    }
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

/// Get tests for a suite.
Future<Iterable<String>> testsForSuite(String suite) async {
  Iterable<String> tests = await callTestPy(["--list", suite]);
  return tests
      .skip(3)
      .takeWhile((testName) => testName.isNotEmpty)
      .map((testInfo) {
    return testInfo.substring(0, testInfo.indexOf(" ")).trim();
  });
}
