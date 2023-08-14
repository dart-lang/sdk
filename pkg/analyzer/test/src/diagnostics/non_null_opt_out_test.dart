// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullOptOutTest);
  });
}

@reflectiveTest
class NonNullOptOutTest extends PubPackageResolutionTest {
  ImportFindElement get _import_a {
    return findElement.importFind('package:test/a.dart');
  }

  test_assignment_indexExpression() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void operator[]=(int a, int b) {}
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a[null] = null;
}
''');

    var assignment = findNode.assignment(' = null;');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::main::@parameter::a
      staticType: A*
    leftBracket: [
    index: NullLiteral
      literal: null
      parameter: ParameterMember
        base: package:test/a.dart::@class::A::@method::[]=::@parameter::a
        isLegacy: true
      staticType: Null*
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: NullLiteral
    literal: null
    parameter: ParameterMember
      base: package:test/a.dart::@class::A::@method::[]=::@parameter::b
      isLegacy: true
    staticType: Null*
  readElement: <null>
  readType: null
  writeElement: MethodMember
    base: package:test/a.dart::@class::A::@method::[]=
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: Null*
''');
  }

  test_assignment_prefixedIdentifier_instanceTarget_class_field() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a.foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::main::@parameter::a
      staticType: A*
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@class::A::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@class::A::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_prefixedIdentifier_instanceTarget_extension_setter() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  void set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a.foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::main::@parameter::a
      staticType: A*
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@extension::E::@setter::foo::@parameter::_
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@extension::E::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_prefixedIdentifier_staticTarget_class_field() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A.foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/a.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@class::A::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@class::A::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_prefixedIdentifier_staticTarget_extension_field() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  static int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E.foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: package:test/a.dart::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@extension::E::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@extension::E::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_prefixedIdentifier_topLevelVariable() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart' as p;

main() {
  p.foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      staticElement: self::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_propertyAccess_class_field() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A().foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: package:test/a.dart::@class::A
          type: A*
        staticElement: ConstructorMember
          base: package:test/a.dart::@class::A::@constructor::new
          isLegacy: true
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@class::A::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@class::A::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_propertyAccess_extension_setter() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  void set foo(int a) {}
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A().foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: package:test/a.dart::@class::A
          type: A*
        staticElement: ConstructorMember
          base: package:test/a.dart::@class::A::@constructor::new
          isLegacy: true
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@extension::E::@setter::foo::@parameter::a
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@extension::E::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_propertyAccess_extensionOverride_setter() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  void set foo(int a) {}
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  E(a).foo = 0;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: a
            parameter: <null>
            staticElement: self::@function::main::@parameter::a
            staticType: A*
        rightParenthesis: )
      element: package:test/a.dart::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@extension::E::@setter::foo::@parameter::a
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@extension::E::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_propertyAccess_superTarget() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    super.foo = 0;
  }
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: ParameterMember
      base: package:test/a.dart::@class::A::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@class::A::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
  }

  test_assignment_simpleIdentifier_topLevelVariable() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  foo = null;
}
''');

    var assignment = findNode.assignment('foo =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: NullLiteral
    literal: null
    parameter: ParameterMember
      base: package:test/a.dart::@setter::foo::@parameter::_foo
      isLegacy: true
    staticType: Null*
  readElement: <null>
  readType: null
  writeElement: PropertyAccessorMember
    base: package:test/a.dart::@setter::foo
    isLegacy: true
  writeType: int*
  staticElement: <null>
  staticType: Null*
''');
  }

  test_binaryExpression() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int operator+(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a + null;
}
''');

    final node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::main::@parameter::a
    staticType: A*
  operator: +
  rightOperand: NullLiteral
    literal: null
    parameter: root::@parameter::a
    staticType: Null*
  staticElement: MethodMember
    base: package:test/a.dart::@class::A::@method::+
    isLegacy: true
  staticInvokeType: int* Function(int*)*
  staticType: int*
''');
  }

  test_functionExpressionInvocation() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
