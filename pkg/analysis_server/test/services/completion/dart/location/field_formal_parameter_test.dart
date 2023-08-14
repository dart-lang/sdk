// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldFormalParameterTest1);
    defineReflectiveTests(FieldFormalParameterTest2);
  });
}

@reflectiveTest
class FieldFormalParameterTest1 extends AbstractCompletionDriverTest
    with SuperFormalParameterTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class FieldFormalParameterTest2 extends AbstractCompletionDriverTest
    with SuperFormalParameterTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin SuperFormalParameterTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) => true,
      withReturnType: true,
    );
  }

  Future<void> test_class_replacement_left() async {
    await _checkContainers(
      declarations: 'var foo = 0;',
      constructorParameters: 'this.f^',
      validator: () {
        assertResponse(r'''
replacement
  left: 1
suggestions
  foo
    kind: field
    returnType: int
''');
      },
    );
  }

  Future<void> test_class_replacement_right() async {
    await _checkContainers(
      declarations: 'var foo = 0;',
      constructorParameters: 'this.^f',
      validator: () {
        assertResponse(r'''
replacement
  right: 1
suggestions
  foo
    kind: field
    returnType: int
''');
      },
    );
  }

  Future<void> test_class_suggestions_instanceFields_local() async {
    await computeSuggestions('''
class A {
  static final superStatic = 0;
  var inherited = 0;

  void superMethod() {}
  int get superGetter => 0;
  void superSetter(int _) {}
}

class B extends A {
  static final thisStatic = 0;

  var first = 0;
  var second = 1.2;

  B(this.^);
  B.otherConstructor() {}

  void thisMethod() {}
  int get thisGetter => 0;
  void thisSetter(int _) {}
}
''');

    assertResponse(r'''
suggestions
  first
    kind: field
    returnType: int
  second
    kind: field
    returnType: double
''');
  }

  Future<void> test_class_suggestions_onlyNotSpecified_optionalNamed() async {
    await _checkContainers(
      declarations: 'final int x; final int y;',
      constructorParameters: '{this.x, this.^}',
      validator: () {
        assertResponse(r'''
suggestions
  y
    kind: field
    returnType: int
''');
      },
    );
  }

  Future<void>
      test_class_suggestions_onlyNotSpecified_requiredPositional() async {
    await _checkContainers(
      declarations: 'final int x; final int y;',
      constructorParameters: 'this.x, this.^',
      validator: () {
        assertResponse(r'''
suggestions
  y
    kind: field
    returnType: int
''');
      },
    );
  }

  Future<void> test_enum_suggestions_instanceFields() async {
    await computeSuggestions('''
enum E {
  v();

  static final zero = 0;
  final int first;
  final double second;

  E(this.^);
  E.otherConstructor();

  void myMethod() {}
  int get myGetter => 0;
  void mySetter(int _) {}
}
''');

    assertResponse(r'''
suggestions
  first
    kind: field
    returnType: int
  second
    kind: field
    returnType: double
''');
  }

  Future<void> _checkContainers({
    required String declarations,
    required String constructorParameters,
    required void Function() validator,
  }) async {
    // class
    {
      await computeSuggestions('''
class A {
  $declarations
  A($constructorParameters);
}
''');
      validator();
    }
    // enum
    {
      await computeSuggestions('''
enum E {
  v;
  $declarations
  E($constructorParameters);
}
''');
      validator();
    }
  }
}
