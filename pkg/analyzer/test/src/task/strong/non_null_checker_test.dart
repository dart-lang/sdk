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

  void test_uninitialized_nonnullable() {
    // If `int`s are non-nullable, then this code should throw an error.
    addFile('int x;');
    check(nonnullableTypes: <String>['dart:core,int']);
  }

  void test_initialize_nonnullable_with_null() {
    addFile('int x = /*error:INVALID_ASSIGNMENT*/null;');
    check(nonnullableTypes: <String>['dart:core,int']);
  }

  void test_initialize_nonnullable_with_valid_value() {
    addFile('int x = 0;');
    check(nonnullableTypes: <String>['dart:core,int']);
  }

  void test_assign_null_to_nonnullable() {
    addFile('''
int x = 0;

main() {
  x = 1;
  x = /*error:INVALID_ASSIGNMENT*/null;
}
''');
    check(nonnullableTypes: <String>['dart:core,int']);
  }

  // Default example from NNBD document.
  final String defaultNnbdExample = '''
class Point {
  final int x, y;
  Point(this.x, this.y);
  Point operator +(Point other) => new Point(x + other.x, y + other.y);
  String toString() => "x: \$x, y: \$y";
}

void main() {
  Point p1 = new Point(0, 0);
  Point p2 = new Point(10, 10);
  print("p1 + p2 = \${p1 + p2}");
}
''';

  final String defaultNnbdExampleMod1 = '''
class Point {
  final int x, y;
  Point(this.x, this.y);
  Point operator +(Point other) => new Point(x + other.x, y + other.y);
  String toString() => "x: \$x, y: \$y";
}

void main() {
  Point p1 = new Point(0, 0);
  Point p2 = new Point(10, /*boom*/null); // Change here.
  print("p1 + p2 = \${p1 + p2}");
}
''';

  final String defaultNnbdExampleMod2 = '''
class Point {
  final int x, y;
  Point(this.x, this.y);
  Point operator +(Point other) => new Point(x + other.x, y + other.y);
  String toString() => "x: \$x, y: \$y";
}

void main() {
  bool f = false; // Necessary, because dead code is otherwise detected.
  Point p1 = new Point(0, 0);
  Point p2 = new Point(10, /*boom*/f ? 10 : null); // Change here.
  print("p1 + p2 = \${p1 + p2}");
}
''';

  void test_nullable_fields() {
    addFile(defaultNnbdExample);
    // `null` can be passed as an argument to `Point` in default mode.
    addFile(defaultNnbdExampleMod1);
    // A nullable expression can be passed as an argument to `Point` in default
    // mode.
    addFile(defaultNnbdExampleMod2);
    check();
  }

  void test_nonnullable_fields() {
    addFile(defaultNnbdExample);
    // `null` can be passed as an argument to `Point` in default mode.
    addFile(_withError(defaultNnbdExampleMod1, "error:INVALID_ASSIGNMENT"));
    // A nullable expression can be passed as an argument to `Point` in default
    // mode.
    addFile(_withError(defaultNnbdExampleMod2, "error:INVALID_ASSIGNMENT"));
    check(nonnullableTypes: <String>['dart:core,int']);
  }
}

String _withError(String file, String error) {
  return ("" + file).replaceFirst("boom", error);
}
