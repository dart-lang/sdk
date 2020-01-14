// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

bool c = false;

// Test that the type produced from expression `x?.y` is nullable.
void main() {
  int? x;
  x?.bitLength + 1; //# 01: compile-time error
  x?.round(2) + 1; //# 02: compile-time error
}

// Ensure it works correctly on type parameters
void f<T extends num>(Generic<T>? generic, Generic<T?> nullableGeneric) {
  generic?.getter + 1; //# 03: compile-time error
  generic?.method() + 1; //# 04: compile-time error
  generic?.nullableGetter + 1; //# 05: compile-time error
  generic?.nullableMethod() + 1; //# 06: compile-time error
  nullableGeneric?.getter + 1; //# 07: compile-time error
  nullableGeneric?.method() + 1; //# 08: compile-time error
  nullableGeneric?.nullableGetter + 1; //# 09: compile-time error
  nullableGeneric?.nullableMethod() + 1; //# 10: compile-time error
}

class Generic<T> {
  T get getter => throw Exception('unreachable');
  T method() => throw Exception('unreachable');
  T? nullableGetter = null;
  T? nullableMethod() => null;
}
