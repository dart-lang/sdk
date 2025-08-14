// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PropertyAccessResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PropertyAccessResolutionTest extends PubPackageResolutionTest {
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

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element2: <testLibrary>::@extension::E
    extendedType: A
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: int
  staticType: int
''');
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
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element2: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement2: <testLibrary>::@extension::E::@setter::foo
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
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
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element2: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_functionType_call_read() async {
    await assertNoErrorsInCode('''
void f(int Function(String) a) {
  (a).call;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int Function(String)
    rightParenthesis: )
    staticType: int Function(String)
  operator: .
  propertyName: SimpleIdentifier
    token: call
    element: <null>
    staticType: int Function(String)
  staticType: int Function(String)
''');
  }

  test_implicitCall_tearOff_nullable() async {
    await assertErrorsInCode(
      '''
class A {
  int call() => 0;
}

class B {
  A? a;
}

int Function() foo() {
  return B().a; // ref
}
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 85, 5)],
    );

    var identifier = findNode.simple('a; // ref');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@class::B::@getter::a
  staticType: A?
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_inClass_explicitThis_inDeclaration_augmentationAugments() async {
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

  void f() {
    this.foo;
  }
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getterAugmentation::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: int
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_inClass_explicitThis_inDeclaration_augmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

int get foo => 0;

class A {
  void f() {
    this.foo;
  }
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo#element
    staticType: int
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_inClass_explicitThis_inDeclaration_augmentationDeclares_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

int get foo => 0;

class A {
  void f() {
    this.foo;
  }
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@method::foo#element
    staticType: void Function()
  staticType: void Function()
''');
  }

  test_inClass_superExpression_identifier_setter() async {
    await assertErrorsInCode(
      '''
class A {
  set foo(int _) {}

  void f() {
    super.foo;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedSuperGetter, 54, 3)],
    );

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function(int)
  staticType: void Function(int)
''');
  }

  test_inClass_superQualifier_identifier_setter() async {
    await assertErrorsInCode(
      '''
class A {
  set foo(int _) {}
}

class B extends A {
  set foo(int _) {}

  void f() {
    super.foo;
  }
}
''',
      [error(CompileTimeErrorCode.undefinedSuperGetter, 97, 3)],
    );

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function(int)
  staticType: void Function(int)
''');
  }

  test_inExtensionType_explicitThis_declared() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;

  void f() {
    this.foo;
  }
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@getter::foo
    staticType: int
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
    this.foo;
  }
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: X
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
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

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element2: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
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
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element2: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
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
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element2: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_invalid_inDefaultValue_nullAware() async {
    await assertInvalidTestCode('''
void f({a = b?.foo}) {}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: b
    element: <null>
    staticType: InvalidType
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_invalid_inDefaultValue_nullAware2() async {
    await assertInvalidTestCode('''
typedef void F({a = b?.foo});
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: b
    element: <null>
    staticType: InvalidType
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_invalid_inDefaultValue_nullAware_cascade() async {
    await assertInvalidTestCode('''
void f({a = b?..foo}) {}
''');

    var node = findNode.defaultParameter('a =');
    assertResolvedNodeText(node, r'''
DefaultFormalParameter
  parameter: SimpleFormalParameter
    name: a
    declaredElement: <testLibraryFragment> a@8
      element: hasImplicitType isPublic
        type: dynamic
  separator: =
  defaultValue: CascadeExpression
    target: SimpleIdentifier
      token: b
      element: <null>
      staticType: InvalidType
    cascadeSections
      PropertyAccess
        operator: ?..
        propertyName: SimpleIdentifier
          token: foo
          element: <null>
          staticType: InvalidType
        staticType: InvalidType
    staticType: InvalidType
  declaredElement: <testLibraryFragment> a@8
    element: hasImplicitType isPublic
      type: dynamic
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

    var node = findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  cascadeSections
    PropertyAccess
      operator: ?..
      propertyName: SimpleIdentifier
        token: foo
        element: <testLibrary>::@class::A::@getter::foo
        staticType: int
      staticType: int
    PropertyAccess
      operator: ..
      propertyName: SimpleIdentifier
        token: bar
        element: <testLibrary>::@class::A::@getter::bar
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

    var node = findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element2: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
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
          element: <testLibrary>::@class::A::@getter::foo
          staticType: int?
        staticType: int?
      operator: ?.
      propertyName: SimpleIdentifier
        token: isEven
        element: dart:core::@class::int::@getter::isEven
        staticType: bool
      staticType: bool?
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

    var node = findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element2: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
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
            element: <testLibrary>::@class::A::@getter::foo
            staticType: A?
          staticType: A?
        operator: ?.
        propertyName: SimpleIdentifier
          token: bar
          element: <testLibrary>::@class::A::@getter::bar
          staticType: A?
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: baz
        element: <testLibrary>::@class::A::@getter::baz
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

    var node = findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: PropertyAccess
    target: SimpleIdentifier
      token: foo
      element: <testLibrary>::@getter::foo
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: bar
      element: <testLibrary>::@class::A::@getter::bar
      staticType: A
    staticType: A?
  cascadeSections
    PropertyAccess
      target: PropertyAccess
        operator: ?..
        propertyName: SimpleIdentifier
          token: baz
          element: <testLibrary>::@class::A::@getter::baz
          staticType: A?
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: baq
        element: <testLibrary>::@class::A::@getter::baq
        staticType: A
      staticType: A?
  staticType: A?
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
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
  (a).foo;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getterAugmentation::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: int
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
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
  (a).foo;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo#element
    staticType: int
  staticType: int
''');
  }

  test_ofClass_inheritedGetter_ofGenericClass_usesTypeParameter() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  T get foo => throw 0;
}

class B extends A<int> {}

void f(B b) {
  (b).foo;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: B
    rightParenthesis: )
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: GetterMember
      baseElement: <testLibrary>::@class::A::@getter::foo
      substitution: {T: int}
    staticType: int
  staticType: int
''');
  }

  test_ofClass_inheritedGetter_ofGenericClass_usesTypeParameterNot() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  double get foo => throw 0;
}

class B extends A<int> {}

void f(B b) {
  (b).foo;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: B
    rightParenthesis: )
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: double
  staticType: double
''');
  }

  test_ofDynamic_read_hash() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  (a).hash;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: hash
    element: <null>
    staticType: dynamic
  staticType: dynamic
