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
  var script =
      Platform.script.resolve('file_blocking_lock_script.dart').toFilePath();
  var arguments = <String>[]
    ..addAll(Platform.executableArguments)
    ..add(script)
    ..add(path)
    ..add(len.toString());
  return Process.start(Platform.executable, arguments).then((process) {
    process.stdout.transform(utf8.decoder).listen((data) {
      print(data);
    });
    process.stderr.transform(utf8.decoder).listen((data) {
      print(data);
    });
    return process;
  });
}

const int peerTimeoutMilliseconds = 30000;

Future<bool> waitForPeer(RandomAccessFile raf, int length) async {
  Stopwatch s = new Stopwatch();
  s.start();
  while (true) {
    await raf.unlock(0, length);
    if (s.elapsedMilliseconds > peerTimeoutMilliseconds) {
      s.stop();
      return false;
    }
    try {
      await raf.lock(FileLock.EXCLUSIVE, 0, length);
    } on dynamic {
      await raf.lock(FileLock.BLOCKING_EXCLUSIVE, 0, length);
      break;
    }
  }
  s.stop();
  return true;
}

testLockWholeFile() async {
  const int length = 25;
  Directory directory = await Directory.systemTemp.createTemp('dart_file_lock');
  File file = new File(join(directory.path, "file"));
  await file.writeAsBytes(new List.filled(length, 0));
  var raf = await file.open(mode: APPEND);
  await raf.lock(FileLock.BLOCKING_EXCLUSIVE, 0, length);
  Process peer = await runPeer(file.path, length, FileLock.BLOCKING_EXCLUSIVE);

  // If the peer doesn't come up within the timeout, then give up on the test
  // to avoid the test being flaky.
  if (!await waitForPeer(raf, length)) {
    await raf.close();
    await directory.delete(recursive: true);
    return;
  }

  // Check that the peer wrote to the file.
  int p = 0;
  await raf.setPosition(0);
  while (p < length) {
    int at = await raf.readByte();
    Expect.equals(1, at);
    p++;
  }
  await raf.unlock(0, length);

  // Check that the peer exited successfully.
  int v = await peer.exitCode;
  Expect.equals(0, v);
  await raf.close();
  await directory.delete(recursive: true);
}

main() async {
  asyncStart();
  await testLockWholeFile();
  asyncEnd();
}
