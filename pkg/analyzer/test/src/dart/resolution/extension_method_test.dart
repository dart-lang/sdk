// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionMethodsDeclarationTest);
    defineReflectiveTests(ExtensionMethodsExtendedTypeTest);
    defineReflectiveTests(ExtensionMethodsExternalReferenceTest);
    defineReflectiveTests(ExtensionMethodsInternalReferenceTest);
  });
}

/// Tests that show that extension declarations and the members inside them are
/// resolved correctly.
@reflectiveTest
class ExtensionMethodsDeclarationTest extends PubPackageResolutionTest {
  @override
  List<MockSdkLibrary> get additionalMockSdkLibraries => [
        MockSdkLibrary('test1', [
          MockSdkLibraryUnit('test1/test1.dart', r'''
extension E on Object {
  int get a => 1;
}

class A {}
'''),
        ]),
        MockSdkLibrary('test2', [
          MockSdkLibraryUnit('test2/test2.dart', r'''
extension E on Object {
  int get a => 1;
}
'''),
        ]),
      ];

  test_constructor() async {
    await assertErrorsInCode('''
extension E {
  E() {}
}
''', [
      error(ParserErrorCode.EXPECTED_TOKEN, 10, 1),
      error(ParserErrorCode.EXPECTED_TYPE_NAME, 12, 1),
      error(ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR, 16, 1),
    ]);
  }

  test_factory() async {
    await assertErrorsInCode('''
extension E {
  factory S() {}
}
''', [
      error(ParserErrorCode.EXPECTED_TOKEN, 10, 1),
      error(ParserErrorCode.EXPECTED_TYPE_NAME, 12, 1),
      error(ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR, 16, 7),
    ]);
  }

  test_fromPlatform() async {
    await assertNoErrorsInCode('''
import 'dart:test2';

f(Object o) {
  o.a;
}
''');
  }

  test_metadata() async {
    await assertNoErrorsInCode('''
const int ann = 1;
class C {}
@ann
extension E on C {}
''');
    var annotation = findNode.annotation('@ann');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: ann
    staticElement: <testLibraryFragment>::@getter::ann
    element: <testLibraryFragment>::@getter::ann#element
    staticType: null
  element: <testLibraryFragment>::@getter::ann
  element2: <testLibraryFragment>::@getter::ann#element
''');
  }

  test_multipleExtensions_noConflict() async {
    await assertNoErrorsInCode('''
class C {}
extension E1 on C {}
extension E2 on C {}
''');
  }

  test_this_type_interface() async {
    await assertNoErrorsInCode('''
extension E on int {
  void foo() {
    this;
  }
}
''');
    var node = findNode.this_('this;');
    assertResolvedNodeText(node, r'''
ThisExpression
  thisKeyword: this
  staticType: int
''');
  }

  test_this_type_typeParameter() async {
    await assertNoErrorsInCode('''
extension E<T> on T {
  void foo() {
    this;
  }
}
''');
    var node = findNode.this_('this;');
    assertResolvedNodeText(node, r'''
ThisExpression
  thisKeyword: this
  staticType: T
''');
  }

  test_this_type_typeParameter_withBound() async {
    await assertNoErrorsInCode('''
extension E<T extends Object> on T {
  void foo() {
    this;
  }
}
''');
    var node = findNode.this_('this;');
    assertResolvedNodeText(node, r'''
ThisExpression
  thisKeyword: this
  staticType: T
''');
  }

  test_visibility_hidden() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on C {
  int a = 1;
}
''');
    await assertErrorsInCode('''
import 'lib.dart' hide E;

f(C c) {
  c.a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 40, 1),
    ]);
  }

  test_visibility_notShown() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on C {
  int a = 1;
}
''');
    await assertErrorsInCode('''
import 'lib.dart' show C;

f(C c) {
  c.a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 40, 1),
    ]);
  }

  test_visibility_private() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on C {
  int _a = 1;
}
''');
    await assertErrorsInCode('''
import 'lib.dart';

f(C c) {
  c._a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 33, 2),
    ]);
  }

  test_visibility_shadowed_byClass() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on C {
  int get a => 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart';

class E {}
f(C c) {
  c.a;
}
''');
    var access = findNode.prefixed('c.a');
    assertResolvedNodeText(access, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: package:test/lib.dart::<fragment>::@extension::E::@getter::a
    element: package:test/lib.dart::<fragment>::@extension::E::@getter::a#element
    staticType: int
  staticElement: package:test/lib.dart::<fragment>::@extension::E::@getter::a
  element: package:test/lib.dart::<fragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_visibility_shadowed_byImport() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension E on Object {
  int get a => 1;
}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
class E {}
class A {}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';

f(Object o, A a) {
  o.a;
}
''');
    var access = findNode.prefixed('o.a');
    assertResolvedNodeText(access, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: o
    staticElement: <testLibraryFragment>::@function::f::@parameter::o
    element: <testLibraryFragment>::@function::f::@parameter::o#element
    staticType: Object
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: package:test/lib1.dart::<fragment>::@extension::E::@getter::a
    element: package:test/lib1.dart::<fragment>::@extension::E::@getter::a#element
    staticType: int
  staticElement: package:test/lib1.dart::<fragment>::@extension::E::@getter::a
  element: package:test/lib1.dart::<fragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_visibility_shadowed_byLocal_imported() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on C {
  int get a => 1;
}
''');
    await assertErrorsInCode('''
import 'lib.dart';

f(C c) {
  double E = 2.71;
  c.a;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 38, 1),
    ]);
    var access = findNode.prefixed('c.a');
    assertResolvedNodeText(access, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: package:test/lib.dart::<fragment>::@extension::E::@getter::a
    element: package:test/lib.dart::<fragment>::@extension::E::@getter::a#element
    staticType: int
  staticElement: package:test/lib.dart::<fragment>::@extension::E::@getter::a
  element: package:test/lib.dart::<fragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_visibility_shadowed_byLocal_local() async {
    await assertErrorsInCode('''
class C {}
extension E on C {
  int get a => 1;
}
f(C c) {
  double E = 2.71;
  c.a;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 68, 1),
    ]);
    var access = findNode.prefixed('c.a');
    assertResolvedNodeText(access, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@getter::a
    element: <testLibraryFragment>::@extension::E::@getter::a#element
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@getter::a
  element: <testLibraryFragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_visibility_shadowed_byTopLevelVariable() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on C {
  int get a => 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart';

double E = 2.71;
f(C c) {
  c.a;
}
''');
    var access = findNode.prefixed('c.a');
    assertResolvedNodeText(access, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: package:test/lib.dart::<fragment>::@extension::E::@getter::a
    element: package:test/lib.dart::<fragment>::@extension::E::@getter::a#element
    staticType: int
  staticElement: package:test/lib.dart::<fragment>::@extension::E::@getter::a
  element: package:test/lib.dart::<fragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_visibility_shadowed_platformByNonPlatform() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on Object {
  int get a => 1;
}
class B {}
''');
    await assertNoErrorsInCode('''
import 'dart:test1';
import 'lib.dart';

f(Object o, A a, B b) {
  o.a;
}
''');
  }

  test_visibility_withPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on C {
  int get a => 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f(p.C c) {
  c.a;
}
''');
  }
}

@reflectiveTest
class ExtensionMethodsExtendedTypeTest extends PubPackageResolutionTest {
  test_named_generic() async {
    await assertNoErrorsInCode('''
class C<T> {}
extension E<S> on C<S> {}
''');
    var extendedType = findNode.typeAnnotation('C<S>');
    assertResolvedNodeText(extendedType, r'''
NamedType
  name: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: S
        element: S@26
        element2: <not-implemented>
        type: S
    rightBracket: >
  element: <testLibraryFragment>::@class::C
  element2: <testLibraryFragment>::@class::C#element
  type: C<S>
''');
  }

  test_named_onDynamic() async {
    await assertNoErrorsInCode('''
extension E on dynamic {}
''');
    var extendedType = findNode.typeAnnotation('dynamic');
    assertResolvedNodeText(extendedType, r'''
NamedType
  name: dynamic
  element: dynamic@-1
  element2: dynamic@-1
  type: dynamic
''');
  }

  test_named_onEnum() async {
    await assertNoErrorsInCode('''
enum A {a, b, c}
extension E on A {}
''');
    var extendedType = findNode.typeAnnotation('A {}');
    assertResolvedNodeText(extendedType, r'''
NamedType
  name: A
  element: <testLibraryFragment>::@enum::A
  element2: <testLibraryFragment>::@enum::A#element
  type: A
''');
  }

  test_named_onFunctionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {}
''');
    var extendedType = findNode.typeAnnotation('Function');
    assertResolvedNodeText(extendedType, r'''
GenericFunctionType
  returnType: NamedType
    name: int
    element: dart:core::<fragment>::@class::int
    element2: dart:core::<fragment>::@class::int#element
    type: int
  functionKeyword: Function
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
      declaredElement: @-1
        type: int
    rightParenthesis: )
  declaredElement: GenericFunctionTypeElement
    parameters
      <empty>
        kind: required positional
        type: int
    returnType: int
    type: int Function(int)
  type: int Function(int)
''');
  }

  test_named_onInterface() async {
    await assertNoErrorsInCode('''
class C { }
extension E on C {}
''');
    var extendedType = findNode.typeAnnotation('C {}');
    assertResolvedNodeText(extendedType, r'''
NamedType
  name: C
  element: <testLibraryFragment>::@class::C
  element2: <testLibraryFragment>::@class::C#element
  type: C
''');
  }

  test_named_onMixin() async {
    await assertNoErrorsInCode('''
mixin M {
}
extension E on M {}
''');
    var extendedType = findNode.typeAnnotation('M {}');
    assertResolvedNodeText(extendedType, r'''
NamedType
  name: M
  element: <testLibraryFragment>::@mixin::M
  element2: <testLibraryFragment>::@mixin::M#element
  type: M
''');
  }

  test_unnamed_generic() async {
    await assertNoErrorsInCode('''
class C<T> {}
extension<S> on C<S> {}
''');
    var extendedType = findNode.typeAnnotation('C<S>');
    assertResolvedNodeText(extendedType, r'''
NamedType
  name: C
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: S
        element: S@24
        element2: <not-implemented>
        type: S
    rightBracket: >
  element: <testLibraryFragment>::@class::C
  element2: <testLibraryFragment>::@class::C#element
  type: C<S>
''');
  }

  test_unnamed_onDynamic() async {
    await assertNoErrorsInCode('''
extension on dynamic {}
''');
    var extendedType = findNode.typeAnnotation('dynamic');
    assertResolvedNodeText(extendedType, r'''
NamedType
  name: dynamic
  element: dynamic@-1
  element2: dynamic@-1
  type: dynamic
''');
  }

  test_unnamed_onEnum() async {
    await assertNoErrorsInCode('''
enum A {a, b, c}
extension on A {}
''');
    var extendedType = findNode.typeAnnotation('A {}');
    assertResolvedNodeText(extendedType, r'''
NamedType
  name: A
  element: <testLibraryFragment>::@enum::A
  element2: <testLibraryFragment>::@enum::A#element
  type: A
''');
  }

  test_unnamed_onFunctionType() async {
    await assertNoErrorsInCode('''
extension on int Function(String) {}
''');
    var extendedType = findNode.typeAnnotation('Function');
    assertResolvedNodeText(extendedType, r'''
GenericFunctionType
  returnType: NamedType
    name: int
    element: dart:core::<fragment>::@class::int
    element2: dart:core::<fragment>::@class::int#element
    type: int
  functionKeyword: Function
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: String
        element: dart:core::<fragment>::@class::String
        element2: dart:core::<fragment>::@class::String#element
        type: String
      declaredElement: @-1
        type: String
    rightParenthesis: )
  declaredElement: GenericFunctionTypeElement
    parameters
      <empty>
        kind: required positional
        type: String
    returnType: int
    type: int Function(String)
  type: int Function(String)
''');
  }

  test_unnamed_onInterface() async {
    await assertNoErrorsInCode('''
class C { }
extension on C {}
''');
    var extendedType = findNode.typeAnnotation('C {}');
    assertResolvedNodeText(extendedType, r'''
NamedType
  name: C
  element: <testLibraryFragment>::@class::C
  element2: <testLibraryFragment>::@class::C#element
  type: C
''');
  }

  test_unnamed_onMixin() async {
    await assertNoErrorsInCode('''
mixin M {
}
extension on M {}
''');
    var extendedType = findNode.typeAnnotation('M {}');
    assertResolvedNodeText(extendedType, r'''
NamedType
  name: M
  element: <testLibraryFragment>::@mixin::M
  element2: <testLibraryFragment>::@mixin::M#element
  type: M
''');
  }
}

