// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
// ignore: library_prefixes
import 'dart:isolate' as I;

import 'common/test_helper.dart';

final spawnCount = 4;
final isolates = [];

void spawnEntry(int i) {}

Future<void> during() async {
  debugger(); // LINE_A
  // Spawn spawnCount long lived isolates.
  for (int i = 0; i < spawnCount; i++) {
    final isolate = await I.Isolate.spawn(spawnEntry, i);
    isolates.add(isolate);
  }
  print('spawned all isolates');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: during);
}
