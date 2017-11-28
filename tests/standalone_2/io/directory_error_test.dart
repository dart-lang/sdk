// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing error handling in directory I/O.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

Directory tempDir() {
  return Directory.systemTemp.createTempSync('dart_directory_error');
}

bool checkCreateInNonExistentFileSystemException(e) {
  Expect.isTrue(e is FileSystemException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Creation failed") != -1);
  if (Platform.operatingSystem == "linux") {
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "macos") {
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "windows") {
    Expect.equals(3, e.osError.errorCode);
  }

  return true;
}

void testCreateInNonExistent(Directory temp, Function done) {
  Directory inNonExistent = new Directory("${temp.path}/nonExistent/xxx");
  Expect.throws(() => inNonExistent.createSync(),
      (e) => checkCreateInNonExistentFileSystemException(e));

  inNonExistent.create().catchError((error) {
    checkCreateInNonExistentFileSystemException(error);
    done();
  });
}

bool checkCreateTempInNonExistentFileSystemException(e) {
  Expect.isTrue(e is FileSystemException);
  Expect.isTrue(e.osError != null);
  if (Platform.operatingSystem == "linux") {
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "macos") {
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "windows") {
    Expect.equals(3, e.osError.errorCode);
  }

  return true;
}

void testCreateTempInNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent/xxx");
  Expect.throws(() => nonExistent.createTempSync('tempdir'),
      (e) => checkCreateTempInNonExistentFileSystemException(e));

  nonExistent.createTemp('tempdir').catchError((error) {
    checkCreateTempInNonExistentFileSystemException(error);
    done();
  });
}

bool checkDeleteNonExistentFileSystemException(e) {
  Expect.isTrue(e is FileSystemException);
  Expect.isTrue(e.osError != null);
  // File not not found has error code 2 on all supported platforms.
  Expect.equals(2, e.osError.errorCode);

  return true;
}

void testDeleteNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent");
  Expect.throws(() => nonExistent.deleteSync(),
      (e) => checkDeleteNonExistentFileSystemException(e));

  nonExistent.delete().catchError((error) {
    checkDeleteNonExistentFileSystemException(error);
    done();
  });
}

bool checkDeleteRecursivelyNonExistentFileSystemException(e) {
  Expect.isTrue(e is FileSystemException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Deletion failed") != -1);
  // File not not found has error code 2 on all supported platforms.
  Expect.equals(2, e.osError.errorCode);

  return true;
}

void testDeleteRecursivelyNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent");
  Expect.throws(() => nonExistent.deleteSync(recursive: true),
      (e) => checkDeleteRecursivelyNonExistentFileSystemException(e));

  nonExistent.delete(recursive: true).catchError((error) {
    checkDeleteRecursivelyNonExistentFileSystemException(error);
    done();
  });
}

bool checkListNonExistentFileSystemException(e) {
  Expect.isTrue(e is FileSystemException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Directory listing failed") != -1);
  if (Platform.operatingSystem == "linux") {
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "macos") {
    Expect.equals(2, e.osError.errorCode);
  } else if (Platform.operatingSystem == "windows") {
    Expect.equals(3, e.osError.errorCode);
  }

  return true;
}

bool checkAsyncListNonExistentFileSystemException(error) {
  return checkListNonExistentFileSystemException(error);
}

void testListNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent");
  Expect.throws(() => nonExistent.listSync(), (e) => e is FileSystemException);
  nonExistent.list().listen((_) => Expect.fail("listing should not succeed"),
      onError: (e) {
    checkAsyncListNonExistentFileSystemException(e);
    done();
  });
}

void testRenameNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent");
  var newPath = "${temp.path}/nonExistent2";
  Expect.throws(
      () => nonExistent.renameSync(newPath), (e) => e is FileSystemException);
  var renameDone = nonExistent.rename(newPath);
  renameDone
      .then((ignore) => Expect.fail('rename non existent'))
      .catchError((error) {
    Expect.isTrue(error is FileSystemException);
    done();
  });
}

void testRenameFileAsDirectory(Directory temp, Function done) {
  File f = new File("${temp.path}/file");
  var newPath = "${temp.path}/file2";
  f.createSync();
  var d = new Directory(f.path);
  Expect.throws(() => d.renameSync(newPath), (e) => e is FileSystemException);
  var renameDone = d.rename(newPath);
  renameDone
      .then((ignore) => Expect.fail('rename file as directory'))
      .catchError((error) {
    Expect.isTrue(error is FileSystemException);
    done();
  });
}

testRenameOverwriteFile(Directory temp, Function done) {
  var temp1 = Directory.systemTemp.createTempSync('dart_directory_error');
  var fileName = '${temp.path}/x';
  new File(fileName).createSync();
  Expect.throws(
      () => temp1.renameSync(fileName), (e) => e is FileSystemException);
  var renameDone = temp1.rename(fileName);
  renameDone
      .then((ignore) => Expect.fail('rename dir overwrite file'))
      .catchError((error) {
    Expect.isTrue(error is FileSystemException);
    temp1.deleteSync(recursive: true);
    done();
  });
}

void runTest(Function test) {
  // Create a temporary directory for the test.
  var temp = Directory.systemTemp.createTempSync('dart_directory_error');

  // Wait for the test to finish and delete the temporary directory.
  asyncStart();

  // Run the test.
  test(temp, () {
    temp.deleteSync(recursive: true);
    asyncEnd();
  });
}

main() {
  runTest(testCreateInNonExistent);
  runTest(testCreateTempInNonExistent);
  runTest(testDeleteNonExistent);
  runTest(testDeleteRecursivelyNonExistent);
  runTest(testListNonExistent);
  runTest(testRenameNonExistent);
  runTest(testRenameFileAsDirectory);
  runTest(testRenameOverwriteFile);
}
