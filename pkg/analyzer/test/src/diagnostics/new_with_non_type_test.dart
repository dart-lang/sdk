// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewWithNonTypeTest);
  });
}

@reflectiveTest
class NewWithNonTypeTest extends PubPackageResolutionTest {
  test_functionTypeAlias() async {
    await assertErrorsInCode(
      '''
typedef F = void Function();

void foo() {
  new F();
}
''',
      [error(CompileTimeErrorCode.newWithNonType, 49, 1)],
    );

    var node = findNode.namedType('F()');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element2: <testLibrary>::@typeAlias::F
  type: InvalidType
''');
  }

  test_imported() async {
    newFile('$testPackageLibPath/lib.dart', '''
class B {}
''');
    await assertErrorsInCode(
      '''
import 'lib.dart' as lib;
void f() {
  new lib.A();
}
lib.B b = lib.B();
''',
      [error(CompileTimeErrorCode.newWithNonType, 47, 1)],
    );
  }

  test_local() async {
    await assertErrorsInCode(
      '''
var A = 0;
void f() {
  new A();
}
''',
      [error(CompileTimeErrorCode.newWithNonType, 28, 1)],
    );

    var node = findNode.namedType('A()');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element2: <testLibrary>::@getter::A
  type: InvalidType
''');
  }

  test_local_withTypeArguments() async {
    await assertErrorsInCode(
      '''
var A = 0;
void f() {
  new A<int>();
}
''',
      [error(CompileTimeErrorCode.newWithNonType, 28, 1)],
    );

    var node = findNode.namedType('A<int>()');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  element2: <testLibrary>::@getter::A
  type: InvalidType
''');
  }

  test_malformed_constructor_call() async {
    await assertErrorsInCode(
      '''
class C {
  C.x();
}
main() {
  new C.x.y();
}
''',
      [error(CompileTimeErrorCode.newWithNonType, 36, 3)],
    );
  }

  test_typeParameter() async {
    await assertErrorsInCode(
      '''
void foo<T>() {
  new T();
}
''',
      [error(CompileTimeErrorCode.newWithNonType, 22, 1)],
    );
  }
}
