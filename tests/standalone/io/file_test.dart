// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file I/O.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

class MyListOfOneElement implements List {
  int _value;
  MyListOfOneElement(this._value);
  int get length => 1;
  operator [](int index) => _value;
}

class FileTest {
  static Directory tempDirectory;
  static int numLiveAsyncTests = 0;
  static ReceivePort port;

  static void asyncTestStarted() { ++numLiveAsyncTests; }
  static void asyncTestDone(String name) {
    --numLiveAsyncTests;
    if (numLiveAsyncTests == 0) {
      deleteTempDirectory();
      port.close();
    }
  }

  static void createTempDirectory(Function doNext) {
    new Directory('').createTemp().then((temp) {
      tempDirectory = temp;
      doNext();
    });
  }

  static void deleteTempDirectory() {
    tempDirectory.deleteSync(recursive: true);
  }

  // Test for file read functionality.
  static void testReadStream() {
    // Read a file and check part of it's contents.
    String filename = getFilename("bin/file_test.cc");
    File file = new File(filename);
    Expect.isTrue('$file'.contains(file.path));
    var subscription;
    List<int> buffer = new List<int>();
    subscription = file.openRead().listen(
        (d) {
          buffer.addAll(d);
          if (buffer.length >= 12) {
            subscription.cancel();
            Expect.equals(47, buffer[0]);  // represents '/' in the file.
            Expect.equals(47, buffer[1]);  // represents '/' in the file.
            Expect.equals(32, buffer[2]);  // represents ' ' in the file.
            Expect.equals(67, buffer[3]);  // represents 'C' in the file.
            Expect.equals(111, buffer[4]);  // represents 'o' in the file.
            Expect.equals(112, buffer[5]);  // represents 'p' in the file.
            Expect.equals(121, buffer[6]);  // represents 'y' in the file.
            Expect.equals(114, buffer[7]);  // represents 'r' in the file.
            Expect.equals(105, buffer[8]);  // represents 'i' in the file.
            Expect.equals(103, buffer[9]);  // represents 'g' in the file.
            Expect.equals(104, buffer[10]);  // represents 'h' in the file.
            Expect.equals(116, buffer[11]);  // represents 't' in the file.
          }
        });
  }

  // Test for file read and write functionality.
  static void testReadWriteStream() {
    asyncTestStarted();

    // Read a file.
    String inFilename = getFilename("tests/vm/data/fixed_length_file");
    File file;
    int bytesRead;

    var file1 = new File(inFilename);
    List<int> buffer = new List<int>();
    file1.openRead().listen(
      (d) {
        buffer.addAll(d);
      },
      onDone: () {
        Expect.equals(42, buffer.length);
        // Write the contents of the file just read into another file.
        String outFilename =
            tempDirectory.path + "/out_read_write_stream";
        var file2 = new File(outFilename);
        var output = file2.openWrite();
        output.add(buffer);
        output.close();
        output.done.then((_) {
          // Now read the contents of the file just written.
          List<int> buffer2 = new List<int>();
          new File(outFilename).openRead().listen(
              (d) {
                buffer2.addAll(d);
              },
              onDone: () {
                Expect.equals(42, buffer2.length);
                // Now compare the two buffers to check if they are
                // identical.
                for (int i = 0; i < buffer.length; i++) {
                  Expect.equals(buffer[i],  buffer2[i]);
                }
                // Delete the output file.
                file2.deleteSync();
                Expect.isFalse(file2.existsSync());
                asyncTestDone("testReadWriteStream");
              });
          });
      });
  }

  // Test for file stream buffered handling of large files.
  static void testReadWriteStreamLargeFile() {
    asyncTestStarted();

    // Create the test data - arbitrary binary data.
    List<int> buffer = new List<int>(100000);
    for (var i = 0; i < buffer.length; ++i) {
      buffer[i] = i % 256;
    }
    String filename =
        tempDirectory.path + "/out_read_write_stream_large_file";
    File file = new File(filename);
    IOSink output = file.openWrite();
    output.add(buffer);
    output.add(buffer);
    output.close();
    output.done.then((_) {
      Stream input = file.openRead();
      int position = 0;
      final int expectedLength = 200000;
      // Start an independent asynchronous check on the length.
      asyncTestStarted();
      file.length().then((len) {
        Expect.equals(expectedLength, len);
        asyncTestDone('testReadWriteStreamLargeFile: length check');
      });

      // Immediate read should read 0 bytes.
      input.listen(
        (d) {
          for (int i = 0; i < d.length; ++i) {
            Expect.equals(buffer[(i + position) % buffer.length], d[i]);
          }
          position += d.length;
        },
        onError: (error) {
          print('Error on input in testReadWriteStreamLargeFile');
          print('with error $error');
          var trace = getAttachedStackTrace(error);
          if (trace != null) print("StackTrace: $trace");
          throw error;
        },
        onDone: () {
          Expect.equals(expectedLength, position);
          testPipe(file, buffer)
              .then((_) => file.delete())
              .then((_) {
                  asyncTestDone('testReadWriteStreamLargeFile: main test');
              })
              .catchError((e) {
                print('Exception while deleting ReadWriteStreamLargeFile file');
                print('Exception $e');
                var trace = getAttachedStackTrace(e);
                if (trace != null) print("StackTrace: $trace");
              });
        });
    });
  }

