// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

main() {
  StackTrace trace;
  asyncStart();
  var f = new Future(() {
    throw "foo";
  });
  f.then((_) => 499).then((_) {
    throw "Unreachable";
  }, onError: (e, st) {
    Expect.equals("foo", e);
    Expect.isNotNull(st);
    asyncEnd();
  });
}
