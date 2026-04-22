// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryTypeNameInConstructorTest);
  });
}

@reflectiveTest
class UnnecessaryTypeNameInConstructorTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_type_name_in_constructor;

  test_factory_named() async {
    await assertDiagnosticsFromMarkdown(r'''
class C {
  factory [!C!].name() => C._();
  new _();
}
''');
  }

  test_factory_unnamed() async {
    await assertDiagnosticsFromMarkdown(r'''
class C {
  factory [!C!]() => C._();
  new _();
}
''');
  }

  test_generative_named() async {
    await assertDiagnosticsFromMarkdown(r'''
class C {
  [!C!].name();
}
''');
  }

  test_generative_unnamed() async {
    await assertDiagnosticsFromMarkdown(r'''
class C {
  [!C!]();
}
''');
  }

  test_generative_unnamed_explicitNew() async {
    await assertDiagnosticsFromMarkdown(r'''
class C {
  [!C!].new();
}
''');
  }
}
