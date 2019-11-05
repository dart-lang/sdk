// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";
import "dart:async";
import "dart:io";

// Test the dart:io Link class.

testCreateSync() {
  asyncStart();
  String base = Directory.systemTemp.createTempSync('dart_link').path;
  if (isRelative(base)) {
    Expect.fail(
        'Link tests expect absolute paths to system temporary directories. '
        'A relative path in TMPDIR gives relative paths to them.');
  }
  String link = join(base, 'link');
  String target = join(base, 'target');
  new Directory(target).createSync();
  new Link(link).createSync(target);
  Expect.equals(
      FileSystemEntityType.directory, FileSystemEntity.typeSync(link));
  Expect.equals(
      FileSystemEntityType.directory, FileSystemEntity.typeSync(target));
  Expect.equals(FileSystemEntityType.link,
      FileSystemEntity.typeSync(link, followLinks: false));
  Expect.equals(FileSystemEntityType.directory,
      FileSystemEntity.typeSync(target, followLinks: false));
  Expect.isTrue(FileSystemEntity.isLinkSync(link));
  Expect.isFalse(FileSystemEntity.isLinkSync(target));
  Expect.isTrue(new Directory(link).existsSync());
  Expect.isTrue(new Directory(target).existsSync());
  Expect.isTrue(new Link(link).existsSync());
  Expect.isFalse(new Link(target).existsSync());
  Expect.equals(target, new Link(link).targetSync());
  Expect.throws(() => new Link(target).targetSync());

  String createdThroughLink = join(base, 'link', 'createdThroughLink');
  String createdDirectly = join(base, 'target', 'createdDirectly');
  new Directory(createdThroughLink).createSync();
  new Directory(createdDirectly).createSync();
  Expect.isTrue(new Directory(createdThroughLink).existsSync());
  Expect.isTrue(new Directory(createdDirectly).existsSync());
  Expect.isTrue(
      new Directory(join(base, 'link', 'createdDirectly')).existsSync());
  Expect.isTrue(
      new Directory(join(base, 'target', 'createdThroughLink')).existsSync());
  Expect.equals(FileSystemEntityType.directory,
      FileSystemEntity.typeSync(createdThroughLink, followLinks: false));
  Expect.equals(FileSystemEntityType.directory,
      FileSystemEntity.typeSync(createdDirectly, followLinks: false));

  // Test FileSystemEntity.identical on files, directories, and links,
  // reached by different paths.
  Expect.isTrue(
      FileSystemEntity.identicalSync(createdDirectly, createdDirectly));
  Expect.isFalse(
      FileSystemEntity.identicalSync(createdDirectly, createdThroughLink));
  Expect.isTrue(FileSystemEntity.identicalSync(
      createdDirectly, join(base, 'link', 'createdDirectly')));
  Expect.isTrue(FileSystemEntity.identicalSync(
      createdThroughLink, join(base, 'target', 'createdThroughLink')));

  Expect.isFalse(FileSystemEntity.identicalSync(target, link));
  Expect.isTrue(FileSystemEntity.identicalSync(link, link));
  Expect.isTrue(FileSystemEntity.identicalSync(target, target));
  Expect.isTrue(
      FileSystemEntity.identicalSync(target, new Link(link).targetSync()));
  String absolutePath = new File(".").resolveSymbolicLinksSync();
  Expect.isTrue(FileSystemEntity.identicalSync(".", absolutePath));

  String createdFile = join(base, 'target', 'createdFile');
  new File(createdFile).createSync();
  Expect.isTrue(FileSystemEntity.identicalSync(createdFile, createdFile));
  Expect.isFalse(FileSystemEntity.identicalSync(createdFile, createdDirectly));
  Expect.isTrue(FileSystemEntity.identicalSync(
      createdFile, join(base, 'link', 'createdFile')));
  Expect.throws(() => FileSystemEntity.identicalSync(
      createdFile, join(base, 'link', 'does_not_exist')));

  var baseDir = new Directory(base);

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
      // We use Stream.reduce to run a function on each entry, and return
      // a future that completes when done.
      var f = new Completer();
      futures.add(f.future);
      baseDir.list(recursive: recursive, followLinks: followLinks).listen(
          (entity) {
        checkEntity(entity, expected);
      }, onDone: () {
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
        var result =
            baseDir.listSync(recursive: recursive, followLinks: followLinks);
        Expect.equals(1, result.length);
        Expect.isTrue(result[0] is Link);
      }
    }
    baseDir.deleteSync(recursive: true);
    asyncEnd();
  });
}

testCreateLoopingLink() {
  asyncStart();
  String base = Directory.systemTemp.createTempSync('dart_link').path;
  new Directory(join(base, 'a', 'b', 'c'))
      .create(recursive: true)
      .then((_) =>
          new Link(join(base, 'a', 'b', 'c', 'd')).create(join(base, 'a', 'b')))
      .then((_) =>
          new Link(join(base, 'a', 'b', 'c', 'e')).create(join(base, 'a')))
      .then((_) => new Directory(join(base, 'a'))
          .list(recursive: true, followLinks: false)
          .last)
      .then((_) =>
          // This directory listing must terminate, even though it contains loops.
          new Directory(join(base, 'a'))
              .list(recursive: true, followLinks: true)
              .last)
      .then((_) =>
          // This directory listing must terminate, even though it contains loops.
          new Directory(join(base, 'a', 'b', 'c'))
              .list(recursive: true, followLinks: true)
              .last)
      .whenComplete(() {
    new Directory(base).deleteSync(recursive: true);
    asyncEnd();
  });
}

