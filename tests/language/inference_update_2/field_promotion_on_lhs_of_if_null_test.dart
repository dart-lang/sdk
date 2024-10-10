// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a promotable field access appearing on the LHS of `??` is properly
// promoted in a code path where it is known to be non-null.

import 'package:expect/expect.dart';
import '../static_type_helper.dart';

class A {
  final int? _f1;

  A(this._f1);
}

test(A a) {
  a._f1.expectStaticType<Exactly<int?>>();
  a._f1 ?? [a._f1.expectStaticType<Exactly<int?>>(), throw ''];
  a._f1.expectStaticType<Exactly<int>>();
}

main() {
  test(A(0));
  Expect.throws(() => test(A(null)));
}
