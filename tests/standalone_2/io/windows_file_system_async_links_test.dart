// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

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

Future testJunctionTypeDelete() {
  return Directory.systemTemp
      .createTemp('dart_windows_file_system_async_links')
      .then((temp) {
    var x = '${temp.path}${Platform.pathSeparator}x';
    var y = '${temp.path}${Platform.pathSeparator}y';
    return new Directory(x)
        .create()
        .then((_) => new Link(y).create(x))
        .then((_) => FutureExpect.isTrue(new Directory(y).exists()))
        .then((_) => FutureExpect.isTrue(new Directory(x).exists()))
        .then((_) => FutureExpect.isTrue(FileSystemEntity.isLink(y)))
        .then((_) => FutureExpect.isFalse(FileSystemEntity.isLink(x)))
        .then((_) => FutureExpect.isTrue(FileSystemEntity.isDirectory(y)))
        .then((_) => FutureExpect.isTrue(FileSystemEntity.isDirectory(x)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.DIRECTORY, FileSystemEntity.type(y)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.DIRECTORY, FileSystemEntity.type(x)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.LINK,
            FileSystemEntity.type(y, followLinks: false)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.DIRECTORY,
            FileSystemEntity.type(x, followLinks: false)))
        .then((_) => FutureExpect.equals(x, new Link(y).target()))

        // Test Junction pointing to a missing directory.
        .then((_) => new Directory(x).delete())
        .then((_) => FutureExpect.isTrue(new Link(y).exists()))
        .then((_) => FutureExpect.isFalse(new Directory(x).exists()))
        .then((_) => FutureExpect.isTrue(FileSystemEntity.isLink(y)))
        .then((_) => FutureExpect.isFalse(FileSystemEntity.isLink(x)))
        .then((_) => FutureExpect.isFalse(FileSystemEntity.isDirectory(y)))
        .then((_) => FutureExpect.isFalse(FileSystemEntity.isDirectory(x)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.LINK, FileSystemEntity.type(y)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.NOT_FOUND, FileSystemEntity.type(x)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.LINK,
            FileSystemEntity.type(y, followLinks: false)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.NOT_FOUND,
            FileSystemEntity.type(x, followLinks: false)))
        .then((_) => FutureExpect.equals(x, new Link(y).target()))

        // Delete Junction pointing to a missing directory.
        .then((_) => new Link(y).delete())
        .then((_) => FutureExpect.isFalse(FileSystemEntity.isLink(y)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.NOT_FOUND, FileSystemEntity.type(y)))
        .then((_) => FutureExpect.throws(new Link(y).target()))
        .then((_) => new Directory(x).create())
        .then((_) => new Link(y).create(x))
        .then((_) => FutureExpect.equals(FileSystemEntityType.LINK,
            FileSystemEntity.type(y, followLinks: false)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.DIRECTORY,
            FileSystemEntity.type(x, followLinks: false)))
        .then((_) => FutureExpect.equals(x, new Link(y).target()))

        // Delete Junction pointing to an existing directory.
        .then((_) => new Directory(y).delete())
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.NOT_FOUND, FileSystemEntity.type(y)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.NOT_FOUND,
            FileSystemEntity.type(y, followLinks: false)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.DIRECTORY, FileSystemEntity.type(x)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.DIRECTORY,
            FileSystemEntity.type(x, followLinks: false)))
        .then((_) => FutureExpect.throws(new Link(y).target()))
        .then((_) => temp.delete(recursive: true));
  });
}

main() {
  // Links on other platforms are tested by file_system_[async_]links_test.
  if (Platform.operatingSystem == 'windows') {
    asyncStart();
    testJunctionTypeDelete().then((_) => asyncEnd());
  }
}
