// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixedIdentifierResolutionTest);
    defineReflectiveTests(PrefixedIdentifierResolutionTest_WithoutNullSafety);
  });
}

@reflectiveTest
class PrefixedIdentifierResolutionTest extends PubPackageResolutionTest
    with PrefixedIdentifierResolutionTestCases {
  test_deferredImportPrefix_loadLibrary_optIn_fromOptOut() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await assertErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' deferred as a;

main() {
  a.loadLibrary;
}
''', [
      error(WarningCode.UNUSED_IMPORT, 22, 8),
    ]);

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@prefix::a
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: loadLibrary
    staticElement: FunctionMember
      base: loadLibrary@-1
      isLegacy: true
    staticType: Future<dynamic>* Function()*
  staticElement: FunctionMember
    base: loadLibrary@-1
    isLegacy: true
  staticType: Future<dynamic>* Function()*
''');
  }

  test_enum_read() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  int get foo => 0;
}

void f(E e) {
  e.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: e
    staticElement: self::@function::f::@parameter::e
    staticType: E
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@enum::E::@getter::foo
    staticType: int
  staticElement: self::@enum::E::@getter::foo
  staticType: int
''');
  }

  test_enum_write() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  set foo(int _) {}
}

void f(E e) {
  e.foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: e
      staticElement: self::@function::f::@parameter::e
      staticType: E
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: self::@enum::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@enum::E::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_hasReceiver_typeAlias_staticGetter() async {
    await assertNoErrorsInCode(r'''
class A {
  static int get foo => 0;
}

typedef B = A;

void f() {
  B.foo;
}
''');

    final node = findNode.prefixed('B.foo');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: B
    staticElement: self::@typeAlias::B
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: int
  staticElement: self::@class::A::@getter::foo
  staticType: int
''');
  }

  test_implicitCall_tearOff_nullable() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int call() => 0;
}

A? a;
''');
    await assertErrorsInCode('''
import 'a.dart';

int Function() foo() {
  return a;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 50, 1),
    ]);

    var identifier = findNode.simple('a;');
    assertElement(
      identifier,
      findElement.importFind('package:test/a.dart').topGet('a'),
    );
    assertType(identifier, 'A?');
  }

  test_importPrefix_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

void f() {
  prefix.A;
}
''');

    final node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: self::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: A
    staticElement: package:test/a.dart::@class::A
    staticType: Type
  staticElement: package:test/a.dart::@class::A
  staticType: Type
''');
  }

  test_importPrefix_functionTypeAlias() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef void F();
''');

    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

void f() {
  prefix.F;
}
''');

    final node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: self::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: F
    staticElement: package:test/a.dart::@typeAlias::F
    staticType: Type
  staticElement: package:test/a.dart::@typeAlias::F
  staticType: Type
''');
  }

  test_importPrefix_topLevelFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');

    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

void f() {
  prefix.foo;
}
''');

    final node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: self::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::@function::foo
    staticType: void Function()
  staticElement: package:test/a.dart::@function::foo
  staticType: void Function()
''');
  }

  test_importPrefix_topLevelGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');

    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

void f() {
  prefix.foo;
}
''');

    final node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: self::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::@getter::foo
    staticType: int
  staticElement: package:test/a.dart::@getter::foo
  staticType: int
''');
  }

  test_importPrefix_topLevelSetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int _) {}
''');

    await assertErrorsInCode('''
import 'a.dart' as prefix;

void f() {
  prefix.foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 48, 3),
    ]);

    final node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: self::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_importPrefix_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
final foo = 0;
''');

    await assertNoErrorsInCode('''
import 'a.dart' as prefix;

void f() {
  prefix.foo;
}
''');

    final node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: self::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::@getter::foo
    staticType: int
  staticElement: package:test/a.dart::@getter::foo
  staticType: int
''');
  }

  test_ofClass_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  augment int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

class A {
  int get foo => 0;
}

void f(A a) {
  a.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
    staticType: int
  staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
  staticType: int
''');
  }

  test_ofClass_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

class A {}

void f(A a) {
  a.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
    staticType: int
  staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
  staticType: int
''');
  }

  test_ofClassName_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  augment static int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

class A {
  static int get foo => 0;
}

void f() {
  A.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
    staticType: int
  staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
  staticType: int
''');
  }

  test_ofClassName_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  static int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

class A {}

void f() {
  A.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
    staticType: int
  staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
  staticType: int
''');
  }

  test_ofClassName_augmentationDeclares_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  static void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

class A {}

void f() {
  A.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@class::A::@method::foo
    staticType: void Function()
  staticElement: self::@augmentation::package:test/a.dart::@class::A::@method::foo
  staticType: void Function()
''');
  }

  test_ofMixin_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment mixin A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

mixin A {}

