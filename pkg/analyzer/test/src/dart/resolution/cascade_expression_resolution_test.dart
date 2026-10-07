// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CascadeExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class CascadeExpressionResolutionTest extends PubPackageResolutionTest {
  test_callableGetter_generic_inferredArguments() async {
    var result = await resolveTestCode(r'''
T id<T>(T value) => value;
class A {
  T Function<T>(T) get callback => id;
}
void f(A a) {
  a..callback(0).isEven;
}
''');
    var node = result.findNode.receiverPropertyExtraction('isEven');
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: CallInvocation
    receiver: CascadePropertyExtraction
      name: callback
      resolution: GetterInvocationResolution
        element: <testLibrary>::@class::A::@getter::callback
        invokeType: T Function<T>(T) Function()
        type: T Function<T>(T)
      staticType: T Function<T>(T)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <null-name>@null
            substitution: {T: int}
          staticType: int
      rightParenthesis: )
    resolution: FunctionTypeInvocationResolution
      invokeType: int Function(int)
      type: int
    staticType: int
    typeArgumentTypes
      int
  operator: .
  name: isEven
  resolution: GetterInvocationResolution
    element: dart:core::@class::int::@getter::isEven
    invokeType: bool Function()
    type: bool
  staticType: bool
V1: PropertyAccess
  target: FunctionExpressionInvocation
    function: PropertyAccess
      operator: ..
      propertyName: SimpleIdentifier
        token: callback
        element: <testLibrary>::@class::A::@getter::callback
        staticType: T Function<T>(T)
      staticType: T Function<T>(T)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <null-name>@null
            substitution: {T: int}
          staticType: int
      rightParenthesis: )
    element: <null>
    staticInvokeType: int Function(int)
    staticType: int
    typeArgumentTypes
      int
  operator: .
  propertyName: SimpleIdentifier
    token: isEven
    element: dart:core::@class::int::@getter::isEven
    staticType: bool
  staticType: bool
''');
  }

  test_extensionMethod_followedByInvocation() async {
    var result = await resolveTestCode(r'''
