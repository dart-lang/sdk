// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PropertyAccessResolutionTest);
    defineReflectiveTests(PropertyAccessResolutionTest_WithoutNullSafety);
  });
}

@reflectiveTest
class PropertyAccessResolutionTest extends PubPackageResolutionTest
    with PropertyAccessResolutionTestCases {
  test_implicitCall_tearOff_nullable() async {
    await assertErrorsInCode('''
class A {
  int call() => 0;
}

class B {
  A? a;
}

int Function() foo() {
  return B().a; // ref
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 85, 5),
    ]);

    var identifier = findNode.simple('a; // ref');
    assertElement(identifier, findElement.getter('a'));
    assertType(identifier, 'A?');
  }

  test_inClass_explicitThis_inDeclaration_augmentationAugments() async {
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

  void f() {
    this.foo;
  }
}
''');

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_inClass_explicitThis_inDeclaration_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

int get foo => 0;

class A {
  void f() {
    this.foo;
  }
}
''');

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_inClass_explicitThis_inDeclaration_augmentationDeclares_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

int get foo => 0;

class A {
  void f() {
    this.foo;
  }
}
''');

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@class::A::@method::foo
    staticType: void Function()
  staticType: void Function()
''');
  }

  test_inClass_superQualifier_identifier_getter() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

class B extends A {
  int get foo => 0;

  void f() {
    super.foo;
  }
}
''');

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_inClass_superQualifier_identifier_method() async {
    await assertNoErrorsInCode('''
class A {
  void foo(int _) {}
}

class B extends A {
  void foo(int _) {}

  void f() {
    super.foo;
  }
}
''');

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int)
  staticType: void Function(int)
''');
  }

  test_inClass_superQualifier_identifier_setter() async {
    await assertErrorsInCode('''
class A {
  set foo(int _) {}
}

class B extends A {
  set foo(int _) {}

  void f() {
    super.foo;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_GETTER, 97, 3),
    ]);

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_inClass_thisExpression_identifier_getter() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;

  void f() {
    this.foo;
  }
}
''');

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_inClass_thisExpression_identifier_method() async {
    await assertNoErrorsInCode('''
class A {
  void foo(int _) {}

