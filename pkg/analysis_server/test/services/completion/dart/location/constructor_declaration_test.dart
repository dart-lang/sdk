// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorDeclarationTest);
  });
}

@reflectiveTest
class ConstructorDeclarationTest extends AbstractCompletionDriverTest
    with ConstructorDeclarationTestCases {}

mixin ConstructorDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_beforeFactory() async {
    await computeSuggestions('''
class C {
  ^factory ();
}
''');
    assertResponse(r'''
replacement
  right: 7
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => [!super.hashCode!];
    kind: override
  @override
  // TODO: implement runtimeType
  Type get runtimeType => [!super.runtimeType!];
    kind: override
  @override
  String toString() {
    // TODO: implement toString
    [!return super.toString();!]
  }
    kind: override
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    [!return super == other;!]
  }
    kind: override
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    [!return super.noSuchMethod(invocation);!]
  }
    kind: override
  final
    kind: keyword
  static
    kind: keyword
  void
    kind: keyword
  const
    kind: keyword
  set
    kind: keyword
  factory
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  new
    kind: keyword
  operator
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_beforeNew() async {
    await computeSuggestions('''
class C {
  ^new ();
}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => [!super.hashCode!];
    kind: override
  @override
  // TODO: implement runtimeType
  Type get runtimeType => [!super.runtimeType!];
    kind: override
  @override
  String toString() {
    // TODO: implement toString
    [!return super.toString();!]
  }
    kind: override
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    [!return super == other;!]
  }
    kind: override
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    [!return super.noSuchMethod(invocation);!]
  }
    kind: override
  final
    kind: keyword
  static
    kind: keyword
  void
    kind: keyword
  const
    kind: keyword
  set
    kind: keyword
  factory
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  new
    kind: keyword
  operator
    kind: keyword
  var
    kind: keyword
''');
  }

  Future<void> test_factory_noInstanceValues() async {
    await computeSuggestions('''
class A {
  A();
  factory A.n() {
    ^
    return A();
  }
  bool isEmpty = false;
}
''');
    assertNoSuggestion(completion: 'isEmpty');
  }

  Future<void> test_factory_redirectedConstructor_afterName() async {
    await computeSuggestions('''
class A {
  A.n01();
  const A.n02();

  factory A.n03() = A.^
}
''');
    assertResponse(r'''
suggestions
  n01
    kind: constructor
  n02
    kind: constructor
''');
  }

  Future<void> test_factory_redirectedConstructor_afterName_const() async {
    await computeSuggestions('''
class A {
  A.n01();
  const A.n02();

  const factory A.n03() = A.^
}
''');
    assertResponse(r'''
suggestions
  n02
    kind: constructor
''');
  }

  Future<void> test_factory_redirectedConstructor_noClassName_named() async {
    await computeSuggestions('''
class A {
  A.n01();
  factory A.n02() = ^
}
''');
    printerConfiguration.filter = (_) => true;
    assertResponse(r'''
suggestions
  A.n01
    kind: constructor
''');
  }

  Future<void> test_factory_redirectedConstructor_noClassName_unnamed() async {
    await computeSuggestions('''
class A {
  A();
  factory A.n01() = ^
}
''');
    printerConfiguration.filter = (_) => true;
    assertResponse(r'''
suggestions
  A
    kind: constructor
''');
  }

  Future<void> test_initializers_beforeInitializer() async {
    await computeSuggestions('''
class A {
  int f0;
  int f1;
  A() : ^, f1 = 1;
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: field
  assert
    kind: keyword
  this
    kind: keyword
''');
  }

  Future<void> test_initializers_first() async {
    await computeSuggestions('''
class A {
  int f0;
  int f1;
  A() : ^;
}
''');
    assertResponse(r'''
suggestions
  super
    kind: keyword
  f0
    kind: field
  f1
    kind: field
  assert
    kind: keyword
  this
    kind: keyword
''');
  }

  Future<void> test_initializers_last() async {
    await computeSuggestions('''
class A {
  int f0;
  int f1;
  A() : f0 = 1, ^;
}
''');
    assertResponse(r'''
suggestions
  super
    kind: keyword
  f1
    kind: field
  assert
    kind: keyword
  this
    kind: keyword
''');
  }

  Future<void> test_initializers_withDeclarationInitializer() async {
    await computeSuggestions('''
class A {
  int f0 = 0;
  int f1;
  A() : ^;
}
''');
    assertResponse(r'''
suggestions
  super
    kind: keyword
  f0
    kind: field
  f1
    kind: field
  assert
    kind: keyword
  this
    kind: keyword
''');
  }

  Future<void> test_initializers_withFieldFormalInitializer() async {
    await computeSuggestions('''
class A {
  int f0;
  int f1;
  A(this.f0) : ^;
}
''');
    assertResponse(r'''
suggestions
  super
    kind: keyword
  f1
    kind: field
  assert
    kind: keyword
  this
    kind: keyword
''');
  }
}
