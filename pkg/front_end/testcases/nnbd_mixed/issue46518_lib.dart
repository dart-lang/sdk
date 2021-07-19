// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef NullableIntF = int? Function();

void _check(Type t1, Type t2) {
  print("Opted in: identical($t1, $t2) == ${identical(t1, t2)}");
  print("Opted in: ($t1 == $t2) == ${t1 == t2}");
}

void checkOptedIn(Type t) {
  _check(t, NullableIntF);
}
