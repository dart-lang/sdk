// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_is_not_operator`

class Foo {}
var _a;

foo() {
  if (!(_a is Foo)) {} // LINT
  var _exp = !(_a is Foo); // LINT

  if (_a is! Foo) {} // OK
  var _exp1 = _a is! Foo; // OK
}
