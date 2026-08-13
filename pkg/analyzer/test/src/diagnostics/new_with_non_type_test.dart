// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewWithNonTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NewWithNonTypeTest extends PubPackageResolutionTest {
  test_functionTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics('''
typedef F = void Function();

void foo() {
  new F();
//    ^
// [diag.newWithNonType] The name 'F' isn't a class.
}
''');

    var node = result.findNode.namedType('F()');
    assertResolvedNodeText(node, r'''
NamedType
  name: F
  element: <testLibrary>::@typeAlias::F
  type: InvalidType
''');
  }

  test_imported() async {
    newFile('$testPackageLibPath/lib.dart', '''
class B {}
''');
    await resolveTestCodeWithDiagnostics('''
import 'lib.dart' as lib;
void f() {
  new lib.A();
//        ^
// [diag.newWithNonType] The name 'A' isn't a class.
}
lib.B b = lib.B();
''');
  }

  test_local() async {
    var result = await resolveTestCodeWithDiagnostics('''
var A = 0;
void f() {
  new A();
//    ^
// [diag.newWithNonType] The name 'A' isn't a class.
}
''');

    var node = result.findNode.namedType('A()');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  element: <testLibrary>::@getter::A
  type: InvalidType
''');
  }

  test_local_withTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics('''
var A = 0;
void f() {
  new A<int>();
//    ^
// [diag.newWithNonType] The name 'A' isn't a class.
}
''');

    var node = result.findNode.namedType('A<int>()');
    assertResolvedNodeText(node, r'''
NamedType
  name: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  element: <testLibrary>::@getter::A
  type: InvalidType
''');
  }

  test_malformed_constructor_call() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  C.x();
}
main() {
  new C.x.y();
//    ^^^
// [diag.newWithNonType] The name 'x' isn't a class.
}
''');
  }

  test_typeParameter() async {
    await resolveTestCodeWithDiagnostics('''
void foo<T>() {
  new T();
//    ^
// [diag.newWithNonType] The name 'T' isn't a class.
}
''');
  }
}