  void f() {
    this.foo;
  }
}
''');

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int)
  staticType: void Function(int)
''');
  }

  test_inClass_thisExpression_identifier_setter() async {
    await assertErrorsInCode('''
class A {
  set foo(int _) {}

  void f() {
    super.foo;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_GETTER, 54, 3),
    ]);

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_nullShorting_cascade() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
  int get bar => 0;
}

void f(A? a) {
  a?..foo..bar;
}
''');

    final node = findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A?
  cascadeSections
    PropertyAccess
      operator: ?..
      propertyName: SimpleIdentifier
        token: foo
        staticElement: self::@class::A::@getter::foo
        staticType: int
      staticType: int
    PropertyAccess
      operator: ..
      propertyName: SimpleIdentifier
        token: bar
        staticElement: self::@class::A::@getter::bar
        staticType: int
      staticType: int
  staticType: A?
''');
  }

  test_nullShorting_cascade2() async {
    await assertNoErrorsInCode(r'''
class A {
  int? get foo => 0;
}

main() {
  A a = A()..foo?.isEven;
  a;
}
''');

    final node = findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: self::@class::A
        type: A
      staticElement: self::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  cascadeSections
    PropertyAccess
      target: PropertyAccess
        operator: ..
        propertyName: SimpleIdentifier
          token: foo
          staticElement: self::@class::A::@getter::foo
          staticType: int?
        staticType: int?
      operator: ?.
      propertyName: SimpleIdentifier
        token: isEven
        staticElement: dart:core::@class::int::@getter::isEven
        staticType: bool
      staticType: bool
  staticType: A
''');
  }

  test_nullShorting_cascade3() async {
    await assertNoErrorsInCode(r'''
class A {
  A? get foo => this;
  A? get bar => this;
  A? get baz => this;
}

main() {
  A a = A()..foo?.bar?.baz;
  a;
}
''');

    final node = findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: self::@class::A
        type: A
      staticElement: self::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  cascadeSections
    PropertyAccess
      target: PropertyAccess
        target: PropertyAccess
          operator: ..
          propertyName: SimpleIdentifier
            token: foo
            staticElement: self::@class::A::@getter::foo
            staticType: A?
          staticType: A?
        operator: ?.
        propertyName: SimpleIdentifier
          token: bar
          staticElement: self::@class::A::@getter::bar
          staticType: A?
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: baz
        staticElement: self::@class::A::@getter::baz
        staticType: A?
      staticType: A?
  staticType: A
''');
  }

  test_nullShorting_cascade4() async {
    await assertNoErrorsInCode(r'''
A? get foo => A();

class A {
  A get bar => this;
  A? get baz => this;
  A get baq => this;
}

main() {
  foo?.bar?..baz?.baq;
}
''');

    final node = findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: PropertyAccess
    target: SimpleIdentifier
      token: foo
      staticElement: self::@getter::foo
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: bar
      staticElement: self::@class::A::@getter::bar
      staticType: A
    staticType: A?
  cascadeSections
    PropertyAccess
      target: PropertyAccess
        operator: ?..
        propertyName: SimpleIdentifier
          token: baz
          staticElement: self::@class::A::@getter::baz
          staticType: A?
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: baq
        staticElement: self::@class::A::@getter::baq
        staticType: A
      staticType: A
  staticType: A?
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
  (a).foo;
}
''');

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
    staticType: int
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
  (a).foo;
}
''');

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_ofEnum_read() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  int get foo => 0;
}

void f(E e) {
  (e).foo;
}
''');

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: e
      staticElement: self::@function::f::@parameter::e
      staticType: E
    rightParenthesis: )
    staticType: E
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@enum::E::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_ofEnum_read_fromMixin() async {
    await assertNoErrorsInCode('''
mixin M on Enum {
  int get foo => 0;
}

enum E with M {
  v;
}

void f(E e) {
  (e).foo;
}
''');

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: e
      staticElement: self::@function::f::@parameter::e
      staticType: E
    rightParenthesis: )
    staticType: E
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@mixin::M::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_ofEnum_write() async {
    await assertNoErrorsInCode('''
enum E {
  v;
  set foo(int _) {}
}

void f(E e) {
  (e).foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: e
        staticElement: self::@function::f::@parameter::e
        staticType: E
      rightParenthesis: )
      staticType: E
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
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

  test_ofExtension_onRecordType() async {
    await assertNoErrorsInCode('''
extension IntStringRecordExtension on (int, String) {
  int get foo => 0;
}

void f((int, String) r) {
  r.foo;
}
''');

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@extension::IntStringRecordExtension::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_ofExtension_onRecordType_generic() async {
    await assertNoErrorsInCode('''
extension BiRecordExtension<T, U> on (T, U) {
  Map<T, U> get foo => {};
}

void f((int, String) r) {
  r.foo;
}
''');

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: PropertyAccessorMember
      base: self::@extension::BiRecordExtension::@getter::foo
      substitution: {T: int, U: String}
    staticType: Map<int, String>
  staticType: Map<int, String>
''');
  }

  test_ofMixin_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment mixin A {
  augment int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

mixin A {
  int get foo => 0;
}

void f(A a) {
  (a).foo;
}
''');

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@mixin::A::@getter::foo
    staticType: int
  staticType: int
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
  (a).foo;
}
''');

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@augmentation::package:test/a.dart::@mixin::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_namedField() async {
    await assertNoErrorsInCode('''
void f(({int foo}) r) {
  r.foo;
}
''');

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_namedField_hasExtension() async {
    await assertNoErrorsInCode('''
extension E on ({int foo}) {
  bool get foo => false;
}

void f(({int foo}) r) {
  r.foo;
}
''');

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_namedField_language219() async {
    newFile('$testPackageLibPath/a.dart', r'''
final r = (foo: 42);
''');

    await assertNoErrorsInCode('''
// @dart = 2.19
import 'a.dart';
void f() {
  r.foo;
}
''');

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: package:test/a.dart::@getter::r
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_namedField_nullAware() async {
    await assertNoErrorsInCode('''
void f(({int foo})? r) {
  r?.foo;
}
''');

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: ({int foo})?
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: int
  staticType: int?
''');
  }

  test_ofRecordType_namedField_ofTypeParameter() async {
    await assertNoErrorsInCode(r'''
void f<T extends ({int foo})>(T r) {
  r.foo;
}
''');

    final node = findNode.propertyAccess(r'foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_Object_hashCode() async {
    await assertNoErrorsInCode('''
void f(({int foo}) r) {
  r.hashCode;
}
''');

    final node = findNode.propertyAccess('hashCode;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    staticElement: dart:core::@class::Object::@getter::hashCode
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_positionalField_0() async {
    await assertNoErrorsInCode(r'''
void f((int, String) r) {
  r.$1;
}
''');

    final node = findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    staticElement: <null>
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_positionalField_0_hasExtension() async {
    await assertNoErrorsInCode(r'''
extension E on (int, String) {
  bool get $1 => false;
}

void f((int, String) r) {
  r.$1;
}
''');

    final node = findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    staticElement: <null>
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_positionalField_1() async {
    await assertNoErrorsInCode(r'''
void f((int, String) r) {
  r.$2;
}
''');

    final node = findNode.propertyAccess(r'$2;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $2
    staticElement: <null>
    staticType: String
  staticType: String
''');
  }

  test_ofRecordType_positionalField_2_fromExtension() async {
    await assertNoErrorsInCode(r'''
extension on (int, String) {
  bool get $3 => false;
}

void f((int, String) r) {
  r.$3;
}
''');

    final node = findNode.propertyAccess(r'$3;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $3
    staticElement: self::@extension::0::@getter::$3
    staticType: bool
  staticType: bool
''');
  }

  test_ofRecordType_positionalField_2_unresolved() async {
    await assertErrorsInCode(r'''
void f((int, String) r) {
  r.$3;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 30, 2),
    ]);

    final node = findNode.propertyAccess(r'$3;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $3
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_ofRecordType_positionalField_dollarDigitLetter() async {
    await assertErrorsInCode(r'''
void f((int, String) r) {
  r.$0a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 30, 3),
    ]);

    final node = findNode.propertyAccess(r'$0a;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $0a
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_ofRecordType_positionalField_dollarName() async {
    await assertErrorsInCode(r'''
void f((int, String) r) {
  r.$zero;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 30, 5),
    ]);

    final node = findNode.propertyAccess(r'$zero;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $zero
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_ofRecordType_positionalField_language219() async {
    newFile('$testPackageLibPath/a.dart', r'''
final r = (0, 'bar');
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.19
import 'a.dart';
void f() {
  r.$1;
}
''');

    final node = findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: package:test/a.dart::@getter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    staticElement: <null>
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_positionalField_letterDollarZero() async {
    await assertErrorsInCode(r'''
void f((int, String) r) {
  r.a$0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 30, 3),
    ]);

    final node = findNode.propertyAccess(r'a$0;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: a$0
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_ofRecordType_positionalField_ofTypeParameter() async {
    await assertNoErrorsInCode(r'''
void f<T extends (int, String)>(T r) {
  r.$1;
}
''');

    final node = findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    staticElement: <null>
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_unresolved() async {
    await assertErrorsInCode('''
void f(({int foo}) r) {
  r.bar;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 28, 3),
    ]);

    final node = findNode.propertyAccess('bar;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: bar
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  /// Even though positional fields can have names, these names cannot be
  /// used to access these fields.
  test_ofRecordType_unresolved_positionalField() async {
    await assertErrorsInCode('''
void f((int foo, String) r) {
  r.foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 34, 3),
    ]);

    final node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: self::@function::f::@parameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_ofSwitchExpression() async {
    await assertNoErrorsInCode('''
void f(Object? x) {
  (switch (x) {
    _ => 0,
  }.isEven);
}
''');

    var node = findNode.propertyAccess('.isEven');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: IntegerLiteral
          literal: 0
          staticType: int
    rightBracket: }
    staticType: int
  operator: .
  propertyName: SimpleIdentifier
    token: isEven
    staticElement: dart:core::@class::int::@getter::isEven
    staticType: bool
  staticType: bool
''');
  }

  test_unresolved_identifier() async {
    await assertErrorsInCode('''
void f() {
  (a).foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 14, 1),
    ]);

    final node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: <null>
      staticType: InvalidType
    rightParenthesis: )
    staticType: InvalidType
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }
}

@reflectiveTest
class PropertyAccessResolutionTest_WithoutNullSafety
    extends PubPackageResolutionTest
    with PropertyAccessResolutionTestCases, WithoutNullSafetyMixin {}

mixin PropertyAccessResolutionTestCases on PubPackageResolutionTest {
  test_extensionOverride_read() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  int get foo => 0;
}

void f(A a) {
  E(a).foo;
}
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@extension::E::@getter::foo
    staticType: int
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A*
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A*
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@extension::E::@getter::foo
    staticType: int*
  staticType: int*
''');
    }
  }

  test_extensionOverride_readWrite_assignment() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  int get foo => 0;
  set foo(num _) {}
}

void f(A a) {
  E(a).foo += 1;
}
''');

    var assignment = findNode.assignment('foo += 1');
    if (isNullSafetyEnabled) {
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
            staticElement: self::@function::f::@parameter::a
            staticType: A
        rightParenthesis: )
      element: self::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@extension::E::@getter::foo
  readType: int
  writeElement: self::@extension::E::@setter::foo
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
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
            staticElement: self::@function::f::@parameter::a
            staticType: A*
        rightParenthesis: )
      element: self::@extension::E
      extendedType: A*
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: ParameterMember
      base: dart:core::@class::num::@method::+::@parameter::other
      isLegacy: true
    staticType: int*
  readElement: self::@extension::E::@getter::foo
  readType: int*
  writeElement: self::@extension::E::@setter::foo
  writeType: num*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_extensionOverride_write() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  set foo(int _) {}
}

void f(A a) {
  E(a).foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    if (isNullSafetyEnabled) {
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
            staticElement: self::@function::f::@parameter::a
            staticType: A
        rightParenthesis: )
      element: self::@extension::E
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
    literal: 1
    parameter: self::@extension::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
    } else {
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
            staticElement: self::@function::f::@parameter::a
            staticType: A*
        rightParenthesis: )
      element: self::@extension::E
      extendedType: A*
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: self::@extension::E::@setter::foo::@parameter::_
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@setter::foo
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
    }
  }

  test_functionType_call_read() async {
    await assertNoErrorsInCode('''
void f(int Function(String) a) {
  (a).call;
}
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int Function(String)
    rightParenthesis: )
    staticType: int Function(String)
  operator: .
  propertyName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: int Function(String)
  staticType: int Function(String)
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int* Function(String*)*
    rightParenthesis: )
    staticType: int* Function(String*)*
  operator: .
  propertyName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: int* Function(String*)*
  staticType: int* Function(String*)*
''');
    }
  }

  test_instanceCreation_read() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f() {
  A().foo;
}
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: self::@class::A
        type: A
      staticElement: self::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: self::@class::A
        type: A*
      staticElement: self::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A*
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: int*
  staticType: int*
''');
    }
  }

  test_instanceCreation_readWrite_assignment() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f() {
  A().foo += 1;
}
''');

    var assignment = findNode.assignment('foo += 1');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: self::@class::A
          type: A
        staticElement: self::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
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
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: self::@class::A
          type: A*
        staticElement: self::@class::A::@constructor::new
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

  test_instanceCreation_write() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

void f() {
  A().foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: self::@class::A
          type: A
        staticElement: self::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
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
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: self::@class::A
          type: A*
        staticElement: self::@class::A::@constructor::new
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

  test_invalid_inDefaultValue_nullAware() async {
    await assertInvalidTestCode('''
