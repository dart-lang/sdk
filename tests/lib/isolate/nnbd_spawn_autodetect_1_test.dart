// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "nnbd_spawn_autodetect_helper.dart";

void main() {
  // Create temporary directory.
  var tmpDir = Directory.systemTemp.createTempSync();
  var tmpDirPath = tmpDir.path;
  String sourcePath = "$tmpDirPath/strong.dart";
  String dillPath = "$tmpDirPath/strong.dill";
  String jitPath = "$tmpDirPath/strong.appjit";

  // Generate code for an isolate to run in strong mode.
  generateIsolateSource(sourcePath, "");
  generateKernel(sourcePath, dillPath);
  generateAppJIT(sourcePath, jitPath);

  try {
    // Strong Isolate Spawning another Strong Isolate using spawn.
    testNullSafetyMode(sourcePath, 're: strong');
    testNullSafetyMode(dillPath, 're: strong');
    testNullSafetyMode(jitPath, 're: strong');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
