// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:status_file/canonical_status_file.dart';
import 'package:status_file/status_file.dart' as status_file;
import 'package:status_file/status_file_linter.dart';

void main(List<String> arguments) {
  var parser = new ArgParser();
  parser.addFlag("check-for-disjunctions",
      negatable: false,
      defaultsTo: false,
      help: "Warn if a status header expression contains '||'.");
  var results = parser.parse(arguments);
  if (results.rest.length != 1) {
    print("Usage: dart status_file/bin/lint.dart <path>");
    exit(1);
  }
  print("");
  var path = results.rest.first;
  bool result = true;
  if (new File(path).existsSync()) {
    result =
        lintFile(path, checkForDisjunctions: results['check-for-disjunctions']);
  } else if (new Directory(path).existsSync()) {
    var allResults = new Directory(path).listSync(recursive: true).map((entry) {
      if (!entry.path.endsWith(".status")) {
        return true;
      }
      return lintFile(entry.path,
          checkForDisjunctions: results['check-for-disjunctions']);
    }).toList();
    return allResults.every((result) => result);
  }
  if (!result) {
    exit(1);
  }
}

bool lintFile(String path, {bool checkForDisjunctions = false}) {
  try {
    var statusFile = new StatusFile.read(path);
    var lintingErrors =
        lint(statusFile, checkForDisjunctions: checkForDisjunctions);
    if (lintingErrors.isEmpty) {
      return true;
    }
    print("${path}:");
    var errors = lintingErrors.toList();
    errors.sort((a, b) => a.lineNumber.compareTo((b.lineNumber)));
    errors.forEach(print);
    print("");
  } on status_file.SyntaxError catch (error) {
    stderr.writeln("Could not parse $path:\n$error");
  }
  return false;
}
