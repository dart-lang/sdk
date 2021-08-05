// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups --disable-heap-verification

import 'dart:isolate';

import 'package:expect/expect.dart';

import 'test_utils.dart';

main(args) async {
  final rp = ReceivePort();
  final int count = (isDebugMode || isSimulator) ? 100 : (10 * 1000);
  await Isolate.spawn(sumRecursive, [rp.sendPort, count]);
  Expect.equals(count, await rp.first);
}
