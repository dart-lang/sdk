// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing error handling in file I/O.

#import("dart:io");
#import("dart:isolate");

String tempDir() {
  var d = new Directory('');
  d.createTempSync();
  return d.path;
}


bool checkOpenNonExistentFileException(e) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Cannot open file") != -1);
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

void testOpenNonExistent() {
  var file = new File("${tempDir()}/nonExistentFile");

  // Non-existing file should throw exception.
  Expect.throws(() => file.openSync(),
                (e) => checkOpenNonExistentFileException(e));

  file.open(FileMode.READ, (raf) => Expect.fail("Unreachable code"));
  file.onError = (e) => checkOpenNonExistentFileException(e);
}

bool checkDeleteNonExistentFileException(e) {
  Expect.isTrue(e is FileIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Cannot delete file") != -1);
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

void testDeleteNonExistent() {
  var file = new File("${tempDir()}/nonExistentFile");

  // Non-existing file should throw exception.
  Expect.throws(() => file.deleteSync(),
                (e) => checkDeleteNonExistentFileException(e));

  file.delete(() => Expect.fail("Unreachable code"));
  file.onError = (e) => checkDeleteNonExistentFileException(e);
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
  var file = new File("${tempDir()}/nonExistentDirectory/newFile");

  // Create in non-existent directory should throw exception.
  Expect.throws(() => file.createSync(),
                (e) => checkCreateInNonExistentDirectoryException(e));

  file.create(() => Expect.fail("Unreachable code"));
  file.onError = (e) => checkCreateInNonExistentDirectoryException(e);
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
  var file = new File("${tempDir()}/nonExistentDirectory");

  // Full path non-existent directory should throw exception.
  Expect.throws(() => file.fullPathSync(),
                (e) => checkFullPathOnNonExistentDirectoryException(e));

  file.fullPath((path) => Expect.fail("Unreachable code $path"));
  file.onError = (e) => checkFullPathOnNonExistentDirectoryException(e);
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
  var file = new File("${tempDir()}/nonExistentDirectory/newFile");

  // Create in non-existent directory should throw exception.
  Expect.throws(() => file.directorySync(),
                (e) => checkDirectoryInNonExistentDirectoryException(e));

  file.directory((directory) => Expect.fail("Unreachable code"));
  file.onError = (e) => checkDirectoryInNonExistentDirectoryException(e);
}

void testReadAsBytesNonExistent() {
  var file = new File("${tempDir()}/nonExistentFile3");

  // Non-existing file should throw exception.
  Expect.throws(() => file.readAsBytesSync(),
                (e) => checkOpenNonExistentFileException(e));

  // TODO(sgjesse): Handle error for file.readAsBytes as well.
}

void testReadAsTextNonExistent() {
  var file = new File("${tempDir()}/nonExistentFile4");

  // Non-existing file should throw exception.
  Expect.throws(() => file.readAsTextSync(),
                (e) => checkOpenNonExistentFileException(e));

  // TODO(sgjesse): Handle error for file.readAsText as well.
}

void testReadAsLinesNonExistent() {
  var file = new File("${tempDir()}/nonExistentFile5");

  // Non-existing file should throw exception.
  Expect.throws(() => file.readAsLinesSync(),
                (e) => checkOpenNonExistentFileException(e));

  // TODO(sgjesse): Handle error for file.readAsLines as well.
}

main() {
  testOpenNonExistent();
  testDeleteNonExistent();
  testCreateInNonExistentDirectory();
  testFullPathOnNonExistentDirectory();
  testDirectoryInNonExistentDirectory();
  testReadAsBytesNonExistent();
  testReadAsTextNonExistent();
  testReadAsLinesNonExistent();
}
