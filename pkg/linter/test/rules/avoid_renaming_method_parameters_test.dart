// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    // TODO(srawlins): Add more tests:
    // * implementation (B implements A),
    defineReflectiveTests(AvoidRenamingMethodParametersTest);
  });
}

@reflectiveTest
class AvoidRenamingMethodParametersTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_renaming_method_parameters;

  @FailingTest(
    reason: 'lint is limited to methods',
    issue: 'https://github.com/dart-lang/linter/issues/4891',
  )
  test_augmentedFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

void f(int p) {}
''');

    await assertDiagnostics(
      r'''
part of 'a.dart';

augment void f(int q) {}
''',
      [lint(41, 1)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_augmentedMethod() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void m(int p) {}
}
''');

    await assertDiagnostics(
      r'''
part of 'a.dart';

augment class A {
  augment void m(int q) {}
  augment void m(int q) {}
}
''',
      [
        lint(58, 1), // Only the first augmentation gets linted.
      ],
    );
  }

  test_enumMixingIn() async {
    await assertDiagnostics(
      r'''
mixin class C {
  int f(int f) => f;
}
enum A with C {
  a,b,c;
  @override
  int f(int x) => x;
}
''',
      [lint(88, 1)],
    );
  }

  test_extends_indirectly() async {
    await assertDiagnostics(
      r'''
class A {
  void m(int p) {}
}
class B extends A {}
class C extends B {
  @override
  void m(int q) {}
}
''',
      [lint(97, 1)],
    );
  }

  test_mixedIn() async {
    await assertDiagnostics(
      r'''
mixin M {
  void m(int p) {}
}
class C with M {
  @override
  void m(int q) {}
}
''',
      [lint(73, 1)],
    );
  }

  test_mixinApplication() async {
    await assertDiagnostics(
      r'''
mixin M {
  void m(int p) {}
}
abstract class C = Object with M;
class D extends C {
  @override
  void m(int q) {}
}
''',
      [lint(110, 1)],
    );
  }

  test_optionalPositional_renamed() async {
    await assertDiagnostics(
      r'''
class A {
  void m([int p = 0]) {}
}
class B extends A {
  void m([int q = 0]) {}
}
''',
      [lint(71, 1)],
    );
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
    await assertDiagnostics(
      r'''
class A {
  void m(int p) {}
}
class B extends A {
  void m(int q) {}
}
''',
      [lint(64, 1)],
    );
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
    await assertNoDiagnosticsInFile(lib.path);
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

  test_renamingWithDoubleUnderscore() async {
    await assertDiagnostics(
      r'''
class A {
  void m(int p) {}
}
class B extends A {
  @override
  void m(int __) {}
}
''',
      [lint(76, 2)],
    );
  }

  test_renamingWithWildcard() async {
    await assertNoDiagnostics(r'''
class A {
  void m(int p) {}
}
class B extends A {
  @override
  void m(int _) {}
}
''');
  }

  test_wildcard_allowed() async {
    await assertNoDiagnostics(r'''
class A {
  void m(int p) {}
}
class B extends A {
  void m(_) {}
}
''');
  }

  test_wildcard_featureDisabledFails() async {
    await assertDiagnostics(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  void m(int p) {}
}
class B extends A {
  void m(_) {}
}
''',
      [lint(104, 1)],
    );
  }

  test_wildcard_mixed() async {
    await assertNoDiagnostics(r'''
class A {
  void m(int a, int b, int c) {}
}
class B extends A {
  void m(_, b, _) {}
}
''');
  }

  test_wildcard_mixedFails() async {
    await assertDiagnostics(
      r'''
class A {
  void m(int a, int b, int c) {}
}
class B extends A {
  void m(_, c, _) {}
}
''',
      [lint(77, 1)],
    );
  }

  test_wildcard_multipleWildcards() async {
    await assertNoDiagnostics(r'''
class A {
  void m(int a, int b) {}
}
class B extends A {
  void m(_, _) {}
}
''');
  }

  test_wildcard_nonWildcardButUnderscoreBefore() async {
    await assertDiagnostics(
      r'''
class A {
  void m(int a, int b) {}
}
class B extends A {
  void m(_, _b) {}
}
''',
      [lint(70, 2)],
    );
  }

  test_wildcard_nonWildcardButUnderscoresAround() async {
    await assertDiagnostics(
      r'''
class A {
  void m(int p) {}
}
class B extends A {
  void m(_p_) {}
}
''',
      [lint(60, 3)],
    );
  }

  test_wildcardInBase() async {
    await assertNoDiagnostics(r'''
class A {
  void m(int _, int b, int c) {}
}
class B extends A {
  void m(a, b, c) {}
}
''');
  }

  test_wildcardInBaseAndSub() async {
    await assertNoDiagnostics(r'''
class A {
  void m(int _, int b, int c) {}
}
class B extends A {
  void m(a, b, _) {}
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
