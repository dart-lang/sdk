// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

// Tests that waitForEventSync() respects its 'timeout' parameter.

main() {
  asyncStart();
  Duration t = const Duration(seconds: 1);
  Stopwatch s = new Stopwatch()..start();
  waitForEventSync(timeout: t);
  s.stop();
  Expect.isTrue(s.elapsed > t);
  asyncEnd();
}
