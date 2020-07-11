// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryElementTest);
  });
}

@reflectiveTest
class LibraryElementTest extends DriverResolutionTest {
  test_languageVersion() async {
    newFile('/test/.dart_tool/package_config.json', content: '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.7"
    },
    {
      "name": "aaa",
      "rootUri": "${toUriStr('/aaa')}",
      "packageUri": "lib/"
    }
  ]
}
''');
    driver.configure(
      packages: findPackagesFrom(
        resourceProvider,
        getFolder('/test'),
      ),
    );

    newFile('/test/lib/a.dart', content: r'''
class A {}
''');

    newFile('/test/lib/b.dart', content: r'''
// @dart = 2.6
class A {}
''');

    newFile('/test/lib/c.dart', content: r'''
// @dart = 2.9
class A {}
''');

    newFile('/test/lib/d.dart', content: r'''
// @dart = 2.99
class A {}
''');

    newFile('/test/lib/e.dart', content: r'''
// @dart = 3.0
class A {}
''');

    newFile('/aaa/lib/a.dart', content: r'''
class A {}
''');

    newFile('/aaa/lib/b.dart', content: r'''
// @dart = 2.99
class A {}
''');

    newFile('/aaa/lib/c.dart', content: r'''
// @dart = 3.0
class A {}
''');

    // No override.
    await _assertLanguageVersion(
      uriStr: 'package:test/a.dart',
      package: Version.parse('2.7.0'),
      override: null,
    );

    // Valid override, less than the latest supported language version.
    await _assertLanguageVersion(
      uriStr: 'package:test/b.dart',
      package: Version.parse('2.7.0'),
      override: Version.parse('2.6.0'),
    );

    // Valid override, even if greater than the package language version.
    await _assertLanguageVersion(
      uriStr: 'package:test/c.dart',
      package: Version.parse('2.7.0'),
      override: Version.parse('2.9.0'),
    );

    // Invalid override: minor is greater than the latest minor.
    await _assertLanguageVersion(
      uriStr: 'package:test/d.dart',
      package: Version.parse('2.7.0'),
      override: null,
    );

    // Invalid override: major is greater than the latest major.
    await _assertLanguageVersion(
      uriStr: 'package:test/e.dart',
      package: Version.parse('2.7.0'),
      override: null,
    );

    await _assertLanguageVersionCurrent('package:aaa/a.dart');
    await _assertLanguageVersionCurrent('package:aaa/b.dart');
    await _assertLanguageVersionCurrent('package:aaa/c.dart');
  }

  test_scope() async {
    await assertNoErrorsInCode(r'''
int foo;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup(id: 'foo', setter: false),
      findElement.topGet('foo'),
    );
    assertElement(
      scope.lookup(id: 'foo', setter: true),
      findElement.topSet('foo'),
    );
  }

  test_scope_implicitCoreImport() async {
    await assertNoErrorsInCode('');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup(id: 'int', setter: false),
      intElement,
    );
  }

  test_scope_notFound() async {
    await assertNoErrorsInCode('');

    var scope = result.libraryElement.scope;

    assertElementNull(
      scope.lookup(id: 'noSuchGetter', setter: false),
    );

    assertElementNull(
      scope.lookup(id: 'noSuchSetter', setter: true),
    );
  }

  test_scope_prefersLocal() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math';

int sin() => 3;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup(id: 'sin', setter: false),
      findElement.topFunction('sin'),
    );

    assertElement(
      scope.lookup(id: 'cos', setter: false),
      findElement.importFind('dart:math').topFunction('cos'),
    );
  }

  test_scope_prefix() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup(id: 'math', setter: false),
      findElement.prefix('math'),
    );
  }

  test_scope_respectsCombinator_hide() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' hide sin;
''');

    var scope = result.libraryElement.scope;

    assertElementNull(
      scope.lookup(id: 'sin', setter: false),
    );

    var mathFind = findElement.importFind('dart:math');
    assertElement(
      scope.lookup(id: 'cos', setter: false),
      mathFind.topFunction('cos'),
    );
    assertElement(
      scope.lookup(id: 'tan', setter: false),
      mathFind.topFunction('tan'),
    );
  }

  test_scope_respectsCombinator_show() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' show sin;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup(id: 'sin', setter: false),
      findElement.importFind('dart:math').topFunction('sin'),
    );

    assertElementNull(
      scope.lookup(id: 'cos', setter: false),
    );
  }

  Future<void> _assertLanguageVersion({
    @required String uriStr,
    @required Version package,
    @required Version override,
  }) async {
    var element = await driver.getLibraryByUri(uriStr);
    expect(element.languageVersion.package, package);
    expect(element.languageVersion.override, override);
  }

  Future<void> _assertLanguageVersionCurrent(String uriStr) async {
    await _assertLanguageVersion(
      uriStr: uriStr,
      package: ExperimentStatus.currentVersion,
      override: null,
    );
  }
}
