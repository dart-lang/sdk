// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library future_test;

import "package:expect/expect.dart";
import 'dart:async';

main() {
  compare(func) {
    // Compare the results of the following two futures.
    Future f1 = new Future(func);
    Future f2 = new Future.value().then((_) => func());
    f2.catchError((_) {}); // I'll get the error later.
    f1.then((v1) {
      f2.then((v2) {
        Expect.equals(v1, v2);
      });
    }, onError: (e1) {
      f2.then((_) {
        Expect.fail("Expected error");
      }, onError: (e2) {
        Expect.equals(e1, e2);
      });
    });
  }

  Future val = new Future.value(42);
  Future err1 = new Future.error("Error")..catchError((_) {});
  compare(() => 42);
  compare(() => val);
  compare(() {
    throw "Flif";
  });
  compare(() => err1);
  bool hasExecuted = false;
  compare(() {
    hasExecuted = true;
    return 499;
  });
  Expect.isFalse(hasExecuted);
}
