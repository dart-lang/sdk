// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:status_file/canonical_status_file.dart';
import 'package:status_file/status_file.dart' as status_file;
import 'package:status_file/status_file_linter.dart';
import 'package:status_file/utils.dart';

ArgParser buildParser() {
  var parser = new ArgParser();
  parser.addFlag("check-for-disjunctions",
      negatable: false,
      defaultsTo: false,
      help: "Warn if a status header expression contains '||'.");
  parser.addFlag("text",
      abbr: "t",
      negatable: false,
      defaultsTo: false,
      help: "Lint text passed in stdin.");
  parser.addFlag("help",
      abbr: "h",
      negatable: false,
      defaultsTo: false,
      help: "Show help and commands for this tool.");
  return parser;
}

void printHelp(ArgParser parser) {
  print("Usage: 'dart status_file/bin/lint.dart <path>' or 'dart "
      "status_file/bin/lint.dart -t <input>' for text input.");
  print(parser.usage);
}

void main(List<String> arguments) {
  var parser = buildParser();
  var results = parser.parse(arguments);
  if (results["help"]) {
    printHelp(parser);
    return;
  }
  bool checkForDisjunctions = results["check-for-disjunctions"];
  bool usePipe = results["text"];
  if (usePipe) {
    lintStdIn(checkForDisjunctions: checkForDisjunctions);
  } else {
    if (results.rest.length != 1) {
      printHelp(parser);
      exit(1);
    }
    lintPath(results.rest.first, checkForDisjunctions: checkForDisjunctions);
  }
}

void lintStdIn({bool checkForDisjunctions = false}) {
  List<String> strings = <String>[];
  String readString;
  try {
    while (null != (readString = stdin.readLineSync())) {
      strings.add(readString);
    }
  } on StdinException {
    // I do not know why this happens.
  }
  if (!lintText(strings)) {
    exit(1);
  }
}

void lintPath(path, {bool checkForDisjunctions = false}) {
  var filesWithErrors = <String>[];
  if (FileSystemEntity.isFileSync(path)) {
    if (!lintFile(path, checkForDisjunctions: checkForDisjunctions)) {
      filesWithErrors.add(path);
    }
  } else if (FileSystemEntity.isDirectorySync(path)) {
    new Directory(path).listSync(recursive: true).forEach((entry) {
      if (!canLint(entry.path)) {
        return;
      }
      if (!lintFile(entry.path, checkForDisjunctions: checkForDisjunctions)) {
        filesWithErrors.add(entry.path);
      }
    });
  }
  if (filesWithErrors.isNotEmpty) {
    print("File output does not match how status files should be formatted.");
    print("Fix these issues with:");
    print("dart ${Platform.script.resolve("normalize.dart").path} -w \\");
    print(filesWithErrors.join(" \\\n"));
    exit(1);
  }
}

bool lintText(List<String> text, {bool checkForDisjunctions = false}) {
  try {
    var statusFile = new StatusFile.parse("stdin", text);
    return lintStatusFile(statusFile,
        checkForDisjunctions: checkForDisjunctions);
  } on status_file.SyntaxError {
    stderr.writeln("Could not parse stdin.");
  }
  return false;
}

bool lintFile(String path, {bool checkForDisjunctions = false}) {
  try {
    var statusFile = new StatusFile.read(path);
    return lintStatusFile(statusFile,
        checkForDisjunctions: checkForDisjunctions);
  } on status_file.SyntaxError catch (error) {
    stderr.writeln("Could not parse $path:\n$error");
  }
  return false;
}

bool lintStatusFile(StatusFile statusFile,
    {bool checkForDisjunctions = false}) {
  var lintingErrors =
      lint(statusFile, checkForDisjunctions: checkForDisjunctions);
  if (lintingErrors.isEmpty) {
    print("${statusFile.path}\n Status file passed all tests");
    print("");
    return true;
  }
  if (statusFile.path != null && statusFile.path.isNotEmpty) {
    print("${statusFile.path}");
  }
  var errors = lintingErrors.toList();
  errors.sort((a, b) => a.lineNumber.compareTo((b.lineNumber)));
  errors.forEach(print);
  print("");
  return false;
}
