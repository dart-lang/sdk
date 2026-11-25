// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

class FileTest {
  static late Directory tempDirectory;
  static late File largeFile;
  static final largeFileLastBytes = [104, 101, 108, 108, 111];
  static final largeFileSize = (1 << 31) + largeFileLastBytes.length;

  static int numLiveAsyncTests = 0;

  static void asyncTestStarted() {
    asyncStart();
    ++numLiveAsyncTests;
  }

  static void asyncTestDone(String name) {
    asyncEnd();
    --numLiveAsyncTests;
    if (numLiveAsyncTests == 0) {
      deleteTempDirectory();
    }
  }

  static Future setupTempDirectory(Function doNext) async {
    tempDirectory = Directory.systemTemp.createTempSync('dart_file');

    await doNext();
  }

  static Future createLargeFile(Function doNext) async {
    // Increase the test count to prevent the temp directory from being
    // deleted.
    ++numLiveAsyncTests;
    final buffer = Uint8List(1 << 24);
    largeFile = new File('${tempDirectory.path}/test_large_file');
    IOSink output = largeFile.openWrite();
    for (
      var i = 0;
      i < (largeFileSize - largeFileLastBytes.length) / buffer.length;
      ++i
    ) {
      output.add(buffer);
    }
    output.add(largeFileLastBytes);
    await output.flush();
    await output.close();
    --numLiveAsyncTests;
    await doNext();
  }

  static void deleteTempDirectory() {
    tempDirectory.deleteSync(recursive: true);
  }

  static Future testPipe(File file, buffer) {
    String outputFilename = '${file.path}_copy';
    File outputFile = new File(outputFilename);
    var input = file.openRead();
    var output = outputFile.openWrite();
    Completer done = new Completer();
    input.cast<List<int>>().pipe(output).then((_) {
      var copy = outputFile.openRead();
      int position = 0;
      copy.listen(
        (d) {
          for (int i = 0; i < d.length; i++) {
            Expect.equals(buffer[(position + i) % buffer.length], d[i]);
          }
          position += d.length;
        },
        onDone: () {
          Expect.equals(2 * buffer.length, position);
          outputFile.delete().then((ignore) {
            done.complete();
          });
        },
      );
    });
    return done.future;
  }

  // Test for file stream buffered handling of large files.
  static Future testReadWriteStreamLargeFile() async {
    // Create the test data - arbitrary binary data.
    List<int> buffer = new List<int>.filled(100000, 0);
    for (var i = 0; i < buffer.length; ++i) {
      buffer[i] = i % 256;
    }
    String filename = tempDirectory.path + "/out_read_write_stream_large_file";
    File file = new File(filename);
    IOSink output = file.openWrite();
    output.add(buffer);
    output.add(buffer);
    output.flush().then((_) => output.close());

    asyncTestStarted();
    return output.done
        .then((_) {
          final input = file.openRead();
          int position = 0;
          final int expectedLength = 200000;

          // Start an independent asynchronous check on the length.
          Future lengthTest() {
            asyncTestStarted();
            return file.length().then((len) {
              Expect.equals(expectedLength, len);
              asyncTestDone('testReadWriteStreamLargeFile: length check');
            });
          }

          // Immediate read should read 0 bytes.
          Future contentTest() {
            asyncTestStarted();
            var completer = new Completer();
            input.listen(
              (List<int> data) {
                for (int i = 0; i < data.length; ++i) {
                  Expect.equals(
                    buffer[(i + position) % buffer.length],
                    data[i],
                  );
                }
                position += data.length;
              },
              onError: (error, trace) {
                print('Error on input in testReadWriteStreamLargeFile');
                print('with error $error');
                if (trace != null) print("StackTrace: $trace");
                throw error;
              },
              onDone: () {
                Expect.equals(expectedLength, position);
                testPipe(file, buffer)
                    .then((_) {
                      asyncTestDone('testReadWriteStreamLargeFile: main test');
                    })
                    .catchError((error, trace) {
                      print(
                        'Exception while deleting ReadWriteStreamLargeFile file',
                      );
                      print('Exception $error');
                      if (trace != null) print("StackTrace: $trace");
                      throw error;
                    })
                    .whenComplete(completer.complete);
              },
            );
            return completer.future;
          }

          return Future.forEach<Function>([
            lengthTest,
            contentTest,
          ], (test) => test());
        })
        .whenComplete(file.delete)
        .whenComplete(() {
          asyncTestDone('testReadWriteStreamLargeFile finished');
        });
  }

  static Future testReadAsBytesLargeFile() async {
    asyncTestStarted();
    // On Windows and macOS, it is an error to call
    // `read/_read(fildes, buf, nbyte)` with `nbyte >= INT_MAX` and, on Linux,
    // it returns partial data.
    return largeFile.readAsBytes().then(
      (bytes) {
        Expect.equals(largeFileSize, bytes.length);
        Expect.listEquals(
          largeFileLastBytes,
          Uint8List.sublistView(
            bytes,
            bytes.length - largeFileLastBytes.length,
          ),
        );
        asyncTestDone("testReadAsBytesLargeFile");
      },
      onError: (e) {
        // The test fails on 32-bit platforms or when using compressed
        // pointers. It is not possible to identify when running with
        // compressed pointers.
        Expect.type<OutOfMemoryError>(e);
        asyncTestDone("testReadAsBytesLargeFile");
      },
    );
  }

  static testReadAsBytesSyncLargeFile() {
    asyncTestStarted();
    // On Windows and macOS, it is an error to call
    // `read/_read(fildes, buf, nbyte)` with `nbyte >= INT_MAX` and, on Linux,
    // it returns partial data.
    Uint8List? bytes;
    try {
      bytes = largeFile.readAsBytesSync();
    } on OutOfMemoryError catch (e) {
      // The test fails on 32-bit platforms or when using compressed
      // pointers. It is not possible to identify when running with
      // compressed pointers.
      asyncTestDone("testReadAsBytesSyncLargeFile");
      return;
    }
    Expect.equals(largeFileSize, bytes.length);
    Expect.listEquals(
      largeFileLastBytes,
      Uint8List.sublistView(bytes, bytes.length - largeFileLastBytes.length),
    );
    asyncTestDone("testReadAsBytesSyncLargeFile");
  }

  static String getFilename(String path) {
    return Platform.script.resolve(path).toFilePath();
  }

  // Main test entrypoint.
  static testMain() async {
    asyncTestStarted();

    await setupTempDirectory(() async {
      await testReadWriteStreamLargeFile();
      await createLargeFile(() async {
        await testReadAsBytesLargeFile();
        testReadAsBytesSyncLargeFile();
      });
    });

    asyncTestDone("all");
  }
}

main() {
  FileTest.testMain();
}
