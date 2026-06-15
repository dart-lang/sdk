// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSuperClassConstraintNonInterfaceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinSuperClassConstraintNonInterfaceTest
    extends PubPackageResolutionTest {
  test_dynamic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M on dynamic {}
//         ^^^^^^^
// [diag.mixinSuperClassConstraintNonInterface] Only classes and mixins can be used as superclass constraints.
''');

    var node = result.findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: dynamic
      element: dynamic
      type: dynamic
''');
  }

  test_enum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E { v }
mixin M on E {}
//         ^
// [diag.mixinSuperClassConstraintNonInterface] Only classes and mixins can be used as superclass constraints.
''');

    var node = result.findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: E
      element: <testLibrary>::@enum::E
      type: E
''');
  }

  test_extensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
mixin M on A {}
//         ^
// [diag.mixinSuperClassConstraintNonInterface] Only classes and mixins can be used as superclass constraints.
''');

    var node = result.findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: A
      element: <testLibrary>::@extensionType::A
      type: A
''');
  }

  test_Never() async {
    var result = await resolveTestCodeWithDiagnostics('''
mixin M on Never {}
//         ^^^^^
// [diag.mixinSuperClassConstraintNonInterface] Only classes and mixins can be used as superclass constraints.
''');

    var node = result.findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: Never
      element: Never
      type: Never
''');
  }

  test_void() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M on void {}
//         ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.mixinSuperClassConstraintNonInterface] Only classes and mixins can be used as superclass constraints.
''');

    var node = result.findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: void
      element: <null>
      type: void
''');
  }
}