@reflectiveTest
class ExtensionMethodsExternalReferenceTest extends PubPackageResolutionTest {
  /// Corresponds to: extension_member_resolution_t07
  test_dynamicInvocation() async {
    await assertNoErrorsInCode(r'''
class A {}
class C extends A {
  String method(int i) => "$i";
  noSuchMethod(Invocation i) { }
}

extension E<T extends A> on T {
  String method(int i, String s) => '';
}

main() {
  dynamic c = new C();
  c.method(42, "-42");
}
''');
  }

  test_instance_call_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  int call(int x) => 0;
}

extension E on C {
  int call(int x) => 0;
}

f(C c) {
  c(2);
}
''');
    var invocation = findNode.functionExpressionInvocation('c(2)');
    assertResolvedNodeText(invocation, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        parameter: <testLibraryFragment>::@class::C::@method::call::@parameter::x
        staticType: int
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@class::C::@method::call
  element: <testLibraryFragment>::@class::C::@method::call#element
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_instance_call_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int call(int x) => 0;
}

f(C c) {
  c(2);
}
''');
    var invocation = findNode.functionExpressionInvocation('c(2)');
    assertResolvedNodeText(invocation, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        parameter: <testLibraryFragment>::@extension::E::@method::call::@parameter::x
        staticType: int
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@extension::E::@method::call
  element: <testLibraryFragment>::@extension::E::@method::call#element
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_instance_call_fromExtension_int() async {
    await assertNoErrorsInCode('''
extension E on int {
  int call(int x) => 0;
}

f() {
  1(2);
}
''');
    var invocation = findNode.functionExpressionInvocation('1(2)');
    assertResolvedNodeText(invocation, r'''
FunctionExpressionInvocation
  function: IntegerLiteral
    literal: 1
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        parameter: <testLibraryFragment>::@extension::E::@method::call::@parameter::x
        staticType: int
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@extension::E::@method::call
  element: <testLibraryFragment>::@extension::E::@method::call#element
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_instance_compoundAssignment_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  C operator +(int i) => this;
}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  c += 2;
}
''');
    var assignment = findNode.assignment('+=');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::C::@method::+::@parameter::i
    staticType: int
  readElement: <testLibraryFragment>::@function::f::@parameter::c
  readElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  readType: C
  writeElement: <testLibraryFragment>::@function::f::@parameter::c
  writeElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  writeType: C
  staticElement: <testLibraryFragment>::@class::C::@method::+
  element: <testLibraryFragment>::@class::C::@method::+#element
  staticType: C
''');
  }

  test_instance_compoundAssignment_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  c += 2;
}
''');
    var assignment = findNode.assignment('+=');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@extension::E::@method::+::@parameter::i
    staticType: int
  readElement: <testLibraryFragment>::@function::f::@parameter::c
  readElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  readType: C
  writeElement: <testLibraryFragment>::@function::f::@parameter::c
  writeElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  writeType: C
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticType: C
''');
  }

  test_instance_getter_fromDifferentExtension_usingBounds() async {
    await assertNoErrorsInCode('''
class B {}
extension E1 on B {
  int get g => 0;
}
extension E2<T extends B> on T {
  void a() {
    g;
  }
}
''');
    var identifier = findNode.simple('g;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: g
  staticElement: <testLibraryFragment>::@extension::E1::@getter::g
  element: <testLibraryFragment>::@extension::E1::@getter::g#element
  staticType: int
''');
  }

  test_instance_getter_fromDifferentExtension_withoutTarget() async {
    await assertNoErrorsInCode('''
class C {}
extension E1 on C {
  int get a => 1;
}
extension E2 on C {
  void m() {
    a;
  }
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@extension::E1::@getter::a
  element: <testLibraryFragment>::@extension::E1::@getter::a#element
  staticType: int
''');
  }

  test_instance_getter_fromExtendedType_usingBounds() async {
    await assertNoErrorsInCode('''
class B {
  int get g => 0;
}
extension E<T extends B> on T {
  void a() {
    g;
  }
}
''');
    var identifier = findNode.simple('g;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: g
  staticElement: <testLibraryFragment>::@class::B::@getter::g
  element: <testLibraryFragment>::@class::B::@getter::g#element
  staticType: int
''');
  }

  test_instance_getter_fromExtendedType_withoutTarget() async {
    await assertNoErrorsInCode('''
class C {
  void m() {
    a;
  }
}
extension E on C {
  int get a => 1;
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@extension::E::@getter::a
  element: <testLibraryFragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_instance_getter_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  int get a => 1;
}
g(int Function(int) f) {
  f.a;
}
''');
    var access = findNode.prefixed('f.a');
    assertResolvedNodeText(access, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::g::@parameter::f
    element: <testLibraryFragment>::@function::g::@parameter::f#element
    staticType: int Function(int)
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@getter::a
    element: <testLibraryFragment>::@extension::E::@getter::a#element
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@getter::a
  element: <testLibraryFragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_instance_getter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int get a => 1;
}

f(C c) {
  c.a;
}
''');
    var access = findNode.prefixed('c.a');
    assertResolvedNodeText(access, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@getter::a
    element: <testLibraryFragment>::@extension::E::@getter::a#element
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@getter::a
  element: <testLibraryFragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_instance_getter_fromInstance_extensionType() async {
    await assertNoErrorsInCode('''
extension type A(int it) {}

extension E on A {
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
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@getter::foo
    element: <testLibraryFragment>::@extension::E::@getter::foo#element
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@getter::foo
  element: <testLibraryFragment>::@extension::E::@getter::foo#element
  staticType: int
''');
  }

  test_instance_getter_fromInstance_Never() async {
    await assertNoErrorsInCode('''
extension E on Never {
  int get foo => 0;
}

f(Never a) {
  a.foo;
}
''');
    var access = findNode.prefixed('a.foo');
    assertResolvedNodeText(access, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: Never
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: Never
  staticElement: <null>
  element: <null>
  staticType: Never
''');
  }

  test_instance_getter_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
extension E on int? {
  int get foo => 0;
}

f(int? a) {
  a.foo;
}
''');
    var access = findNode.prefixed('a.foo');
    assertResolvedNodeText(access, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int?
  period: .
  identifier: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@getter::foo
    element: <testLibraryFragment>::@extension::E::@getter::foo#element
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@getter::foo
  element: <testLibraryFragment>::@extension::E::@getter::foo#element
  staticType: int
''');
  }

  test_instance_getter_fromInstance_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int get foo => 0;
}

f(int? a) {
  a?.foo;
}
''');
    var access = findNode.propertyAccess('foo;');
    assertResolvedNodeText(access, r'''
PropertyAccess
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int?
  operator: ?.
  propertyName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@getter::foo
    element: <testLibraryFragment>::@extension::E::@getter::foo#element
    staticType: int
  staticType: int?
''');
  }

  test_instance_getter_methodInvocation() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  double Function(int) get a => (b) => 2.0;
}

f(C c) {
  c.a(0);
}
''');
    var invocation = findNode.functionExpressionInvocation('c.a(0)');
    assertResolvedNodeText(invocation, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@extension::E::@getter::a
      element: <testLibraryFragment>::@extension::E::@getter::a#element
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
  }

  test_instance_getter_specificSubtypeMatchLocal() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {}

extension A_Ext on A {
  int get a => 1;
}
extension B_Ext on B {
  int get a => 2;
}

f(B b) {
  b.a;
}
''');
    var access = findNode.prefixed('b.a');
    assertResolvedNodeText(access, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: b
    staticElement: <testLibraryFragment>::@function::f::@parameter::b
    element: <testLibraryFragment>::@function::f::@parameter::b#element
    staticType: B
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::B_Ext::@getter::a
    element: <testLibraryFragment>::@extension::B_Ext::@getter::a#element
    staticType: int
  staticElement: <testLibraryFragment>::@extension::B_Ext::@getter::a
  element: <testLibraryFragment>::@extension::B_Ext::@getter::a#element
  staticType: int
''');
  }

  test_instance_getterInvoked_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  String Function() get a => () => 'a';
}
g(int Function(int) f) {
  f.a();
}
''');
    var invocation = findNode.functionExpressionInvocation('f.a()');
    assertResolvedNodeText(invocation, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::g::@parameter::f
      element: <testLibraryFragment>::@function::g::@parameter::f#element
      staticType: int Function(int)
    operator: .
    propertyName: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@extension::E::@getter::a
      element: <testLibraryFragment>::@extension::E::@getter::a#element
      staticType: String Function()
    staticType: String Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  element: <null>
  staticInvokeType: String Function()
  staticType: String
''');
  }

  test_instance_method_fromDifferentExtension_usingBounds() async {
    await assertNoErrorsInCode('''
class B {}
extension E1 on B {
  void m() {}
}
extension E2<T extends B> on T {
  void a() {
    m();
  }
}
''');
    var invocation = findNode.methodInvocation('m();');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
    staticElement: <testLibraryFragment>::@extension::E1::@method::m
    element: <testLibraryFragment>::@extension::E1::@method::m#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromDifferentExtension_withoutTarget() async {
    await assertNoErrorsInCode('''
class B {}
extension E1 on B {
  void a() {}
}
extension E2 on B {
  void m() {
    a();
  }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E1::@method::a
    element: <testLibraryFragment>::@extension::E1::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromExtendedType_usingBounds() async {
    await assertNoErrorsInCode('''
class B {
  void m() {}
}
extension E<T extends B> on T {
  void a() {
    m();
  }
}
''');
    var invocation = findNode.methodInvocation('m();');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
    staticElement: <testLibraryFragment>::@class::B::@method::m
    element: <testLibraryFragment>::@class::B::@method::m#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromExtendedType_withoutTarget() async {
    await assertNoErrorsInCode('''
class B {
  void m() {
    a();
  }
}
extension E on B {
  void a() {}
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void a() {}
}
g(int Function(int) f) {
  f.a();
}
''');
    var invocation = findNode.methodInvocation('f.a()');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::g::@parameter::f
    element: <testLibraryFragment>::@function::g::@parameter::f#element
    staticType: int Function(int)
  operator: .
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromInstance() async {
    await assertNoErrorsInCode('''
class B {}

extension A on B {
  void a() {}
}

f(B b) {
  b.a();
}
''');
    var invocation = findNode.methodInvocation('b.a()');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: SimpleIdentifier
    token: b
    staticElement: <testLibraryFragment>::@function::f::@parameter::b
    element: <testLibraryFragment>::@function::f::@parameter::b#element
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::A::@method::a
    element: <testLibraryFragment>::@extension::A::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromInstance_extensionType() async {
    await assertNoErrorsInCode('''
extension type A(int it) {}

extension E on A {
  void foo() {}
}

void f(A a) {
  a.foo();
}
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromInstance_importInPart() async {
    newFile('$testPackageLibPath/x.dart', r'''
extension E on int {
  void foo() {}
}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'x.dart';
void f() {
  0.foo();
}
''');

    await resolveFile2(b);
    assertErrorsInResult([]);

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: IntegerLiteral
    literal: 0
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: package:test/x.dart::<fragment>::@extension::E::@method::foo
    element: package:test/x.dart::<fragment>::@extension::E::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromInstance_Never() async {
    await assertErrorsInCode('''
extension E on Never {
  void foo() {}
}

f(Never a) {
  a.foo();
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 57, 1),
      error(WarningCode.DEAD_CODE, 62, 3),
    ]);

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: Never
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: Never
''');
  }

  test_instance_method_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
extension E on int? {
  void foo() {}
}

f(int? a) {
  a.foo();
}
''');
    var invocation = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromInstance_nullable_nullLiteral() async {
    await assertNoErrorsInCode('''
extension E on int? {
  void foo() {}
}

f(int? a) {
  null.foo();
}
''');
    var invocation = findNode.methodInvocation('null.foo()');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: NullLiteral
    literal: null
    staticType: Null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromInstance_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  void foo() {}
}

f(int? a) {
  a?.foo();
}
''');
    var invocation = findNode.methodInvocation('a?.foo()');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int?
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromInstance_nullLiteral() async {
    await assertNoErrorsInCode('''
extension E<T> on T {
  void foo() {}
}

f() {
  null.foo();
}
''');
    var invocation = findNode.methodInvocation('null.foo()');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: NullLiteral
    literal: null
    staticType: Null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: <testLibraryFragment>::@extension::E::@method::foo
      substitution: {T: Null}
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_specificSubtypeMatchLocal() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {}

extension A_Ext on A {
  void a() {}
}
extension B_Ext on B {
  void a() {}
}

f(B b) {
  b.a();
}
''');

    var invocation = findNode.methodInvocation('b.a()');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: SimpleIdentifier
    token: b
    staticElement: <testLibraryFragment>::@function::f::@parameter::b
    element: <testLibraryFragment>::@function::f::@parameter::b#element
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::B_Ext::@method::a
    element: <testLibraryFragment>::@extension::B_Ext::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_specificSubtypeMatchLocalGenerics() async {
    await assertNoErrorsInCode('''
class A<T> {}

class B<T> extends A<T> {}

class C {}

extension A_Ext<T> on A<T> {
  void f(T x) {}
}

extension B_Ext<T> on B<T> {
  void f(T x) {}
}

f(B<C> x, C o) {
  x.f(o);
}
''');
    var invocation = findNode.methodInvocation('x.f(o)');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: B<C>
  operator: .
  methodName: SimpleIdentifier
    token: f
    staticElement: MethodMember
      base: <testLibraryFragment>::@extension::B_Ext::@method::f
      substitution: {T: C}
    element: <testLibraryFragment>::@extension::B_Ext::@method::f#element
    staticType: void Function(C)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: o
        parameter: root::@parameter::x
        staticElement: <testLibraryFragment>::@function::f::@parameter::o
        element: <testLibraryFragment>::@function::f::@parameter::o#element
        staticType: C
    rightParenthesis: )
  staticInvokeType: void Function(C)
  staticType: void
''');
  }

  test_instance_operator_binary_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator +(int i) {}
}
extension E on C {
  void operator +(int i) {}
}
f(C c) {
  c + 2;
}
''');
    var binary = findNode.binary('+ ');
    assertResolvedNodeText(binary, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  operator: +
  rightOperand: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::C::@method::+::@parameter::i
    staticType: int
  staticElement: <testLibraryFragment>::@class::C::@method::+
  element: <testLibraryFragment>::@class::C::@method::+#element
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_instance_operator_binary_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void operator +(int i) {}
}
g(int Function(int) f) {
  f + 2;
}
''');
    var binary = findNode.binary('+ ');
    assertResolvedNodeText(binary, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::g::@parameter::f
    element: <testLibraryFragment>::@function::g::@parameter::f#element
    staticType: int Function(int)
  operator: +
  rightOperand: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@extension::E::@method::+::@parameter::i
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_instance_operator_binary_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator +(int i) {}
}
f(C c) {
  c + 2;
}
''');
    var binary = findNode.binary('+ ');
    assertResolvedNodeText(binary, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  operator: +
  rightOperand: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@extension::E::@method::+::@parameter::i
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_instance_operator_binary_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A? {
  int operator +(int _) => 0;
}

f(A? a) {
  a + 1;
}
''');
    var binary = findNode.binary('a + 1');
    assertResolvedNodeText(binary, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@extension::E::@method::+::@parameter::_
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_instance_operator_binary_undefinedTarget() async {
    // Ensure that there is no exception thrown while resolving the code.
    await assertErrorsInCode('''
extension on Object {}
var a = b + c;
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 31, 1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 35, 1),
    ]);
  }

  test_instance_operator_index_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator [](int index) {}
}
extension E on C {
  void operator [](int index) {}
}
f(C c) {
  c[2];
}
''');
    var index = findNode.index('c[2]');
    assertResolvedNodeText(index, r'''
