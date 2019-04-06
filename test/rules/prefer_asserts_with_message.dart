// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_asserts_with_message`

m() {
  assert(true); // LINT
  assert(true, ''); // OK
}

class A {
  A()
      : assert(true), // LINT
        assert(true, ''), // OK
        super();
}
