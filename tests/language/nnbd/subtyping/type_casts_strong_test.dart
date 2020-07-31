// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --deterministic

// Requirements=nnbd-strong

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

doTests() {
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

main() {
  for (int i = 0; i < 20; ++i) {
    doTests();
  }
}