testRenameSync() {
  testRename(String base, String target) {
    Link link1 = new Link(join(base, 'c'))..createSync(target);
    Expect.isTrue(link1.existsSync());
    Link link2 = link1.renameSync(join(base, 'd'));
    Expect.isFalse(link1.existsSync());
    Expect.isTrue(link2.existsSync());
    link2.deleteSync();
    Expect.isFalse(link2.existsSync());
  }

  testRenameToLink(String base, String target) {
    Link link1 = Link(join(base, '1'))..createSync(target);
    Link link2 = Link(join(base, '2'))..createSync(target);
    Expect.isTrue(link1.existsSync());
    Expect.isTrue(link2.existsSync());
    Link renamed = link1.renameSync(link2.path);
    Expect.isFalse(link1.existsSync());
    Expect.isTrue(renamed.existsSync());
    renamed.deleteSync();
    Expect.isFalse(renamed.existsSync());
  }

  testRenameToTarget(String linkName, String target, bool isDirectory) {
    Link link = Link(linkName)..createSync(target);
    Expect.isTrue(link.existsSync());
    try {
      Link renamed = link.renameSync(target);
      if (isDirectory) {
        Expect.fail('Renaming a link to the name of an existing directory ' +
            'should fail');
      }
      Expect.isTrue(renamed.existsSync());
      renamed.deleteSync();
    } on FileSystemException catch (_) {
      if (isDirectory) {
        return;
      }
      Expect.fail('Renaming a link to the name of an existing file should ' +
          'not fail');
    }
  }

  Directory baseDir = Directory.systemTemp.createTempSync('dart_link');
  String base = baseDir.path;
  Directory dir = new Directory(join(base, 'a'))..createSync();
  File file = new File(join(base, 'b'))..createSync();

  testRename(base, file.path);
  testRename(base, dir.path);

  testRenameToLink(base, file.path);

  testRenameToTarget(join(base, 'fileLink'), file.path, false);
  testRenameToTarget(join(base, 'dirLink'), dir.path, true);

  baseDir.deleteSync(recursive: true);
}

void testLinkErrorSync() {
  Expect.throws(
      () => new Link('some-dir-that-doent exist/some link file/bla/fisk')
          .createSync('bla bla bla/b lalal/blfir/sdfred/es'),
      (e) => e is FileSystemException);
}

checkExists(String filePath) => Expect.isTrue(new File(filePath).existsSync());

testRelativeLinksSync() {
  Directory tempDirectory = Directory.systemTemp.createTempSync('dart_link');
  String temp = tempDirectory.path;
  String oldWorkingDirectory = Directory.current.path;
  // Make directories and files to test links.
  new Directory(join(temp, 'dir1', 'dir2')).createSync(recursive: true);
  new File(join(temp, 'dir1', 'file1')).createSync();
  new File(join(temp, 'dir1', 'dir2', 'file2')).createSync();
  // Make links whose path and/or target is given by a relative path.
  new Link(join(temp, 'dir1', 'link1_2')).createSync('dir2');
  Directory.current = temp;
  new Link('link0_2').createSync(join('dir1', 'dir2'));
  new Link(join('dir1', 'link1_0')).createSync('..');
  Directory.current = 'dir1';
  new Link(join('..', 'link0_1')).createSync('dir1');
  new Link(join('dir2', 'link2_1')).createSync(join(temp, 'dir1'));
  new Link(join(temp, 'dir1', 'dir2', 'link2_0')).createSync(join('..', '..'));
  // Test that the links go to the right targets.
  checkExists(join('..', 'link0_1', 'file1'));
  checkExists(join('..', 'link0_2', 'file2'));
  checkExists(join('link1_0', 'dir1', 'file1'));
  checkExists(join('link1_2', 'file2'));
  checkExists(join('dir2', 'link2_0', 'dir1', 'file1'));
  checkExists(join('dir2', 'link2_1', 'file1'));
  // Clean up
  Directory.current = oldWorkingDirectory;
  tempDirectory.deleteSync(recursive: true);
}

testIsDir() async {
  // Only run on Platforms that supports file watcher
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
  Directory sandbox = Directory.systemTemp.createTempSync();
  Directory dir = new Directory(sandbox.path + Platform.pathSeparator + "dir");
  dir.createSync();
  File target = new File(sandbox.path + Platform.pathSeparator + "target");
  target.createSync();

  var eventCompleter = new Completer<FileSystemEvent>();
  var subscription;
  // Check for link pointing to file
  subscription = dir.watch().listen((FileSystemEvent event) {
    if (event.path.endsWith('link')) {
      eventCompleter.complete(event);
      subscription.cancel();
    }
  });
  Link link = new Link(dir.path + Platform.pathSeparator + "link");
  link.createSync(target.path);
  var event = await eventCompleter.future;
  Expect.isFalse(event.isDirectory);

  // Check for link pointing to directory
  eventCompleter = new Completer<FileSystemEvent>();
  subscription = dir.watch().listen((FileSystemEvent event) {
    if (event.path.endsWith('link2')) {
      eventCompleter.complete(event);
      subscription.cancel();
    }
  });
  link = new Link(dir.path + Platform.pathSeparator + "link2");
  link.createSync(dir.path);
  event = await eventCompleter.future;
  Expect.isFalse(event.isDirectory);

  sandbox.deleteSync(recursive: true);
}

main() {
  testCreateSync();
  testCreateLoopingLink();
  testRenameSync();
  testLinkErrorSync();
  testRelativeLinksSync();
  testIsDir();
}
