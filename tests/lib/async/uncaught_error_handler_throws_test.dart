// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

void main() async {
  asyncStart();
  await testThrowSame();
  await testThrowOther();
  asyncEnd();
}

Future<void> testThrowSame() async {
  asyncStart();
  var object1 = Object();
  var stack1 = StackTrace.current;
  var outerZone = Zone.current;
  var firstZone = Zone.current.fork(specification: onError((error, stack) {
    // Uncaught error handlers run in the parent zone.
    Expect.identical(outerZone, Zone.current);
    Expect.identical(object1, error);
    Expect.identical(stack1, stack); // Get same stack trace.
    asyncEnd();
  }));
  firstZone.run(() async {
    Expect.identical(firstZone, Zone.current);
    var secondZone = Zone.current.fork(specification: onError((error, stack) {
      // Uncaught error handlers run in the parent zone.
      Expect.identical(firstZone, Zone.current);
      Expect.identical(object1, error);
      Expect.identical(stack1, stack);
      throw error; // Throw same object
    }));
    secondZone.run(() async {
      Expect.identical(secondZone, Zone.current);
      Future.error(object1, stack1); // Unhandled async error.
      await Future(() {});
    });
  });
}

Future<void> testThrowOther() async {
  asyncStart();
  var object1 = Object();
  var object2 = Object();
  var stack1 = StackTrace.current;
  var outerZone = Zone.current;
  var firstZone = Zone.current.fork(specification: onError((error, stack) {
    Expect.identical(outerZone, Zone.current);
    Expect.identical(object2, error);
    Expect.notIdentical(stack1, stack); // Get different stack trace.
    asyncEnd();
  }));
  firstZone.run(() async {
    Expect.identical(firstZone, Zone.current);
    var secondZone = Zone.current.fork(specification: onError((error, stack) {
      Expect.identical(firstZone, Zone.current);
      Expect.identical(object1, error);
      Expect.identical(stack1, stack);
      throw object2; // Throw different object
    }));
    secondZone.run(() async {
      Expect.identical(secondZone, Zone.current);
      Future.error(object1, stack1); // Unhandled async error.
      await Future(() {});
    });
  });
}

ZoneSpecification onError(void Function(Object, StackTrace) handler) {
  return ZoneSpecification(
      handleUncaughtError: (s, p, z, e, st) => handler(e, st));
}
