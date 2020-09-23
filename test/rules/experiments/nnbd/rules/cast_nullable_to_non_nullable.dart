// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N cast_nullable_to_non_nullable`

class A {}

class B extends A {}

m() {
  var v;
  {
    A? a;
    v = a as B; // LINT
  }
  {
    A? a;
    v = a as B?; // OK
  }
  {
    A? a;
    v = a as A; // LINT
  }

  // exclude dynamic
  {
    dynamic b;
    v = b as B; // OK
  }
  {
    dynamic b;
    v = b as B?; // OK
  }
}
