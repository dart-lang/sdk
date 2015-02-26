// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library io;

import 'dart:io';

import 'package:linter/src/linter.dart';
import 'package:linter/src/util.dart';
import 'package:path/path.dart' as p;

/// Visible for testing
IOSink std_err = stderr;

/// Visible for testing
IOSink std_out = stdout;

bool isDartFile(FileSystemEntity entry) => isDartFileName(entry.path);

bool isLintable(FileSystemEntity file) =>
    isDartFile(file) || isPubspecFile(file);
bool isPubspecFile(FileSystemEntity entry) =>
    isPubspecFileName(p.basename(entry.path));

/// Runs the linter on [file], skipping links and files not ending in the
/// '.dart' extension.
///
/// Returns `true` if successful or `false` if an error occurred.
bool lintFile(FileSystemEntity file,
    {String dartSdkPath, String packageRoot, DartLinter linter}) {
  var path = file.path;

  if (file is Link) {
    std_out.writeln('Skipping link $path');
    return false;
  }

  if (!isLintable(file)) {
    std_out.writeln('Skipping $path (unsupported extenstion)');
    return false;
  }

  if (linter == null) {
    linter = new DartLinter();
  }

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
    std_err.writeln('''An error occurred while linting $path
  Please report it at: github.com/dart-lang/dart_lint/issues
$err
$stack''');
  }
  return false;
}
