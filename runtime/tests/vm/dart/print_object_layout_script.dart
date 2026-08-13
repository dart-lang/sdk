// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test script for print_object_layout_test.dart

class ClassA {
  String fieldA1 = 'a';
  int fieldA2 = 1;
}

class ClassB extends ClassA {
  String fieldB1 = 'b';
  int fieldB2 = 2;
  int unusedB3 = 3;
  static int staticB4 = 4;
}

@pragma('vm:never-inline')
useFields(ClassB obj) =>
    "${obj.fieldA1}${obj.fieldA2}${obj.fieldB1}${obj.fieldB2}${ClassB.staticB4}";

main() {
  useFields(ClassB());
}
