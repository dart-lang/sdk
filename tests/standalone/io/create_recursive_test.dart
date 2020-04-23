// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

main() {
  testCreateDirectoryRecursiveSync();
  testCreateLinkRecursiveSync();
  testCreateFileRecursiveSync();
  testCreateDirectoryRecursive();
  testCreateLinkRecursive();
  testCreateFileRecursive();
}

testCreateDirectoryRecursiveSync() {
  var temp = Directory.systemTemp.createTempSync('directory_test');
  try {
    var dir = new Directory(join(temp.path, 'a', 'b', 'c'));
    Expect.throws(() => dir.createSync());
    dir.createSync(recursive: true);
    Expect.isTrue(dir.existsSync());
    // Test cases where the directory or parent directory already exists.
    dir.deleteSync();
    dir.createSync(recursive: true);
    Expect.isTrue(dir.existsSync());
    dir.createSync(recursive: true);
    Expect.isTrue(dir.existsSync());
  } finally {
    temp.deleteSync(recursive: true);
  }
}

testCreateFileRecursiveSync() {
  var temp = Directory.systemTemp.createTempSync('directory_test');
  try {
    var file = new File(join(temp.path, 'a', 'b', 'c'));
    Expect.throws(() => file.createSync());
    file.createSync(recursive: true);
    Expect.isTrue(file.existsSync());
    // Test cases where the file or parent directory already exists.
    file.deleteSync();
    file.createSync(recursive: true);
    Expect.isTrue(file.existsSync());
    file.createSync(recursive: true);
    Expect.isTrue(file.existsSync());
  } finally {
    temp.deleteSync(recursive: true);
  }
}

testCreateLinkRecursiveSync() {
  var temp = Directory.systemTemp.createTempSync('directory_test');
  try {
    var link = new Link(join(temp.path, 'a', 'b', 'c'));
    Expect.throws(() => link.createSync(temp.path));
    link.createSync(temp.path, recursive: true);
    Expect.isTrue(link.existsSync());
    Expect.isTrue(new Directory(link.targetSync()).existsSync());
    // Test cases where the link or parent directory already exists.
    link.deleteSync();
    link.createSync(temp.path, recursive: true);
    Expect.isTrue(link.existsSync());
    Expect.throws(() => link.createSync(temp.path, recursive: true));
    Expect.isTrue(link.existsSync());
  } finally {
    temp.deleteSync(recursive: true);
  }
}

Future expectFutureIsTrue(Future future) =>
    future.then((value) => Expect.isTrue(value));

Future expectFileSystemException(Function f, String message) {
  return f().then(
      (_) => Expect.fail('Expected a FileSystemException: $message'),
      onError: (e) => Expect.isTrue(e is FileSystemException));
}

testCreateDirectoryRecursive() {
  asyncStart();
  Directory.systemTemp.createTemp('dart_directory').then((temp) {
    var dir = new Directory(join(temp.path, 'a', 'b', 'c'));
    return expectFileSystemException(() => dir.create(), 'dir.create')
        .then((_) => dir.create(recursive: true))
        .then((_) => expectFutureIsTrue(dir.exists()))
        // Test cases where the directory or parent directory already exists.
        .then((_) => dir.delete())
        .then((_) => dir.create(recursive: true))
        .then((_) => expectFutureIsTrue(dir.exists()))
        .then((_) => dir.create(recursive: true))
        .then((_) => expectFutureIsTrue(dir.exists()))
        .then((_) => asyncEnd())
        .whenComplete(() => temp.delete(recursive: true));
  });
}

testCreateFileRecursive() {
  asyncStart();
  Directory.systemTemp.createTemp('dart_directory').then((temp) {
    var file = new File(join(temp.path, 'a', 'b', 'c'));
    return expectFileSystemException(() => file.create(), 'file.create')
        .then((_) => file.create(recursive: true))
        .then((_) => expectFutureIsTrue(file.exists()))
        // Test cases where the file or parent directory already exists.
        .then((_) => file.delete())
        .then((_) => file.create(recursive: true))
        .then((_) => expectFutureIsTrue(file.exists()))
        .then((_) => file.create(recursive: true))
        .then((_) => expectFutureIsTrue(file.exists()))
        .then((_) => asyncEnd())
        .whenComplete(() => temp.delete(recursive: true));
  });
}

testCreateLinkRecursive() {
  asyncStart();
  Directory.systemTemp.createTemp('dart_directory').then((temp) {
    var link = new Link(join(temp.path, 'a', 'b', 'c'));
    return expectFileSystemException(
            () => link.create(temp.path), 'link.create')
        .then((_) => link.create(temp.path, recursive: true))
        .then((_) => expectFutureIsTrue(link.exists()))
        // Test cases where the link or parent directory already exists.
        .then((_) => link.delete())
        .then((_) => link.create(temp.path, recursive: true))
        .then((_) => expectFutureIsTrue(link.exists()))
        .then((_) => expectFileSystemException(
            () => link.create(temp.path, recursive: true),
            'existing link.create'))
        .then((_) => expectFutureIsTrue(link.exists()))
        .then((_) => asyncEnd())
        .whenComplete(() => temp.delete(recursive: true));
  });
}
