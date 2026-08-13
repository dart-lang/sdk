// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate' hide Isolate;
import 'common/test_helper.dart';

late final RawReceivePort port1;
late final RawReceivePort port2;
late final RawReceivePort port3;

void warmup() {
  port1 = RawReceivePort(null, 'port1');
  port2 = RawReceivePort((_) {});
  port3 = RawReceivePort((_) {}, 'port3');
  port3.close();
  RawReceivePort((_) {}, 'port4');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: warmup);
}
