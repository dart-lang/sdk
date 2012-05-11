// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Directory listing test.

#import("dart:io");
#import("dart:isolate");

class DirectoryTest {
  static void testListing() {
    bool listedDir = false;
    bool listedFile = false;

    Directory directory = new Directory("").createTempSync();
    Directory subDirectory = new Directory("${directory.path}/subdir");
    Expect.isFalse(subDirectory.existsSync());
    subDirectory.createSync();
    File f = new File('${subDirectory.path}/file.txt');
    Expect.isFalse(f.existsSync());
    f.createSync();

    var lister = directory.list(recursive: true);

    lister.onDir = (dir) {
      listedDir = true;
      Expect.isTrue(dir.contains(directory.path));
      Expect.isTrue(dir.contains('subdir'));
    };

    lister.onFile = (f) {
      listedFile = true;
      Expect.isTrue(f.contains(directory.path));
      Expect.isTrue(f.contains('subdir'));
      Expect.isTrue(f.contains('file.txt'));
    };

    lister.onDone = (completed) {
      Expect.isTrue(completed, "directory listing did not complete");
      Expect.isTrue(listedDir, "directory not found");
      Expect.isTrue(listedFile, "file not found");
      directory.deleteRecursively().then((ignore) {
        f.exists().then((exists) => Expect.isFalse(exists));
        directory.exists().then((exists) => Expect.isFalse(exists));
        subDirectory.exists().then((exists) => Expect.isFalse(exists));
      });
    };

    // Listing is asynchronous, so nothing should be listed at this
    // point.
    Expect.isFalse(listedDir);
    Expect.isFalse(listedFile);
  }

  static void testListNonExistent() {
    setupListerHandlers(DirectoryLister lister) {
      // Test that listing a non-existing directory fails.
      lister.onError = (e) {
        Expect.isTrue(e is DirectoryIOException);
      };
      lister.onFile = (file) {
        Expect.fail("Listing of non-existing directory should fail");
      };
      lister.onDir = (dir) {
        Expect.fail("Listing of non-existing directory should fail");
      };
      lister.onDone = (success) {
        Expect.isFalse(success);
      };
    }
    new Directory("").createTemp().then((d) {
      d.delete().then((ignore) {
        setupListerHandlers(d.list());
        setupListerHandlers(d.list(recursive: true));
      });
    });
  }

  static void testListTooLongName() {
    new Directory("").createTemp().then((d) {
      var errors = 0;
      setupListHandlers(DirectoryLister lister) {
        lister.onError = (e) {
          Expect.isTrue(e is DirectoryIOException);
          if (++errors == 2) {
            d.deleteRecursively();
          }
        };
        lister.onFile = (file) {
          Expect.fail("Listing of non-existing directory should fail");
        };
        lister.onDir = (dir) {
          Expect.fail("Listing of non-existing directory should fail");
        };
        lister.onDone = (success) {
          Expect.isFalse(success);
        };
      }
      var subDirName = 'subdir';
      var subDir = new Directory("${d.path}/$subDirName");
      subDir.create().then((ignore) {
        // Construct a long string of the form
        // 'tempdir/subdir/../subdir/../subdir'.
        var buffer = new StringBuffer();
        buffer.add(subDir.path);
        for (var i = 0; i < 1000; i++) {
          buffer.add("/../${subDirName}");
        }
        var long = new Directory("${buffer.toString()}");
        setupListHandlers(long.list());
        setupListHandlers(long.list(recursive: true));
      });
    });
  }

  static void testDeleteNonExistent() {
    // Test that deleting a non-existing directory fails.
    setupFutureHandlers(future) {
      future.handleException((e) {
        Expect.isTrue(e is DirectoryIOException);
        return true;
      });
      future.then((ignore) {
        Expect.fail("Deletion of non-existing directory should fail");
      });
    }

    new Directory("").createTemp().then((d) {
      d.delete().then((ignore) {
        setupFutureHandlers(d.delete());
        setupFutureHandlers(d.deleteRecursively());
      });
    });
  }

  static void testDeleteTooLongName() {
    var port = new ReceivePort();
    new Directory("").createTemp().then((d) {
      var subDirName = 'subdir';
      var subDir = new Directory("${d.path}/$subDirName");
      subDir.create().then((ignore) {
          // Construct a long string of the form
          // 'tempdir/subdir/../subdir/../subdir'.
          var buffer = new StringBuffer();
          buffer.add(subDir.path);
          for (var i = 0; i < 1000; i++) {
            buffer.add("/../${subDirName}");
          }
          var long = new Directory("${buffer.toString()}");
          var errors = 0;
          onError(e) {
            Expect.isTrue(e is DirectoryIOException);
            if (++errors == 2) {
              d.deleteRecursively().then((ignore) => port.close());
            }
            return true;
          }
          long.delete().handleException(onError);
          long.deleteRecursively().handleException(onError);
        });
    });
  }

