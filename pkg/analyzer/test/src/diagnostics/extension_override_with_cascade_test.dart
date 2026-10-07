// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideWithCascadeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExtensionOverrideWithCascadeTest extends PubPackageResolutionTest {
  test_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get g => 0;
}
f() {
  E(3)..g..g;
//^
// [diag.extensionOverrideWithCascade] Extension overrides have no value so they can't be used as the receiver of a cascade expression.
}
''');
    var node = result.findNode.cascade('E(');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target2: InvalidExtensionOverrideExpression
    extensionOverride: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 3
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    staticType: InvalidType
  target(v1): ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 3
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: dynamic
  sections
    CascadeSection
      operator: ..
      body: CascadePropertyExtraction
        name: g
        resolution: GetterInvocationResolution
          element: <testLibrary>::@extension::E::@getter::g
          invokeType: int Function()
          type: int
        staticType: int
    CascadeSection
      operator: ..
      body: CascadePropertyExtraction
        name: g
        resolution: GetterInvocationResolution
          element: <testLibrary>::@extension::E::@getter::g
          invokeType: int Function()
          type: int
        staticType: int
  cascadeSections
    PropertyAccess
      operator: ..
      propertyName: SimpleIdentifier
        token: g
        element: <testLibrary>::@extension::E::@getter::g
        staticType: int
      staticType: int
    PropertyAccess
      operator: ..
      propertyName: SimpleIdentifier
        token: g
        element: <testLibrary>::@extension::E::@getter::g
        staticType: int
      staticType: int
  staticType: InvalidType
''');
  }

  test_index() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get g => 0;
  int operator [](int index) => 0;
  void operator []=(int index, int value) {}
}
f() {
  E(3)..g..[0]..[1] = 2;
//^
// [diag.extensionOverrideWithCascade] Extension overrides have no value so they can't be used as the receiver of a cascade expression.
}
''');
    var node = result.findNode.cascade('E(');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target2: InvalidExtensionOverrideExpression
    extensionOverride: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 3
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    staticType: InvalidType
  target(v1): ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 3
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: dynamic
  sections
    CascadeSection
      operator: ..
      body: CascadePropertyExtraction
        name: g
        resolution: GetterInvocationResolution
          element: <testLibrary>::@extension::E::@getter::g
          invokeType: int Function()
          type: int
        staticType: int
    CascadeSection
      operator: ..
      body: CascadeIndexExpression
        leftBracket: [
        index: IntegerLiteral
          literal: 0
          correspondingParameter: <testLibrary>::@extension::E::@method::[]::@formalParameter::index
          staticType: int
        rightBracket: ]
        resolution: MethodIndexReadResolution
          element: <testLibrary>::@extension::E::@method::[]
          invokeType: int Function(int)
          type: int
        staticType: int
    CascadeSection
      operator: ..
      body: DirectAssignment
        target: CascadeIndexAssignmentTarget
          leftBracket: [
          index: IntegerLiteral
            literal: 1
            correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::index
            staticType: int
          rightBracket: ]
          read: <null>
          write: MethodIndexWriteResolution
            element: <testLibrary>::@extension::E::@method::[]=
            invokeType: void Function(int, int)
            acceptedType: int
        operator: =
        value: IntegerLiteral
          literal: 2
          correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::value
          staticType: int
        staticType: int
  cascadeSections
    PropertyAccess
      operator: ..
      propertyName: SimpleIdentifier
        token: g
        element: <testLibrary>::@extension::E::@getter::g
        staticType: int
      staticType: int
    IndexExpression
      period: ..
      leftBracket: [
      index: IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extension::E::@method::[]::@formalParameter::index
        staticType: int
      rightBracket: ]
      element: <testLibrary>::@extension::E::@method::[]
      staticType: int
    AssignmentExpression
      leftHandSide: IndexExpression
        period: ..
        leftBracket: [
        index: IntegerLiteral
          literal: 1
          correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::index
          staticType: int
        rightBracket: ]
        element: <null>
        staticType: null
      operator: =
      rightHandSide: IntegerLiteral
        literal: 2
        correspondingParameter: <testLibrary>::@extension::E::@method::[]=::@formalParameter::value
        staticType: int
      readElement: <null>
      readType: null
      writeElement: <testLibrary>::@extension::E::@method::[]=
      writeType: int
      element: <null>
      staticType: int
  staticType: InvalidType
''');
  }

  test_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void m() {}
}
f() {
  E(3)..m()..m();
//^
// [diag.extensionOverrideWithCascade] Extension overrides have no value so they can't be used as the receiver of a cascade expression.
}
''');
    var node = result.findNode.cascade('E(');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target2: InvalidExtensionOverrideExpression
    extensionOverride: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 3
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    staticType: InvalidType
  target(v1): ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 3
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: dynamic
  sections
    CascadeSection
      operator: ..
      body: CascadeMethodInvocation
        name: m
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        resolution: ExecutableInvocationResolution
          element: <testLibrary>::@extension::E::@method::m
          invokeType: void Function()
          type: void
        staticType: void
    CascadeSection
      operator: ..
      body: CascadeMethodInvocation
        name: m
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        resolution: ExecutableInvocationResolution
          element: <testLibrary>::@extension::E::@method::m
          invokeType: void Function()
          type: void
        staticType: void
  cascadeSections
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: m
        element: <testLibrary>::@extension::E::@method::m
        staticType: void Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: void Function()
      staticType: void
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: m
        element: <testLibrary>::@extension::E::@method::m
        staticType: void Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: void Function()
      staticType: void
  staticType: InvalidType
''');
  }

  test_method_nullAware() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int? {
  void m() {}
}
f(int? x) {
  E(x)?..m();
//^
// [diag.extensionOverrideWithCascade] Extension overrides have no value so they can't be used as the receiver of a cascade expression.
}
''');
    var node = result.findNode.cascade('E(');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target2: InvalidExtensionOverrideExpression
    extensionOverride: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          UnqualifiedNameExpression
            name: x
            resolution: VariableReadResolution
              element: <testLibrary>::@function::f::@formalParameter::x
              type: int?
            correspondingParameter: <null>
            staticType: int?
        arguments(v1)
          SimpleIdentifier
            token: x
            correspondingParameter: <null>
            element: <testLibrary>::@function::f::@formalParameter::x
            staticType: int?
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int?
    staticType: InvalidType
  target(v1): ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: x
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::x
          staticType: int?
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int?
    staticType: dynamic
  sections
    CascadeSection
      operator: ?..
      body: CascadeMethodInvocation
        name: m
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        resolution: ExecutableInvocationResolution
          element: <testLibrary>::@extension::E::@method::m
          invokeType: void Function()
          type: void
        staticType: void
  cascadeSections
    MethodInvocation
      operator: ?..
      methodName: SimpleIdentifier
        token: m
        element: <testLibrary>::@extension::E::@method::m
        staticType: void Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: void Function()
      staticType: void
  staticType: InvalidType
''');
  }

  test_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set s(int i) {}
}
f() {
  E(3)..s = 1..s = 2;
//^
// [diag.extensionOverrideWithCascade] Extension overrides have no value so they can't be used as the receiver of a cascade expression.
}
''');
    var node = result.findNode.cascade('E(');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target2: InvalidExtensionOverrideExpression
    extensionOverride: ExtensionOverride2
      name: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          IntegerLiteral
            literal: 3
            correspondingParameter: <null>
            staticType: int
        rightParenthesis: )
      element: <testLibrary>::@extension::E
      extendedType: int
    staticType: InvalidType
  target(v1): ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        IntegerLiteral
          literal: 3
          correspondingParameter: <null>
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: dynamic
  sections
    CascadeSection
      operator: ..
      body: DirectAssignment
        target: CascadePropertyAssignmentTarget
          name: s
          read: <null>
          write: SetterInvocationResolution
            element: <testLibrary>::@extension::E::@setter::s
            acceptedType: int
        operator: =
        value: IntegerLiteral
          literal: 1
          correspondingParameter: <testLibrary>::@extension::E::@setter::s::@formalParameter::i
          staticType: int
        staticType: int
    CascadeSection
      operator: ..
      body: DirectAssignment
        target: CascadePropertyAssignmentTarget
          name: s
          read: <null>
          write: SetterInvocationResolution
            element: <testLibrary>::@extension::E::@setter::s
            acceptedType: int
        operator: =
        value: IntegerLiteral
          literal: 2
          correspondingParameter: <testLibrary>::@extension::E::@setter::s::@formalParameter::i
          staticType: int
        staticType: int
  cascadeSections
    AssignmentExpression
      leftHandSide: PropertyAccess
        operator: ..
        propertyName: SimpleIdentifier
          token: s
          element: <null>
          staticType: null
        staticType: null
      operator: =
      rightHandSide: IntegerLiteral
        literal: 1
        correspondingParameter: <testLibrary>::@extension::E::@setter::s::@formalParameter::i
        staticType: int
      readElement: <null>
      readType: null
      writeElement: <testLibrary>::@extension::E::@setter::s
      writeType: int
      element: <null>
      staticType: int
    AssignmentExpression
      leftHandSide: PropertyAccess
        operator: ..
        propertyName: SimpleIdentifier
          token: s
          element: <null>
          staticType: null
        staticType: null
      operator: =
      rightHandSide: IntegerLiteral
        literal: 2
        correspondingParameter: <testLibrary>::@extension::E::@setter::s::@formalParameter::i
        staticType: int
      readElement: <null>
      readType: null
      writeElement: <testLibrary>::@extension::E::@setter::s
      writeType: int
      element: <null>
      staticType: int
  staticType: InvalidType
''');
  }
}
