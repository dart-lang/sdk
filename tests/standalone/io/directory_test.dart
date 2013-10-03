// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Directory listing test.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

class DirectoryTest {
  static void testListing() {
    bool listedDir = false;
    bool listedFile = false;

    Directory directory = new Directory("").createTempSync();
    Directory subDirectory = new Directory("${directory.path}/subdir");
    Expect.isTrue('$directory'.contains(directory.path));
    Expect.isFalse(subDirectory.existsSync());
    subDirectory.createSync();
    Expect.isTrue(subDirectory.existsSync());
    File f = new File('${subDirectory.path}/file.txt');
    File fLong = new File('${directory.path}/subdir/../subdir/file.txt');
    Expect.isFalse(f.existsSync());
    f.createSync();

    void testSyncListing(bool recursive) {
      for (var entry in directory.listSync(recursive: recursive)) {
        if (entry is File) {
          Expect.isTrue(entry.path.contains(directory.path));
          Expect.isTrue(entry.path.contains('subdir'));
          Expect.isTrue(entry.path.contains('file.txt'));
          Expect.isFalse(listedFile);
          listedFile = true;
        } else {
          Expect.isTrue(entry is Directory);
          Expect.isTrue(entry.path.contains(directory.path));
          Expect.isTrue(entry.path.contains('subdir'));
          Expect.isFalse(listedDir);
          listedDir = true;
        }
      }
      Expect.equals(listedFile, recursive);
      Expect.isTrue(listedDir);
      listedFile = false;
      listedDir = false;
    }

    testSyncListing(true);
    testSyncListing(false);
    Expect.equals(f.fullPathSync(), fLong.fullPathSync());

    asyncStart();
    directory.list(recursive: true).listen(
        (FileSystemEntity entity) {
          if (entity is File) {
            var path = entity.path;
            listedFile = true;
            Expect.isTrue(path.contains(directory.path));
            Expect.isTrue(path.contains('subdir'));
            Expect.isTrue(path.contains('file.txt'));
          } else {
            var path = entity.path;
            Expect.isTrue(entity is Directory);
            listedDir = true;
            Expect.isTrue(path.contains(directory.path));
            Expect.isTrue(path.contains('subdir'));
          }
        },
        onDone: () {
          Expect.isTrue(listedDir, "directory not found");
          Expect.isTrue(listedFile, "file not found");
          directory.delete(recursive: true).then((ignore) {
            f.exists().then((exists) => Expect.isFalse(exists));
            directory.exists().then((exists) => Expect.isFalse(exists));
            subDirectory.exists().then((exists) => Expect.isFalse(exists));
            asyncEnd();
          });
        });

    // Listing is asynchronous, so nothing should be listed at this
    // point.
    Expect.isFalse(listedDir);
    Expect.isFalse(listedFile);
  }

  static void testListingTailingPaths() {
    Directory directory = new Directory("").createTempSync();
    Directory subDirectory = new Directory("${directory.path}/subdir/");
    subDirectory.createSync();
    File f = new File('${subDirectory.path}/file.txt');
    f.createSync();

    void test(entry) {
      Expect.isFalse(entry.path.contains(new RegExp('[\\/][\\/]')));
    }

    subDirectory.listSync().forEach(test);

    subDirectory.list().listen(test, onDone: () {
      directory.deleteSync(recursive: true);
    });
  }

