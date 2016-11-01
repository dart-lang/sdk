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
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullCheckerTest);
  });
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

  void setUp() {
    doSetUp();
  }

  void tearDown() {
    doTearDown();
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

  void test_compoundAssignment() {
    addFile('''
void main() {
  int i = 1;
  i += 2;
  /*error:INVALID_ASSIGNMENT*/i += null;
  print(i);
}
''');
    check(nonnullableTypes: <String>['dart:core,int']);
  }

  void test_forEach() {
    addFile('''
void main() {
  var ints = <num>[1, 2, 3, null];
  for (int /*error:INVALID_ASSIGNMENT*/i in ints) {
    print(i);
  }
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

  void test_generics() {
    addFile('''
class Foo<T> {
  T x;

  Foo(this.x);
}

void main() {
  var f = new Foo<String>("hello");
  var g = new Foo<int>(10);
  var h = new Foo<String>(null);
  var i = new Foo<int>(/*error:INVALID_ASSIGNMENT*/null);

  print(f.x);
  print(g.x);
  print(h.x);
  print(i.x);
}
''');
    addFile('''
class Foo<T> {
  T x; // Should be annotated for a runtime check: x = (null as T)

  Foo();
}

void main() {
  var f = new Foo<String>();
  var g = new Foo<int>(); // Should fail at runtime.
}
''');
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

  void test_map() {
    addFile('''
class Pair<K, V> {
  K first;
  V second;

  Pair(this.first, this.second);
}

class SlowMap<K, V> {
  List<Pair<K, V>> array;
  int arrayLength = 0;

  SlowMap() : array = <Pair<K, V>>[];

  void insert(K key, V value) {
    array.add(new Pair<K, V>(key, value));
    ++arrayLength;
  }

  bool has(K key) {
    for (int i = 0; i < arrayLength; ++i) {
      if (array[i].first == key) {
        return true;
      }
    }
    return false;
  }

  V get(K key) {
    for (int i = 0; i < arrayLength; ++i) {
      if (array[i].first == key) {
        return array[i].second;
      }
    }
    return null;
    // TODO(stanm): generate explicit cast to V which will produce a runtime
    // error if V is non-nullable. Optionally, generate a static warning too.
  }
}

void main() {
  var legs = new SlowMap<String, int>();
  legs.insert("spider", 8);
  legs.insert("goat", 4);
  legs.insert("chicken", 2);

  int x = legs.get("goat"); // This should not produce an error.
  int y = legs.get("sheep"); // TODO(stanm): Runtime error here.
}
''');
    check(nonnullableTypes: <String>['dart:core,int']);
  }

  // Default example from NNBD document.
  void test_method_call() {
    addFile('''
int s(int x) {
  return x + 1;
}

void main() {
  s(10);
  s(/*error:INVALID_ASSIGNMENT*/null);
}
''');
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
