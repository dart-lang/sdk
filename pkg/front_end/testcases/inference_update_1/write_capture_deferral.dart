// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when the feature is enabled, if an invocation argument is a
// closure, write captures made by that closure do not take effect until after
// the invocation.  This is a minor improvement to flow analysis that falls
// naturally out of the fact that closures are analyzed last (so that their
// types can depend on the types of other arguments).

withUnnamedArguments(int? i, void Function(void Function(), Object?) f) {
  if (i != null) {
    f(() {
      i = null;
    }, i);
    i;
  }
}

withNamedArguments(
    int? i, void Function({required void Function() g, Object? x}) f) {
  if (i != null) {
    f(
        g: () {
          i = null;
        },
        x: i);
    i;
  }
}

withIdentical_lhs(int? i) {
  if (i != null) {
    i;
    identical(() {
      i = null;
    }, i);
    i;
  }
}

withIdentical_rhs(int? i) {
  if (i != null) {
    identical(i, () {
      i = null;
    });
    i;
  }
}

class B {
  B(Object? x, void Function() g, Object? y);
  B.redirectingConstructorInvocation(int? i)
      : this(i!, () {
          i = null;
        }, i);
}

class C extends B {
  C.superConstructorInvocation(int? i)
      : super(i!, () {
          i = null;
        }, i);
}

main() {}
