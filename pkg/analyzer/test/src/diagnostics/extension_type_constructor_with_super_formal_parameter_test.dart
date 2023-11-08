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
    await assertErrorsInCode('''
extension type E(int it) {
  E.named(this.it, {super.foo});
}
''', [
      error(
          CompileTimeErrorCode
              .EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_FORMAL_PARAMETER,
          47,
          5),
    ]);

    final node = findNode.singleFormalParameterList;
    assertResolvedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FieldFormalParameter
    thisKeyword: this
    period: .
    name: it
    declaredElement: self::@extensionType::E::@constructor::named::@parameter::it
      type: int
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SuperFormalParameter
      superKeyword: super
      period: .
      name: foo
      declaredElement: self::@extensionType::E::@constructor::named::@parameter::foo
        type: dynamic
    declaredElement: self::@extensionType::E::@constructor::named::@parameter::foo
      type: dynamic
  rightDelimiter: }
  rightParenthesis: )
''');
  }

  test_positional() async {
    await assertErrorsInCode('''
extension type E(int it) {
  E.named(this.it, super.foo);
}
''', [
      error(
          CompileTimeErrorCode
              .EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_FORMAL_PARAMETER,
          46,
          5),
    ]);

    final node = findNode.singleFormalParameterList;
    assertResolvedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  parameter: FieldFormalParameter
    thisKeyword: this
    period: .
    name: it
    declaredElement: self::@extensionType::E::@constructor::named::@parameter::it
      type: int
  parameter: SuperFormalParameter
    superKeyword: super
    period: .
    name: foo
    declaredElement: self::@extensionType::E::@constructor::named::@parameter::foo
      type: dynamic
  rightParenthesis: )
''');
  }
}
