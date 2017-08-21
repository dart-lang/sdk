// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'package:async_helper/async_helper.dart';

main() {
  asyncStart();
  dynamic x = 499;
  scheduleMicrotask(() {
    Expect.equals(499, x);
    x = 42;
  });
  new Future.microtask(() {
    Expect.equals(42, x);
    x = null;
    return 99;
  }).then((val) {
    Expect.isNull(x);
    Expect.equals(99, val);
    x = "foo";
  });
  scheduleMicrotask(() {
    Expect.equals("foo", x);
    x = "toto";
    asyncEnd();
  });

  asyncStart();
  new Future.microtask(() {
    throw "foo";
  }).catchError((e, stackTrace) {
    Expect.equals("foo", e);
    asyncEnd();
  });
}
