// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrivateSetterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PrivateSetterTest extends PubPackageResolutionTest {
  test_typeLiteral_privateField_differentLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int _foo = 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

main() {
  A._foo = 0;
//  ^^^^
// [diag.privateSetter] The setter '_foo' is private and can't be accessed outside the library that declares it.
}
''');

    var node = result.findNode.assignment('_foo =');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: package:test/a.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: package:test/a.dart::@class::A::@setter::_foo::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@class::A::@setter::_foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_typeLiteral_privateField_sameLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  // ignore:unused_field
  static int _foo = 0;
}

main() {
  A._foo = 0;
}
''');
  }

  test_typeLiteral_privateSetter_differentLibrary_hasGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static set _foo(int _) {}

  static int get _foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

main() {
  A._foo = 0;
//  ^^^^
// [diag.privateSetter] The setter '_foo' is private and can't be accessed outside the library that declares it.
}
''');

    var node = result.findNode.assignment('_foo =');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: package:test/a.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: package:test/a.dart::@class::A::@setter::_foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@class::A::@setter::_foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_typeLiteral_privateSetter_differentLibrary_noGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static set _foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

main() {
  A._foo = 0;
//  ^^^^
// [diag.privateSetter] The setter '_foo' is private and can't be accessed outside the library that declares it.
}
''');

    var node = result.findNode.assignment('_foo =');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: package:test/a.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: _foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: package:test/a.dart::@class::A::@setter::_foo::@formalParameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@class::A::@setter::_foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_typeLiteral_privateSetter_sameLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set _foo(int _) {}
}

main() {
  A._foo = 0;
}
''');
  }
}
