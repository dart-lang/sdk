// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverrideOnNonOverridingGetterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class OverrideOnNonOverridingGetterTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  @override
  int get foo => 0;
//        ^^^
// [diag.overrideOnNonOverridingGetter] The getter doesn't override an inherited getter.
}
''');
  }

  test_class_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

class B extends A {
  @override
  int get foo => 0;
}
''');
  }

  test_class_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

class B implements A {
  @override
  int get foo => 0;
}
''');
  }

  test_class_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  @override
  static int get foo => 0;
//               ^^^
// [diag.overrideOnNonOverridingGetter] The getter doesn't override an inherited getter.
}
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  @override
  int get foo => 0;
//        ^^^
// [diag.overrideOnNonOverridingGetter] The getter doesn't override an inherited getter.
}
''');
  }

  test_enum_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

enum E implements A {
  v;
  @override
  int get foo => 0;
}
''');
  }

  test_enum_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  @override
  int get foo => 0;
}
''');
  }

  test_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  @override
  int get foo => 1;
//        ^^^
// [diag.overrideOnNonOverridingGetter] The getter doesn't override an inherited getter.
}
''');
  }

  test_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  @override
  int get foo => 0;
//        ^^^
// [diag.overrideOnNonOverridingGetter] The getter doesn't override an inherited getter.
}
''');
  }

  test_topLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
@override
int get foo => 1;
//      ^^^
// [diag.overrideOnNonOverridingGetter] The getter doesn't override an inherited getter.
''');
  }
}
