// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedeclareOnNonRedeclaringMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RedeclareOnNonRedeclaringMemberTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(PackageConfigFileBuilder(), meta: true);
  }

  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {}

extension type E(C c) implements C {
  @redeclare
  int get i => 0;
//        ^
// [diag.redeclareOnNonRedeclaringMember] The getter doesn't redeclare a getter declared in a superinterface.
}
''');
  }

  test_getter_redeclares() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  int get i => 0;
}

extension type E(C c) implements C {
  @redeclare
  int get i => 0;
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {}

extension type E(C c) implements C {
  @redeclare
  void n() {}
//     ^
// [diag.redeclareOnNonRedeclaringMember] The method doesn't redeclare a method declared in a superinterface.
}
''');
  }

  test_method_inClass() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {}

class D implements C {
  // No REDECLARE_ON_NON_REDECLARING_MEMBER warning.
  @redeclare
// ^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'redeclare' can only be used on instance members of extension types.
  void n() {}
}
''');
  }

  test_method_redeclared() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  void m() {}
}

extension type E(C c) implements C {
  @redeclare
  void m() {}
}
''');
  }

  test_method_redeclared_private() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class A {
  void _foo() {}
//     ^^^^
// [diag.unusedElement] The declaration '_foo' isn't referenced.
}

extension type E(A it) implements A {
  @redeclare
  void _foo() {}
//     ^^^^
// [diag.unusedElement] The declaration '_foo' isn't referenced.
}
''');
  }

  test_method_static() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {}

extension type E(C c) implements C {
  // No REDECLARE_ON_NON_REDECLARING_MEMBER warning.
  @redeclare
// ^^^^^^^^^
// [diag.invalidAnnotationTarget] The annotation 'redeclare' can only be used on instance members of extension types.
  static void n() {}
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {}

extension type E(C c) implements C {
  @redeclare
  set i(int i) {}
//    ^
// [diag.redeclareOnNonRedeclaringMember] The setter doesn't redeclare a setter declared in a superinterface.
}
''');
  }

  test_setter_redeclares() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';

class C {
  set i(int i) {}
}

extension type E(C c) implements C {
  @redeclare
  set i(int i) {}
}
''');
  }
}
