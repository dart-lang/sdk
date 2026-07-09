// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Make sure that file system watcher works when Mac OS X restricts pipe buffer
// size to 512 bytes (see https://github.com/dart-lang/sdk/issues/61551).

import 'dart:async';
import 'dart:io';
import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  if (!Platform.isMacOS) {
    return;
  }

  exhaustMaxPipeKVA();

  var tempDir = await Directory.systemTemp.createTemp('fsevents_test_');
  try {
    var watcher = tempDir.watch();
    var eventsReceived = 0;

    var subscription = watcher.listen((event) {
      eventsReceived++;
    });

    // Wait for the watcher to become active.
    await Future.delayed(Duration(milliseconds: 500));

    // Make some changes in the directory.
    final testFile = File(p.join(tempDir.path, 'test_file.txt'));
    await testFile.writeAsString('test content');
    await testFile.writeAsString('modified content', mode: FileMode.append);
    await testFile.delete();

    // Wait a bit for events to arrive.
    await Future.delayed(Duration(seconds: 2));

    // Cancel the watcher.
    await subscription.cancel();

    // We should have received at least some events.
    Expect.isTrue(eventsReceived > 0);
  } finally {
    await tempDir.delete(recursive: true);
  }
}

// Create pipes and force their buffers to grow to 64KB until we reach
// kern.ipc.maxpipekva. This should not take more than 256 pipes because
// the limit is 16 MB.
void exhaustMaxPipeKVA() {
  final fds = calloc<Int>(2);

  const writeSize = 64 * 1024;
  final buf = calloc<Int8>(writeSize);

  for (int i = 0; i < 256; i++) {
    final pipeRes = pipe(fds);
    // We do not expect to run out of file descriptors before we run out of space
    // in kernel for pipebuffers.
    Expect.equals(0, pipeRes, 'Failed to create a pipe');
    var writeFd = (fds + 1).value;

    const F_GETFL = 3;
    const F_SETFL = 4;
    const O_NONBLOCK = 0x00000004;

    final flags = fcntl0(writeFd, F_GETFL);
    Expect.isTrue(flags != -1, 'Failed to call fcntl($writeFd, F_GETFL)');

    final setFlagsRes = fcntl1(writeFd, F_SETFL, flags | O_NONBLOCK);
    Expect.isTrue(setFlagsRes != -1, 'Failed to call fcntl($writeFd, F_SETFL)');

    if (write(writeFd, buf.cast(), writeSize) != writeSize) {
      break;
    }
  }
}

@Native<Int Function(Pointer<Int>)>()
external int pipe(Pointer<Int> fds);

@Native<Int Function(Pointer<Int>)>()
external int fnctl(Pointer<Int> fds);

@Native<Int Function(Int, Int, VarArgs<()>)>(symbol: 'fcntl')
external int fcntl0(int fd, int cmd);

@Native<Int Function(Int, Int, VarArgs<(Int,)>)>(symbol: 'fcntl')
external int fcntl1(int fd, int cmd, int val);

@Native<Int Function(Int, Pointer<Void> buf, Size)>()
external int write(int fd, Pointer<Void> buf, int size);
