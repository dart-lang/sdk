// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinWithNonClassSuperclassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinWithNonClassSuperclassTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
int A = 0;
mixin B {}
class C extends A with B {}
//              ^
// [diag.mixinWithNonClassSuperclass] Mixin can only be applied to class.
''');
  }

  test_mixinApplication() async {
    await resolveTestCodeWithDiagnostics(r'''
int A = 0;
mixin B {}
class C = A with B;
//        ^
// [diag.mixinWithNonClassSuperclass] Mixin can only be applied to class.
''');
  }
}
