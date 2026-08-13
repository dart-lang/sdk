// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinOfTypeAliasExpandsToTypeParameterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinOfTypeAliasExpandsToTypeParameterTest
    extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}
typedef T = A;
class B with A {}
''');
  }

  test_class_noTypeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}
typedef T<X extends A> = X;
class B with T {}
//           ^
// [diag.mixinOfTypeAliasExpandsToTypeParameter] A type alias that expands to a type parameter can't be mixed in.
''');
  }

  test_class_withTypeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}
typedef T<X extends A> = X;
class B with T<A> {}
//           ^
// [diag.mixinOfTypeAliasExpandsToTypeParameter] A type alias that expands to a type parameter can't be mixed in.
''');
  }
}
