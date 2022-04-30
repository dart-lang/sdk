// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when the feature is enabled, if an invocation argument is a
// closure, write captures made by that closure do not take effect until after
// the invocation.  This is a minor improvement to flow analysis that falls
// naturally out of the fact that closures are analyzed last (so that their
// types can depend on the types of other arguments).

// SharedOptions=--enable-experiment=inference-update-1

import '../static_type_helper.dart';

withUnnamedArguments(int? i, void Function(void Function(), Object?) f) {
  if (i != null) {
    f(() {
      i = null;
    }, i..expectStaticType<Exactly<int>>());
    i..expectStaticType<Exactly<int?>>();
  }
}

withUnnamedArgumentsParenthesized(
    int? i, void Function(void Function(), Object?) f) {
  if (i != null) {
    f((() {
      i = null;
    }), i..expectStaticType<Exactly<int>>());
    i..expectStaticType<Exactly<int?>>();
  }
}

withUnnamedArgumentsParenthesizedTwice(
    int? i, void Function(void Function(), Object?) f) {
  if (i != null) {
    f(((() {
      i = null;
    })), i..expectStaticType<Exactly<int>>());
    i..expectStaticType<Exactly<int?>>();
  }
}

withNamedArguments(
    int? i, void Function({required void Function() g, Object? x}) f) {
  if (i != null) {
    f(
        g: () {
          i = null;
        },
        x: i..expectStaticType<Exactly<int>>());
    i..expectStaticType<Exactly<int?>>();
  }
}

withNamedArgumentsParenthesized(
    int? i, void Function({required void Function() g, Object? x}) f) {
  if (i != null) {
    f(
        g: (() {
          i = null;
        }),
        x: i..expectStaticType<Exactly<int>>());
    i..expectStaticType<Exactly<int?>>();
  }
}

withNamedArgumentsParenthesizedTwice(
    int? i, void Function({required void Function() g, Object? x}) f) {
  if (i != null) {
    f(
        g: ((() {
          i = null;
        })),
        x: i..expectStaticType<Exactly<int>>());
    i..expectStaticType<Exactly<int?>>();
  }
}

withIdentical_lhs(int? i) {
  if (i != null) {
    i..expectStaticType<Exactly<int>>();
    identical(() {
      i = null;
    }, i..expectStaticType<Exactly<int>>());
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
        }, i..expectStaticType<Exactly<int>>());
}

class C extends B {
  C.superConstructorInvocation(int? i)
      : super(i!, () {
          i = null;
        }, i..expectStaticType<Exactly<int>>());
}

main() {}
