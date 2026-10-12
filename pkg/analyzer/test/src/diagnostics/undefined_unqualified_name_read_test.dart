// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedUnqualifiedNameReadTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedUnqualifiedNameReadTest extends PubPackageResolutionTest {
  test_found_annotation_localConstVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  const a = 0;
  g(@a x) {}
  g(0);
}
''');
  }

  test_found_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int foo = 0;

void f() {
  foo += 1;
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: GetterInvocationResolution
      element: <testLibrary>::@getter::foo
      invokeType: int Function()
      type: int
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::foo
      acceptedType: int
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  binaryOperator: add
  element: dart:core::@class::num::@method::+
  operatorResultType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@getter::foo
  readType: int
  writeElement: <testLibrary>::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_found_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void foo() {}

void f() {
  foo();
}
''');

    var node = result.findNode.singleUnqualifiedFunctionInvocation;
    assertResolvedNodeText(node, r'''
UnqualifiedFunctionInvocation
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@function::foo
    invokeType: void Function()
    type: void
  staticType: void
V1: MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <testLibrary>::@function::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_found_nameExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int foo = 0;

void f() {
  foo;
}
''');

    var node = result.findNode.singleUnqualifiedNameExpression;
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: foo
  resolution: GetterInvocationResolution
    element: <testLibrary>::@getter::foo
    invokeType: int Function()
    type: int
  staticType: int
V1: SimpleIdentifier
  token: foo
  element: <testLibrary>::@getter::foo
  staticType: int
''');
  }

  test_found_nameExpression_externalFinalVariable() async {
    await resolveTestCodeWithDiagnostics('''
external final int x;
int f() => x;
''');
  }

  test_found_nameExpression_externalVariable() async {
    await resolveTestCodeWithDiagnostics('''
external int x;
int f() => x;
''');
  }

  test_found_nameExpression_forElementVariable() async {
    await resolveTestCodeWithDiagnostics('''
f(Object x) {
  return [for(int x in []) x, null];
}
''');
  }

  test_found_nameExpression_forStatementVariable() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  for (int x in []) {
    x;
  }
}
''');
  }

  test_notFound_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
@unresolved
// [diag.undefinedUnqualifiedNameReadNotFound][column 2][length 10] Undefined name 'unresolved'.
void f() {}
''');
  }

  test_notFound_annotation_importPrefix() async {
    await resolveTestCodeWithDiagnostics(r'''
@p.A(0)
// [diag.undefinedUnqualifiedNameReadNotFound][column 2][length 1] Undefined name 'p'.
void f() {}
''');
  }

  test_notFound_annotation_staticConstOfClass() async {
    await resolveTestCodeWithDiagnostics(r'''
@foo
// [diag.undefinedUnqualifiedNameReadNotFound][column 2][length 3] Undefined name 'foo'.
class A {
  static const foo = null;
}
''');
  }

  test_notFound_annotation_typeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
@unresolved<int>
// [diag.undefinedUnqualifiedNameReadNotFound][column 2][length 10] Undefined name 'unresolved'.
//             ^
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
void f() {}
''');
  }

  test_notFound_annotationArgument_staticMethodOfClass() async {
    await resolveTestCodeWithDiagnostics('''
@Annotation(foo)
//          ^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
class C {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
    ''');
  }

  test_notFound_annotationArgument_staticMethodOfClass_typeParameter() async {
    // It not is allowed for an annotation of a class type parameter to refer to
    // a method in a class.
    await resolveTestCodeWithDiagnostics('''
class C<@Annotation(foo) T> {
//                  ^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
''');
  }

  test_notFound_annotationArgument_staticMethodOfExtension() async {
    await resolveTestCodeWithDiagnostics('''
@Annotation(foo)
//          ^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
extension E on int {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
    ''');
  }

  test_notFound_annotationArgument_staticMethodOfExtension_typeParameter() async {
    // It is not allowed for an annotation of an extension type parameter to
    // refer to a method in a class.
    await resolveTestCodeWithDiagnostics('''
extension E<@Annotation(foo) T> on T {
//                      ^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
''');
  }

  test_notFound_annotationArgument_staticMethodOfMixin() async {
    await resolveTestCodeWithDiagnostics('''
@Annotation(foo)
//          ^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
mixin M {
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
    ''');
  }

  test_notFound_annotationArgument_staticMethodOfMixin_typeParameter() async {
    // It is not allowed for an annotation of a mixin type parameter to refer to
    // a method in a class.
    await resolveTestCodeWithDiagnostics('''
mixin M<@Annotation(foo) T> {
//                  ^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  static void foo() {}
}
class Annotation {
  const Annotation(dynamic d);
}
''');
  }

  test_notFound_annotationArgument_typeParameterOfClass() async {
    // If an annotation on a class type parameter cannot be resolved using the
    // normal scope resolution mechanism, it is not resolved via implicit
    // `this`.
    await resolveTestCodeWithDiagnostics('''
class C<@Annotation.function(foo) @Annotation.type(B) T> {
//                           ^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  static void foo() {}
  static void B() {}
}
class B {}
class Annotation {
  const Annotation.function(void Function() f);
  const Annotation.type(Type t);
}
''');
  }

  test_notFound_annotationArgument_typeParameterOfExtension() async {
    // If an annotation on an extension type parameter cannot be resolved using
    // the normal scope resolution mechanism, it is not resolved via implicit
    // `this`.
    await resolveTestCodeWithDiagnostics('''
extension E<@Annotation.function(foo) @Annotation.type(B) T> on C {}
//                               ^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
class C {
  static void foo() {}
  static void B() {}
}
class B {}
class Annotation {
  const Annotation.function(void Function() f);
  const Annotation.type(Type t);
}
''');
  }

  test_notFound_annotationArgument_typeParameterOfMixin() async {
    // If an annotation on a mixin type parameter cannot be resolved using the
    // normal scope resolution mechanism, it is not resolved via implicit
    // `this`.
    await resolveTestCodeWithDiagnostics('''
mixin M<@Annotation.function(foo) @Annotation.type(B) T> {
//                           ^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
// [diag.constWithNonConstantArgument] Arguments of a constant creation must be constant expressions.
  static void foo() {}
  static void B() {}
}
class B {}
class Annotation {
  const Annotation.function(void Function() f);
  const Annotation.type(Type t);
}
''');
  }

  @FailingTest() // TODO(scheglov): review this
  test_notFound_commentReference() async {
    await resolveTestCodeWithDiagnostics('''
/** [m] xxx [new B.c] */
//   ^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'm'.
//               ^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'B'.
class A {
}''');
  }

  test_notFound_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  foo += 1;
