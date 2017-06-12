// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file creation.

import 'dart:async';
import 'dart:io';

import "package:expect/expect.dart";
import "package:path/path.dart";

testCreate() async {
  Directory tmp = await Directory.systemTemp.createTemp('file_test_create');
  Expect.isTrue(await tmp.exists());
  String filePath = "${tmp.path}/foo";
  File file = new File(filePath);
  File createdFile = await file.create();
  Expect.equals(file, createdFile);
  Expect.isTrue(await createdFile.exists());
  await tmp.delete(recursive: true);
}

testBadCreate() async {
  Directory tmp = await Directory.systemTemp.createTemp('file_test_create');
  Expect.isTrue(await tmp.exists());
  Directory tmp2 = await tmp.createTemp('file_test_create');
  Expect.isTrue(await tmp2.exists());
  String badFilePath = tmp2.path;
  File badFile = new File(badFilePath);
  try {
    await badFile.create();
    Expect.fail('Should be unreachable');
  } catch (e) {
    Expect.isTrue(e is FileSystemException);
    Expect.isNotNull(e.osError);
  }
  await tmp.delete(recursive: true);
}

main() async {
  await testCreate();
  await testBadCreate();
}
