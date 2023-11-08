// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when determining whether field promotion should be inhibited due
// to a `noSuchMethod` forwarder, the implementation doesn't terminate its
// exploration of the class hierarchy at a library boundary; it continues in
// order to find transitive superclass relationships via an intermediate class
// in another library. Note that this situation can only arise in libraries that
// are part of a library cycle.

// SharedOptions=--enable-experiment=inference-update-2

// The class hierarchy implemented in this test looks like this:
//
// C {_f1}   F {_f2}      H {_f1, _f2}
// ^         ^
// |extends  |implements
// B         E
// ^         ^
// |extends  |implements
// A         D {_f1}
// ^         ^
// |extends  |implements
// +---------+
// |
// G
//
// With classes B and E in a different library than this one.
//
// In brackets following each class name are the names of fields explicitly
// declared in the corresponding class declaration.

import "../static_type_helper.dart";

import 'field_promotion_and_no_such_method_library_cycle_lib.dart';

class A extends B {
  A(super.f1);
}

class C {
  final int? _f1;
  C(this._f1);
}

// Note: this class is abstract because it has an `_f2` getter in its interface,
// inherited from `F` (by way of `E`), but it neither inherits nor declares any
// implementation of `_f2`. Since it does not have a non-default `noSuchMethod`
// implementation, it needs to be abstract to avoid a compile-time error.
abstract class D implements E {
  // Note: this is `_f1` on purpose; not `_f2`. The reason for this field is to
  // make the overall test more robust; if there is a bug that prevents the
  // implementation from finding `C._f1` when it walks the class hierarchy of
  // `G` (e.g. because it stops walking the class hierarchy at a library
  // boundary--a bug that exists as of
  // 98b63e1dcf600402c910740cf2338cb18e05f68d), it will still find `D._f1`,
  // causing promotion of `H._f1` to suppressed and causing the test to fail.
  final int? _f1;
  D(this._f1);
}

abstract class F {
  final int? _f2;
  F(this._f2);
}

class G extends A implements D {
  G(super.f1);
  @override
  noSuchMethod(_) => 0;
}

class H {
  final int? _f1;
  final int? _f2;
  H(int? i)
      : _f1 = i,
        _f2 = i;
}

testImplementedFieldSeenViaOtherLib(H h) {
  // Class `G` inherits an implmentation of `_f1` from `C` (via `B` and
  // `A`). Therefore it doesn't need a noSuchMethod forwarder for `_f1`, and
  // consequently, promotion of `H._f1` works.
  if (h._f1 != null) {
    h._f1.expectStaticType<Exactly<int>>;
  }
}

testInterfceFieldSeenViaOtherLib(H h) {
  // Class `G` inherits `_f2` into its interface from `F` (via `E` and `D`). But
  // it doesn't inherit an implementation of `_f2` from anywhere. Therefore it
  // needs a noSuchMethod forwarder for `_f2`, and consequently, promotion of
  // `H._f2` is disabled.
  if (h._f2 != null) {
    h._f2.expectStaticType<Exactly<int?>>;
  }
}

main() {
  for (var h in [H(null), H(0)]) {
    testImplementedFieldSeenViaOtherLib(h);
    testInterfceFieldSeenViaOtherLib(h);
  }
}
