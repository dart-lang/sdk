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
  while (nextToWrite <= len) {
    await raf.lock(FileLock.BLOCKING_EXCLUSIVE, 0, len);

    int at;
    int p;
    while (true) {
      p = await raf.position();
      at = await raf.readByte();
      if (at == 0 || at == -1) break;
      nextToWrite++;
    }
    await raf.setPosition(p);
    await raf.writeByte(nextToWrite);
    await raf.flush();
    nextToWrite++;
    await raf.unlock(0, len);
  }

  await raf.lock(FileLock.BLOCKING_EXCLUSIVE, 0, len);
  await raf.setPosition(0);
  for (int i = 1; i <= len; i++) {
    if ((await raf.readByte()) != i) {
      await raf.unlock(0, len);
      await raf.close();
      return 1;
    }
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
