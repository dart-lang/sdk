// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing error handling in file I/O.

#import("dart:io");
#import("dart:isolate");

Directory tempDir() {
  var d = new Directory('');
  d.createTempSync();
  return d;
}


bool checkNonExistentFileException(e, str) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf(str) != -1);
  Platform platform = new Platform();
  if (platform.operatingSystem() == "linux") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (platform.operatingSystem() == "macos") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (platform.operatingSystem() == "windows") {
    Expect.isTrue(
        e.toString().indexOf(
            "The system cannot find the file specified") != -1);
  }
  // File not not found has error code 2 on all supported platforms.
  Expect.equals(2, e.osError.errorCode);

  return true;
}


bool checkOpenNonExistentFileException(e) {
  return checkNonExistentFileException(e, "Cannot open file");
}


bool checkDeleteNonExistentFileException(e) {
  return checkNonExistentFileException(e, "Cannot delete file");
}


bool checkLengthNonExistentFileException(e) {
  return checkNonExistentFileException(e, "Cannot retrieve length of file");
}


void testOpenNonExistent() {
  Directory temp = tempDir();
  ReceivePort p = new ReceivePort();
  p.receive((x, y) {
    p.close();
    temp.deleteRecursivelySync();
  });
  var file = new File("${temp.path}/nonExistentFile");

  // Non-existing file should throw exception.
  Expect.throws(() => file.openSync(),
                (e) => checkOpenNonExistentFileException(e));

  file.open(FileMode.READ, (raf) => Expect.fail("Unreachable code"));
  file.onError = (e) {
    checkOpenNonExistentFileException(e);
    p.toSendPort().send(null);
  };
}


void testDeleteNonExistent() {
  Directory temp = tempDir();
  ReceivePort p = new ReceivePort();
  p.receive((x, y) {
    p.close();
    temp.deleteRecursivelySync();
  });
  var file = new File("${temp.path}/nonExistentFile");

  // Non-existing file should throw exception.
  Expect.throws(() => file.deleteSync(),
                (e) => checkDeleteNonExistentFileException(e));

  file.delete(() => Expect.fail("Unreachable code"));
  file.onError = (e) {
    checkDeleteNonExistentFileException(e);
    p.toSendPort().send(null);
  };
}


void testLengthNonExistent() {
  Directory temp = tempDir();
  ReceivePort p = new ReceivePort();
  p.receive((x, y) {
    p.close();
    temp.deleteRecursivelySync();
  });
  var file = new File("${temp.path}/nonExistentFile");

  // Non-existing file should throw exception.
  Expect.throws(() => file.lengthSync(),
                (e) => checkLengthNonExistentFileException(e));

  file.length((len) => Expect.fail("Unreachable code"));
  file.onError = (e) {
    checkLengthNonExistentFileException(e);
    p.toSendPort().send(null);
  };
}


bool checkCreateInNonExistentDirectoryException(e) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Cannot create file") != -1);
  Platform platform = new Platform();
  if (platform.operatingSystem() == "linux") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
    Expect.equals(2, e.osError.errorCode);
  } else if (platform.operatingSystem() == "macos") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
    Expect.equals(2, e.osError.errorCode);
  } else if (platform.operatingSystem() == "windows") {
    Expect.isTrue(
        e.toString().indexOf(
            "The system cannot find the path specified") != -1);
    Expect.equals(3, e.osError.errorCode);
  }

  return true;
}

void testCreateInNonExistentDirectory() {
  Directory temp = tempDir();
  ReceivePort p = new ReceivePort();
  p.receive((x, y) {
    p.close();
    temp.deleteRecursivelySync();
  });
  var file = new File("${temp.path}/nonExistentDirectory/newFile");

  // Create in non-existent directory should throw exception.
  Expect.throws(() => file.createSync(),
                (e) => checkCreateInNonExistentDirectoryException(e));

  file.create(() => Expect.fail("Unreachable code"));
  file.onError = (e) {
    checkCreateInNonExistentDirectoryException(e);
    p.toSendPort().send(null);
  };
}

bool checkFullPathOnNonExistentDirectoryException(e) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Cannot retrieve full path") != -1);
  Platform platform = new Platform();
  if (platform.operatingSystem() == "linux") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (platform.operatingSystem() == "macos") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (platform.operatingSystem() == "windows") {
    Expect.isTrue(
        e.toString().indexOf(
            "The system cannot find the file specified") != -1);
  }
  // File not not found has error code 2 on all supported platforms.
  Expect.equals(2, e.osError.errorCode);

  return true;
}

