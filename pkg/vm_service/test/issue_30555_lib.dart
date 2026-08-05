// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
// ignore: library_prefixes
import 'dart:isolate' as I;

import 'common/test_helper.dart';

void isolate(I.SendPort port) {
  final receive = I.RawReceivePort((_) {
    debugger(); // LINE_A
    throw Exception();
  });
  port.send(receive.sendPort);
}

void test() {
  final receive = I.RawReceivePort((port) {
    debugger(); // LINE_B
    port.send(null);
    debugger(); // LINE_C
    port.send(null);
    debugger(); // LINE_D
  });
  I.Isolate.spawn(isolate, receive.sendPort);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: test);
}
