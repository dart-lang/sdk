// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'baseline_test.dart' as baseline_test;
import 'dart:io';

/// Removes the compiled binaries and runs the tests again.
///
/// Run this if the frontend has changed.
void main() {
  String directory = baseline_test.binaryDirectory;
  for (FileSystemEntity entity in new Directory(directory).listSync()) {
    if (entity is File && entity.path.endsWith('.bart')) {
      entity.deleteSync();
    }
  }
  baseline_test.main();
}
