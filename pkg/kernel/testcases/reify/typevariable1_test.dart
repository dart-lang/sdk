// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library typevariable1_test;

import 'test_base.dart';

class Z {
  get succ => new N<Z>();
}

class N<T> {
  get succ => new N<N<T>>();
  get pred => T;
}

main() {
  var one = new Z().succ;
  var two = one.succ;
}
