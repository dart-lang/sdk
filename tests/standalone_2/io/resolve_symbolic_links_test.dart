// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing FileSystemEntity.resolveSymbolicLinks

import "package:expect/expect.dart";
import "package:path/path.dart";
import "package:async_helper/async_helper.dart";
import 'dart:async';
import 'dart:io';

main() {
  String testsDir = Directory.current.uri.resolve('tests').toFilePath();

  // All of these tests test that resolveSymbolicLinks gives a path
  // that points to the same place as the original, and that it removes
  // all links, .., and . segments, and that it produces an absolute path.
  asyncTest(() => testFile(join(
      testsDir, 'standalone_2', 'io', 'resolve_symbolic_links_test.dart')));
  asyncTest(() => testFile(join(testsDir, 'standalone_2', 'io', '..', 'io',
      'resolve_symbolic_links_test.dart')));

  asyncTest(() => testDir(join(testsDir, 'standalone_2', 'io')));
  asyncTest(() => testDir(join(testsDir, 'lib', '..', 'standalone_2', 'io')));
  // Test a relative path.
  if (Platform.isWindows) {
    asyncTest(() => testFile(join('\\\\?\\$testsDir', 'standalone_2', 'io',
        'resolve_symbolic_links_test.dart')));
    asyncTest(() => testDir('\\\\?\\$testsDir'));
  }
  asyncTest(() => Directory.systemTemp
          .createTemp('dart_resolve_symbolic_links')
          .then((tempDir) {
        String temp = tempDir.path;
        return makeEntities(temp)
            .then((_) => Future.wait([
                  testFile(join(temp, 'dir1', 'file1')),
                  testFile(join(temp, 'link1', 'file2')),
                  testDir(join(temp, 'dir1', 'dir2', '..', '.', '..', 'dir1')),
                  testDir(join(temp, 'dir1', 'dir2', '..', '.', '..', 'dir1')),
                  testLink(join(temp, 'link1')),
                  testDir('.')
                ]))
            .then((_) {
          if (Platform.isWindows) {
            // Windows applies '..' to a link without resolving the link first.
            return Future.wait([
              testFile(join(
                  temp, 'dir1', '..', 'link1', '..', 'dir1', 'dir2', 'file2')),
              testDir(join(temp, 'dir1', '..', 'link1', '..', 'dir1')),
              testLink(join(temp, 'link1', '..', 'link1'))
            ]);
          } else {
            // Non-Windows platforms resolve the link before adding the '..'.
            return Future.wait([
              testFile(
                  join(temp, 'dir1', '..', 'link1', '..', 'dir2', 'file2')),
              testDir(join(temp, 'dir1', '..', 'link1', '..', 'dir2')),
              testLink(join(temp, 'link1', '..', '..', 'link1'))
            ]);
          }
        }).then((_) {
          Directory.current = temp;
          return Future.wait([
            testFile('dir1/dir2/file2'), // Test forward slashes on Windows too.
            testFile('link1/file2'),
            testFile(join('dir1', '..', 'dir1', '.', 'file1')),
            testDir('.'),
            testLink('link1')
          ]);
        }).then((_) {
          Directory.current = 'link1';
          if (Platform.isWindows) {
            return Future.wait([
              testFile('file2'),
              // Windows applies '..' to a link without resolving the link first.
              testFile('..\\dir1\\file1'),
              testLink('.'),
              testDir('..'),
              testLink('..\\link1')
            ]);
          } else {
            return Future.wait([
              testFile('file2'),
              // On non-Windows the link is changed to dir1/dir2 before .. happens.
              testFile('../dir2/file2'),
              testDir('.'),
              testDir('..'),
              testLink('../../link1')
            ]);
          }
        }).whenComplete(() {
          Directory.current = testsDir;
          tempDir.delete(recursive: true);
        });
      }));
}

Future makeEntities(String temp) {
  return new Directory(join(temp, 'dir1', 'dir2'))
      .create(recursive: true)
      .then((_) => new File(join(temp, 'dir1', 'dir2', 'file2')).create())
      .then((_) => new File(join(temp, 'dir1', 'file1')).create())
      .then((_) =>
          new Link(join(temp, 'link1')).create(join(temp, 'dir1', 'dir2')));
}

Future testFile(String name) {
  // We test that f.resolveSymbolicLinks points to the same place
  // as f, because the actual resolved path is not easily predictable.
  // The location of the temp directory varies from system to system,
  // and its path includes symbolic links on some systems.
  //Expect.isTrue(FileSystemEntity.identicalSync(name,
  //   new File(name).resolveSymbolicLinksSync()));
  return new File(name).resolveSymbolicLinks().then((String resolved) {
    //Expect.isTrue(FileSystemEntity.identicalSync(name, resolved));
    Expect.isTrue(isAbsolute(resolved));
    // Test that resolveSymbolicLinks removes all links, .., and . segments.
    Expect.isFalse(resolved.contains('..'));
    Expect.isFalse(resolved.contains('./'));
    Expect.isFalse(resolved.contains('link1'));
  });
}

Future testDir(String name) {
  Expect.isTrue(FileSystemEntity.identicalSync(
      name, new Directory(name).resolveSymbolicLinksSync()));
  return new Directory(name).resolveSymbolicLinks().then((String resolved) {
    Expect.isTrue(FileSystemEntity.identicalSync(name, resolved));
    Expect.isTrue(isAbsolute(resolved));
    // Test that resolveSymbolicLinks removes all links, .., and . segments.
    Expect.isFalse(resolved.contains('..'));
    Expect.isFalse(resolved.contains('./'));
    Expect.isFalse(resolved.contains('link1'));
  });
}

Future testLink(String name) {
  Expect.isFalse(FileSystemEntity.identicalSync(
      name, new Link(name).resolveSymbolicLinksSync()));
  Expect.isTrue(FileSystemEntity.identicalSync(
      new Link(name).targetSync(), new Link(name).resolveSymbolicLinksSync()));
  return new Link(name).resolveSymbolicLinks().then((String resolved) {
    Expect.isFalse(FileSystemEntity.identicalSync(name, resolved));
    Expect.isTrue(isAbsolute(resolved));
    // Test that resolveSymbolicLinks removes all links, .., and . segments.
    Expect.isFalse(resolved.contains('..'));
    Expect.isFalse(resolved.contains('./'));
    Expect.isFalse(resolved.contains('link1'));
    return new Link(name)
        .target()
        .then((targetName) => FileSystemEntity.identical(targetName, resolved))
        .then((identical) => Expect.isTrue(identical));
  });
}
