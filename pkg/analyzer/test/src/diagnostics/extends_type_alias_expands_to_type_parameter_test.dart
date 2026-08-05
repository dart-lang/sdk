// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsTypeAliasExpandsToTypeParameterTest);
  });
}

@reflectiveTest
class ExtendsTypeAliasExpandsToTypeParameterTest
    extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef T = A;
class B extends A {}
''');
  }

  test_class_noTypeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef T<X extends A> = X;
class B extends T {}
//              ^
// [diag.extendsTypeAliasExpandsToTypeParameter] A type alias that expands to a type parameter can't be used as a superclass.
''');
  }

  test_class_withTypeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef T<X extends A> = X;
class B extends T<A> {}
//              ^
// [diag.extendsTypeAliasExpandsToTypeParameter] A type alias that expands to a type parameter can't be used as a superclass.
''');
  }
}