IndexExpression
  target: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  leftBracket: [
  index: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::C::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: <testLibraryFragment>::@class::C::@method::[]
  element: <testLibraryFragment>::@class::C::@method::[]#element
  staticType: void
''');
  }

  test_instance_operator_index_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void operator [](int index) {}
}
g(int Function(int) f) {
  f[2];
}
''');
    var index = findNode.index('f[2]');
    assertResolvedNodeText(index, r'''
IndexExpression
  target: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::g::@parameter::f
    element: <testLibraryFragment>::@function::g::@parameter::f#element
    staticType: int Function(int)
  leftBracket: [
  index: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@extension::E::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: <testLibraryFragment>::@extension::E::@method::[]
  element: <testLibraryFragment>::@extension::E::@method::[]#element
  staticType: void
''');
  }

  test_instance_operator_index_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator [](int index) {}
}
f(C c) {
  c[2];
}
''');
    var index = findNode.index('c[2]');
    assertResolvedNodeText(index, r'''
IndexExpression
  target: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  leftBracket: [
  index: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@extension::E::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: <testLibraryFragment>::@extension::E::@method::[]
  element: <testLibraryFragment>::@extension::E::@method::[]#element
  staticType: void
''');
  }

  test_instance_operator_index_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
extension E on int? {
  int operator [](int index) => 0;
}

f(int? a) {
  a[0];
}
''');
    var index = findNode.index('a[0]');
    assertResolvedNodeText(index, r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@extension::E::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: <testLibraryFragment>::@extension::E::@method::[]
  element: <testLibraryFragment>::@extension::E::@method::[]#element
  staticType: int
''');
  }

  test_instance_operator_index_fromInstance_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  int operator [](int index) => 0;
}

f(int? a) {
  a?[0];
}
''');
    var index = findNode.index('a?[0]');
    assertResolvedNodeText(index, r'''
IndexExpression
  target: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int?
  leftBracket: [
  index: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@extension::E::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: <testLibraryFragment>::@extension::E::@method::[]
  element: <testLibraryFragment>::@extension::E::@method::[]#element
  staticType: int?
''');
  }

  test_instance_operator_indexEquals_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator []=(int index, int value) {}
}
extension E on C {
  void operator []=(int index, int value) {}
}
f(C c) {
  c[2] = 1;
}
''');
    var assignment = findNode.assignment('[2] =');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: c
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C
    leftBracket: [
    index: IntegerLiteral
      literal: 2
      parameter: <testLibraryFragment>::@class::C::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@class::C::@method::[]=::@parameter::value
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::C::@method::[]=
  writeElement2: <testLibraryFragment>::@class::C::@method::[]=#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_instance_operator_indexEquals_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void operator []=(int index, int value) {}
}
g(int Function(int) f) {
  f[2] = 3;
}
''');
    var assignment = findNode.assignment('f[2]');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::g::@parameter::f
      element: <testLibraryFragment>::@function::g::@parameter::f#element
      staticType: int Function(int)
    leftBracket: [
    index: IntegerLiteral
      literal: 2
      parameter: <testLibraryFragment>::@extension::E::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <testLibraryFragment>::@extension::E::@method::[]=::@parameter::value
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@method::[]=
  writeElement2: <testLibraryFragment>::@extension::E::@method::[]=#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_instance_operator_indexEquals_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator []=(int index, int value) {}
}
f(C c) {
  c[2] = 3;
}
''');
    var assignment = findNode.assignment('c[2]');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: c
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C
    leftBracket: [
    index: IntegerLiteral
      literal: 2
      parameter: <testLibraryFragment>::@extension::E::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <testLibraryFragment>::@extension::E::@method::[]=::@parameter::value
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@method::[]=
  writeElement2: <testLibraryFragment>::@extension::E::@method::[]=#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_instance_operator_postfix_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  C operator +(int i) => this;
}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  c++;
}
''');
    var postfix = findNode.postfix('++');
    assertResolvedNodeText(postfix, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@function::f::@parameter::c
  readElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  readType: C
  writeElement: <testLibraryFragment>::@function::f::@parameter::c
  writeElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  writeType: C
  staticElement: <testLibraryFragment>::@class::C::@method::+
  element: <testLibraryFragment>::@class::C::@method::+#element
  staticType: C
''');
  }

  test_instance_operator_postfix_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  int Function(int) operator +(int i) => this;
}
g(int Function(int) f) {
  f++;
}
''');
    var postfix = findNode.postfix('++');
    assertResolvedNodeText(postfix, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::g::@parameter::f
    element: <testLibraryFragment>::@function::g::@parameter::f#element
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@function::g::@parameter::f
  readElement2: <testLibraryFragment>::@function::g::@parameter::f#element
  readType: int Function(int)
  writeElement: <testLibraryFragment>::@function::g::@parameter::f
  writeElement2: <testLibraryFragment>::@function::g::@parameter::f#element
  writeType: int Function(int)
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticType: int Function(int)
''');
  }

  test_instance_operator_postfix_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  c++;
}
''');
    var postfix = findNode.postfix('++');
    assertResolvedNodeText(postfix, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@function::f::@parameter::c
  readElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  readType: C
  writeElement: <testLibraryFragment>::@function::f::@parameter::c
  writeElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  writeType: C
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticType: C
''');
  }

  test_instance_operator_postfixInc_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A? {
  A? operator +(int _) => this;
}

f(A? a) {
  a++;
}
''');
    var expression = findNode.postfix('a++');
    assertResolvedNodeText(expression, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: null
  operator: ++
  readElement: <testLibraryFragment>::@function::f::@parameter::a
  readElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  readType: A?
  writeElement: <testLibraryFragment>::@function::f::@parameter::a
  writeElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  writeType: A?
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticType: A?
''');
  }

  test_instance_operator_prefix_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  C operator +(int i) => this;
}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  ++c;
}
''');
    var prefix = findNode.prefix('++');
    assertResolvedNodeText(prefix, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: null
  readElement: <testLibraryFragment>::@function::f::@parameter::c
  readElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  readType: C
  writeElement: <testLibraryFragment>::@function::f::@parameter::c
  writeElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  writeType: C
  staticElement: <testLibraryFragment>::@class::C::@method::+
  element: <testLibraryFragment>::@class::C::@method::+#element
  staticType: C
''');
  }

  test_instance_operator_prefix_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  int Function(int) operator +(int i) => this;
}
g(int Function(int) f) {
  ++f;
}
''');
    var prefix = findNode.prefix('++');
    assertResolvedNodeText(prefix, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::g::@parameter::f
    element: <testLibraryFragment>::@function::g::@parameter::f#element
    staticType: null
  readElement: <testLibraryFragment>::@function::g::@parameter::f
  readElement2: <testLibraryFragment>::@function::g::@parameter::f#element
  readType: int Function(int)
  writeElement: <testLibraryFragment>::@function::g::@parameter::f
  writeElement2: <testLibraryFragment>::@function::g::@parameter::f#element
  writeType: int Function(int)
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticType: int Function(int)
''');
  }

  test_instance_operator_prefix_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  C operator +(int i) => this;
}
f(C c) {
  ++c;
}
''');
    var prefix = findNode.prefix('++');
    assertResolvedNodeText(prefix, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: null
  readElement: <testLibraryFragment>::@function::f::@parameter::c
  readElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  readType: C
  writeElement: <testLibraryFragment>::@function::f::@parameter::c
  writeElement2: <testLibraryFragment>::@function::f::@parameter::c#element
  writeType: C
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticType: C
''');
  }

  test_instance_operator_prefixInc_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A? {
  A? operator +(int _) => this;
}

f(A? a) {
  ++a;
}
''');
    var expression = findNode.prefix('++a');
    assertResolvedNodeText(expression, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: null
  readElement: <testLibraryFragment>::@function::f::@parameter::a
  readElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  readType: A?
  writeElement: <testLibraryFragment>::@function::f::@parameter::a
  writeElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  writeType: A?
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticType: A?
''');
  }

  test_instance_operator_unary_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  C operator -() => this;
}
extension E on C {
  C operator -() => this;
}
f(C c) {
  -c;
}
''');
    var prefix = findNode.prefix('-c');
    assertResolvedNodeText(prefix, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  staticElement: <testLibraryFragment>::@class::C::@method::unary-
  element: <testLibraryFragment>::@class::C::@method::unary-#element
  staticType: C
''');
  }

  test_instance_operator_unary_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void operator -() {}
}
g(int Function(int) f) {
  -f;
}
''');
    var prefix = findNode.prefix('-f');
    assertResolvedNodeText(prefix, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::g::@parameter::f
    element: <testLibraryFragment>::@function::g::@parameter::f#element
    staticType: int Function(int)
  staticElement: <testLibraryFragment>::@extension::E::@method::unary-
  element: <testLibraryFragment>::@extension::E::@method::unary-#element
  staticType: void
''');
  }

  test_instance_operator_unary_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  C operator -() => this;
}
f(C c) {
  -c;
}
''');
    var prefix = findNode.prefix('-c');
    assertResolvedNodeText(prefix, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  staticElement: <testLibraryFragment>::@extension::E::@method::unary-
  element: <testLibraryFragment>::@extension::E::@method::unary-#element
  staticType: C
''');
  }

  test_instance_operator_unaryMinus_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
class A {}

extension E on A? {
  A? operator -() => this;
}

f(A? a) {
  -a;
}
''');
    var expression = findNode.prefix('-a');
    assertResolvedNodeText(expression, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: A?
  staticElement: <testLibraryFragment>::@extension::E::@method::unary-
  element: <testLibraryFragment>::@extension::E::@method::unary-#element
  staticType: A?
''');
  }

  test_instance_setter_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  set a(int x) {}
}
g(int Function(int) f) {
  f.a = 1;
}
''');
    var assignment = findNode.assignment('a = 1');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::g::@parameter::f
      element: <testLibraryFragment>::@function::g::@parameter::f#element
      staticType: int Function(int)
    period: .
    identifier: SimpleIdentifier
      token: a
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@extension::E::@setter::a::@parameter::x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::a
  writeElement2: <testLibraryFragment>::@extension::E::@setter::a#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_instance_setter_fromInstance_extensionType() async {
    await assertNoErrorsInCode('''
extension type A(int it) {}

extension E on A {
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
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
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

  test_instance_setter_fromInstance_nullable() async {
    await assertNoErrorsInCode('''
extension E on int? {
  set foo(int _) {}
}

f(int? a) {
  a.foo = 1;
}
''');
    assertResolvedNodeText(findNode.assignment('foo = 1'), r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: int?
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
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

  test_instance_setter_fromInstance_nullAware() async {
    await assertNoErrorsInCode('''
extension E on int {
  set foo(int _) {}
}

f(int? a) {
  a?.foo = 1;
}
''');
    assertResolvedNodeText(findNode.assignment('foo = 1'), r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: int?
    operator: ?.
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
  staticType: int?
''');
  }

  test_instance_setter_oneMatch() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  set a(int x) {}
}

