// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("StatusFileParserTest");

#import("../../../tools/testing/dart/status_file_parser.dart");


void main() {
  TestReadStatusFile("tests/co19/co19-compiler.status");
  TestReadStatusFile("tests/co19/co19-runtime.status");
  TestReadStatusFile("tests/corelib/corelib.status");
  TestReadStatusFile("tests/isolate/isolate.status");
  TestReadStatusFile("tests/language/language.status");
  TestReadStatusFile("tests/standalone/standalone.status");
  TestReadStatusFile("tests/stub-generator/stub-generator.status");
  TestReadStatusFile("samples/tests/samples/samples.status");
  TestReadStatusFile("runtime/tests/vm/vm.status");
  TestReadStatusFile("frog/tests/frog/frog.status");
  TestReadStatusFile("compiler/tests/dartc/dartc.status");
  TestReadStatusFile("client/tests/client/client.status");
  TestReadStatusFile("client/tests/dartc/dartc.status");
}


void TestReadStatusFile(String filePath) {
  File file = new File(getFilename(filePath));
  if (file.existsSync()) {
    List<Section> sections = new List<Section>();
    ReadConfigurationInto(filePath, sections);
    Expect.isTrue(sections.length > 0);
  }
}
