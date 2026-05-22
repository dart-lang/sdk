// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeclaresConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinDeclaresConstructorTest extends PubPackageResolutionTest {
  test_factory_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {
  factory M.named() => throw 0;
//^^^^^^^
// [diag.mixinDeclaresConstructor] Mixins can't declare constructors.
}
''');

    var node = result.findNode.singleMixinDeclaration;
    assertResolvedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> M@6
invalidNodes
  ConstructorDeclarationImpl [12, 41)
''');
  }

  test_factory_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {
  factory M() => throw 0;
//^^^^^^^
// [diag.mixinDeclaresConstructor] Mixins can't declare constructors.
}
''');

    var node = result.findNode.singleMixinDeclaration;
    assertResolvedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> M@6
invalidNodes
  ConstructorDeclarationImpl [12, 35)
''');
  }

  test_generative_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {
  M.named();
//^
// [diag.mixinDeclaresConstructor] Mixins can't declare constructors.
}
''');

    var node = result.findNode.singleMixinDeclaration;
    assertResolvedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> M@6
invalidNodes
  ConstructorDeclarationImpl [12, 22)
''');
  }

  test_generative_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {
  M();
//^
// [diag.mixinDeclaresConstructor] Mixins can't declare constructors.
}
''');

    var node = result.findNode.singleMixinDeclaration;
    assertResolvedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> M@6
invalidNodes
  ConstructorDeclarationImpl [12, 16)
''');
  }
}
