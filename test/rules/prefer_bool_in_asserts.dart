// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
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
}