void f(A a) {
  a.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@mixin::A::@getter::foo
    staticType: int
  staticElement: self::@augmentation::package:test/a.dart::@mixin::A::@getter::foo
  staticType: int
''');
  }

  test_ofMixinName_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment mixin A {
  static int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

mixin A {}

void f() {
  A.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: self::@mixin::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@mixin::A::@getter::foo
    staticType: int
  staticElement: self::@augmentation::package:test/a.dart::@mixin::A::@getter::foo
  staticType: int
''');
  }

  test_ofMixinName_augmentationDeclares_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment mixin A {
  static void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

mixin A {}

void f() {
  A.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: self::@mixin::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@mixin::A::@method::foo
    staticType: void Function()
  staticElement: self::@augmentation::package:test/a.dart::@mixin::A::@method::foo
  staticType: void Function()
''');
  }

  test_read_dynamicIdentifier_hashCode() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  a.hashCode;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: dynamic
  period: .
  identifier: SimpleIdentifier
    token: hashCode
    staticElement: dart:core::@class::Object::@getter::hashCode
    staticType: int
  staticElement: dart:core::@class::Object::@getter::hashCode
  staticType: int
''');
  }

  test_read_dynamicIdentifier_identifier() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  a.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: dynamic
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_read_typedef_interfaceType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A = List<int>;
''');

    await assertNoErrorsInCode('''
import 'a.dart' as p;

void f() {
  p.A;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    staticElement: self::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: A
    staticElement: package:test/a.dart::@typeAlias::A
    staticType: Type
  staticElement: package:test/a.dart::@typeAlias::A
  staticType: Type
''');
  }
}

@reflectiveTest
class PrefixedIdentifierResolutionTest_WithoutNullSafety
    extends PubPackageResolutionTest
    with PrefixedIdentifierResolutionTestCases, WithoutNullSafetyMixin {}

mixin PrefixedIdentifierResolutionTestCases on PubPackageResolutionTest {
  test_class_read() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: int
  staticElement: self::@class::A::@getter::foo
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A*
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: int*
  staticElement: self::@class::A::@getter::foo
  staticType: int*
''');
    }
  }

  test_class_read_staticMethod_generic() async {
    await assertNoErrorsInCode('''
class A<T> {
  static void foo<U>(int a, U u) {}
}

void f() {
  A.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function<U>(int, U)
  staticElement: self::@class::A::@method::foo
  staticType: void Function<U>(int, U)
''');
    } else {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function<U>(int*, U*)*
  staticElement: self::@class::A::@method::foo
  staticType: void Function<U>(int*, U*)*
''');
    }
  }

  test_class_read_staticMethod_ofGenericClass() async {
    await assertNoErrorsInCode('''
class A<T> {
  static void foo(int a) {}
}

void f() {
  A.foo;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int)
  staticElement: self::@class::A::@method::foo
  staticType: void Function(int)
''');
    } else {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: self::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int*)*
  staticElement: self::@class::A::@method::foo
  staticType: void Function(int*)*
''');
    }
  }

  test_class_read_typedef_functionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A = void Function();
''');

    await assertNoErrorsInCode('''
import 'a.dart' as p;

void f() {
  p.A;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    staticElement: self::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: A
    staticElement: package:test/a.dart::@typeAlias::A
    staticType: Type
  staticElement: package:test/a.dart::@typeAlias::A
  staticType: Type
''');
    } else {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    staticElement: self::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: A
    staticElement: package:test/a.dart::@typeAlias::A
    staticType: Type*
  staticElement: package:test/a.dart::@typeAlias::A
  staticType: Type*
''');
    }
  }

  test_class_readWrite_assignment() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo += 1;
}
''');

    var assignment = findNode.assignment('foo += 1');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::foo
  readType: int
  writeElement: self::@class::A::@setter::foo
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A*
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: ParameterMember
      base: dart:core::@class::num::@method::+::@parameter::other
      isLegacy: true
    staticType: int*
  readElement: self::@class::A::@getter::foo
  readType: int*
  writeElement: self::@class::A::@setter::foo
  writeType: int*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_class_write() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: self::@class::A::@setter::foo::@parameter::_foo
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
    } else {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
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
    literal: 1
    parameter: self::@class::A::@setter::foo::@parameter::_foo
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::foo
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
    }
  }

  test_dynamic_explicitCore_withPrefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:core' as mycore;

main() {
  mycore.dynamic;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: mycore
    staticElement: self::@prefix::mycore
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: dynamic
    staticElement: dynamic@-1
    staticType: Type
  staticElement: dynamic@-1
  staticType: Type
''');
    } else {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: mycore
    staticElement: self::@prefix::mycore
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: dynamic
    staticElement: dynamic@-1
    staticType: Type*
  staticElement: dynamic@-1
  staticType: Type*
''');
    }
  }

  test_functionType_call_read() async {
    await assertNoErrorsInCode('''
void f(int Function(String) a) {
  a.call;
}
''');

    final node = findNode.singlePrefixedIdentifier;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int Function(String)
  period: .
  identifier: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: int Function(String)
  staticElement: <null>
  staticType: int Function(String)
''');
    } else {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int* Function(String*)*
  period: .
  identifier: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: int* Function(String*)*
  staticElement: <null>
  staticType: int* Function(String*)*
''');
    }
  }

  test_implicitCall_tearOff() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int call() => 0;
}

A a;
''');
    await assertNoErrorsInCode('''
import 'a.dart';

int Function() foo() {
  return a;
}
''');

    var identifier = findNode.simple('a;');
    assertElement(
      identifier,
      findElement.importFind('package:test/a.dart').topGet('a'),
    );
    assertType(identifier, 'A');
  }

  test_read_interfaceType_unresolved() async {
    await assertErrorsInCode('''
void f(int a) {
  a.foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 20, 3),
    ]);

    final node = findNode.prefixed('foo;');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
    } else {
      assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
    }
  }
}
