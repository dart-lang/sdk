// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsSuperClassConstraintTest);
  });
}

@reflectiveTest
class ImplementsSuperClassConstraintTest extends PubPackageResolutionTest {
  test_it() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M on A implements A {}
''');
  }

  test_it_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {}
mixin M on A implements A {}
//                      ^
// [diag.implementsSuperClassConstraint] 'class A' can't be used in both the 'on' and 'implements' clauses.
''');
  }
}
