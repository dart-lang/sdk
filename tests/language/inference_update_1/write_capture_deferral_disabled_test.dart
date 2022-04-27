// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when the feature is disabled, if an invocation argument is a
// closure, write captures made by that closure take effect immediately after
// the closure is visited

// @dart=2.17

import '../static_type_helper.dart';

withUnnamedArguments(
    int? i, void Function(Object?, void Function(), Object?) f) {
  if (i != null) {
    f(i..expectStaticType<Exactly<int>>(), () {
      i = null;
    }, i..expectStaticType<Exactly<int?>>());
    i..expectStaticType<Exactly<int?>>();
  }
}

withNamedArguments(int? i,
    void Function({Object? x, required void Function() g, Object? y}) f) {
  if (i != null) {
    f(
        x: i..expectStaticType<Exactly<int>>(),
        g: () {
          i = null;
        },
        y: i..expectStaticType<Exactly<int?>>());
    i..expectStaticType<Exactly<int?>>();
  }
}

withIdentical_lhs(int? i) {
  if (i != null) {
    i..expectStaticType<Exactly<int>>();
    identical(() {
      i = null;
    }, i..expectStaticType<Exactly<int?>>());
    i..expectStaticType<Exactly<int?>>();
  }
}

withIdentical_rhs(int? i) {
  if (i != null) {
    identical(i..expectStaticType<Exactly<int>>(), () {
      i = null;
    });
    i..expectStaticType<Exactly<int?>>();
  }
}

class B {
  B(Object? x, void Function() g, Object? y);
  B.redirectingConstructorInvocation(int? i)
      : this(i!, () {
          i = null;
        }, i..expectStaticType<Exactly<int?>>());
}

class C extends B {
  C.superConstructorInvocation(int? i)
      : super(i!, () {
          i = null;
        }, i..expectStaticType<Exactly<int?>>());
}

main() {}
