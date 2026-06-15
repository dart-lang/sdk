// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate' hide Isolate;

import '../common/test_helper.dart';

late final RawReceivePort port1;
late final RawReceivePort port2;

void warmup() {
  port1 = RawReceivePort(null);
  port2 = RawReceivePort((_) {});
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: warmup);
}