extension E on int {
  T id<T>(T value) => value;
}
void f(int a) {
  a..id(0).toString();
}
''');
    var node = result.findNode.receiverMethodInvocation('toString()');
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: CascadeMethodInvocation
    name: id
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        IntegerLiteral
          literal: 0
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@extension::E::@method::id::@formalParameter::value
            substitution: {T: int}
          staticType: int
      rightParenthesis: )
    resolution: ExecutableInvocationResolution
      element: <testLibrary>::@extension::E::@method::id
      invokeType: int Function(int)
      type: int
    staticType: int
    typeArgumentTypes
      int
  operator: .
  name: toString
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: dart:core::@class::int::@method::toString
    invokeType: String Function()
    type: String
  staticType: String
V1: MethodInvocation
  target: MethodInvocation
    operator: ..
    methodName: SimpleIdentifier
      token: id
      element: <testLibrary>::@extension::E::@method::id
      staticType: int Function(int)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 0
          correspondingParameter: SubstitutedFormalParameterElementImpl
            baseElement: <testLibrary>::@extension::E::@method::id::@formalParameter::value
            substitution: {T: int}
          staticType: int
      rightParenthesis: )
    staticInvokeType: int Function(int)
    staticType: int
    typeArgumentTypes
      int
  operator: .
  methodName: SimpleIdentifier
    token: toString
    element: dart:core::@class::int::@method::toString
    staticType: String Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: String Function()
  staticType: String
''');
  }

  test_functionInterface_call_read() async {
    var result = await resolveTestCode(r'''
Function f(Function a) {
  return a..call;
}
''');

    var node = result.findNode.cascadePropertyExtraction('call;');
    assertResolvedNodeText(node, r'''
CascadePropertyExtraction
  name: call
  resolution: FunctionInterfaceCallTearOffResolution
    type: Function
  staticType: Function
V1: PropertyAccess
  operator: ..
  propertyName: SimpleIdentifier
    token: call
    element: <null>
    staticType: Function
  staticType: Function
''');
  }

  test_functionType_call_read_typeParameterBound() async {
    var result = await resolveTestCode(r'''
T f<T extends int Function(String)>(T a) {
  return a..call;
}
''');

    var node = result.findNode.cascadePropertyExtraction('call;');
    assertResolvedNodeText(node, r'''
CascadePropertyExtraction
  name: call
  resolution: FunctionCallTearOffResolution
    type: T
    associatedFunctionType: int Function(String)
  staticType: T
V1: PropertyAccess
  operator: ..
  propertyName: SimpleIdentifier
    token: call
    element: <null>
    staticType: T
  staticType: T
''');
  }

  test_functionType_genericCall_topLevelInitializer_secondResolution() async {
    var result = await resolveTestCode(r'''
T id<T>(T value) => value;
var value = id..call<int>(0);
''');
    var node = result.findNode.cascadeMethodInvocation('call<int>(0)');
    assertResolvedNodeText(node, r'''
CascadeMethodInvocation
  name: call
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@function::id::@formalParameter::value
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  resolution: FunctionCallInvocationResolution
    invokeType: int Function(int)
    type: int
  staticType: int
  typeArgumentTypes
    int
V1: MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: call
    element: <null>
    staticType: int Function(int)
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@function::id::@formalParameter::value
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: int Function(int)
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_index_followedByInvocation() async {
    var result = await resolveTestCode(r'''
void f(List<int> a) {
  a..[0].toRadixString(16);
}
''');
    var node = result.findNode.receiverMethodInvocation('toRadixString(16)');
    assertResolvedNodeText(node, r'''
ReceiverMethodInvocation
  receiver: CascadeIndexExpression
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: SubstitutedFormalParameterElementImpl
        baseElement: dart:core::@class::List::@method::[]::@formalParameter::index
        substitution: {E: int}
      staticType: int
    rightBracket: ]
    resolution: MethodIndexReadResolution
      element: SubstitutedMethodElementImpl
        baseElement: dart:core::@class::List::@method::[]
        substitution: {E: int}
      invokeType: int Function(int)
      type: int
    staticType: int
  operator: .
  name: toRadixString
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      IntegerLiteral
        literal: 16
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  resolution: InvalidInvocationResolution
    type: InvalidType
    recovery: <null>
  staticType: InvalidType
V1: MethodInvocation
  target: IndexExpression
    period: ..
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: SubstitutedFormalParameterElementImpl
        baseElement: dart:core::@class::List::@method::[]::@formalParameter::index
        substitution: {E: int}
      staticType: int
    rightBracket: ]
    element: SubstitutedMethodElementImpl
      baseElement: dart:core::@class::List::@method::[]
      substitution: {E: int}
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: toRadixString
    element: <null>
    staticType: InvalidType
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 16
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_indexSections_ast() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  dynamic operator[](int index) => 0;
  operator[]=(int index, dynamic value) {}
}

void f(A a) {
  a..[0]..[1] = 1..[2] += 1..[3] ??= 1;
}
''');

    var node = result.findNode.singleCascadeExpression;
    assertResolvedNodeText(node, r'''
