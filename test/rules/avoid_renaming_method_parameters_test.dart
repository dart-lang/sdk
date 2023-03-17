// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    // TODO(srawlins): Add more tests:
    // * indirect extension (C extends B extends A),
    // * implementation (B implements A),
    // * mixing in
    // * mix-in applications
    // * renaming with `_`
    // * renaming with `__` (like `m(_, __)`)
    defineReflectiveTests(AvoidRenamingMethodParametersTest);
  });
}

@reflectiveTest
class AvoidRenamingMethodParametersTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_renaming_method_parameters';

  test_enumMixingIn() async {
    await assertDiagnostics(r'''
mixin class C {
  int f(int f) => f;
}
enum A with C {
  a,b,c;
  @override
  int f(int x) => x;
}
''', [
      lint(88, 1),
    ]);
  }

  test_optionalPositional_renamed() async {
    await assertDiagnostics(r'''
class A {
  void m([int p = 0]) {}
}
class B extends A {
  void m([int q = 0]) {}
}
''', [
      lint(71, 1),
    ]);
  }

  test_positional_docComments() async {
    await assertNoDiagnostics(r'''
class A {
  void m(int p) {}
}
class B extends A {
  /// New comment.
  void m(int q) {}
}
''');
  }

  test_positional_privateOverride() async {
    await assertNoDiagnostics(r'''
class A {
  void m(int p) {}
}
// ignore: unused_element
class _B extends A {
  void m(int q) {}
}
''');
  }

  test_positional_renamed() async {
    await assertDiagnostics(r'''
class A {
  void m(int p) {}
}
class B extends A {
  void m(int q) {}
}
''', [
      lint(64, 1),
    ]);
  }

  test_positional_renamed_nonLibSource() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void m(int p) {}
}
''');
    var lib = newFile('$testPackageRootPath/test/a.dart', r'''
import '../lib/a.dart';
class B extends A {
  void m(int q) {}
}
''');
    var result = await resolveFile(lib.path);
    await assertNoDiagnosticsIn(result.errors);
  }

  test_positional_sameName() async {
    await assertNoDiagnostics(r'''
class A {
  void m(int p) {}
}
class B extends A {
  void m(int p) {}
}
''');
  }

  test_zeroParameters() async {
    await assertNoDiagnostics(r'''
class A {
  void m() {}
}
class B extends A {
  void m() {}
}
''');
  }
}
