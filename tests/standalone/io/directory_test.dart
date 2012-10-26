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
    Expect.isTrue(subDirectory.existsSync());
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

  static void testDeleteSymlink() {
    // temp/
    //   a/
    //     file.txt
    //   b/
    //     a_link -> a
    var d = new Directory("").createTempSync();
    var a = new Directory("${d.path}/a");
    a.createSync();

    var b = new Directory("${d.path}/b");
    b.createSync();

    var f = new File("${d.path}/a/file.txt");
    f.createSync();
    Expect.isTrue(f.existsSync());

    // Create a symlink (or junction on Windows) from
    // temp/b/a_link to temp/a.
    var cmd = "ln";
    var args = ['-s', "${d.path}/b/a_link", "${d.path}/a"];

    if (Platform.operatingSystem == "windows") {
      cmd = "cmd";
      args = ["/c", "mklink", "/j", "${d.path}\\b\\a_link", "${d.path}\\a"];
    }

    Process.run(cmd, args).then((_) {
      // Delete the directory containing the junction.
      b.deleteRecursivelySync();

      // We should not have recursed through a_link into a.
      Expect.isTrue(f.existsSync());

      // Clean up after ourselves.
      d.deleteRecursivelySync();
    });
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
    Directory d2 = new Directory('${d.path}/');
    Expect.isTrue(d.existsSync());
    Expect.isTrue(d2.existsSync());
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
      String filename =
          "${tempDirectory.path}${Platform.pathSeparator}dart_testfile";
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

  static void testFromPath() {
    var name = new File('.').fullPathSync();
    Directory current1 = new Directory(name);
    var path = new Path.fromNative(name);
    Directory current2 = new Directory.fromPath(path);
    Expect.equals(current1.path, current2.path);
    Expect.isTrue(current1.existsSync());
  }

  static void testMain() {
    testListing();
    testListNonExistent();
    testListTooLongName();
    testDeleteNonExistent();
    testDeleteTooLongName();
    testDeleteNonExistentSync();
    testDeleteTooLongNameSync();
    testDeleteSymlink();
    testExistsCreateDelete();
    testExistsCreateDeleteSync();
    testCreateTemp();
    testCreateDeleteTemp();
    testCurrent();
    testFromPath();
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
    if (!createdDirectories.isEmpty) {
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


testCreateExistingSync() {
  // Test that creating an existing directory succeeds.
  var d = new Directory('');
  var temp = d.createTempSync();
  var subDir = new Directory('${temp.path}/flaf');
  Expect.isFalse(subDir.existsSync());
  subDir.createSync();
  Expect.isTrue(subDir.existsSync());
  subDir.createSync();
  Expect.isTrue(subDir.existsSync());
  temp.deleteRecursivelySync();
}


testCreateExisting() {
  // Test that creating an existing directory succeeds.
  var port = new ReceivePort();
  var d = new Directory('');
  d.createTemp().then((temp) {
    var subDir = new Directory('${temp.path}/flaf');
    subDir.exists().then((dirExists) {
      Expect.isFalse(dirExists);
      subDir.create().then((_) {
        subDir.exists().then((dirExists) {
          Expect.isTrue(dirExists);
          subDir.create().then((_) {
            subDir.exists().then((dirExists) {
              Expect.isTrue(dirExists);
              temp.deleteRecursively().then((_) {
                port.close();
              });
            });
          });
        });
      });
    });
  });
}


testCreateDirExistingFileSync() {
  // Test that creating an existing directory succeeds.
  var d = new Directory('');
  var temp = d.createTempSync();
  var path = '${temp.path}/flaf';
  var file = new File(path);
  file.createSync();
  Expect.isTrue(file.existsSync());
  Expect.throws(new Directory(path).createSync,
                (e) => e is DirectoryIOException);
  temp.deleteRecursivelySync();
}


testCreateDirExistingFile() {
  // Test that creating an existing directory succeeds.
  var port = new ReceivePort();
  var d = new Directory('');
  d.createTemp().then((temp) {
    var path = '${temp.path}/flaf';
    var file = new File(path);
    var subDir = new Directory(path);
    file.create().then((_) {
      subDir.create()
        ..then((_) { Expect.fail("dir create should fail on existing file"); })
        ..handleException((e) {
            Expect.isTrue(e is DirectoryIOException);
            temp.deleteRecursively().then((_) {
              port.close();
            });
            return true;
          });
    });
  });
}


testRename() {
  var d = new Directory('');
  var temp1 = d.createTempSync();
  var temp2 = d.createTempSync();
  var temp3 = temp1.renameSync(temp2.path);
  Expect.isFalse(temp1.existsSync());
  Expect.isTrue(temp2.existsSync());
  Expect.equals(temp3.path, temp2.path);

  temp2.rename(temp1.path).then((temp4) {
    Expect.isFalse(temp3.existsSync());
    Expect.isFalse(temp2.existsSync());
    Expect.isTrue(temp1.existsSync());
    Expect.isTrue(temp4.existsSync());
    Expect.equals(temp1.path, temp4.path);
    temp1.deleteRecursivelySync();
  });
}

main() {
  DirectoryTest.testMain();
  NestedTempDirectoryTest.testMain();
  testCreateTempErrorSync();
  testCreateTempError();
  testCreateExistingSync();
  testCreateExisting();
  testCreateDirExistingFileSync();
  testCreateDirExistingFile();
  testRename();
}
