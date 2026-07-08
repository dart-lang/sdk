// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotateRedeclaresTest);
  });
}

@reflectiveTest
class AnnotateRedeclaresTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.annotate_redeclares;

  test_augmentationClass_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

class A {
  void m() {}
}
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

extension type E(A a) implements A {
  void [!m!]() {}
}
''');
  }

  @FailingTest(
    issue: 'https://github.com/dart-lang/sdk/issues/56174',
    reason: 'There are unexpected diagnostics.',
  )
  // TODO(scheglov): implement augmentation
  test_augmentationMethodWithAnnotation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

import 'package:meta/meta.dart';

class A {
  void m() {}
}

extension type E(A a) implements A {
  @redeclare
  void m() {}
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment extension type E(A a) {
  augment void m() { }
}
''');
  }

  test_method() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  void m() {}
}

extension type E(A a) implements A {
  void [!m!]() {}
}
''');
  }

  test_method_annotated() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  void m() {}
}

extension type E(A a) implements A {
  @redeclare
  void m() {}
}
''');
  }

  test_setter() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  int i = 0;
}

extension type E(A a) implements A {
  set [!i!](int i) {}
}
''');
  }
}
