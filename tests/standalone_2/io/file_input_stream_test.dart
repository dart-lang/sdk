// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing file input stream, VM-only, standalone test.
//
// OtherResources=readuntil_test.dat
// OtherResources=readline_test1.dat
// OtherResources=readline_test2.dat

import "dart:convert";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

String getFilename(String path) {
  return Platform.script.resolve(path).toFilePath();
}

void testStringLineSplitter() {
  String fileName = getFilename("readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  File file = new File(fileName);
  int linesRead = 0;
  var lineStream =
      file.openRead().transform(UTF8.decoder).transform(new LineSplitter());
  lineStream.listen((line) {
    linesRead++;
    if (linesRead == 1) {
      Expect.equals("Hello Dart", line);
    } else if (linesRead == 2) {
      Expect.equals("wassup!", line);
    } else {
      Expect.fail("More or less than 2 lines read ($linesRead lines read).");
    }
  });
}

void testOpenStreamAsync() {
  asyncStart();
  String fileName = getFilename("readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  var expected = "Hello Dart\nwassup!\n".codeUnits;
  var byteCount = 0;
  (new File(fileName)).openRead().listen((d) => byteCount += d.length,
      onDone: () {
    Expect.equals(expected.length, byteCount);
    asyncEnd();
  });
}

// Create a file that is big enough that a file stream will
// read it in multiple chunks.
int writeLongFileSync(File file) {
  file.createSync();
  StringBuffer buffer = new StringBuffer();
  for (var i = 0; i < 50000; i++) {
    buffer.write("Hello, world");
  }
  file.writeAsStringSync(buffer.toString());
  var length = file.lengthSync();
  Expect.equals(buffer.length, length);
  return length;
}

void testInputStreamTruncate() {
  asyncStart();
  var temp = Directory.systemTemp.createTempSync('file_input_stream_test');
  var file = new File('${temp.path}/input_stream_truncate.txt');
  var originalLength = writeLongFileSync(file);
  // Start streaming the file. Pause after first chunk. Truncate
  // underlying file and check that the streaming stops with or
  // without getting all data.
  var streamedBytes = 0;
  var subscription;
  subscription = file.openRead().listen((d) {
    if (streamedBytes == 0) {
      subscription.pause();
      // Truncate the file by opening it for writing.
      file.open(mode: FileMode.WRITE).then((opened) {
        opened.close().then((_) {
          Expect.equals(0, file.lengthSync());
          subscription.resume();
        });
      });
    }
    streamedBytes += d.length;
  }, onDone: () {
    Expect.isTrue(streamedBytes > 0 && streamedBytes <= originalLength);
    temp.delete(recursive: true).then((_) => asyncEnd());
  }, onError: (e) {
    Expect.fail("Unexpected error");
  });
}

void testInputStreamDelete() {
  asyncStart();
  var temp = Directory.systemTemp.createTempSync('file_input_stream_test');
  var file = new File('${temp.path}/input_stream_delete.txt');
  var originalLength = writeLongFileSync(file);
  // Start streaming the file. Pause after first chunk. Truncate
  // underlying file and check that the streaming stops with or
  // without getting all data.
  var streamedBytes = 0;
  var subscription;
  subscription = file.openRead().listen((d) {
    if (streamedBytes == 0) {
      subscription.pause();
      // Delete the underlying file by opening it for writing.
      file.delete().then((deleted) {
        Expect.isFalse(deleted.existsSync());
        subscription.resume();
      }).catchError((e) {
        // On Windows, you cannot delete a file that is open
        // somewhere else. The stream has this file open
        // and therefore we get an error on deletion on Windows.
        Expect.equals('windows', Platform.operatingSystem);
        subscription.resume();
      });
    }
    streamedBytes += d.length;
  }, onDone: () {
    Expect.equals(originalLength, streamedBytes);
    temp.delete(recursive: true).then((_) => asyncEnd());
  }, onError: (e) {
    Expect.fail("Unexpected error");
  });
}

void testInputStreamAppend() {
  asyncStart();
  var temp = Directory.systemTemp.createTempSync('file_input_stream_test');
  var file = new File('${temp.path}/input_stream_append.txt');
  var originalLength = writeLongFileSync(file);
  // Start streaming the file. Pause after first chunk. Append to
  // underlying file and check that the stream gets all the data.
  var streamedBytes = 0;
  var subscription;
  subscription = file.openRead().listen((d) {
    if (streamedBytes == 0) {
      subscription.pause();
      // Double the length of the underlying file.
      file.readAsBytes().then((bytes) {
        file.writeAsBytes(bytes, mode: FileMode.APPEND).then((_) {
          Expect.equals(2 * originalLength, file.lengthSync());
          subscription.resume();
        });
      });
    }
    streamedBytes += d.length;
  }, onDone: () {
    Expect.equals(2 * originalLength, streamedBytes);
    temp.delete(recursive: true).then((_) => asyncEnd());
  }, onError: (e) {
    Expect.fail("Unexpected error");
  });
}

void testInputStreamOffset() {
  void test(int start, int end, int expectedBytes) {
    asyncStart();
    var temp = Directory.systemTemp.createTempSync('file_input_stream_test');
    var file = new File('${temp.path}/input_stream_offset.txt');
    var originalLength = writeLongFileSync(file);
    var streamedBytes = 0;
    if (expectedBytes < 0) expectedBytes = originalLength + expectedBytes;
    file.openRead(start, end).listen((d) {
      streamedBytes += d.length;
    }, onDone: () {
      Expect.equals(expectedBytes, streamedBytes);
      temp.delete(recursive: true).then((_) => asyncEnd());
    }, onError: (e) {
      Expect.fail("Unexpected error");
    });
  }

  test(10, 20, 10);
  test(10, 11, 1);
  test(10, 10, 0);
  test(100000000, null, 0);
  test(null, 0, 0);
  test(null, 1, 1);
  test(1, null, -1);
  test(20, null, -20);
}

void testInputStreamBadOffset() {
  void test(int start, int end) {
    asyncStart();
    var temp = Directory.systemTemp.createTempSync('file_input_stream_test');
    var file = new File('${temp.path}/input_stream_bad_offset.txt');
    var originalLength = writeLongFileSync(file);
    var streamedBytes = 0;
    bool error = false;
    file.openRead(start, end).listen((d) {
      streamedBytes += d.length;
    }, onDone: () {
      Expect.isTrue(error);
      temp.deleteSync(recursive: true);
      asyncEnd();
    }, onError: (e) {
      error = true;
    });
  }

  test(-1, null);
  test(100, 99);
  test(null, -1);
}

void testStringLineSplitterEnding(String name, int length) {
  String fileName = getFilename(name);
  // File contains 10 lines.
  File file = new File(fileName);
  Expect.equals(length, file.lengthSync());
  var lineStream =
      file.openRead().transform(UTF8.decoder).transform(new LineSplitter());
  int lineCount = 0;
  lineStream.listen((line) {
    lineCount++;
    Expect.isTrue(lineCount <= 10);
    if (line[0] != "#") {
      Expect.equals("Line $lineCount", line);
    }
  }, onDone: () {
    Expect.equals(10, lineCount);
  });
}

main() {
  testStringLineSplitter();
  testOpenStreamAsync();
  testInputStreamTruncate();
  testInputStreamDelete();
  testInputStreamAppend();
  testInputStreamOffset();
  testInputStreamBadOffset();
  // Check the length of these files as both are text files where one
  // is without a terminating line separator which can easily be added
  // back if accidentally opened in a text editor.
  testStringLineSplitterEnding("readline_test1.dat", 111);
  testStringLineSplitterEnding("readline_test2.dat", 114);
}
