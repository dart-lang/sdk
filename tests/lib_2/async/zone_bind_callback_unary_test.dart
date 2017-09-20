// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

main() {
  Completer done = new Completer();

  var valueToCapture;
  var restoredValue;

  Expect.identical(Zone.ROOT, Zone.current);
  Zone forked = Zone.current.fork(specification: new ZoneSpecification(
      registerUnaryCallback:
          <R, T>(Zone self, ZoneDelegate parent, Zone origin, R f(T arg)) {
    // The zone is still the same as when origin.run was invoked, which
    // is the root zone. (The origin zone hasn't been set yet).
    Expect.identical(Zone.current, Zone.ROOT);
    // Note that not forwarding is completely legal, though not encouraged.
    var capturedValue = valueToCapture;
    return parent.registerUnaryCallback(origin, (arg) {
      restoredValue = capturedValue;
      return f(arg);
    });
  }));

  valueToCapture = 499;
  var fun = (x) {
    Expect.identical(forked, Zone.current);
    return x + 99;
  };
  var bound = forked.bindUnaryCallback(fun);
  Expect.isFalse(identical(fun, bound));

  // It is legal to invoke the callback in a different zone. This is, of course,
  // extremely discouraged.
  var result = bound(399);
  Expect.equals(498, result);
  Expect.equals(499, restoredValue);
}
