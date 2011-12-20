// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file I/O.


class FileTest {
  static Directory tempDirectory;
  static int numLiveAsyncTests = 0;

  static void asyncTestStarted() { ++numLiveAsyncTests; }
  static void asyncTestDone() {
    --numLiveAsyncTests;
    if (numLiveAsyncTests == 0) {
      deleteTempDirectory();
    }
  }

  static void createTempDirectory(Function doNext) {
    tempDirectory = new Directory('');
    tempDirectory.createTempHandler = doNext;
    tempDirectory.createTemp();
  }

  static void deleteTempDirectory() {
    tempDirectory.deleteSync();
  }

  // Test for file read functionality.
  static int testReadStream() {
    // Read a file and check part of it's contents.
    String filename = getFilename("bin/file_test.cc");
    File file = new File(filename);
    FileInputStream input = file.openInputStream();
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
    return 1;
  }

  // Test for file read and write functionality.
  static int testReadWriteStream() {
    // Read a file.
    String inFilename = getFilename("tests/vm/data/fixed_length_file");
    File file = new File(inFilename);
    FileInputStream input = file.openInputStream();
    List<int> buffer1 = new List<int>(42);
    int bytesRead = input.readInto(buffer1, 0, 42);
    Expect.equals(42, bytesRead);
    input.close();
    // Write the contents of the file just read into another file.
    String outFilename = tempDirectory.path + "/out_read_write_stream";
    file = new File(outFilename);
    OutputStream output = file.openOutputStream();
    bool writeDone = output.writeFrom(buffer1, 0, 42);
    Expect.equals(true, writeDone);
    output.close();
    // Now read the contents of the file just written.
    List<int> buffer2 = new List<int>(42);
    file = new File(outFilename);
    input = file.openInputStream();
    bytesRead = input.readInto(buffer2, 0, 42);
    input.close();
    Expect.equals(42, bytesRead);
    // Now compare the two buffers to check if they are identical.
    for (int i = 0; i < buffer1.length; i++) {
      Expect.equals(buffer1[i],  buffer2[i]);
    }
    // Delete the output file.
    file.deleteSync();
    Expect.isFalse(file.existsSync());
    return 1;
  }

  static int testRead() {
    // Read a file and check part of it's contents.
    String filename = getFilename("bin/file_test.cc");
    File file = new File(filename);
    file.errorHandler = (s) {
      Expect.fail("No errors expected");
    };
    file.openHandler = (RandomAccessFile file) {
      List<int> buffer = new List<int>(10);
      file.readListHandler = (bytes_read) {
        Expect.equals(5, bytes_read);
        file.readListHandler = (bytes_read) {
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
          file.close();
        };
        file.readList(buffer, 5, 5);
      };
      file.readList(buffer, 0, 5);
    };
    file.open();
    return 1;
  }

  static int testReadSync() {
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
    return 1;
  }