int Function(int, int?)? foo;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  foo(null, null);
}
''');

    final node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: PropertyAccessorMember
      base: package:test/a.dart::@getter::foo
      isLegacy: true
    staticType: int* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::
        staticType: Null*
      NullLiteral
        literal: null
        parameter: root::@parameter::
        staticType: Null*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: int* Function(int*, int*)*
  staticType: int*
''');
  }

  test_functionExpressionInvocation_call() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int call(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a(null, null);
}
''');

    final node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    staticElement: self::@function::main::@parameter::a
    staticType: A*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
      NullLiteral
        literal: null
        parameter: root::@parameter::b
        staticType: Null*
    rightParenthesis: )
  staticElement: MethodMember
    base: package:test/a.dart::@class::A::@method::call
    isLegacy: true
  staticInvokeType: int* Function(int*, int*)*
  staticType: int*
''');
  }

  test_functionExpressionInvocation_extension_staticTarget() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  static int Function(int) get foo => (_) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E.foo(null);
}
''');

    final node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: E
      staticElement: package:test/a.dart::@extension::E
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: PropertyAccessorMember
        base: package:test/a.dart::@extension::E::@getter::foo
        isLegacy: true
      staticType: int* Function(int*)*
    staticType: int* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::
        staticType: Null*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: int* Function(int*)*
  staticType: int*
''');
  }

  test_instanceCreation() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A(int a, int? b);
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A(null, null);
}
''');
    var instanceCreation = findNode.instanceCreation('A(null');
    assertType(instanceCreation, 'A*');

    _assertLegacyMember(
      instanceCreation.constructorName.staticElement,
      _import_a.unnamedConstructor('A'),
    );
  }

  test_instanceCreation_generic() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A(T a, T? b);
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A<int>(null, null);
}
''');
    var instanceCreation = findNode.instanceCreation('A<int>(null');
    assertType(instanceCreation, 'A<int*>*');

    _assertLegacyMember(
      instanceCreation.constructorName.staticElement,
      _import_a.unnamedConstructor('A'),
      expectedSubstitution: {'T': 'int*'},
    );
  }

  test_instanceCreation_generic_instantiateToBounds() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A<T extends num> {}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

var v = A();
''');

    var v = findElement.topVar('v');
    assertType(v.type, 'A<num*>*');
  }

  test_methodInvocation_extension_functionTarget() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
extension E on void Function() {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(void Function() a) {
  a.foo(null);
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::main::@parameter::a
    staticType: void Function()*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: package:test/a.dart::@extension::E::@method::foo
      isLegacy: true
    staticType: int* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*)*
  staticType: int*
''');
  }

  test_methodInvocation_extension_interfaceTarget() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  0.foo(null);
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: IntegerLiteral
    literal: 0
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: package:test/a.dart::@extension::E::@method::foo
      isLegacy: true
    staticType: int* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*)*
  staticType: int*
''');
  }

  test_methodInvocation_extension_nullTarget() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    foo(null);
  }
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: package:test/a.dart::@extension::E::@method::foo
      isLegacy: true
    staticType: int* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*)*
  staticType: int*
''');
  }

  test_methodInvocation_extension_staticTarget() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  static int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E.foo(null);
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: E
    staticElement: package:test/a.dart::@extension::E
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: package:test/a.dart::@extension::E::@method::foo
      isLegacy: true
    staticType: int* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*)*
  staticType: int*
''');
  }

  test_methodInvocation_extensionOverride() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E(0).foo(null);
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          parameter: <null>
          staticType: int*
      rightParenthesis: )
    element: package:test/a.dart::@extension::E
    extendedType: int
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: package:test/a.dart::@extension::E::@method::foo
      isLegacy: true
    staticType: int* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*)*
  staticType: int*
''');
  }

  test_methodInvocation_function() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
