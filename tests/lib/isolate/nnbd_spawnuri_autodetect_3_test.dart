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
  String outPath = "$tmpDirPath/strong_isolate.dill";

  // Generate code for an isolate to run in strong mode.
  generateIsolateSource(sourcePath, "");
  generateKernel(sourcePath, outPath);

  try {
    String outUri = Uri.file(outPath).toString();

    // Strong Isolate Spawning another Strong Isolate using spawnUri.
    testNullSafetyMode(
        "$tmpDirPath/strong_strong.dart", "", outUri, 're: strong');

    // Weak Isolate Spawning a Strong Isolate using spawnUri.
    testNullSafetyMode(
        "$tmpDirPath/weak_strong.dart", "2.6", outUri, 're: strong');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
