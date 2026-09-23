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

  test_externalPackage() async {
    newPackage('foo').addFile('lib/foo.dart', r'''
class Foo {}
''');
    writeTestPackageConfig2();
    await assertNoDiagnostics(r'''
/// This provides [Foo].
import 'package:foo/foo.dart';
''');
  }

  test_externalPackage_inPart() async {
    newPackage('foo').addFile('lib/foo.dart', r'''
class Foo {}
''');
    writeTestPackageConfig2();
    newFile('$testPackageRootPath/test/a.dart', r'''
part 'test.dart';
''');
    await assertNoDiagnosticsInTestDir(r'''
part of 'a.dart';

/// This provides [Foo].
import 'package:foo/foo.dart';
''');
  }

  test_samePackage_packageSchema() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    await assertNoDiagnosticsInTestDir(r'''
/// This provides [C].
import 'package:test/lib.dart';
''');
  }

  test_samePackage_packageSchema_inPart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    newFile('$testPackageRootPath/test/a.dart', r'''
part 'test.dart';
''');
    await assertNoDiagnosticsInTestDir(r'''
part of 'a.dart';

/// This provides [C].
import 'package:test/lib.dart';
''');
  }

  test_samePackage_packageSchema_inSubpart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    newFile('$testPackageRootPath/test/a.dart', r'''
part 'b.dart';
''');
    newFile('$testPackageRootPath/test/b.dart', r'''
part of 'a.dart';
part 'test.dart';
''');
    await assertNoDiagnosticsInTestDir(r'''
part of 'b.dart';

/// This provides [C].
import 'package:test/lib.dart';
''');
  }

  test_samePackage_relativeUri() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    await assertDiagnosticsInTestDirFromMarkup(r'''
/// This provides [C].
import [!'../lib/lib.dart'!];
''');
  }

  test_samePackage_relativeUri_inPart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');

    newFile('$testPackageRootPath/test/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnosticsInTestDirFromMarkup(r'''
part of 'a.dart';

/// This provides [C].
import [!'../lib/lib.dart'!];
''');
  }

  test_samePackage_relativeUri_inSubpart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');

    newFile('$testPackageRootPath/test/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageRootPath/test/b.dart', r'''
part of 'a.dart';
part 'test.dart';
''');

    await assertDiagnosticsInTestDirFromMarkup(r'''
part of 'b.dart';

/// This provides [C].
import [!'../lib/lib.dart'!];
''');
  }
}