int foo(int a, int? b) => 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  foo(null, null);
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: FunctionMember
      base: package:test/a.dart::@function::foo
      isLegacy: true
    staticType: int* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
      NullLiteral
        literal: null
        parameter: root::@parameter::b
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*, int*)*
  staticType: int*
''');
  }

  test_methodInvocation_function_prefixed() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
int foo(int a, int? b) => 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart' as p;

main() {
  p.foo(null, null);
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    staticElement: self::@prefix::p
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: FunctionMember
      base: package:test/a.dart::@function::foo
      isLegacy: true
    staticType: int* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
      NullLiteral
        literal: null
        parameter: root::@parameter::b
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*, int*)*
  staticType: int*
''');
  }

  test_methodInvocation_method_cascade() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a..foo(null, null);
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: package:test/a.dart::@class::A::@method::foo
      isLegacy: true
    staticType: int* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
      NullLiteral
        literal: null
        parameter: root::@parameter::b
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*, int*)*
  staticType: int*
''');
  }

  test_methodInvocation_method_interfaceTarget() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a.foo(null, null);
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::main::@parameter::a
    staticType: A*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: package:test/a.dart::@class::A::@method::foo
      isLegacy: true
    staticType: int* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
      NullLiteral
        literal: null
        parameter: root::@parameter::b
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*, int*)*
  staticType: int*
''');
  }

  test_methodInvocation_method_nullTarget() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  m() {
    foo(null, null);
  }
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: package:test/a.dart::@class::A::@method::foo
      isLegacy: true
    staticType: int* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
      NullLiteral
        literal: null
        parameter: root::@parameter::b
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*, int*)*
  staticType: int*
