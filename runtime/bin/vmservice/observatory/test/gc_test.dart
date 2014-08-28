// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'test_helper.dart';

import 'dart:async';

void script() {
  List<int> data;
  var grow;
  grow = (int iterations, int size, Duration duration) {
    if (iterations <= 0) {
      return;
    }
    data = new List<int>(size);
    new Timer(duration, () => grow(iterations - 1, size, duration));
  };
  grow(100, 1 << 24, new Duration(seconds: 1));
}

var tests = [

(Isolate isolate) {
  Completer completer = new Completer();
  // Expect at least this many GC events.
  int gcCountdown = 3;
  isolate.vm.events.stream.listen((ServiceEvent event) {
    if (event.eventType == 'GC' && --gcCountdown == 0) {
      completer.complete();
    }
  });
  return completer.future;
},

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: script);
