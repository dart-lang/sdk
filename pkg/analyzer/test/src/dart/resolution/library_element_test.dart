// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryElementTest);
  });
}

@reflectiveTest
class LibraryElementTest extends PubPackageResolutionTest {
  test_languageVersion() async {
    newFile('$testPackageRootPath/.dart_tool/package_config.json', content: '''
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

    newFile('$testPackageLibPath/a.dart', content: r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', content: r'''
// @dart = 2.6
class A {}
''');

    newFile('$testPackageLibPath/c.dart', content: r'''
// @dart = 2.9
class A {}
''');

    newFile('$testPackageLibPath/d.dart', content: r'''
// @dart = 2.99
class A {}
''');

    newFile('$testPackageLibPath/e.dart', content: r'''
// @dart = 3.0
class A {}
''');

    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {}
''');

    newFile('$workspaceRootPath/aaa/lib/b.dart', content: r'''
// @dart = 2.99
class A {}
''');

    newFile('$workspaceRootPath/aaa/lib/c.dart', content: r'''
// @dart = 3.0
class A {}
''');

    // No override.
    await _assertLanguageVersion(
      path: '$testPackageLibPath/a.dart',
      package: Version.parse('2.7.0'),
      override: null,
    );

    // Valid override, less than the latest supported language version.
    await _assertLanguageVersion(
      path: '$testPackageLibPath/b.dart',
      package: Version.parse('2.7.0'),
      override: Version.parse('2.6.0'),
    );

    // Valid override, even if greater than the package language version.
    await _assertLanguageVersion(
      path: '$testPackageLibPath/c.dart',
      package: Version.parse('2.7.0'),
      override: Version.parse('2.9.0'),
    );

    // Invalid override: minor is greater than the latest minor.
    await _assertLanguageVersion(
      path: '$testPackageLibPath/d.dart',
      package: Version.parse('2.7.0'),
      override: null,
    );

    // Invalid override: major is greater than the latest major.
    await _assertLanguageVersion(
      path: '$testPackageLibPath/e.dart',
      package: Version.parse('2.7.0'),
      override: null,
    );

    await _assertLanguageVersionCurrent('$workspaceRootPath/aaa/lib/a.dart');
    await _assertLanguageVersionCurrent('$workspaceRootPath/aaa/lib/b.dart');
    await _assertLanguageVersionCurrent('$workspaceRootPath/aaa/lib/c.dart');
  }

  test_scope_lookup2() async {
    await assertNoErrorsInCode(r'''
int foo;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup2('foo').getter,
      findElement.topGet('foo'),
    );
    assertElement(
      scope.lookup2('foo').setter,
      findElement.topSet('foo'),
    );
  }

  test_scope_lookup2_implicitCoreImport() async {
    await assertNoErrorsInCode('');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup2('int').getter,
      intElement,
    );
  }

  test_scope_lookup2_notFound() async {
    await assertNoErrorsInCode('');

    var scope = result.libraryElement.scope;

    assertElementNull(
      scope.lookup2('noSuchGetter').getter,
    );

    assertElementNull(
      scope.lookup2('noSuchSetter').setter,
    );
  }

  test_scope_lookup2_prefersLocal() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math';

int sin() => 3;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup2('sin').getter,
      findElement.topFunction('sin'),
    );

    assertElement(
      scope.lookup2('cos').getter,
      findElement.importFind('dart:math').topFunction('cos'),
    );
  }

  test_scope_lookup2_prefix() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup2('math').getter,
      findElement.prefix('math'),
    );
  }

  test_scope_lookup2_respectsCombinator_hide() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' hide sin;
''');

    var scope = result.libraryElement.scope;

    assertElementNull(
      scope.lookup2('sin').getter,
    );

    var mathFind = findElement.importFind('dart:math');
    assertElement(
      scope.lookup2('cos').getter,
      mathFind.topFunction('cos'),
    );
    assertElement(
      scope.lookup2('tan').getter,
      mathFind.topFunction('tan'),
    );
  }

  test_scope_lookup2_respectsCombinator_show() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' show sin;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      scope.lookup2('sin').getter,
      findElement.importFind('dart:math').topFunction('sin'),
    );

    assertElementNull(
      scope.lookup2('cos').getter,
    );
  }

  test_scope_lookup_implicitCoreImport() async {
    await assertNoErrorsInCode('');

    var scope = result.libraryElement.scope;

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'int', setter: false),
      intElement,
    );
  }

  test_scope_lookup_lookup() async {
    await assertNoErrorsInCode(r'''
int foo;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: false),
      findElement.topGet('foo'),
    );
    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: true),
      findElement.topSet('foo'),
    );
  }

  test_scope_lookup_notFound() async {
    await assertNoErrorsInCode('');

    var scope = result.libraryElement.scope;

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'noSuchGetter', setter: false),
    );

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'noSuchSetter', setter: true),
    );
  }

  test_scope_lookup_prefersLocal() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math';

int sin() => 3;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'sin', setter: false),
      findElement.topFunction('sin'),
    );

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'cos', setter: false),
      findElement.importFind('dart:math').topFunction('cos'),
    );
  }

  test_scope_lookup_prefix() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'math', setter: false),
      findElement.prefix('math'),
    );
  }

  test_scope_lookup_respectsCombinator_hide() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' hide sin;
''');

    var scope = result.libraryElement.scope;

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'sin', setter: false),
    );

    var mathFind = findElement.importFind('dart:math');
    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'cos', setter: false),
      mathFind.topFunction('cos'),
    );
    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'tan', setter: false),
      mathFind.topFunction('tan'),
    );
  }

  test_scope_lookup_respectsCombinator_show() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' show sin;
''');

    var scope = result.libraryElement.scope;

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'sin', setter: false),
      findElement.importFind('dart:math').topFunction('sin'),
    );

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'cos', setter: false),
    );
  }

  Future<void> _assertLanguageVersion({
    @required String path,
    @required Version package,
    @required Version override,
  }) async {
    path = convertPath(path);
    var session = contextFor(path).currentSession;
    var file = session.getFile(path);
    var element = await session.getLibraryByUri('${file.uri}');
    expect(element.languageVersion.package, package);
    expect(element.languageVersion.override, override);
  }

  Future<void> _assertLanguageVersionCurrent(String path) async {
    await _assertLanguageVersion(
      path: path,
      package: ExperimentStatus.currentVersion,
      override: null,
    );
  }
}
