// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConstLiteralsToCreateImmutablesTest);
  });
}

@reflectiveTest
class PreferConstLiteralsToCreateImmutablesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'prefer_const_literals_to_create_immutables';

  test_extensionType() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
extension type E(List<int> i) { }

var e = E([1]);
''', [
      lint(90, 3),
    ]);
  }

  test_missingRequiredArgument() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

@immutable
class K {
  final List<K> children;
  const K({required this.children});
}

final k = K(
  children: <K>[for (var i = 0; i < 5; ++i) K()], // OK
);
''', [
      // No lint
      error(CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT, 178, 1),
    ]);
  }

  test_newWithNonType() async {
    await assertDiagnostics(r'''
var e1 = new B([]); // OK
''', [
      // No lint
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 13, 1),
    ]);
  }
}
