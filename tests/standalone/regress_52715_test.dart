// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that cancelled [Directory.watch] subscriptions do not waste memory.

import 'dart:io';

import 'package:expect/expect.dart';

void main() async {
  final startRss = ProcessInfo.currentRss;

  for (var i = 0; i < 1024; i++) {
    final subscription = Directory.systemTemp.watch().listen((event) {});
    await subscription.cancel();
  }

  final endRss = ProcessInfo.currentRss;
  final allocatedBytes = (endRss - startRss);
  final limit = 10 * 1024 * 1024;
  Expect.isTrue(allocatedBytes < limit,
      'expected VM RSS growth to be below ${limit} but got ${allocatedBytes}');
}
