// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  @pragma('vm:entry-point', 'init')
  final int initializedNonNullableField;
  @pragma('vm:entry-point', 'init')
  final int? initializedNullableField;
  final int defaultNonNullableFieldWithValue = 42;
  final int? implicitDefaultNullableField;
  final int noInitNonNullableField;

  external A();
}

@pragma('vm:never-inline')
void test(A a) {
  print(a.initializedNonNullableField);
  print(a.initializedNullableField);
  print(a.defaultNonNullableFieldWithValue);
  print(a.implicitDefaultNullableField);
  print(a.noInitNonNullableField);
}

void main() {
  test(A());
}
