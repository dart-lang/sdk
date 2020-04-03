// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'test_helper.dart';

import 'dart:async';

void script() {
  var grow;
  grow = (int iterations, int size, Duration duration) {
    if (iterations <= 0) {
      return;
    }
    new List<int>.filled(size, 0);
    new Timer(duration, () => grow(iterations - 1, size, duration));
  };
  grow(100, 1 << 24, new Duration(seconds: 1));
}

var tests = <IsolateTest>[
  (Isolate isolate) {
    Completer completer = new Completer();
    // Expect at least this many GC events.
    int gcCountdown = 3;
    isolate.vm.getEventStream(VM.kGCStream).then((stream) {
      var subscription;
      subscription = stream.listen((ServiceEvent event) {
        assert(event.kind == ServiceEvent.kGC);
        print('Received GC event');
        if (--gcCountdown == 0) {
          subscription.cancel();
          completer.complete();
        }
      });
    });
    return completer.future;
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: script);
