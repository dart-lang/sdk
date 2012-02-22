// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file I/O.

#import("dart:io");

class MyListOfOneElement implements List {
  int _value;
  MyListOfOneElement(this._value);
  int get length() => 1;
  operator [](int index) => _value;
}

class FileTest {
  static Directory tempDirectory;
  static int numLiveAsyncTests = 0;

  static void asyncTestStarted() { ++numLiveAsyncTests; }
  static void asyncTestDone(String name) {
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
  static void testReadStream() {
    // Read a file and check part of it's contents.
    String filename = getFilename("bin/file_test.cc");
    File file = new File(filename);
    InputStream input = file.openInputStream();
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
  }

  // Test for file read and write functionality.
  static void testReadWriteStream() {
    // Read a file.
    String inFilename = getFilename("tests/vm/data/fixed_length_file");
    File file;
    InputStream input;
    int bytesRead;

    // Test reading all using readInto.
    file = new File(inFilename);
    input = file.openInputStream();
    List<int> buffer1 = new List<int>(42);
    bytesRead = input.readInto(buffer1, 0, 42);
    Expect.equals(42, bytesRead);
    Expect.isTrue(input.closed);

    // Test reading all using readInto and read.
    file = new File(inFilename);
    input = file.openInputStream();
    bytesRead = input.readInto(buffer1, 0, 21);
    Expect.equals(21, bytesRead);
    buffer1 = input.read();
    Expect.equals(21, buffer1.length);
    Expect.isTrue(input.closed);

    // Test reading all using read and readInto.
    file = new File(inFilename);
    input = file.openInputStream();
    buffer1 = input.read(21);
    Expect.equals(21, buffer1.length);
    bytesRead = input.readInto(buffer1, 0, 21);
    Expect.equals(21, bytesRead);
    Expect.isTrue(input.closed);

    // Test reading all using read.
    file = new File(inFilename);
    input = file.openInputStream();
    buffer1 = input.read();
    Expect.equals(42, buffer1.length);
    Expect.isTrue(input.closed);

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
    Expect.isTrue(input.closed);
    Expect.equals(42, bytesRead);
    // Now compare the two buffers to check if they are identical.
    for (int i = 0; i < buffer1.length; i++) {
      Expect.equals(buffer1[i],  buffer2[i]);
    }
    // Delete the output file.
    file.deleteSync();
    Expect.isFalse(file.existsSync());
  }

  static void testRead() {
    // Read a file and check part of it's contents.
    String filename = getFilename("bin/file_test.cc");
    File file = new File(filename);
    file.errorHandler = (s) {
      Expect.fail("No errors expected : $s");
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
    file.errorHandler = (s) {
      Expect.fail("No errors expected : $s");
    };
    file.openHandler = (RandomAccessFile openedFile) {
      openedFile.errorHandler = (s) {
        Expect.fail("No errors expected : $s");
      };
      List<int> buffer1 = new List<int>(42);
      openedFile.readListHandler = (bytes_read) {
        Expect.equals(42, bytes_read);
        openedFile.closeHandler = () {
          // Write the contents of the file just read into another file.
          String outFilename = tempDirectory.path + "/out_read_write";
          final File file2 = new File(outFilename);
          file2.errorHandler = (s) {
            Expect.fail("No errors expected : $s");
          };
          file2.createHandler = () {
            file2.fullPathHandler = (s) {
              Expect.isTrue(new File(s).existsSync());
              if (s[0] != '/' && s[0] != '\\' && s[1] != ':') {
                Expect.fail("Not a full path");
              }
              file2.openHandler = (RandomAccessFile openedFile2) {
                openedFile2.errorHandler = (s) {
                  Expect.fail("No errors expected : $s");
                };
                openedFile2.noPendingWriteHandler = () {
                  openedFile2.closeHandler = () {
                    List<int> buffer2 = new List<int>(bytes_read);
                    final File file3 = new File(outFilename);
                    file3.errorHandler = (s) {
                      Expect.fail("No errors expected : $s");
                    };
                    file3.openHandler = (RandomAccessFile openedFile3) {
                      openedFile3.errorHandler = (s) {
                        Expect.fail("No errors expected : $s");
                      };
                      openedFile3.readListHandler = (bytes_read) {
                       Expect.equals(42, bytes_read);
                        openedFile3.closeHandler = () {
                          // Now compare the two buffers to check if they
                          // are identical.
                          Expect.equals(buffer1.length, buffer2.length);
                          for (int i = 0; i < buffer1.length; i++) {
                            Expect.equals(buffer1[i],  buffer2[i]);
                          }
                          // Delete the output file.
                          final file4 = file3;
                          file4.deleteHandler = () {
                            file4.existsHandler = (exists) {
                              Expect.isFalse(exists);
                              asyncTestDone("testReadWrite");
                            };
                            file4.exists();
                          };
                          file4.delete();
                        };
                        openedFile3.close();
                      };
                      openedFile3.readList(buffer2, 0, 42);
                    };
                    file3.open();
                  };
                  openedFile2.close();
                };
                openedFile2.writeList(buffer1, 0, bytes_read);
              };
              file2.open(FileMode.WRITE);
            };
            file2.fullPath();
          };
          file2.create();
        };
        openedFile.close();
      };
      openedFile.readList(buffer1, 0, 42);
    };
    asyncTestStarted();
    file.open();
  }

  static void testWriteAppend() {
    String content = "foobar";
    String filename = tempDirectory.path + "/write_append";
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
    String filename = tempDirectory.path + "/outstream_write_append";
    File file = new File(filename);
    file.createSync();
    List<int> buffer = content.charCodes();
    OutputStream outStream = file.openOutputStream();
    outStream.write(buffer);
    outStream.close();
    File file2 = new File(filename);
    OutputStream appendingOutput = file2.openOutputStream(FileMode.APPEND);
    appendingOutput.write(buffer);
    appendingOutput.close();
    File file3 = new File(filename);
    file3.openHandler = (RandomAccessFile openedFile) {
      openedFile.lengthHandler = (int length) {
        Expect.equals(content.length * 2, length);
        openedFile.closeHandler = () {
          file3.deleteHandler = () {
            asyncTestDone("testOutputStreamWriteAppend");
          };
          file3.delete();
        };
        openedFile.close();
      };
      openedFile.length();
    };
    file3.open();
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
    String outFilename = tempDirectory.path + "/out_read_write_sync";
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
    String fileName = tempDirectory.path + "/empty_file_sync";
    File file = new File(fileName);
    file.createSync();
    RandomAccessFile openedFile = file.openSync();
    Expect.throws(() => openedFile.readByteSync(), (e) => e is FileIOException);
    openedFile.closeSync();
    file.deleteSync();
  }

  static void testReadEmptyFile() {
    String fileName = tempDirectory.path + "/empty_file";
    File file = new File(fileName);
    file.errorHandler = (s) {
      Expect.fail("No errors expected : $s");
    };
    file.createHandler = () {
      file.openHandler = (RandomAccessFile openedFile) {
        openedFile.readByteHandler = (int byte) {
          Expect.fail("Read byte from empty file");
        };
        openedFile.errorHandler = (String err) {
          Expect.isTrue(err.indexOf("failed") != -1);
          openedFile.closeHandler = () {
            file.deleteHandler = () {
              asyncTestDone("testReadEmptyFile");
            };
            file.delete();
          };
          openedFile.close();
        };
        openedFile.readByte();
      };
      file.open();
    };
    asyncTestStarted();
    file.create();
  }

  // Test for file write of different types of lists.
  static void testWriteVariousLists() {
    final String fileName = "${tempDirectory.path}/testWriteVariousLists";
    final File file = new File(fileName);
    file.create();
    file.createHandler = () {
      file.open(FileMode.WRITE);
      file.openHandler = (RandomAccessFile openedFile) {
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
        openedFile.writeList([y - x], 0, 1);

        openedFile.errorHandler = (s) {
          Expect.fail("No errors expected : $s");
        };
        openedFile.noPendingWriteHandler = () {
          openedFile.close();
        };
        openedFile.closeHandler = () {
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
        };
      };
      file.errorHandler = (s) {
        Expect.fail("No errors expected : $s");
      };
    };
  }

  // Test for file length functionality.
  static void testLength() {
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
  }

  static void testLengthSync() {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    RandomAccessFile input = (new File(filename)).openSync();
    Expect.equals(42, input.lengthSync());
    input.closeSync();
  }

  // Test for file position functionality.
  static void testPosition() {
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
                    asyncTestDone("testTruncate");
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
    file.open(FileMode.WRITE);
  }

  static void testTruncateSync() {
    File file = new File(tempDirectory.path + "/out_truncate_sync");
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
    File input = new File(tempDirectory.path + "/out_close_exception");
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
    List<int> buffer = new List<int>(42);
    File file = new File(tempDirectory.path + "/out_close_exception_stream");
    file.createSync();
    InputStream input = file.openInputStream();
    Expect.isTrue(input.closed);
    Expect.isNull(input.readInto(buffer, 0, 12));
    OutputStream output = file.openOutputStream();
    output.close();
    Expect.throws(( ) => output.writeFrom(buffer, 0, 12),
                  (e) => e is FileIOException);
    file.deleteSync();
  }

  // Tests buffer out of bounds exception.
  static void testBufferOutOfBoundsException() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    File file = new File(tempDirectory.path + "/out_buffer_out_of_bounds");
    RandomAccessFile openedFile = file.openSync(FileMode.WRITE);
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
  }

  static void testMixedSyncAndAsync() {
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
  }

  static void testOpenDirectoryAsFile() {
    var f = new File('.');
    f.open();
    f.openHandler = (r) => Expect.fail('Directory opened as file');
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

  // Test that opens the same file for writing then for appending to test
  // that the file is not truncated when opened for appending.
  static void testAppend() {
    var file = new File('${tempDirectory.path}/out_append');
    file.openHandler = (openedFile) {
      openedFile.noPendingWriteHandler = () {
        openedFile.closeHandler = () {
          file.openHandler = (openedFile) {
            openedFile.lengthHandler = (length) {
              Expect.equals(4, length);
              openedFile.setPositionHandler = () {
                openedFile.noPendingWriteHandler = () {
                  openedFile.lengthHandler = (length) {
                    Expect.equals(8, length);
                    openedFile.closeHandler = () {
                      file.deleteHandler = () {
                        file.existsHandler = (exists) {
                          Expect.isFalse(exists);
                          asyncTestDone("testAppend");
                        };
                        file.exists();
                      };
                      file.delete();
                    };
                    openedFile.close();
                  };
                  openedFile.length();
                };
                openedFile.writeString("asdf");
              };
              openedFile.setPosition(4);
            };
            openedFile.length();
          };
          file.open(FileMode.APPEND);
        };
        openedFile.close();
      };
      openedFile.writeString("asdf");
    };
    asyncTestStarted();
    file.open(FileMode.WRITE);
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
      new File(path).existsSync() ? path : 'runtime/' + path;

  // Main test entrypoint.
  static testMain() {
    testRead();
    testReadSync();
    testReadStream();
    testLength();
    testLengthSync();
    testPosition();
    testPositionSync();
    testMixedSyncAndAsync();
    testOpenDirectoryAsFile();
    testOpenDirectoryAsFileSync();

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
        testWriteVariousLists();
      });
  }
}

main() {
  FileTest.testMain();
}
