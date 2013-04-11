// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

// Test the dart:io Link class.

testCreateSync() {
  Path base = new Path(new Directory('').createTempSync().path);
  String link = base.append('link').toNativePath();
  String target = base.append('target').toNativePath();
  new Directory(target).createSync();
  new Link(link).createSync(target);

  Expect.equals(FileSystemEntityType.DIRECTORY,
                FileSystemEntity.typeSync(link));
  Expect.equals(FileSystemEntityType.DIRECTORY,
                FileSystemEntity.typeSync(target));
  Expect.equals(FileSystemEntityType.LINK,
                FileSystemEntity.typeSync(link, followLinks: false));
  Expect.equals(FileSystemEntityType.DIRECTORY,
                FileSystemEntity.typeSync(target, followLinks: false));
  Expect.isTrue(FileSystemEntity.isLinkSync(link));
  Expect.isFalse(FileSystemEntity.isLinkSync(target));
  Expect.isTrue(new Directory(link).existsSync());
  Expect.isTrue(new Directory(target).existsSync());
  Expect.isTrue(new Link(link).existsSync());
  Expect.isFalse(new Link(target).existsSync());
  Expect.equals(target, new Link(link).targetSync());
  Expect.throws(() => new Link(target).targetSync());

  String createdThroughLink =
      base.append('link/createdThroughLink').toNativePath();
  String createdDirectly = base.append('target/createdDirectly').toNativePath();
  new Directory(createdThroughLink).createSync();
  new Directory(createdDirectly).createSync();
  Expect.isTrue(new Directory(createdThroughLink).existsSync());
  Expect.isTrue(new Directory(createdDirectly).existsSync());
  Expect.isTrue(new Directory.fromPath(base.append('link/createdDirectly'))
                .existsSync());
  Expect.isTrue(new Directory.fromPath(base.append('target/createdThroughLink'))
                .existsSync());
  Expect.equals(FileSystemEntityType.DIRECTORY,
                FileSystemEntity.typeSync(createdThroughLink,
                                          followLinks: false));
  Expect.equals(FileSystemEntityType.DIRECTORY,
                FileSystemEntity.typeSync(createdDirectly, followLinks: false));

  // Test FileSystemEntity.identical on files, directories, and links,
  // reached by different paths.
  Expect.isTrue(FileSystemEntity.identicalSync(createdDirectly,
                                               createdDirectly));
  Expect.isFalse(FileSystemEntity.identicalSync(createdDirectly,
                                                createdThroughLink));
  Expect.isTrue(FileSystemEntity.identicalSync(createdDirectly,
      base.append('link/createdDirectly').toNativePath()));
  Expect.isTrue(FileSystemEntity.identicalSync(createdThroughLink,
      base.append('target/createdThroughLink').toNativePath()));

  Expect.isFalse(FileSystemEntity.identicalSync(target, link));
  Expect.isTrue(FileSystemEntity.identicalSync(link, link));
  Expect.isTrue(FileSystemEntity.identicalSync(target, target));
  Expect.isTrue(FileSystemEntity.identicalSync(target,
                                               new Link(link).targetSync()));
  String absolutePath = new File(".").fullPathSync();
  Expect.isTrue(FileSystemEntity.identicalSync(".", absolutePath));

  String createdFile = base.append('target/createdFile').toNativePath();
  new File(createdFile).createSync();
  Expect.isTrue(FileSystemEntity.identicalSync(createdFile, createdFile));
  Expect.isFalse(FileSystemEntity.identicalSync(createdFile, createdDirectly));
  Expect.isTrue(FileSystemEntity.identicalSync(createdFile,
      base.append('link/createdFile').toNativePath()));
  Expect.throws(() => FileSystemEntity.identicalSync(createdFile,
      base.append('link/foo').toNativePath()));

  var baseDir = new Directory.fromPath(base);

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
      // We use Stream.reduce to run a function on each entry, and return
      // a future that completes when done.
      var f = new Completer();
      futures.add(f.future);
      baseDir.list(recursive: recursive, followLinks: followLinks).listen(
          (entity) {
            checkEntity(entity, expected);
          },
          onDone: () {
            for (var v in expected.values) {
              Expect.equals('Found', v);
            }
            f.complete(null);
          });
    }
  }
  Future.wait(futures).then((_) {
    new Directory(target).deleteSync(recursive: true);
    for (bool recursive in [true, false]) {
      for (bool followLinks in [true, false]) {
        var result = baseDir.listSync(recursive: recursive,
                                      followLinks: followLinks);
        Expect.equals(1, result.length);
        Expect.isTrue(result[0] is Link);
      }
    }
    baseDir.deleteSync(recursive: true);
  });
}

testCreateLoopingLink() {
  Path base = new Path(new Directory('').createTempSync().path);
  new Directory.fromPath(base.append('a/b/c')).create(recursive: true)
  .then((_) =>
    new Link.fromPath(base.append('a/b/c/d'))
        .create(base.append('a/b').toNativePath()))
  .then((_) =>
    new Link.fromPath(base.append('a/b/c/e'))
        .create(base.append('a').toNativePath()))
  .then((_) =>
    new Directory.fromPath(base.append('a'))
        .list(recursive: true, followLinks: false)
        .last)
  .then((_) =>
    // This directory listing must terminate, even though it contains loops.
    new Directory.fromPath(base.append('a'))
        .list(recursive: true, followLinks: true)
        .last)
  .then((_) =>
    // This directory listing must terminate, even though it contains loops.
    new Directory.fromPath(base.append('a/b/c'))
        .list(recursive: true, followLinks: true)
        .last)
  .then((_) =>
    new Directory.fromPath(base).delete(recursive: true));
}

main() {
  testCreateSync();
  testCreateLoopingLink();
}