  // Test for file read and write functionality.
  static int testReadWrite() {
    // Read a file.
    String inFilename = getFilename("tests/vm/data/fixed_length_file");
    File file = new File(inFilename);
    file.errorHandler = (s) {
      Expect.fail("No errors expected");
    };
    file.openHandler = (RandomAccessFile openedFile) {
      List<int> buffer1 = new List<int>(42);
      openedFile.readListHandler = (bytes_read) {
        Expect.equals(42, bytes_read);
        openedFile.closeHandler = () {
          // Write the contents of the file just read into another file.
          String outFilename = tempDirectory.path + "/out_read_write";
          file = new File(outFilename);
          file.errorHandler = (s) {
            Expect.fail("No errors expected");
          };
          file.createHandler = () {
            file.fullPathHandler = (s) {
              Expect.isTrue(new File(s).existsSync());
              if (s[0] != '/' && s[0] != '\\' && s[1] != ':') {
                Expect.fail("Not a full path");
              }
              file.openHandler = (RandomAccessFile openedFile) {
                openedFile.noPendingWriteHandler = () {
                  openedFile.closeHandler = () {
                    // Now read the contents of the file just written.
                    List<int> buffer2 = new List<int>(bytes_read);
                    file = new File(outFilename);
                    file.errorHandler = (s) {
                      Expect.fail("No errors expected");
                    };
                    file.openHandler = (RandomAccessFile openedfile) {
                      openedFile.readListHandler = (bytes_read) {
                        Expect.equals(42, bytes_read);
                        openedFile.closeHandler = () {
                          // Now compare the two buffers to check if they
                          // are identical.
                          Expect.equals(buffer1.length, buffer2.length);
                          for (int i = 0; i < buffer1.length; i++) {
                            Expect.equals(buffer1[i],  buffer2[i]);
                          }
                          // Delete the output file.
                          file.deleteHandler = () {
                            file.existsHandler = (exists) {
                              Expect.isFalse(exists);
                              asyncTestDone();
                            };
                            file.exists();
                          };
                          file.delete();
                        };
                        openedFile.close();
                      };
                      openedFile.readList(buffer2, 0, 42);
                    };
                    file.open();
                  };
                  openedFile.close();
                };
                openedFile.writeList(buffer1, 0, bytes_read);
              };
              file.open(true);
            };
            file.fullPath();
          };
          file.create();
        };
        openedFile.close();
      };
      openedFile.readList(buffer1, 0, 42);
    };
    asyncTestStarted();
    file.open();
    return 1;

  }

  static int testReadWriteSync() {
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
    String outFilename = tempDirectory.path + "/out_read_write_sync";
    File outFile = new File(outFilename);
    outFile.createSync();
    String path = outFile.fullPathSync();
    if (path[0] != '/' && path[0] != '\\' && path[1] != ':') {
      Expect.fail("Not a full path");
    }
    Expect.isTrue(new File(path).existsSync());
    RandomAccessFile openedFile = outFile.openSync(true);
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
    return 1;
  }

  // Test for file length functionality.
  static int testLength() {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    RandomAccessFile input = (new File(filename)).openSync();
    input.errorHandler = (s) {
      Expect.fail("No errors expected");
    };
    input.lengthHandler = (length) {
      Expect.equals(42, length);
      input.close();
    };
    input.length();
    return 1;
  }

  static int testLengthSync() {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    RandomAccessFile input = (new File(filename)).openSync();
    Expect.equals(42, input.lengthSync());
    input.closeSync();
    return 1;
  }

  // Test for file position functionality.
  static int testPosition() {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    RandomAccessFile input = (new File(filename)).openSync();
    input.errorHandler = (s) {
      Expect.fail("No errors expected");
    };
    input.positionHandler = (position) {
      Expect.equals(0, position);
      List<int> buffer = new List<int>(100);
      input.readListHandler = (bytes_read) {
        input.positionHandler = (position) {
          Expect.equals(12, position);
          input.readListHandler = (bytes_read) {
            input.positionHandler = (position) {
              Expect.equals(18, position);
              input.setPositionHandler = () {
                input.positionHandler = (position) {
                  Expect.equals(8, position);
                  input.close();
                };
                input.position();
              };
              input.setPosition(8);
            };
          };
          input.readList(buffer, 12, 6);
        };
        input.position();
      };
      input.readList(buffer, 0, 12);
    };
    input.position();
    return 1;
  }

  static int testPositionSync() {
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
    return 1;
  }

  static int testTruncate() {
    File file = new File(tempDirectory.path + "/out_truncate");
    List buffer = const [65, 65, 65, 65, 65, 65, 65, 65, 65, 65];
    file.errorHandler = (error) {
      Expect.fail("testTruncate: No errors expected");
    };
    file.openHandler = (RandomAccessFile openedFile) {
      openedFile.noPendingWriteHandler = () {
        openedFile.lengthHandler = (length) {
          Expect.equals(10, length);
          openedFile.truncateHandler = () {
            openedFile.lengthHandler = (length) {
              Expect.equals(5, length);
              openedFile.closeHandler = () {
                file.deleteHandler = () {
                  file.existsHandler = (exists) {
                    Expect.isFalse(exists);
                    asyncTestDone();
                  };
                  file.exists();
                };
                file.delete();
              };
              openedFile.close();
            };
            openedFile.length();
          };
          openedFile.truncate(5);
        };
        openedFile.length();
      };
      openedFile.writeList(buffer, 0, 10);
    };
    asyncTestStarted();
    file.open(true);
    return 1;
  }

