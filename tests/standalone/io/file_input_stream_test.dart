// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing file input stream, VM-only, standalone test.

#import("dart:io");
#import("dart:isolate");

// Helper method to be able to run the test from the runtime
// directory, or the top directory.
String getFilename(String path) =>
    new File(path).existsSync() ? path : '../$path';

void testStringInputStreamSync() {
  String fileName = getFilename("tests/standalone/io/readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  File file = new File(fileName);
  int linesRead = 0;
  StringInputStream x = new StringInputStream(file.openInputStream());
  x.onLine = () {
    String line = x.readLine();
    linesRead++;
    if (linesRead == 1) {
      Expect.equals("Hello Dart", line);
    } else if (linesRead == 2) {
      Expect.equals("wassup!", line);
    } else {
      Expect.fail("More or less than 2 lines read ($linesRead lines read).");
    }
  };
}

void testInputStreamAsync() {
  String fileName = getFilename("tests/standalone/io/readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  var expected = "Hello Dart\nwassup!\n".charCodes();
  InputStream x = (new File(fileName)).openInputStream();
  var byteCount = 0;
  x.onData = () {
    Expect.equals(expected[byteCount], x.read(1)[0]);
    byteCount++;
  };
  x.onClosed = () {
    Expect.equals(expected.length, byteCount);
  };
}

void testStringInputStreamAsync(String name, int length) {
  String fileName = getFilename("tests/standalone/io/$name");
  // File contains 10 lines.
  File file = new File(fileName);
  Expect.equals(length, file.openSync().lengthSync());
  StringInputStream x = new StringInputStream(file.openInputStream());
  int lineCount = 0;
  x.onLine = () {
    var line = x.readLine();
    lineCount++;
    Expect.isTrue(lineCount <= 10);
    if (line[0] != "#") {
      Expect.equals("Line $lineCount", line);
    }
  };
  x.onClosed = () {
    Expect.equals(10, lineCount);
  };
}

void testChunkedInputStream() {
  // Force the test to timeout if it does not finish.
  ReceivePort done = new ReceivePort();
  done.receive((message, replyTo) { done.close(); });

  String fileName = getFilename("tests/standalone/io/readuntil_test.dat");
  // File contains 19 bytes ("Hello Dart\nwassup!")
  File file = new File(fileName);
  ChunkedInputStream x = new ChunkedInputStream(file.openInputStream());
  x.chunkSize = 9;
  x.onData = () {
    List<int> chunk = x.read();
    Expect.equals(9, chunk.length);
    x.chunkSize = 5;
    x.onData = () {
      chunk = x.read();
      Expect.equals(5, chunk.length);
      x.onData = () {
        chunk = x.read();
        Expect.equals(5, chunk.length);
        chunk = x.read();
        Expect.equals(null, chunk);
        done.toSendPort().send(null);
      };
    };
  };
}

void testUnreadyInputStream() {
  String fileName = getFilename("tests/standalone/io/readuntil_test.dat");
  var expected = "Hello Dart\nwassup!\n".charCodes();
  InputStream x = (new File(fileName)).openInputStream();
  List<int> buffer = new List<int>(100);

  x.onData = () {
    Expect.fail("Input stream closed before opening called onData handler.");
  };

  x.onClosed = () { };

  // Called before stream is ready.
  int read = x.readInto(buffer);
  Expect.equals(0, read);

  // Called before stream is ready.
  x.close();
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
  testUnreadyInputStream();
}
