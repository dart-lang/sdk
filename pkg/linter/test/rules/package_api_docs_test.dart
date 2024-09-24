// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackageApiDocsTest);
  });
}

@reflectiveTest
class PackageApiDocsTest extends LintRuleTest {
  @override
  List<AnalyzerErrorCode> get ignoredErrorCodes => [WarningCode.UNUSED_ELEMENT];

  @override
  String get lintRule => 'package_api_docs';

  test_privateClass() async {
    await assertNoDiagnostics(r'''
class _Bar {}
''');
  }

  @FailingTest(reason: 'fix API Model to treat tests specially')
  test_publicClass() async {
    await assertDiagnostics(r'''
class Foo {}
''', [
      lint(6, 3),
    ]);
  }

  test_publicMember_ofPrivateClass() async {
    await assertNoDiagnostics(r'''
class _C {
  int m() => 42;
}
''');
  }

  @FailingTest(reason: 'fix API Model to treat tests specially')
  test_publicMember_ofPublicClass() async {
    await assertDiagnostics(r'''
/// Documented.
class Foo {
  int foo() => 42;
}
''', [
      lint(34, 3),
    ]);
  }

  test_publicMember_ofPublicClass_documented() async {
    await assertNoDiagnostics(r'''
/// Documented.
class Foo {
  /// Documented.
  int foo() => 42;
}
''');
  }
}