  static void testDeleteNonExistentSync() {
    Directory d = new Directory("").createTempSync();
    d.deleteSync();
    Expect.throws(d.deleteSync);
    Expect.throws(() => d.deleteRecursivelySync());
  }

  static void testDeleteTooLongNameSync() {
    Directory d = new Directory("").createTempSync();
    var subDirName = 'subdir';
    var subDir = new Directory("${d.path}/$subDirName");
    subDir.createSync();
    // Construct a long string of the form
    // 'tempdir/subdir/../subdir/../subdir'.
    var buffer = new StringBuffer();
    buffer.add(subDir.path);
    for (var i = 0; i < 1000; i++) {
      buffer.add("/../${subDirName}");
    }
    var long = new Directory("${buffer.toString()}");
    Expect.throws(long.deleteSync);
    Expect.throws(() => long.deleteRecursivelySync());
    d.deleteRecursivelySync();
  }

  static void testExistsCreateDelete() {
    new Directory("").createTemp().then((d) {
      d.exists().then((bool exists) {
        Expect.isTrue(exists);
        Directory created = new Directory("${d.path}/subdir");
        created.create().then((ignore) {
          created.exists().then((bool exists) {
            Expect.isTrue(exists);
            created.delete().then((ignore) {
              created.exists().then((bool exists) {
                Expect.isFalse(exists);
                d.delete().then((ignore) {
                  d.exists().then((bool exists) {
                    Expect.isFalse(exists);
                  });
                });
              });
            });
          });
        });
      });
    });
  }

  static void testExistsCreateDeleteSync() {
    Directory d = new Directory("").createTempSync();
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
    Directory tempDir1;
    Directory tempDir2;
    bool stage1aDone = false;
    bool stage1bDone = false;
    bool emptyTemplateTestRunning = false;

    // Stages 0 through 2 run twice, the second time with an empty path.
    Function stage0;
    Function stage1a;
    Function stage1b;
    Function stage2;
    Function stage3;  // Loops to stage 0.

    stage0 = () {
      var dir = new Directory("/tmp/dart_temp_dir_");
      dir.createTemp().then(stage1a);
      dir.createTemp().then(stage1b);
    };

    stage1a = (temp) {
      tempDir1 = temp;
      stage1aDone = true;
      Expect.isTrue(tempDir1.existsSync());
      if (stage1bDone) {
        stage2();
      }
    };

    stage1b = (temp) {
      tempDir2 = temp;
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
    new Directory("").createTemp().then((tempDirectory) {
      String filename = tempDirectory.path +
          Platform.pathSeparator + "dart_testfile";
      File file = new File(filename);
      Expect.isFalse(file.existsSync());
      file.create().then((ignore) {
        file.exists().then((exists) {
          Expect.isTrue(exists);
          // Try to delete the directory containing the file - should throw.
          Expect.throws(tempDirectory.deleteSync);
          Expect.isTrue(tempDirectory.existsSync());

          // Delete the file, and then delete the directory.
          file.delete().then((ignore) {
            tempDirectory.deleteSync();
            Expect.isFalse(tempDirectory.existsSync());
          });
        });
      });
    });
  }

  static void testCurrent() {
    Directory current = new Directory.current();
    if (Platform.operatingSystem != "windows") {
      Expect.equals("/", current.path.substring(0, 1));
    }
  }

  static void testMain() {
    testListing();
    testListNonExistent();
    testListTooLongName();
    testDeleteNonExistent();
    testDeleteTooLongName();
    testDeleteNonExistentSync();
    testDeleteTooLongNameSync();
    testExistsCreateDelete();
    testExistsCreateDeleteSync();
    testCreateTemp();
    testCreateDeleteTemp();
    testCurrent();
  }
}


class NestedTempDirectoryTest {
  List<Directory> createdDirectories;
  Directory current;

  NestedTempDirectoryTest.run()
      : createdDirectories = new List<Directory>() {
    new Directory("").createTemp().then(createPhaseCallback);
  }

  void createPhaseCallback(temp) {
    createdDirectories.add(temp);
    int nestingDepth = 6;
    var os = Platform.operatingSystem;
    if (os == "windows") nestingDepth = 2;
    if (createdDirectories.length < nestingDepth) {
      temp = new Directory(
          '${temp.path}/nested_temp_dir_${createdDirectories.length}_');
      temp.createTemp().then(createPhaseCallback);
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
  var os = Platform.operatingSystem;
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
                  (e) => e is DirectoryIOException);
  }
}


testCreateTempError() {
  var location = illegalTempDirectoryLocation();
  if (location == null) return;

  var port = new ReceivePort();
  var future = new Directory(location).createTemp();
  future.handleException((e) => port.close());
}


main() {
  DirectoryTest.testMain();
  NestedTempDirectoryTest.testMain();
  testCreateTempErrorSync();
  testCreateTempError();
}
