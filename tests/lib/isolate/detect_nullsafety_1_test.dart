// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "detect_nullsafety_helper.dart";

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
    // Running from Source.
    testNullSafetyMode(sourcePath, 'Strong Mode');
    // Without the enable experiment option it will be in strong mode.
    testNullSafetyMode1(sourcePath, 'Strong Mode');

    // Running from Kernel File.
    testNullSafetyMode(dillPath, 'Strong Mode');
    // Without the enable experiment option it will be inferred to strong.
    testNullSafetyMode1(dillPath, 'Strong Mode');

    // Running from app JIT File.
    testNullSafetyMode(jitPath, 'Strong Mode');
    // Without the enable experiment option it will be inferred to strong.
    testNullSafetyMode1(jitPath, 'Strong Mode');
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
