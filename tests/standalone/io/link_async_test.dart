// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

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
  static Future throws(Future result) =>
      result.then((value) {
        throw new ExpectException(
            "FutureExpect.throws received $value instead of an exception");
        }, onError: (_) => null);
}


Future testCreate() {
  return new Directory('').createTemp().then((temp) {
    Path base = new Path(temp.path);
    Directory baseDir = new Directory.fromPath(base);
    String link = base.append('link').toNativePath();
    String target = base.append('target').toNativePath();
    return new Directory(target).create()
    .then((_) => new Link(link).create(target))

    .then((_) => FutureExpect.equals(FileSystemEntityType.DIRECTORY,
                                     FileSystemEntity.type(link)))
    .then((_) => FutureExpect.equals(FileSystemEntityType.DIRECTORY,
                                     FileSystemEntity.type(target)))
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
      String createdThroughLink =
          base.append('link/createdThroughLink').toNativePath();
      String createdDirectly =
          base.append('target/createdDirectly').toNativePath();
      String createdFile =
          base.append('target/createdFile').toNativePath();
      return new Directory(createdThroughLink).create()
      .then((_) => new Directory(createdDirectly).create())
      .then((_) => new File(createdFile).create())
      .then((_) => FutureExpect.isTrue(
          new Directory(createdThroughLink).exists()))
      .then((_) => FutureExpect.isTrue(
          new Directory(createdDirectly).exists()))
      .then((_) => FutureExpect.isTrue(
          new Directory.fromPath(base.append('link/createdDirectly')).exists()))
      .then((_) => FutureExpect.isTrue(new Directory.fromPath(
          base.append('target/createdThroughLink')).exists()))
      .then((_) => FutureExpect.equals(FileSystemEntityType.DIRECTORY,
          FileSystemEntity.type(createdThroughLink, followLinks: false)))
      .then((_) => FutureExpect.equals(FileSystemEntityType.DIRECTORY,
          FileSystemEntity.type(createdDirectly, followLinks: false)))

      // Test FileSystemEntity.identical on files, directories, and links,
      // reached by different paths.
      .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(
          createdDirectly,
          createdDirectly)))
      .then((_) => FutureExpect.isFalse(FileSystemEntity.identical(
          createdDirectly,
          createdThroughLink)))
      .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(
          createdDirectly,
          base.append('link/createdDirectly').toNativePath())))
      .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(
          createdThroughLink,
          base.append('target/createdThroughLink').toNativePath())))
      .then((_) => FutureExpect.isFalse(FileSystemEntity.identical(
          target,
          link)))
      .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(
          link,
          link)))
      .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(
          target,
          target)))
      .then((_) => new Link(link).target())
      .then((linkTarget) => FutureExpect.isTrue(FileSystemEntity.identical(
          target,
          linkTarget)))
      .then((_) => new File(".").fullPath())
      .then((fullCurrentDir) => FutureExpect.isTrue(FileSystemEntity.identical(
          ".",
          fullCurrentDir)))
      .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(
          createdFile,
          createdFile)))
      .then((_) => FutureExpect.isFalse(FileSystemEntity.identical(
          createdFile,
          createdDirectly)))
      .then((_) => FutureExpect.isTrue(FileSystemEntity.identical(
          createdFile,
          base.append('link/createdFile').toNativePath())))
      .then((_) => FutureExpect.throws(FileSystemEntity.identical(
          createdFile,
          base.append('link/foo').toNativePath())))

      .then((_) => testDirectoryListing(base, baseDir))
      .then((_) => new Directory(target).delete(recursive: true))
      .then((_) {
        List<Future> futures = [];
        for (bool recursive in [true, false]) {
          for (bool followLinks in [true, false]) {
            var result = baseDir.listSync(recursive: recursive,
                                          followLinks: followLinks);
            Expect.equals(1, result.length);
            Expect.isTrue(result[0] is Link);
            futures.add(FutureExpect.isTrue(
              baseDir.list(recursive: recursive,
                           followLinks: followLinks)
              .single.then((element) => element is Link)));
          }
        }
        return Future.wait(futures);
      })
      .then((_) => baseDir.delete(recursive: true));
    });
  });
}


