// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Reformats the status file(s) at the given path.
import 'dart:io';

import 'package:status_file/status_file.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    print("Usage: dart status_file/bin/format.dart <path>");
    exit(1);
  }

  var path = arguments[0];

  if (new File(path).existsSync()) {
    formatFile(path);
  } else if (new Directory(path).existsSync()) {
    for (var entry in new Directory(path).listSync(recursive: true)) {
      if (!entry.path.endsWith(".status")) continue;

      formatFile(entry.path);
    }
  }
}

void formatFile(String path) {
  try {
    var statusFile = new StatusFile.read(path);
    new File(path).writeAsStringSync(statusFile.serialize());
    print("Formatted $path");
  } on SyntaxError catch (error) {
    stderr.writeln("Could not parse $path:\n$error");
  }
}
