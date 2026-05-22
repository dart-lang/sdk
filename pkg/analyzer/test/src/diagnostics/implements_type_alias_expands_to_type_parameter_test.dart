// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsTypeAliasExpandsToTypeParameterTest);
  });
}

@reflectiveTest
class ImplementsTypeAliasExpandsToTypeParameterTest
    extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef T = A;
class B implements T {}
''');
  }

  test_class_typeParameter_noTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef T<X extends A> = X;
class B implements T {}
//                 ^
// [diag.implementsTypeAliasExpandsToTypeParameter] A type alias that expands to a type parameter can't be implemented.
''');

    var node = result.findNode.namedType('T {}');
    assertResolvedNodeText(node, r'''
NamedType
  name: T
  element: <testLibrary>::@typeAlias::T
  type: InvalidType
''');
  }

  test_class_typeParameter_withTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef T<X extends A> = X;
class B implements T<A> {}
//                 ^
// [diag.implementsTypeAliasExpandsToTypeParameter] A type alias that expands to a type parameter can't be implemented.
''');

    var node = result.findNode.namedType('T<A> {}');
    assertResolvedNodeText(node, r'''
NamedType
  name: T
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: A
        element: <testLibrary>::@class::A
        type: A
    rightBracket: >
  element: <testLibrary>::@typeAlias::T
  type: InvalidType
''');
  }

  test_mixin_typeParameter_noTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef T<X extends A> = X;
mixin M implements T {}
//                 ^
// [diag.implementsTypeAliasExpandsToTypeParameter] A type alias that expands to a type parameter can't be implemented.
''');

    var node = result.findNode.namedType('T {}');
    assertResolvedNodeText(node, r'''
NamedType
  name: T
  element: <testLibrary>::@typeAlias::T
  type: InvalidType
''');
  }
}
