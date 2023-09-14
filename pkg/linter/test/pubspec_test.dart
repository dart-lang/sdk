// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BadPubspecTest);
  });
}

@reflectiveTest
class BadPubspecTest extends LintRuleTest {
  @override
  String get lintRule => 'sort_pub_dependencies';

  // ignore: non_constant_identifier_names
  test_malformedPubspec() async {
    await assertNoPubspecDiagnostics(r'''
not: a
  valid
 pub
  spec:
''');
  }
}
