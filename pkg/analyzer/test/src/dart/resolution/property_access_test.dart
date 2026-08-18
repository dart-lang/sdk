// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
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
  test_constructorInvocation_read() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo = 0;
}

void f() {
  A().foo;
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: ConstructorInvocation
    constructorReference: ConstructorReference2
      typeReference: ConstructorTypeReference
        name: A
        element: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  target(v1): InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibrary>::@class::A
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

  test_constructorInvocation_readWrite_assignment() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo = 0;
}

void f() {
  A().foo += 1;
}
''');

    var node = result.findNode.assignment('foo += 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: ConstructorInvocation
      constructorReference: ConstructorReference2
        typeReference: ConstructorTypeReference
          name: A
          element: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    target(v1): InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@class::A
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
  rightHandSide2: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_constructorInvocation_write() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo = 0;
}

void f() {
  A().foo = 1;
}
''');

    var node = result.findNode.assignment('foo = 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: ConstructorInvocation
      constructorReference: ConstructorReference2
        typeReference: ConstructorTypeReference
          name: A
          element: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    target(v1): InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@class::A
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
  rightHandSide2: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_extensionOverride_read() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {
  int get foo => 0;
}

void f(A a) {
  E(a).foo;
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element: <testLibrary>::@extension::E
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {
  int get foo => 0;
  set foo(num _) {}
}

void f(A a) {
  E(a).foo += 1;
}
''');

    var node = result.findNode.assignment('foo += 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_extensionOverride_write() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {
  set foo(int _) {}
}

void f(A a) {
  E(a).foo = 1;
}
''');

    var node = result.findNode.assignment('foo = 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: ExtensionOverride
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          SimpleIdentifier
            token: a
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: A
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_functionType_call_read() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(int Function(String) a) {
  (a).call;
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int call() => 0;
}

class B {
  A? a;
}

int Function() foo() {
  return B().a; // ref
//       ^^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'A?' can't be returned from the function 'foo' because it has a return type of 'int Function()'.
}
''');

    var node = result.findNode.simple('a; // ref');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@class::B::@getter::a
  staticType: A?
''');
  }

  test_inClass_explicitThis_inDeclaration_augmentationAugments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo;

  void f() {
    this.foo;
  }
}

