// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --deterministic

// Requirements=nnbd-strong

import 'package:expect/expect.dart';
import 'type_casts_legacy_library.dart'; // A, B, C, D
import 'type_casts_null_safe_library.dart'; // W, X, Y, Z

doTests() {
  // Testing 'arg as T*', T = C*
  final ac = newAOfLegacyC();
  ac.asT(new C());
  ac.asT(new D());
  ac.asT(null);
  Expect.throwsTypeError(() {
    ac.asT(new Y());
  });

  // Testing 'arg as T*', T = B<C*>*
  final abc = newAOfLegacyBOfLegacyC();
  abc.asT(new B<C>());
  abc.asT(new B<D>());
  abc.asT(null);
  Expect.throwsTypeError(() {
    abc.asT(new B<dynamic>());
  });
  Expect.throwsTypeError(() {
    abc.asT(new B<Y>());
  });

  // Testing 'arg as T*', T = Y
  final ay = new A<Y>();
  ay.asT(new Y());
  ay.asT(new Z());
  ay.asT(null);
  Expect.throwsTypeError(() {
    ay.asT(new C());
  });

  // Testing 'arg as T', T = C*
  final wc = newWOfLegacyC();
  wc.asT(new C());
  wc.asT(new D());
  wc.asT(null);
  Expect.throwsTypeError(() {
    wc.asT(new Y());
  });

  // Testing 'arg as T?', T = C*
  wc.asNullableT(new C());
  wc.asNullableT(new D());
  wc.asNullableT(null);
  Expect.throwsTypeError(() {
    wc.asNullableT(new Y());
  });

  // Testing 'arg as T', T = B<C*>*
  final wby = newWOfLegacyBOfLegacyC();
  wby.asT(new B<C>());
  wby.asT(new B<D>());
  wby.asT(null);
  Expect.throwsTypeError(() {
    wby.asT(new B<dynamic>());
  });
  Expect.throwsTypeError(() {
    wby.asT(new B<Y>());
  });

  // Testing 'arg as T?', T = B<C*>*
  wby.asNullableT(new B<C>());
  wby.asNullableT(new B<D>());
  wby.asNullableT(null);
  Expect.throwsTypeError(() {
    wby.asNullableT(new B<dynamic>());
  });
  Expect.throwsTypeError(() {
    wby.asNullableT(new B<Y>());
  });

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

  // Testing 'arg as B<T*>*', T = Y
  ay.asBT(new B<Y>());
  ay.asBT(new B<Z>());
  ay.asBT(null);
  Expect.throwsTypeError(() {
    ay.asBT(new B<dynamic>());
  });
  Expect.throwsTypeError(() {
    ay.asBT(new B<C>());
  });

  // Testing 'arg as X<T>', T = Y
  wy.asXT(new X<Y>());
  wy.asXT(new X<Z>());
  wy.asXT(newXOfLegacyY());
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
  wy.asNullableXT(newXOfLegacyY());
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
  wy.asXNullableT(newXOfLegacyY());
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
  wny.asXT(newXOfLegacyY());
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
