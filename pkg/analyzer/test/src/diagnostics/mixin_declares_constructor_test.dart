// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeclaresConstructorTest);
  });
}

@reflectiveTest
class MixinDeclaresConstructorTest extends PubPackageResolutionTest {
  test_factory_named() async {
    await assertErrorsInCode(r'''
mixin M {
  factory M.named() => throw 0;
}
''', [
      error(ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR, 12, 7),
    ]);

    var node = findNode.singleMixinDeclaration;
    assertResolvedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  leftBracket: {
  rightBracket: }
  declaredElement: <testLibraryFragment>::@mixin::M
''');
  }

  test_factory_unnamed() async {
    await assertErrorsInCode(r'''
mixin M {
  factory M() => throw 0;
}
''', [
      error(ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR, 12, 7),
    ]);

    var node = findNode.singleMixinDeclaration;
    assertResolvedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  leftBracket: {
  rightBracket: }
  declaredElement: <testLibraryFragment>::@mixin::M
''');
  }

  test_generative_named() async {
    await assertErrorsInCode(r'''
mixin M {
  M.named();
}
''', [
      error(ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR, 12, 1),
    ]);

    var node = findNode.singleMixinDeclaration;
    assertResolvedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  leftBracket: {
  rightBracket: }
  declaredElement: <testLibraryFragment>::@mixin::M
''');
  }

  test_generative_unnamed() async {
    await assertErrorsInCode(r'''
mixin M {
  M();
}
''', [
      error(ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR, 12, 1),
    ]);

    var node = findNode.singleMixinDeclaration;
    assertResolvedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  leftBracket: {
  rightBracket: }
  declaredElement: <testLibraryFragment>::@mixin::M
''');
  }
}
