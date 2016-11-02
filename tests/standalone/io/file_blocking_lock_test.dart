// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=file_blocking_lock_script.dart

// This test works by spawning a new process running
// file_blocking_lock_script.dart, trading the file lock back and forth,
// writing bytes 1 ... 25 in order to the file. There are checks to ensure
// that the bytes are written in order, that one process doesn't write all the
// bytes and that a non-blocking lock fails such that a blocking lock must
// be taken, which succeeds.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

// Check whether the file is locked or not.
runPeer(String path, int len, FileLock mode) {
  var script = Platform.script.resolve(
      'file_blocking_lock_script.dart').toFilePath();
  var arguments = []
      ..addAll(Platform.executableArguments)
      ..add(script)
      ..add(path)
      ..add(len.toString());
  return Process.start(Platform.executable, arguments).then((process) {
    process.stdout
        .transform(UTF8.decoder)
        .listen((data) { print(data); });
    process.stderr
        .transform(UTF8.decoder)
        .listen((data) { print(data); });
    return process;
  });
}

testLockWholeFile() async {
  const int length = 25;
  Directory directory = await Directory.systemTemp.createTemp('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  await file.writeAsBytes(new List.filled(length, 0));
  var raf = await file.open(mode: APPEND);
  await raf.setPosition(0);
  await raf.lock(FileLock.BLOCKING_EXCLUSIVE, 0, length);
  Process peer = await runPeer(file.path, length, FileLock.BLOCKING_EXCLUSIVE);

  int nextToWrite = 1;
  int at = 0;
  List iWrote = new List.filled(length, 0);
  bool nonBlockingFailed = false;
  while (nextToWrite <= length) {
    int p = await raf.position();
    await raf.writeByte(nextToWrite);
    await raf.flush();
    // Record which bytes this process wrote so that we can check that the
    // other process was able to take the lock and write some bytes.
    iWrote[nextToWrite-1] = nextToWrite;
    nextToWrite++;
    // Let the other process get the lock at least once by spinning until the
    // non-blocking lock fails.
    while (!nonBlockingFailed) {
      await raf.unlock(0, length);
      try {
        await raf.lock(FileLock.EXCLUSIVE, 0, length);
      } catch(e) {
        // Check that at some point the non-blocking lock fails.
        nonBlockingFailed = true;
        await raf.lock(FileLock.BLOCKING_EXCLUSIVE, 0, length);
      }
    }
    while (true) {
      p = await raf.position();
      at = await raf.readByte();
      if (at == 0 || at == -1) break;
      nextToWrite++;
    }
    await raf.setPosition(p);
  }

  await raf.setPosition(0);
  for (int i = 1; i <= length; i++) {
    Expect.equals(i, await raf.readByte());
  }
  await raf.unlock(0, length);

  bool wroteAll = true;
  for (int i = 0; i < length; i++) {
    // If there's a 0 entry, this process didn't write all bytes.
    wroteAll = wroteAll && (iWrote[i] == 0);
  }
  Expect.equals(false, wroteAll);

  Expect.equals(true, nonBlockingFailed);

  await peer.exitCode.then((v) async {
    Expect.equals(0, v);
    await raf.close();
    await directory.delete(recursive: true);
  });
}

main() async {
  asyncStart();
  await testLockWholeFile();
  asyncEnd();
}