f(C c) {
  c.a = 1;
}
''');
    var assignment = findNode.assignment('a = 1');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      staticElement: <testLibraryFragment>::@function::f::@parameter::c
      element: <testLibraryFragment>::@function::f::@parameter::c#element
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: a
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@extension::E::@setter::a::@parameter::x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::a
  writeElement2: <testLibraryFragment>::@extension::E::@setter::a#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_instance_tearoff_fromExtension_functionType() async {
    await assertNoErrorsInCode('''
extension E on int Function(int) {
  void a(int x) {}
}
g(int Function(int) f) => f.a;
''');
    var node = findNode.prefixed('a;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: f
    staticElement: <testLibraryFragment>::@function::g::@parameter::f
    element: <testLibraryFragment>::@function::g::@parameter::f#element
    staticType: int Function(int)
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function(int)
  staticElement: <testLibraryFragment>::@extension::E::@method::a
  element: <testLibraryFragment>::@extension::E::@method::a#element
  staticType: void Function(int)
''');
  }

  test_instance_tearoff_fromExtension_interfaceType() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
}

f(C c) => c.a;
''');
    var node = findNode.prefixed('a;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: c
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: C
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function(int)
  staticElement: <testLibraryFragment>::@extension::E::@method::a
  element: <testLibraryFragment>::@extension::E::@method::a#element
  staticType: void Function(int)
''');
  }

  test_static_field_importedWithPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  static int a = 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a;
}
''');
    var node = findNode.propertyAccess('p.E.a;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      staticElement: <testLibraryFragment>::@prefix::p
      element: <testLibraryFragment>::@prefix2::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: E
      staticElement: package:test/lib.dart::<fragment>::@extension::E
      element: package:test/lib.dart::<fragment>::@extension::E#element
      staticType: null
    staticElement: package:test/lib.dart::<fragment>::@extension::E
    element: package:test/lib.dart::<fragment>::@extension::E#element
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: a
    staticElement: package:test/lib.dart::<fragment>::@extension::E::@getter::a
    element: package:test/lib.dart::<fragment>::@extension::E::@getter::a#element
    staticType: int
  staticType: int
''');
  }

  test_static_field_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int a = 1;
}

