// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These tests are for an experimental feature that treats Dart primitive types
// (int, bool, double, etc.) as non-nullable. This file is not evidence for an
// intention to officially support non-nullable primitives in Dart (or general
// NNBD, for that matter) so don't get too crazy about it.

library analyzer.test.src.task.non_null_primitives.checker_test;

import '../../../reflective_tests.dart';
import '../strong/strong_test_helper.dart';

void main() {
  initStrongModeTests();
  runReflectiveTests(NonNullCheckerTest);
}

@reflectiveTest
class NonNullCheckerTest {
  // Tests simple usage of ints as iterators for a loop. Not directly related to
  // non-nullability, but if it is implemented this should be more efficient,
  // since languages.length will not be null-checked on every iteration.
  void test_forLoop() {
    checkFile('''
class MyList {
  int length;
  MyList() {
    length = 6;
  }
  String operator [](int i) {
    return <String>["Dart", "Java", "JS", "C", "C++", "C#"][i];
  }
}

main() {
  var languages = new MyList();
  for (int i = 0; i < languages.length; ++i) {
    print(languages[i]);
  }
}
''');
  }

  void test_nullableTypes() {
    // By default x can be set to null.
    checkFile('int x = null;');
  }

  void test_nonnullableTypes() {
    // If `int`s are non-nullable, then this code should throw an error.
    addFile('int x;');
    addFile('int x = /*error:INVALID_ASSIGNMENT*/null;');
    addFile('int x = 0;');
    addFile('''
int x = 0;

main() {
  x = 1;
  x = /*error:INVALID_ASSIGNMENT*/null;
}
''');
    check(nonnullableTypes: <String>['dart:core,int']);
  }
}
