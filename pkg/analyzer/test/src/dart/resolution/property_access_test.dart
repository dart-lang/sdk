// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PropertyAccessResolutionTest);
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
          parameter: <null>
          staticElement: <testLibraryFragment>::@function::f::@parameter::a
          element: <testLibraryFragment>::@function::f::@parameter::a#element
          staticType: A
      rightParenthesis: )
    element: <testLibraryFragment>::@extension::E
    element2: <testLibraryFragment>::@extension::E#element
    extendedType: A
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@getter::foo
    element: <testLibraryFragment>::@extension::E::@getter::foo#element
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
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@extension::E::@getter::foo
  readElement2: <testLibraryFragment>::@extension::E::@getter::foo#element
  readType: int
  writeElement: <testLibraryFragment>::@extension::E::@setter::foo
  writeElement2: <testLibraryFragment>::@extension::E::@setter::foo#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
            parameter: <null>
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: A
        rightParenthesis: )
      element: <testLibraryFragment>::@extension::E
      element2: <testLibraryFragment>::@extension::E#element
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@extension::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::foo
  writeElement2: <testLibraryFragment>::@extension::E::@setter::foo#element
  writeType: int
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: int Function(String)
    rightParenthesis: )
    staticType: int Function(String)
  operator: .
  propertyName: SimpleIdentifier
    token: call
    staticElement: <null>
    element: <null>
    staticType: int Function(String)
  staticType: int Function(String)