void f({a = b?.foo}) {}
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: b
    staticElement: <null>
    staticType: InvalidType
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: b
    staticElement: <null>
    staticType: InvalidType
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
    }
  }

  test_invalid_inDefaultValue_nullAware2() async {
    await assertInvalidTestCode('''
typedef void F({a = b?.foo});
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: b
    staticElement: <null>
    staticType: InvalidType
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: b
    staticElement: <null>
    staticType: InvalidType
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
    }
  }

  test_invalid_inDefaultValue_nullAware_cascade() async {
    await assertInvalidTestCode('''
void f({a = b?..foo}) {}
''');

    final node = findNode.defaultParameter('a =');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
DefaultFormalParameter
  parameter: SimpleFormalParameter
    name: a
    declaredElement: self::@function::f::@parameter::a
      type: dynamic
  separator: =
  defaultValue: CascadeExpression
    target: SimpleIdentifier
      token: b
      staticElement: <null>
      staticType: InvalidType
    cascadeSections
      PropertyAccess
        operator: ?..
        propertyName: SimpleIdentifier
          token: foo
          staticElement: <null>
          staticType: InvalidType
        staticType: InvalidType
    staticType: InvalidType
  declaredElement: self::@function::f::@parameter::a
    type: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
DefaultFormalParameter
  parameter: SimpleFormalParameter
    name: a
    declaredElement: self::@function::f::@parameter::a
      type: dynamic
  separator: =
  defaultValue: PropertyAccess
    target: PropertyAccess
      target: SimpleIdentifier
        token: b
        staticElement: <null>
        staticType: InvalidType
      operator: ?.
      propertyName: SimpleIdentifier
        token: <empty> <synthetic>
        staticElement: <null>
        staticType: InvalidType
      staticType: InvalidType
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: InvalidType
    staticType: InvalidType
  declaredElement: self::@function::f::@parameter::a
    type: dynamic
''');
    }
  }

  test_ofDynamic_read_hash() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  (a).hash;
}
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: hash
    staticElement: <null>
    staticType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: hash
    staticElement: <null>
    staticType: dynamic
  staticType: dynamic
