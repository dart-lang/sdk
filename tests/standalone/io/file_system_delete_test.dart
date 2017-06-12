// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";

Future throws(callback()) {
  return new Future.value().then((_) => callback()).then((_) {
    throw "Expected error";
  }, onError: (_) {});
}

void testDeleteFileSync() {
  var tmp = Directory.systemTemp.createTempSync('dart_file_system_delete');
  var path = "${tmp.path}${Platform.pathSeparator}";

  var file = new File("${path}myFile");

  file.createSync();

  Expect.isTrue(file.existsSync());
  new File(file.path).deleteSync();
  Expect.isFalse(file.existsSync());

  file.createSync();

  Expect.isTrue(file.existsSync());
  new Directory(file.path).deleteSync(recursive: true);
  Expect.isFalse(file.existsSync());

  file.createSync();

  Expect.isTrue(file.existsSync());
  Expect.throws(() => new Directory(file.path).deleteSync());
  Expect.isTrue(file.existsSync());

  Expect.isTrue(file.existsSync());
  Expect.throws(() => new Link(file.path).deleteSync());
  Expect.isTrue(file.existsSync());

  file.deleteSync();
  Expect.isFalse(file.existsSync());

  tmp.deleteSync();
}

void testDeleteFile() {
  Directory.systemTemp.createTemp('dart_file_system_delete').then((tmp) {
    var path = "${tmp.path}${Platform.pathSeparator}";
    var file = new File("${path}myFile");
    return file
        .create()
        .then((_) => file.exists().then(Expect.isTrue))
        .then((_) => new File(file.path).delete())
        .then((_) => file.exists().then(Expect.isFalse))
        .then((_) => file.create())
        .then((_) => file.exists().then(Expect.isTrue))
        .then((_) => new Directory(file.path).delete(recursive: true))
        .then((_) => file.exists().then(Expect.isFalse))
        .then((_) => file.create())
        .then((_) => file.exists().then(Expect.isTrue))
        .then((_) => throws(() => new Directory(file.path).delete()))
        .then((_) => file.exists().then(Expect.isTrue))
        .then((_) => file.exists().then(Expect.isTrue))
        .then((_) => throws(() => new Link(file.path).delete()))
        .then((_) => file.exists().then(Expect.isTrue))
        .then((_) => file.delete())
        .then((_) => tmp.delete());
  });
}

void testDeleteDirectorySync() {
  var tmp = Directory.systemTemp.createTempSync('dart_file_system_delete');
  var path = "${tmp.path}${Platform.pathSeparator}";

  var dir = new Directory("${path}myDirectory");

  dir.createSync();

  Expect.isTrue(dir.existsSync());
  new Directory(dir.path).deleteSync();
  Expect.isFalse(dir.existsSync());

  dir.createSync();

  Expect.isTrue(dir.existsSync());
  new Directory(dir.path).deleteSync(recursive: true);
  Expect.isFalse(dir.existsSync());

  dir.createSync();

  Expect.isTrue(dir.existsSync());
  Expect.throws(() => new File(dir.path).deleteSync());
  Expect.isTrue(dir.existsSync());

  Expect.isTrue(dir.existsSync());
  Expect.throws(() => new Link(dir.path).deleteSync());
  Expect.isTrue(dir.existsSync());

  dir.deleteSync();
  Expect.isFalse(dir.existsSync());

  tmp.deleteSync();
}

void testDeleteDirectory() {
  Directory.systemTemp.createTemp('dart_file_system_delete').then((tmp) {
    var path = "${tmp.path}${Platform.pathSeparator}";
    var dir = new Directory("${path}myDirectory");
    return dir
        .create()
        .then((_) => dir.exists().then(Expect.isTrue))
        .then((_) => new Directory(dir.path).delete())
        .then((_) => dir.exists().then(Expect.isFalse))
        .then((_) => dir.create())
        .then((_) => dir.exists().then(Expect.isTrue))
        .then((_) => new Directory(dir.path).delete(recursive: true))
        .then((_) => dir.exists().then(Expect.isFalse))
        .then((_) => dir.create())
        .then((_) => dir.exists().then(Expect.isTrue))
        .then((_) => throws(() => new File(dir.path).delete()))
        .then((_) => dir.exists().then(Expect.isTrue))
        .then((_) => dir.exists().then(Expect.isTrue))
        .then((_) => throws(() => new Link(dir.path).delete()))
        .then((_) => dir.exists().then(Expect.isTrue))
        .then((_) => dir.delete())
        .then((_) => tmp.delete());
  });
}

