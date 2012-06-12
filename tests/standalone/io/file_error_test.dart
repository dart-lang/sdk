// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing error handling in file I/O.

#import("dart:io");
#import("dart:isolate");

Directory tempDir() {
  return new Directory('').createTempSync();
}


bool checkNonExistentFileException(e, str) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf(str) != -1);
  if (Platform.operatingSystem == "linux") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (Platform.operatingSystem == "macos") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (Platform.operatingSystem == "windows") {
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

  var openFuture = file.open(FileMode.READ);
  openFuture.then((raf) => Expect.fail("Unreachable code"));
  openFuture.handleException((e) {
    checkOpenNonExistentFileException(e);
    p.toSendPort().send(null);
    return true;
  });
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

  var delete = file.delete();
  delete.then((ignore) => Expect.fail("Unreachable code"));
  delete.handleException((e) {
    checkDeleteNonExistentFileException(e);
    p.toSendPort().send(null);
    return true;
  });
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

  var lenFuture = file.length();
  lenFuture.then((len) => Expect.fail("Unreachable code"));
  lenFuture.handleException((e) {
    checkLengthNonExistentFileException(e);
    p.toSendPort().send(null);
    return true;
  });
}


bool checkCreateInNonExistentDirectoryException(e) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Cannot create file") != -1);
  if (Platform.operatingSystem == "linux") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "macos") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "windows") {
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

  var create = file.create();
  create.then((ignore) => Expect.fail("Unreachable code"));
  create.handleException((e) {
    checkCreateInNonExistentDirectoryException(e);
    p.toSendPort().send(null);
    return true;
  });
}

bool checkFullPathOnNonExistentDirectoryException(e) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Cannot retrieve full path") != -1);
  if (Platform.operatingSystem == "linux") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (Platform.operatingSystem == "macos") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (Platform.operatingSystem == "windows") {
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

  var fullPathFuture = file.fullPath();
  fullPathFuture.then((path) => Expect.fail("Unreachable code $path"));
  fullPathFuture.handleException((e) {
    checkFullPathOnNonExistentDirectoryException(e);
    p.toSendPort().send(null);
    return true;
  });
}

bool checkDirectoryInNonExistentDirectoryException(e) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(
      e.toString().indexOf("Cannot retrieve directory for file") != -1);
  if (Platform.operatingSystem == "linux") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (Platform.operatingSystem == "macos") {
    Expect.isTrue(e.toString().indexOf("No such file or directory") != -1);
  } else if (Platform.operatingSystem == "windows") {
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

  var dirFuture = file.directory();
  dirFuture.then((directory) => Expect.fail("Unreachable code"));
  dirFuture.handleException((e) {
    checkDirectoryInNonExistentDirectoryException(e);
    p.toSendPort().send(null);
    return true;
  });
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

  var readAsBytesFuture = file.readAsBytes();
  readAsBytesFuture.then((data) => Expect.fail("Unreachable code"));
  readAsBytesFuture.handleException((e) {
    checkOpenNonExistentFileException(e);
    p.toSendPort().send(null);
    return true;
  });
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

  var readAsTextFuture = file.readAsText(Encoding.ASCII);
  readAsTextFuture.then((data) => Expect.fail("Unreachable code"));
  readAsTextFuture.handleException((e) {
    checkOpenNonExistentFileException(e);
    p.toSendPort().send(null);
    return true;
  });
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

  var readAsLinesFuture = file.readAsLines(Encoding.ASCII);
  readAsLinesFuture.then((data) => Expect.fail("Unreachable code"));
  readAsLinesFuture.handleException((e) {
    checkOpenNonExistentFileException(e);
    p.toSendPort().send(null);
    return true;
  });
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

    var writeByteFuture = openedFile.writeByte(0);
    writeByteFuture.handleException((e) {
      checkWriteReadOnlyFileException(e);
      openedFile.close().then((ignore) => port.send(null));
      return true;
    });
  });
}

testWriteListToReadOnlyFile() {
  createTestFile((file, port) {
    var openedFile = file.openSync(FileMode.READ);

    List data = [0, 1, 2, 3];
    // Writing to read only file should throw an exception.
    Expect.throws(() => openedFile.writeListSync(data, 0, data.length),
                  (e) => checkWriteReadOnlyFileException(e));

    var writeListFuture = openedFile.writeList(data, 0, data.length);
    writeListFuture.handleException((e) {
      checkWriteReadOnlyFileException(e);
      openedFile.close().then((ignore) => port.send(null));
      return true;
    });
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

    var truncateFuture = openedFile.truncate(0);
    truncateFuture.then((ignore) => Expect.fail("Unreachable code"));
    truncateFuture.handleException((e) {
      checkWriteReadOnlyFileException(e);
      openedFile.close().then((ignore) => port.send(null));
      return true;
    });
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

    _errorHandler(e) {
      checkFileClosedException(e);
      if (--errorCount == 0) {
        port.send(null);
      }
      return true;
    }

    var readByteFuture = openedFile.readByte();
    readByteFuture.then((byte) => Expect.fail("Unreachable code"));
    readByteFuture.handleException(_errorHandler);
    errorCount++;
    var writeByteFuture = openedFile.writeByte(0);
    writeByteFuture.then((ignore) => Expect.fail("Unreachable code"));
    writeByteFuture.handleException(_errorHandler);
    errorCount++;
    var readListFuture = openedFile.readList(data, 0, data.length);
    readListFuture.then((bytesRead) => Expect.fail("Unreachable code"));
    readListFuture.handleException(_errorHandler);
    errorCount++;
    var writeListFuture = openedFile.writeList(data, 0, data.length);
    writeListFuture.then((ignore) => Expect.fail("Unreachable code"));
    writeListFuture.handleException(_errorHandler);
    errorCount++;
    var writeStringFuture = openedFile.writeString("Hello");
    writeStringFuture.then((ignore) => Expect.fail("Unreachable code"));
    writeStringFuture.handleException(_errorHandler);
    errorCount++;
    var positionFuture = openedFile.position();
    positionFuture.then((position) => Expect.fail("Unreachable code"));
    positionFuture.handleException(_errorHandler);
    errorCount++;
    var setPositionFuture = openedFile.setPosition(0);
    setPositionFuture.then((ignore) => Expect.fail("Unreachable code"));
    setPositionFuture.handleException(_errorHandler);
    errorCount++;
    var truncateFuture = openedFile.truncate(0);
    truncateFuture.then((ignore) => Expect.fail("Unreachable code"));
    truncateFuture.handleException(_errorHandler);
    errorCount++;
    var lenFuture = openedFile.length();
    lenFuture.then((length) => Expect.fail("Unreachable code"));
    lenFuture.handleException(_errorHandler);
    errorCount++;
    var flushFuture = openedFile.flush();
    flushFuture.then((ignore) => Expect.fail("Unreachable code"));
    flushFuture.handleException(_errorHandler);
    errorCount++;
  });
}

testRepeatedlyCloseFile() {
  createTestFile((file, port) {
    var openedFile = file.openSync();
    openedFile.close().then((ignore) {
      var closeFuture = openedFile.close();
      closeFuture.handleException((e) {
        Expect.isTrue(e is FileIOException);
        port.send(null);
        return true;
      });
      closeFuture.then((ignore) => null);
    });
  });
}

testRepeatedlyCloseFileSync() {
  createTestFile((file, port) {
    var openedFile = file.openSync();
    openedFile.closeSync();
    Expect.throws(openedFile.closeSync,
                  (e) => e is FileIOException);
    port.send(null);
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
  testRepeatedlyCloseFileSync();
}
