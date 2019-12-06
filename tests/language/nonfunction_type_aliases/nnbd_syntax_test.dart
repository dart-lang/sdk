// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=nonfunction-type-aliases,non-nullable

typedef T0 = Function?;
typedef T1<X> = List<X?>?;
typedef T2<X, Y> = Map<X?, Y?>?;
typedef T3 = Never? Function(void)?;
typedef T4<X> = X? Function(X?, {required X? name})?;
typedef T5<X extends String, Y extends List<X?>> =
    X? Function(Y?, [Map<Y, Y?>]);

void main() {
  // ignore:unused_local_variable
  var ensure_usage = [T0, T1, T2, T3, T4, T5];
}
