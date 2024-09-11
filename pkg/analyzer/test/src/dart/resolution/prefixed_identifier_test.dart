// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixedIdentifierResolutionTest);
  });
}

@reflectiveTest
class PrefixedIdentifierResolutionTest extends PubPackageResolutionTest {
  test_class_read() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f(A a) {
  a.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    staticType: int
  staticElement: <testLibraryFragment>::@class::A::@getter::foo
  staticType: int
''');
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

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    staticType: void Function<U>(int, U)
  staticElement: <testLibraryFragment>::@class::A::@method::foo
  staticType: void Function<U>(int, U)
''');
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

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    staticType: void Function(int)
  staticElement: <testLibraryFragment>::@class::A::@method::foo
  staticType: void Function(int)
''');
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

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    staticElement: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: A
    staticElement: package:test/a.dart::<fragment>::@typeAlias::A
    staticType: Type
  staticElement: package:test/a.dart::<fragment>::@typeAlias::A
  staticType: Type
''');
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
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
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
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::foo
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  staticType: int
''');
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
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
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
    parameter: <testLibraryFragment>::@class::A::@setter::foo::@parameter::_foo
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_dynamic_explicitCore_withPrefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:core' as mycore;

main() {
  mycore.dynamic;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: mycore
    staticElement: <testLibraryFragment>::@prefix::mycore
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: dynamic
    staticElement: dynamic@-1
    staticType: Type
  staticElement: dynamic@-1
  staticType: Type
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

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: e
    staticElement: <testLibraryFragment>::@function::f::@parameter::e
    staticType: E
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@enum::E::@getter::foo
    staticType: int
  staticElement: <testLibraryFragment>::@enum::E::@getter::foo
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::e
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
    parameter: <testLibraryFragment>::@enum::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibraryFragment>::@enum::E::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_functionClass_call_read() async {
    await assertNoErrorsInCode('''
void f(Function a) {
  a.call;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: Function
  period: .
  identifier: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: Function
  staticElement: <null>
  staticType: Function
''');
  }

  test_functionType_call_read() async {
    await assertNoErrorsInCode('''
void f(int Function(String) a) {
  a.call;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: int Function(String)
  period: .
  identifier: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: int Function(String)
  staticElement: <null>
  staticType: int Function(String)
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

    var node = findNode.prefixed('B.foo');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: B
    staticElement: <testLibraryFragment>::@typeAlias::B
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    staticType: int
  staticElement: <testLibraryFragment>::@class::A::@getter::foo
  staticType: int
''');
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

    var node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: <testLibraryFragment>::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: A
    staticElement: package:test/a.dart::<fragment>::@class::A
    staticType: Type
  staticElement: package:test/a.dart::<fragment>::@class::A
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

    var node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: <testLibraryFragment>::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: F
    staticElement: package:test/a.dart::<fragment>::@typeAlias::F
    staticType: Type
  staticElement: package:test/a.dart::<fragment>::@typeAlias::F
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

    var node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: <testLibraryFragment>::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::<fragment>::@function::foo
    staticType: void Function()
  staticElement: package:test/a.dart::<fragment>::@function::foo
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

    var node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: <testLibraryFragment>::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::<fragment>::@getter::foo
    staticType: int
  staticElement: package:test/a.dart::<fragment>::@getter::foo
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

    var node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: <testLibraryFragment>::@prefix::prefix
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

    var node = findNode.prefixed('prefix.');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: prefix
    staticElement: <testLibraryFragment>::@prefix::prefix
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::<fragment>::@getter::foo
    staticType: int
  staticElement: package:test/a.dart::<fragment>::@getter::foo
  staticType: int
''');
  }

  test_ofClass_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  augment int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {
  int get foo => 0;
}

void f(A a) {
  a.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getterAugmentation::foo
    staticType: int
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getterAugmentation::foo
  staticType: int
''');
  }

  test_ofClass_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {}

void f(A a) {
  a.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo
    staticType: int
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo
  staticType: int
''');
  }

  test_ofClassName_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  augment static int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {
  static int get foo => 0;
}

void f() {
  A.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getterAugmentation::foo
    staticType: int
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getterAugmentation::foo
  staticType: int
''');
  }

  test_ofClassName_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  static int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {}

void f() {
  A.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo
    staticType: int
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo
  staticType: int
''');
  }

  test_ofClassName_augmentationDeclares_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  static void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {}

void f() {
  A.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@class::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo
    staticType: void Function()
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo
  staticType: void Function()
''');
  }

  test_ofExtensionType_read() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;
}

void f(A a) {
  a.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionType::A::@getter::foo
    staticType: int
  staticElement: <testLibraryFragment>::@extensionType::A::@getter::foo
  staticType: int
''');
  }

  test_ofExtensionType_read_nullableRepresentation() async {
    await assertNoErrorsInCode(r'''
extension type A(int? it) {
  int get foo => 0;
}

void f(A a) {
  a.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionType::A::@getter::foo
    staticType: int
  staticElement: <testLibraryFragment>::@extensionType::A::@getter::foo
  staticType: int
''');
  }

  test_ofExtensionType_read_nullableType() async {
    await assertErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;
}

void f(A? a) {
  a.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE,
          69, 3),
    ]);

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: A?
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionType::A::@getter::foo
    staticType: int
  staticElement: <testLibraryFragment>::@extensionType::A::@getter::foo
  staticType: int
''');
  }

  test_ofExtensionType_read_nullableType_nullAware() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;
}

void f(A? a) {
  a?.foo;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: A?
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionType::A::@getter::foo
    staticType: int
  staticType: int?
''');
  }

  test_ofExtensionType_write() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  set foo(int _) {}
}

void f(A a) {
  a.foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
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
    literal: 0
    parameter: <testLibraryFragment>::@extensionType::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extensionType::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_ofMixin_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment mixin A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

mixin A {}

void f(A a) {
  a.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo
    staticType: int
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo
  staticType: int
''');
  }

  test_ofMixinName_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment mixin A {
  static int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

mixin A {}

void f() {
  A.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@mixin::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo
    staticType: int
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo
  staticType: int
''');
  }

  test_ofMixinName_augmentationDeclares_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment mixin A {
  static void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

mixin A {}

void f() {
  A.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@mixin::A
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo
    staticType: void Function()
  staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@method::foo
  staticType: void Function()
''');
  }

  test_read_dynamicIdentifier_hashCode() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  a.hashCode;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: dynamic
  period: .
  identifier: SimpleIdentifier
    token: hashCode
    staticElement: dart:core::<fragment>::@class::Object::@getter::hashCode
    staticType: int
  staticElement: dart:core::<fragment>::@class::Object::@getter::hashCode
  staticType: int
''');
  }

  test_read_dynamicIdentifier_identifier() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  a.foo;
}
''');

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
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

  test_read_interfaceType_unresolved() async {
    await assertErrorsInCode('''
void f(int a) {
  a.foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 20, 3),
    ]);

    var node = findNode.prefixed('foo;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    staticType: int
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticElement: <null>
  staticType: InvalidType
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

    var node = findNode.singlePrefixedIdentifier;
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: p
    staticElement: <testLibraryFragment>::@prefix::p
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: A
    staticElement: package:test/a.dart::<fragment>::@typeAlias::A
    staticType: Type
  staticElement: package:test/a.dart::<fragment>::@typeAlias::A
  staticType: Type
''');
  }
}
