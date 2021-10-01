// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConstConstructorsTest);
  });
}

@reflectiveTest
class PreferConstConstructorsTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'prefer_const_constructors';

  test_extraPositionalArgument() async {
    await assertDiagnostics(r'''
import 'package:meta/meta.dart';

class K {
  @literal
  const K();
}

K k() {
  var kk = K();
  return kk;
}
''', [
      // No lint
      error(HintCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR, 90, 3),
    ]);
  }
}
