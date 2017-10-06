// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file I/O.

// OtherResources=empty_file
// OtherResources=file_test.txt
// OtherResources=fixed_length_file
// OtherResources=read_as_text.dat
// OtherResources=readline_test1.dat

import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

class MyListOfOneElement extends Object
    with ListMixin<int>
    implements List<int> {
  int _value;
  MyListOfOneElement(this._value);
  int get length => 1;
  operator [](int index) => _value;
  void set length(int index) {
    throw "Unsupported";
  }

  operator []=(int index, value) {
    if (index != 0) {
      throw "Unsupported";
    } else {
      _value = value;
    }
  }
}

class FileTest {
  static Directory tempDirectory;
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

  static void createTempDirectory(Function doNext) {
    Directory.systemTemp.createTemp('dart_file').then((temp) {
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
    String filename = getFilename("file_test.txt");
    File file = new File(filename);
    Expect.isTrue('$file'.contains(file.path));
    var subscription;
    List<int> buffer = new List<int>();
    subscription = file.openRead().listen((d) {
      buffer.addAll(d);
      if (buffer.length >= 12) {
        subscription.cancel();
        Expect.equals(47, buffer[0]); // represents '/' in the file.
        Expect.equals(47, buffer[1]); // represents '/' in the file.
        Expect.equals(32, buffer[2]); // represents ' ' in the file.
        Expect.equals(67, buffer[3]); // represents 'C' in the file.
        Expect.equals(111, buffer[4]); // represents 'o' in the file.
        Expect.equals(112, buffer[5]); // represents 'p' in the file.
        Expect.equals(121, buffer[6]); // represents 'y' in the file.
        Expect.equals(114, buffer[7]); // represents 'r' in the file.
        Expect.equals(105, buffer[8]); // represents 'i' in the file.
        Expect.equals(103, buffer[9]); // represents 'g' in the file.
        Expect.equals(104, buffer[10]); // represents 'h' in the file.
        Expect.equals(116, buffer[11]); // represents 't' in the file.
      }
    });
  }

  // Test for file read and write functionality.
  static void testReadWriteStream() {
    asyncTestStarted();

    // Read a file.
    String inFilename = getFilename("fixed_length_file");
    File file;
    int bytesRead;

    var file1 = new File(inFilename);
    List<int> buffer = new List<int>();
    file1.openRead().listen((d) {
      buffer.addAll(d);
    }, onDone: () {
      Expect.equals(42, buffer.length);
      // Write the contents of the file just read into another file.
      String outFilename = tempDirectory.path + "/out_read_write_stream";
      var file2 = new File(outFilename);
      var output = file2.openWrite();
      output.add(buffer);
      output.flush().then((_) => output.close());
      output.done.then((_) {
        // Now read the contents of the file just written.
        List<int> buffer2 = new List<int>();
        new File(outFilename).openRead().listen((d) {
          buffer2.addAll(d);
        }, onDone: () {
          Expect.equals(42, buffer2.length);
          // Now compare the two buffers to check if they are
          // identical.
          for (int i = 0; i < buffer.length; i++) {
            Expect.equals(buffer[i], buffer2[i]);
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
    // Create the test data - arbitrary binary data.
    List<int> buffer = new List<int>(100000);
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
    output.done
        .then((_) {
          Stream input = file.openRead();
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
            input.listen((data) {
              for (int i = 0; i < data.length; ++i) {
                Expect.equals(buffer[(i + position) % buffer.length], data[i]);
              }
              position += data.length;
            }, onError: (error, trace) {
              print('Error on input in testReadWriteStreamLargeFile');
              print('with error $error');
              if (trace != null) print("StackTrace: $trace");
              throw error;
            }, onDone: () {
              Expect.equals(expectedLength, position);
              testPipe(file, buffer).then((_) {
                asyncTestDone('testReadWriteStreamLargeFile: main test');
              }).catchError((error, trace) {
                print('Exception while deleting ReadWriteStreamLargeFile file');
                print('Exception $error');
                if (trace != null) print("StackTrace: $trace");
                throw error;
              }).whenComplete(completer.complete);
            });
            return completer.future;
          }

          return Future.forEach([lengthTest, contentTest], (test) => test());
        })
        .whenComplete(file.delete)
        .whenComplete(() {
          asyncTestDone('testReadWriteStreamLargeFile finished');
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
      copy.listen((d) {
        for (int i = 0; i < d.length; i++) {
          Expect.equals(buffer[(position + i) % buffer.length], d[i]);
        }
        position += d.length;
      }, onDone: () {
        Expect.equals(2 * buffer.length, position);
        outputFile.delete().then((ignore) {
          done.complete();
        });
      });
    });
    return done.future;
  }

  static void testRead() {
    asyncStart();
    // Read a file and check part of it's contents.
    String filename = getFilename("file_test.txt");
    File file = new File(filename);
    file.open(mode: READ).then((RandomAccessFile file) {
      List<int> buffer = new List<int>(10);
      file.readInto(buffer, 0, 5).then((bytes_read) {
        Expect.equals(5, bytes_read);
        file.readInto(buffer, 5, 10).then((bytes_read) {
          Expect.equals(5, bytes_read);
          Expect.equals(47, buffer[0]); // represents '/' in the file.
          Expect.equals(47, buffer[1]); // represents '/' in the file.
          Expect.equals(32, buffer[2]); // represents ' ' in the file.
          Expect.equals(67, buffer[3]); // represents 'C' in the file.
          Expect.equals(111, buffer[4]); // represents 'o' in the file.
          Expect.equals(112, buffer[5]); // represents 'p' in the file.
          Expect.equals(121, buffer[6]); // represents 'y' in the file.
          Expect.equals(114, buffer[7]); // represents 'r' in the file.
          Expect.equals(105, buffer[8]); // represents 'i' in the file.
          Expect.equals(103, buffer[9]); // represents 'g' in the file.
          file.close().then((ignore) => asyncEnd());
        });
      });
    });
  }

  static void testReadSync() {
    // Read a file and check part of it's contents.
    String filename = getFilename("file_test.txt");
    RandomAccessFile raf = (new File(filename)).openSync();
    List<int> buffer = new List<int>(42);
    int bytes_read = 0;
    bytes_read = raf.readIntoSync(buffer, 0, 12);
    Expect.equals(12, bytes_read);
    bytes_read = raf.readIntoSync(buffer, 12, 42);
    Expect.equals(30, bytes_read);
    Expect.equals(47, buffer[0]); // represents '/' in the file.
    Expect.equals(47, buffer[1]); // represents '/' in the file.
    Expect.equals(32, buffer[2]); // represents ' ' in the file.
    Expect.equals(67, buffer[3]); // represents 'C' in the file.
    Expect.equals(111, buffer[4]); // represents 'o' in the file.
    Expect.equals(112, buffer[5]); // represents 'p' in the file.
    Expect.equals(121, buffer[6]); // represents 'y' in the file.
    Expect.equals(114, buffer[7]); // represents 'r' in the file.
    Expect.equals(105, buffer[8]); // represents 'i' in the file.
    Expect.equals(103, buffer[9]); // represents 'g' in the file.
    Expect.equals(104, buffer[10]); // represents 'h' in the file.
    Expect.equals(116, buffer[11]); // represents 't' in the file.
    raf.closeSync();

    filename = getFilename("fixed_length_file");
    File file = new File(filename);
    int len = file.lengthSync();
    int read(int length) {
      var f = file.openSync();
      int res = f.readSync(length).length;
      f.closeSync();
      return res;
    }

    Expect.equals(0, read(0));
    Expect.equals(1, read(1));
    Expect.equals(len - 1, read(len - 1));
    Expect.equals(len, read(len));
    Expect.equals(len, read(len + 1));
    Expect.equals(len, read(len * 2));
    Expect.equals(len, read(len * 10));
  }

  // Test for file read and write functionality.
  static void testReadWrite() {
    asyncTestStarted();
    // Read a file.
    String inFilename = getFilename("fixed_length_file");
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
            file2.resolveSymbolicLinks().then((s) {
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
                            Expect.equals(buffer1[i], buffer2[i]);
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
    openedFile.writeFromSync(buffer, 2, buffer.length - 2);
    Expect.equals(content.length + content.length - 4, openedFile.lengthSync());
    Expect.equals(content + content.substring(2, content.length - 2),
        file.readAsStringSync());
    openedFile.closeSync();
    file.deleteSync();
  }

  static void testOutputStreamWriteAppend() {
    asyncTestStarted();
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
  }

  // Test for file read and write functionality.
  static void testOutputStreamWriteString() {
    asyncTestStarted();
    String content = "foobar";
    String filename = tempDirectory.path + "/outstream_write_string";
    File file = new File(filename);
    file.createSync();
    List<int> buffer = content.codeUnits;
    var output = file.openWrite();
    output.write("abcdABCD");
    output.encoding = UTF8;
    output.write("abcdABCD");
    output.encoding = LATIN1;
    output.write("abcdABCD");
    output.encoding = ASCII;
    output.write("abcdABCD");
    output.encoding = UTF8;
    output.write("æøå");
    output.close();
    output.done.then((_) {
      RandomAccessFile raf = file.openSync();
      Expect.equals(38, raf.lengthSync());
      raf.close().then((ignore) {
        asyncTestDone("testOutputStreamWriteString");
      });
    });
  }

  static void testReadWriteSync() {
    // Read a file.
    String inFilename = getFilename("fixed_length_file");
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
    String path = outFile.resolveSymbolicLinksSync();
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
      Expect.equals(buffer1[i], buffer2[i]);
    }
    // Delete the output file.
    outFile.deleteSync();
    Expect.isFalse(outFile.existsSync());
  }

  static void testReadWriteNoArgsSync() {
    // Read a file.
    String inFilename = getFilename("fixed_length_file");
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
    String path = outFile.resolveSymbolicLinksSync();
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
      Expect.equals(buffer1[i], buffer2[i]);
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
        openedFile.writeFromSync([0], 0, 1);
        openedFile.writeFromSync(const [1], 0, 1);
        openedFile.writeFromSync(new MyListOfOneElement(2), 0, 1);
        var x = 12345678901234567890123456789012345678901234567890;
        var y = 12345678901234567890123456789012345678901234567893;
        openedFile.writeFromSync([y - x], 0, 1);
        openedFile.writeFromSync([260], 0, 1); // 260 = 256 + 4 = 0x104.
        openedFile.writeFromSync(const [261], 0, 1);
        openedFile.writeFromSync(new MyListOfOneElement(262), 0, 1);
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

  static void testWriteFromOffset() {
    Directory tmp;
    RandomAccessFile raf;
    try {
      tmp = tempDirectory.createTempSync('write_from_offset_test_');
      File f = new File('${tmp.path}/file')..createSync();
      f.writeAsStringSync('pre-existing content\n', flush: true);
      raf = f.openSync(mode: FileMode.APPEND);
      String truth = "Hello world";
      raf.writeFromSync(UTF8.encode('Hello world'), 2, 5);
      raf.flushSync();
      Expect.equals(f.readAsStringSync(), 'pre-existing content\nllo');
    } finally {
      if (raf != null) {
        raf.closeSync();
      }
      if (tmp != null) {
        tmp.deleteSync(recursive: true);
      }
    }
  }

  static void testDirectory() {
    asyncTestStarted();
    var tempDir = tempDirectory.path;
    var file = new File("${tempDir}/testDirectory");
    file.create().then((ignore) {
      Directory d = file.parent;
      d.exists().then((xexists) {
        Expect.isTrue(xexists);
        Expect.isTrue(d.path.endsWith(tempDir));
        file.delete().then((ignore) => asyncTestDone("testDirectory"));
      });
    });
  }

  static void testDirectorySync() {
    var tempDir = tempDirectory.path;
    var file = new File("${tempDir}/testDirectorySync");
    // Non-existing file still provides the directory.
    Expect.equals("${tempDir}", file.parent.path);
    file.createSync();
    // Check that the path of the returned directory is the temp directory.
    Directory d = file.parent;
    Expect.isTrue(d.existsSync());
    Expect.isTrue(d.path.endsWith(tempDir));
    file.deleteSync();
    // The directory getter does not care about file or type of file
    // system entity.
    Expect.equals("${tempDir}", file.parent.path);
    file = new File("foo");
    Expect.equals(".", file.parent.path);
    file = new File(".");
    Expect.equals(".", file.parent.path);
  }

  // Test for file length functionality.
  static void testLength() {
    asyncTestStarted();
    String filename = getFilename("fixed_length_file");
    File file = new File(filename);
    RandomAccessFile openedFile = file.openSync();
    openedFile.length().then((length) {
      Expect.equals(42, length);
      openedFile.close().then((ignore) => asyncTestDone("testLength"));
    });
    file.length().then((length) {
      Expect.equals(42, length);
    });
  }

  static void testLengthSync() {
    String filename = getFilename("fixed_length_file");
    File file = new File(filename);
    RandomAccessFile openedFile = file.openSync();
    Expect.equals(42, file.lengthSync());
    Expect.equals(42, openedFile.lengthSync());
    openedFile.closeSync();
  }

  static void testLengthSyncDirectory() {
    Directory tmp = tempDirectory.createTempSync('file_length_test_');
    String dirPath = '${tmp.path}/dir';
    new Directory(dirPath).createSync();
    try {
      new File(dirPath).lengthSync();
      Expect.fail('Expected operation to throw');
    } catch (e) {
      if (e is! FileSystemException) {
        print(e);
      }
      Expect.isTrue(e is FileSystemException);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  }

  // Test for file position functionality.
  static void testPosition() {
    asyncTestStarted();
    String filename = getFilename("fixed_length_file");
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
                  input.close().then((ignore) => asyncTestDone("testPosition"));
                });
              });
            });
          });
        });
      });
    });
  }

  static void testPositionSync() {
    String filename = getFilename("fixed_length_file");
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
    asyncTestStarted();
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
  }

  static void testTruncateSync() {
    File file = new File(tempDirectory.path + "/out_truncate_sync");
    List buffer = const [65, 65, 65, 65, 65, 65, 65, 65, 65, 65];
    RandomAccessFile openedFile = file.openSync(mode: WRITE);
    openedFile.writeFromSync(buffer, 0, 10);
    Expect.equals(10, openedFile.lengthSync());
    openedFile.truncateSync(5);
    Expect.equals(5, openedFile.lengthSync());
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    try {
      openedFile.truncateSync(-5);
    } on FileSystemException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    openedFile.closeSync();
    file.deleteSync();
    Expect.isFalse(file.existsSync());
  }

  static testReadInto() async {
    asyncTestStarted();
    File file = new File(tempDirectory.path + "/out_read_into");

    var openedFile = await file.open(mode: WRITE);
    await openedFile.writeFrom(const [1, 2, 3]);

    await openedFile.setPosition(0);
    var list = [null, null, null];
    Expect.equals(3, await openedFile.readInto(list));
    Expect.listEquals([1, 2, 3], list);

    read(start, end, length, expected) async {
      var list = [null, null, null];
      await openedFile.setPosition(0);
      Expect.equals(length, await openedFile.readInto(list, start, end));
      Expect.listEquals(expected, list);
      return list;
    }

    await read(0, 3, 3, [1, 2, 3]);
    await read(0, 2, 2, [1, 2, null]);
    await read(1, 2, 1, [null, 1, null]);
    await read(1, 3, 2, [null, 1, 2]);
    await read(2, 3, 1, [null, null, 1]);
    await read(0, 0, 0, [null, null, null]);

    await openedFile.close();

    asyncTestDone("testReadInto");
  }

  static void testReadIntoSync() {
    File file = new File(tempDirectory.path + "/out_read_into_sync");

    var openedFile = file.openSync(mode: WRITE);
    openedFile.writeFromSync(const [1, 2, 3]);

    openedFile.setPositionSync(0);
    var list = [null, null, null];
    Expect.equals(3, openedFile.readIntoSync(list));
    Expect.listEquals([1, 2, 3], list);

    read(start, end, length, expected) {
      var list = [null, null, null];
      openedFile.setPositionSync(0);
      Expect.equals(length, openedFile.readIntoSync(list, start, end));
      Expect.listEquals(expected, list);
      return list;
    }

    read(0, 3, 3, [1, 2, 3]);
    read(0, 2, 2, [1, 2, null]);
    read(1, 2, 1, [null, 1, null]);
    read(1, 3, 2, [null, 1, 2]);
    read(2, 3, 1, [null, null, 1]);
    read(0, 0, 0, [null, null, null]);

    openedFile.closeSync();
  }

  static testWriteFrom() async {
    asyncTestStarted();
    File file = new File(tempDirectory.path + "/out_write_from");

    var buffer = const [1, 2, 3];
    var openedFile = await file.open(mode: WRITE);

    await openedFile.writeFrom(buffer);
    var result = []..addAll(buffer);
    ;

    write([start, end]) async {
      var returnValue = await openedFile.writeFrom(buffer, start, end);
      Expect.identical(openedFile, returnValue);
      result.addAll(buffer.sublist(start, end));
    }

    await write(0, 3);
    await write(0, 2);
    await write(1, 2);
    await write(1, 3);
    await write(2, 3);
    await write(0, 0);

    var bytesFromFile = await file.readAsBytes();
    Expect.listEquals(result, bytesFromFile);

    await openedFile.close();

    asyncTestDone("testWriteFrom");
  }

  static void testWriteFromSync() {
    File file = new File(tempDirectory.path + "/out_write_from_sync");

    var buffer = const [1, 2, 3];
    var openedFile = file.openSync(mode: WRITE);

    openedFile.writeFromSync(buffer);
    var result = []..addAll(buffer);
    ;

    write([start, end]) {
      var returnValue = openedFile.writeFromSync(buffer, start, end);
      result.addAll(buffer.sublist(start, end));
    }

    write(0, 3);
    write(0, 2);
    write(1, 2);
    write(1, 3);
    write(2, 3);

    var bytesFromFile = file.readAsBytesSync();
    Expect.listEquals(result, bytesFromFile);

    openedFile.closeSync();
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
    } on FileSystemException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.writeByteSync(1);
    } on FileSystemException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.writeStringSync("Test");
    } on FileSystemException catch (ex) {
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
    } on FileSystemException catch (ex) {
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
    } on FileSystemException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.positionSync();
    } on FileSystemException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.lengthSync();
    } on FileSystemException catch (ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.flushSync();
    } on FileSystemException catch (ex) {
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
    File file = new File(tempDirectory.path + "/out_close_exception_stream");
    file.createSync();
    var output = file.openWrite();
    output.close();
    output.add(buffer); // Ignored.
    output.done.then((_) {
      file.deleteSync();
      asyncTestDone("testCloseExceptionStream");
    });
  }

  // Tests buffer out of bounds exception.
  static void testBufferOutOfBoundsException() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    File file = new File(tempDirectory.path + "/out_buffer_out_of_bounds");
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
    future
        .then((r) => Expect.fail('Directory opened as file'))
        .catchError((e) {});
  }

  static void testOpenDirectoryAsFileSync() {
    var f = new File('.');
    try {
      f.openSync();
      Expect.fail("Expected exception opening directory as file");
    } catch (e) {
      Expect.isTrue(e is FileSystemException);
    }
  }

  static void testReadAsBytes() {
    asyncTestStarted();
    var name = getFilename("fixed_length_file");
    var f = new File(name);
    f.readAsBytes().then((bytes) {
      Expect.isTrue(new String.fromCharCodes(bytes).endsWith("42 bytes."));
      Expect.equals(42, bytes.length);
      asyncTestDone("testReadAsBytes");
    });
  }

  static void testReadAsBytesEmptyFile() {
    asyncTestStarted();
    var name = getFilename("empty_file");
    var f = new File(name);
    f.readAsBytes().then((bytes) {
      Expect.equals(0, bytes.length);
      asyncTestDone("testReadAsBytesEmptyFile");
    });
  }

  static void testReadAsBytesSync() {
    var name = getFilename("fixed_length_file");
    var bytes = new File(name).readAsBytesSync();
    Expect.isTrue(new String.fromCharCodes(bytes).endsWith("42 bytes."));
    Expect.equals(bytes.length, 42);
  }

  static void testReadAsBytesSyncEmptyFile() {
    var name = getFilename("empty_file");
    var bytes = new File(name).readAsBytesSync();
    Expect.equals(bytes.length, 0);
  }

  static void testReadAsText() {
    asyncTestStarted();
    var name = getFilename("fixed_length_file");
    var f = new File(name);
    f.readAsString(encoding: UTF8).then((text) {
      Expect.isTrue(text.endsWith("42 bytes."));
      Expect.equals(42, text.length);
      var name = getFilename("read_as_text.dat");
      var f = new File(name);
      f.readAsString(encoding: UTF8).then((text) {
        Expect.equals(6, text.length);
        var expected = [955, 120, 46, 32, 120, 10];
        Expect.listEquals(expected, text.codeUnits);
        f.readAsString(encoding: LATIN1).then((text) {
          Expect.equals(7, text.length);
          var expected = [206, 187, 120, 46, 32, 120, 10];
          Expect.listEquals(expected, text.codeUnits);
          var readAsStringFuture = f.readAsString(encoding: ASCII);
          readAsStringFuture.then((text) {
            Expect.fail("Non-ascii char should cause error");
          }).catchError((e) {
            asyncTestDone("testReadAsText");
          });
        });
      });
    });
  }

  static void testReadAsTextEmptyFile() {
    asyncTestStarted();
    var name = getFilename("empty_file");
    var f = new File(name);
    f.readAsString(encoding: UTF8).then((text) {
      Expect.equals(0, text.length);
      asyncTestDone("testReadAsTextEmptyFile");
      return true;
    });
  }

  static void testReadAsTextSync() {
    var name = getFilename("fixed_length_file");
    var text = new File(name).readAsStringSync();
    Expect.isTrue(text.endsWith("42 bytes."));
    Expect.equals(42, text.length);
    name = getFilename("read_as_text.dat");
    text = new File(name).readAsStringSync();
    Expect.equals(6, text.length);
    var expected = [955, 120, 46, 32, 120, 10];
    Expect.listEquals(expected, text.codeUnits);
    // First character is not ASCII. The default ASCII decoder will throw.
    Expect.throws(() => new File(name).readAsStringSync(encoding: ASCII),
        (e) => e is FileSystemException);
    // We can use an ASCII decoder that inserts the replacement character.
    var lenientAscii = const AsciiCodec(allowInvalid: true);
    text = new File(name).readAsStringSync(encoding: lenientAscii);
    // Default replacement character is the Unicode replacement character.
    expected = [
      UNICODE_REPLACEMENT_CHARACTER_RUNE,
      UNICODE_REPLACEMENT_CHARACTER_RUNE,
      120,
      46,
      32,
      120,
      10
    ];
    Expect.listEquals(expected, text.codeUnits);
    text = new File(name).readAsStringSync(encoding: LATIN1);
    expected = [206, 187, 120, 46, 32, 120, 10];
    Expect.equals(7, text.length);
    Expect.listEquals(expected, text.codeUnits);
  }

  static void testReadAsTextSyncEmptyFile() {
    var name = getFilename("empty_file");
    var text = new File(name).readAsStringSync();
    Expect.equals(0, text.length);
  }

  static void testReadAsLines() {
    asyncTestStarted();
    var name = getFilename("fixed_length_file");
    var f = new File(name);
    f.readAsLines(encoding: UTF8).then((lines) {
      Expect.equals(1, lines.length);
      var line = lines[0];
      Expect.isTrue(line.endsWith("42 bytes."));
      Expect.equals(42, line.length);
      asyncTestDone("testReadAsLines");
    });
  }

  static void testReadAsLinesSync() {
    var name = getFilename("fixed_length_file");
    var lines = new File(name).readAsLinesSync();
    Expect.equals(1, lines.length);
    var line = lines[0];
    Expect.isTrue(line.endsWith("42 bytes."));
    Expect.equals(42, line.length);
    name = getFilename("readline_test1.dat");
    lines = new File(name).readAsLinesSync();
    Expect.equals(10, lines.length);
  }

  static void testReadAsErrors() {
    asyncTestStarted();
    var f = new File('.');
    Expect.throws(f.readAsBytesSync, (e) => e is FileSystemException);
    Expect.throws(f.readAsStringSync, (e) => e is FileSystemException);
    Expect.throws(f.readAsLinesSync, (e) => e is FileSystemException);
    var readAsBytesFuture = f.readAsBytes();
    readAsBytesFuture
        .then((bytes) => Expect.fail("no bytes expected"))
        .catchError((e) {
      var readAsStringFuture = f.readAsString(encoding: UTF8);
      readAsStringFuture
          .then((text) => Expect.fail("no text expected"))
          .catchError((e) {
        var readAsLinesFuture = f.readAsLines(encoding: UTF8);
        readAsLinesFuture
            .then((lines) => Expect.fail("no lines expected"))
            .catchError((e) {
          asyncTestDone("testReadAsLines");
        });
      });
    });
  }

  static void testLastModified() {
    asyncTestStarted();
    new File(Platform.executable).lastModified().then((modified) {
      Expect.isTrue(modified is DateTime);
      Expect.isTrue(modified.isBefore(new DateTime.now()));
      asyncTestDone("testLastModified");
    });
  }

  static void testLastAccessed() {
    asyncTestStarted();
    new File(Platform.executable).lastAccessed().then((accessed) {
      Expect.isTrue(accessed is DateTime);
      Expect.isTrue(accessed.isBefore(new DateTime.now()));
      asyncTestDone("testLastAccessed");
    });
  }

  static void testDoubleAsyncOperation() {
    asyncTestStarted();
    var file = new File(Platform.executable).openSync();
    var completer = new Completer();
    int done = 0;
    bool error = false;
    void getLength() {
      file.length().catchError((e) {
        error = true;
      }).whenComplete(() {
        if (++done == 2) {
          asyncTestDone("testDoubleAsyncOperation");
          Expect.isTrue(error);
          file.lengthSync();
          file.closeSync();
        }
      });
    }

    getLength();
    getLength();
    Expect.throws(() => file.lengthSync());
  }

  static void testLastModifiedSync() {
    var modified = new File(Platform.executable).lastModifiedSync();
    Expect.isTrue(modified is DateTime);
    Expect.isTrue(modified.isBefore(new DateTime.now()));
  }

  static void testLastAccessedSync() {
    var accessed = new File(Platform.executable).lastAccessedSync();
    Expect.isTrue(accessed is DateTime);
    Expect.isTrue(accessed.isBefore(new DateTime.now()));
  }

  static void testLastModifiedSyncDirectory() {
    Directory tmp = tempDirectory.createTempSync('file_last_modified_test_');
    String dirPath = '${tmp.path}/dir';
    new Directory(dirPath).createSync();
    try {
      new File(dirPath).lastModifiedSync();
      Expect.fail('Expected operation to throw');
    } catch (e) {
      if (e is! FileSystemException) {
        print(e);
      }
      Expect.isTrue(e is FileSystemException);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  }

  static void testLastAccessedSyncDirectory() {
    Directory tmp = tempDirectory.createTempSync('file_last_accessed_test_');
    String dirPath = '${tmp.path}/dir';
    new Directory(dirPath).createSync();
    try {
      new File(dirPath).lastAccessedSync();
      Expect.fail('Expected operation to throw');
    } catch (e) {
      if (e is! FileSystemException) {
        print(e);
      }
      Expect.isTrue(e is FileSystemException);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  }

  static void testSetLastModifiedSync() {
    String newFilePath = '${tempDirectory.path}/set_last_modified_sync_test';
    File file = new File(newFilePath);
    file.createSync();
    DateTime modifiedTime = new DateTime(2016, 1, 1);
    file.setLastModifiedSync(modifiedTime);
    FileStat stat = file.statSync();
    Expect.equals(2016, stat.modified.year);
    Expect.equals(1, stat.modified.month);
    Expect.equals(1, stat.modified.day);
  }

  static testSetLastModified() async {
    asyncTestStarted();
    String newFilePath = '${tempDirectory.path}/set_last_modified_test';
    File file = new File(newFilePath);
    file.createSync();
    DateTime modifiedTime = new DateTime(2016, 1, 1);
    await file.setLastModified(modifiedTime);
    FileStat stat = await file.stat();
    Expect.equals(2016, stat.modified.year);
    Expect.equals(1, stat.modified.month);
    Expect.equals(1, stat.modified.day);
    asyncTestDone("testSetLastModified");
  }

  static void testSetLastModifiedSyncDirectory() {
    Directory tmp = tempDirectory.createTempSync('file_last_modified_test_');
    String dirPath = '${tmp.path}/dir';
    new Directory(dirPath).createSync();
    try {
      DateTime modifiedTime = new DateTime(2016, 1, 1);
      new File(dirPath).setLastModifiedSync(modifiedTime);
      Expect.fail('Expected operation to throw');
    } catch (e) {
      if (e is! FileSystemException) {
        print(e);
      }
      Expect.isTrue(e is FileSystemException);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  }

  static void testSetLastAccessedSync() {
    String newFilePath = '${tempDirectory.path}/set_last_accessed_sync_test';
    File file = new File(newFilePath);
    file.createSync();
    DateTime accessedTime = new DateTime(2016, 1, 1);
    file.setLastAccessedSync(accessedTime);
    FileStat stat = file.statSync();
    Expect.equals(2016, stat.accessed.year);
    Expect.equals(1, stat.accessed.month);
    Expect.equals(1, stat.accessed.day);
  }

  static testSetLastAccessed() async {
    asyncTestStarted();
    String newFilePath = '${tempDirectory.path}/set_last_accessed_test';
    File file = new File(newFilePath);
    file.createSync();
    DateTime accessedTime = new DateTime(2016, 1, 1);
    await file.setLastAccessed(accessedTime);
    FileStat stat = await file.stat();
    Expect.equals(2016, stat.accessed.year);
    Expect.equals(1, stat.accessed.month);
    Expect.equals(1, stat.accessed.day);
    asyncTestDone("testSetLastAccessed");
  }

  static void testSetLastAccessedSyncDirectory() {
    Directory tmp = tempDirectory.createTempSync('file_last_accessed_test_');
    String dirPath = '${tmp.path}/dir';
    new Directory(dirPath).createSync();
    try {
      DateTime accessedTime = new DateTime(2016, 1, 1);
      new File(dirPath).setLastAccessedSync(accessedTime);
      Expect.fail('Expected operation to throw');
    } catch (e) {
      if (e is! FileSystemException) {
        print(e);
      }
      Expect.isTrue(e is FileSystemException);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  }

  // Test that opens the same file for writing then for appending to test
  // that the file is not truncated when opened for appending.
  static void testAppend() {
    asyncTestStarted();
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
    asyncTestStarted();
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

  static void testRename({bool targetExists}) {
    lift(Function f) => (futureValue) => futureValue.then((value) => f(value));
    asyncTestStarted();

    String source = join(tempDirectory.path, 'rename_${targetExists}_source');
    String dest = join(tempDirectory.path, 'rename_${targetExists}_dest');
    var file = new File(source);
    var newfile = new File(dest);
    file
        .create()
        .then((_) => targetExists ? newfile.create() : null)
        .then((_) => file.rename(dest))
        .then((_) => lift(Expect.isFalse)(file.exists()))
        .then((_) => lift(Expect.isTrue)(newfile.exists()))
        .then((_) => newfile.delete())
        .then((_) => lift(Expect.isFalse)(newfile.exists()))
        .then((_) {
      if (Platform.operatingSystem != "windows") {
        new Link(source).create(dest).then((_) => file.rename("xxx")).then((_) {
          throw "Rename of broken link succeeded";
        }).catchError((e) {
          Expect.isTrue(e is FileSystemException);
          asyncTestDone("testRename$targetExists");
        });
      } else {
        asyncTestDone("testRename$targetExists");
      }
    });
  }

  static void testRenameSync({bool targetExists}) {
    String source = join(tempDirectory.path, 'rename_source');
    String dest = join(tempDirectory.path, 'rename_dest');
    var file = new File(source);
    var newfile = new File(dest);
    file.createSync();
    if (targetExists) {
      newfile.createSync();
    }
    var result = file.renameSync(dest);
    Expect.isFalse(file.existsSync());
    Expect.isTrue(newfile.existsSync());
    Expect.equals(result.path, newfile.path);
    newfile.deleteSync();
    Expect.isFalse(newfile.existsSync());
    if (Platform.operatingSystem != "windows") {
      var brokenLink = new Link(source);
      brokenLink.createSync(dest);
      Expect.throws(() => file.renameSync('xxx'));
      brokenLink.deleteSync();
    }
  }

  static String getFilename(String path) {
    return Platform.script.resolve(path).toFilePath();
  }

  // Main test entrypoint.
  static testMain() {
    asyncStart();

    testRead();
    testReadSync();
    testReadStream();
    testLengthSync();
    testPositionSync();
    testOpenDirectoryAsFile();
    testOpenDirectoryAsFileSync();
    testReadAsBytesSync();
    testReadAsBytesSyncEmptyFile();
    testReadAsTextSync();
    testReadAsTextSyncEmptyFile();
    testReadAsLinesSync();
    testLastModifiedSync();
    testLastAccessedSync();

    createTempDirectory(() {
      testLength();
      testLengthSyncDirectory();
      testReadWrite();
      testReadWriteSync();
      testReadWriteNoArgsSync();
      testReadWriteStream();
      testReadEmptyFileSync();
      testReadEmptyFile();
      testReadWriteStreamLargeFile();
      testReadAsBytes();
      testReadAsBytesEmptyFile();
      testReadAsText();
      testReadAsTextEmptyFile();
      testReadAsLines();
      testReadAsErrors();
      testPosition();
      testTruncate();
      testTruncateSync();
      testReadInto();
      testReadIntoSync();
      testWriteFrom();
      testWriteFromSync();
      testCloseException();
      testCloseExceptionStream();
      testBufferOutOfBoundsException();
      testAppend();
      testAppendSync();
      testWriteAppend();
      testOutputStreamWriteAppend();
      testOutputStreamWriteString();
      testWriteVariousLists();
      testWriteFromOffset();
      testDirectory();
      testDirectorySync();
      testWriteStringUtf8();
      testWriteStringUtf8Sync();
      testRename(targetExists: false);
      testRenameSync(targetExists: false);
      testRename(targetExists: true);
      testRenameSync(targetExists: true);
      testLastModified();
      testLastAccessed();
      testLastModifiedSyncDirectory();
      testLastAccessedSyncDirectory();
      testSetLastModified();
      testSetLastModifiedSync();
      testSetLastModifiedSyncDirectory();
      testSetLastAccessed();
      testSetLastAccessedSync();
      testSetLastAccessedSyncDirectory();
      testDoubleAsyncOperation();
      asyncEnd();
    });
  }
}

main() {
  FileTest.testMain();
}
