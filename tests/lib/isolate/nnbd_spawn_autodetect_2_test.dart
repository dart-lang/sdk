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
  generateIsolateSource(sourcePath, "2.6");
  generateKernel(sourcePath, dillPath);
  generateAppJIT(sourcePath, jitPath);

  try {
    // Strong Isolate Spawning another Strong Isolate using spawn.
    testNullSafetyMode(sourcePath, 're: weak');
    testNullSafetyMode(dillPath, 're: weak');
    testNullSafetyMode(jitPath, 're: weak');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
