// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:expect/expect.dart';

import 'reload_utils.dart';

const N = 5;

main() async {
  if (!currentVmSupportsReload) return;

  await withTempDir((String tempDir) async {
    final dills = await generateDills(tempDir, dartTestFile(N));
    final reloader = await launchOn(dills[0]);

    await reloader.waitUntilStdoutContainsN('entering ready loop', N);

    final reloadResult1 = await reloader.reload(dills[1]);
    Expect.equals('ReloadReport', reloadResult1['type']);
    Expect.equals(true, reloadResult1['success']);

    await reloader.waitUntilStdoutContainsN('entering done loop', N);

    final reloadResult2 = await reloader.reload(dills[2]);
    Expect.equals('ReloadReport', reloadResult2['type']);
    Expect.equals(true, reloadResult2['success']);

    final int exitCode = await reloader.close();
    Expect.equals(0, exitCode);
  });
}

String dartTestFile(int N) => '''
import 'dart:async';
import 'dart:isolate';

import 'package:expect/expect.dart';

const int N = $N;

Future main() async {
  final done = ReceivePort();
  final errors = ReceivePort();
  for (int i = 0; i < N; ++i) {
    await Isolate.spawn(child, i,
        onExit: done.sendPort, onError: errors.sendPort);
  }

  final allErrors = [];
  errors.listen((e) {
    print('error: \$e');
    allErrors.add(e);
  });

  final si = StreamIterator(done);
  for (int i = 0; i < N; ++i) {
    Expect.isTrue(await si.moveNext());
    print('got exit');
  }
  await si.cancel();

  errors.close();
  Expect.equals(0, allErrors.length);
}

Future child(int index) async {
  bool isReady = false;
  ensureReady() {
    if (!isReady) {
      print('[child-\$index] entering ready loop');
      isReady = true;
    }
  }

  bool isDone = false;
  ensureDone() {
    if (!isDone) {
      print('[child-\$index] entering done loop');
      isDone = true;
    }
  }

  try {
    while (true) {
      ensureReady();
      await insideInfiniteLoop();
    }
  } on Done {
    print('Got infinite loop abortion');
  }

  try {
    while (true) {
      ensureDone();
      await insideShutdownLoop();
    }
  } on Done {
    print('Got shutdown');
  }
}

final timeout = const Duration(milliseconds: 200);

@pragma('vm:never-inline')
Future insideInfiniteLoop() async {
  await Future.delayed(timeout); // @include-in-reload-0
  print('throwing Done'); // @include-in-reload-1
  throw Done(); // @include-in-reload-1
}

@pragma('vm:never-inline')
Future insideShutdownLoop() async {
  await Future.delayed(timeout); // @include-in-reload-0
  await Future.delayed(timeout); // @include-in-reload-1

  print('throwing Done 2'); // @include-in-reload-2
  throw Done(); // @include-in-reload-2
}

class Done {}
''';
