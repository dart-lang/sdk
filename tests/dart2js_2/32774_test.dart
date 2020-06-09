// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

T id<T>(T t) => t;

class C<T> {
  final T t;
  final T Function(T) f;

  const C(this.t, this.f);
}

class D<T> {
  final T t;
  final T Function(T) f;

  const D(this.t, this.f);
}

const C<int> c1a = const C<int>(0, id);
const C<int> c1b = const C<int>(0, id);

const C<double> c2a = const C<double>(0.5, id);
const C<double> c2b = const C<double>(0.5, id);

const D<int> d = const D<int>(0, id);

main() {
  Expect.equals(c1a, c1b);
  Expect.isTrue(identical(c1a, c1b));
  Expect.equals(c1a.f, c1b.f);

  Expect.equals(c2a, c2b);
  Expect.isTrue(identical(c2a, c2b));
  Expect.equals(c2a.f, c2b.f);

  Expect.notEquals(c1a, c2a);
  Expect.notEquals(c1a.f, c2a.f);

  Expect.notEquals(c1a, d);
  Expect.isTrue(identical(c1a.f, d.f));
}