void testFullPathOnNonExistentDirectory() {
  Directory temp = tempDir();
  ReceivePort p = new ReceivePort();
  p.receive((x, y) {
    p.close();
    temp.deleteRecursivelySync();
  });
  var file = new File("${temp.path}/nonExistentDirectory");

  // Full path non-existent directory should throw exception.
  Expect.throws(() => file.fullPathSync(),
                (e) => checkFullPathOnNonExistentDirectoryException(e));

  file.fullPath((path) => Expect.fail("Unreachable code $path"));
  file.onError = (e) {
    checkFullPathOnNonExistentDirectoryException(e);
    p.toSendPort().send(null);
  };
}

bool checkDirectoryInNonExistentDirectoryException(e) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(
      e.toString().indexOf("Cannot retrieve directory for file") != -1);
  Platform platform = new Platform();
  if (platform.operatingSystem() == "linux") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (platform.operatingSystem() == "macos") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (platform.operatingSystem() == "windows") {
    Expect.isTrue(
        e.toString().indexOf(
            "The system cannot find the file specified") != -1);
  }
  // File not not found has error code 2 on all supported platforms.
  Expect.equals(2, e.osError.errorCode);

  return true;
}

void testDirectoryInNonExistentDirectory() {
  Directory temp = tempDir();
  ReceivePort p = new ReceivePort();
  p.receive((x, y) {
    p.close();
    temp.deleteRecursivelySync();
  });
  var file = new File("${temp.path}/nonExistentDirectory/newFile");

  // Create in non-existent directory should throw exception.
  Expect.throws(() => file.directorySync(),
                (e) => checkDirectoryInNonExistentDirectoryException(e));

  file.directory((directory) => Expect.fail("Unreachable code"));
  file.onError = (e) {
    checkDirectoryInNonExistentDirectoryException(e);
    p.toSendPort().send(null);
  };
}

void testReadAsBytesNonExistent() {
  Directory temp = tempDir();
  ReceivePort p = new ReceivePort();
  p.receive((x, y) {
    p.close();
    temp.deleteRecursivelySync();
  });
  var file = new File("${temp.path}/nonExistentFile3");

  // Non-existing file should throw exception.
  Expect.throws(() => file.readAsBytesSync(),
                (e) => checkOpenNonExistentFileException(e));

  file.readAsBytes((data) => Expect.fail("Unreachable code"));
  file.onError = (e) {
    checkOpenNonExistentFileException(e);
    p.toSendPort().send(null);
  };
}

void testReadAsTextNonExistent() {
  Directory temp = tempDir();
  ReceivePort p = new ReceivePort();
  p.receive((x, y) {
    p.close();
    temp.deleteRecursivelySync();
  });
  var file = new File("${temp.path}/nonExistentFile4");

  // Non-existing file should throw exception.
  Expect.throws(() => file.readAsTextSync(),
                (e) => checkOpenNonExistentFileException(e));

  file.readAsText(Encoding.ASCII, (data) => Expect.fail("Unreachable code"));
  file.onError = (e) {
    checkOpenNonExistentFileException(e);
    p.toSendPort().send(null);
  };
}

testReadAsLinesNonExistent() {
  Directory temp = tempDir();
  ReceivePort p = new ReceivePort();
  p.receive((x, y) {
    p.close();
    temp.deleteRecursivelySync();
  });
  var file = new File("${temp.path}/nonExistentFile5");

  // Non-existing file should throw exception.
  Expect.throws(() => file.readAsLinesSync(),
                (e) => checkOpenNonExistentFileException(e));

  file.readAsLines(Encoding.ASCII, (data) => Expect.fail("Unreachable code"));
  file.onError = (e) {
    checkOpenNonExistentFileException(e);
    p.toSendPort().send(null);
  };
}

bool checkWriteReadOnlyFileException(e) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.osError.errorCode != OSError.noErrorCode);
  return true;
}


// Create a test file in a temporary directory. Setup a port to signal
// when the temporary directory should be deleted. Pass the file and
// the port to the callback argument.
createTestFile(callback) {
  Directory temp = tempDir();
  ReceivePort p = new ReceivePort();
  p.receive((x, y) {
    p.close();
    temp.deleteRecursivelySync();
  });

  var file = new File("${temp.path}/test_file");
  file.createSync();
  callback(file, p.toSendPort());
}