''');
    }
  }

  test_ofDynamic_read_hashCode() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  (a).hashCode;
}
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    staticElement: dart:core::@class::Object::@getter::hashCode
    staticType: int
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    staticElement: PropertyAccessorMember
      base: dart:core::@class::Object::@getter::hashCode
      isLegacy: true
    staticType: int*
  staticType: int*
''');
    }
  }

  test_ofDynamic_read_runtimeType() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  (a).runtimeType;
}
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: runtimeType
    staticElement: dart:core::@class::Object::@getter::runtimeType
    staticType: Type
  staticType: Type
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: runtimeType
    staticElement: PropertyAccessorMember
      base: dart:core::@class::Object::@getter::runtimeType
      isLegacy: true
    staticType: Type*
  staticType: Type*
''');
    }
  }

  test_ofDynamic_read_toString() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  (a).toString;
}
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: toString
    staticElement: dart:core::@class::Object::@method::toString
    staticType: String Function()
  staticType: String Function()
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: toString
    staticElement: MethodMember
      base: dart:core::@class::Object::@method::toString
      isLegacy: true
    staticType: String* Function()*
  staticType: String* Function()*
''');
    }
  }

  test_ofExtension_read() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  int get foo => 0;
}

void f(A a) {
  A().foo;
}
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: self::@class::A
        type: A
      staticElement: self::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@extension::E::@getter::foo
    staticType: int
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: self::@class::A
        type: A*
      staticElement: self::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A*
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@extension::E::@getter::foo
    staticType: int*
  staticType: int*
