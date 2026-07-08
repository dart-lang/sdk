// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryPrimaryConstructorBodyTest);
  });
}

@reflectiveTest
class UnnecessaryPrimaryConstructorBodyTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_primary_constructor_body;

  test_emptyBody_block() async {
    await assertDiagnosticsFromMarkup(r'''
class C() {
  [!this!] {}
}
''');
  }

  test_emptyBody_semicolon() async {
    await assertDiagnosticsFromMarkup(r'''
class C() {
  [!this!];
}
''');
  }

  test_hasDocComment() async {
    await assertNoDiagnostics(r'''
class C() {
  /// comment
  this;
}
''');
  }

  test_hasInitializer() async {
    await assertNoDiagnostics(r'''
class C(int i) {
  this : assert(i >= 0);
}
''');
  }

  test_hasMetadata() async {
    await assertNoDiagnostics(r'''
class C() {
  @deprecated
  this;
}
''');
  }

  test_hasNonEmptyBody() async {
    await assertNoDiagnostics(r'''
class C(int i) {
  this {
    print(i);
  }
}
''');
  }
}
