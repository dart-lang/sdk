// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups --disable-heap-verification

import 'dart:isolate';

import 'package:expect/expect.dart';

import 'test_utils.dart';

main(args) async {
  final rp = ReceivePort();
  final int n = 18;
  await Isolate.spawn(fibonacciRecursive, [rp.sendPort, n]);
  Expect.equals(4181, await rp.first);
}