void testDeleteFileLinkSync() {
  var tmp = Directory.systemTemp.createTempSync('dart_file_system_delete');
  var path = "${tmp.path}${Platform.pathSeparator}";

  var file = new File("${path}myFile");
  file.createSync();

  var link = new Link("${path}myLink");

  link.createSync(file.path);

  Expect.isTrue(link.existsSync());
  new File(link.path).deleteSync();
  Expect.isFalse(link.existsSync());

  link.createSync(file.path);

  Expect.isTrue(link.existsSync());
  new Link(link.path).deleteSync();
  Expect.isFalse(link.existsSync());

  link.createSync(file.path);

  Expect.isTrue(link.existsSync());
  new Directory(link.path).deleteSync(recursive: true);
  Expect.isFalse(link.existsSync());

  link.createSync(file.path);

  Expect.isTrue(link.existsSync());
  Expect.throws(() => new Directory(link.path).deleteSync());
  Expect.isTrue(link.existsSync());

  link.deleteSync();
  Expect.isFalse(link.existsSync());

  Expect.isTrue(file.existsSync());
  file.deleteSync();
  Expect.isFalse(file.existsSync());

  tmp.deleteSync();
}

void testDeleteFileLink() {
  Directory.systemTemp.createTemp('dart_file_system_delete').then((tmp) {
    var path = "${tmp.path}${Platform.pathSeparator}";
    var file = new File("${path}myFile");
    var link = new Link("${path}myLink");
    return file
        .create()
        .then((_) => link.create(file.path))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => new File(link.path).delete())
        .then((_) => link.exists().then(Expect.isFalse))
        .then((_) => link.create(file.path))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => new Link(link.path).delete())
        .then((_) => link.exists().then(Expect.isFalse))
        .then((_) => link.create(file.path))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => new Directory(link.path).delete(recursive: true))
        .then((_) => link.exists().then(Expect.isFalse))
        .then((_) => link.create(file.path))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => throws(() => new Directory(link.path).delete()))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => link.deleteSync())
        .then((_) => link.exists().then(Expect.isFalse))
        .then((_) => file.exists().then(Expect.isTrue))
        .then((_) => file.delete())
        .then((_) => file.exists().then(Expect.isFalse))
        .then((_) => tmp.delete());
  });
}

void testDeleteDirectoryLinkSync() {
  var tmp = Directory.systemTemp.createTempSync('dart_file_system_delete');
  var path = "${tmp.path}${Platform.pathSeparator}";

  var directory = new Directory("${path}myDirectory");
  directory.createSync();

  var link = new Link("${path}myLink");

  link.createSync(directory.path);

  Expect.isTrue(link.existsSync());
  new Link(link.path).deleteSync();
  Expect.isFalse(link.existsSync());

  link.createSync(directory.path);

  Expect.isTrue(link.existsSync());
  new Directory(link.path).deleteSync();
  Expect.isFalse(link.existsSync());

  link.createSync(directory.path);

  Expect.isTrue(link.existsSync());
  new Directory(link.path).deleteSync(recursive: true);
  Expect.isFalse(link.existsSync());

  link.createSync(directory.path);

  Expect.isTrue(link.existsSync());
  Expect.throws(() => new File(link.path).deleteSync());
  Expect.isTrue(link.existsSync());

  link.deleteSync();
  Expect.isFalse(link.existsSync());

  Expect.isTrue(directory.existsSync());
  directory.deleteSync();
  Expect.isFalse(directory.existsSync());

  tmp.deleteSync();
}

