// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

// test w/ `dart test -N prefer_bool_in_asserts`

// todo(pq): remove w/ lint-- https://github.com/dart-lang/linter/issues/3002
main() {
  assert(true); // OK
  assert(true, 'message'); // OK
  assert((() => true)()); // OK
  assert((() => true)(), 'message'); // OK
  assert(() { return true; }()); // OK
  assert(() { return true; }(), 'message'); // OK
  assert(() { throw ""; }()); // OK
}
m1(p) {
  assert(() { return p; }()); // OK
}
m2(Object p) {
  assert(() { return p; }()); // OK
}
