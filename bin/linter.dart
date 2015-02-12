// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:linter/src/io.dart';

const processFileFailedExitCode = 65;
const unableToProcessExitCode = 64;

isLinterErrorCode(int code) =>
    code == unableToProcessExitCode || code == processFileFailedExitCode;

void main(List<String> args) {
  var parser = new ArgParser(allowTrailingOptions: true);

  parser
    ..addFlag("help",
        abbr: "h", negatable: false, help: "Shows usage information.")
    ..addOption('dart-sdk', help: 'Custom path to a Dart SDK.')
    ..addOption('package-root',
        abbr: 'p',
        help: 'Custom package root. (Discouraged.) Remove to use package information computed by pub.');

  var options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    exitCode = unableToProcessExitCode;
    return;
  }

  if (options["help"]) {
    printUsage(parser);
    return;
  }

  if (options.rest.isEmpty) {
    printUsage(parser, "Please provide at least one library file to lint.");
    exitCode = unableToProcessExitCode;
    return;
  }

  for (var path in options.rest) {
    var file = new File(path);
    if (file.existsSync()) {
      print("Linting $path...");
      if (!lintFile(file)) {
        exitCode = processFileFailedExitCode;
      }
    } else {
      stderr.writeln('No file found at "$path".');
      exitCode = unableToProcessExitCode;
    }
  }
}

void printUsage(ArgParser parser, [String error]) {
  var message = "Lints Dart source files.";
  if (error != null) {
    message = error;
  }

  stdout.write('''$message
Usage: lint <library_files>
${parser.usage}
  
For more information, see https://github.com/dart-lang/dart_lint
''');
}
