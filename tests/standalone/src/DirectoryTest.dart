// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Directory listing test.

#import("dart:io");

class DirectoryTest {
  static void testListing() {
    bool listedDir = false;
    bool listedFile = false;

    Directory directory = new Directory("");
    directory.createTempSync();
    Directory subDirectory = new Directory("${directory.path}/subdir");
    Expect.isFalse(subDirectory.existsSync());
    subDirectory.createSync();
    File f = new File('${subDirectory.path}/file.txt');
    Expect.isFalse(f.existsSync());
    f.createSync();

    directory.dirHandler = (dir) {
      listedDir = true;
      Expect.isTrue(dir.contains('subdir'));
    };

    directory.fileHandler = (f) {
      listedFile = true;
      Expect.isTrue(f.contains('subdir'));
      Expect.isTrue(f.contains('file.txt'));
    };

    directory.doneHandler = (completed) {
      Expect.isTrue(completed, "directory listing did not complete");
      Expect.isTrue(listedDir, "directory not found");
      Expect.isTrue(listedFile, "file not found");
      f.deleteHandler = () {
        // TODO(ager): use async directory deletion API when available.
        subDirectory.deleteSync();
        directory.deleteSync();
      };
      f.delete();
    };

    directory.errorHandler = (error) {
      Expect.fail("error listing directory: $error");
    };

    directory.list(recursive: true);

    // Listing is asynchronous, so nothing should be listed at this
    // point.
    Expect.isFalse(listedDir);
    Expect.isFalse(listedFile);
  }

  static void testExistsCreateDelete() {
    Directory d = new Directory("");
    d.createTempHandler = () {
      d.existsHandler = (bool exists) {
        Expect.isTrue(exists);
        Directory created = new Directory("${d.path}/subdir");
        created.createHandler = () {
          created.existsHandler = (bool exists) {
            Expect.isTrue(exists);
            created.deleteHandler = () {
              created.existsHandler = (bool exists) {
                Expect.isFalse(exists);
                d.deleteHandler = () {
                  d.existsHandler = (bool exists) {
                    Expect.isFalse(exists);
                  };
                  d.exists();
                };
                d.delete();
              };
              created.exists();
            };
            created.delete();
          };
          created.exists();
        };
        created.create();
      };
      d.exists();
    };
    d.createTemp();
  }

  static void testExistsCreateDeleteSync() {
    Directory d = new Directory("");
    d.createTempSync();
    Expect.isTrue(d.existsSync());
    Directory created = new Directory("${d.path}/subdir");
    created.createSync();
    Expect.isTrue(created.existsSync());
    created.deleteSync();
    Expect.isFalse(created.existsSync());
    d.deleteSync();
    Expect.isFalse(d.existsSync());
  }

  static void testCreateTemp() {
    Directory tempDir1 = new Directory("/tmp/dart_temp_dir_");
    Directory tempDir2 = new Directory("/tmp/dart_temp_dir_");
    bool stage1aDone = false;
    bool stage1bDone = false;
    bool emptyTemplateTestRunning = false;

    // Stages 0 through 2 run twice, the second time with an empty path.
    Function stage0;
    Function stage1a;
    Function stage1b;
    Function stage2;
    Function stage3;  // Loops to stage 0.

    Function error(String message) {
      Expect.fail("Directory errorHandler: $message");
    }

    stage0 = () {
      tempDir1.createTempHandler = stage1a;
      tempDir1.errorHandler = error;
      tempDir1.createTemp();
      tempDir2.createTempHandler = stage1b;
      tempDir2.errorHandler = error;
      tempDir2.createTemp();
    };

    stage1a = () {
      stage1aDone = true;
      Expect.isTrue(tempDir1.existsSync());
      if (stage1bDone) {
        stage2();
      }
    };

    stage1b = () {
      stage1bDone = true;
      Expect.isTrue(tempDir2.existsSync());
      if (stage1aDone) {
        stage2();
      }
    };

    stage2 = () {
      Expect.notEquals(tempDir1.path, tempDir2.path);
      tempDir1.deleteSync();
      tempDir2.deleteSync();
      Expect.isFalse(tempDir1.existsSync());
      Expect.isFalse(tempDir2.existsSync());
      if (!emptyTemplateTestRunning) {
        emptyTemplateTestRunning = true;
        stage3();
      } else {
        // Done with test.
      }
    };

    stage3 = () {
      tempDir1 = new Directory("");
      tempDir2 = new Directory("");
      stage1aDone = false;
      stage1bDone = false;
      stage0();
    };

    if (new Directory("/tmp").existsSync()) {
      stage0();
    } else {
      emptyTemplateTestRunning = true;
      stage3();
    }
  }

