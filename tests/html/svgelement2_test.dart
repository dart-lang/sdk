// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library SVGElement2Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'svgelement_test.dart' as originalTest;

class A {
  var _this;
  A(x) : this._this = x;
}

main() {
  // The svgelement_test requires the field "_this" to map to "_this". In this
  // test-case we use another library's '_this' first (see issue 3039 and
  // _ChildNodeListLazy.first).
  expect(new A(499)._this, 499);
  originalTest.main();
}