''');
  }

  test_ofDynamic_read_hashCode() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  (a).hashCode;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    element: dart:core::@class::Object::@getter::hashCode
    staticType: int
  staticType: int
''');
  }

  test_ofDynamic_read_runtimeType() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  (a).runtimeType;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: runtimeType
    element: dart:core::@class::Object::@getter::runtimeType
    staticType: Type
  staticType: Type
''');
  }

  test_ofDynamic_read_toString() async {
    await assertNoErrorsInCode('''
void f(dynamic a) {
  (a).toString;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: toString
    element: dart:core::@class::Object::@method::toString
    staticType: String Function()
  staticType: String Function()
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

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: e
      element: <testLibrary>::@function::f::@formalParameter::e
      staticType: E
    rightParenthesis: )
    staticType: E
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@enum::E::@getter::foo
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

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: e
      element: <testLibrary>::@function::f::@formalParameter::e
      staticType: E
    rightParenthesis: )
    staticType: E
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::M::@getter::foo
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
        element: <testLibrary>::@function::f::@formalParameter::e
        staticType: E
      rightParenthesis: )
      staticType: E
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@enum::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@enum::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_ofExtension_augmentation_read() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment extension E {
  int get foo => 0;
}
''');

    await assertNoErrorsInCode('''
part 'a.dart';

class A {}

extension E on A {}

void f(A a) {
  (a).foo;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@getter::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@getter::foo#element
    staticType: int
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_ofExtension_augmentation_write() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment extension E {
  set foo(int _) {}
}
''');

    await assertNoErrorsInCode('''
part 'a.dart';

class A {}

extension E on A {}

void f(A a) {
  (a).foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@setter::foo
  writeElement2: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_ofExtension_augmentationGeneric_read() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment extension E<U2> {
  U2 get foo => throw 0;
}
''');

    await assertNoErrorsInCode('''
part 'a.dart';

class A<T> {}

extension E<U1> on A<U1> {}

void f(A<int> a) {
  (a).foo;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A<int>
    rightParenthesis: )
    staticType: A<int>
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: GetterMember
      base: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@getter::foo
      augmentationSubstitution: {U2: U1}
      substitution: {U1: int}
    element: <testLibrary>::@fragment::package:test/a.dart::@extensionAugmentation::E::@getter::foo#element
    staticType: int
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::IntStringRecordExtension::@getter::foo
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: GetterMember
      baseElement: <testLibrary>::@extension::BiRecordExtension::@getter::foo
      substitution: {T: int, U: String}
    staticType: Map<int, String>
  staticType: Map<int, String>
''');
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

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element2: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: int
  staticType: int
''');
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
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element2: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement2: <testLibrary>::@extension::E::@setter::foo
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
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
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element2: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_ofExtensionType_read() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;
}

