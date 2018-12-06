// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_bool_in_asserts`

main() {
  assert(true); // OK
  assert(true, 'message'); // OK
  assert(() => true); // LINT
  assert(() => true, 'message'); // LINT
  assert((() => true)()); // OK
  assert((() => true)(), 'message'); // OK
  assert(() { return true; }); // LINT
  assert(() { return true; }, 'message'); // LINT
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
m3<T>(T p) {
  assert(() { return p; }()); // OK
}
m4<T extends List>(T p) {
  assert(() { return p; }()); // LINT
}
m5<S, T extends S>(T p) {
  assert(() { return p; }()); // OK
}
m6<S extends List, T extends S>(T p) {
  assert(() { return p; }()); // LINT
}
