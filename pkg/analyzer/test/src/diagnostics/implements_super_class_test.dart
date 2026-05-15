// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsSuperClassTest);
  });
}

@reflectiveTest
class ImplementsSuperClassTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A implements A {}
//                           ^
// [diag.implementsSuperClass] 'class A' can't be used in both the 'extends' and 'implements' clauses.
''');
  }

  test_class_Object() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements Object {}
//                 ^^^^^^
// [diag.implementsSuperClass] 'class Object' can't be used in both the 'extends' and 'implements' clauses.
''');
  }

  test_class_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef B = A;
class C extends A implements B {}
//                           ^
// [diag.implementsSuperClass] 'class A' can't be used in both the 'extends' and 'implements' clauses.
''');
  }

  test_classAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M {}
class B = A with M implements A;
//                            ^
// [diag.implementsSuperClass] 'class A' can't be used in both the 'extends' and 'implements' clauses.
''');
  }

  test_classAlias_Object() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
class A = Object with M implements Object;
//                                 ^^^^^^
// [diag.implementsSuperClass] 'class Object' can't be used in both the 'extends' and 'implements' clauses.
''');
  }

  test_classAlias_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M {}
typedef B = A;
class C = A with M implements B;
//                            ^
// [diag.implementsSuperClass] 'class A' can't be used in both the 'extends' and 'implements' clauses.
''');
  }
}
