// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstantiateTypeAliasExpandsToTypeParameterTest);
  });
}

@reflectiveTest
class InstantiateTypeAliasExpandsToTypeParameterTest
    extends PubPackageResolutionTest {
  test_const_generic_noArguments_unnamed_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = T;

void f() {
  const A();
//      ^
// [diag.instantiateTypeAliasExpandsToTypeParameter] Type aliases that expand to a type parameter can't be instantiated.
}
''');
  }

  test_const_notGeneric_unnamed_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

typedef X = A;

void f() {
  const X();
}
''');
  }

  test_new_generic_noArguments_unnamed_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = T;

void f() {
  new A();
//    ^
// [diag.instantiateTypeAliasExpandsToTypeParameter] Type aliases that expand to a type parameter can't be instantiated.
}
''');
  }

  test_new_generic_withArgument_named_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named();
}

typedef B<T> = T;

void f() {
  new B<A>.named();
//    ^
// [diag.instantiateTypeAliasExpandsToTypeParameter] Type aliases that expand to a type parameter can't be instantiated.
}
''');
  }

  test_new_generic_withArgument_unnamed_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

typedef B<T> = T;

void f() {
  new B<A>();
//    ^
// [diag.instantiateTypeAliasExpandsToTypeParameter] Type aliases that expand to a type parameter can't be instantiated.
}
''');
  }

  test_new_notGeneric_unnamed_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

typedef X = A;

void f() {
  new X();
}
''');
  }

  test_new_notGeneric_unnamed_typeParameter2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = T;
typedef B<T> = A<T>;

void f() {
  new B();
//    ^
// [diag.instantiateTypeAliasExpandsToTypeParameter] Type aliases that expand to a type parameter can't be instantiated.
}
''');

    var node = result.findNode.instanceCreation('new B()');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: B
      element: <testLibrary>::@typeAlias::B
      type: InvalidType
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: InvalidType
''');
  }
}