testWriteByteToReadOnlyFile() {
  createTestFile((file, port) {
      var openedFile = file.openSync(FileMode.READ);

      // Writing to read only file should throw an exception.
      Expect.throws(() => openedFile.writeByteSync(0),
                    (e) => checkWriteReadOnlyFileException(e));

      openedFile.writeByte(0);
      openedFile.onError = (e) {
        checkWriteReadOnlyFileException(e);
        openedFile.close(() => port.send(null));
    };
  });
}

testWriteListToReadOnlyFile() {
  createTestFile((file, port) {
    var openedFile = file.openSync(FileMode.READ);

    List data = [0, 1, 2, 3];
    // Writing to read only file should throw an exception.
    Expect.throws(() => openedFile.writeListSync(data, 0, data.length),
                  (e) => checkWriteReadOnlyFileException(e));

    openedFile.writeList(data, 0, data.length);
    openedFile.onError = (e) {
      checkWriteReadOnlyFileException(e);
      openedFile.close(() => port.send(null));
    };
  });
}

testTruncateReadOnlyFile() {
  createTestFile((file, port) {
    var openedFile = file.openSync(FileMode.WRITE);
    openedFile.writeByteSync(0);
    openedFile.closeSync();
    openedFile = file.openSync(FileMode.READ);

    // Truncating read only file should throw an exception.
    Expect.throws(() => openedFile.truncateSync(0),
                  (e) => checkWriteReadOnlyFileException(e));

    openedFile.truncate(0, () => Expect.fail("Unreachable code"));
    openedFile.onError = (e) {
      checkWriteReadOnlyFileException(e);
      openedFile.close(() => port.send(null));
    };
  });
}

bool checkFileClosedException(e) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.toString().indexOf("File closed") != -1);
  Expect.isTrue(e.osError == null);
  return true;
}

testOperateOnClosedFile() {
  createTestFile((file, port) {
    var openedFile = file.openSync(FileMode.READ);
    openedFile.closeSync();

    List data = [0, 1, 2, 3];
    Expect.throws(() => openedFile.readByteSync(),
                  (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.writeByteSync(0),
                  (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.writeListSync(data, 0, data.length),
                  (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.readListSync(data, 0, data.length),
                  (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.writeStringSync("Hello"),
                  (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.positionSync(),
                  (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.setPositionSync(0),
                  (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.truncateSync(0),
                  (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.lengthSync(),
                  (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.flushSync(),
                  (e) => checkFileClosedException(e));

    var errorCount = 0;
    openedFile.readByte((byte) => Expect.fail("Unreachable code"));
    errorCount++;
    openedFile.writeByte(0);
    errorCount++;
    openedFile.readList(
        data, 0, data.length, (bytesRead) => Expect.fail("Unreachable code"));
    errorCount++;
    openedFile.writeList(data, 0, data.length);
    errorCount++;
    openedFile.writeString("Hello");
    errorCount++;
    openedFile.position((position) => Expect.fail("Unreachable code"));
    errorCount++;
    openedFile.setPosition(0, () => Expect.fail("Unreachable code"));
    errorCount++;
    openedFile.truncate(0, () => Expect.fail("Unreachable code"));
    errorCount++;
    openedFile.length((length) => Expect.fail("Unreachable code"));
    errorCount++;
    openedFile.flush(() => Expect.fail("Unreachable code"));
    errorCount++;

    openedFile.onError = (e) {
      checkFileClosedException(e);
      if (--errorCount == 0) {
        port.send(null);
      }
    };
  });
}

testRepeatedlyCloseFile() {
  createTestFile((file, port) {
    var openedFile = file.openSync();
    openedFile.close(() {
      openedFile.onError = (e) {
        Expect.isTrue(e is FileIOException);
        port.send(null);
      };
      openedFile.close(() => null);
    });
  });
}

main() {
  testOpenNonExistent();
  testDeleteNonExistent();
  testLengthNonExistent();
  testCreateInNonExistentDirectory();
  testFullPathOnNonExistentDirectory();
  testDirectoryInNonExistentDirectory();
  testReadAsBytesNonExistent();
  testReadAsTextNonExistent();
  testReadAsLinesNonExistent();
  testWriteByteToReadOnlyFile();
  testWriteListToReadOnlyFile();
  testTruncateReadOnlyFile();
  testOperateOnClosedFile();
  testRepeatedlyCloseFile();
}
