// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverrideOnNonOverridingSetterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class OverrideOnNonOverridingSetterTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  @override
  set foo(int _) {}
//    ^^^
// [diag.overrideOnNonOverridingSetter] The setter doesn't override an inherited setter.
}
''');
  }

  test_class_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set m(int x) {}
}
class B extends A {
  @override
  set m(int x) {}
}''');
  }

  test_class_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set m(int x) {}
}
class B implements A {
  @override
  set m(int x) {}
}''');
  }

  test_class_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  @override
  static set foo(int _) {}
//           ^^^
// [diag.overrideOnNonOverridingSetter] The setter doesn't override an inherited setter.
}
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  @override
  set foo(int _) {}
//    ^^^
// [diag.overrideOnNonOverridingSetter] The setter doesn't override an inherited setter.
}
''');
  }

  test_enum_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}

enum E implements A {
  v;
  @override
  set foo(int _) {}
}
''');
  }

  test_enum_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  set foo(int _) {}
}

enum E with M {
  v;
  @override
  set foo(int _) {}
}
''');
  }

  test_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  @override
  set foo(int _) {}
//    ^^^
// [diag.overrideOnNonOverridingSetter] The setter doesn't override an inherited setter.
}
''');
  }

  test_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

mixin M on A {
  @override
  set foo(int _) {}
//    ^^^
// [diag.overrideOnNonOverridingSetter] The setter doesn't override an inherited setter.
}
''');
  }

  test_topLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
@override
set foo(int _) {}
//  ^^^
// [diag.overrideOnNonOverridingSetter] The setter doesn't override an inherited setter.
''');
  }
}
