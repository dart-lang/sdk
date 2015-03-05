// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.io;

import 'dart:io';

import 'package:linter/src/util.dart';
import 'package:path/path.dart' as p;

/// Shared IO sink for standard error reporting.
/// Visible for testing
IOSink errorSink = stderr;

/// Shared IO sink for standard out reporting.
/// Visible for testing
IOSink outSink = stdout;

Iterable<File> collectFiles(String path) {
  List<File> files = [];

  var file = new File(path);
  if (file.existsSync()) {
    files.add(file);
  } else {
    var directory = new Directory(path);
    if (directory.existsSync()) {
      for (var entry
          in directory.listSync(recursive: true, followLinks: false)) {
        var relative = p.relative(entry.path, from: directory.path);

        if (isLintable(entry) && !isInHiddenDir(relative)) {
          files.add(entry);
        }
      }
    }
  }

  return files;
}

bool isDartFile(FileSystemEntity entry) => isDartFileName(entry.path);

bool isInHiddenDir(String relative) =>
    p.split(relative).any((part) => part.startsWith("."));

bool isLintable(FileSystemEntity file) =>
    file is File && (isDartFile(file) || isPubspecFile(file));

bool isPubspecFile(FileSystemEntity entry) =>
    isPubspecFileName(p.basename(entry.path));
