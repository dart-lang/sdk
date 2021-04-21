// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N prefer_null_aware_method_calls`

var o;
var f, g;

m() {
  if (o != null) o!(); // LINT

  if (o != null) {
    o!(); // LINT
  }

  if (o.m != null) {
    o.m!(); // LINT
  }

  if (o.a != null) {
    o.m!(); // OK
  }

  o != null ? o!() : null; // LINT
  o.m != null ? o.m!() : null; // LINT
  o.a != null ? o.m!() : null; // OK

  if (f != null) g!(); // OK
  f != null ? g!() : null; // OK
}