f() {
  E.a;
}
''');
    var node = findNode.prefixed('E.a;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: E
    staticElement: <testLibraryFragment>::@extension::E
    element: <testLibraryFragment>::@extension::E#element
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@getter::a
    element: <testLibraryFragment>::@extension::E::@getter::a#element
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@getter::a
  element: <testLibraryFragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_static_getter_importedWithPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  static int get a => 1;
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a;
}
''');
    var node = findNode.propertyAccess('p.E.a;');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      staticElement: <testLibraryFragment>::@prefix::p
      element: <testLibraryFragment>::@prefix2::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: E
      staticElement: package:test/lib.dart::<fragment>::@extension::E
      element: package:test/lib.dart::<fragment>::@extension::E#element
      staticType: null
    staticElement: package:test/lib.dart::<fragment>::@extension::E
    element: package:test/lib.dart::<fragment>::@extension::E#element
    staticType: null
  operator: .
  propertyName: SimpleIdentifier
    token: a
    staticElement: package:test/lib.dart::<fragment>::@extension::E::@getter::a
    element: package:test/lib.dart::<fragment>::@extension::E::@getter::a#element
    staticType: int
  staticType: int
''');
  }

  test_static_getter_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int get a => 1;
}

f() {
  E.a;
}
''');
    var node = findNode.prefixed('E.a;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: E
    staticElement: <testLibraryFragment>::@extension::E
    element: <testLibraryFragment>::@extension::E#element
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@getter::a
    element: <testLibraryFragment>::@extension::E::@getter::a#element
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@getter::a
  element: <testLibraryFragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_static_method_importedWithPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  static void a() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a();
}
''');
    var invocation = findNode.methodInvocation('E.a()');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      staticElement: <testLibraryFragment>::@prefix::p
      element: <testLibraryFragment>::@prefix2::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: E
      staticElement: package:test/lib.dart::<fragment>::@extension::E
      element: package:test/lib.dart::<fragment>::@extension::E#element
      staticType: null
    staticElement: package:test/lib.dart::<fragment>::@extension::E
    element: package:test/lib.dart::<fragment>::@extension::E#element
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: a
    staticElement: package:test/lib.dart::<fragment>::@extension::E::@method::a
    element: package:test/lib.dart::<fragment>::@extension::E::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_static_method_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a() {}
}

f() {
  E.a();
}
''');
    var invocation = findNode.methodInvocation('E.a()');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: SimpleIdentifier
    token: E
    staticElement: <testLibraryFragment>::@extension::E
    element: <testLibraryFragment>::@extension::E#element
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_static_setter_importedWithPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension E on C {
  static set a(int x) {}
}
''');
    await assertNoErrorsInCode('''
