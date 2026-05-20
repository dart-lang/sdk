// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimpleIdentifierResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SimpleIdentifierResolutionTest extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_augment_topLevel_function_with_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment void foo() {}
''');

    await resolveTestCodeWithDiagnostics('''
part 'a.dart';

void foo() {}

void f() {
  foo;
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@functionAugmentation::foo
  element: <testLibrary>::@function::foo
  staticType: void Function()
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_augment_topLevel_getter_with_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment int get foo => 1;
''');

    await resolveTestCodeWithDiagnostics('''
part 'a.dart';

int get foo => 0;

void f() {
  foo;
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
  element: <testLibraryFragment>::@getter::foo#element
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_augment_topLevel_setter_with_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment set foo(int _) {}
''');

    await resolveTestCodeWithDiagnostics('''
part 'a.dart';

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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibrary>::@fragment::package:test/a.dart::@setterAugmentation::foo
  writeElement2: <testLibraryFragment>::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_augment_topLevel_variable_with_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment int get foo() => 1;
''');

    await resolveTestCodeWithDiagnostics('''
part 'a.dart';

int foo = 0;

void f() {
  foo;
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@getterAugmentation::foo
  element: <testLibraryFragment>::@getter::foo#element
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_augment_topLevel_variable_with_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment int foo = 1;
''');

    await resolveTestCodeWithDiagnostics('''
part 'a.dart';

int foo = 0;

void f() {
  foo;
}
''');

    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: <testLibraryFragment>::@getter::foo
  element: <testLibraryFragment>::@getter::foo#element
  staticType: int
''');
  }

  test_dynamic_explicitCore_withPrefix_referenceWithout() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:core' as mycore;

main() {
  dynamic;
//^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'dynamic'.
}
''');

    var node = findNode.simple('dynamic;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: dynamic
  element: <null>
  staticType: InvalidType
''');
  }

  test_expression_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics('''
final a = 0;

void f() {
  a;
}
''');

    var node = findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@getter::a
  staticType: int
''');
  }

  test_expression_topLevelVariable_constructor_returnBody() async {
    await resolveTestCodeWithDiagnostics('''
final a = 0;

class C {
  C() {
    return a;
//         ^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
  }
}
''');

    var node = findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@getter::a
  staticType: int
''');
  }

  test_expression_topLevelVariable_constructor_returnExpression() async {
    await resolveTestCodeWithDiagnostics('''
final a = 0;

class C {
  C() => a;
//    ^^^^^
// [diag.returnInGenerativeConstructor] Constructors can't return values.
//       ^
// [diag.returnOfInvalidTypeFromConstructor] A value of type 'int' can't be returned from the constructor 'C' because it has a return type of 'C'.
}
''');

    var node = findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@getter::a
  staticType: int
''');
  }

  test_expression_topLevelVariable_invocationArgument_afterNamed() async {
    await resolveTestCodeWithDiagnostics('''
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
  correspondingParameter: <testLibrary>::@function::foo::@formalParameter::a
  element: <testLibrary>::@getter::a
  staticType: int
''');
  }

  test_implicitCall_tearOff() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int call() => 0;
}

int Function() foo(A a) {
  return a;
}
''');

    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@function::foo::@formalParameter::a
  staticType: A
''');
  }

  test_implicitCall_tearOff_nullable() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int call() => 0;
}

int Function() foo(A? a) {
  return a;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'A?' can't be returned from the function 'foo' because it has a return type of 'int Function()'.
}
''');

    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@function::foo::@formalParameter::a
  staticType: A?
''');
  }

  test_inClass_getterInherited_setterDeclaredLocally() async {
    await resolveTestCodeWithDiagnostics('''
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
  element: <testLibrary>::@class::A::@getter::foo
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_inClass_inDeclaration_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  int get foo => 0;
}
''');
    await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';

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
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo
  element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo#element
  staticType: int
''');
  }

  test_inExtension_onFunctionType_call() async {
    await resolveTestCodeWithDiagnostics('''
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
  element: <null>
  staticType: int Function(double)
''');
  }

  test_inExtension_onFunctionType_call_inference() async {
    await resolveTestCodeWithDiagnostics('''
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
  element: <null>
  staticType: int Function(double)
  tearOffTypeArgumentTypes
    double
''');
  }

  test_inExtension_onRecordType_fromTypeParameterBound_named() async {
    await resolveTestCodeWithDiagnostics('''
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
  element: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_fromTypeParameterBound_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
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
  element: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_named() async {
    await resolveTestCodeWithDiagnostics('''
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
  element: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_named_fromExtension() async {
    await resolveTestCodeWithDiagnostics('''
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
  element: <testLibrary>::@extension::E::@getter::bar
  staticType: bool
''');
  }

  test_inExtension_onRecordType_named_unresolved() async {
    await resolveTestCodeWithDiagnostics('''
extension E on ({int foo}) {
  void f() {
    bar;
//  ^^^
// [diag.undefinedIdentifier] Undefined name 'bar'.
  }
}
''');

    var node = findNode.simple('bar;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: bar
  element: <null>
  staticType: InvalidType
''');
  }

  test_inExtension_onRecordType_positional_0() async {
    await resolveTestCodeWithDiagnostics(r'''
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
  element: <null>
  staticType: int
''');
  }

  test_inExtension_onRecordType_positional_1() async {
    await resolveTestCodeWithDiagnostics(r'''
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
  element: <null>
  staticType: String
''');
  }

  test_inExtension_onRecordType_positional_2_fromExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
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
  element: <testLibrary>::@extension::E::@getter::$3
  staticType: bool
''');
  }

  test_inExtension_onRecordType_positional_2_unresolved() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  void f() {
    $3;
//  ^^
// [diag.undefinedIdentifier] Undefined name '$3'.
  }
}
''');

    var node = findNode.simple(r'$3;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: $3
  element: <null>
  staticType: InvalidType
''');
  }

  test_inExtensionType_declared() async {
    await resolveTestCodeWithDiagnostics(r'''
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
  element: <testLibrary>::@extensionType::A::@getter::foo
  staticType: int
''');
  }

  test_inExtensionType_explicitThis_exposed() async {
    await resolveTestCodeWithDiagnostics(r'''
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
  element: <testLibrary>::@class::A::@getter::foo
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_inMixin_inDeclaration_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment mixin A {
  int get foo => 0;
}
''');
    await resolveTestCodeWithDiagnostics(r'''
part 'a.dart';

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
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo
  element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo#element
  staticType: int
''');
  }

  test_localFunction_generic() async {
    await resolveTestCodeWithDiagnostics('''
class C<T> {
  static void foo<S>(S s) {
    void f<U>(S s, U u) {}
    f;
  }
}
''');

    var identifier = findNode.simple('f;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: f
  element: f@50
  staticType: void Function<U>(S, U)
''');
  }

  test_tearOff_function_topLevel() async {
    await resolveTestCodeWithDiagnostics('''
void foo(int a) {}

main() {
  foo;
}
''');

    var identifier = findNode.simple('foo;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@function::foo
  staticType: void Function(int)
''');
  }

  test_tearOff_method() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  void foo(int a) {}

  bar() {
    foo;
  }
}
''');

    var identifier = findNode.simple('foo;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@class::A::@method::foo
  staticType: void Function(int)
''');
  }
}
