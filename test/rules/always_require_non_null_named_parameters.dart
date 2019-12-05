// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N always_require_non_null_named_parameters`

import 'package:meta/meta.dart';

var condition = true;

m0({
  Object a, // OK
}) {
  if (condition) {
    return;
  }
  assert(a != null);
}

m1(
  a,
  b,
  c, {
  d, // LINT
  e: '',
  @required f, // OK
  g, // LINT
  h: 1, // OK
}) {
  assert(null != d);
  assert(g != null);
  assert(f != null);
  assert(h != null);
}

class A {
  A({
    @required a, // OK
    b, // LINT
    @required c, // OK
  }) {
    assert(a != null);
    assert(b != null);
  }

  m1({
    @required a, // OK
    b, // LINT
    @required c, // OK
  }) {
    assert(a != null);
    assert(b != null);
  }

  m2({
    @required a, // OK
    b, // LINT
    @required c, // OK
  }) {
    assert(true && a != null);
    assert(b != null && true);
  }
}
