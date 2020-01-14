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

  Expect.identical(Zone.root, Zone.current);
  Zone forked = Zone.current.fork(specification: new ZoneSpecification(
      registerCallback:
          <R>(Zone self, ZoneDelegate parent, Zone origin, R f()) {
    // The zone is still the same as when origin.run was invoked, which
    // is the root zone. (The origin zone hasn't been set yet).
    Expect.identical(Zone.current, Zone.root);
    // Note that not forwarding is completely legal, though not encouraged.
    var capturedValue = valueToCapture;
    return parent.registerCallback(origin, () {
      restoredValue = capturedValue;
      return f();
    });
  }));

  valueToCapture = 499;
  var fun = () => 99;
  var registered = forked.registerCallback<dynamic>(fun);
  Expect.isFalse(identical(fun, registered));

  // It is legal to invoke the callback in a different zone. This is, of course,
  // extremely discouraged.
  var result = registered();
  Expect.equals(99, result);
  Expect.equals(499, restoredValue);
}