  static void testListNonExistent() {
    setupListerHandlers(Stream<FileSystemEntity> stream) {
      stream.listen(
          (_) => Expect.fail("Listing of non-existing directory should fail"),
          onError: (error) {
            Expect.isTrue(error is DirectoryException);
          });
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
      asyncStart();
      setupListHandlers(Stream<FileSystemEntity> stream) {
        stream.listen(
          (_) => Expect.fail("Listing of non-existing directory should fail"),
          onError: (error) {
            Expect.isTrue(error is DirectoryException);
            if (++errors == 2) {
              d.delete(recursive: true).then((_) {
                asyncEnd();
              });
            }
          });
      }
      var subDirName = 'subdir';
      var subDir = new Directory("${d.path}/$subDirName");
      subDir.create().then((ignore) {
        // Construct a long string of the form
        // 'tempdir/subdir/../subdir/../subdir'.
        var buffer = new StringBuffer();
        buffer.write(subDir.path);
        for (var i = 0; i < 1000; i++) {
          buffer.write("/../${subDirName}");
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
      future.then((ignore) {
        Expect.fail("Deletion of non-existing directory should fail");
      }).catchError((error) {
        Expect.isTrue(error is DirectoryException);
      });
    }

    new Directory("").createTemp().then((d) {
      d.delete().then((ignore) {
        setupFutureHandlers(d.delete());
        setupFutureHandlers(d.delete(recursive: true));
      });
    });
  }

  static void testDeleteTooLongName() {
    asyncStart();
    new Directory("").createTemp().then((d) {
      var subDirName = 'subdir';
      var subDir = new Directory("${d.path}/$subDirName");
      subDir.create().then((ignore) {
          // Construct a long string of the form
          // 'tempdir/subdir/../subdir/../subdir'.
          var buffer = new StringBuffer();
          buffer.write(subDir.path);
          for (var i = 0; i < 1000; i++) {
            buffer.write("/../${subDirName}");
          }
          var long = new Directory("${buffer.toString()}");
          var errors = 0;
          onError(error) {
            Expect.isTrue(error is DirectoryException);
            if (++errors == 2) {
              d.delete(recursive: true).then((_) => asyncEnd());
            }
            return true;
          }
          long.delete().catchError(onError);
          long.delete(recursive: true).catchError(onError);
        });
    });
  }

  static void testDeleteNonExistentSync() {
    Directory d = new Directory("").createTempSync();
    d.deleteSync();
    Expect.throws(d.deleteSync);
    Expect.throws(() => d.deleteSync(recursive: true));
  }

  static void testDeleteTooLongNameSync() {
    Directory d = new Directory("").createTempSync();
    var subDirName = 'subdir';
    var subDir = new Directory("${d.path}/$subDirName");
    subDir.createSync();
    // Construct a long string of the form
    // 'tempdir/subdir/../subdir/../subdir'.
    var buffer = new StringBuffer();
    buffer.write(subDir.path);
    for (var i = 0; i < 1000; i++) {
      buffer.write("/../${subDirName}");
    }
    var long = new Directory("${buffer.toString()}");
    Expect.throws(long.deleteSync);
    Expect.throws(() => long.deleteSync(recursive: true));
    d.deleteSync(recursive: true);
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

  static void testDeleteLinkSync() {
    Directory tmp = new Directory("").createTempSync();
    var path = "${tmp.path}${Platform.pathSeparator}";
    Directory d = new Directory("${path}target");
    d.createSync();
    Link l = new Link("${path}symlink");
    l.createSync("${path}target");
    Expect.isTrue(d.existsSync());
    Expect.isTrue(l.existsSync());
    new Directory(l.path).deleteSync(recursive: true);
    Expect.isTrue(d.existsSync());
    Expect.isFalse(l.existsSync());
    d.deleteSync();
    Expect.isFalse(d.existsSync());
    tmp.deleteSync();
  }

  static void testDeleteLinkAsFileSync() {
    Directory tmp = new Directory("").createTempSync();
    var path = "${tmp.path}${Platform.pathSeparator}";
    Directory d = new Directory("${path}target");
    d.createSync();
    Link l = new Link("${path}symlink");
    l.createSync("${path}target");
    Expect.isTrue(d.existsSync());
    Expect.isTrue(l.existsSync());
    new Link(l.path).deleteSync();
    Expect.isTrue(d.existsSync());
    Expect.isFalse(l.existsSync());
    d.deleteSync();
    Expect.isFalse(d.existsSync());
    tmp.deleteSync();
  }

  static void testDeleteBrokenLinkAsFileSync() {
    Directory tmp = new Directory("").createTempSync();
    var path = "${tmp.path}${Platform.pathSeparator}";
    Directory d = new Directory("${path}target");
    d.createSync();
    Link l = new Link("${path}symlink");
    l.createSync("${path}target");
    d.deleteSync();
    Expect.isFalse(d.existsSync());
    Expect.isTrue(l.existsSync());
    new Link(l.path).deleteSync();
    Expect.isFalse(l.existsSync());
    Expect.isFalse(d.existsSync());
    tmp.deleteSync();
  }

  static void testListBrokenLinkSync() {
    Directory tmp = new Directory("").createTempSync();
    var path = "${tmp.path}${Platform.pathSeparator}";
    Directory d = new Directory("${path}target");
    d.createSync();
    Link l = new Link("${path}symlink");
    l.createSync("${path}target");
    d.deleteSync();
    int count = 0;
    tmp.list(followLinks: true).listen(
        (file) {
          count++;
          Expect.isTrue(file is Link);
        },
        onDone: () {
          Expect.equals(1, count);
          l.deleteSync();
          tmp.deleteSync();
        });
  }

  static void testListLinkSync() {
    Directory tmp = new Directory("").createTempSync();
    var path = "${tmp.path}${Platform.pathSeparator}";
    Directory d = new Directory("${path}target");
    d.createSync();
    Link l = new Link("${path}symlink");
    l.createSync("${path}target");
    int count = 0;
    tmp.list(followLinks: true).listen(
        (file) {
          count++;
          Expect.isTrue(file is Directory);
        },
        onDone: () {
          Expect.equals(2, count);
          l.deleteSync();
          d.deleteSync();
          tmp.deleteSync();
        });
  }

  static void testCreateTemp([String template = ""]) {
    asyncStart();
    Directory dir = new Directory(template);
    Future.wait([dir.createTemp(), dir.createTemp()])
      .then((tempDirs) {
        Expect.notEquals(tempDirs[0].path, tempDirs[1].path);
        for (Directory t in tempDirs) {
          Expect.isTrue(t.existsSync());
          t.deleteSync();
          Expect.isFalse(t.existsSync());
        }
        asyncEnd();
      });
  }

  static void testCreateTempTemplate() {
    if (new Directory("/tmp").existsSync()) {
      testCreateTemp("/tmp/dart_temp_dir_");
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
    Directory current = Directory.current;
    if (Platform.operatingSystem != "windows") {
      Expect.equals("/", current.path.substring(0, 1));
    }
  }

  static void testEquals() {
    var name = new File('.').fullPathSync();
    Directory current1 = new Directory(name);
    Directory current2 = new Directory(name);
    Expect.equals(current1.path, current2.path);
    Expect.isTrue(current1.existsSync());
  }

  static void testMain() {
    testListing();
    testListingTailingPaths();
    testListNonExistent();
    testListTooLongName();
    testDeleteNonExistent();
    testDeleteTooLongName();
    testDeleteNonExistentSync();
    testDeleteTooLongNameSync();
    testExistsCreateDelete();
    testExistsCreateDeleteSync();
    testDeleteLinkSync();
    testDeleteLinkAsFileSync();
    testDeleteBrokenLinkAsFileSync();
    testListBrokenLinkSync();
    testListLinkSync();
    testCreateTemp();
    testCreateDeleteTemp();
    testCurrent();
    testEquals();
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
      temp.createTemp('nested_temp_dir_${createdDirectories.length}_')
          .then(createPhaseCallback);
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
                  (e) => e is DirectoryException);
  }
}


testCreateTempError() {
  var location = illegalTempDirectoryLocation();
  if (location == null) return;

  asyncStart();
  var future = new Directory(location).createTemp();
  future.catchError((_) => asyncEnd());
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
  temp.deleteSync(recursive: true);
}


testCreateExisting() {
  // Test that creating an existing directory succeeds.
  asyncStart();
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
              temp.delete(recursive: true).then((_) {
                asyncEnd();
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
                (e) => e is DirectoryException);
  temp.deleteSync(recursive: true);
}


testCreateDirExistingFile() {
  // Test that creating an existing directory succeeds.
  asyncStart();
  var d = new Directory('');
  d.createTemp().then((temp) {
    var path = '${temp.path}/flaf';
    var file = new File(path);
    var subDir = new Directory(path);
    file.create().then((_) {
      subDir.create()
        .then((_) { Expect.fail("dir create should fail on existing file"); })
        .catchError((error) {
          Expect.isTrue(error is DirectoryException);
          temp.delete(recursive: true).then((_) {
            asyncEnd();
          });
        });
    });
  });
}


testCreateRecursiveSync() {
  var temp = new Directory('').createTempSync();
  var d = new Directory('${temp.path}/a/b/c');
  d.createSync(recursive: true);
  Expect.isTrue(new Directory('${temp.path}/a').existsSync());
  Expect.isTrue(new Directory('${temp.path}/a/b').existsSync());
  Expect.isTrue(new Directory('${temp.path}/a/b/c').existsSync());
  temp.deleteSync(recursive: true);
}


testCreateRecursive() {
  asyncStart();
  new Directory('').createTemp().then((temp) {
    var d = new Directory('${temp.path}/a/b/c');
    d.create(recursive: true).then((_) {
      Expect.isTrue(new Directory('${temp.path}/a').existsSync());
      Expect.isTrue(new Directory('${temp.path}/a/b').existsSync());
      Expect.isTrue(new Directory('${temp.path}/a/b/c').existsSync());
      temp.deleteSync(recursive: true);
      asyncEnd();
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
    temp1.deleteSync(recursive: true);
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
  testCreateRecursive();
  testCreateRecursiveSync();
  testRename();
}
