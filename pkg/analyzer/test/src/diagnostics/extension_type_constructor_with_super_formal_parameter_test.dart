// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
    await assertErrorsInCode(
      '''
extension type E(int it) {
  E.named(this.it, {super.foo});
}
''',
      [
        error(
          CompileTimeErrorCode.extensionTypeConstructorWithSuperFormalParameter,
          47,
          5,
        ),
      ],
    );

    var node = findNode.singleFormalParameterList;
    assertResolvedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FieldFormalParameter
    thisKeyword: this
    period: .
    name: it
    declaredElement: <testLibraryFragment> it@42
      element: hasImplicitType isFinal isPublic
        type: int
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SuperFormalParameter
      superKeyword: super
      period: .
      name: foo
      declaredElement: <testLibraryFragment> foo@53
        element: hasImplicitType isFinal isPublic
          type: dynamic
    declaredElement: <testLibraryFragment> foo@53
      element: hasImplicitType isFinal isPublic
        type: dynamic
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  test_positional() async {
    await assertErrorsInCode(
      '''
extension type E(int it) {
  E.named(this.it, super.foo);
}
''',
      [
        error(
          CompileTimeErrorCode.extensionTypeConstructorWithSuperFormalParameter,
          46,
          5,
        ),
      ],
    );

    var node = findNode.singleFormalParameterList;
    assertResolvedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FieldFormalParameter
    thisKeyword: this
    period: .
    name: it
    declaredElement: <testLibraryFragment> it@42
      element: hasImplicitType isFinal isPublic
        type: int
  parameter: SuperFormalParameter
    superKeyword: super
    period: .
    name: foo
    declaredElement: <testLibraryFragment> foo@52
      element: hasImplicitType isFinal isPublic
        type: dynamic
  rightParenthesis: )
''');
  }
}
