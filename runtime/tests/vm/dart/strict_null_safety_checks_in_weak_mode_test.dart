// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that with --strict_null_safety_checks runtime casts and
// required parameters have strong mode semantics in weak mode.
// Derived from tests/language/nnbd/subtyping/type_casts_strong_test.dart
// and tests/language/nnbd/required_named_parameters/required_named_args_strong_test.dart.

// VMOptions=--strict_null_safety_checks --optimization_counter_threshold=10 --deterministic
// Requirements=nnbd-weak

import 'package:expect/expect.dart';

class C {}

class W<T> {
  @pragma('vm:never-inline')
  asT(arg) => arg as T;

  @pragma('vm:never-inline')
  asNullableT(arg) => arg as T?;

  @pragma('vm:never-inline')
  asXT(arg) => arg as X<T>;

  @pragma('vm:never-inline')
  asNullableXT(arg) => arg as X<T>?;

  @pragma('vm:never-inline')
  asXNullableT(arg) => arg as X<T?>;
}

class X<T> {}

class Y {}

class Z extends Y {}

testCasts() {
  // Testing 'arg as T', T = Y
  final wy = new W<Y>();
  wy.asT(new Y());
  wy.asT(new Z());
  Expect.throwsTypeError(() {
    wy.asT(null);
  });
  Expect.throwsTypeError(() {
    wy.asT(new C());
  });

  // Testing 'arg as T?', T = Y
  wy.asNullableT(new Y());
  wy.asNullableT(new Z());
  wy.asNullableT(null);
  Expect.throwsTypeError(() {
    wy.asNullableT(new C());
  });

  // Testing 'arg as X<T>', T = Y
  wy.asXT(new X<Y>());
  wy.asXT(new X<Z>());
  Expect.throwsTypeError(() {
    wy.asXT(null);
  });
  Expect.throwsTypeError(() {
    wy.asXT(new X<dynamic>());
  });
  Expect.throwsTypeError(() {
    wy.asXT(new X<Y?>());
  });

  // Testing 'arg as X<T>?', T = Y
  wy.asNullableXT(new X<Y>());
  wy.asNullableXT(new X<Z>());
  wy.asNullableXT(null);
  Expect.throwsTypeError(() {
    wy.asNullableXT(new X<dynamic>());
  });
  Expect.throwsTypeError(() {
    wy.asNullableXT(new X<Y?>());
  });

  // Testing 'arg as X<T?>', T = Y
  wy.asXNullableT(new X<Y>());
  wy.asXNullableT(new X<Z>());
  wy.asXNullableT(new X<Y?>());
  Expect.throwsTypeError(() {
    wy.asXNullableT(null);
  });
  Expect.throwsTypeError(() {
    wy.asXNullableT(new X<dynamic>());
  });

  // Testing 'arg as X<T>', T = Y?
  final wny = new W<Y?>();
  wny.asXT(new X<Y>());
  wny.asXT(new X<Z>());
  wny.asXT(new X<Y?>());
  Expect.throwsTypeError(() {
    wny.asXT(null);
  });
  Expect.throwsTypeError(() {
    wny.asXT(new X<dynamic>());
  });
}

func(String q0, {bool p3 = false, required int p1, required String p2}) => "";

testRequiredParameters() {
  dynamic f = func;

  // Invalid: Subtype may not redeclare optional parameters as required.
  Expect.throwsTypeError(() {
    Function(
      String p0, {
      required int p1,
      String p2,
    }) t2 = f;
  });

  // Invalid: Subtype may not declare new required named parameters.
  Expect.throwsTypeError(() {
    Function(
      String p0, {
      required int p1,
    }) t3 = f;
  });

  // Invalid: Invocation with explicit null required named argument.
  Expect.throwsTypeError(() {
    f("", p1: null, p2: null);
  });
  Expect.throwsTypeError(() {
    Function.apply(f, [""], {#p1: null, #p2: null});
  });

  // Invalid: Invocation that omits a required named argument.
  Expect.throwsNoSuchMethodError(() {
    f("", p1: 100);
  });
  Expect.throwsNoSuchMethodError(() {
    Function.apply(f, [""], {#p1: 100});
  });
}

main() {
  for (int i = 0; i < 20; ++i) {
    testCasts();
    testRequiredParameters();
  }
}
