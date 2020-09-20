// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "detect_nullsafety_helper.dart";

void main() {
  // Create temporary directory.
  var tmpDir = Directory.systemTemp.createTempSync();
  var tmpDirPath = tmpDir.path;
  String sourcePath = "$tmpDirPath/weak.dart";
  String dillPath = "$tmpDirPath/weak.dill";
  String jitPath = "$tmpDirPath/weak.appjit";

  // Generate code for an isolate to run in weak mode.
  generateIsolateSource(sourcePath, "2.6");
  generateKernel(sourcePath, dillPath);
  generateAppJIT(sourcePath, jitPath);

  try {
    testNullSafetyMode(sourcePath, 'Weak Mode');
    // Without the enable experiment option it will be in weak mode.
    testNullSafetyMode1(sourcePath, 'Weak Mode');

    // Running from Kernel File.
    testNullSafetyMode(dillPath, 'Weak Mode');
    // Without the enable experiment option it will be inferred to weak.
    testNullSafetyMode1(dillPath, 'Weak Mode');

    // Running from app JIT File.
    testNullSafetyMode(jitPath, 'Weak Mode');
    // Without the enable experiment option it will be inferred to weak.
    testNullSafetyMode1(jitPath, 'Weak Mode');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
