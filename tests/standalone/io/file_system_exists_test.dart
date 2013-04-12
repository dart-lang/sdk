// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

void testFileExistsSync() {
  var tmp = new Directory("").createTempSync();
  var path = "${tmp.path}${Platform.pathSeparator}";

  var file = new File("${path}myFile");
  file.createSync();

  Expect.isTrue(new File(file.path).existsSync());
  Expect.isFalse(new Directory(file.path).existsSync());
  Expect.isFalse(new Link(file.path).existsSync());

  file.deleteSync();
  Expect.isFalse(file.existsSync());

  tmp.deleteSync();
}

void testFileExists() {
  new Directory("").createTemp().then((tmp) {
    var path = "${tmp.path}${Platform.pathSeparator}";
    var file = new File("${path}myFile");
    return file.create()
      .then((_) => new File(file.path).exists().then(Expect.isTrue))
      .then((_) => new Directory(file.path).exists().then(Expect.isFalse))
      .then((_) => new Link(file.path).exists().then(Expect.isFalse))

      .then((_) => file.delete())
      .then((_) => tmp.delete());
  });
}

void testDirectoryExistsSync() {
  var tmp = new Directory("").createTempSync();
  var path = "${tmp.path}${Platform.pathSeparator}";

  var dir = new Directory("${path}myDirectory");
  dir.createSync();

  Expect.isFalse(new File(dir.path).existsSync());
  Expect.isTrue(new Directory(dir.path).existsSync());
  Expect.isFalse(new Link(dir.path).existsSync());

  dir.deleteSync();
  Expect.isFalse(dir.existsSync());

  tmp.deleteSync();
}

void testDirectoryExists() {
  new Directory("").createTemp().then((tmp) {
    var path = "${tmp.path}${Platform.pathSeparator}";
    var dir = new Directory("${path}myDirectory");
    return dir.create()
      .then((_) => new File(dir.path).exists().then(Expect.isFalse))
      .then((_) => new Directory(dir.path).exists().then(Expect.isTrue))
      .then((_) => new Link(dir.path).exists().then(Expect.isFalse))

      .then((_) => dir.delete())
      .then((_) => tmp.delete());
  });
}

void testFileLinkExistsSync() {
  var tmp = new Directory("").createTempSync();
  var path = "${tmp.path}${Platform.pathSeparator}";

  var file = new File("${path}myFile");
  file.createSync();

  var link = new Link("${path}myLink");
  link.createSync(file.path);

  Expect.isTrue(new File(link.path).existsSync());
  Expect.isFalse(new Directory(link.path).existsSync());
  Expect.isTrue(new Link(link.path).existsSync());

  link.deleteSync();
  Expect.isFalse(link.existsSync());

  file.deleteSync();
  Expect.isFalse(file.existsSync());

  tmp.deleteSync();
}

void testFileLinkExists() {
  new Directory("").createTemp().then((tmp) {
    var path = "${tmp.path}${Platform.pathSeparator}";
    var file = new File("${path}myFile");
    var link = new Link("${path}myLink");
    return file.create()
      .then((_) => link.create(file.path))

      .then((_) => new File(link.path).exists().then(Expect.isTrue))
      .then((_) => new Directory(link.path).exists().then(Expect.isFalse))
      .then((_) => new Link(link.path).exists().then(Expect.isTrue))

      .then((_) => link.delete())
      .then((_) => file.delete())
      .then((_) => tmp.delete());
  });
}

void testDirectoryLinkExistsSync() {
  var tmp = new Directory("").createTempSync();
  var path = "${tmp.path}${Platform.pathSeparator}";

  var directory = new Directory("${path}myDirectory");
  directory.createSync();

  var link = new Link("${path}myLink");
  link.createSync(directory.path);

  Expect.isFalse(new File(link.path).existsSync());
  Expect.isTrue(new Directory(link.path).existsSync());
  Expect.isTrue(new Link(link.path).existsSync());

  link.deleteSync();
  Expect.isFalse(link.existsSync());

  directory.deleteSync();
  Expect.isFalse(directory.existsSync());

  tmp.deleteSync();
}

void testDirectoryLinkExists() {
  new Directory("").createTemp().then((tmp) {
    var path = "${tmp.path}${Platform.pathSeparator}";
    var dir = new Directory("${path}myDir");
    var link = new Link("${path}myLink");
    return dir.create()
      .then((_) => link.create(dir.path))

      .then((_) => new File(link.path).exists().then(Expect.isFalse))
      .then((_) => new Directory(link.path).exists().then(Expect.isTrue))
      .then((_) => new Link(link.path).exists().then(Expect.isTrue))

      .then((_) => link.delete())
      .then((_) => dir.delete())
      .then((_) => tmp.delete());
  });
}

void testBrokenLinkExistsSync() {
  var tmp = new Directory("").createTempSync();
  var path = "${tmp.path}${Platform.pathSeparator}";

  var directory = new Directory("${path}myDirectory");
  directory.createSync();

  var link = new Link("${path}myLink");
  link.createSync(directory.path);
  directory.deleteSync();

  Expect.isFalse(new File(link.path).existsSync());
  Expect.isFalse(new Directory(link.path).existsSync());
  Expect.isTrue(new Link(link.path).existsSync());

  link.deleteSync();
  Expect.isFalse(link.existsSync());

  tmp.deleteSync();
}

void testBrokenLinkExists() {
  new Directory("").createTemp().then((tmp) {
    var path = "${tmp.path}${Platform.pathSeparator}";
    var dir = new Directory("${path}myDir");
    var link = new Link("${path}myLink");
    return dir.create()
      .then((_) => link.create(dir.path))
      .then((_) => dir.delete())

      .then((_) => new File(link.path).exists().then(Expect.isFalse))
      .then((_) => new Directory(link.path).exists().then(Expect.isFalse))
      .then((_) => new Link(link.path).exists().then(Expect.isTrue))

      .then((_) => link.delete())
      .then((_) => tmp.delete());
  });
}

void main() {
  testFileExistsSync();
  testFileExists();
  testDirectoryExistsSync();
  testDirectoryExists();
  if (Platform.operatingSystem != 'windows') {
    testFileLinkExistsSync();
    testFileLinkExists();
  }
  testDirectoryLinkExistsSync();
  testDirectoryLinkExists();
  testBrokenLinkExistsSync();
  testBrokenLinkExists();
}

