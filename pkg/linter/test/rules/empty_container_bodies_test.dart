// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmptyContainerBodiesTest);
  });
}

@reflectiveTest
class EmptyContainerBodiesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.empty_container_bodies;

  test_class_notEmpty() async {
    await assertNoDiagnostics(r'''
class C {
  C();
}
''');
  }

  test_class_onDifferentLines() async {
    await assertDiagnosticsFromMarkdown(r'''
class C [!{
}!]
''');
  }

  test_class_onSameLine() async {
    await assertDiagnosticsFromMarkdown(r'''
class C [!{}!]
''');
  }

  test_class_withComment() async {
    await assertNoDiagnostics(r'''
class C {
  // eol
}
''');
  }

  test_class_withDocComment() async {
    await assertNoDiagnostics(r'''
class C {
  /// doc
}
''');
  }

  test_extension() async {
    await assertDiagnosticsFromMarkdown(r'''
extension on String [!{}!]
''');
  }

  test_extensionType() async {
    await assertDiagnosticsFromMarkdown(r'''
extension type E(String self) [!{}!]
''');
  }

  test_mixin() async {
    await assertDiagnosticsFromMarkdown(r'''
mixin M [!{}!]
''');
  }
}
