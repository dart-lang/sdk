// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that type arguments in function types contain the correct nullability
/// after tearing them off.

import 'package:expect/expect.dart';

typedef voidToNullableInt = int? Function();
typedef nullableSToVoid = void Function<S>(S?);
typedef voidToNullableS = S? Function<S>();

class A<T> {
  T? fn() => null;
  void gn<S>(S? param) {}
  S? hn<S>() => null;
}

main() {
  var a = A<int>();
  Expect.equals(voidToNullableInt, a.fn.runtimeType);
  Expect.equals(nullableSToVoid, a.gn.runtimeType);
  Expect.equals(voidToNullableS, a.hn.runtimeType);
}
