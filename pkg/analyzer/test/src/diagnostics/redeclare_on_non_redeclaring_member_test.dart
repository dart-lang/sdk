// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedeclareOnNonRedeclaringMemberTest);
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
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

class C {}

extension type E(C c) implements C {
  @redeclare
  int get i => 0;
}
''',
      [error(diag.redeclareOnNonRedeclaringMember, 106, 1)],
    );
  }

  test_getter_redeclares() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

class C {}

extension type E(C c) implements C {
  @redeclare
  void n() {}
}
''',
      [error(diag.redeclareOnNonRedeclaringMember, 103, 1)],
    );
  }

  test_method_inClass() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

class C {}

class D implements C {
  @redeclare
  void n() {}
}
''',
      [
        // No REDECLARE_ON_NON_REDECLARING_MEMBER warning.
        error(diag.invalidAnnotationTarget, 72, 9),
      ],
    );
  }

  test_method_redeclared() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

class A {
  void _foo() {}
}

extension type E(A it) implements A {
  @redeclare
  void _foo() {}
}
''',
      [error(diag.unusedElement, 51, 4), error(diag.unusedElement, 122, 4)],
    );
  }

  test_method_static() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

class C {}

extension type E(C c) implements C {
  @redeclare
  static void n() {}
}
''',
      [
        // No REDECLARE_ON_NON_REDECLARING_MEMBER warning.
        error(diag.invalidAnnotationTarget, 86, 9),
      ],
    );
  }

  test_setter() async {
    await assertErrorsInCode(
      r'''
import 'package:meta/meta.dart';

class C {}

extension type E(C c) implements C {
  @redeclare
  set i(int i) {}
}
''',
      [error(diag.redeclareOnNonRedeclaringMember, 102, 1)],
    );
  }

  test_setter_redeclares() async {
    await assertNoErrorsInCode(r'''
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
