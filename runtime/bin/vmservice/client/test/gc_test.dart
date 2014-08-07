// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gc_test;

import 'test_helper.dart';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'dart:io';

// Expect at least this many GC events.
int gcCountdown = 3;

void onEvent(ServiceEvent event) {
  if (event.eventType != 'GC') {
    return;
  }
  if (--gcCountdown == 0) {
    exit(0);
  }
}

main() {
  String script = 'gc_script.dart';
  var process = new TestLauncher(script);
  process.launch().then((port) {
    String addr = 'ws://localhost:$port/ws';
    new WebSocketVM(new WebSocketVMTarget(addr)).get('vm')
        .then((VM vm) {
      vm.events.stream.listen(onEvent);
    });
  });
}
