// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library StatusFileParserTest;

import "package:expect/expect.dart";
import "dart:io";
import "../../../tools/testing/dart/path.dart";
import "../../../tools/testing/dart/status_file_parser.dart";
import "../../../tools/testing/dart/utils.dart";


void main() {
  TestReadStatusFile("runtime/tests/vm/vm.status");
  TestReadStatusFile("samples/tests/samples/samples.status");
  TestReadStatusFile("tests/co19/co19-compiler.status");
  TestReadStatusFile("tests/co19/co19-runtime.status");
  TestReadStatusFile("tests/corelib/corelib.status");
  TestReadStatusFile("tests/dom/dom.status");
  TestReadStatusFile("tests/html/html.status");
  TestReadStatusFile("tests/isolate/isolate.status");
  TestReadStatusFile("tests/language/language.status");
  TestReadStatusFile("tests/standalone/standalone.status");
}

String fixedFilePath(String filePath) {
  if (new File(filePath).existsSync()) {
    return filePath;
  } else {
    return "../${filePath}";
  }
}

void TestReadStatusFile(String filePath) {
  File file = new File(fixedFilePath(filePath));
  if (file.existsSync()) {
    List<Section> sections = new List<Section>();
    ReadConfigurationInto(new Path(file.path), sections, () {
      Expect.isTrue(sections.length > 0);
    });
  }
}
