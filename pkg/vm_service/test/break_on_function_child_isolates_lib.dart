// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:isolate' as dart_isolate;

import 'common/test_helper.dart';

int nIsolates = 0;

void foo(args) // LINE_A
{
  print('${dart_isolate.Isolate.current.debugName}: $args');
  final sendPort = args[0] as dart_isolate.SendPort;
  final int i = args[1] as int;
  sendPort.send('reply from foo: $i');
}

Future<void> testMain() async {
  final rps = List<dart_isolate.ReceivePort>.generate(
    nIsolates,
    (i) => dart_isolate.ReceivePort(),
  );

  print('Isolate count: $nIsolates\n\n\n\n');
  debugger(); // LINE_B
  print('stepping'); // LINE_B_PLUS_1
  for (int i = 0; i < nIsolates; i++) {
    await dart_isolate.Isolate.spawn(
      foo,
      [rps[i].sendPort, i],
      debugName: 'foo$i',
    );
  }
  print(await Future.wait(rps.map((rp) => rp.first)));
  debugger(); // LINE_C
  print('done'); // LINE_C_PLUS_1
}

Future<void> main([List<String> args = const <String>[]]) {
  nIsolates = int.fromEnvironment('NUM_CHILD_ISOLATES');
  return startServiceTest(testeeConcurrent: testMain);
}
