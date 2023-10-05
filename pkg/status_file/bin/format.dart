// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Reformats the status file(s) at the given path.
library;

import 'dart:io';

import 'package:status_file/status_file.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    print("Usage: dart status_file/bin/format.dart <path>");
    exit(1);
  }

  var path = arguments[0];

  if (File(path).existsSync()) {
    formatFile(path);
  } else if (Directory(path).existsSync()) {
    for (var entry in Directory(path).listSync(recursive: true)) {
      if (!entry.path.endsWith(".status")) continue;

      formatFile(entry.path);
    }
  }
}

void formatFile(String path) {
  try {
    var statusFile = StatusFile.read(path);
    File(path).writeAsStringSync(statusFile.serialize());
    print("Formatted $path");
  } on SyntaxError catch (error) {
    stderr.writeln("Could not parse $path:\n$error");
  }
}