''');
  }

  test_methodInvocation_method_staticTarget() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int foo(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A.foo(null, null);
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: A
    staticElement: package:test/a.dart::@class::A
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: package:test/a.dart::@class::A::@method::foo
      isLegacy: true
    staticType: int* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
      NullLiteral
        literal: null
        parameter: root::@parameter::b
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*, int*)*
  staticType: int*
''');
  }

  test_methodInvocation_method_superTarget() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  m() {
    super.foo(null, null);
  }
}
''');

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: package:test/a.dart::@class::A::@method::foo
      isLegacy: true
    staticType: int* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NullLiteral
        literal: null
        parameter: root::@parameter::a
        staticType: Null*
      NullLiteral
        literal: null
        parameter: root::@parameter::b
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: int* Function(int*, int*)*
  staticType: int*
''');
  }

  test_nnbd_optOut_invalidSyntax() async {
    noSoundNullSafety = false;
    await assertErrorsInCode('''
// @dart = 2.2
// NNBD syntax is not allowed
f(x, z) { (x is String?) ? x : z; }
''', [error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 67, 1)]);
  }

  test_nnbd_optOut_late() async {
    noSoundNullSafety = false;
    await assertNoErrorsInCode('''
// @dart = 2.2
class C {
  // "late" is allowed as an identifier
  int late;
}
''');
  }

  test_nnbd_optOut_transformsOptedInSignatures() async {
    noSoundNullSafety = false;
    await assertNoErrorsInCode('''
// @dart = 2.2
f(String x) {
  x + null; // OK because we're in a nullable library.
}
''');
  }

  test_postfixExpression() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A operator+(int a) => this;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a++;
}
''');
    var prefixExpression = findNode.postfix('a++');
    assertType(prefixExpression, 'A*');

    var element = prefixExpression.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('+'));
  }

  test_prefixExpression() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int operator-() => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  -a;
}
''');
    var prefixExpression = findNode.prefix('-a');
    assertType(prefixExpression, 'int*');

    var element = prefixExpression.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('unary-'));
  }

  test_read_indexExpression_class() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int operator[](int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a[null];
}
''');
    var indexExpression = findNode.index('a[');
    assertType(indexExpression, 'int*');

    var element = indexExpression.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('[]'));
  }

  test_read_prefixedIdentifier_instanceTarget_class_field() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('a.foo');
    assertType(prefixedIdentifier, 'int*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_prefixedIdentifier_instanceTarget_extension_getter() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  a.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('a.foo');
    assertType(prefixedIdentifier, 'int*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_prefixedIdentifier_staticTarget_class_field() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int foo;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('A.foo');
    assertType(prefixedIdentifier, 'int*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_prefixedIdentifier_staticTarget_class_method() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('A.foo');
    assertType(prefixedIdentifier, 'int* Function(int*)*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_read_prefixedIdentifier_staticTarget_extension_field() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
extension E {
  static int foo;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('E.foo');
    assertType(prefixedIdentifier, 'int*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_prefixedIdentifier_staticTarget_extension_method() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
extension E {
  static int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  E.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('E.foo');
    assertType(prefixedIdentifier, 'int* Function(int*)*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_read_prefixedIdentifier_topLevelVariable() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart' as p;

main() {
  p.foo;
}
''');
    var prefixedIdentifier = findNode.prefixed('p.foo');
    assertType(prefixedIdentifier, 'int*');

    var identifier = prefixedIdentifier.identifier;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.topGet('foo'));
  }

  test_read_propertyAccessor_class_field() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A().foo;
}
''');
    var propertyAccess = findNode.propertyAccess('foo');
    assertType(propertyAccess, 'int*');

    var identifier = propertyAccess.propertyName;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_propertyAccessor_class_method() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo() => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  A().foo;
}
''');
    var propertyAccess = findNode.propertyAccess('foo');
    assertType(propertyAccess, 'int* Function()*');

    var identifier = propertyAccess.propertyName;
    assertType(identifier, 'int* Function()*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_read_propertyAccessor_extensionOverride_getter() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main(A a) {
  E(a).foo;
}
''');
    var propertyAccess = findNode.propertyAccess('foo');
    assertType(propertyAccess, 'int*');

    var identifier = propertyAccess.propertyName;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_propertyAccessor_superTarget() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    super.foo;
  }
}
''');
    var propertyAccess = findNode.propertyAccess('foo');
    assertType(propertyAccess, 'int*');

    var identifier = propertyAccess.propertyName;
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_simpleIdentifier_class_field() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    foo;
  }
}
''');
    var identifier = findNode.simple('foo');
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_simpleIdentifier_class_method() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    foo;
  }
}
''');
    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_read_simpleIdentifier_extension_getter() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    foo;
  }
}
''');
    var identifier = findNode.simple('foo');
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.getter('foo'));
  }

  test_read_simpleIdentifier_extension_method() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
extension E on A {
  int foo(int a) => 0;
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  void bar() {
    foo;
  }
}
''');
    var identifier = findNode.simple('foo');
    assertType(identifier, 'int* Function(int*)*');

    var element = identifier.staticElement as MethodElement;
    _assertLegacyMember(element, _import_a.method('foo'));
  }

  test_read_simpleIdentifier_topLevelVariable() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
int foo = 0;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

main() {
  foo;
}
''');
    var identifier = findNode.simple('foo');
    assertType(identifier, 'int*');

    var element = identifier.staticElement as PropertyAccessorElement;
    _assertLegacyMember(element, _import_a.topGet('foo'));
  }

  test_superConstructorInvocation() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A(int a, int? b);
}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class B extends A {
  B() : super(null, null);
}
''');
    var instanceCreation = findNode.superConstructorInvocation('super(');

    _assertLegacyMember(
      instanceCreation.staticElement,
      _import_a.unnamedConstructor('A'),
    );
  }

  void _assertLegacyMember(
    Element? actualElement,
    Element declaration, {
    Map<String, String> expectedSubstitution = const {},
  }) {
    var actualMember = actualElement as Member;
    expect(actualMember.declaration, same(declaration));
    expect(actualMember.isLegacy, isTrue);
    assertSubstitution(actualMember.substitution, expectedSubstitution);
  }
}