import 'lib.dart' as p;

f() {
  p.E.a = 3;
}
''');
    var assignment = findNode.assignment('a = 3');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        staticElement: <testLibraryFragment>::@prefix::p
        element: <testLibraryFragment>::@prefix2::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: package:test/lib.dart::<fragment>::@extension::E
        element: package:test/lib.dart::<fragment>::@extension::E#element
        staticType: null
      staticElement: package:test/lib.dart::<fragment>::@extension::E
      element: package:test/lib.dart::<fragment>::@extension::E#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: a
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: package:test/lib.dart::<fragment>::@extension::E::@setter::a::@parameter::x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: package:test/lib.dart::<fragment>::@extension::E::@setter::a
  writeElement2: package:test/lib.dart::<fragment>::@extension::E::@setter::a#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_static_setter_local() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static set a(int x) {}
}

f() {
  E.a = 3;
}
''');
    var assignment = findNode.assignment('a = 3');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: a
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <testLibraryFragment>::@extension::E::@setter::a::@parameter::x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::a
  writeElement2: <testLibraryFragment>::@extension::E::@setter::a#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_static_tearoff() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a(int x) {}
}

f() => E.a;
''');
    var node = findNode.prefixed('E.a;');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: E
    staticElement: <testLibraryFragment>::@extension::E
    element: <testLibraryFragment>::@extension::E#element
    staticType: null
  period: .
  identifier: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function(int)
  staticElement: <testLibraryFragment>::@extension::E::@method::a
  element: <testLibraryFragment>::@extension::E::@method::a#element
  staticType: void Function(int)
''');
  }

  test_thisAccessOnDynamic() async {
    await assertNoErrorsInCode('''
extension E on dynamic {
  int get d => 3;

  void testDynamic() {
    // Static type of `this` is dynamic, allows dynamic invocation.
    this.arglebargle();
  }
}
''');
  }

  test_thisAccessOnFunction() async {
    await assertNoErrorsInCode('''
extension E on Function {
  int get f => 4;

  void testFunction() {
    // Static type of `this` is Function. Allows any dynamic invocation.
    this();
    this(1);
    this(x: 1);
    // No function can have both optional positional and named parameters.
  }
}
''');
  }
}

