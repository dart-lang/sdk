// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSuperClassConstraintNonInterfaceTest);
  });
}

@reflectiveTest
class MixinSuperClassConstraintNonInterfaceTest
    extends PubPackageResolutionTest {
  test_dynamic() async {
    await assertErrorsInCode(r'''
mixin M on dynamic {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE, 11,
          7),
    ]);

    final node = findNode.singleOnClause;
    assertResolvedNodeText(node, r'''
OnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: SimpleIdentifier
        token: dynamic
        staticElement: dynamic@-1
        staticType: null
      type: dynamic
''');
  }

  test_enum() async {
    await assertErrorsInCode(r'''
enum E { v }
mixin M on E {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE, 24,
          1),
    ]);

    final node = findNode.singleOnClause;
    assertResolvedNodeText(node, r'''
OnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: SimpleIdentifier
        token: E
        staticElement: self::@enum::E
        staticType: null
      type: E
''');
  }

  test_Never() async {
    await assertErrorsInCode('''
mixin M on Never {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE, 11,
          5),
    ]);

    final node = findNode.singleOnClause;
    assertResolvedNodeText(node, r'''
OnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: SimpleIdentifier
        token: Never
        staticElement: Never@-1
        staticType: null
      type: Never
''');
  }

  test_void() async {
    await assertErrorsInCode(r'''
mixin M on void {}
''', [
      error(ParserErrorCode.EXPECTED_TYPE_NAME, 11, 4),
      error(CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE, 11,
          4),
    ]);

    final node = findNode.singleOnClause;
    assertResolvedNodeText(node, r'''
OnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: SimpleIdentifier
        token: void
        staticElement: <null>
        staticType: null
      type: void
''');
  }
}
