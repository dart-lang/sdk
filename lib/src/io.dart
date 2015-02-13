// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library io;

import 'dart:io';

import 'package:linter/src/linter.dart';


/// Runs the linter on [file], skipping links and files not ending in the
/// '.dart' extension.
///
/// Returns `true` if successful or `false` if an error occurred.
bool lintFile(FileSystemEntity file, {String dartSdkPath, String packageRoot}) {
  var path = file.path;

  if (file is Link) {
    stdout.writeln('Skipping link $path');
    return false;
  }

  if (!isDartFile(file)) {
    stdout.writeln('Skipping $path (unsupported extenstion)');
    return false;
  }

  DartLinter linter = new DartLinter();
  if (dartSdkPath != null) {
    linter.options.dartSdkPath = dartSdkPath;
  }
  if (packageRoot != null) {
    linter.options.packageRootPath = packageRoot;
  }

  try {
   linter.lintFile(file);
   return true;
  } catch (err, stack) {
    stderr.writeln('''An error occurred while linting $path
  Please report it at: github.com/dart-lang/dart_lint/issues
$err
$stack''');
  }
  return false;
}

bool isDartFile(FileSystemEntity entry) => entry.path.endsWith('.dart');