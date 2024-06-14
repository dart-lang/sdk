// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimpleIdentifierResolutionTest);
  });
}

@reflectiveTest
class SimpleIdentifierResolutionTest extends PubPackageResolutionTest {
  test_augment_topLevel_function_with_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment void foo() {}
''');

    await assertNoErrorsInCode('''
import augment 'a.dart';

void foo() {}

void f() {
  foo;
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: self::@augmentation::package:test/a.dart::@functionAugmentation::foo
  staticType: void Function()
''');
  }

  test_augment_topLevel_getter_with_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment int get foo => 1;
''');

    await assertNoErrorsInCode('''
import augment 'a.dart';

int get foo => 0;

void f() {
  foo;
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: self::@augmentation::package:test/a.dart::@getterAugmentation::foo
  staticType: int
''');
  }

  test_augment_topLevel_setter_with_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment set foo(int _) {}
''');

    await assertNoErrorsInCode('''
import augment 'a.dart';

set foo(int _) {}

void f() {
  foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@augmentation::package:test/a.dart::@setterAugmentation::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@augmentation::package:test/a.dart::@setterAugmentation::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_augment_topLevel_variable_with_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment int get foo() => 1;
''');

    await assertNoErrorsInCode('''
import augment 'a.dart';

int foo = 0;

void f() {
  foo;
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: self::@augmentation::package:test/a.dart::@getterAugmentation::foo
  staticType: int
''');
  }

  test_augment_topLevel_variable_with_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment int foo = 1;
''');

    await assertNoErrorsInCode('''
import augment 'a.dart';

int foo = 0;

void f() {
  foo;
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: self::@getter::foo
  staticType: int
''');
  }

  test_dynamic_explicitCore() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';

main() {
  dynamic;
}
''');

    var node = findNode.simple('dynamic;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: dynamic
  staticElement: dynamic@-1
  staticType: Type
''');
  }

  test_dynamic_explicitCore_withPrefix_referenceWithout() async {
    await assertErrorsInCode(r'''
import 'dart:core' as mycore;

main() {
  dynamic;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 42, 7),
    ]);

    var node = findNode.simple('dynamic;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: dynamic
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_dynamic_implicitCore() async {
    await assertNoErrorsInCode(r'''
main() {
  dynamic;
}
''');

    var node = findNode.simple('dynamic;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: dynamic
  staticElement: dynamic@-1
  staticType: Type
''');
  }

  test_enum_typeParameter_in_method() async {
    await assertNoErrorsInCode('''
enum E<T> {
  v;
  void foo() {
    T;
  }
}
''');

    var node = findNode.simple('T;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: T
  staticElement: T@7
  staticType: Type
''');
  }

  test_expression_topLevelVariable() async {
    await assertNoErrorsInCode('''
final a = 0;

void f() {
  a;
}
''');

    var node = findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  staticElement: self::@getter::a
  staticType: int
''');
  }

  test_expression_topLevelVariable_constructor_returnBody() async {
    await assertErrorsInCode('''
final a = 0;

class C {
  C() {
    return a;
  }
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, 43, 1),
    ]);

    var node = findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  staticElement: self::@getter::a
  staticType: int
''');
  }

  test_expression_topLevelVariable_constructor_returnExpression() async {
    await assertErrorsInCode('''
final a = 0;

class C {
  C() => a;
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, 30, 5),
      error(
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR, 33, 1),
    ]);

    var node = findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  staticElement: self::@getter::a
  staticType: int
''');
  }

  test_expression_topLevelVariable_invocationArgument_afterNamed() async {
    await assertNoErrorsInCode('''
final a = 0;

void foo(int a, {int? b}) {}

void f() {
  foo(b: 0, a);
}
''');

    var node = findNode.simple('a);');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  parameter: self::@function::foo::@parameter::a
  staticElement: self::@getter::a
  staticType: int
''');
  }

  test_implicitCall_tearOff() async {
    await assertNoErrorsInCode('''
class A {
  int call() => 0;
}

int Function() foo(A a) {
  return a;
}
''');

    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.parameter('a'));
    assertType(identifier, 'A');
  }

  test_implicitCall_tearOff_nullable() async {
    await assertErrorsInCode('''
class A {
  int call() => 0;
}

int Function() foo(A? a) {
  return a;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 68, 1),
    ]);

    var identifier = findNode.simple('a;');
    assertElement(identifier, findElement.parameter('a'));
    assertType(identifier, 'A?');
  }

  test_inClass_getterInherited_setterDeclaredLocally() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 7;
}
class B extends A {
  set foo(int _) {}

