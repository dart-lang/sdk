// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidRelativeLibImportsTest);
  });
}

@reflectiveTest
class AvoidRelativeLibImportsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_relative_lib_imports;

  @override
  void setUp() {
    newPackage('foo').addFile('lib/foo.dart', r'''
class Foo {}
''');
    super.setUp();
  }

  test_externalPackage() async {
    await assertNoDiagnostics(r'''
/// This provides [Foo].
import 'package:foo/foo.dart';
''');
  }

  test_samePackage_relativeUri() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    var test = newFile('$testPackageRootPath/test/test.dart', r'''
/// This provides [C].
import '../lib/lib.dart';
''');
    await assertDiagnosticsInFile(test.path, [lint(30, 17)]);
  }

  test_samePackage_relativeUri_inPart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');

    newFile('$testPackageRootPath/test/a.dart', r'''
part 'test.dart';
''');

    var test = newFile('$testPackageRootPath/test/test.dart', r'''
part of 'a.dart';

/// This provides [C].
import '../lib/lib.dart';
''');
    await assertDiagnosticsInFile(test.path, [lint(49, 17)]);
  }
}