augment class A {
  augment int get foo => 0;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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

  test_inClass_explicitThis_inDeclaration_augmentationDeclares() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

class A {
  void f() {
    this.foo;
  }
}

augment class A {
  int get foo => 0;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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

  test_inClass_explicitThis_inDeclaration_augmentationDeclares_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

class A {
  void f() {
    this.foo;
  }
}

augment class A {
  void foo() {}
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: foo
  resolution: ExecutableTearOffResolution
    element: <testLibrary>::@class::A::@method::foo
    type: void Function()
  staticType: void Function()
V1: PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function()
  staticType: void Function()
''');
  }

  test_inClass_superExpression_identifier_setter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}

  void f() {
    super.foo;
//        ^^^
// [diag.undefinedSuperGetter] The getter 'foo' isn't defined in a superclass of 'A'.
  }
}
''');

    var node = result.findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SuperExpression
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SuperExpression
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SuperExpression
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

class B extends A {
  set foo(int _) {}

  void f() {
    super.foo;
//        ^^^
// [diag.undefinedSuperGetter] The getter 'foo' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SuperExpression
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;

  void f() {
    this.foo;
  }
}
''');

    var node = result.findNode.propertyExtraction('foo;');
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo(int _) {}

  void f() {
    this.foo;
  }
}
''');

    var node = result.findNode.propertyExtraction('foo;');
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: foo
  resolution: ExecutableTearOffResolution
    element: <testLibrary>::@class::A::@method::foo
    type: void Function(int)
  staticType: void Function(int)
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;

  void f() {
    this.foo;
  }
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ThisExpression
    thisKeyword: this
    staticType: A
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extensionType::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ThisExpression
    thisKeyword: this
    staticType: X
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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

  test_invalid_inDefaultValue_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f({a = b?.foo}) {}
//          ^
// [diag.undefinedIdentifier] Undefined name 'b'.
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics('''
typedef void F({a = b?.foo});
//                ^
// [diag.defaultValueInFunctionType] Parameters in a function type can't have default values.
//                  ^
// [diag.undefinedIdentifier] Undefined name 'b'.
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics('''
void f({a = b?..foo}) {}
//          ^
// [diag.undefinedIdentifier] Undefined name 'b'.
''');

    var node = result.findNode.singleFormalParameter;
    assertResolvedNodeText(node, r'''
RegularFormalParameter
  name: a
  defaultClause: FormalParameterDefaultClause
    separator: =
    value2: CascadeExpression
      target2: SimpleIdentifier
        token: b
        element: <null>
        staticType: InvalidType
      sections
        CascadeSection
          body: PropertyAccess
            operator: ?..
            propertyName: SimpleIdentifier
              token: foo
              element: <null>
              staticType: InvalidType
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
  declaredFragment: <testLibraryFragment> a@8
    element: hasImplicitType isPublic
      type: dynamic
''');
  }

  test_nullShorting_cascade() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
  int get bar => 0;
}

void f(A? a) {
  a?..foo..bar;
}
''');

    var node = result.findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target2: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A?
  sections
    CascadeSection
      body: PropertyAccess
        operator: ?..
        propertyName: SimpleIdentifier
          token: foo
          element: <testLibrary>::@class::A::@getter::foo
          staticType: int
        staticType: int
    CascadeSection
      body: PropertyAccess
        operator: ..
        propertyName: SimpleIdentifier
          token: bar
          element: <testLibrary>::@class::A::@getter::bar
          staticType: int
        staticType: int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get foo => 0;
}

main() {
  A a = A()..foo?.isEven;
  a;
}
''');

    var node = result.findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target2: ConstructorInvocation
    constructorReference: ConstructorReference2
      typeReference: ConstructorTypeReference
        name: A
        element: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  target(v1): InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  sections
    CascadeSection
      body: PropertyAccess
        target2: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target2: ConstructorInvocation
    constructorReference: ConstructorReference2
      typeReference: ConstructorTypeReference
        name: A
        element: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  target(v1): InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  sections
    CascadeSection
      body: PropertyAccess
        target2: PropertyAccess
          target2: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target2: PropertyAccess
    target2: SimpleIdentifier
      token: foo
      element: <testLibrary>::@getter::foo
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: bar
      element: <testLibrary>::@class::A::@getter::bar
      staticType: A
    staticType: A?
  sections
    CascadeSection
      body: PropertyAccess
        target2: PropertyAccess
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

  test_ofClass_augmentationAugments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo;
}

void f(A a) {
  (a).foo;
}

augment class A {
  augment int get foo => 0;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_ofClass_augmentationDeclares() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

void f(A a) {
  (a).foo;
}

augment class A {
  int get foo => 0;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_ofClass_inheritedGetter_ofGenericClass_usesTypeParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  T get foo => throw 0;
}

class B extends A<int> {}

void f(B b) {
  (b).foo;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: B
    rightParenthesis: )
    staticType: B
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: SubstitutedGetterElementImpl
      baseElement: <testLibrary>::@class::A::@getter::foo
      substitution: {T: int}
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    element: SubstitutedGetterElementImpl
      baseElement: <testLibrary>::@class::A::@getter::foo
      substitution: {T: int}
    staticType: int
  staticType: int
''');
  }

  test_ofClass_inheritedGetter_ofGenericClass_usesTypeParameterNot() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  double get foo => throw 0;
}

class B extends A<int> {}

