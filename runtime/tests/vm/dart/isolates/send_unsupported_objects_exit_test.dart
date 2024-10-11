// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import "package:expect/async_helper.dart";
import 'package:expect/expect.dart';

import 'send_unsupported_objects_test.dart';

worker(SendPort sp) async {
  try {
    Isolate.exit(sp, Fu.unsendable('fu'));
  } catch (e) {
    Expect.isTrue(checkForRetainingPath(e, <String>[
      'NativeClass',
      'Baz',
      'Fu',
    ]));
    sp.send(true);
  }
}

main() async {
  asyncStart();
  final rp = ReceivePort();
  await Isolate.spawn(worker, rp.sendPort);
  Expect.isTrue(await rp.first);
  asyncEnd();
}
