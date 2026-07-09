// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int? method() => null;

late var nonNullableTopLevelField = 0;
late var nullableTopLevelField = method();

class A {
  late var nonNullableInstanceField = 0;
  late var nullableInstanceField = method();

  static late var nonNullableStaticField = 0;
  static late var nullableStaticField = method();
}

class B extends A {
  get nonNullableInstanceField => 0;
  set nonNullableInstanceField(value) {}

  get nullableInstanceField => 0;
  set nullableInstanceField(value) {}
}

main() {}
