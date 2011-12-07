// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing FileInputStream, VM-only, standalone test.

// Helper method to be able to run the test from the runtime
// directory, or the top directory.
String getFilename(String path) =>
    new File(path).existsSync() ? path : '../' + path;

void testStringInputStreamSync() {
  String fileName = getFilename("tests/standalone/src/readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  File file = new File(fileName);
  file.openSync();
  StringInputStream x = new StringInputStream(file.openInputStream());
  String line = x.readLine();
  Expect.equals("Hello Dart", line);
  file.closeSync();
  line = x.readLine();
  Expect.equals("wassup!", line);
}

void testInputStreamAsync() {
  String fileName = getFilename("tests/standalone/src/readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  var expected = "Hello Dart\nwassup!\n".charCodes();
  File file = new File(fileName);
  file.openSync();
  InputStream x = file.openInputStream();
  var byteCount = 0;
  x.dataHandler = () {
    Expect.equals(expected[byteCount],  x.read(1)[0]);
    byteCount++;
  };
  x.closeHandler = () {
    Expect.equals(expected.length, byteCount);
  };
}


void testStringInputStreamAsync1() {
  String fileName = getFilename("tests/standalone/src/readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  File file = new File(fileName);
  file.openSync();
  StringInputStream x = new StringInputStream(file.openInputStream());
  var result = "";
  x.dataHandler = () {
    result += x.read();
  };
  x.closeHandler = () {
    Expect.equals("Hello Dart\nwassup!\n", result);
  };
}


void testStringInputStreamAsync2() {
  String fileName = getFilename("tests/standalone/src/readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  File file = new File(fileName);
  file.openSync();
  StringInputStream x = new StringInputStream(file.openInputStream());
  int lineCount = 0;
  x.lineHandler = () {
    var line = x.readLine();
    Expect.isTrue(lineCount == 0 || lineCount == 1);
    if (lineCount == 0) Expect.equals("Hello Dart", line);
    if (lineCount == 1) Expect.equals("wassup!", line);
    lineCount++;
  };
  x.closeHandler = () {
    Expect.equals(2, lineCount);
  };
}


void testChunkedInputStream() {
  String fileName = getFilename("tests/standalone/src/readuntil_test.dat");
  // File contains 19 bytes ("Hello Dart\nwassup!")
  File file = new File(fileName);
  file.openSync();
  ChunkedInputStream x = new ChunkedInputStream(file.openInputStream());
  x.chunkSize = 9;
  List<int> chunk = x.read();
  Expect.equals(9, chunk.length);
  file.closeSync();
  x.chunkSize = 5;
  chunk = x.read();
  Expect.equals(5, chunk.length);
  chunk = x.read();
  Expect.equals(5, chunk.length);
  chunk = x.read();
  Expect.equals(null, chunk);
}


main() {
  testStringInputStreamSync();
  testInputStreamAsync();
  testStringInputStreamAsync1();
  testStringInputStreamAsync2();
  testChunkedInputStream();
}