CascadeExpression
  target2: UnqualifiedNameExpression
    name: a
    resolution: VariableReadResolution
      element: <testLibrary>::@function::f::@formalParameter::a
      type: A
    staticType: A
  target(v1): SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  sections
    CascadeSection
      operator: ..
      body: CascadeIndexExpression
        leftBracket: [
        index: IntegerLiteral
          literal: 0
          correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
          staticType: int
        rightBracket: ]
        resolution: MethodIndexReadResolution
          element: <testLibrary>::@class::A::@method::[]
          invokeType: dynamic Function(int)
          type: dynamic
        staticType: dynamic
    CascadeSection
      operator: ..
      body: DirectAssignment
        target: CascadeIndexAssignmentTarget
          leftBracket: [
          index: IntegerLiteral
            literal: 1
            correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
            staticType: int
          rightBracket: ]
          read: <null>
          write: MethodIndexWriteResolution
            element: <testLibrary>::@class::A::@method::[]=
            invokeType: void Function(int, dynamic)
            acceptedType: dynamic
        operator: =
        value: IntegerLiteral
          literal: 1
          correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
          staticType: int
        staticType: int
    CascadeSection
      operator: ..
      body: CompoundAssignment
        target: CascadeIndexAssignmentTarget
          leftBracket: [
          index: IntegerLiteral
            literal: 2
            correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
            staticType: int
          rightBracket: ]
          read: MethodIndexReadResolution
            element: <testLibrary>::@class::A::@method::[]
            invokeType: dynamic Function(int)
            type: dynamic
          write: MethodIndexWriteResolution
            element: <testLibrary>::@class::A::@method::[]=
            invokeType: void Function(int, dynamic)
            acceptedType: dynamic
        operator: +=
        value: IntegerLiteral
          literal: 1
          correspondingParameter: <null>
          staticType: int
        binaryOperator: add
        element: <null>
        operatorResultType: dynamic
        staticType: dynamic
    CascadeSection
      operator: ..
      body: IfNullAssignment
        target: CascadeIndexAssignmentTarget
          leftBracket: [
          index: IntegerLiteral
            literal: 3
            correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
            staticType: int
          rightBracket: ]
          read: MethodIndexReadResolution
            element: <testLibrary>::@class::A::@method::[]
            invokeType: dynamic Function(int)
            type: dynamic
          write: MethodIndexWriteResolution
            element: <testLibrary>::@class::A::@method::[]=
            invokeType: void Function(int, dynamic)
            acceptedType: dynamic
        operator: ??=
        value: IntegerLiteral
          literal: 1
          correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
          staticType: int
        staticType: dynamic
  cascadeSections
    IndexExpression
      period: ..
      leftBracket: [
      index: IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
        staticType: int
      rightBracket: ]
      element: <testLibrary>::@class::A::@method::[]
      staticType: dynamic
    AssignmentExpression
      leftHandSide: IndexExpression
        period: ..
        leftBracket: [
        index: IntegerLiteral
          literal: 1
          correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
          staticType: int
        rightBracket: ]
        element: <null>
        staticType: null
      operator: =
      rightHandSide: IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
        staticType: int
      readElement: <null>
      readType: null
      writeElement: <testLibrary>::@class::A::@method::[]=
      writeType: dynamic
      element: <null>
      staticType: int
    AssignmentExpression
      leftHandSide: IndexExpression
        period: ..
        leftBracket: [
        index: IntegerLiteral
          literal: 2
          correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
          staticType: int
        rightBracket: ]
        element: <null>
        staticType: null
      operator: +=
      rightHandSide: IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
      readElement: <testLibrary>::@class::A::@method::[]
      readType: dynamic
      writeElement: <testLibrary>::@class::A::@method::[]=
      writeType: dynamic
      element: <null>
      staticType: dynamic
    AssignmentExpression
      leftHandSide: IndexExpression
        period: ..
        leftBracket: [
        index: IntegerLiteral
          literal: 3
          correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
          staticType: int
        rightBracket: ]
        element: <null>
        staticType: null
      operator: ??=
      rightHandSide: IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::value
        staticType: int
      readElement: <testLibrary>::@class::A::@method::[]
      readType: dynamic
      writeElement: <testLibrary>::@class::A::@method::[]=
      writeType: dynamic
      element: <null>
      staticType: dynamic
  staticType: A
''');
  }

  test_method_lexicalArgument() async {
    var result = await resolveTestCode(r'''
class A {
  T m<T>(T value) => value;
}
void f(A a, String m) {
  a..m(m);
}
''');
    var node = result.findNode.cascadeMethodInvocation('m(m)');
    assertResolvedNodeText(node, r'''
CascadeMethodInvocation
  name: m
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      UnqualifiedNameExpression
        name: m
        resolution: VariableReadResolution
          element: <testLibrary>::@function::f::@formalParameter::m
          type: String
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@method::m::@formalParameter::value
          substitution: {T: String}
        staticType: String
    rightParenthesis: )
  resolution: ExecutableInvocationResolution
    element: <testLibrary>::@class::A::@method::m
    invokeType: String Function(String)
    type: String
  staticType: String
  typeArgumentTypes
    String
