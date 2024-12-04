// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic does not try to promote method tearoffs.

import 'package:expect/static_type_helper.dart';

class C {
  num _f(int i) => 0;
}

class D extends C {
  int _f(num i) => 0;
}

void test(C c) {
  if (c._f is int Function(num)) {
    var x = c._f;
    x.expectStaticType<Exactly<num Function(int)>>();
  }
}

main() {
  test(D());
}
