// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

typedef T1 = void Function<T>(T);
typedef T2 = void Function(void Function<T>(T));
typedef T3 = List<void Function<T>(T)>;
typedef T4<X extends void Function<T>(T)> = Class<X>;

test(
  T1 t1, // Ok
  T1 t2, // Ok
  T3 t3, // Ok
) {
  new T4(); // Ok
}
