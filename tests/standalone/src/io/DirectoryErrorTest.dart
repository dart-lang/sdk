// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing error handling in directory I/O.

#import("dart:io");
#import("dart:isolate");

Directory tempDir() {
  var d = new Directory('');
  d.createTempSync();
  return d;
}


bool checkCreateInNonExistentFileException(e) {
  Expect.isTrue(e is DirectoryIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Creation failed") != -1);
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


void testCreateInNonExistent(Directory temp, Function done) {
  Directory inNonExistent = new Directory("${temp.path}/nonExistent/xxx");
  Expect.throws(() => inNonExistent.createSync(),
                (e) => checkCreateInNonExistentFileException(e));

  inNonExistent.create(() => Expect.fail("Unreachable code"));
  inNonExistent.onError = (e) {
    checkCreateInNonExistentFileException(e);
    done();
  };
}


bool checkCreateTempInNonExistentFileException(e) {
  Expect.isTrue(e is DirectoryIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf(
      "Creation of temporary directory failed") != -1);
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


void testCreateTempInNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent/xxx");
  Expect.throws(() => nonExistent.createTempSync(),
                (e) => checkCreateTempInNonExistentFileException(e));

  nonExistent.createTemp(() => Expect.fail("Unreachable code"));
  nonExistent.onError = (e) {
    checkCreateTempInNonExistentFileException(e);
    done();
  };
}


bool checkDeleteNonExistentFileException(e) {
  Expect.isTrue(e is DirectoryIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Deletion failed") != -1);
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


void testDeleteNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent");
  Expect.throws(() => nonExistent.deleteSync(),
                (e) => checkDeleteNonExistentFileException(e));

  nonExistent.delete(() => Expect.fail("Unreachable code"));
  nonExistent.onError = (e) {
    checkDeleteNonExistentFileException(e);
    done();
  };
}


bool checkDeleteRecursivelyNonExistentFileException(e) {
  Expect.isTrue(e is DirectoryIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Deletion failed") != -1);
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


void testDeleteRecursivelyNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent");
  Expect.throws(() => nonExistent.deleteRecursivelySync(),
                (e) => checkDeleteRecursivelyNonExistentFileException(e));

  nonExistent.deleteRecursively(() => Expect.fail("Unreachable code"));
  nonExistent.onError = (e) {
    checkDeleteRecursivelyNonExistentFileException(e);
    done();
  };
}


bool checkListNonExistentFileException(e) {
  Expect.isTrue(e is DirectoryIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Directory listing failed") != -1);
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


void testListNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent");
  nonExistent.list();
  nonExistent.onError = (e) {
    checkListNonExistentFileException(e);
    done();
  };
}


void runTest(Function test) {
  // Create a temporary directory for the test.
  var temp = new Directory('');
  temp.createTempSync();

  // Wait for the test to finish and delete the temporary directory.
  ReceivePort p = new ReceivePort();
  p.receive((x,y) {
    p.close();
    temp.deleteRecursivelySync();
  });

  // Run the test.
  test(temp, () => p.toSendPort().send(null));
}


main() {
  runTest(testCreateInNonExistent);
  runTest(testCreateTempInNonExistent);
  runTest(testDeleteNonExistent);
  runTest(testDeleteRecursivelyNonExistent);
  runTest(testListNonExistent);
}