  static void testCreateDeleteTemp() {
    Directory tempDirectory = new Directory("");
    tempDirectory.createTempHandler = () {
      String filename = tempDirectory.path +
          new Platform().pathSeparator() + "dart_testfile";
      File file = new File(filename);
      Expect.isFalse(file.existsSync());
      file.errorHandler = (error) {
        Expect.fail("testCreateTemp file.errorHandler called: $error");
      };
      file.createHandler = () {
        file.existsHandler = (bool exists) {
          Expect.isTrue(exists);
          // Try to delete the directory containing the file - should throw.
          Expect.throws(tempDirectory.deleteSync);
          Expect.isTrue(tempDirectory.existsSync());

          // Delete the file, and then delete the directory.
          file.deleteHandler = () {
            tempDirectory.deleteSync();
            Expect.isFalse(tempDirectory.existsSync());
          };
          file.delete();
        };
        file.exists();
      };
      file.create();
    };
    tempDirectory.createTemp();
  }

  static void testMain() {
    testListing();
    testExistsCreateDelete();
    testExistsCreateDeleteSync();
    testCreateTemp();
    testCreateDeleteTemp();
  }
}


class NestedTempDirectoryTest {
  List<Directory> createdDirectories;
  Directory current;

  NestedTempDirectoryTest.run()
      : createdDirectories = new List<Directory>(),
        current = new Directory("") {
    current.createTempHandler = createPhaseCallback;
    current.errorHandler = errorCallback;
    current.createTemp();
  }

  void errorCallback(error) {
    Expect.fail("Error callback called in NestedTempDirectoryTest: $error");
  }

  void createPhaseCallback() {
    createdDirectories.add(current);
    int nestingDepth = 6;
    var os = new Platform().operatingSystem();
    if (os == "windows") nestingDepth = 2;
    if (createdDirectories.length < nestingDepth) {
      current = new Directory(
          current.path + "/nested_temp_dir_${createdDirectories.length}_");
      current.errorHandler = errorCallback;
      current.createTempHandler = createPhaseCallback;
      current.createTemp();
    } else {
      deletePhaseCallback();
    }
  }

  void deletePhaseCallback() {
    if (!createdDirectories.isEmpty()) {
      current = createdDirectories.removeLast();
      current.deleteSync();
      deletePhaseCallback();
    }
  }

  static void testMain() {
    new NestedTempDirectoryTest.run();
    new NestedTempDirectoryTest.run();
  }
}


String illegalTempDirectoryLocation() {
  // Determine a platform specific illegal location for a temporary directory.
  var os = new Platform().operatingSystem();
  if (os == "linux" || os == "macos") {
    return "/dev/zero/";
  }
  if (os == "windows") {
    return "*";
  }
  return null;
}


testCreateTempErrorSync() {
  var location = illegalTempDirectoryLocation();
  if (location != null) {
    Expect.throws(new Directory(location).createTempSync,
                  (e) => e is DirectoryException);
  }
}


testCreateTempError() {
  var location = illegalTempDirectoryLocation();
  if (location == null) return;

  var resultPort = new ReceivePort.singleShot();
  resultPort.receive((String message, ignored) {
      Expect.equals("error", message);
    });

  Directory dir = new Directory(location);
  dir.errorHandler = (error) { resultPort.toSendPort().send("error"); };
  dir.createTempHandler = () { resultPort.toSendPort().send("success"); };
  dir.createTemp();
}


main() {
  DirectoryTest.testMain();
  NestedTempDirectoryTest.testMain();
  testCreateTempErrorSync();
  testCreateTempError();
}
