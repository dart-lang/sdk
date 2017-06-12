// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library StatusFileParserTest;

import "package:expect/expect.dart";
import "dart:io";
import "../../../tools/testing/dart/path.dart";
import "../../../tools/testing/dart/status_file.dart";
import "../../../tools/testing/dart/utils.dart";

void main() {
  testReadStatusFile("runtime/tests/vm/vm.status");
  testReadStatusFile("samples/tests/samples/samples.status");
  testReadStatusFile("tests/co19/co19-compiler.status");
  testReadStatusFile("tests/co19/co19-runtime.status");
  testReadStatusFile("tests/corelib/corelib.status");
  testReadStatusFile("tests/dom/dom.status");
  testReadStatusFile("tests/html/html.status");
  testReadStatusFile("tests/isolate/isolate.status");
  testReadStatusFile("tests/language/language.status");
  testReadStatusFile("tests/standalone/standalone.status");
}

String fixFilePath(String filePath) {
  if (new File(filePath).existsSync()) {
    return filePath;
  } else {
    return "../${filePath}";
  }
}

void testReadStatusFile(String filePath) {
  var file = new File(fixFilePath(filePath));
  if (!file.existsSync()) return;

  var statusFile = new StatusFile.read(file.path);
  Expect.isTrue(statusFile.sections.length > 0);
}
