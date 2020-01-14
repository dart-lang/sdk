// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/33330
import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

var log = [];

main() {
  asyncStart();
  runZoned(() {
    dynamic d = new AsyncDoEvent();
    return d.doEvent();
  }, zoneSpecification: new ZoneSpecification(
    scheduleMicrotask: (self, parent, zone, fn) {
      log.add('scheduleMicrotask()');
      return parent.scheduleMicrotask(zone, fn);
    },
  )).then((_) {
    Expect.listEquals(log, ['doEvent()', 'scheduleMicrotask()']);
    asyncEnd();
  });
}

class AsyncDoEvent {
  Future doEvent() async {
    log.add('doEvent()');
  }
}
