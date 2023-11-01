// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

void script() {
  var grow;
  grow = (int iterations, int size, Duration duration) {
    if (iterations <= 0) {
      return;
    }
    List<int>.filled(size, 0);
    Timer(duration, () => grow(iterations - 1, size, duration));
  };
  grow(100, 1 << 24, new Duration(seconds: 1));
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    Completer completer = Completer();
    // Expect at least this many GC events.
    int gcCountdown = 3;
    late final StreamSubscription sub;
    sub = service.onGCEvent.listen((stream) {
      if (--gcCountdown == 0) {
        sub.cancel();
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kGC);
    return completer.future;
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'gc_test.dart',
      testeeConcurrent: script,
    );
