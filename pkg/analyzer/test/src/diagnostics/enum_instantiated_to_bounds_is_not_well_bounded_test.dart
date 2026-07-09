// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumInstantiatedToBoundsIsNotWellBoundedTest);
  });
}

@reflectiveTest
class EnumInstantiatedToBoundsIsNotWellBoundedTest
    extends PubPackageResolutionTest {
  test_enum_it() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A<X> = X Function(X);

enum E<T extends A<T>, U> {
//   ^
// [diag.enumInstantiatedToBoundsIsNotWellBounded] The result of instantiating the enum to bounds is not well-bounded.
  v<Never, int>()
}
''');
  }
}