  static int testTruncateSync() {
    File file = new File(tempDirectory.path + "/out_truncate_sync");
    List buffer = const [65, 65, 65, 65, 65, 65, 65, 65, 65, 65];
    RandomAccessFile openedFile = file.openSync(true);
    openedFile.writeListSync(buffer, 0, 10);
    Expect.equals(10, openedFile.lengthSync());
    openedFile.truncateSync(5);
    Expect.equals(5, openedFile.lengthSync());
    openedFile.closeSync();
    file.deleteSync();
    Expect.isFalse(file.existsSync());
    return 1;
  }

  // Tests exception handling after file was closed.
  static int testCloseException() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    File input = new File(tempDirectory.path + "/out_close_exception");
    RandomAccessFile openedFile = input.openSync(true);
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
    return 1;
  }

  // Tests stream exception handling after file was closed.
  static int testCloseExceptionStream() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    File file = new File(tempDirectory.path + "/out_close_exception_stream");
    file.createSync();
    FileInputStream input = file.openInputStream();
    input.close();
    try {
      List<int> buffer = new List<int>(42);
      input.readInto(buffer, 0, 12);
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    OutputStream output = file.openOutputStream();
    output.close();
    try {
      List<int> buffer = new List<int>(42);
      bool readDone = output.writeFrom(buffer, 0, 12);
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    file.deleteSync();
    return 1;
  }

  // Tests buffer out of bounds exception.
  static int testBufferOutOfBoundsException() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    File file = new File(tempDirectory.path + "/out_buffer_out_of_bounds");
    RandomAccessFile openedFile = file.openSync(true);
    try {
      List<int> buffer = new List<int>(10);
      bool readDone = openedFile.readListSync(buffer, 0, 12);
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
      bool readDone = openedFile.readListSync(buffer, 6, 6);
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
      bool readDone = openedFile.readListSync(buffer, -1, 1);
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
      bool readDone = openedFile.readListSync(buffer, 0, -1);
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
      bool readDone = openedFile.writeListSync(buffer, 0, 12);
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
      bool readDone = openedFile.writeListSync(buffer, 6, 6);
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
      bool readDone = openedFile.writeListSync(buffer, -1, 1);
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
      bool readDone = openedFile.writeListSync(buffer, 0, -1);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    openedFile.closeSync();
    file.deleteSync();
    return 1;
  }

  static int testMixedSyncAndAsync() {
    var name = getFilename("tests/vm/data/fixed_length_file");
    var f = new File(name);
    f.errorHandler = (s) {
      Expect.fail("No errors expected");
    };
    f.existsHandler = (exists) {
      try {
        f.existsSync();
        Expect.fail("Expected exception");
      } catch (var e) {
        Expect.isTrue(e is FileIOException);
      }
    };
    f.exists();
    return 1;
  }

  // Helper method to be able to run the test from the runtime
  // directory, or the top directory.
  static String getFilename(String path) =>
      new File(path).existsSync() ? path : 'runtime/' + path;

  // Main test entrypoint.
  static testMain() {
    Expect.equals(1, testRead());
    Expect.equals(1, testReadSync());
    Expect.equals(1, testReadStream());
    Expect.equals(1, testLength());
    Expect.equals(1, testLengthSync());
    Expect.equals(1, testPosition());
    Expect.equals(1, testPositionSync());
    Expect.equals(1, testMixedSyncAndAsync());
    asyncTestStarted();
    createTempDirectory(() {
        Expect.equals(1, testReadWrite());
        Expect.equals(1, testReadWriteSync());
        Expect.equals(1, testReadWriteStream());
        Expect.equals(1, testTruncate());
        Expect.equals(1, testTruncateSync());
        Expect.equals(1, testCloseException());
        Expect.equals(1, testCloseExceptionStream());
        Expect.equals(1, testBufferOutOfBoundsException());
        asyncTestDone();
      });
  }
}

main() {
  FileTest.testMain();
}