V1: MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: m
    element: <testLibrary>::@class::A::@method::m
    staticType: String Function(String)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: m
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@method::m::@formalParameter::value
          substitution: {T: String}
        element: <testLibrary>::@function::f::@formalParameter::m
        staticType: String
    rightParenthesis: )
  staticInvokeType: String Function(String)
  staticType: String
  typeArgumentTypes
    String
''');
  }

  test_nullAware_indexGet_promotableField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final D? _d;
  C(this._d);
}

abstract class D {
  void f();
  void g();
  D operator[](int i);
}

test(C c) {
  c.._d?[0].f().._d?.g();
}
''');
    // The null shorting for the index get `.._d?[0]` ends at the end of the
    // cascade section, therefore in the cascade section that follows, `..d_`
    // has static type `D?`.
    var node = result.findNode.cascadePropertyExtraction('_d?.g()');
    assertResolvedNodeText(node, r'''
CascadePropertyExtraction
  name: _d
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::_d
    invokeType: D? Function()
    type: D?
  staticType: D?
V1: PropertyAccess
  operator: ..
  propertyName: SimpleIdentifier
    token: _d
    element: <testLibrary>::@class::C::@getter::_d
    staticType: D?
  staticType: D?
''');
  }

  test_nullAware_indexGet_promotableLocal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  D? get d;
}

abstract class D {
  void f(int i);
  void g(int i);
  D operator[](int i);
}

test(C c, int? i) {
  c..d?[0].f(i!)..d?.g(i!);
}

''');
    // The null shorting for the index get `..d?[0]` ends at the end of the
    // cascade section, therefore in the cascade section that follows, `i` has
    // static type `int?`.
    var node = result.findNode.unqualifiedNameExpression('i!);');
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: i
  resolution: VariableReadResolution
    element: <testLibrary>::@function::test::@formalParameter::i
    type: int?
  staticType: int?
V1: SimpleIdentifier
  token: i
  element: <testLibrary>::@function::test::@formalParameter::i
  staticType: int?
''');
  }

  test_nullAware_indexSet_promotableLocal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  D get d;
  void f(int i);
}

abstract class D {
  int? operator[](int i);
  operator[]=(int i, int? j);
}

test(C c, int? i) {
  c..d[0] ??= i!..f(i!);
}
''');
    // The null shorting for the index set `..d[0] ??= i!` ends at the end of
    // the cascade section, therefore in the cascade section that follows, `i`
    // has static type `int?`.
    var node = result.findNode.unqualifiedNameExpression('i!);');
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: i
  resolution: VariableReadResolution
    element: <testLibrary>::@function::test::@formalParameter::i
    type: int?
  staticType: int?
V1: SimpleIdentifier
  token: i
  element: <testLibrary>::@function::test::@formalParameter::i
  staticType: int?
''');
  }

  test_nullAware_methodInvocation_promotableField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final D? _d;
  C(this._d);
}

abstract class D {
  void f();
  void g();
}

test(C c) {
  c.._d?.f().._d?.g();
}
''');
    // The null shorting for the method invocation `.._d?.f()` ends at the end
    // of the cascade section, therefore in the cascade section that follows,
    // `.._d` has static type `D?`.
    var node = result.findNode.cascadePropertyExtraction('_d?.g()');
    assertResolvedNodeText(node, r'''
CascadePropertyExtraction
  name: _d
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::_d
    invokeType: D? Function()
    type: D?
  staticType: D?
V1: PropertyAccess
  operator: ..
  propertyName: SimpleIdentifier
    token: _d
    element: <testLibrary>::@class::C::@getter::_d
    staticType: D?
  staticType: D?
''');
  }

  test_nullAware_methodInvocation_promotableLocal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  D? get d;
}

abstract class D {
  void f(int i);
  void g(int i);
}

test(C c, int? i) {
  c..d?.f(i!)..d?.g(i!);
}
''');
    // The null shorting for the method invocation `..d?.f(i!)` ends at the end
    // of the cascade section, therefore in the cascade section that follows,
    // `i` has static type `int?`.
    var node = result.findNode.unqualifiedNameExpression('i!);');
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: i
  resolution: VariableReadResolution
    element: <testLibrary>::@function::test::@formalParameter::i
    type: int?
  staticType: int?
