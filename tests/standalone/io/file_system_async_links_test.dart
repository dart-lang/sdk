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

Future testFileExistsCreate() {
  return Directory.systemTemp.createTemp('dart_file_system_async').then((temp) {
    var x = '${temp.path}${Platform.pathSeparator}x';
    var y = '${temp.path}${Platform.pathSeparator}y';
    return new Link(y)
        .create(x)
        .then((link) => Expect.equals(y, link.path))
        .then((_) => FutureExpect.isFalse(new File(y).exists()))
        .then((_) => FutureExpect.isFalse(new File(x).exists()))
        .then((_) => FutureExpect.isTrue(FileSystemEntity.isLink(y)))
        .then((_) => FutureExpect.isFalse(FileSystemEntity.isLink(x)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.NOT_FOUND, FileSystemEntity.type(y)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.NOT_FOUND, FileSystemEntity.type(x)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.LINK,
            FileSystemEntity.type(y, followLinks: false)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.NOT_FOUND,
            FileSystemEntity.type(x, followLinks: false)))
        .then((_) => FutureExpect.equals(x, new Link(y).target()))
        .then((_) => new File(y).create())
        .then((yFile) => Expect.equals(y, yFile.path))
        .then((_) => FutureExpect.isTrue(new File(y).exists()))
        .then((_) => FutureExpect.isTrue(new File(x).exists()))
        .then((_) => FutureExpect.isTrue(FileSystemEntity.isLink(y)))
        .then((_) => FutureExpect.isFalse(FileSystemEntity.isLink(x)))
        .then((_) => FutureExpect.isTrue(FileSystemEntity.isFile(y)))
        .then((_) => FutureExpect.isTrue(FileSystemEntity.isFile(x)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.FILE, FileSystemEntity.type(y)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.FILE, FileSystemEntity.type(x)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.LINK,
            FileSystemEntity.type(y, followLinks: false)))
        .then((_) => FutureExpect.equals(FileSystemEntityType.FILE,
            FileSystemEntity.type(x, followLinks: false)))
        .then((_) => FutureExpect.equals(x, new Link(y).target()))
        .then((_) => new File(x).delete())
        .then((xDeletedFile) => Expect.equals(x, xDeletedFile.path))
        .then((_) => new Directory(x).create())
        .then((xCreatedDirectory) => Expect.equals(x, xCreatedDirectory.path))
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
        .then((_) => new Link(y).delete())
        .then((_) => FutureExpect.isFalse(FileSystemEntity.isLink(y)))
        .then((_) => FutureExpect.isFalse(FileSystemEntity.isLink(x)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.NOT_FOUND, FileSystemEntity.type(y)))
        .then((_) => FutureExpect.equals(
            FileSystemEntityType.DIRECTORY, FileSystemEntity.type(x)))
        .then((_) => FutureExpect.throws(new Link(y).target()))
        .then((_) => temp.delete(recursive: true));
  });
}

Future testFileDelete() {
  return Directory.systemTemp.createTemp('dart_file_system_async').then((temp) {
    var x = '${temp.path}${Platform.pathSeparator}x';
    var y = '${temp.path}${Platform.pathSeparator}y';
    return new File(x)
        .create()
        .then((_) => new Link(y).create(x))
        .then((_) => FutureExpect.isTrue(new File(x).exists()))
        .then((_) => FutureExpect.isTrue(new File(y).exists()))
        .then((_) => new File(y).delete())
        .then((_) => FutureExpect.isTrue(new File(x).exists()))
        .then((_) => FutureExpect.isFalse(new File(y).exists()))
        .then((_) => new Link(y).create(x))
        .then((_) => FutureExpect.isTrue(new File(x).exists()))
        .then((_) => FutureExpect.isTrue(new File(y).exists()))
        .then((_) => new File(y).delete())
        .then((_) => FutureExpect.isTrue(new File(x).exists()))
        .then((_) => FutureExpect.isFalse(new File(y).exists()))
        .then((_) => temp.delete(recursive: true));
  });
}

Future testFileWriteRead() {
  return Directory.systemTemp.createTemp('dart_file_system_async').then((temp) {
    var x = '${temp.path}${Platform.pathSeparator}x';
    var y = '${temp.path}${Platform.pathSeparator}y';
    var data = "asdf".codeUnits;
    return new File(x)
        .create()
        .then((_) => new Link(y).create(x))
        .then((_) =>
            (new File(y).openWrite(mode: FileMode.WRITE)..add(data)).close())
        .then((_) => FutureExpect.listEquals(data, new File(y).readAsBytes()))
        .then((_) => FutureExpect.listEquals(data, new File(x).readAsBytes()))
        .then((_) => temp.delete(recursive: true));
  });
}

