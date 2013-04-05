// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing file input stream, VM-only, standalone test.

import "package:expect/expect.dart";
import "dart:io";
import "dart:isolate";

// Helper method to be able to run the test from the runtime
// directory, or the top directory.
String getFilename(String path) =>
    new File(path).existsSync() ? path : '../$path';

void testStringLineTransformer() {
  String fileName = getFilename("tests/standalone/io/readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  File file = new File(fileName);
  int linesRead = 0;
  var lineStream = file.openRead()
    .transform(new StringDecoder())
    .transform(new LineTransformer());
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
  var keepAlive = new ReceivePort();
  String fileName = getFilename("tests/standalone/io/readuntil_test.dat");
  // File contains "Hello Dart\nwassup!\n"
  var expected = "Hello Dart\nwassup!\n".codeUnits;
  var byteCount = 0;
  (new File(fileName)).openRead().listen(
      (d) => byteCount += d.length,
      onDone: () {
        Expect.equals(expected.length, byteCount);
        keepAlive.close();
      });
}


// Create a file that is big enough that a file stream will
// read it in multiple chunks.
int writeLongFileSync(File file) {
  file.createSync();
  StringBuffer buffer = new StringBuffer();
  for (var i = 0; i < 10000; i++) {
    buffer.write("Hello, world");
  }
  file.writeAsStringSync(buffer.toString());
  var length = file.lengthSync();
  Expect.equals(buffer.length, length);
  return length;
}


void testInputStreamTruncate() {
  var keepAlive = new ReceivePort();
  var temp = new Directory('').createTempSync();
  var file = new File('${temp.path}/input_stream_truncate.txt');
  var originalLength = writeLongFileSync(file);
  // Start streaming the file. Pause after first chunk. Truncate
  // underlying file and check that the streaming stops with or
  // without getting all data.
  var streamedBytes = 0;
  var subscription;
  subscription = file.openRead().listen(
      (d) {
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
      },
      onDone: () {
        Expect.isTrue(streamedBytes > 0 && streamedBytes <= originalLength);
        temp.delete(recursive: true).then((_) => keepAlive.close());
      },
      onError: (e) {
        Expect.fail("Unexpected error");
      });
}

void testInputStreamDelete() {
  var keepAlive = new ReceivePort();
  var temp = new Directory('').createTempSync();
  var file = new File('${temp.path}/input_stream_delete.txt');
  var originalLength = writeLongFileSync(file);
  // Start streaming the file. Pause after first chunk. Truncate
  // underlying file and check that the streaming stops with or
  // without getting all data.
  var streamedBytes = 0;
  var subscription;
  subscription = file.openRead().listen(
      (d) {
        if (streamedBytes == 0) {
          subscription.pause();
          // Delete the underlying file by opening it for writing.
          file.delete()
            .then((deleted) {
              Expect.isFalse(deleted.existsSync());
              subscription.resume();
            })
            .catchError((e) {
              // On Windows, you cannot delete a file that is open
              // somewhere else. The stream has this file open
              // and therefore we get an error on deletion on Windows.
              Expect.equals('windows', Platform.operatingSystem);
              subscription.resume();
            });
        }
        streamedBytes += d.length;
      },
      onDone: () {
        Expect.equals(originalLength, streamedBytes);
        temp.delete(recursive: true).then((_) => keepAlive.close());
      },
      onError: (e) {
        Expect.fail("Unexpected error");
      });
}


void testInputStreamAppend() {
  var keepAlive = new ReceivePort();
  var temp = new Directory('').createTempSync();
  var file = new File('${temp.path}/input_stream_append.txt');
  var originalLength = writeLongFileSync(file);
  // Start streaming the file. Pause after first chunk. Append to
  // underlying file and check that the stream gets all the data.
  var streamedBytes = 0;
  var subscription;
  subscription = file.openRead().listen(
      (d) {
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
      },
      onDone: () {
        Expect.equals(2 * originalLength, streamedBytes);
        temp.delete(recursive: true).then((_) => keepAlive.close());
      },
      onError: (e) {
        Expect.fail("Unexpected error");
      });
}


void testStringLineTransformerEnding(String name, int length) {
  String fileName = getFilename("tests/standalone/io/$name");
  // File contains 10 lines.
  File file = new File(fileName);
  Expect.equals(length, file.openSync().lengthSync());
  var lineStream = file.openRead()
    .transform(new StringDecoder())
    .transform(new LineTransformer());
  int lineCount = 0;
  lineStream.listen(
      (line) {
        lineCount++;
        Expect.isTrue(lineCount <= 10);
        if (line[0] != "#") {
          Expect.equals("Line $lineCount", line);
        }
      },
      onDone: () {
        Expect.equals(10, lineCount);
      });
}


main() {
  testStringLineTransformer();
  testOpenStreamAsync();
  testInputStreamTruncate();
  testInputStreamDelete();
  testInputStreamAppend();
  // Check the length of these files as both are text files where one
  // is without a terminating line separator which can easily be added
  // back if accidentally opened in a text editor.
  testStringLineTransformerEnding("readline_test1.dat", 111);
  testStringLineTransformerEnding("readline_test2.dat", 114);
}
