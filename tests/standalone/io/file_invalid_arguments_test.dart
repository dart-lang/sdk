// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=fixed_length_file_invalid_arguments

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testReadInvalidArgs(arg) {
  String filename = getFilename("fixed_length_file_invalid_arguments");
  var file = (new File(filename)).openSync();
  Expect.throws(() => file.readSync(arg), (e) => e is ArgumentError);

  Expect.throws(() => file.read(arg), (e) => e is ArgumentError);
  file.closeSync();
}

void testReadIntoInvalidArgs(buffer, start, end) {
  String filename = getFilename("fixed_length_file_invalid_arguments");
  var file = (new File(filename)).openSync();
  Expect.throws(
      () => file.readIntoSync(buffer, start, end), (e) => e is ArgumentError);

  Expect.throws(
      () => file.readInto(buffer, start, end), (e) => e is ArgumentError);
  file.closeSync();
}

void testWriteByteInvalidArgs(value) {
  String filename = getFilename("fixed_length_file_invalid_arguments");
  var file = (new File("${filename}_out")).openSync(mode: FileMode.WRITE);
  Expect.throws(() => file.writeByteSync(value), (e) => e is ArgumentError);

  Expect.throws(() => file.writeByte(value), (e) => e is ArgumentError);
  file.closeSync();
}

void testWriteFromInvalidArgs(buffer, start, end) {
  String filename = getFilename("fixed_length_file_invalid_arguments");
  var file = (new File("${filename}_out")).openSync(mode: FileMode.WRITE);
  Expect.throws(
      () => file.writeFromSync(buffer, start, end), (e) => e is ArgumentError);

  Expect.throws(
      () => file.writeFrom(buffer, start, end), (e) => e is ArgumentError);
  file.closeSync();
}

void testWriteStringInvalidArgs(string, encoding) {
  String filename = getFilename("fixed_length_file_invalid_arguments");
  var file = new File("${filename}_out").openSync(mode: FileMode.WRITE);
  Expect.throws(() => file.writeStringSync(string, encoding: encoding),
      (e) => e is ArgumentError);

  Expect.throws(() => file.writeString(string, encoding: encoding),
      (e) => e is ArgumentError);
  file.closeSync();
}

Future futureThrows(Future result) {
  return result.then((value) {
    throw new ExpectException(
        "futureThrows received $value instead of an exception");
  }, onError: (_) => null);
}

void testFileSystemEntity() {
  Expect.throws(() => ((x) => FileSystemEntity.typeSync(x))([1, 2, 3]));
  Expect.throws(() => ((x, y) =>
      FileSystemEntity.typeSync(x, followLinks: y))(".", "why not?"));
  Expect.throws(
      () => ((x, y) => FileSystemEntity.identicalSync(x, y))([1, 2, 3], "."));
  Expect
      .throws(() => ((x, y) => FileSystemEntity.identicalSync(x, y))(".", 52));
  Expect.throws(() => ((x) => FileSystemEntity.isLinkSync(x))(52));
  Expect.throws(() => ((x) => FileSystemEntity.isFileSync(x))(52));
  Expect.throws(() => ((x) => FileSystemEntity.isDirectorySync(x))(52));

  asyncStart();
  futureThrows(((x) => FileSystemEntity.type(x))([1, 2, 3]))
      .then((_) => futureThrows(((x, y) =>
          FileSystemEntity.type(x, followLinks: y))(".", "why not?")))
      .then((_) => futureThrows(
          ((x, y) => FileSystemEntity.identical(x, y))([1, 2, 3], ".")))
      .then((_) =>
          futureThrows(((x, y) => FileSystemEntity.identical(x, y))(".", 52)))
      .then((_) => futureThrows(((x) => FileSystemEntity.isLink(x))(52)))
      .then((_) => futureThrows(((x) => FileSystemEntity.isFile(x))(52)))
      .then((_) => futureThrows(((x) => FileSystemEntity.isDirectory(x))(52)))
      .then((_) => asyncEnd());
}

String getFilename(String path) {
  return Platform.script.resolve(path).toFilePath();
}

main() {
  testReadInvalidArgs('asdf');
  testReadIntoInvalidArgs(12, 0, 1);
  testReadIntoInvalidArgs(new List(10), '0', 1);
  testReadIntoInvalidArgs(new List(10), 0, '1');
  testWriteByteInvalidArgs('asdf');
  testWriteFromInvalidArgs(12, 0, 1);
  testWriteFromInvalidArgs(new List(10), '0', 1);
  testWriteFromInvalidArgs(new List(10), 0, '1');
  testWriteStringInvalidArgs("Hello, world", 42);
  testFileSystemEntity();
}
