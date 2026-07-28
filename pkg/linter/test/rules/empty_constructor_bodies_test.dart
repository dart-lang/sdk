// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmptyConstructorBodiesTest);
  });
}

@reflectiveTest
class EmptyConstructorBodiesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.empty_constructor_bodies;

  test_empty_inBody_factory() async {
    // No diagnostic is produced because there's already an error indicating
    // that the constructor doesn't return a value.
    await assertDiagnostics(
      r'''
class A {
  factory () {}
}
''',
      [error(diag.bodyMightCompleteNormally, 12, 7)],
    );
  }

  test_empty_inBody_new() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  new() [!{}!]
}
''');
  }

  test_empty_inBody_normal() async {
    await assertDiagnosticsFromMarkup(r'''
class A {
  A() [!{}!]
}
''');
  }

  test_empty_primary() async {
    await assertDiagnosticsFromMarkup(r'''
class A() {
  this : assert(1 < 2) [!{}!]
}
''');
  }

  test_empty_withComment() async {
    await assertNoDiagnostics(r'''
class A {
  A() {
    // Comments make this OK!
  }
}
''');
  }

  test_noBody() async {
    await assertNoDiagnostics(r'''
class A {
  A();
}
''');
  }

  test_noBody_parameters() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}
''');
  }

  test_notEmpty() async {
    await assertNoDiagnostics(r'''
class A {
  A() {
    print('hi');
  }
}
''');
  }
}