@reflectiveTest
class ExtensionMethodsInternalReferenceTest extends PubPackageResolutionTest {
  test_instance_call() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int call(int x) => 0;
  int m() => this(2);
}
''');
    var invocation = findNode.functionExpressionInvocation('this(2)');
    assertResolvedNodeText(invocation, r'''
FunctionExpressionInvocation
  function: ThisExpression
    thisKeyword: this
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 2
        parameter: <testLibraryFragment>::@extension::E::@method::call::@parameter::x
        staticType: int
    rightParenthesis: )
  staticElement: <testLibraryFragment>::@extension::E::@method::call
  element: <testLibraryFragment>::@extension::E::@method::call#element
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_instance_getter_asSetter() async {
    await assertErrorsInCode('''
extension E1 on int {
  int get foo => 0;
}

extension E2 on int {
  int get foo => 0;
  void f() {
    foo = 0;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 104, 3),
    ]);
    var assignment = findNode.assignment('foo = 0');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E2::@getter::foo
  writeElement2: <testLibraryFragment>::@extension::E2::@getter::foo#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_instance_getter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  int get a => 1;
}

extension E on C {
  int get a => 1;
  int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@extension::E::@getter::a
  element: <testLibraryFragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_instance_getter_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  int get a => 1;
}

extension E on C {
  int get a => 1;
  int m() => this.a;
}
''');
    var access = findNode.propertyAccess('this.a');
    assertResolvedNodeText(access, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: C
  operator: .
  propertyName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@class::C::@getter::a
    element: <testLibraryFragment>::@class::C::@getter::a#element
    staticType: int
  staticType: int
''');
  }

  test_instance_getter_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  int get a => 1;
  int m() => this.a;
}
''');

    var node = findNode.singlePropertyAccess;
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: C
  operator: .
  propertyName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@getter::a
    element: <testLibraryFragment>::@extension::E::@getter::a#element
    staticType: int
  staticType: int
''');
  }

  test_instance_method_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  void a() {}
}
extension E on C {
  void a() {}
  void b() { a(); }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void a() {}
}
extension E on C {
  void a() {}
  void b() { this.a(); }
}
''');
    var invocation = findNode.methodInvocation('this.a');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: ThisExpression
    thisKeyword: this
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@class::C::@method::a
    element: <testLibraryFragment>::@class::C::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_method_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void a() {}
  void b() { this.a(); }
}
''');
    var invocation = findNode.methodInvocation('this.a');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  target: ThisExpression
    thisKeyword: this
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_instance_operator_binary_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator +(int i) {}
}
extension E on C {
  void operator +(int i) {}
  void b() { this + 2; }
}
''');
    var binary = findNode.binary('+ ');
    assertResolvedNodeText(binary, r'''
BinaryExpression
  leftOperand: ThisExpression
    thisKeyword: this
    staticType: C
  operator: +
  rightOperand: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::C::@method::+::@parameter::i
    staticType: int
  staticElement: <testLibraryFragment>::@class::C::@method::+
  element: <testLibraryFragment>::@class::C::@method::+#element
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_instance_operator_binary_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator +(int i) {}
  void b() { this + 2; }
}
''');
    var binary = findNode.binary('+ ');
    assertResolvedNodeText(binary, r'''
BinaryExpression
  leftOperand: ThisExpression
    thisKeyword: this
    staticType: C
  operator: +
  rightOperand: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@extension::E::@method::+::@parameter::i
    staticType: int
  staticElement: <testLibraryFragment>::@extension::E::@method::+
  element: <testLibraryFragment>::@extension::E::@method::+#element
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_instance_operator_index_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator [](int index) {}
}
extension E on C {
  void operator [](int index) {}
  void b() { this[2]; }
}
''');
    var index = findNode.index('this[2]');
    assertResolvedNodeText(index, r'''
IndexExpression
  target: ThisExpression
    thisKeyword: this
    staticType: C
  leftBracket: [
  index: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::C::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: <testLibraryFragment>::@class::C::@method::[]
  element: <testLibraryFragment>::@class::C::@method::[]#element
  staticType: void
''');
  }

  test_instance_operator_index_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator [](int index) {}
  void b() { this[2]; }
}
''');
    var index = findNode.index('this[2]');
    assertResolvedNodeText(index, r'''
IndexExpression
  target: ThisExpression
    thisKeyword: this
    staticType: C
  leftBracket: [
  index: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@extension::E::@method::[]::@parameter::index
    staticType: int
  rightBracket: ]
  staticElement: <testLibraryFragment>::@extension::E::@method::[]
  element: <testLibraryFragment>::@extension::E::@method::[]#element
  staticType: void
