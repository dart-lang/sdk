// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

// Test the dart:io Link class.

class FutureExpect {
  static Future isTrue(Future<bool> result) =>
      result.then((value) => Expect.isTrue(value));
  static Future isFalse(Future<bool> result) =>
      result.then((value) => Expect.isFalse(value));
  static Future equals(expected, Future result) =>
      result.then((value) => Expect.equals(expected, value));
  static Future listEquals(expected, Future result) =>
      result.then((value) => Expect.listEquals(expected, value));
  static Future throws(Future result) => result.then((value) {
        throw new ExpectException(
            "FutureExpect.throws received $value instead of an exception");
      }, onError: (_) => null);
}

Future testCreate() {
  return Directory.systemTemp.createTemp('dart_link_async').then((baseDir) {
    if (isRelative(baseDir.path)) {
      Expect.fail(
          'Link tests expect absolute paths to system temporary directories. '
          'A relative path in TMPDIR gives relative paths to them.');
    }
    String base = baseDir.path;
    String link = join(base, 'link');
    String target = join(base, 'target');
    return new Directory(target)
        .create()
        .then((_) => new Link(link).create(target))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.DIRECTORY, FileSystemEntity.type(link)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.DIRECTORY, FileSystemEntity.type(target)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.LINK,
            FileSystemEntity.type(link, followLinks: false)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.DIRECTORY,
            FileSystemEntity.type(target, followLinks: false)))
        .then((_) => FutureExpect.isTrue(FileSystemEntity.isLink(link)))
        .then((_) => FutureExpect.isFalse(FileSystemEntity.isLink(target)))
        .then((_) => FutureExpect.isTrue(new Directory(link).exists()))
        .then((_) => FutureExpect.isTrue(new Directory(target).exists()))
        .then((_) => FutureExpect.isTrue(new Link(link).exists()))
        .then((_) => FutureExpect.isFalse(new Link(target).exists()))
        .then((_) => FutureExpect.equals(target, new Link(link).target()))
        .then((_) => FutureExpect.throws(new Link(target).target()))
        .then((_) {
      String createdThroughLink = join(base, 'link', 'createdThroughLink');
      String createdDirectly = join(base, 'target', 'createdDirectly');
      String createdFile = join(base, 'link', 'createdFile');
      return new Directory(createdThroughLink)
          .create()
          .then((_) => new Directory(createdDirectly).create())
          .then((_) => new File(createdFile).create())
          .then((_) =>
              FutureExpect.isTrue(new Directory(createdThroughLink).exists()))
          .then((_) =>
              FutureExpect.isTrue(new Directory(createdDirectly).exists()))
          .then((_) => FutureExpect.isTrue(
              new Directory(join(base, 'link', 'createdDirectly')).exists()))
          .then((_) => FutureExpect.isTrue(
              new Directory(join(base, 'target', 'createdThroughLink'))
                  .exists()))
          .then((_) => FutureExpect.equals(FileSystemEntityType.DIRECTORY,
              FileSystemEntity.type(createdThroughLink, followLinks: false)))
          .then((_) => FutureExpect.equals(FileSystemEntityType.DIRECTORY,
              FileSystemEntity.type(createdDirectly, followLinks: false)))

          // Test FileSystemEntity.identical on files, directories, and links,
          // reached by different paths.
          .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(createdDirectly, createdDirectly)))
          .then((_) => FutureExpect.isFalse(FileSystemEntity.identical(createdDirectly, createdThroughLink)))
          .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(createdDirectly, join(base, 'link', 'createdDirectly'))))
          .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(createdThroughLink, join(base, 'target', 'createdThroughLink'))))
          .then((_) => FutureExpect.isFalse(FileSystemEntity.identical(target, link)))
          .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(link, link)))
          .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(target, target)))
          .then((_) => new Link(link).target())
          .then((linkTarget) => FutureExpect.isTrue(FileSystemEntity.identical(target, linkTarget)))
          .then((_) => new File(".").resolveSymbolicLinks())
          .then((fullCurrentDir) => FutureExpect.isTrue(FileSystemEntity.identical(".", fullCurrentDir)))
          .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(createdFile, createdFile)))
          .then((_) => FutureExpect.isFalse(FileSystemEntity.identical(createdFile, createdDirectly)))
          .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(createdFile, join(base, 'link', 'createdFile'))))
          .then((_) => FutureExpect.throws(FileSystemEntity.identical(createdFile, join(base, 'link', 'does_not_exist'))))
          .then((_) => testDirectoryListing(base, baseDir))
          .then((_) => new Directory(target).delete(recursive: true))
          .then((_) {
        var futures = <Future>[];
        for (bool recursive in [true, false]) {
          for (bool followLinks in [true, false]) {
            var result = baseDir.listSync(
                recursive: recursive, followLinks: followLinks);
            Expect.equals(1, result.length);
            Expect.isTrue(result[0] is Link);
            futures.add(FutureExpect.isTrue(baseDir
                .list(recursive: recursive, followLinks: followLinks)
                .single
                .then((element) => element is Link)));
          }
        }
        return Future.wait(futures);
      }).then((_) => baseDir.delete(recursive: true));
    });
  });
}