void f(B b) {
  (b).foo;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: B
    rightParenthesis: )
    staticType: B
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: double Function()
    type: double
  staticType: double
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics('''
void f(dynamic a) {
  (a).hash;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: hash
  resolution: DynamicPropertyReadResolution
    type: dynamic
  staticType: dynamic
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics('''
void f(dynamic a) {
  (a).hashCode;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: hashCode
  resolution: GetterInvocationResolution
    element: dart:core::@class::Object::@getter::hashCode
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics('''
void f(dynamic a) {
  (a).runtimeType;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: runtimeType
  resolution: GetterInvocationResolution
    element: dart:core::@class::Object::@getter::runtimeType
    invokeType: Type Function()
    type: Type
  staticType: Type
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics('''
void f(dynamic a) {
  (a).toString;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  operator: .
  propertyName: toString
  resolution: ExecutableTearOffResolution
    element: dart:core::@class::Object::@method::toString
    type: String Function()
  staticType: String Function()
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics('''
enum E {
  v;
  int get foo => 0;
}

void f(E e) {
  (e).foo;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: e
      element: <testLibrary>::@function::f::@formalParameter::e
      staticType: E
    rightParenthesis: )
    staticType: E
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@enum::E::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: e
      element: <testLibrary>::@function::f::@formalParameter::e
      staticType: E
    rightParenthesis: )
    staticType: E
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@mixin::M::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics('''
enum E {
  v;
  set foo(int _) {}
}

void f(E e) {
  (e).foo = 1;
}
''');

    var node = result.findNode.assignment('foo = 1');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@enum::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_ofExtension_augmentation_read() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {}

void f(A a) {
  (a).foo;
}

augment extension E {
  int get foo => 0;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extension::E::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_ofExtension_augmentation_write() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {}

void f(A a) {
  (a).foo = 0;
}

augment extension E {
  set foo(int _) {}
}
''');

    var node = result.findNode.singleAssignmentExpression;
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
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_ofExtension_augmentationGeneric_read() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {}

extension E<U> on A<U> {}

void f(A<int> a) {
  (a).foo;
}

augment extension E<U> {
  U get foo => throw 0;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A<int>
    rightParenthesis: )
    staticType: A<int>
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: SubstitutedGetterElementImpl
      baseElement: <testLibrary>::@extension::E::@getter::foo
      substitution: {U: int}
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A<int>
    rightParenthesis: )
    staticType: A<int>
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: SubstitutedGetterElementImpl
      baseElement: <testLibrary>::@extension::E::@getter::foo
      substitution: {U: int}
    staticType: int
  staticType: int
''');
  }

  test_ofExtension_onRecordType() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension IntStringRecordExtension on (int, String) {
  int get foo => 0;
}

void f((int, String) r) {
  r.foo;
}
''');

    var node = result.findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics('''
extension BiRecordExtension<T, U> on (T, U) {
  Map<T, U> get foo => {};
}

void f((int, String) r) {
  r.foo;
}
''');

    var node = result.findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: SubstitutedGetterElementImpl
      baseElement: <testLibrary>::@extension::BiRecordExtension::@getter::foo
      substitution: {T: int, U: String}
    staticType: Map<int, String>
  staticType: Map<int, String>
''');
  }

  test_ofExtension_read() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {
  int get foo => 0;
}

void f(A a) {
  A().foo;
}
''');

    var node = result.findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: ConstructorInvocation
    constructorReference: ConstructorReference2
      typeReference: ConstructorTypeReference
        name: A
        element: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  target(v1): InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibrary>::@class::A
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {
  int get foo => 0;
  set foo(num _) {}
}

void f() {
  A().foo += 1;
}
''');

    var node = result.findNode.assignment('foo += 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: ConstructorInvocation
      constructorReference: ConstructorReference2
        typeReference: ConstructorTypeReference
          name: A
          element: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    target(v1): InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@class::A
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
  rightHandSide2: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_ofExtension_write() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}

extension E on A {
  set foo(int _) {}
}

void f() {
  A().foo = 1;
}
''');

    var node = result.findNode.assignment('foo = 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: ConstructorInvocation
      constructorReference: ConstructorReference2
        typeReference: ConstructorTypeReference
          name: A
          element: <testLibrary>::@class::A
          type: A
        element: <testLibrary>::@class::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: A
    target(v1): InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@class::A
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
  rightHandSide2: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_ofExtensionType_read() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
}

void f(A a) {
  (a).foo;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@extensionType::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

void f(A a) {
  (a).hashCode;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: hashCode
  resolution: GetterInvocationResolution
    element: dart:core::@class::Object::@getter::hashCode
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int? it) {}

void f(A a) {
  (a).hashCode;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: hashCode
  resolution: GetterInvocationResolution
    element: dart:core::@class::Object::@getter::hashCode
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

void f(A a) {
  (a).foo;
//    ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'A'.
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: foo
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  set foo(int _) {}
}

void f(A a) {
  (a).foo = 0;
}
''');

    var node = result.findNode.singleAssignmentExpression;
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extensionType::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_ofMixin_augmentationAugments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A {
  int get foo;
}

void f(A a) {
  (a).foo;
}

augment mixin A {
  augment int get foo => 0;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@mixin::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    element: <testLibrary>::@mixin::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_ofMixin_augmentationDeclares() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A {}

void f(A a) {
  (a).foo;
}

augment mixin A {
  int get foo => 0;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@mixin::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
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
    element: <testLibrary>::@mixin::A::@getter::foo
    staticType: int
  staticType: int
''');
  }

  test_ofRecordType_namedField() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(({int foo}) r) {
  r.foo;
}
''');

    var node = result.findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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

  test_ofRecordType_namedField_beforeRecords() async {
    newFile('$testPackageLibPath/a.dart', r'''
