// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C<T> {
  final T t;
  const C(this.t);
}

typedef int Fun(bool, String);

const c0 = C;
const c1 = const C<Type>(C);
const c2 = Fun;
const c3 = const C<Type>(Fun);

main() {
  Expect.identical(C, C);
  Expect.identical(C, c0);
  Expect.identical(c1, c1);
  Expect.notEquals(c0, c1);
  Expect.notEquals(c1, c2);
  Expect.identical(c1.t, c0);
  Expect.notEquals(C, Fun);
  Expect.identical(Fun, Fun);
  Expect.identical(Fun, c2);
  Expect.identical(c3.t, c2);
}
