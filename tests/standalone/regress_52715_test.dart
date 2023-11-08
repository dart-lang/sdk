// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that cancelled [Directory.watch] subscriptions do not waste memory.

import 'dart:io';

import 'package:expect/expect.dart';

void main() async {
  final startRss = ProcessInfo.currentRss; //# measure: ok

  for (var i = 0; i < 1024; i++) {
    final subscription = Directory.systemTemp.watch().listen((event) {});
    await subscription.cancel();
  }

  final endRss = ProcessInfo.currentRss; //# measure: continued
  final allocatedBytes = (endRss - startRss); //# measure: continued
  final limit = 10 * 1024 * 1024; //# measure: continued
  Expect.isTrue(allocatedBytes < limit, //# measure: continued
      'expected VM RSS growth to be below ${limit} but got ${allocatedBytes}'); //# measure: continued
}