void testDeleteDirectoryLink() {
  Directory.systemTemp.createTemp('dart_file_system_delete').then((tmp) {
    var path = "${tmp.path}${Platform.pathSeparator}";
    var dir = new Directory("${path}myDir");
    var link = new Link("${path}myLink");
    return dir
        .create()
        .then((_) => link.create(dir.path))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => new Directory(link.path).delete())
        .then((_) => link.exists().then(Expect.isFalse))
        .then((_) => link.create(dir.path))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => new Directory(link.path).delete(recursive: true))
        .then((_) => link.exists().then(Expect.isFalse))
        .then((_) => link.create(dir.path))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => new Link(link.path).delete())
        .then((_) => link.exists().then(Expect.isFalse))
        .then((_) => link.create(dir.path))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => throws(() => new File(link.path).delete()))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => link.deleteSync())
        .then((_) => link.exists().then(Expect.isFalse))
        .then((_) => dir.exists().then(Expect.isTrue))
        .then((_) => dir.delete())
        .then((_) => dir.exists().then(Expect.isFalse))
        .then((_) => tmp.delete());
  });
}

void testDeleteBrokenLinkSync() {
  var tmp = Directory.systemTemp.createTempSync('dart_file_system_delete');
  var path = "${tmp.path}${Platform.pathSeparator}";

  var directory = new Directory("${path}myDirectory");
  directory.createSync();

  var link = new Link("${path}myLink");

  link.createSync(directory.path);
  directory.deleteSync();

  Expect.isTrue(link.existsSync());
  new Link(link.path).deleteSync();
  Expect.isFalse(link.existsSync());

  directory.createSync();
  link.createSync(directory.path);
  directory.deleteSync();

  Expect.isTrue(link.existsSync());
  new Directory(link.path).deleteSync(recursive: true);
  Expect.isFalse(link.existsSync());

  directory.createSync();
  link.createSync(directory.path);
  directory.deleteSync();

  Expect.isTrue(link.existsSync());
  Expect.throws(() => new Directory(link.path).deleteSync());
  Expect.isTrue(link.existsSync());

  Expect.isTrue(link.existsSync());
  Expect.throws(() => new File(link.path).deleteSync());
  Expect.isTrue(link.existsSync());

  link.deleteSync();
  Expect.isFalse(link.existsSync());

  tmp.deleteSync();
}

void testDeleteBrokenLink() {
  Directory.systemTemp.createTemp('dart_file_system_delete').then((tmp) {
    var path = "${tmp.path}${Platform.pathSeparator}";
    var dir = new Directory("${path}myDir");
    var link = new Link("${path}myLink");
    return dir
        .create()
        .then((_) => link.create(dir.path))
        .then((_) => dir.delete())
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => new Link(link.path).delete())
        .then((_) => link.exists().then(Expect.isFalse))
        .then((_) => dir.create())
        .then((_) => link.create(dir.path))
        .then((_) => dir.delete())
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => new Directory(link.path).delete(recursive: true))
        .then((_) => link.exists().then(Expect.isFalse))
        .then((_) => dir.create())
        .then((_) => link.create(dir.path))
        .then((_) => dir.delete())
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => throws(() => new Directory(link.path).delete()))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => throws(() => new File(link.path).delete()))
        .then((_) => link.exists().then(Expect.isTrue))
        .then((_) => link.deleteSync())
        .then((_) => link.exists().then(Expect.isFalse))
        .then((_) => tmp.delete());
  });
}

void main() {
  testDeleteFileSync();
  testDeleteFile();
  testDeleteDirectorySync();
  testDeleteDirectory();
  if (Platform.operatingSystem != 'windows') {
    testDeleteFileLinkSync();
    testDeleteFileLink();
  }
  testDeleteDirectoryLinkSync();
  testDeleteDirectoryLink();
  testDeleteBrokenLinkSync();
  testDeleteBrokenLink();
}