Future testDirectoryExistsCreate() {
  return Directory.systemTemp.createTemp('dart_file_system_async').then((temp) {
    var x = '${temp.path}${Platform.pathSeparator}x';
    var y = '${temp.path}${Platform.pathSeparator}y';
    return new Link(y)
        .create(x)
        .then((_) => FutureExpect.isFalse(new Directory(x).exists()))
        .then((_) => FutureExpect.isFalse(new Directory(y).exists()))
        .then((_) => FutureExpect.throws(new Directory(y).create()))
        .then((_) => temp.delete(recursive: true));
  });
}

Future testDirectoryDelete() {
  return Directory.systemTemp.createTemp('dart_file_system_async').then((temp) {
    return Directory.systemTemp
        .createTemp('dart_file_system_async')
        .then((temp2) {
      var y = '${temp.path}${Platform.pathSeparator}y';
      var x = '${temp2.path}${Platform.pathSeparator}x';
      var link = new Directory(y);
      return new File(x)
          .create()
          .then((_) => new Link(y).create(temp2.path))
          .then((_) => FutureExpect.isTrue(link.exists()))
          .then((_) => FutureExpect.isTrue(temp2.exists()))
          .then((_) => link.delete())
          .then((_) => FutureExpect.isFalse(link.exists()))
          .then((_) => FutureExpect.isTrue(temp2.exists()))
          .then((_) => new Link(y).create(temp2.path))
          .then((_) => FutureExpect.isTrue(link.exists()))
          .then((_) => temp.delete(recursive: true))
          .then((_) => FutureExpect.isFalse(link.exists()))
          .then((_) => FutureExpect.isFalse(temp.exists()))
          .then((_) => FutureExpect.isTrue(temp2.exists()))
          .then((_) => FutureExpect.isTrue(new File(x).exists()))
          .then((_) => temp2.delete(recursive: true));
    });
  });
}

Future testDirectoryListing() {
  return Directory.systemTemp.createTemp('dart_file_system_async').then((temp) {
    return Directory.systemTemp
        .createTemp('dart_file_system_async_links')
        .then((temp2) {
      var sep = Platform.pathSeparator;
      var y = '${temp.path}${sep}y';
      var x = '${temp2.path}${sep}x';
      return new File(x)
          .create()
          .then((_) => new Link(y).create(temp2.path))
          .then((_) =>
              temp.list(recursive: true).singleWhere((entry) => entry is File))
          .then((file) => Expect.isTrue(file.path.endsWith('$y${sep}x')))
          .then((_) => temp
              .list(recursive: true)
              .singleWhere((entry) => entry is Directory))
          .then((dir) => Expect.isTrue(dir.path.endsWith('y')))
          .then((_) => temp.delete(recursive: true))
          .then((_) => temp2.delete(recursive: true));
    });
  });
}

Future testDirectoryListingBrokenLink() {
  return Directory.systemTemp.createTemp('dart_file_system_async').then((temp) {
    var x = '${temp.path}${Platform.pathSeparator}x';
    var link = '${temp.path}${Platform.pathSeparator}link';
    var doesNotExist = 'this_thing_does_not_exist';
    bool sawFile = false;
    bool sawLink = false;
    return new File(x)
        .create()
        .then((_) => new Link(link).create(doesNotExist))
        .then((_) => temp.list(recursive: true).forEach((entity) {
              if (entity is File) {
                Expect.isFalse(sawFile);
                sawFile = true;
                Expect.isTrue(entity.path.endsWith(x));
              } else {
                Expect.isTrue(entity is Link);
                Expect.isFalse(sawLink);
                sawLink = true;
                Expect.isTrue(entity.path.endsWith(link));
              }
              return true;
            }))
        .then((_) => temp.delete(recursive: true));
  });
}

main() {
  // Links on Windows are tested by windows_file_system_[async_]links_test.
  if (Platform.operatingSystem != 'windows') {
    asyncStart();
    testFileExistsCreate()
        .then((_) => testFileDelete())
        .then((_) => testFileWriteRead())
        .then((_) => testDirectoryExistsCreate())
        .then((_) => testDirectoryDelete())
        .then((_) => testDirectoryListing())
        .then((_) => testDirectoryListingBrokenLink())
        .then((_) => asyncEnd());
  }
}
