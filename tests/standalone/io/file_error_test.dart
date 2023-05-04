// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing error handling in file I/O.

import "dart:convert";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

Directory tempDir() {
  return Directory.systemTemp.createTempSync('dart_file_error');
}

bool checkCannotOpenFileException(e) {
  Expect.isTrue(e is PathNotFoundException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Cannot open file") != -1);
  if (Platform.operatingSystem == "linux") {
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "macos") {
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "windows") {
    Expect.equals(3, e.osError.errorCode);
  }
  return true;
}

bool checkNonExistentFileSystemException(e, str) {
  Expect.isTrue(e is PathNotFoundException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf(str) != -1);
  // File not found has error code 2 on all supported platforms.
  Expect.equals(2, e.osError.errorCode);
  return true;
}

bool checkOpenNonExistentFileSystemException(e) {
  return checkNonExistentFileSystemException(e, "Cannot open file");
}

bool checkDeleteNonExistentFileSystemException(e) {
  return checkNonExistentFileSystemException(e, "Cannot delete file");
}

bool checkLengthNonExistentFileSystemException(e) {
  return checkNonExistentFileSystemException(
      e, "Cannot retrieve length of file");
}

void testOpenBlankFilename() {
  asyncStart();
  var file = new File("");

  // Non-existing file should throw exception.
  Expect.throws(() => file.openSync(), (e) => checkCannotOpenFileException(e));

  var openFuture = file.open(mode: FileMode.read);
  openFuture.then((raf) => Expect.fail("Unreachable code")).catchError((error) {
    checkCannotOpenFileException(error);
    asyncEnd();
    return file;
  });
}

void testOpenNonExistent() {
  asyncStart();
  Directory temp = tempDir();
  var file = new File("${temp.path}/nonExistentFile");

  // Non-existing file should throw exception.
  Expect.throws(
      () => file.openSync(), (e) => checkOpenNonExistentFileSystemException(e));

  var openFuture = file.open(mode: FileMode.read);
  openFuture.then((raf) => Expect.fail("Unreachable code")).catchError((error) {
    checkOpenNonExistentFileSystemException(error);
    temp.deleteSync(recursive: true);
    asyncEnd();
    return file;
  });
}

void testDeleteNonExistent() {
  asyncStart();
  Directory temp = tempDir();
  var file = new File("${temp.path}/nonExistentFile");

  // Non-existing file should throw exception.
  Expect.throws(() => file.deleteSync(),
      (e) => checkDeleteNonExistentFileSystemException(e));

  var delete = file.delete();
  delete.then((ignore) => Expect.fail("Unreachable code")).catchError((error) {
    checkDeleteNonExistentFileSystemException(error);
    temp.deleteSync(recursive: true);
    asyncEnd();
    return file;
  });
}

void testLengthNonExistent() {
  asyncStart();
  Directory temp = tempDir();
  var file = new File("${temp.path}/nonExistentFile");

  // Non-existing file should throw exception.
  Expect.throws(() => file.lengthSync(),
      (e) => checkLengthNonExistentFileSystemException(e));

  var lenFuture = file.length();
  lenFuture.then((len) => Expect.fail("Unreachable code")).catchError((error) {
    checkLengthNonExistentFileSystemException(error);
    temp.deleteSync(recursive: true);
    asyncEnd();
    return file;
  });
}

bool checkCreateInNonExistentFileSystemException(e) {
  Expect.isTrue(e is FileSystemException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Cannot create file") != -1);
  if (Platform.operatingSystem == "linux") {
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "macos") {
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "windows") {
    Expect.equals(3, e.osError.errorCode);
  }

  return true;
}

void testCreateInNonExistentDirectory() {
  asyncStart();
  Directory temp = tempDir();
  var file = new File("${temp.path}/nonExistentDirectory/newFile");

  // Create in nonexistent directory should throw exception.
  Expect.throws(() => file.createSync(),
      (e) => checkCreateInNonExistentFileSystemException(e));

  var create = file.create();
  create.then((ignore) => Expect.fail("Unreachable code")).catchError((error) {
    checkCreateInNonExistentFileSystemException(error);
    temp.deleteSync(recursive: true);
    asyncEnd();
    return file;
  });
}

bool checkResolveSymbolicLinksOnNonExistentFileSystemException(e) {
  Expect.isTrue(e is FileSystemException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Cannot resolve symbolic links") != -1);
  // File not found has error code 2 on all supported platforms.
  Expect.equals(2, e.osError.errorCode);

  return true;
}

void testResolveSymbolicLinksOnNonExistentDirectory() {
  asyncStart();
  Directory temp = tempDir();
  var file = new File("${temp.path}/nonExistentDirectory");

  // Full path nonexistent directory should throw exception.
  Expect.throws(() => file.resolveSymbolicLinksSync(),
      (e) => checkResolveSymbolicLinksOnNonExistentFileSystemException(e));

  var resolvedFuture = file.resolveSymbolicLinks();
  resolvedFuture
      .then((path) => Expect.fail("Unreachable code $path"))
      .catchError((error) {
    checkResolveSymbolicLinksOnNonExistentFileSystemException(error);
    temp.deleteSync(recursive: true);
    asyncEnd();
    return file;
  });
}

void testReadAsBytesNonExistent() {
  asyncStart();
  Directory temp = tempDir();
  var file = new File("${temp.path}/nonExistentFile3");

  // Non-existing file should throw exception.
  Expect.throws(() => file.readAsBytesSync(),
      (e) => checkOpenNonExistentFileSystemException(e));

  var readAsBytesFuture = file.readAsBytes();
  readAsBytesFuture
      .then((data) => Expect.fail("Unreachable code"))
      .catchError((error) {
    checkOpenNonExistentFileSystemException(error);
    temp.deleteSync(recursive: true);
    asyncEnd();
    return file;
  });
}

void testReadAsTextNonExistent() {
  asyncStart();
  Directory temp = tempDir();
  var file = new File("${temp.path}/nonExistentFile4");

  // Non-existing file should throw exception.
  Expect.throws(() => file.readAsStringSync(),
      (e) => checkOpenNonExistentFileSystemException(e));

  var readAsStringFuture = file.readAsString(encoding: ascii);
  readAsStringFuture
      .then((data) => Expect.fail("Unreachable code"))
      .catchError((error) {
    checkOpenNonExistentFileSystemException(error);
    temp.deleteSync(recursive: true);
    asyncEnd();
    return file;
  });
}

testReadAsLinesNonExistent() {
  asyncStart();
  Directory temp = tempDir();
  var file = new File("${temp.path}/nonExistentFile5");

  // Non-existing file should throw exception.
  Expect.throws(() => file.readAsLinesSync(),
      (e) => checkOpenNonExistentFileSystemException(e));

  var readAsLinesFuture = file.readAsLines(encoding: ascii);
  readAsLinesFuture
      .then((data) => Expect.fail("Unreachable code"))
      .catchError((error) {
    checkOpenNonExistentFileSystemException(error);
    temp.deleteSync(recursive: true);
    asyncEnd();
    return file;
  });
}

bool checkWriteReadOnlyFileSystemException(e) {
  Expect.isTrue(e is FileSystemException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.osError.errorCode != OSError.noErrorCode);
  return true;
}

// Create a test file in a temporary directory. Setup a port to signal
// when the temporary directory should be deleted. Pass the file and
// the port to the callback argument.
createTestFile(callback) {
  asyncStart();
  Directory temp = tempDir();
  var file = new File("${temp.path}/test_file");
  file.createSync();
  callback(file, () {
    temp.deleteSync(recursive: true);
    asyncEnd();
  });
}

testWriteByteToReadOnlyFile() {
  createTestFile((file, done) {
    var openedFile = file.openSync(mode: FileMode.read);

    // Writing to read only file should throw an exception.
    Expect.throws(() => openedFile.writeByteSync(0),
        (e) => checkWriteReadOnlyFileSystemException(e));

    var writeByteFuture = openedFile.writeByte(0);
    writeByteFuture.catchError((error) {
      checkWriteReadOnlyFileSystemException(error);
      openedFile.close().then((_) => done());
      return openedFile;
    });
  });
}

testWriteFromToReadOnlyFile() {
  createTestFile((file, done) {
    var openedFile = file.openSync(mode: FileMode.read);

    List<int> data = [0, 1, 2, 3];
    // Writing to read only file should throw an exception.
    Expect.throws(() => openedFile.writeFromSync(data, 0, data.length),
        (e) => checkWriteReadOnlyFileSystemException(e));

    var writeFromFuture = openedFile.writeFrom(data, 0, data.length);
    writeFromFuture.catchError((error) {
      checkWriteReadOnlyFileSystemException(error);
      openedFile.close().then((_) => done());
      return openedFile;
    });
  });
}

testTruncateReadOnlyFile() {
  createTestFile((file, done) {
    var openedFile = file.openSync(mode: FileMode.write);
    openedFile.writeByteSync(0);
    openedFile.closeSync();
    openedFile = file.openSync(mode: FileMode.read);

    // Truncating read only file should throw an exception.
    Expect.throws(() => openedFile.truncateSync(0),
        (e) => checkWriteReadOnlyFileSystemException(e));

    var truncateFuture = openedFile.truncate(0);
    truncateFuture
        .then((ignore) => Expect.fail("Unreachable code"))
        .catchError((error) {
      checkWriteReadOnlyFileSystemException(error);
      openedFile.close().then((_) => done());
      return openedFile;
    });
  });
}

bool checkFileClosedException(e) {
  Expect.isTrue(e is FileSystemException);
  Expect.isTrue(e.toString().indexOf("File closed") != -1);
  Expect.isTrue(e.osError == null);
  return true;
}

testOperateOnClosedFile() {
  createTestFile((file, done) {
    var openedFile = file.openSync(mode: FileMode.read);
    openedFile.closeSync();

    List<int> data = [0, 1, 2, 3];
    Expect.throws(
        () => openedFile.readByteSync(), (e) => checkFileClosedException(e));
    Expect.throws(
        () => openedFile.writeByteSync(0), (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.writeFromSync(data, 0, data.length),
        (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.readIntoSync(data, 0, data.length),
        (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.writeStringSync("Hello"),
        (e) => checkFileClosedException(e));
    Expect.throws(
        () => openedFile.positionSync(), (e) => checkFileClosedException(e));
    Expect.throws(() => openedFile.setPositionSync(0),
        (e) => checkFileClosedException(e));
    Expect.throws(
        () => openedFile.truncateSync(0), (e) => checkFileClosedException(e));
    Expect.throws(
        () => openedFile.lengthSync(), (e) => checkFileClosedException(e));
    Expect.throws(
        () => openedFile.flushSync(), (e) => checkFileClosedException(e));

    var errorCount = 0;

    _errorHandler(error) {
      checkFileClosedException(error);
      if (--errorCount == 0) {
        done();
      }
      return openedFile;
    }

    var readByteFuture = openedFile.readByte();
    readByteFuture
        .then((byte) => Expect.fail("Unreachable code"))
        .catchError(_errorHandler);
    errorCount++;
    var writeByteFuture = openedFile.writeByte(0);
    writeByteFuture
        .then((ignore) => Expect.fail("Unreachable code"))
        .catchError(_errorHandler);
    errorCount++;
    var readIntoFuture = openedFile.readInto(data, 0, data.length);
    readIntoFuture
        .then((bytesRead) => Expect.fail("Unreachable code"))
        .catchError(_errorHandler);
    errorCount++;
    var writeFromFuture = openedFile.writeFrom(data, 0, data.length);
    writeFromFuture
        .then((ignore) => Expect.fail("Unreachable code"))
        .catchError(_errorHandler);
    errorCount++;
    var writeStringFuture = openedFile.writeString("Hello");
    writeStringFuture
        .then((ignore) => Expect.fail("Unreachable code"))
        .catchError(_errorHandler);
    errorCount++;
    var positionFuture = openedFile.position();
    positionFuture
        .then((position) => Expect.fail("Unreachable code"))
        .catchError(_errorHandler);
    errorCount++;
    var setPositionFuture = openedFile.setPosition(0);
    setPositionFuture
        .then((ignore) => Expect.fail("Unreachable code"))
        .catchError(_errorHandler);
    errorCount++;
    var truncateFuture = openedFile.truncate(0);
    truncateFuture
        .then((ignore) => Expect.fail("Unreachable code"))
        .catchError(_errorHandler);
    errorCount++;
    var lenFuture = openedFile.length();
    lenFuture
        .then((length) => Expect.fail("Unreachable code"))
        .catchError(_errorHandler);
    errorCount++;
    var flushFuture = openedFile.flush();
    flushFuture
        .then((ignore) => Expect.fail("Unreachable code"))
        .catchError(_errorHandler);
    errorCount++;
  });
}

testRepeatedlyCloseFile() {
  createTestFile((file, done) {
    var openedFile = file.openSync();
    openedFile.close().then((ignore) {
      var closeFuture = openedFile.close();
      closeFuture.then((ignore) => null).catchError((error) {
        Expect.isTrue(error is FileSystemException);
        done();
        return openedFile;
      });
    });
  });
}

testRepeatedlyCloseFileSync() {
  createTestFile((file, done) {
    var openedFile = file.openSync();
    openedFile.closeSync();
    Expect.throws(openedFile.closeSync, (e) => e is FileSystemException);
    done();
  });
}

testReadSyncClosedFile() {
  createTestFile((file, done) {
    var openedFile = file.openSync();
    openedFile.closeSync();
    Expect.throws(
        () => openedFile.readSync(1), (e) => e is FileSystemException);
    done();
  });
}

void testCreateExistingFile() {
  createTestFile((file, done) {
    Expect.throws<PathExistsException>(() => file.createSync(exclusive: true));
    done();
  });
}

void testDeleteDirectoryWithoutPermissions() {
  if (Platform.isMacOS) {
    createTestFile((file, done) async {
      Process.runSync('chflags', ['uchg', file.path]);
      Expect.throws<PathAccessException>(file.deleteSync);
      Process.runSync('chflags', ['nouchg', file.path]);
      done();
    });
  }
  if (Platform.isWindows) {
    final oldCurrent = Directory.current;
    Directory.current = tempDir();
    // Cannot delete the current working directory in Windows.
    Expect.throws<PathAccessException>(Directory.current.deleteSync);
    Directory.current = oldCurrent;
  }
}

main() {
  testOpenBlankFilename();
  testOpenNonExistent();
  testDeleteNonExistent();
  testLengthNonExistent();
  testCreateInNonExistentDirectory();
  testResolveSymbolicLinksOnNonExistentDirectory();
  testReadAsBytesNonExistent();
  testReadAsTextNonExistent();
  testReadAsLinesNonExistent();
  testWriteByteToReadOnlyFile();
  testWriteFromToReadOnlyFile();
  testTruncateReadOnlyFile();
  testOperateOnClosedFile();
  testRepeatedlyCloseFile();
  testRepeatedlyCloseFileSync();
  testReadSyncClosedFile();
  testCreateExistingFile();
  testDeleteDirectoryWithoutPermissions();
}
