// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericFunctionTypeResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class GenericFunctionTypeResolutionTest extends PubPackageResolutionTest {
  /// Test that when [GenericFunctionType] is used in a constant variable
  /// initializer, analysis does not throw an exception; and that the next
  /// [GenericFunctionType] is also handled correctly.
  test_constInitializer_field_static_const() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  const A();
}

class B {
  static const x = const A<bool Function()>();
}

int Function(int a)? y;
''');
  }

  /// Test that when [GenericFunctionType] is used in a constant variable
  /// initializer, analysis does not throw an exception; and that the next
  /// [GenericFunctionType] is also handled correctly.
  test_constInitializer_topLevel() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  const A();
}

const x = const A<bool Function()>();

int Function(int a)? y;
''');
  }

  test_element_enclosingElement() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(
  void Function() a,
) {}
''');

    var node = result.findNode.singleGenericFunctionType;
    var element = node.declaredFragment!.element;
    expect(element.enclosingElement, same(result.libraryElement));
  }

  test_metadata_typeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const a = 42;

Function<@a T>()? x;
''');

    var node = result.findNode.typeParameter('T');
    assertResolvedNodeText(node, r'''
TypeParameter
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: a
        element: <testLibrary>::@getter::a
        staticType: null
      element: <testLibrary>::@getter::a
  name: T
  declaredFragment: <testLibraryFragment> T@27
    defaultType: null
''');
  }

  /// Test that when multiple [GenericFunctionType]s are used in a
  /// [FunctionDeclaration], all of them are resolved correctly.
  test_typeAnnotation_function() async {
    var result = await resolveTestCodeWithDiagnostics('''
void Function()? f<T extends bool Function()>(int Function() a) {
  return null;
}

double Function()? x;
''');
    assertType(
      result.findNode.genericFunctionType('void Function()?'),
      'void Function()?',
    );
    assertType(
      result.findNode.genericFunctionType('bool Function()'),
      'bool Function()',
    );
    assertType(
      result.findNode.genericFunctionType('int Function()'),
      'int Function()',
    );
    assertType(
      result.findNode.genericFunctionType('double Function()?'),
      'double Function()?',
    );
  }

  /// Test that when multiple [GenericFunctionType]s are used in a
  /// [FunctionDeclaration], the one in the return type is consumed before the
  /// one in the parameter type. This is necessary because matching of
  /// [GenericFunctionType] nodes to their elements is based on the sequential
  /// identifier of a node in the unit.
  test_typeAnnotation_function_returnType_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
void Function(E a) f<E>(void Function() b) {
  return (_) {};
}
''');
  }

  /// Test that when multiple [GenericFunctionType]s are used in a
  /// [GenericFunctionType], all of them are resolved correctly.
  test_typeAnnotation_genericFunctionType() async {
    await resolveTestCodeWithDiagnostics('''
void f(
  void Function() a,
  bool Function() Function(int Function()) b,
) {}
''');
  }

  /// Test that when multiple [GenericFunctionType]s are used in a
  /// [FunctionDeclaration], all of them are resolved correctly.
  test_typeAnnotation_method() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  void Function()? m<T extends bool Function()>(int Function() a) {
    return null;
  }
}

double Function()? x;
''');
    assertType(
      result.findNode.genericFunctionType('void Function()?'),
      'void Function()?',
    );
    assertType(
      result.findNode.genericFunctionType('bool Function()'),
      'bool Function()',
    );
    assertType(
      result.findNode.genericFunctionType('int Function()'),
      'int Function()',
    );
    assertType(
      result.findNode.genericFunctionType('double Function()?'),
      'double Function()?',
    );
  }

  /// Test that when multiple [GenericFunctionType]s are used in a
  /// [MethodDeclaration], the one in the return type is consumed before the
  /// one in the parameter type. This is necessary because matching of
  /// [GenericFunctionType] nodes to their elements is based on the sequential
  /// identifier of a node in the unit.
  test_typeAnnotation_method_returnType_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  void Function(E a) f<E>(void Function() b) {
    return (_) {};
  }
}
''');
  }
}
