// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing file input stream, VM-only, standalone test.

#import("dart:io");
#import("dart:isolate");

// Helper method to be able to run the test from the runtime
// directory, or the top directory.
String getFilename(String path) =>
    new File(path).existsSync() ? path : '../' + path;

void testStringInputStreamSync() {
  String fileName = getFilename("tests/standalone/src/readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  File file = new File(fileName);
  StringInputStream x = new StringInputStream(file.openInputStreamSync());
  x.lineHandler = () {
    // The file input stream is known (for now) to have read the whole
    // file when the data handler is called.
    String line = x.readLine();
    Expect.equals("Hello Dart", line);
    line = x.readLine();
    Expect.equals("wassup!", line);
  };
}

void testInputStreamAsync() {
  String fileName = getFilename("tests/standalone/src/readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  var expected = "Hello Dart\nwassup!\n".charCodes();
  InputStream x = (new File(fileName)).openInputStreamSync();
  var byteCount = 0;
  x.dataHandler = () {
    Expect.equals(expected[byteCount],  x.read(1)[0]);
    byteCount++;
  };
  x.closeHandler = () {
    Expect.equals(expected.length, byteCount);
  };
}


void testStringInputStreamAsync(String name, int length) {
  String fileName = getFilename("tests/standalone/src/$name");
  // File contains 10 lines.
  File file = new File(fileName);
  Expect.equals(length, file.openSync().lengthSync());
  StringInputStream x = new StringInputStream(file.openInputStreamSync());
  int lineCount = 0;
  x.lineHandler = () {
    var line = x.readLine();
    lineCount++;
    Expect.isTrue(lineCount <= 10);
    if (line[0] != "#") {
      Expect.equals("Line $lineCount", line);
    }
  };
  x.closeHandler = () {
    Expect.equals(10, lineCount);
  };
}


void testChunkedInputStream() {
  String fileName = getFilename("tests/standalone/src/readuntil_test.dat");
  // File contains 19 bytes ("Hello Dart\nwassup!")
  File file = new File(fileName);
  ChunkedInputStream x = new ChunkedInputStream(file.openInputStreamSync());
  x.chunkSize = 9;
  List<int> chunk = x.read();
  Expect.equals(9, chunk.length);
  x.chunkSize = 5;
  chunk = x.read();
  Expect.equals(5, chunk.length);
  chunk = x.read();
  Expect.equals(5, chunk.length);
  chunk = x.read();
  Expect.equals(null, chunk);
}


void testOpenInputStreamAsync() {
  // Create a port for waiting on the final result of this test.
  ReceivePort done = new ReceivePort();
  done.receive((message, replyTo) {
    done.close();
  });

  // Test using the asynchronous way of opening an input stream.
  String fileName = getFilename("tests/standalone/src/readuntil_test.dat");
  File file = new File(fileName);
  file.exists();
  file.existsHandler = (exists) {
    if (exists) {
      file.openInputStream();
    } else {
      Expect.fail("Test file not found");
    }
  };
  file.inputStreamHandler = (InputStream stream) {
    done.toSendPort().send("Got an InputStream");
  };
  file.errorHandler = (String error) {
    Expect.fail("Error $error");
  };
}


main() {
  testStringInputStreamSync();
  testInputStreamAsync();
  // Check the length of these files as both are text files where one
  // is without a terminating line separator which can easily be added
  // back if accidentally opened in a text editor.
  testStringInputStreamAsync("readline_test1.dat", 111);
  testStringInputStreamAsync("readline_test2.dat", 114);
  testChunkedInputStream();
  testOpenInputStreamAsync();
}
