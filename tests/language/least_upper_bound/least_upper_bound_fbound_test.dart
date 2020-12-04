// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../static_type_helper.dart';

// Test least upper bound for a type variable with an F-bound.

bool condition = true;

class A<X extends A<X, X>?, Y extends A<Y, Y>?> {
  X x;
  late Y y;

  A(this.x);

  void m(X x, Y y) {
    // UP(X extends A<X, X>?, Y extends A<Y, Y>?) ==
    // A<Object?, Object?>?.
    var z = condition ? x : y;
    z.expectStaticType<Exactly<A<Object?, Object?>?>>();

    // Distinguish top types.
    if (z == null) throw 0;
    var zx = z.x, zy = z.y;

    // Not `dynamic`, not `void`.
    zx?.whatever;
    //  ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'whatever' isn't defined for the class 'Object'.
    zy?.whatever;
    //  ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'whatever' isn't defined for the class 'Object'.

    if (zx == null || zy == null) throw 0;
    zx.expectStaticType<Exactly<Object>>();
    zy.expectStaticType<Exactly<Object>>();
  }
}

class B<X> extends A<B<X>?, B<X>?> {
  B() : super(null);
}

void main() {
  var b = B<Null>();
  b.m(b, null);
}