''');
    }
  }

  test_ofExtension_readWrite_assignment() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  int get foo => 0;
  set foo(num _) {}
}

void f() {
  A().foo += 1;
}
''');

    var assignment = findNode.assignment('foo += 1');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: self::@class::A
          type: A
        staticElement: self::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@extension::E::@getter::foo
  readType: int
  writeElement: self::@extension::E::@setter::foo
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
    } else {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: self::@class::A
          type: A*
        staticElement: self::@class::A::@constructor::new
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
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: ParameterMember
      base: dart:core::@class::num::@method::+::@parameter::other
      isLegacy: true
    staticType: int*
  readElement: self::@extension::E::@getter::foo
  readType: int*
  writeElement: self::@extension::E::@setter::foo
  writeType: num*
  staticElement: MethodMember
    base: dart:core::@class::num::@method::+
    isLegacy: true
  staticType: int*
''');
    }
  }

  test_ofExtension_write() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A {
  set foo(int _) {}
}

void f() {
  A().foo = 1;
}
''');

    var assignment = findNode.assignment('foo = 1');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: self::@class::A
          type: A
        staticElement: self::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: self::@extension::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
    } else {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: self::@class::A
          type: A*
        staticElement: self::@class::A::@constructor::new
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
    literal: 1
    parameter: self::@extension::E::@setter::foo::@parameter::_
    staticType: int*
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@setter::foo
  writeType: int*
  staticElement: <null>
  staticType: int*
''');
    }
  }

  test_super_read() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

class B extends A {
  void f() {
    super.foo;
  }
}
''');

    final node = findNode.propertyAccess('super.foo');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B*
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: int*
  staticType: int*
