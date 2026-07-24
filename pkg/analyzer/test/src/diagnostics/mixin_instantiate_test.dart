// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinInstantiateTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinInstantiateTest extends PubPackageResolutionTest {
  test_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {
  M.named() {}
//^
// [diag.mixinDeclaresConstructor] Mixins can't declare constructors.
}

void f() {
  new M.named();
//    ^
// [diag.mixinInstantiate] Mixins can't be instantiated.
}
''');

    var node = result.findNode.singleConstructorInvocation;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  keyword: new
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: M
      element: <testLibrary>::@mixin::M
      type: M
    selector: ConstructorSelector
      period: .
      name2: named
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: M
invalidNodes
  ConstructorDeclarationImpl [12, 24)
''');
  }

  test_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}

void f() {
  new M();
//    ^
// [diag.mixinInstantiate] Mixins can't be instantiated.
}
''');

    var node = result.findNode.singleConstructorInvocation;
    assertResolvedNodeText(node, r'''
ConstructorInvocation
  keyword: new
  constructorReference: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: M
      element: <testLibrary>::@mixin::M
      type: M
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: M
''');
  }
}
