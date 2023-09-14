// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CanonicalizationTest);
  });
}

@reflectiveTest
class CanonicalizationTest extends PubPackageResolutionTest {
  // ignore: non_constant_identifier_names
  test_canonicalizedPathResolution() async {
    /// https://github.com/dart-lang/linter/commit/fcb8c9093c9c7a7cfabe27e17d40bd09d4c408f7
    newFile('$testPackageLibPath/lib3.dart', r'''
C g() => C();

class C {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib3.dart';

void f(C c) {}
''');

    await assertNoDiagnostics(r'''
import 'package:test/lib2.dart';

import 'lib3.dart';

void test() {
  f(g());
}
''');
  }
}