''');
    }
  }

  test_super_readWrite_assignment() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

class B extends A {
  void f() {
    super.foo += 1;
  }
}
''');

    var assignment = findNode.assignment('foo += 1');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
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

  test_super_write() async {
    await assertNoErrorsInCode('''
class A {
  int foo = 0;
}

class B extends A {
  void f() {
    super.foo = 1;
  }
}
''');

    var assignment = findNode.assignment('foo = 1');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
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

  test_targetTypeParameter_dynamicBounded() async {
    await assertNoErrorsInCode('''
class A<T extends dynamic> {
  void f(T t) {
    (t).foo;
  }
}
''');

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: t
      staticElement: self::@class::A::@method::f::@parameter::t
      staticType: T
    rightParenthesis: )
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: t
      staticElement: self::@class::A::@method::f::@parameter::t
      staticType: T*
    rightParenthesis: )
    staticType: T*
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  staticType: dynamic
''');
    }
  }

  test_targetTypeParameter_noBound() async {
    await resolveTestCode('''
class C<T> {
  void f(T t) {
    (t).foo;
  }
}
''');
    assertErrorsInResult(expectedErrorsByNullability(
      nullable: [
        error(CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE,
            37, 3),
      ],
      legacy: [
        error(CompileTimeErrorCode.UNDEFINED_GETTER, 37, 3),
      ],
    ));

    final node = findNode.singlePropertyAccess;
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: t
      staticElement: self::@class::C::@method::f::@parameter::t
      staticType: T
    rightParenthesis: )
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
    } else {
      assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: t
      staticElement: self::@class::C::@method::f::@parameter::t
      staticType: T*
    rightParenthesis: )
    staticType: T*
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
    }
  }

  test_tearOff_method() async {
    await assertNoErrorsInCode('''
class A {
  void foo(int a) {}
}

bar() {
  A().foo;
}
''');

    var identifier = findNode.simple('foo;');
    assertElement(identifier, findElement.method('foo'));
    assertType(identifier, 'void Function(int)');
  }
}
