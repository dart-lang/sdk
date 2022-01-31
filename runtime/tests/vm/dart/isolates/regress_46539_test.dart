// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-filter=foo --no-use-osr --optimization-counter-threshold=1 --deterministic

// Important: This is a regression test for a concurrency issue, if this test
// is flaky it is essentially failing!

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:_internal' show VMInternalsForTesting;

import 'package:expect/expect.dart';

const int isolateCount = 3;
const int deoptIsolateId = 0;
const int polyIsolateId = 1;

final bool isAOT = Platform.executable.contains('dart_precompiled_runtime');

main() async {
  // This test will cause deoptimizations (via helper in `dart:_internal`) and
  // does therefore not run in AOT.
  if (isAOT) return;

  final onExit = ReceivePort();
  final onError = ReceivePort()
    ..listen((error) {
      print('Error: $error');
      exitCode = 250;
    });
  for (int i = 0; i < isolateCount; ++i) {
    await Isolate.spawn(isolate, i,
        onExit: onExit.sendPort, onError: onError.sendPort);
  }
  final onExits = StreamIterator(onExit);
  for (int i = 0; i < isolateCount; ++i) {
    Expect.isTrue(await onExits.moveNext());
  }
  onExits.cancel();
  onError.close();
}

final globalA = A();
final globalB = B();

isolate(int isolateId) {
  final A a = isolateId == polyIsolateId ? globalB : globalA;
  if (isolateId == polyIsolateId) {
    // We start deopting after 1 second.
    sleep(500000);
  }

  // This runs in unoptimized mode and will therefore do switchable calls.
  final sw = Stopwatch()..start();
  while (sw.elapsedMicroseconds < 2000000) {
    a.foo(isolateId);
    a.foo(isolateId);
    a.foo(isolateId);
    a.foo(isolateId);
  }
}

class A {
  @pragma('vm:never-inline')
  foo(int isolateId) {
    if (isolateId == deoptIsolateId) {
      VMInternalsForTesting.deoptimizeFunctionsOnStack();
    }
  }
}

class B implements A {
  @pragma('vm:never-inline')
  foo(int isolateId) {}
}

void sleep(int us) {
  final sw = Stopwatch()..start();
  while (sw.elapsedMicroseconds < us);
}