//^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_compoundAssignment_missingImportShowsIt() async {
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' show x;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

void f() {
  x += 0;
}
''');
  }

  test_notFound_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  foo ??= 0;
//^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  foo++;
//^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <null>
    write: InvalidNamedWriteResolution
      recoveryElement: <null>
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ++
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  foo();
//^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
}
''');

    var node = result.findNode.singleUnqualifiedFunctionInvocation;
    assertResolvedNodeText(node, r'''
UnqualifiedFunctionInvocation
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_invocation_implicitThis() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {

  void f() {
  foo();
//^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
  }
}
''');

    var node = result.findNode.singleUnqualifiedFunctionInvocation;
    assertResolvedNodeText(node, r'''
UnqualifiedFunctionInvocation
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_notFound_invocation_implicitThis_missingImportShowsIt() async {
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' show foo;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

class A {
  void f() {
    foo();
  }
}
''');
  }

  test_notFound_invocation_implicitThis_missingImportShowsOther() async {
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' show bar;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

class A {
  void f() {
    foo();
//  ^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
  }
}
''');
  }

  test_notFound_nameExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  foo;
//^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
}
''');

    var node = result.findNode.singleUnqualifiedNameExpression;
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: SimpleIdentifier
  token: foo
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_nameExpression_coreImportShowsOther() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:core' show List;
main() {
  List;
  String;
//^^^^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'String'.
}''');
  }

  test_notFound_nameExpression_forElementVariableOutside() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  return [for (int x in []) null, x];
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
//                                ^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'x'.
}
''');
  }

  test_notFound_nameExpression_forStatementVariableOutside() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  for (int x in []) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x;
//^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'x'.
}
''');
  }

  test_notFound_nameExpression_implicitThis() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {

  void f() {
  foo;
//^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
  }
}
''');

    var node = result.findNode.singleUnqualifiedNameExpression;
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <null>
  staticType: InvalidType
V1: SimpleIdentifier
  token: foo
  element: <null>
  staticType: InvalidType
''');
  }

  test_notFound_nameExpression_inheritedPrivateOfOtherLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
library lib;
class A {
  var _foo;
}''');
    await resolveTestCodeWithDiagnostics('''
import 'lib.dart';
class B extends A {
  test() {
    var v = _foo;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
//          ^^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name '_foo'.
  }
}''');
  }

  test_notFound_nameExpression_missingImportShowsIt() async {
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' show x;
//     ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'a.dart'.

void f() {
  x;
}
''');
  }

  test_notFound_nameExpression_staticInvocationTarget() async {
    await resolveTestCodeWithDiagnostics('''
f() { C.m(); }
//    ^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'C'.
''');
  }

  test_notFound_nameExpression_syntheticName() async {
    await resolveTestCodeWithDiagnostics(r'''
print(x) {}
main() {
  print(is String);
//      ^^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_notFound_nameExpression_topLevelVariableInitializer() async {
    await resolveTestCodeWithDiagnostics('''
var a = b;
//      ^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'b'.
''');
  }

  test_notFound_typeInstantiation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  foo<int>;
//^^^
// [diag.undefinedUnqualifiedNameReadNotFound] Undefined name 'foo'.
}
''');

    var node = result.findNode.singleFunctionInstantiation;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: UnqualifiedNameExpression
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }

  test_setterOnly_compoundAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}

void f() {
  foo += 1;
//^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::foo
      acceptedType: int
  operator: +=
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  binaryOperator: add
  element: <null>
  operatorResultType: InvalidType
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <testLibrary>::@setter::foo
  readType: InvalidType
  writeElement: <testLibrary>::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_ifNullAssignment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}

void f() {
  foo ??= 0;
//^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
}
''');

    var node = result.findNode.singleIfNullAssignment;
    assertResolvedNodeText(node, r'''
IfNullAssignment
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::foo
      acceptedType: int
  operator: ??=
  value: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@setter::foo::@formalParameter::_
    staticType: int
  staticType: InvalidType
V1: AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@setter::foo::@formalParameter::_
    staticType: int
  readElement: <testLibrary>::@setter::foo
  readType: InvalidType
  writeElement: <testLibrary>::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_increment() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}

void f() {
  foo++;
//^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
}
''');

    var node = result.findNode.singleIncrementOrDecrement;
    assertResolvedNodeText(node, r'''
IncrementOrDecrementExpression
  target: UnqualifiedNameAssignmentTarget
    name: foo
    read: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@setter::foo
    write: SetterInvocationResolution
      element: <testLibrary>::@setter::foo
      acceptedType: int
  operator: ++
  operation: increment
  position: postfix
  element: <null>
  operatorResultType: dynamic
  staticType: InvalidType
V1: PostfixExpression
  operand: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  operator: ++
  readElement: <testLibrary>::@setter::foo
  readType: InvalidType
  writeElement: <testLibrary>::@setter::foo
  writeType: int
  element: <null>
  staticType: InvalidType
''');
  }

  test_setterOnly_increment_prefix() async {
    await resolveTestCodeWithDiagnostics('''
set foo(int _) {}

void f() {
  ++foo;
//  ^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
}
''');
  }

  test_setterOnly_invocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}

