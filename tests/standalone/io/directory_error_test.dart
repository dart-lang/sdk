// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing error handling in directory I/O.

#import("dart:io");
#import("dart:isolate");

Directory tempDir() {
  return new Directory('').createTempSync();
}


bool checkCreateInNonExistentFileException(e) {
  Expect.isTrue(e is DirectoryIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Creation failed") != -1);
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


void testCreateInNonExistent(Directory temp, Function done) {
  Directory inNonExistent = new Directory("${temp.path}/nonExistent/xxx");
  Expect.throws(() => inNonExistent.createSync(),
                (e) => checkCreateInNonExistentFileException(e));

  inNonExistent.create().handleException((e) {
    checkCreateInNonExistentFileException(e);
    done();
    return true;
  });
}


bool checkCreateTempInNonExistentFileException(e) {
  Expect.isTrue(e is DirectoryIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf(
      "Creation of temporary directory failed") != -1);
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


void testCreateTempInNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent/xxx");
  Expect.throws(() => nonExistent.createTempSync(),
                (e) => checkCreateTempInNonExistentFileException(e));

  nonExistent.createTemp().handleException((e) {
    checkCreateTempInNonExistentFileException(e);
    done();
    return true;
  });
}


bool checkDeleteNonExistentFileException(e) {
  Expect.isTrue(e is DirectoryIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Deletion failed") != -1);
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


void testDeleteNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent");
  Expect.throws(() => nonExistent.deleteSync(),
                (e) => checkDeleteNonExistentFileException(e));

  nonExistent.delete().handleException((e) {
    checkDeleteNonExistentFileException(e);
    done();
    return true;
  });
}


bool checkDeleteRecursivelyNonExistentFileException(e) {
  Expect.isTrue(e is DirectoryIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Deletion failed") != -1);
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


void testDeleteRecursivelyNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent");
  Expect.throws(() => nonExistent.deleteRecursivelySync(),
                (e) => checkDeleteRecursivelyNonExistentFileException(e));

  nonExistent.deleteRecursively().handleException((e) {
    checkDeleteRecursivelyNonExistentFileException(e);
    done();
    return true;
  });
}


bool checkListNonExistentFileException(e) {
  Expect.isTrue(e is DirectoryIOException);
  Expect.isTrue(e.osError != null);
  Expect.isTrue(e.toString().indexOf("Directory listing failed") != -1);
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


void testListNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent");
  var lister = nonExistent.list();
  lister.onError = (e) {
    checkListNonExistentFileException(e);
    done();
  };
}


void testRenameNonExistent(Directory temp, Function done) {
  Directory nonExistent = new Directory("${temp.path}/nonExistent");
  var newPath = "${temp.path}/nonExistent2";
  Expect.throws(() => nonExistent.renameSync(newPath),
                (e) => e is DirectoryIOException);
  var renameDone = nonExistent.rename(newPath);
  renameDone.then((ignore) => Expect.fail('rename non existent'));
  renameDone.handleException((e) {
    Expect.isTrue(e is DirectoryIOException);
    done();
    return true;
  });
}


void testRenameFileAsDirectory(Directory temp, Function done) {
  File f = new File("${temp.path}/file");
  var newPath = "${temp.path}/file2";
  f.createSync();
  var d = new Directory(f.name);
  Expect.throws(() => d.renameSync(newPath),
                (e) => e is DirectoryIOException);
  var renameDone = d.rename(newPath);
  renameDone.then((ignore) => Expect.fail('rename file as directory'));
  renameDone.handleException((e) {
    Expect.isTrue(e is DirectoryIOException);
    done();
    return true;
  });
}


testRenameOverwriteFile(Directory temp, Function done) {
  var d = new Directory('');
  var temp1 = d.createTempSync();
  var fileName = '${temp.path}/x';
  new File(fileName).createSync();
  Expect.throws(() => temp1.renameSync(fileName),
                (e) => e is DirectoryIOException);
  var renameDone = temp1.rename(fileName);
  renameDone.then((ignore) => Expect.fail('rename dir overwrite file'));
  renameDone.handleException((e) {
    Expect.isTrue(e is DirectoryIOException);
    temp1.deleteRecursivelySync();
    done();
    return true;
  });
}


void runTest(Function test) {
  // Create a temporary directory for the test.
  var temp = new Directory('').createTempSync();

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
  runTest(testRenameNonExistent);
  runTest(testRenameFileAsDirectory);
  runTest(testRenameOverwriteFile);
}
