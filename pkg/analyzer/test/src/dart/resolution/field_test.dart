// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldDeclarationResolutionTest);
  });
}

@reflectiveTest
class FieldDeclarationResolutionTest extends PubPackageResolutionTest {
  test_initializer_late_super() async {
    await assertErrorsInCode('''
class A {
  late Object f = super;
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 28, 5),
    ]);

    final node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    type: NamedType
      name: Object
      element: dart:core::@class::Object
      type: Object
    variables
      VariableDeclaration
        name: f
        equals: =
        initializer: SuperExpression
          superKeyword: super
          staticType: A
        declaredElement: self::@class::A::@field::f
  semicolon: ;
  declaredElement: <null>
''');
  }

  test_initializer_late_this() async {
    await assertNoErrorsInCode('''
class A {
  late Object f = this;
}
''');

    final node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    lateKeyword: late
    type: NamedType
      name: Object
      element: dart:core::@class::Object
      type: Object
    variables
      VariableDeclaration
        name: f
        equals: =
        initializer: ThisExpression
          thisKeyword: this
          staticType: A
        declaredElement: self::@class::A::@field::f
  semicolon: ;
  declaredElement: <null>
''');
  }

  test_initializer_notLate_field() async {
    await assertErrorsInCode('''
class A {
  final int a = 0;
  final int b = a;
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 45, 1),
    ]);

    final node = findNode.fieldDeclaration('b =');
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: final
    type: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    variables
      VariableDeclaration
        name: b
        equals: =
        initializer: SimpleIdentifier
          token: a
          staticElement: self::@class::A::@getter::a
          staticType: int
        declaredElement: self::@class::A::@field::b
  semicolon: ;
  declaredElement: <null>
''');
  }

  test_initializer_notLate_getterInvocation() async {
    await assertErrorsInCode('''
class A {
  int get a => 0;
  final int b = a;
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 44, 1),
    ]);

    final node = findNode.fieldDeclaration('b =');
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: final
    type: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    variables
      VariableDeclaration
        name: b
        equals: =
        initializer: SimpleIdentifier
          token: a
          staticElement: self::@class::A::@getter::a
          staticType: int
        declaredElement: self::@class::A::@field::b
  semicolon: ;
  declaredElement: <null>
''');
  }

  test_initializer_notLate_methodInvocation() async {
    await assertErrorsInCode('''
class A {
  int a() => 0;
  final int b = a();
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 42, 1),
    ]);

    final node = findNode.fieldDeclaration('b =');
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: final
    type: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    variables
      VariableDeclaration
        name: b
        equals: =
        initializer: MethodInvocation
          methodName: SimpleIdentifier
            token: a
            staticElement: self::@class::A::@method::a
            staticType: int Function()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: int Function()
          staticType: int
        declaredElement: self::@class::A::@field::b
  semicolon: ;
  declaredElement: <null>
''');
  }

  test_initializer_notLate_this() async {
    await assertErrorsInCode('''
class A {
  final a = this;
}
''', [
      error(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS, 22, 4),
    ]);

    final node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: final
    variables
      VariableDeclaration
        name: a
        equals: =
        initializer: ThisExpression
          thisKeyword: this
          staticType: A
        declaredElement: self::@class::A::@field::a
  semicolon: ;
  declaredElement: <null>
''');
  }

  test_session_getterSetter() async {
    await resolveTestCode('''
class A {
  var f = 0;
}
''');
    var getter = findElement.getter('f');
    expect(getter.session, result.session);

    var setter = findElement.setter('f');
    expect(setter.session, result.session);
  }

  test_type_inferred_int() async {
    await resolveTestCode('''
class A {
  var f = 0;
}
''');
    assertType(findElement.field('f').type, 'int');
  }

  test_type_inferred_Never() async {
    await resolveTestCode('''
class A {
  var f = throw 42;
}
''');
    assertType(
      findElement.field('f').type,
      typeStringByNullability(
        nullable: 'Never',
        legacy: 'dynamic',
      ),
    );
  }

  test_type_inferred_noInitializer() async {
    await resolveTestCode('''
class A {
  var f;
}
''');
    assertType(findElement.field('f').type, 'dynamic');
  }

  test_type_inferred_nonNullify() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
var a = 0;
''');

    await assertErrorsInCode('''
import 'a.dart';

class A {
  var f = a;
}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertType(findElement.field('f').type, 'int');
  }

  test_type_inferred_null() async {
    await resolveTestCode('''
class A {
  var f = null;
}
''');
    assertType(findElement.field('f').type, 'dynamic');
  }

  test_type_scope() async {
    await assertNoErrorsInCode('''
class A<T> {
  var f = <T>[];
}
''');

    final node = findNode.singleFieldDeclaration;
    assertResolvedNodeText(node, r'''
FieldDeclaration
  fields: VariableDeclarationList
    keyword: var
    variables
      VariableDeclaration
        name: f
        equals: =
        initializer: ListLiteral
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: T
                element: T@8
                type: T
            rightBracket: >
          leftBracket: [
          rightBracket: ]
          staticType: List<T>
        declaredElement: self::@class::A::@field::f
  semicolon: ;
  declaredElement: <null>
''');
  }
}
