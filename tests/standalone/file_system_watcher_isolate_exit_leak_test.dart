// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that active [Directory.watch] do not leak when created inside an
// isolate which then exits.
//
// On Mac OS X FileSystemWatcher::Cleanup will hang until all watchers are
// destroyed.

import 'dart:io';
import 'dart:isolate';

import 'package:expect/expect.dart';

void main() async {
  // Wait to give `vm-service` isolate time to start up and initialize,
  // because starting vm-service will consume memory and increase RSS.
  await Future.delayed(const Duration(seconds: 1));

  final startRss = ProcessInfo.currentRss;
  for (var i = 0; i < 500; i++) {
    await Isolate.run(() async {
      Directory.systemTemp.watch().listen((event) {});
      // Give the watcher a chance to start before exiting the isolate.
      await Future.delayed(const Duration(milliseconds: 10));
    });
  }

  final endRss = ProcessInfo.currentRss;
  final allocatedBytes = (endRss - startRss);
  final limit = 10 * 1024 * 1024;
  Expect.isTrue(
    allocatedBytes < limit,
    'expected VM RSS growth to be below ${limit} but got ${allocatedBytes}',
  );
}
