// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unawaited_futures`

import 'dart:async';

Future fut() => null;

foo1() {
  fut();
}
foo2() async {
  fut(); //LINT

  // ignore: unawaited_futures
  fut();
}
foo3() async { await fut(); }
foo4() async { var x = fut(); }
foo5() async {
  new Future.delayed(d); //LINT
  new Future.delayed(d, bar);
}
foo6() async {
  var map = <String, Future>{};
  map.putIfAbsent('foo', fut());
}
