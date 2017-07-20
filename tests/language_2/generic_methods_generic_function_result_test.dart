// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--generic-method-syntax,--error-on-bad-type

// Verify that function type parameter S can be resolved in bar.

import "package:expect/expect.dart";

T foo<T extends num>(int i, T t) => i + t;

List<T Function<T extends num>(S, T)> bar<S extends int>() {
  return <T Function<T extends num>(S, T)>[foo, foo];
}

void main() {
  var list = bar<int>();
  print(list[0]
      .runtimeType); // "<T extends num>(int, T) => T" when reifying generic functions.
  Expect.equals(123, list[1]<int>(100, 23));
}
