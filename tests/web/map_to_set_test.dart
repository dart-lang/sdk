// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for a missing RTI dependency between Map and JsLinkedHashMap.

import 'package:expect/expect.dart';

main() {
  var c = new Class<double, int>();
  var map = c.m();
  var set = map.keys.toSet();
  Expect.isFalse(set is Set<String>);
}

class Class<T, S> {
  m() {
    return <T, S>{};
  }
}
