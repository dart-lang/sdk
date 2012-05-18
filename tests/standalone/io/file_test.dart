// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file I/O.

#import("dart:io");
#import("dart:isolate");

class MyListOfOneElement implements List {
  int _value;
  MyListOfOneElement(this._value);
  int get length() => 1;
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
    tempDirectory.deleteRecursivelySync();
  }

  // Test for file read functionality.
  static void testReadStream() {
    // Read a file and check part of it's contents.
    String filename = getFilename("bin/file_test.cc");
    File file = new File(filename);
    InputStream input = file.openInputStream();
    input.onData = () {
      List<int> buffer = new List<int>(42);
      int bytesRead = input.readInto(buffer, 0, 12);
      Expect.equals(12, bytesRead);
      bytesRead = input.readInto(buffer, 12, 30);
      input.close();
      Expect.equals(30, bytesRead);
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
    };
  }

  // Test for file read and write functionality.
  static void testReadWriteStream() {
    asyncTestStarted();

    // Read a file.
    String inFilename = getFilename("tests/vm/data/fixed_length_file");
    File file;
    InputStream input;
    int bytesRead;

    // Test reading all using readInto.
    file = new File(inFilename);
    input = file.openInputStream();
    input.onData = () {
      List<int> buffer1 = new List<int>(42);
      bytesRead = input.readInto(buffer1, 0, 42);
      Expect.equals(42, bytesRead);
      Expect.isTrue(input.closed);

      // Test reading all using readInto and read.
      file = new File(inFilename);
      input = file.openInputStream();
      input.onData = () {
        bytesRead = input.readInto(buffer1, 0, 21);
        Expect.equals(21, bytesRead);
        buffer1 = input.read();
        Expect.equals(21, buffer1.length);
        Expect.isTrue(input.closed);

        // Test reading all using read and readInto.
        file = new File(inFilename);
        input = file.openInputStream();
        input.onData = () {
          buffer1 = input.read(21);
          Expect.equals(21, buffer1.length);
          bytesRead = input.readInto(buffer1, 0, 21);
          Expect.equals(21, bytesRead);
          Expect.isTrue(input.closed);

          // Test reading all using read.
          file = new File(inFilename);
          input = file.openInputStream();
          input.onData = () {
            buffer1 = input.read();
            Expect.equals(42, buffer1.length);
            Expect.isTrue(input.closed);

            // Write the contents of the file just read into another file.
            String outFilename =
                tempDirectory.path.concat("/out_read_write_stream");
            file = new File(outFilename);
            OutputStream output = file.openOutputStream();
            bool writeDone = output.writeFrom(buffer1, 0, 42);
            Expect.equals(false, writeDone);
            output.onNoPendingWrites = () {
              output.close();
              output.onClosed = () {
                // Now read the contents of the file just written.
                List<int> buffer2 = new List<int>(42);
                file = new File(outFilename);
                input = file.openInputStream();
                input.onData = () {
                  bytesRead = input.readInto(buffer2, 0, 42);
                  Expect.equals(42, bytesRead);
                  // Now compare the two buffers to check if they are identical.
                  for (int i = 0; i < buffer1.length; i++) {
                    Expect.equals(buffer1[i],  buffer2[i]);
                  }
                };
                input.onClosed = () {
                  // Delete the output file.
                  file.deleteSync();
                  Expect.isFalse(file.existsSync());
                  asyncTestDone("testReadWriteStream");
                };
              };
            };
          };
        };
      };
    };
  }

  static void testRead() {
    ReceivePort port = new ReceivePort();
    // Read a file and check part of it's contents.
    String filename = getFilename("bin/file_test.cc");
    File file = new File(filename);
    file.open(FileMode.READ).then((RandomAccessFile file) {
      List<int> buffer = new List<int>(10);
      file.readList(buffer, 0, 5).then((bytes_read) {
        Expect.equals(5, bytes_read);
        file.readList(buffer, 5, 5).then((bytes_read) {
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
    RandomAccessFile file = (new File(filename)).openSync();
    List<int> buffer = new List<int>(42);
    int bytes_read = 0;
    bytes_read = file.readListSync(buffer, 0, 12);
    Expect.equals(12, bytes_read);
    bytes_read = file.readListSync(buffer, 12, 30);
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
  }

  // Test for file read and write functionality.
  static void testReadWrite() {
    // Read a file.
    String inFilename = getFilename("tests/vm/data/fixed_length_file");
    final File file = new File(inFilename);
    file.open(FileMode.READ).then((openedFile) {
      List<int> buffer1 = new List<int>(42);
      openedFile.readList(buffer1, 0, 42).then((bytes_read) {
        Expect.equals(42, bytes_read);
        openedFile.close().then((ignore) {
          // Write the contents of the file just read into another file.
          String outFilename = tempDirectory.path.concat("/out_read_write");
          final File file2 = new File(outFilename);
          file2.create().then((ignore) {
            file2.fullPath().then((s) {
              Expect.isTrue(new File(s).existsSync());
              if (s[0] != '/' && s[0] != '\\' && s[1] != ':') {
                Expect.fail("Not a full path");
              }
              file2.open(FileMode.WRITE).then((openedFile2) {
                openedFile2.writeList(buffer1, 0, bytes_read).then((ignore) {
                  openedFile2.close().then((ignore) {
                    List<int> buffer2 = new List<int>(bytes_read);
                    final File file3 = new File(outFilename);
                    file3.open(FileMode.READ).then((openedFile3) {
                      openedFile3.readList(buffer2, 0, 42).then((bytes_read) {
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
    String filename = tempDirectory.path.concat("/write_append");
    File file = new File(filename);
    file.createSync();
    Expect.isTrue(new File(filename).existsSync());
    List<int> buffer = content.charCodes();
    RandomAccessFile openedFile = file.openSync(FileMode.WRITE);
    openedFile.writeListSync(buffer, 0, buffer.length);
    openedFile.closeSync();
    // Reopen the file in write mode to ensure that we overwrite the content.
    openedFile = (new File(filename)).openSync(FileMode.WRITE);
    openedFile.writeListSync(buffer, 0, buffer.length);
    Expect.equals(content.length, openedFile.lengthSync());
    openedFile.closeSync();
    // Open the file in append mode and ensure that we do not overwrite
    // the existing content.
    openedFile = (new File(filename)).openSync(FileMode.APPEND);
    openedFile.writeListSync(buffer, 0, buffer.length);
    Expect.equals(content.length * 2, openedFile.lengthSync());
    openedFile.closeSync();
    file.deleteSync();
  }

  static void testOutputStreamWriteAppend() {
    String content = "foobar";
    String filename = tempDirectory.path.concat("/outstream_write_append");
    File file = new File(filename);
    file.createSync();
    List<int> buffer = content.charCodes();
    OutputStream outStream = file.openOutputStream();
    outStream.write(buffer);
    outStream.onNoPendingWrites = () {
      outStream.close();
      outStream.onClosed = () {
        File file2 = new File(filename);
        OutputStream appendingOutput =
            file2.openOutputStream(FileMode.APPEND);
        appendingOutput.write(buffer);
        appendingOutput.onNoPendingWrites = () {
          appendingOutput.close();
          appendingOutput.onClosed = () {
            File file3 = new File(filename);
            file3.open(FileMode.READ).then((RandomAccessFile openedFile) {
              openedFile.length().then((int length) {
                Expect.equals(content.length * 2, length);
                openedFile.close().then((ignore) {
                  file3.delete().then((ignore) {
                    asyncTestDone("testOutputStreamWriteAppend");
                  });
                });
              });
            });
          };
        };
      };
    };
    asyncTestStarted();
  }

  // Test for file read and write functionality.
  static void testOutputStreamWriteString() {
    String content = "foobar";
    String filename = tempDirectory.path.concat("/outstream_write_string");
    File file = new File(filename);
    file.createSync();
    List<int> buffer = content.charCodes();
    OutputStream outStream = file.openOutputStream();
    outStream.writeString("abcdABCD");
    outStream.writeString("abcdABCD", Encoding.UTF_8);
    outStream.writeString("abcdABCD", Encoding.ISO_8859_1);
    outStream.writeString("abcdABCD", Encoding.ASCII);
    outStream.writeString("æøå", Encoding.UTF_8);
    outStream.onNoPendingWrites = () {
      outStream.close();
      outStream.onClosed = () {
        RandomAccessFile raf = file.openSync();
        Expect.equals(38, raf.lengthSync());
        raf.close().then((ignore) {
          asyncTestDone("testOutputStreamWriteString");
        });
      };
    };
    asyncTestStarted();
  }


  static void testReadWriteSync() {
    // Read a file.
    String inFilename = getFilename("tests/vm/data/fixed_length_file");
    RandomAccessFile file = (new File(inFilename)).openSync();
    List<int> buffer1 = new List<int>(42);
    int bytes_read = 0;
    int bytes_written = 0;
    bytes_read = file.readListSync(buffer1, 0, 42);
    Expect.equals(42, bytes_read);
    file.closeSync();
    // Write the contents of the file just read into another file.
    String outFilename = tempDirectory.path.concat("/out_read_write_sync");
    File outFile = new File(outFilename);
    outFile.createSync();
    String path = outFile.fullPathSync();
    if (path[0] != '/' && path[0] != '\\' && path[1] != ':') {
      Expect.fail("Not a full path");
    }
    Expect.isTrue(new File(path).existsSync());
    RandomAccessFile openedFile = outFile.openSync(FileMode.WRITE);
    openedFile.writeListSync(buffer1, 0, bytes_read);
    openedFile.closeSync();
    // Now read the contents of the file just written.
    List<int> buffer2 = new List<int>(bytes_read);
    openedFile = (new File(outFilename)).openSync();
    bytes_read = openedFile.readListSync(buffer2, 0, 42);
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
    String fileName = tempDirectory.path.concat("/empty_file_sync");
    File file = new File(fileName);
    file.createSync();
    RandomAccessFile openedFile = file.openSync();
    Expect.equals(-1, openedFile.readByteSync());
    openedFile.closeSync();
    file.deleteSync();
  }

  static void testReadEmptyFile() {
    String fileName = tempDirectory.path.concat("/empty_file");
    File file = new File(fileName);
    asyncTestStarted();
    file.create().then((ignore) {
      file.open(FileMode.READ).then((RandomAccessFile openedFile) {
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
      file.open(FileMode.WRITE).then((RandomAccessFile openedFile) {
        // Write bytes from 0 to 7.
        openedFile.writeList([0], 0, 1);
        openedFile.writeList(const [1], 0, 1);
        openedFile.writeList(new MyListOfOneElement(2), 0, 1);
        var x = 12345678901234567890123456789012345678901234567890;
        var y = 12345678901234567890123456789012345678901234567893;
        openedFile.writeList([y - x], 0, 1);
        openedFile.writeList([260], 0, 1);  // 260 = 256 + 4 = 0x104.
        openedFile.writeList(const [261], 0, 1);
        openedFile.writeList(new MyListOfOneElement(262), 0, 1);
        x = 12345678901234567890123456789012345678901234567890;
        y = 12345678901234567890123456789012345678901234568153;
        openedFile.writeList([y - x], 0, 1).then((ignore) {
          openedFile.close().then((ignore) {
            // Check the written bytes.
            final File file2 = new File(fileName);
            var openedFile2 = file2.openSync();
            var length = openedFile2.lengthSync();
            Expect.equals(8, length);
            List data = new List(length);
            openedFile2.readListSync(data, 0, length);
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
    dirFuture.then((d) => Expect.fail("non-existing file"));
    dirFuture.handleException((e) {
      file.create().then((ignore) {
        file.directory().then((Directory d) {
          d.exists().then((exists) {
            Expect.isTrue(exists);
            Expect.isTrue(d.path.endsWith(tempDir));
            file.delete().then((ignore) {
              var fileDir = new File(".");
              var dirFuture2 = fileDir.directory();
              dirFuture2.then((d) => Expect.fail("non-existing file"));
              dirFuture2.handleException((e) {
                var fileDir = new File(tempDir);
                var dirFuture3 = fileDir.directory();
                dirFuture3.then((d) => Expect.fail("non-existing file"));
                dirFuture3.handleException((e) {
                  port.toSendPort().send(1);
                  return true;
                });
                return true;
              });
            });
          });
        });
      });
      return true;
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
      input.readList(buffer, 0, 12).then((bytes_read) {
        input.position().then((position) {
          Expect.equals(12, position);
          input.readList(buffer, 12, 6).then((bytes_read) {
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
    input.readListSync(buffer, 0, 12);
    Expect.equals(12, input.positionSync());
    input.readListSync(buffer, 12, 6);
    Expect.equals(18, input.positionSync());
    input.setPositionSync(8);
    Expect.equals(8, input.positionSync());
    input.closeSync();
  }

  static void testTruncate() {
    File file = new File(tempDirectory.path.concat("/out_truncate"));
    List buffer = const [65, 65, 65, 65, 65, 65, 65, 65, 65, 65];
    file.open(FileMode.WRITE).then((RandomAccessFile openedFile) {
      openedFile.writeList(buffer, 0, 10).then((ignore) {
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
    File file = new File(tempDirectory.path.concat("/out_truncate_sync"));
    List buffer = const [65, 65, 65, 65, 65, 65, 65, 65, 65, 65];
    RandomAccessFile openedFile = file.openSync(FileMode.WRITE);
    openedFile.writeListSync(buffer, 0, 10);
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
    File input = new File(tempDirectory.path.concat("/out_close_exception"));
    RandomAccessFile openedFile = input.openSync(FileMode.WRITE);
    openedFile.closeSync();
    try {
      openedFile.readByteSync();
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.writeByteSync(1);
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.writeStringSync("Test");
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(100);
      openedFile.readListSync(buffer, 0, 10);
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(100);
      openedFile.writeListSync(buffer, 0, 10);
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.positionSync();
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.lengthSync();
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      openedFile.flushSync();
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
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
        new File(tempDirectory.path.concat("/out_close_exception_stream"));
    file.createSync();
    InputStream input = file.openInputStream();
    input.onClosed = () {
      Expect.isTrue(input.closed);
      Expect.isNull(input.readInto(buffer, 0, 12));
      OutputStream output = file.openOutputStream();
      output.close();
      Expect.throws(() => output.writeFrom(buffer, 0, 12));
      output.onClosed = () {
        file.deleteSync();
        asyncTestDone("testCloseExceptionStream");
      };
    };
  }

  // Tests buffer out of bounds exception.
  static void testBufferOutOfBoundsException() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    File file =
        new File(tempDirectory.path.concat("/out_buffer_out_of_bounds"));
    RandomAccessFile openedFile = file.openSync(FileMode.WRITE);
    try {
      List<int> buffer = new List<int>(10);
      openedFile.readListSync(buffer, 0, 12);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.readListSync(buffer, 6, 6);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.readListSync(buffer, -1, 1);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.readListSync(buffer, 0, -1);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.writeListSync(buffer, 0, 12);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.writeListSync(buffer, 6, 6);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.writeListSync(buffer, -1, 1);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      openedFile.writeListSync(buffer, 0, -1);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    openedFile.closeSync();
    file.deleteSync();
  }

  static void testOpenDirectoryAsFile() {
    var f = new File('.');
    var future = f.open(FileMode.READ);
    future.then((r) => Expect.fail('Directory opened as file'));
    future.handleException((e) => true);
  }

  static void testOpenDirectoryAsFileSync() {
    var f = new File('.');
    try {
      f.openSync();
      Expect.fail("Expected exception opening directory as file");
    } catch (var e) {
      Expect.isTrue(e is FileIOException);
    }
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

  static void testReadAsBytesSync() {
    var name = getFilename("tests/vm/data/fixed_length_file");
    var bytes = new File(name).readAsBytesSync();
    Expect.isTrue(new String.fromCharCodes(bytes).endsWith("42 bytes."));
    Expect.equals(bytes.length, 42);
  }

  static void testReadAsText() {
    var port = new ReceivePort();
    port.receive((result, replyTo) {
      port.close();
      Expect.equals(1, result);
    });
    var name = getFilename("tests/vm/data/fixed_length_file");
    var f = new File(name);
    f.readAsText(Encoding.UTF_8).then((text) {
      Expect.isTrue(text.endsWith("42 bytes."));
      Expect.equals(42, text.length);
      var name = getDataFilename("tests/standalone/io/read_as_text.dat");
      var f = new File(name);
      f.readAsText(Encoding.UTF_8).then((text) {
        Expect.equals(6, text.length);
        var expected = [955, 120, 46, 32, 120, 10];
        Expect.listEquals(expected, text.charCodes());
        f.readAsText(Encoding.ISO_8859_1).then((text) {
          Expect.equals(7, text.length);
          var expected = [206, 187, 120, 46, 32, 120, 10];
          Expect.listEquals(expected, text.charCodes());
          var readAsTextFuture = f.readAsText(Encoding.ASCII);
          readAsTextFuture.then((text) {
            Expect.fail("Non-ascii char should cause error");
          });
          readAsTextFuture.handleException((e) {
            port.toSendPort().send(1);
            return true;
          });
        });
      });
    });
  }

  static void testReadAsTextSync() {
    var name = getFilename("tests/vm/data/fixed_length_file");
    var text = new File(name).readAsTextSync();
    Expect.isTrue(text.endsWith("42 bytes."));
    Expect.equals(42, text.length);
    name = getDataFilename("tests/standalone/io/read_as_text.dat");
    text = new File(name).readAsTextSync();
    Expect.equals(6, text.length);
    var expected = [955, 120, 46, 32, 120, 10];
    Expect.listEquals(expected, text.charCodes());
    Expect.throws(() { new File(name).readAsTextSync(Encoding.ASCII); });
    text = new File(name).readAsTextSync(Encoding.ISO_8859_1);
    expected = [206, 187, 120, 46, 32, 120, 10];
    Expect.equals(7, text.length);
    Expect.listEquals(expected, text.charCodes());
  }

  static void testReadAsLines() {
    var port = new ReceivePort();
    port.receive((result, replyTo) {
      port.close();
      Expect.equals(42, result);
    });
    var name = getFilename("tests/vm/data/fixed_length_file");
    var f = new File(name);
    f.readAsLines(Encoding.UTF_8).then((lines) {
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
    Expect.throws(f.readAsTextSync, (e) => e is FileIOException);
    Expect.throws(f.readAsLinesSync, (e) => e is FileIOException);
    var readAsBytesFuture = f.readAsBytes();
    readAsBytesFuture.then((bytes) => Expect.fail("no bytes expected"));
    readAsBytesFuture.handleException((e) {
      var readAsTextFuture = f.readAsText(Encoding.UTF_8);
      readAsTextFuture.then((text) => Expect.fail("no text expected"));
      readAsTextFuture.handleException((e) {
        var readAsLinesFuture = f.readAsLines(Encoding.UTF_8);
        readAsLinesFuture.then((lines) => Expect.fail("no lines expected"));
        readAsLinesFuture.handleException((e) {
          port.toSendPort().send(1);
          return true;
        });
        return true;
      });
      return true;
    });
  }

  // Test that opens the same file for writing then for appending to test
  // that the file is not truncated when opened for appending.
  static void testAppend() {
    var file = new File('${tempDirectory.path}/out_append');
    file.open(FileMode.WRITE).then((openedFile) {
      openedFile.writeString("asdf").then((ignore) {
        openedFile.close().then((ignore) {
          file.open(FileMode.APPEND).then((openedFile) {
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
    var openedFile = file.openSync(FileMode.WRITE);
    openedFile.writeStringSync("asdf");
    Expect.equals(4, openedFile.lengthSync());
    openedFile.closeSync();
    openedFile = file.openSync(FileMode.WRITE);
    openedFile.setPositionSync(4);
    openedFile.writeStringSync("asdf");
    Expect.equals(8, openedFile.lengthSync());
    openedFile.closeSync();
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
    testReadAsBytes();
    testReadAsBytesSync();
    testReadAsText();
    testReadAsTextSync();
    testReadAsLines();
    testReadAsLinesSync();
    testReadAsErrors();

    createTempDirectory(() {
      testReadWrite();
      testReadWriteSync();
      testReadWriteStream();
      testReadEmptyFileSync();
      testReadEmptyFile();
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
    });
  }
}

main() {
  FileTest.testMain();
}
