// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int nonNullableField = 0;
  int? nullableField;
  int operator [](int key) => key;
  void operator []=(int key, int value) {}
  Class get nonNullableClass => this;
  Class call() => this;
  NullableIndexClass get nonNullableNullableIndexClass => NullableIndexClass();
}

class NullableIndexClass {
  int? operator [](int key) => key;
  void operator []=(int key, int value) {}
}

main() {}

errors(Class? nullableClass, Class nonNullableClass, int? nullableInt,
    int nonNullableInt, NullableIndexClass? nullableNullableIndexClass) {
  -nullableInt; // error
  nullableInt + 2; // error
  nullableClass[nonNullableInt]; // error
  nullableClass[nonNullableInt] = nonNullableInt; // error
  nullableClass[nonNullableInt] += nonNullableInt; // error
  nullableNullableIndexClass[nonNullableInt] ??= nonNullableInt; // error

  nullableClass?.nonNullableClass[nonNullableInt]; // ok
  nullableClass?.nonNullableClass[nonNullableInt] = nonNullableInt; // ok
  nullableClass?.nonNullableClass[nonNullableInt] += nonNullableInt; // ok
  nullableClass?.nonNullableNullableIndexClass[nonNullableInt] ??=
      nonNullableInt; // ok

  nullableClass.nonNullableField; // error
  nullableClass.nonNullableField = 2; // error
  nullableClass.nonNullableField += 2; // error

  nullableClass?.nonNullableField; // ok
  nullableClass?.nonNullableField = 2; // ok
  nullableClass?.nonNullableField += 2; // ok

  nullableClass?.nonNullableClass.nonNullableField; // ok
  nullableClass?.nonNullableClass.nonNullableField = 2; // ok

  nonNullableClass.nullableField += 2; // error
  nullableClass?.nullableField += 2; // error

  nullableClass?.nonNullableField ??= 0; // ok
  nullableClass?.nullableField ??= 0; // ok

  nullableClass?.nonNullableClass.nonNullableField ??= 0; // ok
  nullableClass?.nonNullableClass.nullableField ??= 0; // ok

  nullableClass(); // error
  nonNullableClass(); // ok
  nonNullableClass?.nonNullableClass(); // ok
  nonNullableClass?.nonNullableClass.nonNullableClass(); // ok
}