Future testCreateLoopingLink() {
  return new Directory('').createTemp()
  .then((dir) => new Path(dir.path))
  .then((Path base) =>
    new Directory.fromPath(base.append('a/b/c')).create(recursive: true)
    .then((_) => new Link.fromPath(base.append('a/b/c/d'))
        .create(base.append('a/b').toNativePath()))
    .then((_) => new Link.fromPath(base.append('a/b/c/e'))
        .create(base.append('a').toNativePath()))
    .then((_) => new Directory.fromPath(base.append('a'))
        .list(recursive: true, followLinks: false).last)
    // This directory listing must terminate, even though it contains loops.
    .then((_) => new Directory.fromPath(base.append('a'))
        .list(recursive: true, followLinks: true).last)
    // This directory listing must terminate, even though it contains loops.
    .then((_) => new Directory.fromPath(base.append('a/b/c'))
        .list(recursive: true, followLinks: true).last)
    .then((_) => new Directory.fromPath(base).delete(recursive: true))
  );
}


Future testRename() {
  Future testRename(Path base, String target) {
    Link link1;
    Link link2;
    return new Link.fromPath(base.append('c')).create(target)
    .then((link) {
      link1 = link;
      Expect.isTrue(link1.existsSync());
      return link1.rename(base.append('d').toNativePath());
    })
    .then((link) {
      link2 = link;
      Expect.isFalse(link1.existsSync());
      Expect.isTrue(link2.existsSync());
      return link2.delete();
    })
    .then((_) => Expect.isFalse(link2.existsSync()));
  }

  return new Directory('').createTemp().then((baseDir) {
    Path base = new Path(baseDir.path);
    var targetsFutures = [];
    targetsFutures.add(new Directory.fromPath(base.append('a')).create());
    if (Platform.isWindows) {
      // Currently only links to directories are supported on Windows.
      targetsFutures.add(
          new Directory.fromPath(base.append('b')).create());
    } else {
      targetsFutures.add(new File.fromPath(base.append('b')).create());
    }
    return Future.wait(targetsFutures).then((targets) {
      return testRename(base, targets[0].path)
      .then((_) => testRename(base, targets[1].path))
      .then((_) => baseDir.delete(recursive: true));
    });
  });
}

Future testDirectoryListing(Path base, Directory baseDir) {
  Map makeExpected(bool recursive, bool followLinks) {
    Map expected = new Map();
    expected['target'] = 'Directory';
    expected['link'] = followLinks ? 'Directory' : 'Link';
    if (recursive) {
      expected['target/createdDirectly'] = 'Directory';
      expected['target/createdThroughLink'] = 'Directory';
      expected['target/createdFile'] = 'File';
      if (followLinks) {
        expected['link/createdDirectly'] = 'Directory';
        expected['link/createdThroughLink'] = 'Directory';
        expected['link/createdFile'] = 'File';
      }
    }
    return expected;
  }

  void checkEntity(FileSystemEntity x, Map expected) {
    String ending = new Path(x.path).relativeTo(base).toString();
    Expect.isNotNull(expected[ending]);
    Expect.isTrue(x.toString().startsWith(expected[ending]));
    expected[ending] = 'Found';
  }

  List futures = [];
  for (bool recursive in [true, false]) {
    for (bool followLinks in [true, false]) {
      Map expected = makeExpected(recursive, followLinks);
      for (var x in baseDir.listSync(recursive: recursive,
                                     followLinks: followLinks)) {
        checkEntity(x, expected);
      }
      for (var v in expected.values) {
        Expect.equals('Found', v);
      }
      expected = makeExpected(recursive, followLinks);
      futures.add(
        baseDir.list(recursive: recursive, followLinks: followLinks)
        .forEach((entity) => checkEntity(entity, expected))
        .then((_) {
          for (var v in expected.values) {
            Expect.equals('Found', v);
          }
        })
      );
    }
  }
  return Future.wait(futures);
}

main() {
  ReceivePort keepAlive = new ReceivePort();
  testCreate()
  .then((_) => testCreateLoopingLink())
  .then((_) => testRename())
  .then((_) => keepAlive.close());
}
