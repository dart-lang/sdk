// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferMixinTest);
  });
}

@reflectiveTest
class PreferMixinTest extends LintRuleTest {
  @override
  List<String> get experiments => ['sealed-classes', 'class-modifiers'];

  @override
  String get lintRule => 'prefer_mixin';

  /// https://github.com/dart-lang/linter/issues/4065
  test_mixinClass() async {
    await assertNoDiagnostics(r'''
mixin class M { }

class Z with M { }
''');
  }
}