''');
  }

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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
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
    staticElement: <testLibraryFragment>::@extensionType::A::@getter::foo
    element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
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
        element: <testLibraryFragment>::@class::A
        element2: <testLibraryFragment>::@class::A#element
        type: A
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
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
          element: <testLibraryFragment>::@class::A
          element2: <testLibraryFragment>::@class::A#element
          type: A
        staticElement: <testLibraryFragment>::@class::A::@constructor::new
        element: <testLibraryFragment>::@class::A::@constructor::new#element
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@getter::foo
  readElement2: <testLibraryFragment>::@class::A::@getter::foo#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::foo
  writeElement2: <testLibraryFragment>::@class::A::@setter::foo#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
          element: <testLibraryFragment>::@class::A
          element2: <testLibraryFragment>::@class::A#element
          type: A
        staticElement: <testLibraryFragment>::@class::A::@constructor::new
        element: <testLibraryFragment>::@class::A::@constructor::new#element
      argumentList: ArgumentList
        leftParenthesis: (
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
    literal: 1
    parameter: <testLibraryFragment>::@class::A::@setter::foo::@parameter::_foo
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@setter::foo
  writeElement2: <testLibraryFragment>::@class::A::@setter::foo#element
  writeType: int
  staticElement: <null>
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
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    declaredElement: <testLibraryFragment>::@function::f::@parameter::a
      type: dynamic
  separator: =
  defaultValue: CascadeExpression
    target: SimpleIdentifier
      token: b
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    cascadeSections
      PropertyAccess
        operator: ?..
        propertyName: SimpleIdentifier
          token: foo
          staticElement: <null>
          element: <null>
          staticType: InvalidType
        staticType: InvalidType
    staticType: InvalidType
  declaredElement: <testLibraryFragment>::@function::f::@parameter::a
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  cascadeSections
    PropertyAccess
      operator: ?..
      propertyName: SimpleIdentifier
        token: foo
        staticElement: <testLibraryFragment>::@class::A::@getter::foo
        element: <testLibraryFragment>::@class::A::@getter::foo#element
        staticType: int
      staticType: int
    PropertyAccess
      operator: ..
      propertyName: SimpleIdentifier
        token: bar
        staticElement: <testLibraryFragment>::@class::A::@getter::bar
        element: <testLibraryFragment>::@class::A::@getter::bar#element
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
        element: <testLibraryFragment>::@class::A
        element2: <testLibraryFragment>::@class::A#element
        type: A
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
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
          staticElement: <testLibraryFragment>::@class::A::@getter::foo
          element: <testLibraryFragment>::@class::A::@getter::foo#element
          staticType: int?
        staticType: int?
      operator: ?.
      propertyName: SimpleIdentifier
        token: isEven
        staticElement: dart:core::<fragment>::@class::int::@getter::isEven
        element: dart:core::<fragment>::@class::int::@getter::isEven#element
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

    var node = findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibraryFragment>::@class::A
        element2: <testLibraryFragment>::@class::A#element
        type: A
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
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
            staticElement: <testLibraryFragment>::@class::A::@getter::foo
            element: <testLibraryFragment>::@class::A::@getter::foo#element
            staticType: A?
          staticType: A?
        operator: ?.
        propertyName: SimpleIdentifier
          token: bar
          staticElement: <testLibraryFragment>::@class::A::@getter::bar
          element: <testLibraryFragment>::@class::A::@getter::bar#element
          staticType: A?
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: baz
        staticElement: <testLibraryFragment>::@class::A::@getter::baz
        element: <testLibraryFragment>::@class::A::@getter::baz#element
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
      staticElement: <testLibraryFragment>::@getter::foo
      element: <testLibraryFragment>::@getter::foo#element
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: bar
      staticElement: <testLibraryFragment>::@class::A::@getter::bar
      element: <testLibraryFragment>::@class::A::@getter::bar#element
      staticType: A
    staticType: A?
  cascadeSections
    PropertyAccess
      target: PropertyAccess
        operator: ?..
        propertyName: SimpleIdentifier
          token: baz
          staticElement: <testLibraryFragment>::@class::A::@getter::baz
          element: <testLibraryFragment>::@class::A::@getter::baz#element
          staticType: A?
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: baq
        staticElement: <testLibraryFragment>::@class::A::@getter::baq
        element: <testLibraryFragment>::@class::A::@getter::baq#element
        staticType: A
      staticType: A
  staticType: A?
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: hash
    staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    staticElement: dart:core::<fragment>::@class::Object::@getter::hashCode
    element: dart:core::<fragment>::@class::Object::@getter::hashCode#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: runtimeType
    staticElement: dart:core::<fragment>::@class::Object::@getter::runtimeType
    element: dart:core::<fragment>::@class::Object::@getter::runtimeType#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: SimpleIdentifier
    token: toString
    staticElement: dart:core::<fragment>::@class::Object::@method::toString
    element: dart:core::<fragment>::@class::Object::@method::toString#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::e
      element: <testLibraryFragment>::@function::f::@parameter::e#element
      staticType: E
    rightParenthesis: )
    staticType: E
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@enum::E::@getter::foo
    element: <testLibraryFragment>::@enum::E::@getter::foo#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::e
      element: <testLibraryFragment>::@function::f::@parameter::e#element
      staticType: E
    rightParenthesis: )
    staticType: E
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@mixin::M::@getter::foo
    element: <testLibraryFragment>::@mixin::M::@getter::foo#element
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::e
        element: <testLibraryFragment>::@function::f::@parameter::e#element
        staticType: E
      rightParenthesis: )
      staticType: E
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@enum::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@enum::E::@setter::foo
  writeElement2: <testLibraryFragment>::@enum::E::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::IntStringRecordExtension::@getter::foo
    element: <testLibraryFragment>::@extension::IntStringRecordExtension::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: GetterMember
      base: <testLibraryFragment>::@extension::BiRecordExtension::@getter::foo
      substitution: {T: int, U: String}
    element: <testLibraryFragment>::@extension::BiRecordExtension::@getter::foo#element
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
        element: <testLibraryFragment>::@class::A
        element2: <testLibraryFragment>::@class::A#element
        type: A
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@getter::foo
    element: <testLibraryFragment>::@extension::E::@getter::foo#element
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
          element: <testLibraryFragment>::@class::A
          element2: <testLibraryFragment>::@class::A#element
          type: A
        staticElement: <testLibraryFragment>::@class::A::@constructor::new
        element: <testLibraryFragment>::@class::A::@constructor::new#element
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@extension::E::@getter::foo
  readElement2: <testLibraryFragment>::@extension::E::@getter::foo#element
  readType: int
  writeElement: <testLibraryFragment>::@extension::E::@setter::foo
  writeElement2: <testLibraryFragment>::@extension::E::@setter::foo#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
          element: <testLibraryFragment>::@class::A
          element2: <testLibraryFragment>::@class::A#element
          type: A
        staticElement: <testLibraryFragment>::@class::A::@constructor::new
        element: <testLibraryFragment>::@class::A::@constructor::new#element
      argumentList: ArgumentList
        leftParenthesis: (
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
    literal: 1
    parameter: <testLibraryFragment>::@extension::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::foo
  writeElement2: <testLibraryFragment>::@extension::E::@setter::foo#element
  writeType: int
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extensionType::A::@getter::foo
    element: <testLibraryFragment>::@extensionType::A::@getter::foo#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    staticElement: dart:core::<fragment>::@class::Object::@getter::hashCode
    element: dart:core::<fragment>::@class::Object::@getter::hashCode#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    staticElement: dart:core::<fragment>::@class::Object::@getter::hashCode
    element: dart:core::<fragment>::@class::Object::@getter::hashCode#element
    staticType: int
  staticType: int
''');
  }

  test_ofExtensionType_read_unresolved() async {
    await assertErrorsInCode(r'''
extension type A(int it) {}

void f(A a) {
  (a).foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 49, 3),
    ]);

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
    staticElement: <null>
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
    parameter: <testLibraryFragment>::@extensionType::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extensionType::A::@setter::foo
  writeElement2: <testLibraryFragment>::@extensionType::A::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: package:test/a.dart::<fragment>::@getter::r
    element: package:test/a.dart::<fragment>::@getter::r#element
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: ({int foo})?
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: hashCode
    staticElement: dart:core::<fragment>::@class::Object::@getter::hashCode
    element: dart:core::<fragment>::@class::Object::@getter::hashCode#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $2
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $3
    staticElement: <testLibraryFragment>::@extension::0::@getter::$3
    element: <testLibraryFragment>::@extension::0::@getter::$3#element
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

    var node = findNode.propertyAccess(r'$3;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $3
    staticElement: <null>
    element: <null>
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

    var node = findNode.propertyAccess(r'$0a;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $0a
    staticElement: <null>
    element: <null>
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

    var node = findNode.propertyAccess(r'$zero;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $zero
    staticElement: <null>
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
    staticElement: package:test/a.dart::<fragment>::@getter::r
    element: package:test/a.dart::<fragment>::@getter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    staticElement: <null>
    element: <null>
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

    var node = findNode.propertyAccess(r'a$0;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: a$0
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: $1
    staticElement: <null>
    element: <null>
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

    var node = findNode.propertyAccess('bar;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: ({int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: bar
    staticElement: <null>
    element: <null>
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

    var node = findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: r
    staticElement: <testLibraryFragment>::@function::f::@parameter::r
    element: <testLibraryFragment>::@function::f::@parameter::r#element
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
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
    staticElement: dart:core::<fragment>::@class::int::@getter::isEven
    element: dart:core::<fragment>::@class::int::@getter::isEven#element
    staticType: bool
  staticType: bool
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
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
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
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@getter::foo
  readElement2: <testLibraryFragment>::@class::A::@getter::foo#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::foo
  writeElement2: <testLibraryFragment>::@class::A::@setter::foo#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@class::A::@setter::foo::@parameter::_foo
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@setter::foo
  writeElement2: <testLibraryFragment>::@class::A::@setter::foo#element
  writeType: int
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@class::A::@method::f::@parameter::t
      element: <testLibraryFragment>::@class::A::@method::f::@parameter::t#element
      staticType: T
    rightParenthesis: )
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: dynamic
  staticType: dynamic
''');
  }

  test_targetTypeParameter_noBound() async {
    await assertErrorsInCode('''
class C<T> {
  void f(T t) {
    (t).foo;
  }
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE,
          37, 3),
    ]);

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: t
      staticElement: <testLibraryFragment>::@class::C::@method::f::@parameter::t
      element: <testLibraryFragment>::@class::C::@method::f::@parameter::t#element
      staticType: T
    rightParenthesis: )
    staticType: T
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
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
    assertElement(identifier, findElement.method('foo'));
    assertType(identifier, 'void Function(int)');
  }

  test_unresolved_identifier() async {
    await assertErrorsInCode('''
void f() {
  (a).foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 14, 1),
    ]);

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    rightParenthesis: )
    staticType: InvalidType
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: InvalidType
  staticType: InvalidType
''');
  }
}