final r = (foo: 42);
''');

    var result = await resolveTestCodeWithDiagnostics('''
// %before-language-feature: records
import 'a.dart';
void f() {
  r.foo;
}
''');

    var node = result.findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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

  test_ofRecordType_namedField_hasExtension() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on ({int foo}) {
  bool get foo => false;
}

void f(({int foo}) r) {
  r.foo;
}
''');

    var node = result.findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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

  test_ofRecordType_namedField_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(({int foo})? r) {
  r?.foo;
}
''');

    var node = result.findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T extends ({int foo})>(T r) {
  r.foo;
}
''');

    var node = result.findNode.propertyAccess(r'foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics('''
void f(({int foo}) r) {
  r.hashCode;
}
''');

    var node = result.findNode.propertyAccess('hashCode;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$1;
}
''');

    var node = result.findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  bool get $1 => false;
}

void f((int, String) r) {
  r.$1;
}
''');

    var node = result.findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$2;
}
''');

    var node = result.findNode.propertyAccess(r'$2;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension on (int, String) {
  bool get $3 => false;
}

void f((int, String) r) {
  r.$3;
}
''');

    var node = result.findNode.propertyAccess(r'$3;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
    token: r
    element: <testLibrary>::@function::f::@formalParameter::r
    staticType: (int, String)
  operator: .
  propertyName: SimpleIdentifier
    token: $3
    element: <testLibrary>::@extension::#0::@getter::$3
    staticType: bool
  staticType: bool
''');
  }

  test_ofRecordType_positionalField_2_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$3;
//  ^^
// [diag.undefinedGetter] The getter '$3' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.propertyAccess(r'$3;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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

  test_ofRecordType_positionalField_beforeRecords() async {
    newFile('$testPackageLibPath/a.dart', r'''
final r = (0, 'bar');
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
// %before-language-feature: records
import 'a.dart';
void f() {
  r.$1;
}
''');

    var node = result.findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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

  test_ofRecordType_positionalField_dollarDigitLetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$0a;
//  ^^^
// [diag.undefinedGetter] The getter '$0a' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.propertyAccess(r'$0a;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$zero;
//  ^^^^^
// [diag.undefinedGetter] The getter '$zero' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.propertyAccess(r'$zero;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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

  test_ofRecordType_positionalField_letterDollarZero() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.a$0;
//  ^^^
// [diag.undefinedGetter] The getter 'a$0' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.propertyAccess(r'a$0;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T extends (int, String)>(T r) {
  r.$1;
}
''');

    var node = result.findNode.propertyAccess(r'$1;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics('''
void f(({int foo}) r) {
  r.bar;
//  ^^^
// [diag.undefinedGetter] The getter 'bar' isn't defined for the type '({int foo})'.
}
''');

    var node = result.findNode.propertyAccess('bar;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics('''
