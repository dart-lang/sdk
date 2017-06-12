// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file I/O.

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

Future withTempDir(String prefix, void test(Directory dir)) async {
  var tempDir = Directory.systemTemp.createTempSync(prefix);
  try {
    await test(tempDir);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void withTempDirSync(String prefix, void test(Directory dir)) {
  var tempDir = Directory.systemTemp.createTempSync(prefix);
  try {
    test(tempDir);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

Future expectThrowsAsync(Future future, String message) {
  return future.then((r) => Expect.fail(message)).catchError((e) {});
}

Future write(Directory dir) async {
  var f = new File("${dir.path}${Platform.pathSeparator}write");
  var raf = await f.open(mode: WRITE_ONLY);
  await raf.writeString('Hello');
  await raf.setPosition(0);
  await raf.writeString('Hello');
  await raf.setPosition(0);
  await expectThrowsAsync(
      raf.readByte(), 'Read from write only file succeeded');
  await raf.close();
  raf = await f.open(mode: WRITE_ONLY_APPEND);
  await raf.writeString('Hello');
  await expectThrowsAsync(
      raf.readByte(), 'Read from write only file succeeded');
  await raf.setPosition(0);
  await raf.writeString('Hello');
  await raf.close();
  Expect.equals(f.lengthSync(), 10);
}

void writeSync(Directory dir) {
  var f = new File("${dir.path}${Platform.pathSeparator}write_sync");
  var raf = f.openSync(mode: WRITE_ONLY);
  raf.writeStringSync('Hello');
  raf.setPositionSync(0);
  raf.writeStringSync('Hello');
  raf.setPositionSync(0);
  Expect.throws(() => raf.readByteSync());
  raf.closeSync();
}

Future openWrite(Directory dir) async {
  var f = new File("${dir.path}${Platform.pathSeparator}open_write");
  var sink = f.openWrite(mode: WRITE_ONLY);
  sink.write('Hello');
  await sink.close();
  sink = await f.openWrite(mode: WRITE_ONLY_APPEND);
  sink.write('Hello');
  await sink.close();
  Expect.equals(f.lengthSync(), 10);
}

main() async {
  asyncStart();
  await withTempDir('file_write_only_test_1_', write);
  withTempDirSync('file_write_only_test_2_', writeSync);
  await withTempDir('file_write_only_test_3_', openWrite);
  asyncEnd();
}
