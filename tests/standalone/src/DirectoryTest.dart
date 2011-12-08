// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Directory listing test.

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
      print(dir);
      listedDir = true;
      Expect.isTrue(dir.contains('subdir'));
    };

    directory.fileHandler = (f) {
      print(f);
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
    Directory d = new Directory("/tmp/dart_temp_dir_");
    d.createTempSync();
    Expect.isTrue(d.existsSync());
    Directory created = new Directory("${d.path}/subdir");
    created.createSync();
    Expect.isTrue(created.existsSync());
    created.deleteSync();
    Expect.isFalse(created.existsSync());
    d.deleteSync();
    Expect.isFalse(d.existsSync());

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

  static void testCreateTemp() {
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
        file.open(writable: true);
      };
      file.openHandler = () {
        file.writeList([65, 66, 67, 13], 0, 4);
      };
      file.noPendingWriteHandler = () {
        file.length();
      };
      file.lengthHandler = (int length) {
        Expect.equals(4, length);
        file.close();
      };
      file.closeHandler = () {
        file.exists();
      };
      file.existsHandler = (bool exists) {
        Expect.isTrue(exists);
        // Try to delete the directory containing the file - should throw.
        bool threw_exception = false;
        try {
          tempDirectory.deleteSync();
        } catch (var e) {
          Expect.isTrue(tempDirectory.existsSync());
          threw_exception = true;
        }
        Expect.isTrue(threw_exception);
        Expect.isTrue(tempDirectory.existsSync());

        // Delete the file, and then delete the directory.
        file.delete();
      };
      file.deleteHandler = () {
        tempDirectory.deleteSync();
        Expect.isFalse(tempDirectory.existsSync());
      };

      file.create();
    };
    tempDirectory.createTemp();
  }

  static void testNestedTempDirectory() {
    var test = new NestedTempDirectoryTest();
  }


  static void testMain() {
    testListing();
    testExistsCreateDelete();
    testCreateTemp();
    testNestedTempDirectory();
  }
}


class NestedTempDirectoryTest {
  List<Directory> createdDirectories;
  static final int nestingDepth = 6;
  Directory current;

  NestedTempDirectoryTest(): createdDirectories = new List<Directory>();

  void errorCallback(error) {
    Expect.fail("Error callback called in NestedTempDirectoryTest: $error");
  }

  void createPhaseCallback() {
    createdDirectories.add(current);
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

  void startTest() {
    current = new Directory("");
    current.createTempHandler = createPhaseCallback;
    current.errorHandler = errorCallback;
    current.createTemp();
  }

  static void testMain() {
    new NestedTempDirectoryTest().startTest();
    new NestedTempDirectoryTest().startTest();
 }
}


main() {
  DirectoryTest.testMain();
  NestedTempDirectoryTest.testMain();
}