void f((int foo, String) r) {
  r.foo;
//  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.propertyAccess('foo;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics('''
void f(Object? x) {
  (switch (x) {
    _ => 0,
  }.isEven);
}
''');

    var node = result.findNode.propertyAccess('.isEven');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression2: SimpleIdentifier
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
        expression2: IntegerLiteral
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

  test_propertyExtraction_explicitInstanceCreation_getter() async {
    var result = await resolveTestCode(r'''
class A {
  int get foo => 0;
}

void f() {
  new A().foo;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ConstructorInvocation
    keyword: new
    constructorReference: ConstructorReference2
      typeReference: ConstructorTypeReference
        name: A
        element: <testLibrary>::@class::A
        type: A
      element: <testLibrary>::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  operator: .
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  target: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibrary>::@class::A
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

  test_propertyExtraction_explicitInstanceCreation_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x = 0;
}

void f() {
  new C()?.x;
//       ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ConstructorInvocation
    keyword: new
    constructorReference: ConstructorReference2
      typeReference: ConstructorTypeReference
        name: C
        element: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C
  operator: ?.
  propertyName: x
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::x
    invokeType: int Function()
    type: int
  staticType: int?
V1: PropertyAccess
  target: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: C
  operator: ?.
  propertyName: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::C::@getter::x
    staticType: int
  staticType: int?
''');
  }

  test_propertyExtraction_nestedOrdinaryDotChain() async {
    var result = await resolveTestCode(r'''
void f() {
  ('foo').length.isEven;
}
''');

    var node = result.findNode.propertyExtraction('.isEven');
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: PropertyExtraction
    receiver: ParenthesizedExpression
      leftParenthesis: (
      expression2: SimpleStringLiteral
        literal: 'foo'
      rightParenthesis: )
      staticType: String
    operator: .
    propertyName: length
    resolution: GetterInvocationResolution
      element: dart:core::@class::String::@getter::length
      invokeType: int Function()
      type: int
    staticType: int
  operator: .
  propertyName: isEven
  resolution: GetterInvocationResolution
    element: dart:core::@class::int::@getter::isEven
    invokeType: bool Function()
    type: bool
  staticType: bool
V1: PropertyAccess
  target: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleStringLiteral
        literal: 'foo'
      rightParenthesis: )
      staticType: String
    operator: .
    propertyName: SimpleIdentifier
      token: length
      element: dart:core::@class::String::@getter::length
      staticType: int
    staticType: int
  operator: .
  propertyName: SimpleIdentifier
    token: isEven
    element: dart:core::@class::int::@getter::isEven
    staticType: bool
  staticType: bool
''');
  }

  test_propertyExtraction_parenthesizedExpression_methodTearOff() async {
    var result = await resolveTestCode(r'''
class A {
  void foo(int value) {}
}

void f(A a) {
  (a).foo;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: foo
  resolution: ExecutableTearOffResolution
    element: <testLibrary>::@class::A::@method::foo
    type: void Function(int)
  staticType: void Function(int)
V1: PropertyAccess
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
    element: <testLibrary>::@class::A::@method::foo
    staticType: void Function(int)
  staticType: void Function(int)
''');
  }

  test_propertyExtraction_parenthesizedExpression_never() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
Never get never => throw 0;

void f() {
  (never).foo;
//^^^^^^^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: never
      element: <testLibrary>::@getter::never
      staticType: Never
    rightParenthesis: )
    staticType: Never
  operator: .
  propertyName: foo
  resolution: <null>
  staticType: Never
V1: PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: never
      element: <testLibrary>::@getter::never
      staticType: Never
    rightParenthesis: )
    staticType: Never
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: Never
  staticType: Never
''');
  }

  test_propertyExtraction_parenthesizedExpression_nullAware() async {
    var result = await resolveTestCode(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  (a)?.foo;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    rightParenthesis: )
    staticType: A?
  operator: ?.
  propertyName: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::A::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int?
V1: PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A?
    rightParenthesis: )
    staticType: A?
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: int
  staticType: int?
''');
  }

  test_propertyExtraction_parenthesizedExpression_nullAware_null() async {
    var result = await resolveTestCode(r'''
void f(Null a) {
  (a)?.foo;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: Null
    rightParenthesis: )
    staticType: Null
  operator: ?.
  propertyName: foo
  resolution: <null>
  staticType: Never?
V1: PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: Null
    rightParenthesis: )
    staticType: Null
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: Never?
  staticType: Never?
''');
  }

  test_propertyExtraction_recordLiteral_namedField() async {
    var result = await resolveTestCode(r'''
void f() {
  ((1, foo: 2)).foo;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: RecordLiteral
      leftParenthesis: (
      fields2
        IntegerLiteral
          literal: 1
          staticType: int
        RecordLiteralNamedField
          name: foo
          colon: :
          fieldExpression2: IntegerLiteral
            literal: 2
            staticType: int
      rightParenthesis: )
      staticType: (int, {int foo})
    rightParenthesis: )
    staticType: (int, {int foo})
  operator: .
  propertyName: foo
  resolution: RecordFieldReadResolution
    type: int
  staticType: int
V1: PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: RecordLiteral
      leftParenthesis: (
      fields
        IntegerLiteral
          literal: 1
          staticType: int
        RecordLiteralNamedField
          name: foo
          colon: :
          fieldExpression: IntegerLiteral
            literal: 2
            staticType: int
      rightParenthesis: )
      staticType: (int, {int foo})
    rightParenthesis: )
    staticType: (int, {int foo})
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: int
  staticType: int
''');
  }

  test_propertyExtraction_stringLiteral_getter() async {
    var result = await resolveTestCode(r'''
void f() {
  'foo'.length;
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: SimpleStringLiteral
    literal: 'foo'
  operator: .
  propertyName: length
  resolution: GetterInvocationResolution
    element: dart:core::@class::String::@getter::length
    invokeType: int Function()
    type: int
  staticType: int
V1: PropertyAccess
  target: SimpleStringLiteral
    literal: 'foo'
  operator: .
  propertyName: SimpleIdentifier
    token: length
    element: dart:core::@class::String::@getter::length
    staticType: int
  staticType: int
''');
  }

  test_propertyExtraction_stringLiteral_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  'a'?.length;
