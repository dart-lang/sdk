// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These tests are for an experimental feature that treats Dart primitive types
// (int, bool, double, etc.) as non-nullable. This file is not evidence for an
// intention to officially support non-nullable primitives in Dart (or general
// NNBD, for that matter) so don't get too crazy about it.

library analyzer.test.src.task.non_null_primitives.checker_test;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../strong/strong_test_helper.dart';

void main() {
  initStrongModeTests();
  defineReflectiveTests(NonNullCheckerTest);
}

String _withError(String file, String error) {
  return ("" + file).replaceFirst("boom", error);
}

@reflectiveTest
class NonNullCheckerTest {
  // Tests simple usage of ints as iterators for a loop. Not directly related to
  // non-nullability, but if it is implemented this should be more efficient,
  // since languages.length will not be null-checked on every iteration.
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

  void test_initialize_nonnullable_with_null() {
    addFile('int x = /*error:INVALID_ASSIGNMENT*/null;');
    check(nonnullableTypes: <String>['dart:core,int']);
  }

  void test_initialize_nonnullable_with_valid_value() {
    addFile('int x = 0;');
    check(nonnullableTypes: <String>['dart:core,int']);
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

  void test_nullable_fields() {
    addFile(defaultNnbdExample);
    // `null` can be passed as an argument to `Point` in default mode.
    addFile(defaultNnbdExampleMod1);
    // A nullable expression can be passed as an argument to `Point` in default
    // mode.
    addFile(defaultNnbdExampleMod2);
    check();
  }

  // Default example from NNBD document.
  void test_nullableTypes() {
    // By default x can be set to null.
    checkFile('int x = null;');
  }

  void test_prefer_final_to_non_nullable_error() {
    addFile('main() { final int /*error:FINAL_NOT_INITIALIZED*/x; }');
    addFile('final int /*error:FINAL_NOT_INITIALIZED*/x;');
    addFile('''
void foo() {}

class A {
  final int x;

  /*warning:FINAL_NOT_INITIALIZED_CONSTRUCTOR_1*/A();
}
''');
    check(nonnullableTypes: <String>['dart:core,int']);
  }

  void test_uninitialized_nonnullable_field_declaration() {
    addFile('''
void foo() {}

class A {
  // Ideally, we should allow x to be init in the constructor, but that requires
  // too much complication in the checker, so for now we throw a static error at
  // the declaration site.
  int /*error:NON_NULLABLE_FIELD_NOT_INITIALIZED*/x;

  A();
}
''');
    check(nonnullableTypes: <String>['dart:core,int']);
  }

  void test_uninitialized_nonnullable_local_variable() {
    // Ideally, we will do flow analysis and throw an error only if a variable
    // is used before it has been initialized.
    addFile('main() { int /*error:NON_NULLABLE_FIELD_NOT_INITIALIZED*/x; }');
    check(nonnullableTypes: <String>['dart:core,int']);
  }

  void test_uninitialized_nonnullable_top_level_variable_declaration() {
    // If `int`s are non-nullable, then this code should throw an error.
    addFile('int /*error:NON_NULLABLE_FIELD_NOT_INITIALIZED*/x;');
    check(nonnullableTypes: <String>['dart:core,int']);
  }
}
