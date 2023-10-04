// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

m1(
  a, // OK
  {
  b, // OK
  @required c, // LINT
  @required d, // LINT
  e, // OK
  @required f, // LINT
}) {}

m2({
  @required a, // OK
  @required b, // OK
  c, // OK
  @required d, // LINT
  e, // OK
  @required f, // LINT
}) {}

n1(
  a, // OK
  {
  b, // OK
  required c, // LINT
  required d, // LINT
  e, // OK
  required f, // LINT
}) {}

n2({
  required a, // OK
  required b, // OK
  c, // OK
  required d, // LINT
  e, // OK
  required f, // LINT
}) {}

class A {
  A.c1(
    a, // OK
    {
    b, // OK
    @required c, // LINT
    @required d, // LINT
    e, // OK
    @required f, // LINT
  });
  A.c2({
    @required a, // OK
    @required b, // OK
    c, // OK
    @required d, // LINT
    e, // OK
    @required f, // LINT
  });
  A.d1(
    a, // OK
    {
    b, // OK
    required c, // LINT
    required d, // LINT
    e, // OK
    required f, // LINT
  });
  A.d2({
    required a, // OK
    required b, // OK
    c, // OK
    required d, // LINT
    e, // OK
    required f, // LINT
  });
}