//   ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: SimpleStringLiteral
    literal: 'a'
  operator: ?.
  propertyName: length
  resolution: GetterInvocationResolution
    element: dart:core::@class::String::@getter::length
    invokeType: int Function()
    type: int
  staticType: int?
V1: PropertyAccess
  target: SimpleStringLiteral
    literal: 'a'
  operator: ?.
  propertyName: SimpleIdentifier
    token: length
    element: dart:core::@class::String::@getter::length
    staticType: int
  staticType: int?
''');
  }

  test_propertyExtraction_this_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int x = 0;

  void f() {
    this?.x;
//      ^^
// [diag.invalidNullAwareOperator] The receiver can't be null, so the null-aware operator '?.' is unnecessary.
  }
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ThisExpression
    thisKeyword: this
    staticType: C
  operator: ?.
  propertyName: x
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::x
    invokeType: int Function()
    type: int
  staticType: int?
V1: PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: C
  operator: ?.
  propertyName: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::C::@getter::x
    staticType: int
  staticType: int?
''');
  }

  test_realTarget_views() async {
    var result = await resolveTestCode(r'''
void f(int? x) {
  x!.isEven;
}
''');

    var node = result.findNode.singlePropertyAccess;
    expect(node.realTarget, isA<PostfixExpression>());
    expect(node.realTarget2, isA<NullAssertionExpression>());
  }

  test_rewrite_nullShorting() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  T Function<T>(T) get f;
}
abstract class B {
  A get a;
}
int Function(int)? f(B? b) => b?.a.f;
''');

    var node = result.findNode.functionReference('b?.a.f');
    assertResolvedNodeText(node, r'''FunctionReference
  function2: PropertyAccess
    target2: PropertyAccess
      target2: SimpleIdentifier
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo = 0;
}

class B extends A {
  void f() {
    super.foo;
  }
}
''');

    var node = result.findNode.propertyAccess('super.foo');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target2: SuperExpression
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo = 0;
}

class B extends A {
  void f() {
    super.foo += 1;
  }
}
''');

    var node = result.findNode.assignment('foo += 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide2: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::foo
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_super_write() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int foo = 0;
}

class B extends A {
  void f() {
    super.foo = 1;
  }
}
''');

    var node = result.findNode.assignment('foo = 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::foo::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_targetTypeParameter_dynamicBounded() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T extends dynamic> {
  void f(T t) {
    (t).foo;
  }
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: t
      element: <testLibrary>::@class::A::@method::f::@formalParameter::t
      staticType: T
    rightParenthesis: )
    staticType: T
  operator: .
  propertyName: foo
  resolution: DynamicPropertyReadResolution
    type: dynamic
  staticType: dynamic
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics('''
class C<T> {
  void f(T t) {
    (t).foo;
//      ^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'foo' can't be unconditionally accessed because the receiver can be 'null'.
  }
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: t
      element: <testLibrary>::@class::C::@method::f::@formalParameter::t
      staticType: T
    rightParenthesis: )
    staticType: T
  operator: .
  propertyName: foo
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: PropertyAccess
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
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo(int a) {}
}

bar() {
  A().foo;
}
''');

    var node = result.findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  element: <testLibrary>::@class::A::@method::foo
  staticType: void Function(int)
''');
  }

  test_unresolved_identifier() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  (a).foo;
// ^
// [diag.undefinedIdentifier] Undefined name 'a'.
}
''');

    var node = result.findNode.singlePropertyExtraction;
    assertResolvedNodeText(node, r'''
PropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: SimpleIdentifier
      token: a
      element: <null>
      staticType: InvalidType
    rightParenthesis: )
    staticType: InvalidType
  operator: .
  propertyName: foo
  resolution: InvalidNamedReadResolution
    type: InvalidType
    candidates
    recovery: <null>
  staticType: InvalidType
V1: PropertyAccess
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
