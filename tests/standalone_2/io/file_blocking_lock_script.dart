// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Script used by the file_lock_test.dart test.

import "dart:async";
import "dart:io";

Future<int> testLockWholeFile(File file, int len) async {
  var raf = await file.open(mode: APPEND);
  await raf.setPosition(0);
  int nextToWrite = 1;
  await raf.lock(FileLock.BLOCKING_EXCLUSIVE, 0, len);

  // Make sure the peer fails a non-blocking lock at some point.
  await new Future.delayed(const Duration(seconds: 1));

  int p = 0;
  while (p < len) {
    await raf.writeByte(1);
    p++;
  }
  await raf.unlock(0, len);
  await raf.close();
  return 0;
}

main(List<String> args) async {
  File file = new File(args[0]);
  int len = int.parse(args[1]);
  exit(await testLockWholeFile(file, len));
}