''');
  }

  test_instance_operator_indexEquals_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator []=(int index, int value) {}
}
extension E on C {
  void operator []=(int index, int value) {}
  void b() { this[2] = 1; }
}
''');
    var assignment = findNode.assignment('this[2]');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: ThisExpression
      thisKeyword: this
      staticType: C
    leftBracket: [
    index: IntegerLiteral
      literal: 2
      parameter: <testLibraryFragment>::@class::C::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@class::C::@method::[]=::@parameter::value
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::C::@method::[]=
  writeElement2: <testLibraryFragment>::@class::C::@method::[]=#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_instance_operator_indexEquals_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator []=(int index, int value) {}
  void b() { this[2] = 3; }
}
''');
    var assignment = findNode.assignment('this[2]');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: ThisExpression
      thisKeyword: this
      staticType: C
    leftBracket: [
    index: IntegerLiteral
      literal: 2
      parameter: <testLibraryFragment>::@extension::E::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <testLibraryFragment>::@extension::E::@method::[]=::@parameter::value
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@method::[]=
  writeElement2: <testLibraryFragment>::@extension::E::@method::[]=#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_instance_operator_unary_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  void operator -() {}
}
extension E on C {
  void operator -() {}
  void b() { -this; }
}
''');
    var prefix = findNode.prefix('-this');
    assertResolvedNodeText(prefix, r'''
PrefixExpression
  operator: -
  operand: ThisExpression
    thisKeyword: this
    staticType: C
  staticElement: <testLibraryFragment>::@class::C::@method::unary-
  element: <testLibraryFragment>::@class::C::@method::unary-#element
  staticType: void
''');
  }

  test_instance_operator_unary_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  void operator -() {}
  void b() { -this; }
}
''');
    var prefix = findNode.prefix('-this');
    assertResolvedNodeText(prefix, r'''
PrefixExpression
  operator: -
  operand: ThisExpression
    thisKeyword: this
    staticType: C
  staticElement: <testLibraryFragment>::@extension::E::@method::unary-
  element: <testLibraryFragment>::@extension::E::@method::unary-#element
  staticType: void
''');
  }

  test_instance_setter_asGetter() async {
    await assertErrorsInCode('''
extension E1 on int {
  set foo(int _) {}
}

extension E2 on int {
  set foo(int _) {}
  void f() {
    foo;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 104, 3),
    ]);
    var node = findNode.simple('foo;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: foo
  staticElement: <null>
  element: <null>
  staticType: InvalidType
''');
  }

  test_instance_setter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  set a(int _) {}
}

extension E on C {
  set a(int _) {}
  void m() {
    a = 3;
  }
}
''');
    var assignment = findNode.assignment('a = 3');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <testLibraryFragment>::@extension::E::@setter::a::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::a
  writeElement2: <testLibraryFragment>::@extension::E::@setter::a#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_instance_setter_fromThis_fromExtendedType() async {
    await assertNoErrorsInCode('''
class C {
  set a(int _) {}
}

extension E on C {
  set a(int _) {}
  void m() {
    this.a = 3;
  }
}
''');
    var assignment = findNode.assignment('a = 3');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: a
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <testLibraryFragment>::@class::C::@setter::a::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::C::@setter::a
  writeElement2: <testLibraryFragment>::@class::C::@setter::a#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_instance_setter_fromThis_fromExtension() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  set a(int _) {}
  void m() {
    this.a = 3;
  }
}
''');
    var assignment = findNode.assignment('a = 3');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: a
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <testLibraryFragment>::@extension::E::@setter::a::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::a
  writeElement2: <testLibraryFragment>::@extension::E::@setter::a#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_instance_tearoff_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
  get b => a;
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@extension::E::@method::a
  element: <testLibraryFragment>::@extension::E::@method::a#element
  staticType: void Function(int)
''');
  }

  test_instance_tearoff_fromThis() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  void a(int x) {}
  get c => this.a;
}
''');
    var identifier = findNode.propertyAccess('this.a;');
    assertResolvedNodeText(identifier, r'''
PropertyAccess
  target: ThisExpression
    thisKeyword: this
    staticType: C
  operator: .
  propertyName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function(int)
  staticType: void Function(int)
''');
  }

  test_static_field_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int a = 1;
  int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@extension::E::@getter::a
  element: <testLibraryFragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_static_field_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int a = 1;
  static int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@extension::E::@getter::a
  element: <testLibraryFragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_static_getter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int get a => 1;
  int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@extension::E::@getter::a
  element: <testLibraryFragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_static_getter_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static int get a => 1;
  static int m() => a;
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@extension::E::@getter::a
  element: <testLibraryFragment>::@extension::E::@getter::a#element
  staticType: int
''');
  }

  test_static_method_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  static void a() {}
  void b() { a(); }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_static_method_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}
extension E on C {
  static void a() {}
  static void b() { a(); }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@extension::E::@method::a
    element: <testLibraryFragment>::@extension::E::@method::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_static_setter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static set a(int x) {}
  void m() {
    a = 3;
  }
}
''');
    var assignment = findNode.assignment('a = 3');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <testLibraryFragment>::@extension::E::@setter::a::@parameter::x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::a
  writeElement2: <testLibraryFragment>::@extension::E::@setter::a#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_static_setter_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static set a(int x) {}
  static void m() {
    a = 3;
  }
}
''');
    var assignment = findNode.assignment('a = 3');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <testLibraryFragment>::@extension::E::@setter::a::@parameter::x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::a
  writeElement2: <testLibraryFragment>::@extension::E::@setter::a#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_static_tearoff_fromInstance() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a(int x) {}
  get b => a;
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@extension::E::@method::a
  element: <testLibraryFragment>::@extension::E::@method::a#element
  staticType: void Function(int)
''');
  }

  test_static_tearoff_fromStatic() async {
    await assertNoErrorsInCode('''
class C {}

extension E on C {
  static void a(int x) {}
  static get c => a;
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@extension::E::@method::a
  element: <testLibraryFragment>::@extension::E::@method::a#element
  staticType: void Function(int)
''');
  }

  test_topLevel_function_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  void a() {}
}

void a() {}

extension E on C {
  void b() {
    a();
  }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::a
    element: <testLibraryFragment>::@function::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_topLevel_function_fromStatic() async {
    await assertNoErrorsInCode('''
class C {
  void a() {}
}

void a() {}

extension E on C {
  static void b() {
    a();
  }
}
''');
    var invocation = findNode.methodInvocation('a();');
    assertResolvedNodeText(invocation, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::a
    element: <testLibraryFragment>::@function::a#element
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_topLevel_getter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  int get a => 0;
}

int get a => 0;

extension E on C {
  void b() {
    a;
  }
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@getter::a
  element: <testLibraryFragment>::@getter::a#element
  staticType: int
''');
  }

  test_topLevel_getter_fromStatic() async {
    await assertNoErrorsInCode('''
class C {
  int get a => 0;
}

int get a => 0;

extension E on C {
  static void b() {
    a;
  }
}
''');
    var identifier = findNode.simple('a;');
    assertResolvedNodeText(identifier, r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@getter::a
  element: <testLibraryFragment>::@getter::a#element
  staticType: int
''');
  }

  test_topLevel_setter_fromInstance() async {
    await assertNoErrorsInCode('''
class C {
  set a(int _) {}
}

set a(int _) {}

extension E on C {
  void b() {
    a = 0;
  }
}
''');
    var assignment = findNode.assignment('a = 0');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@setter::a::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@setter::a
  writeElement2: <testLibraryFragment>::@setter::a#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_topLevel_setter_fromStatic() async {
    await assertNoErrorsInCode('''
class C {
  set a(int _) {}
}

set a(int _) {}

extension E on C {
  static void b() {
    a = 0;
  }
}
''');
    var assignment = findNode.assignment('a = 0');
    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@setter::a::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@setter::a
  writeElement2: <testLibraryFragment>::@setter::a#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }
}