void f() {
  foo();
//^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
}
''');

    var node = result.findNode.singleUnqualifiedFunctionInvocation;
    assertResolvedNodeText(node, r'''
UnqualifiedFunctionInvocation
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_setterOnly_invocation_extensionStaticSetterHidesExtensionMethod() async {
    await resolveTestCodeWithDiagnostics('''
class C {}

extension E1 on C {
  int foo(int x) => 1;
}

extension E2 on C {
  static set foo(int x) {}

  void f() {
    foo();
//  ^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
  }
}
''');
  }

  test_setterOnly_invocation_implicitThis() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(int _) {}

  void f() {
  foo();
//^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
  }
}
''');

    var node = result.findNode.singleUnqualifiedFunctionInvocation;
    assertResolvedNodeText(node, r'''
UnqualifiedFunctionInvocation
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_setterOnly_invocation_staticSetterHidesExtensionMethod() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void f() {
    foo();
//  ^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
  }
  static set foo(int x) {}
}

extension E on C {
  int foo() => 1;
}

''');
  }

  test_setterOnly_invocation_topLevelSetterHidesExtensionMethod() async {
    await resolveTestCodeWithDiagnostics('''
class C {
  void f() {
    foo();
//  ^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
  }
}

extension E on C {
  int foo() => 1;
}

set foo(int x) {}
''');
  }

  test_setterOnly_nameExpression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}

void f() {
  foo;
//^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
}
''');

    var node = result.findNode.singleUnqualifiedNameExpression;
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <testLibrary>::@setter::foo
  staticType: InvalidType
V1: SimpleIdentifier
  token: foo
  element: <testLibrary>::@setter::foo
  staticType: InvalidType
''');
  }

  test_setterOnly_nameExpression_implicitThis() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  set foo(int _) {}

  void f() {
  foo;
//^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
  }
}
''');

    var node = result.findNode.singleUnqualifiedNameExpression;
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <testLibrary>::@class::C::@setter::foo
  staticType: InvalidType
V1: SimpleIdentifier
  token: foo
  element: <testLibrary>::@class::C::@setter::foo
  staticType: InvalidType
''');
  }

  test_setterOnly_nameExpression_staticSetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static set foo(int _) {}

  void f() {
  foo;
//^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
  }
}
''');

    var node = result.findNode.singleUnqualifiedNameExpression;
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: foo
  resolution: InvalidNamedReadResolution
    recoveryElement: <testLibrary>::@class::C::@setter::foo
  staticType: InvalidType
V1: SimpleIdentifier
  token: foo
  element: <testLibrary>::@class::C::@setter::foo
  staticType: InvalidType
''');
  }

  test_setterOnly_nameExpression_topLevelSetterHidesInheritedGetter() async {
    await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

void set foo(int _) {}

class B extends A {
  void bar() {
    foo;
//  ^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
  }
}
''');
  }

  test_setterOnly_typeInstantiation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
set foo(int _) {}

void f() {
  foo<int>;
//^^^
// [diag.undefinedUnqualifiedNameReadSetterOnly] There's a setter 'foo', but no getter.
}
''');

    var node = result.findNode.singleFunctionInstantiation;
    assertResolvedNodeText(node, r'''
FunctionInstantiation
  operand: UnqualifiedNameExpression
    name: foo
    resolution: InvalidNamedReadResolution
      recoveryElement: <testLibrary>::@setter::foo
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
V1: FunctionReference
  function: SimpleIdentifier
    token: foo
    element: <testLibrary>::@setter::foo
    staticType: InvalidType
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  staticType: InvalidType
''');
  }
}
