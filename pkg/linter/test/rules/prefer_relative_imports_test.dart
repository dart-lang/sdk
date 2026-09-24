// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferRelativeImportsTest);
  });
}

@reflectiveTest
class PreferRelativeImportsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_relative_imports;

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
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');
    await assertNoDiagnostics(r'''
part of 'a.dart';

/// This provides [Foo].
import 'package:foo/foo.dart';
''');
  }

  test_internalPackage() async {
    var packageConfigBuilder = PackageConfigFileBuilder();
    packageConfigBuilder.add(
      name: 'internal_package',
      rootFolder: getFolder('$testPackageRootPath/vendor/internal_package'),
    );
    writeTestPackageConfig2(config: packageConfigBuilder);

    newFile('$testPackageRootPath/vendor/internal_package/lib/lib.dart', r'''
class C {}
''');
    await assertNoDiagnostics(r'''
/// This provides [C].
import 'package:internal_package/lib.dart';
''');
  }

  test_internalPackage_inPart() async {
    var packageConfigBuilder = PackageConfigFileBuilder();
    packageConfigBuilder.add(
      name: 'internal_package',
      rootFolder: getFolder('$testPackageRootPath/vendor/internal_package'),
    );
    writeTestPackageConfig2(config: packageConfigBuilder);

    newFile('$testPackageRootPath/vendor/internal_package/lib/lib.dart', r'''
class C {}
''');
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');
    await assertNoDiagnostics(r'''
part of 'a.dart';

/// This provides [C].
import 'package:internal_package/lib.dart';
''');
  }

  test_samePackage_packageSchema() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    await assertDiagnosticsFromMarkup(r'''
/// This provides [C].
import [!'package:test/lib.dart'!];
''');
  }

  test_samePackage_packageSchema_fromOutsideLib() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    var bin = newFile('$testPackageRootPath/bin/bin.dart', r'''
/// This provides [C].
import 'package:test/lib.dart';
''');
    await assertNoDiagnosticsInFile(bin.path);
  }

  test_samePackage_packageSchema_inPart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

/// This provides [C].
import [!'package:test/lib.dart'!];
''');
  }

  test_samePackage_packageSchema_inPart_fromOutsideLib() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');

    newFile('$testPackageRootPath/bin/a.dart', r'''
part 'part.dart';
''');

    var part = newFile('$testPackageRootPath/bin/part.dart', r'''
part of 'a.dart';

/// This provides [C].
import 'package:test/lib.dart';
''');
    await assertNoDiagnosticsInFile(part.path);
  }

  test_samePackage_packageSchema_inSubpart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'test.dart';
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'b.dart';

/// This provides [C].
import [!'package:test/lib.dart'!];
''');
  }

  test_samePackage_relativeUri() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    await assertNoDiagnostics(r'''
/// This provides [C].
import 'lib.dart';
''');
  }

  test_samePackage_relativeUri_fromOutsideLib() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');
    var bin = newFile('$testPackageRootPath/bin/bin.dart', r'''
/// This provides [C].
import '../lib/lib.dart';
''');
    await assertNoDiagnosticsInFile(bin.path);
  }

  test_samePackage_relativeUri_inPart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

/// This provides [C].
import 'lib.dart';
''');
  }

  test_samePackage_relativeUri_inPart_fromOutsideLib() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');

    newFile('$testPackageRootPath/bin/a.dart', r'''
part 'part.dart';
''');

    var part = newFile('$testPackageRootPath/bin/part.dart', r'''
part of 'a.dart';

/// This provides [C].
import '../lib/lib.dart';
''');
    await assertNoDiagnosticsInFile(part.path);
  }

  test_samePackage_relativeUri_inSubpart() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class C {}
''');

    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
part 'test.dart';
''');

    await assertNoDiagnostics(r'''
part of 'b.dart';

/// This provides [C].
import 'lib.dart';
''');
  }
}
