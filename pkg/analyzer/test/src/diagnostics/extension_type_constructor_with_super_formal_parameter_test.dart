// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeConstructorWithSuperFormalParameterTest);
  });
}

@reflectiveTest
class ExtensionTypeConstructorWithSuperFormalParameterTest
    extends PubPackageResolutionTest {
  test_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  E.named(this.it, {super.foo});
//                  ^^^^^
// [diag.extensionTypeConstructorWithSuperFormalParameter] Extension type constructors can't declare super formal parameters.
}
''');

    var node = result.findNode.formalParameterList('super.foo');
    assertResolvedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FieldFormalParameter
    thisKeyword: this
    period: .
    name: it
    declaredFragment: <testLibraryFragment> it@42
      element: hasImplicitType isFinal isPublic
        type: int
        field: <testLibrary>::@extensionType::E::@field::it
  leftDelimiter: {
  parameter: SuperFormalParameter
    superKeyword: super
    period: .
    name: foo
    declaredFragment: <testLibraryFragment> foo@53
      element: hasImplicitType isFinal isPublic
        type: dynamic
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  test_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  E.named(this.it, super.foo);
//                 ^^^^^
// [diag.extensionTypeConstructorWithSuperFormalParameter] Extension type constructors can't declare super formal parameters.
}
''');

    var node = result.findNode.formalParameterList('super.foo');
    assertResolvedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FieldFormalParameter
    thisKeyword: this
    period: .
    name: it
    declaredFragment: <testLibraryFragment> it@42
      element: hasImplicitType isFinal isPublic
        type: int
        field: <testLibrary>::@extensionType::E::@field::it
  parameter: SuperFormalParameter
    superKeyword: super
    period: .
    name: foo
    declaredFragment: <testLibraryFragment> foo@52
      element: hasImplicitType isFinal isPublic
        type: dynamic
  rightParenthesis: )
''');
  }
}
