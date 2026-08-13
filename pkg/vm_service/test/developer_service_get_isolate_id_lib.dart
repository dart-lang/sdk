// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:isolate' as iso;

import 'common/test_helper.dart';

// testee state.
late String selfId;
late iso.Isolate childIsolate;
late String childId;

void spawnEntry(int i) {
  debugger();
}

Future testeeMain() async {
  debugger();
  // Spawn an isolate.
  childIsolate = await iso.Isolate.spawn(spawnEntry, 0);
  // Assign the id for this isolate and it's child to strings so they can
  // be read by the tester.
  // ignore: sdk_version_since
  selfId = Service.getIsolateId(iso.Isolate.current)!;
  // ignore: sdk_version_since
  childId = Service.getIsolateId(childIsolate)!;
  debugger();
}

@pragma('vm:entry-point')
String getSelfId() => selfId;

@pragma('vm:entry-point')
String getChildId() => childId;

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
