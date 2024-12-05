// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.5

import '../../static_type_helper.dart';

class A<X extends Iterable<Y>, Y> {
  A(X x);
  Y? y;
}

main() {
  // Inferred as A<List<num>, dynamic>.
  A(<num>[])
    ..y = "ok"
    ..expectStaticType<Exactly<A<List<num>, dynamic>>>();
}
