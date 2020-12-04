// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "nnbd_spawnuri_autodetect_helper.dart";

void main() {
  // Create temporary directory.
  var tmpDir = Directory.systemTemp.createTempSync();
  var tmpDirPath = tmpDir.path;
  String sourcePath = "$tmpDirPath/strong_isolate.dart";

  // Generate code for an isolate to run in strong mode.
  generateIsolateSource(sourcePath, "");

  try {
    String sourceUri = Uri.file(sourcePath).toString();

    // Strong Isolate Spawning another Strong Isolate using spawnUri.
    testNullSafetyMode(
        "$tmpDirPath/strong_strong.dart", "", sourceUri, 're: strong');

    // Weak Isolate Spawning a Strong Isolate using spawnUri.
    testNullSafetyMode(
        "$tmpDirPath/weak_strong.dart", "2.6", sourceUri, 're: strong');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
