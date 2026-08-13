// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion is prevented if there is a synthetic instance
// getter of the same name in the library that's a noSuchMethod forwarder.

import 'field_promotion_and_no_such_method_lib.dart' as otherLib;

abstract class C {
  final int? _f1;
  final int? _f2;

  C(int? i) : _f1 = i, _f2 = i;
}

abstract class D {
  final int? _f1;

  D(int? i) : _f1 = i;
}

class E implements D {
  // Implicitly implements _f1 as a getter that forwards to noSuchMethod

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class F implements otherLib.C {
  // Implicitly implements _f2 as a getter that throws; but the name _f2 comes
  // from the other library so it doesn't conflict with the _f2 in this library.

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void acceptsInt(int x) {}

void testConflictsWithNoSuchMethodForwarder(C c) {
  if (c._f1 != null) {
    var x = c._f1;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testNoConflictWithNoSuchMethodForwarderForDifferentLib(C c) {
  if (c._f2 != null) {
    var x = c._f2;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}
