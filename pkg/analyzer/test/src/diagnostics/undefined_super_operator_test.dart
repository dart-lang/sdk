// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSuperOperatorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedSuperOperatorTest extends PubPackageResolutionTest {
  test_class_binaryExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  operator +(value) {
    return super + value;
//               ^
// [diag.undefinedSuperOperator] The operator '+' isn't defined in a superclass of 'B'.
  }
}
''');
  }

  test_class_indexBoth() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index]++;
//              ^^^^^^^
// [diag.undefinedSuperOperator] The operator '[]' isn't defined in a superclass of 'B'.
  }
}
''');
  }

  test_class_indexBoth_getterDefined() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator [](int index) => 0;
}
class B extends A {
  void f() {
    super[0] += 1;
//       ^^^
// [diag.undefinedSuperOperator] The operator '[]=' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.singleCompoundAssignment;
    assertResolvedNodeText(node, r'''
CompoundAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
      staticType: int
    rightBracket: ]
    read: MethodIndexReadResolution
      element: <testLibrary>::@class::A::@method::[]
      invokeType: int Function(int)
      type: int
    write: InvalidIndexWriteResolution
      recoveryElement: <null>
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
  leftHandSide: IndexExpression
    target: SuperExpression
      superKeyword: super
      staticType: B
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_class_indexGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index + 1];
//              ^^^^^^^^^^^
// [diag.undefinedSuperOperator] The operator '[]' isn't defined in a superclass of 'B'.
  }
}
''');
  }

  test_class_indexSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  operator []=(index, value) {
    super[index] = 0;
//       ^^^^^^^
// [diag.undefinedSuperOperator] The operator '[]=' isn't defined in a superclass of 'B'.
  }
}
''');
  }

  test_class_indexSetter_getterDefined() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator [](int index) => 0;
}
class B extends A {
  void f() {
    super[0] = 1;
//       ^^^
// [diag.undefinedSuperOperator] The operator '[]=' isn't defined in a superclass of 'B'.
  }
}
''');

    var node = result.findNode.singleDirectAssignment;
    assertResolvedNodeText(node, r'''
DirectAssignment
  target: ReceiverIndexAssignmentTarget
    receiver: SuperReference
      superKeyword: super
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    read: <null>
    write: InvalidIndexWriteResolution
      recoveryElement: <null>
  operator: =
  value: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  staticType: int
V1: AssignmentExpression
  leftHandSide: IndexExpression
    target: SuperExpression
      superKeyword: super
      staticType: B
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_enum_binaryExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void f() {
    super + 0;
//        ^
// [diag.undefinedSuperOperator] The operator '+' isn't defined in a superclass of 'E'.
  }
}
''');
  }

  test_enum_binaryExpression_OK() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int operator +(int a) => 0;
}

enum E with M {
  v;
  void f() {
    super + 0;
  }
}
''');
  }

  test_enum_indexBoth() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void f() {
    super[0]++;
//       ^^^
// [diag.undefinedSuperOperator] The operator '[]' isn't defined in a superclass of 'E'.
  }
}
''');
  }

  test_enum_indexBoth_OK() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int operator [](int index) => 0;
  void operator []=(int index, int value) {}
}

enum E with M {
  v;
  void f() {
    super[0]++;
  }
}
''');
  }

  test_enum_indexGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void f() {
    super[0];
//       ^^^
// [diag.undefinedSuperOperator] The operator '[]' isn't defined in a superclass of 'E'.
  }
}
''');
  }

  test_enum_indexSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void f() {
    super[0] = 0;
//       ^^^
// [diag.undefinedSuperOperator] The operator '[]=' isn't defined in a superclass of 'E'.
  }
}
''');
  }
}