Future testCreateLoopingLink(_) {
  return Directory.systemTemp
      .createTemp('dart_link_async')
      .then((dir) => dir.path)
      .then((String base) => new Directory(join(base, 'a', 'b', 'c'))
          .create(recursive: true)
          .then((_) => new Link(join(base, 'a', 'b', 'c', 'd'))
              .create(join(base, 'a', 'b')))
          .then((_) =>
              new Link(join(base, 'a', 'b', 'c', 'e')).create(join(base, 'a')))
          .then((_) => new Directory(join(base, 'a'))
              .list(recursive: true, followLinks: false)
              .last)
          // This directory listing must terminate, even though it contains loops.
          .then((_) => new Directory(join(base, 'a'))
              .list(recursive: true, followLinks: true)
              .last)
          // This directory listing must terminate, even though it contains loops.
          .then((_) => new Directory(join(base, 'a', 'b', 'c'))
              .list(recursive: true, followLinks: true)
              .last)
          .then((_) => new Directory(base).delete(recursive: true))
          .then((_) => FutureExpect.isFalse(new Directory(base).exists())));
}

Future testRename(_) {
  Future testRename(String base, String target) {
    Link link1;
    Link link2;
    return new Link(join(base, 'c')).create(target).then((link) {
      link1 = link;
      Expect.isTrue(link1.existsSync());
      return link1.rename(join(base, 'd'));
    }).then((link) {
      link2 = link;
      Expect.isFalse(link1.existsSync());
      Expect.isTrue(link2.existsSync());
      return link2.delete();
    }).then((_) => Expect.isFalse(link2.existsSync()));
  }

  Future testUpdate(String base, String target1, String target2) {
    Link link1;
    return new Link(join(base, 'c')).create(target1).then((link) {
      link1 = link;
      Expect.isTrue(link1.existsSync());
      return link1.update(target2);
    }).then((Link link) {
      Expect.isTrue(link1.existsSync());
      Expect.isTrue(link.existsSync());
      return FutureExpect
          .equals(target2, link.target())
          .then((_) => FutureExpect.equals(target2, link1.target()))
          .then((_) => link.delete());
    }).then((_) => Expect.isFalse(link1.existsSync()));
  }

  return Directory.systemTemp.createTemp('dart_link_async').then((baseDir) {
    String base = baseDir.path;
    var targetsFutures = <Future>[];
    targetsFutures.add(new Directory(join(base, 'a')).create());
    if (Platform.isWindows) {
      // Currently only links to directories are supported on Windows.
      targetsFutures.add(new Directory(join(base, 'b')).create());
    } else {
      targetsFutures.add(new File(join(base, 'b')).create());
    }
    return Future.wait(targetsFutures).then((targets) {
      return testRename(base, targets[0].path)
          .then((_) => testRename(base, targets[1].path))
          .then((_) => testUpdate(base, targets[0].path, targets[1].path))
          .then((_) => baseDir.delete(recursive: true));
    });
  });
}

