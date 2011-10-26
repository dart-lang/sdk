// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file I/O.


class FileTest {
  // Test for file read functionality.
  static int testReadStream() {
    // Read a file and check part of it's contents.
    String filename = getFilename("bin/file_test.cc");
    File file = new File(filename, false);
    InputStream input = file.inputStream;
    List<int> buffer = new List<int>(42);
    int bytesRead = input.readInto(buffer, 0, 12);
    Expect.equals(12, bytesRead);
    bytesRead = input.readInto(buffer, 12, 30);
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
    File file = new File(inFilename, false);
    InputStream input = file.inputStream;
    List<int> buffer1 = new List<int>(42);
    int bytesRead = input.readInto(buffer1, 0, 42);
    Expect.equals(42, bytesRead);
    file.close();
    // Write the contents of the file just read into another file.
    String outFilename = getFilename("tests/vm/data/fixed_length_file_out");
    file = new File(outFilename, true);
    OutputStream output = file.outputStream;
    bool writeDone = output.write(buffer1, 0, 42, null);
    Expect.equals(true, writeDone);
    file.close();
    // Now read the contents of the file just written.
    List<int> buffer2 = new List<int>(42);
    file = new File(outFilename, false);
    input = file.inputStream;
    bytesRead = input.readInto(buffer2, 0, 42);
    Expect.equals(42, bytesRead);
    file.close();
    // Now compare the two buffers to check if they are identical.
    for (int i = 0; i < buffer1.length; i++) {
      Expect.equals(buffer1[i],  buffer2[i]);
    }
    return 1;
  }
  static int testRead() {
    // Read a file and check part of it's contents.
    String filename = getFilename("bin/file_test.cc");
    File file = new File(filename, false);
    assert(file != null);
    List<int> buffer = new List<int>(42);
    int bytes_read = 0;
    bytes_read = file.readList(buffer, 0, 12);
    Expect.equals(12, bytes_read);
    bytes_read = file.readList(buffer, 12, 30);
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
    File file = new File(inFilename, false);
    List<int> buffer1 = new List<int>(42);
    int bytes_read = 0;
    int bytes_written = 0;
    bytes_read = file.readList(buffer1, 0, 42);
    Expect.equals(42, bytes_read);
    file.close();
    // Write the contents of the file just read into another file.
    String outFilenameBase = "tests/vm/data/fixed_length_file_out";
    file = createFile(outFilenameBase);
    Expect.isNotNull(file);
    file.writeList(buffer1, 0, bytes_read);
    file.close();
    // Now read the contents of the file just written.
    List<int> buffer2 = new List<int>(bytes_read);
    file = new File(getFilename(outFilenameBase), false);
    assert(file != null);
    bytes_read = file.readList(buffer2, 0, 42);
    Expect.equals(42, bytes_read);
    file.close();
    // Now compare the two buffers to check if they are identical.
    Expect.equals(buffer1.length, buffer2.length);
    for (int i = 0; i < buffer1.length; i++) {
      Expect.equals(buffer1[i],  buffer2[i]);
    }
    return 1;
  }

  // Test for file length functionality.
  static int testLength() {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    File input = new File(filename, false);
    assert(input != null);
    Expect.equals(42, input.length);
    return 1;
  }
  // Test for file position functionality.
  static int testPosition() {
    String filename = getFilename("tests/vm/data/fixed_length_file");
    File input = new File(filename, false);
    assert(input != null);
    Expect.equals(0, input.position);
    List<int> buffer = new List<int>(100);
    input.readList(buffer, 0, 12);
    Expect.equals(12, input.position);
    input.readList(buffer, 12, 6);
    Expect.equals(18, input.position);
    return 1;
  }
  // Tests exception handling after file was closed.
  static int testCloseException() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    String filename = getFilename("tests/vm/data/fixed_length_file_out");
    File input = new File(filename, true);
    Expect.isNotNull(input);
    assert(input != null);
    input.close();
    try {
      input.readByte();
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      input.writeByte(1);
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      input.writeString("Test");
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
      input.readList(buffer, 0, 10);
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
      input.writeList(buffer, 0, 10);
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      input.position;
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      input.length;
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      input.flush();
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    return 1;
  }
  // Tests stream exception handling after file was closed.
  static int testCloseExceptionStream() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    String filename = getFilename("tests/vm/data/fixed_length_file_out");
    File file = new File(filename, true);
    assert(file != null);
    file.close();
    InputStream input = file.inputStream;
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
    OutputStream output = file.outputStream;
    try {
      List<int> buffer = new List<int>(42);
      bool readDone = output.write(buffer, 0, 12, null);
    } catch (FileIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    return 1;
  }
  // Tests buffer out of bounds exception.
  static int testBufferOutOfBoundsException() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    String filename = getFilename("tests/vm/data/fixed_length_file_out");
    File file = new File(filename, true);
    assert(file != null);
    try {
      List<int> buffer = new List<int>(10);
      bool readDone = file.readList(buffer, 0, 12);
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
      bool readDone = file.readList(buffer, 6, 6);
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
      bool readDone = file.readList(buffer, -1, 1);
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
      bool readDone = file.readList(buffer, 0, -1);
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
      bool readDone = file.writeList(buffer, 0, 12);
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
      bool readDone = file.writeList(buffer, 6, 6);
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
      bool readDone = file.writeList(buffer, -1, 1);
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
      bool readDone = file.writeList(buffer, 0, -1);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);

    return 1;
  }

  // Helper method to be able to run the test from the runtime
  // directory, or the top directory.
  static String getFilename(String path) =>
      FileUtil.fileExists(path) ? path : 'runtime/' + path;

  static File createFile(String path) {
    File file = new File(path, true);
    if (file === null) {
      file = new File('runtime/' + path, true);
    }
    return file;
  }

  // Main test entrypoint.
  static testMain() {
    Expect.equals(1, testRead());
    Expect.equals(1, testReadWrite());
    Expect.equals(1, testReadStream());
    Expect.equals(1, testReadWriteStream());
    Expect.equals(1, testLength());
    Expect.equals(1, testPosition());
    Expect.equals(1, testCloseException());
    Expect.equals(1, testCloseExceptionStream());
    Expect.equals(1, testBufferOutOfBoundsException());
  }
}

main() {
  FileTest.testMain();
}