  void f() {
    foo;
  }
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: self::@class::A::@getter::foo
  staticType: int
''');
  }

  test_inClass_inDeclaration_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart'

augment class A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

int get foo => 0;

class A {
  void f() {
    foo;
  }
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: self::@augmentation::package:test/a.dart::@classAugmentation::A::@getter::foo
  staticType: int
''');
  }

  test_inExtension_onFunctionType_call() async {
    await assertNoErrorsInCode('''
extension E on int Function(double) {
  void f() {
    call;
  }
}
''');

    var node = findNode.simple('call;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: call
  staticElement: <null>
  staticType: int Function(double)
''');
  }

  test_inExtension_onFunctionType_call_inference() async {
    await assertNoErrorsInCode('''
extension E on int Function<T>(T) {
  int Function(double) f() {
    return call;
  }
}
''');

    var node = findNode.simple('call;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: call
  staticElement: <null>
  staticType: int Function(double)
  tearOffTypeArgumentTypes
    double
''');
  }

  test_inExtension_onRecordType_fromTypeParameterBound_named() async {
    await assertNoErrorsInCode('''
extension E<T extends ({int foo})> on T {
  void f() {
    foo;
  }
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_fromTypeParameterBound_positional() async {
    await assertNoErrorsInCode(r'''
extension E<T extends (int, String)> on T {
  void f() {
    $1;
  }
}
''');

    var node = findNode.simple(r'$1;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: $1
  staticElement: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_named() async {
    await assertNoErrorsInCode('''
extension E on ({int foo}) {
  void f() {
    foo;
  }
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_named_fromExtension() async {
    await assertNoErrorsInCode('''
extension E on ({int foo}) {
  bool get bar => true;

  void f() {
    bar;
  }
}
''');

    var node = findNode.simple('bar;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: bar
  staticElement: self::@extension::E::@getter::bar
  staticType: bool
''');
  }

  test_inExtension_onRecordType_named_unresolved() async {
    await assertErrorsInCode('''
extension E on ({int foo}) {
  void f() {
    bar;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 46, 3),
    ]);

    var node = findNode.simple('bar;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: bar
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_inExtension_onRecordType_positional_0() async {
    await assertNoErrorsInCode(r'''
extension E on (int, String) {
  void f() {
    $1;
  }
}
''');

    var node = findNode.simple(r'$1;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: $1
  staticElement: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_positional_1() async {
    await assertNoErrorsInCode(r'''
extension E on (int, String) {
  void f() {
    $2;
  }
}
''');

    var node = findNode.simple(r'$2;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: $2
  staticElement: <null>
  staticType: String
''');
  }

  test_inExtension_onRecordType_positional_2_fromExtension() async {
    await assertNoErrorsInCode(r'''
extension E on (int, String) {
  bool get $3 => true;

  void f() {
    $3;
  }
}
''');

    var node = findNode.simple(r'$3;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: $3
  staticElement: self::@extension::E::@getter::$3
  staticType: bool
''');
  }

  test_inExtension_onRecordType_positional_2_unresolved() async {
    await assertErrorsInCode(r'''
extension E on (int, String) {
  void f() {
    $3;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 48, 2),
    ]);

    var node = findNode.simple(r'$3;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: $3
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_inExtensionType_declared() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;

  void f() {
    foo;
  }
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: self::@extensionType::A::@getter::foo
  staticType: int
''');
  }

  test_inExtensionType_explicitThis_exposed() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

class B extends A {}

extension type X(B it) implements A {
  void f() {
    foo;
  }
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: self::@class::A::@getter::foo
  staticType: int
''');
  }

  test_inMixin_inDeclaration_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart'

augment mixin A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

int get foo => 0;

mixin A {
  void f() {
    foo;
  }
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: self::@augmentation::package:test/a.dart::@mixinAugmentation::A::@getter::foo
  staticType: int
''');
  }

  test_localFunction_generic() async {
    await assertNoErrorsInCode('''
class C<T> {
  static void foo<S>(S s) {
    void f<U>(S s, U u) {}
    f;
  }
}
''');

    var identifier = findNode.simple('f;');
    assertElement(identifier, findElement.localFunction('f'));
    assertType(identifier, 'void Function<U>(S, U)');
  }

  test_never_implicitCore() async {
    await assertNoErrorsInCode(r'''
main() {
  Never;
}
''');

    var node = findNode.simple('Never;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: Never
  staticElement: Never@-1
  staticType: Type
''');
  }

  test_tearOff_function_topLevel() async {
    await assertNoErrorsInCode('''
void foo(int a) {}

main() {
  foo;
}
''');

    var identifier = findNode.simple('foo;');
    assertElement(identifier, findElement.topFunction('foo'));
    assertType(identifier, 'void Function(int)');
  }

  test_tearOff_method() async {
    await assertNoErrorsInCode('''
class A {
  void foo(int a) {}

  bar() {
    foo;
  }
}
''');

    var identifier = findNode.simple('foo;');
    assertElement(identifier, findElement.method('foo'));
    assertType(identifier, 'void Function(int)');
  }
}