V1: SimpleIdentifier
  token: i
  element: <testLibrary>::@function::test::@formalParameter::i
  staticType: int?
''');
  }

  test_nullAware_nullTarget_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Null a) {
  a?..foo(0);
//    ^^^^^^^
// [diag.deadCode] Dead code.
}
''');
    var node = result.findNode.cascadeMethodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
CascadeMethodInvocation
  name: foo
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  resolution: <null>
  staticType: Never
V1: MethodInvocation
  operator: ?..
  methodName: SimpleIdentifier
    token: foo
    element: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: Never
''');
  }

  test_nullAware_propertyGet_promotableField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  final D? _d;
  C(this._d);
}

abstract class D {
  void f();
  void g();
  D get d;
}

test(C c) {
  c.._d?.d.f().._d?.g();
}
''');
    // The null shorting for the property get `.._d?.d` ends at the end of the
    // cascade section, therefore in the cascade section that follows, `..d_`
    // has static type `D?`.
    var node = result.findNode.cascadePropertyExtraction('_d?.g()');
    assertResolvedNodeText(node, r'''
CascadePropertyExtraction
  name: _d
  resolution: GetterInvocationResolution
    element: <testLibrary>::@class::C::@getter::_d
    invokeType: D? Function()
    type: D?
  staticType: D?
V1: PropertyAccess
  operator: ..
  propertyName: SimpleIdentifier
    token: _d
    element: <testLibrary>::@class::C::@getter::_d
    staticType: D?
  staticType: D?
''');
  }

  test_nullAware_propertyGet_promotableLocal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  D? get d;
}

abstract class D {
  void f(int i);
  void g(int i);
  D get d;
}

test(C c, int? i) {
  c..d?.d.f(i!)..d?.g(i!);
}

''');
    // The null shorting for the property get `..d?.d` ends at the end of the
    // cascade section, therefore in the cascade section that follows, `i` has
    // static type `int?`.
    var node = result.findNode.unqualifiedNameExpression('i!);');
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: i
  resolution: VariableReadResolution
    element: <testLibrary>::@function::test::@formalParameter::i
    type: int?
  staticType: int?
V1: SimpleIdentifier
  token: i
  element: <testLibrary>::@function::test::@formalParameter::i
  staticType: int?
''');
  }

  test_nullAware_propertySet_promotableLocal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class C {
  int? x;
  void f(int i);
}

test(C c, int? i) {
  c..x ??= i!..f(i!);
}
''');
    // The null shorting for the property set `..x ??= i!` ends at the end of
    // the cascade section, therefore in the cascade section that follows, `i`
    // has static type `int?`.
    var node = result.findNode.unqualifiedNameExpression('i!);');
    assertResolvedNodeText(node, r'''
UnqualifiedNameExpression
  name: i
  resolution: VariableReadResolution
    element: <testLibrary>::@function::test::@formalParameter::i
    type: int?
  staticType: int?
V1: SimpleIdentifier
  token: i
  element: <testLibrary>::@function::test::@formalParameter::i
  staticType: int?
''');
  }

  test_recordField_call() async {
    var result = await resolveTestCode(r'''
void f((int Function(String),) a) {
  a..$1('');
}
''');
    var node = result.findNode.callInvocation(r"$1('')");
    assertResolvedNodeText(node, r'''
CallInvocation
  receiver: CascadePropertyExtraction
    name: $1
    resolution: RecordFieldReadResolution
      type: int Function(String)
    staticType: int Function(String)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  resolution: FunctionTypeInvocationResolution
    invokeType: int Function(String)
    type: int
  staticType: int
V1: FunctionExpressionInvocation
  function: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: $1
      element: <null>
      staticType: int Function(String)
    staticType: int Function(String)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  element: <null>
  staticInvokeType: int Function(String)
  staticType: int
''');
  }
}
