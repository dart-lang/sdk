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

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3389')
  test_deferred_arg() async {
    newFile2('$testPackageLibPath/a.dart', '''
class A {
  const A();
}

const aa = A();
''');

    await assertNoDiagnostics(r'''
import 'a.dart' deferred as a;

class B {
  const B(Object a);
}

main() {
  var b = B(a.aa);
  print(b);
}   
''');
  }

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