  static Future testPipe(File file, buffer) {
    String outputFilename = '${file.path}_copy';
    File outputFile = new File(outputFilename);
    var input = file.openRead();
    var output = outputFile.openWrite();
    Completer done = new Completer();
    input.pipe(output).then((_) {
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
            outputFile.delete().then((ignore) { done.complete(); });
          });
      });
    return done.future;
  }

  static void testRead() {
    ReceivePort port = new ReceivePort();
    // Read a file and check part of it's contents.
    String filename = getFilename("bin/file_test.cc");
    File file = new File(filename);
    file.open(mode: READ).then((RandomAccessFile file) {
      List<int> buffer = new List<int>(10);
      file.readInto(buffer, 0, 5).then((bytes_read) {
        Expect.equals(5, bytes_read);
        file.readInto(buffer, 5, 10).then((bytes_read) {
          Expect.equals(5, bytes_read);
          Expect.equals(47, buffer[0]);  // represents '/' in the file.
          Expect.equals(47, buffer[1]);  // represents '/' in the file.
          Expect.equals(32, buffer[2]);  // represents ' ' in the file.
          Expect.equals(67, buffer[3]);  // represents 'C' in the file.
          Expect.equals(111, buffer[4]);  // represents 'o' in the file.
          Expect.equals(112, buffer[5]);  // represents 'p' in the file.
          Expect.equals(121, buffer[6]);  // represents 'y' in the file.
          Expect.equals(114, buffer[7]);  // represents 'r' in the file.
          Expect.equals(105, buffer[8]);  // represents 'i' in the file.
          Expect.equals(103, buffer[9]);  // represents 'g' in the file.
          file.close().then((ignore) => port.close());
        });
      });
    });
  }

  static void testReadSync() {
    // Read a file and check part of it's contents.
    String filename = getFilename("bin/file_test.cc");
    RandomAccessFile raf = (new File(filename)).openSync();
    List<int> buffer = new List<int>(42);
    int bytes_read = 0;
    bytes_read = raf.readIntoSync(buffer, 0, 12);
    Expect.equals(12, bytes_read);
    bytes_read = raf.readIntoSync(buffer, 12, 42);
    Expect.equals(30, bytes_read);
    Expect.equals(47, buffer[0]);  // represents '/' in the file.
    Expect.equals(47, buffer[1]);  // represents '/' in the file.
    Expect.equals(32, buffer[2]);  // represents ' ' in the file.
    Expect.equals(67, buffer[3]);  // represents 'C' in the file.
    Expect.equals(111, buffer[4]);  // represents 'o' in the file.
    Expect.equals(112, buffer[5]);  // represents 'p' in the file.
    Expect.equals(121, buffer[6]);  // represents 'y' in the file.
    Expect.equals(114, buffer[7]);  // represents 'r' in the file.
    Expect.equals(105, buffer[8]);  // represents 'i' in the file.
    Expect.equals(103, buffer[9]);  // represents 'g' in the file.
    Expect.equals(104, buffer[10]);  // represents 'h' in the file.
    Expect.equals(116, buffer[11]);  // represents 't' in the file.

    filename = getFilename("tests/vm/data/fixed_length_file");
    File file = new File(filename);
    int len = file.lengthSync();
    Expect.equals(0, file.openSync().readSync(0).length);
    Expect.equals(1, file.openSync().readSync(1).length);
    Expect.equals(len - 1, file.openSync().readSync(len - 1).length);
    Expect.equals(len, file.openSync().readSync(len).length);
    Expect.equals(len, file.openSync().readSync(len + 1).length);
    Expect.equals(len, file.openSync().readSync(len * 2).length);
    Expect.equals(len, file.openSync().readSync(len * 10).length);
  }

  // Test for file read and write functionality.
  static void testReadWrite() {
    // Read a file.
    String inFilename = getFilename("tests/vm/data/fixed_length_file");
    final File file = new File(inFilename);
    file.open(mode: READ).then((openedFile) {
      List<int> buffer1 = new List<int>(42);
      openedFile.readInto(buffer1, 0, 42).then((bytes_read) {
        Expect.equals(42, bytes_read);
        openedFile.close().then((ignore) {
          // Write the contents of the file just read into another file.
          String outFilename = tempDirectory.path + "/out_read_write";
          final File file2 = new File(outFilename);
          file2.create().then((ignore) {
            file2.fullPath().then((s) {
              Expect.isTrue(new File(s).existsSync());
              if (s[0] != '/' && s[0] != '\\' && s[1] != ':') {
                Expect.fail("Not a full path");
              }
              file2.open(mode: WRITE).then((openedFile2) {
                openedFile2.writeFrom(buffer1, 0, bytes_read).then((ignore) {
                  openedFile2.close().then((ignore) {
                    List<int> buffer2 = new List<int>(bytes_read);
                    final File file3 = new File(outFilename);
                    file3.open(mode: READ).then((openedFile3) {
                      openedFile3.readInto(buffer2, 0, 42).then((bytes_read) {
                        Expect.equals(42, bytes_read);
                        openedFile3.close().then((ignore) {
                          // Now compare the two buffers to check if they
                          // are identical.
                          Expect.equals(buffer1.length, buffer2.length);
                          for (int i = 0; i < buffer1.length; i++) {
                            Expect.equals(buffer1[i],  buffer2[i]);
                          }
                          // Delete the output file.
                          final file4 = file3;
                          file4.delete().then((ignore) {
                            file4.exists().then((exists) {
                              Expect.isFalse(exists);
                              asyncTestDone("testReadWrite");
                            });
                          });
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      });
    });
    asyncTestStarted();
  }

  static void testWriteAppend() {
    String content = "foobar";
    String filename = tempDirectory.path + "/write_append";
    File file = new File(filename);
    file.createSync();
    Expect.isTrue(new File(filename).existsSync());
    List<int> buffer = content.codeUnits;
    RandomAccessFile openedFile = file.openSync(mode: WRITE);
    openedFile.writeFromSync(buffer, 0, buffer.length);
    openedFile.closeSync();
    // Reopen the file in write mode to ensure that we overwrite the content.
    openedFile = (new File(filename)).openSync(mode: WRITE);
    openedFile.writeFromSync(buffer, 0, buffer.length);
    Expect.equals(content.length, openedFile.lengthSync());
    openedFile.closeSync();
    // Open the file in append mode and ensure that we do not overwrite
    // the existing content.
    openedFile = (new File(filename)).openSync(mode: APPEND);
    openedFile.writeFromSync(buffer, 0, buffer.length);
    Expect.equals(content.length * 2, openedFile.lengthSync());
    openedFile.closeSync();
    file.deleteSync();
  }

  static void testOutputStreamWriteAppend() {
    String content = "foobar";
    String filename = tempDirectory.path + "/outstream_write_append";
    File file = new File(filename);
    file.createSync();
    List<int> buffer = content.codeUnits;
    var output = file.openWrite();
    output.add(buffer);
    output.close();
    output.done.then((_) {
      File file2 = new File(filename);
      var appendingOutput = file2.openWrite(mode: APPEND);
      appendingOutput.add(buffer);
      appendingOutput.close();
      appendingOutput.done.then((_) {
        File file3 = new File(filename);
        file3.open(mode: READ).then((RandomAccessFile openedFile) {
          openedFile.length().then((int length) {
            Expect.equals(content.length * 2, length);
            openedFile.close().then((ignore) {
              file3.delete().then((ignore) {
                asyncTestDone("testOutputStreamWriteAppend");
              });
            });
          });
        });
      });
    });
    asyncTestStarted();
  }

  // Test for file read and write functionality.
  static void testOutputStreamWriteString() {
    String content = "foobar";
    String filename = tempDirectory.path + "/outstream_write_string";
    File file = new File(filename);
    file.createSync();
    List<int> buffer = content.codeUnits;
    var output = file.openWrite();
    output.write("abcdABCD");
    output.encoding = UTF_8;
    output.write("abcdABCD");
    output.encoding = ISO_8859_1;
    output.write("abcdABCD");
    output.encoding = ASCII;
    output.write("abcdABCD");
    output.encoding = UTF_8;
    output.write("æøå");
    output.close();
    output.done.then((_) {
      RandomAccessFile raf = file.openSync();
      Expect.equals(38, raf.lengthSync());
      raf.close().then((ignore) {
        asyncTestDone("testOutputStreamWriteString");
      });
    });
    asyncTestStarted();
  }


  static void testReadWriteSync() {
    // Read a file.
    String inFilename = getFilename("tests/vm/data/fixed_length_file");
    RandomAccessFile file = (new File(inFilename)).openSync();
    List<int> buffer1 = new List<int>(42);
    int bytes_read = 0;
    int bytes_written = 0;
    bytes_read = file.readIntoSync(buffer1, 0, 42);
    Expect.equals(42, bytes_read);
    file.closeSync();
    // Write the contents of the file just read into another file.
    String outFilename = tempDirectory.path + "/out_read_write_sync";
    File outFile = new File(outFilename);
    outFile.createSync();
    String path = outFile.fullPathSync();
    if (path[0] != '/' && path[0] != '\\' && path[1] != ':') {
      Expect.fail("Not a full path");
    }
    Expect.isTrue(new File(path).existsSync());
    RandomAccessFile openedFile = outFile.openSync(mode: WRITE);
    openedFile.writeFromSync(buffer1, 0, bytes_read);
    openedFile.closeSync();
    // Now read the contents of the file just written.
    List<int> buffer2 = new List<int>(bytes_read);
    openedFile = (new File(outFilename)).openSync();
    bytes_read = openedFile.readIntoSync(buffer2, 0, 42);
    Expect.equals(42, bytes_read);
    openedFile.closeSync();
    // Now compare the two buffers to check if they are identical.
    Expect.equals(buffer1.length, buffer2.length);
    for (int i = 0; i < buffer1.length; i++) {
      Expect.equals(buffer1[i],  buffer2[i]);
    }
    // Delete the output file.
    outFile.deleteSync();
    Expect.isFalse(outFile.existsSync());
  }

  static void testReadWriteNoArgsSync() {
    // Read a file.
    String inFilename = getFilename("tests/vm/data/fixed_length_file");
    RandomAccessFile file = (new File(inFilename)).openSync();
    List<int> buffer1 = new List<int>(42);
    int bytes_read = 0;
    int bytes_written = 0;
    bytes_read = file.readIntoSync(buffer1);
    Expect.equals(42, bytes_read);
    file.closeSync();
    // Write the contents of the file just read into another file.
    String outFilename = tempDirectory.path + "/out_read_write_sync";
    File outFile = new File(outFilename);
    outFile.createSync();
    String path = outFile.fullPathSync();
    if (path[0] != '/' && path[0] != '\\' && path[1] != ':') {
      Expect.fail("Not a full path");
    }
    Expect.isTrue(new File(path).existsSync());
    RandomAccessFile openedFile = outFile.openSync(mode: WRITE);
    openedFile.writeFromSync(buffer1);
    openedFile.closeSync();
    // Now read the contents of the file just written.
    List<int> buffer2 = new List<int>(bytes_read);
    openedFile = (new File(outFilename)).openSync();
    bytes_read = openedFile.readIntoSync(buffer2, 0);
    Expect.equals(42, bytes_read);
    openedFile.closeSync();
    // Now compare the two buffers to check if they are identical.
    Expect.equals(buffer1.length, buffer2.length);
    for (int i = 0; i < buffer1.length; i++) {
      Expect.equals(buffer1[i],  buffer2[i]);
    }
    // Delete the output file.
    outFile.deleteSync();
    Expect.isFalse(outFile.existsSync());
  }

  static void testReadEmptyFileSync() {
    String fileName = tempDirectory.path + "/empty_file_sync";
    File file = new File(fileName);
    file.createSync();
    RandomAccessFile openedFile = file.openSync();
    Expect.equals(-1, openedFile.readByteSync());
    openedFile.closeSync();
    file.deleteSync();
  }

  static void testReadEmptyFile() {
    String fileName = tempDirectory.path + "/empty_file";
    File file = new File(fileName);
    asyncTestStarted();
    file.create().then((ignore) {
      file.open(mode: READ).then((RandomAccessFile openedFile) {
        var readByteFuture = openedFile.readByte();
        readByteFuture.then((int byte) {
          Expect.equals(-1, byte);
          openedFile.close().then((ignore) {
            asyncTestDone("testReadEmptyFile");
          });
        });
      });
    });
  }

  // Test for file write of different types of lists.
  static void testWriteVariousLists() {
    asyncTestStarted();
    final String fileName = "${tempDirectory.path}/testWriteVariousLists";
    final File file = new File(fileName);
    file.create().then((ignore) {
      file.open(mode: WRITE).then((RandomAccessFile openedFile) {
        // Write bytes from 0 to 7.
        openedFile.writeFrom([0], 0, 1);
        openedFile.writeFrom(const [1], 0, 1);
        openedFile.writeFrom(new MyListOfOneElement(2), 0, 1);
        var x = 12345678901234567890123456789012345678901234567890;
        var y = 12345678901234567890123456789012345678901234567893;
        openedFile.writeFrom([y - x], 0, 1);
        openedFile.writeFrom([260], 0, 1);  // 260 = 256 + 4 = 0x104.
        openedFile.writeFrom(const [261], 0, 1);
        openedFile.writeFrom(new MyListOfOneElement(262), 0, 1);
        x = 12345678901234567890123456789012345678901234567890;
        y = 12345678901234567890123456789012345678901234568153;
        openedFile.writeFrom([y - x], 0, 1).then((ignore) {
          openedFile.close().then((ignore) {
            // Check the written bytes.
            final File file2 = new File(fileName);
            var openedFile2 = file2.openSync();
            var length = openedFile2.lengthSync();
            Expect.equals(8, length);
            List data = new List(length);
            openedFile2.readIntoSync(data, 0, length);
            for (var i = 0; i < data.length; i++) {
              Expect.equals(i, data[i]);
            }
            openedFile2.closeSync();
            file2.deleteSync();
            asyncTestDone("testWriteVariousLists");
          });
        });
      });
    });
  }

  static void testDirectory() {
    asyncTestStarted();

    // Port to verify that the test completes.
    var port = new ReceivePort();
    port.receive((message, replyTo) {
      port.close();
      Expect.equals(1, message);
      asyncTestDone("testDirectory");
    });

    var tempDir = tempDirectory.path;
    var file = new File("${tempDir}/testDirectory");
    var errors = 0;
    var dirFuture = file.directory();
    dirFuture.then((d) => Expect.fail("non-existing file"))
    .catchError((e) {
      file.create().then((ignore) {
        file.directory().then((Directory d) {
          d.exists().then((exists) {
            Expect.isTrue(exists);
            Expect.isTrue(d.path.endsWith(tempDir));
            file.delete().then((ignore) {
              var fileDir = new File(".");
              var dirFuture2 = fileDir.directory();
              dirFuture2.then((d) => Expect.fail("non-existing file"))
              .catchError((e) {
                var fileDir = new File(tempDir);
                var dirFuture3 = fileDir.directory();
                dirFuture3.then((d) => Expect.fail("non-existing file"))
                .catchError((e) {
                  port.toSendPort().send(1);
                });
              });
            });
          });
        });
      });
    });
  }

  static void testDirectorySync() {
    var tempDir = tempDirectory.path;
    var file = new File("${tempDir}/testDirectorySync");
    // Non-existing file should throw exception.
    Expect.throws(file.directorySync, (e) { return e is FileIOException; });
    file.createSync();
    // Check that the path of the returned directory is the temp directory.
    Directory d = file.directorySync();
    Expect.isTrue(d.existsSync());
    Expect.isTrue(d.path.endsWith(tempDir));
    file.deleteSync();
    // Directories should throw exception.
    var file_dir = new File(".");
    Expect.throws(file_dir.directorySync, (e) { return e is FileIOException; });
    file_dir = new File(tempDir);
    Expect.throws(file_dir.directorySync, (e) { return e is FileIOException; });
  }

  // Test for file length functionality.
  static void testLength() {
    var port = new ReceivePort();
    String filename = getFilename("tests/vm/data/fixed_length_file");
    File file = new File(filename);
    RandomAccessFile openedFile = file.openSync();
    openedFile.length().then((length) {
      Expect.equals(42, length);
      openedFile.close().then((ignore) => port.close());
    });
    file.length().then((length) {
      Expect.equals(42, length);
    });
  }

  static void testLengthSync() {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    File file = new File(filename);
    RandomAccessFile openedFile = file.openSync();
    Expect.equals(42, file.lengthSync());
    Expect.equals(42, openedFile.lengthSync());
    openedFile.closeSync();
  }

  // Test for file position functionality.
  static void testPosition() {
    var port = new ReceivePort();
    String filename = getFilename("tests/vm/data/fixed_length_file");
    RandomAccessFile input = (new File(filename)).openSync();
    input.position().then((position) {
      Expect.equals(0, position);
      List<int> buffer = new List<int>(100);
      input.readInto(buffer, 0, 12).then((bytes_read) {
        input.position().then((position) {
          Expect.equals(12, position);
          input.readInto(buffer, 12, 18).then((bytes_read) {
            input.position().then((position) {
              Expect.equals(18, position);
              input.setPosition(8).then((ignore) {
                input.position().then((position) {
                  Expect.equals(8, position);
                  input.close().then((ignore) => port.close());
                });
              });
            });
          });
        });
      });
    });
  }

  static void testPositionSync() {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    RandomAccessFile input = (new File(filename)).openSync();
    Expect.equals(0, input.positionSync());
    List<int> buffer = new List<int>(100);
    input.readIntoSync(buffer, 0, 12);
    Expect.equals(12, input.positionSync());
    input.readIntoSync(buffer, 12, 18);
    Expect.equals(18, input.positionSync());
    input.setPositionSync(8);
    Expect.equals(8, input.positionSync());
    input.closeSync();
  }

  static void testTruncate() {
    File file = new File(tempDirectory.path + "/out_truncate");
    List buffer = const [65, 65, 65, 65, 65, 65, 65, 65, 65, 65];
    file.open(mode: WRITE).then((RandomAccessFile openedFile) {
      openedFile.writeFrom(buffer, 0, 10).then((ignore) {
        openedFile.length().then((length) {
          Expect.equals(10, length);
          openedFile.truncate(5).then((ignore) {
            openedFile.length().then((length) {
              Expect.equals(5, length);
              openedFile.close().then((ignore) {
                file.delete().then((ignore) {
                  file.exists().then((exists) {
                    Expect.isFalse(exists);
                    asyncTestDone("testTruncate");
                  });
                });
              });
            });
          });
        });
      });
    });
    asyncTestStarted();
  }

  static void testTruncateSync() {
    File file = new File(tempDirectory.path + "/out_truncate_sync");
    List buffer = const [65, 65, 65, 65, 65, 65, 65, 65, 65, 65];
    RandomAccessFile openedFile = file.openSync(mode: WRITE);
    openedFile.writeFromSync(buffer, 0, 10);
    Expect.equals(10, openedFile.lengthSync());
    openedFile.truncateSync(5);
    Expect.equals(5, openedFile.lengthSync());
    openedFile.closeSync();
    file.deleteSync();
    Expect.isFalse(file.existsSync());
  }

  // Tests exception handling after file was closed.
  static void testCloseException() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    File input = new File(tempDirectory.path + "/out_close_exception");
    RandomAccessFile openedFile = input.openSync(mode: WRITE);
    openedFile.closeSync();
    try {
      openedFile.readByteSync();
    } on FileIOException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.writeByteSync(1);
    } on FileIOException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.writeStringSync("Test");
    } on FileIOException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(100);
      openedFile.readIntoSync(buffer, 0, 10);
    } on FileIOException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(100);
      openedFile.writeFromSync(buffer, 0, 10);
    } on FileIOException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.positionSync();
    } on FileIOException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.lengthSync();
    } on FileIOException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.flushSync();
    } on FileIOException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    input.deleteSync();
  }

  // Tests stream exception handling after file was closed.
  static void testCloseExceptionStream() {
    asyncTestStarted();
    List<int> buffer = new List<int>(42);
    File file =
        new File(tempDirectory.path + "/out_close_exception_stream");
    file.createSync();
    var output = file.openWrite();
    output.close();
    Expect.throws(() => output.add(buffer));
    output.done.then((_) {
      file.deleteSync();
      asyncTestDone("testCloseExceptionStream");
    });
  }

  // Tests buffer out of bounds exception.
  static void testBufferOutOfBoundsException() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    File file =
        new File(tempDirectory.path + "/out_buffer_out_of_bounds");
    RandomAccessFile openedFile = file.openSync(mode: WRITE);
    try {
      List<int> buffer = new List<int>(10);
      openedFile.readIntoSync(buffer, 0, 12);
    } on RangeError catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.readIntoSync(buffer, 6, 12);
    } on RangeError catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.readIntoSync(buffer, -1, 1);
    } on RangeError catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.readIntoSync(buffer, 0, -1);
    } on RangeError catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.writeFromSync(buffer, 0, 12);
    } on RangeError catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.writeFromSync(buffer, 6, 12);
    } on RangeError catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.writeFromSync(buffer, -1, 1);
    } on RangeError catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.writeFromSync(buffer, 0, -1);
    } on RangeError catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    openedFile.closeSync();
    file.deleteSync();
  }

  static void testOpenDirectoryAsFile() {
    var f = new File('.');
    var future = f.open(mode: READ);
    future.then((r) => Expect.fail('Directory opened as file'))
          .catchError((e) {});
  }

  static void testOpenDirectoryAsFileSync() {
    var f = new File('.');
    try {
      f.openSync();
      Expect.fail("Expected exception opening directory as file");
    } catch (e) {
      Expect.isTrue(e is FileIOException);
    }
  }

  static void testOpenFileFromPath() {
    var name = getFilename("tests/vm/data/fixed_length_file");
    var path = new Path(name);
    var f = new File.fromPath(path);
    Expect.isTrue(f.existsSync());
    name = f.fullPathSync();
    path = new Path(name);
    var g = new File.fromPath(path);
    Expect.isTrue(g.existsSync());
    Expect.equals(name, g.fullPathSync());
  }

  static void testReadAsBytes() {
    var port = new ReceivePort();
    port.receive((result, replyTo) {
      port.close();
      Expect.equals(42, result);
    });
    var name = getFilename("tests/vm/data/fixed_length_file");
    var f = new File(name);
    f.readAsBytes().then((bytes) {
      Expect.isTrue(new String.fromCharCodes(bytes).endsWith("42 bytes."));
      port.toSendPort().send(bytes.length);
    });
  }

  static void testReadAsBytesEmptyFile() {
    var port = new ReceivePort();
    port.receive((result, replyTo) {
      port.close();
      Expect.equals(0, result);
    });
    var name = getFilename("tests/vm/data/empty_file");
    var f = new File(name);
    f.readAsBytes().then((bytes) {
      port.toSendPort().send(bytes.length);
    });
  }

  static void testReadAsBytesSync() {
    var name = getFilename("tests/vm/data/fixed_length_file");
    var bytes = new File(name).readAsBytesSync();
    Expect.isTrue(new String.fromCharCodes(bytes).endsWith("42 bytes."));
    Expect.equals(bytes.length, 42);
  }

  static void testReadAsBytesSyncEmptyFile() {
    var name = getFilename("tests/vm/data/empty_file");
    var bytes = new File(name).readAsBytesSync();
    Expect.equals(bytes.length, 0);
  }

  static void testReadAsText() {
    var port = new ReceivePort();
    port.receive((result, replyTo) {
      port.close();
      Expect.equals(1, result);
    });
    var name = getFilename("tests/vm/data/fixed_length_file");
    var f = new File(name);
    f.readAsString(encoding: UTF_8).then((text) {
      Expect.isTrue(text.endsWith("42 bytes."));
      Expect.equals(42, text.length);
      var name = getDataFilename("tests/standalone/io/read_as_text.dat");
      var f = new File(name);
      f.readAsString(encoding: UTF_8).then((text) {
        Expect.equals(6, text.length);
        var expected = [955, 120, 46, 32, 120, 10];
        Expect.listEquals(expected, text.codeUnits);
        f.readAsString(encoding: ISO_8859_1).then((text) {
          Expect.equals(7, text.length);
          var expected = [206, 187, 120, 46, 32, 120, 10];
          Expect.listEquals(expected, text.codeUnits);
          var readAsStringFuture = f.readAsString(encoding: ASCII);
          readAsStringFuture.then((text) {
            Expect.fail("Non-ascii char should cause error");
          }).catchError((e) {
            port.toSendPort().send(1);
          });
        });
      });
    });
  }

  static void testReadAsTextEmptyFile() {
    var port = new ReceivePort();
    port.receive((result, replyTo) {
      port.close();
      Expect.equals(0, result);
    });
    var name = getFilename("tests/vm/data/empty_file");
    var f = new File(name);
    f.readAsString(encoding: UTF_8).then((text) {
      port.toSendPort().send(text.length);
      return true;
    });
  }

  static void testReadAsTextSync() {
    var name = getFilename("tests/vm/data/fixed_length_file");
    var text = new File(name).readAsStringSync();
    Expect.isTrue(text.endsWith("42 bytes."));
    Expect.equals(42, text.length);
    name = getDataFilename("tests/standalone/io/read_as_text.dat");
    text = new File(name).readAsStringSync();
    Expect.equals(6, text.length);
    var expected = [955, 120, 46, 32, 120, 10];
    Expect.listEquals(expected, text.codeUnits);
    text = new File(name).readAsStringSync(encoding: ASCII);
    // Default replacement character is '?', char code 63.
    expected = [63, 63, 120, 46, 32, 120, 10];
    Expect.listEquals(expected, text.codeUnits);
    text = new File(name).readAsStringSync(encoding: ISO_8859_1);
    expected = [206, 187, 120, 46, 32, 120, 10];
    Expect.equals(7, text.length);
    Expect.listEquals(expected, text.codeUnits);
  }

  static void testReadAsTextSyncEmptyFile() {
    var name = getFilename("tests/vm/data/empty_file");
    var text = new File(name).readAsStringSync();
    Expect.equals(0, text.length);
  }

  static void testReadAsLines() {
    var port = new ReceivePort();
    port.receive((result, replyTo) {
      port.close();
      Expect.equals(42, result);
    });
    var name = getFilename("tests/vm/data/fixed_length_file");
    var f = new File(name);
    f.readAsLines(encoding: UTF_8).then((lines) {
      Expect.equals(1, lines.length);
      var line = lines[0];
      Expect.isTrue(line.endsWith("42 bytes."));
      port.toSendPort().send(line.length);
    });
  }

  static void testReadAsLinesSync() {
    var name = getFilename("tests/vm/data/fixed_length_file");
    var lines = new File(name).readAsLinesSync();
    Expect.equals(1, lines.length);
    var line = lines[0];
    Expect.isTrue(line.endsWith("42 bytes."));
    Expect.equals(42, line.length);
    name = getDataFilename("tests/standalone/io/readline_test1.dat");
    lines = new File(name).readAsLinesSync();
    Expect.equals(10, lines.length);
  }


  static void testReadAsErrors() {
    var port = new ReceivePort();
    port.receive((message, _) {
      port.close();
      Expect.equals(1, message);
    });
    var f = new File('.');
    Expect.throws(f.readAsBytesSync, (e) => e is FileIOException);
    Expect.throws(f.readAsStringSync, (e) => e is FileIOException);
    Expect.throws(f.readAsLinesSync, (e) => e is FileIOException);
    var readAsBytesFuture = f.readAsBytes();
    readAsBytesFuture.then((bytes) => Expect.fail("no bytes expected"))
    .catchError((e) {
      var readAsStringFuture = f.readAsString(encoding: UTF_8);
      readAsStringFuture.then((text) => Expect.fail("no text expected"))
      .catchError((e) {
        var readAsLinesFuture = f.readAsLines(encoding: UTF_8);
        readAsLinesFuture.then((lines) => Expect.fail("no lines expected"))
        .catchError((e) {
          port.toSendPort().send(1);
        });
      });
    });
  }

  static void testLastModified() {
    var port = new ReceivePort();
    new File(new Options().executable).lastModified().then((modified) {
      Expect.isTrue(modified is DateTime);
      Expect.isTrue(modified.isBefore(new DateTime.now()));
      port.close();
    });
  }

  static void testLastModifiedSync() {
    var modified = new File(new Options().executable).lastModifiedSync();
    Expect.isTrue(modified is DateTime);
    Expect.isTrue(modified.isBefore(new DateTime.now()));
  }

  // Test that opens the same file for writing then for appending to test
  // that the file is not truncated when opened for appending.
  static void testAppend() {
    var file = new File('${tempDirectory.path}/out_append');
    file.open(mode: WRITE).then((openedFile) {
      openedFile.writeString("asdf").then((ignore) {
        openedFile.close().then((ignore) {
          file.open(mode: APPEND).then((openedFile) {
            openedFile.length().then((length) {
              Expect.equals(4, length);
              openedFile.writeString("asdf").then((ignore) {
                openedFile.length().then((length) {
                  Expect.equals(8, length);
                  openedFile.close().then((ignore) {
                    file.delete().then((ignore) {
                      file.exists().then((exists) {
                        Expect.isFalse(exists);
                        asyncTestDone("testAppend");
                      });
                    });
                  });
                });
              });
            });
          });
        });
      });
    });
    asyncTestStarted();
  }

  static void testAppendSync() {
    var file = new File('${tempDirectory.path}/out_append_sync');
    var openedFile = file.openSync(mode: WRITE);
    openedFile.writeStringSync("asdf");
    Expect.equals(4, openedFile.lengthSync());
    openedFile.closeSync();
    openedFile = file.openSync(mode: WRITE);
    openedFile.setPositionSync(4);
    openedFile.writeStringSync("asdf");
    Expect.equals(8, openedFile.lengthSync());
    openedFile.closeSync();
    file.deleteSync();
    Expect.isFalse(file.existsSync());
  }

  static void testWriteStringUtf8() {
    var file = new File('${tempDirectory.path}/out_write_string');
    var string = new String.fromCharCodes([0x192]);
    file.open(mode: WRITE).then((openedFile) {
      openedFile.writeString(string).then((_) {
        openedFile.length().then((l) {
          Expect.equals(2, l);
          openedFile.close().then((_) {
            file.open(mode: APPEND).then((openedFile) {
              openedFile.setPosition(2).then((_) {
                openedFile.writeString(string).then((_) {
                  openedFile.length().then((l) {
                    Expect.equals(4, l);
                    openedFile.close().then((_) {
                      file.readAsString().then((readBack) {
                        Expect.stringEquals(readBack, '$string$string');
                        file.delete().then((_) {
                          file.exists().then((e) {
                           Expect.isFalse(e);
                           asyncTestDone("testWriteStringUtf8");
                          });
                        });
                      });
                    });
                  });
                });
              });
            });
          });
        });
      });
    });
    asyncTestStarted();
  }

  static void testWriteStringUtf8Sync() {
    var file = new File('${tempDirectory.path}/out_write_string_sync');
    var string = new String.fromCharCodes([0x192]);
    var openedFile = file.openSync(mode: WRITE);
    openedFile.writeStringSync(string);
    Expect.equals(2, openedFile.lengthSync());
    openedFile.closeSync();
    openedFile = file.openSync(mode: APPEND);
    openedFile.setPositionSync(2);
    openedFile.writeStringSync(string);
    Expect.equals(4, openedFile.lengthSync());
    openedFile.closeSync();
    var readBack = file.readAsStringSync();
    Expect.stringEquals(readBack, '$string$string');
    file.deleteSync();
    Expect.isFalse(file.existsSync());
  }

  // Helper method to be able to run the test from the runtime
  // directory, or the top directory.
  static String getFilename(String path) =>
      new File(path).existsSync() ? path : 'runtime/$path';

  static String getDataFilename(String path) =>
      new File(path).existsSync() ? path : '../$path';

  // Main test entrypoint.
  static testMain() {
    port = new ReceivePort();
    testRead();
    testReadSync();
    testReadStream();
    testLength();
    testLengthSync();
    testPosition();
    testPositionSync();
    testOpenDirectoryAsFile();
    testOpenDirectoryAsFileSync();
    testOpenFileFromPath();
    testReadAsBytes();
    testReadAsBytesEmptyFile();
    testReadAsBytesSync();
    testReadAsBytesSyncEmptyFile();
    testReadAsText();
    testReadAsTextEmptyFile();
    testReadAsTextSync();
    testReadAsTextSyncEmptyFile();
    testReadAsLines();
    testReadAsLinesSync();
    testReadAsErrors();
    testLastModified();
    testLastModifiedSync();

    createTempDirectory(() {
      testReadWrite();
      testReadWriteSync();
      testReadWriteNoArgsSync();
      testReadWriteStream();
      testReadEmptyFileSync();
      testReadEmptyFile();
      testReadWriteStreamLargeFile();
      testTruncate();
      testTruncateSync();
      testCloseException();
      testCloseExceptionStream();
      testBufferOutOfBoundsException();
      testAppend();
      testAppendSync();
      testWriteAppend();
      testOutputStreamWriteAppend();
      testOutputStreamWriteString();
      testWriteVariousLists();
      testDirectory();
      testDirectorySync();
      testWriteStringUtf8();
      testWriteStringUtf8Sync();
    });
  }
}

main() {
  FileTest.testMain();
}
