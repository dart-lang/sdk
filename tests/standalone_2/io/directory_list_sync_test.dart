// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

void main() {
  File script = new File.fromUri(Platform.script);
  // tests/standalone/io/../..
  Directory startingDir = script.parent.parent.parent;
  print("Recursively listing entries in directory ${startingDir.path} ...");
  List<FileSystemEntity> each =
      startingDir.listSync(recursive: true, followLinks: false);
  print("Found: ${each.length} entities");
}