Future testDirectoryListing(String base, Directory baseDir) {
  Map makeExpected(bool recursive, bool followLinks) {
    Map expected = new Map();
    expected['target'] = 'Directory';
    expected['link'] = followLinks ? 'Directory' : 'Link';
    if (recursive) {
      expected[join('target', 'createdDirectly')] = 'Directory';
      expected[join('target', 'createdThroughLink')] = 'Directory';
      expected[join('target', 'createdFile')] = 'File';
      if (followLinks) {
        expected[join('link', 'createdDirectly')] = 'Directory';
        expected[join('link', 'createdThroughLink')] = 'Directory';
        expected[join('link', 'createdFile')] = 'File';
      }
    }
    return expected;
  }

  void checkEntity(FileSystemEntity x, Map expected) {
    String ending = relative(x.path, from: base);
    Expect.isNotNull(expected[ending]);
    Expect.isTrue(x.toString().startsWith(expected[ending]));
    expected[ending] = 'Found';
  }

  var futures = <Future>[];
  for (bool recursive in [true, false]) {
    for (bool followLinks in [true, false]) {
      Map expected = makeExpected(recursive, followLinks);
      for (var x
          in baseDir.listSync(recursive: recursive, followLinks: followLinks)) {
        checkEntity(x, expected);
      }
      for (var v in expected.values) {
        Expect.equals('Found', v);
      }
      expected = makeExpected(recursive, followLinks);
      futures.add(baseDir
          .list(recursive: recursive, followLinks: followLinks)
          .forEach((entity) => checkEntity(entity, expected))
          .then((_) {
        for (var v in expected.values) {
          Expect.equals('Found', v);
        }
      }));
    }
  }
  return Future.wait(futures);
}

Future checkExists(String filePath) =>
    new File(filePath).exists().then(Expect.isTrue);

Future testRelativeLinks(_) {
  return Directory.systemTemp
      .createTemp('dart_link_async')
      .then((tempDirectory) {
    String temp = tempDirectory.path;
    String oldWorkingDirectory = Directory.current.path;
    // Make directories and files to test links.
    return new Directory(join(temp, 'dir1', 'dir2'))
        .create(recursive: true)
        .then((_) => new File(join(temp, 'dir1', 'file1')).create())
        .then((_) => new File(join(temp, 'dir1', 'dir2', 'file2')).create())
        // Make links whose path and/or target is given by a relative path.
        .then((_) => new Link(join(temp, 'dir1', 'link1_2')).create('dir2'))
        .then((_) => Directory.current = temp)
        .then((_) => new Link('link0_2').create(join('dir1', 'dir2')))
        .then((_) => new Link(join('dir1', 'link1_0')).create('..'))
        .then((_) => Directory.current = 'dir1')
        .then((_) => new Link(join('..', 'link0_1')).create('dir1'))
        .then(
            (_) => new Link(join('dir2', 'link2_1')).create(join(temp, 'dir1')))
        .then((_) => new Link(join(temp, 'dir1', 'dir2', 'link2_0'))
            .create(join('..', '..')))
        // Test that the links go to the right targets.
        .then((_) => checkExists(join('..', 'link0_1', 'file1')))
        .then((_) => checkExists(join('..', 'link0_2', 'file2')))
        .then((_) => checkExists(join('link1_0', 'dir1', 'file1')))
        .then((_) => checkExists(join('link1_2', 'file2')))
        .then((_) => checkExists(join('dir2', 'link2_0', 'dir1', 'file1')))
        .then((_) => checkExists(join('dir2', 'link2_1', 'file1')))
        // Clean up
        .whenComplete(() => Directory.current = oldWorkingDirectory)
        .whenComplete(() => tempDirectory.delete(recursive: true));
  });
}

main() {
  asyncStart();
  testCreate()
      .then(testCreateLoopingLink)
      .then(testRename)
      .then(testRelativeLinks)
      .then((_) => asyncEnd());
}
