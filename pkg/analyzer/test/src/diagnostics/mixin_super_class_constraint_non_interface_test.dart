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
    await assertErrorsInCode(
      r'''
mixin M on dynamic {}
''',
      [
        error(
          CompileTimeErrorCode.mixinSuperClassConstraintNonInterface,
          11,
          7,
        ),
      ],
    );

    var node = findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: dynamic
      element2: dynamic
      type: dynamic
''');
  }

  test_enum() async {
    await assertErrorsInCode(
      r'''
enum E { v }
mixin M on E {}
''',
      [
        error(
          CompileTimeErrorCode.mixinSuperClassConstraintNonInterface,
          24,
          1,
        ),
      ],
    );

    var node = findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: E
      element2: <testLibrary>::@enum::E
      type: E
''');
  }

  test_extensionType() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}
mixin M on A {}
''',
      [
        error(
          CompileTimeErrorCode.mixinSuperClassConstraintNonInterface,
          39,
          1,
        ),
      ],
    );

    var node = findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: A
      element2: <testLibrary>::@extensionType::A
      type: A
''');
  }

  test_Never() async {
    await assertErrorsInCode(
      '''
mixin M on Never {}
''',
      [
        error(
          CompileTimeErrorCode.mixinSuperClassConstraintNonInterface,
          11,
          5,
        ),
      ],
    );

    var node = findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: Never
      element2: Never
      type: Never
''');
  }

  test_void() async {
    await assertErrorsInCode(
      r'''
mixin M on void {}
''',
      [
        error(ParserErrorCode.expectedTypeName, 11, 4),
        error(
          CompileTimeErrorCode.mixinSuperClassConstraintNonInterface,
          11,
          4,
        ),
      ],
    );

    var node = findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: void
      element2: <null>
      type: void
''');
  }
}
