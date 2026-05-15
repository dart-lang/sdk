// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinsSuperClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinsSuperClassTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
class B extends A with A {}
//                     ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
''');
  }

  test_class_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
typedef B = A;
class C extends A with B {}
//                     ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
''');
  }

  test_classAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
class B = A with A;
//               ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
''');
  }

  test_classAlias_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
typedef B = A;
class C = A with B;
//               ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
''');
  }
}