void f(A a) {
  (a).foo;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_ofExtensionType_read_ofObject() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {}

void f(A a) {
  (a).hashCode;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    element: dart:core::@class::Object::@getter::hashCode
    staticType: int
  staticType: int
''');
  }

  test_ofExtensionType_read_ofObjectQuestion() async {
    await assertNoErrorsInCode(r'''
extension type A(int? it) {}

void f(A a) {
  (a).hashCode;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    element: dart:core::@class::Object::@getter::hashCode
    staticType: int
  staticType: int
''');
  }

  test_ofExtensionType_read_unresolved() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}

void f(A a) {
  (a).foo;
}
''',
      [error(CompileTimeErrorCode.undefinedGetter, 49, 3)],
    );

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_ofExtensionType_write() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  set foo(int _) {}
}

void f(A a) {
  (a).foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extensionType::A::@setter::foo::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@extensionType::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_ofMixin_augmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment mixin A {
  augment int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

mixin A {
  int get foo => 0;
}

void f(A a) {
  (a).foo;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getterAugmentation::foo
    element: <testLibraryFragment>::@mixin::A::@getter::foo#element
    staticType: int
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
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
  (a).foo;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo
    element: <testLibrary>::@fragment::package:test/a.dart::@mixinAugmentation::A::@getter::foo#element
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: package:test/a.dart::@getter::r
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: ({int foo})?
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
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

    var node = findNode.propertyAccess(r'foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
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

    var node = findNode.propertyAccess('hashCode;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    element: dart:core::@class::Object::@getter::hashCode
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

    var node = findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    element: <null>
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

    var node = findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    element: <null>
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

    var node = findNode.propertyAccess(r'$2;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $2
    element: <null>
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

    var node = findNode.propertyAccess(r'$3;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $3
    element: <testLibrary>::@extension::0::@getter::$3
    staticType: bool
  staticType: bool
''');
  }

  test_ofRecordType_positionalField_2_unresolved() async {
    await assertErrorsInCode(
      r'''
void f((int, String) r) {
  r.$3;
}
''',
      [error(CompileTimeErrorCode.undefinedGetter, 30, 2)],
    );

    var node = findNode.propertyAccess(r'$3;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $3
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_ofRecordType_positionalField_dollarDigitLetter() async {
    await assertErrorsInCode(
      r'''
void f((int, String) r) {
  r.$0a;
}
''',
      [error(CompileTimeErrorCode.undefinedGetter, 30, 3)],
    );

    var node = findNode.propertyAccess(r'$0a;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $0a
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  test_ofRecordType_positionalField_dollarName() async {
    await assertErrorsInCode(
      r'''
void f((int, String) r) {
  r.$zero;
}
''',
      [error(CompileTimeErrorCode.undefinedGetter, 30, 5)],
    );

    var node = findNode.propertyAccess(r'$zero;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $zero
    element: <null>
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

    var node = findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: package:test/a.dart::@getter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    element: <null>
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_positionalField_letterDollarZero() async {
    await assertErrorsInCode(
      r'''
void f((int, String) r) {
  r.a$0;
}
''',
      [error(CompileTimeErrorCode.undefinedGetter, 30, 3)],
    );

    var node = findNode.propertyAccess(r'a$0;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: a$0
    element: <null>
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

    var node = findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    element: <null>
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_unresolved() async {
    await assertErrorsInCode(
      '''
void f(({int foo}) r) {
  r.bar;
}
''',
      [error(CompileTimeErrorCode.undefinedGetter, 28, 3)],
    );

    var node = findNode.propertyAccess('bar;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: bar
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }

  /// Even though positional fields can have names, these names cannot be
  /// used to access these fields.
  test_ofRecordType_unresolved_positionalField() async {
    await assertErrorsInCode(
      '''
void f((int foo, String) r) {
  r.foo;
}
''',
      [error(CompileTimeErrorCode.undefinedGetter, 34, 3)],
    );

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
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
      element: <testLibrary>::@function::f::@formalParameter::x
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
    element: dart:core::@class::int::@getter::isEven
    staticType: bool
  staticType: bool
''');
  }

  test_rewrite_nullShorting() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  T Function<T>(T) get f;
}
abstract class B {
  A get a;
}
int Function(int)? f(B? b) => b?.a.f;
''');

    var node = findNode.functionReference('b?.a.f');
    assertResolvedNodeText(node, r'''FunctionReference
  function: PropertyAccess
    target: PropertyAccess
      target: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: B?
      operator: ?.
      propertyName: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@getter::a
        staticType: A
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: f
      element: <testLibrary>::@class::A::@getter::f
      staticType: T Function<T>(T)
    staticType: T Function<T>(T)
  staticType: int Function(int)?
  typeArgumentTypes
    int
''');
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

    var node = findNode.propertyAccess('super.foo');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
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
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
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
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_targetTypeParameter_dynamicBounded() async {
    await assertNoErrorsInCode('''
class A<T extends dynamic> {
  void f(T t) {
    (t).foo;
  }
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: t
      element: <testLibrary>::@class::A::@method::f::@formalParameter::t
      staticType: T
    rightParenthesis: )
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: dynamic
  staticType: dynamic
''');
  }

  test_targetTypeParameter_noBound() async {
    await assertErrorsInCode(
      '''
class C<T> {
  void f(T t) {
    (t).foo;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.uncheckedPropertyAccessOfNullableValue,
          37,
          3,
        ),
      ],
    );

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: t
      element: <testLibrary>::@class::C::@method::f::@formalParameter::t
      staticType: T
    rightParenthesis: )
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
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
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@class::A::@method::foo
  staticType: void Function(int)
''');
  }

  test_unresolved_identifier() async {
    await assertErrorsInCode(
      '''
void f() {
  (a).foo;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 14, 1)],
    );

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <null>
      staticType: InvalidType
    rightParenthesis: )
    staticType: InvalidType
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }
}
