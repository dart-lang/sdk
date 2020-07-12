// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrefixElementTest);
  });
}

@reflectiveTest
class PrefixElementTest extends DriverResolutionTest {
  test_scope() async {
    newFile('/test/lib/a.dart', content: r'''
var foo = 0;
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart' as prefix;
''');

    var scope = findElement.prefix('prefix').scope;
    var importFind = findElement.importFind('package:test/a.dart');

    assertElement(
      scope.lookup(id: 'foo', setter: false),
      importFind.topGet('foo'),
    );

    assertElement(
      scope.lookup(id: 'foo', setter: true),
      importFind.topSet('foo'),
    );
  }

  test_scope_ambiguous_notSdk_both() async {
    newFile('/test/lib/a.dart', content: r'''
var foo = 0;
''');

    newFile('/test/lib/b.dart', content: r'''
var foo = 1.2;
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart' as prefix;

// ignore:unused_import
import 'b.dart' as prefix;
''');

    var scope = findElement.prefix('prefix').scope;

    var aImport = findElement.importFind('package:test/a.dart');
    var bImport = findElement.importFind('package:test/b.dart');

    _assertMultiplyDefinedElement(
      scope.lookup(id: 'foo', setter: false),
      [
        aImport.topGet('foo'),
        bImport.topGet('foo'),
      ],
    );

    _assertMultiplyDefinedElement(
      scope.lookup(id: 'foo', setter: true),
      [
        aImport.topSet('foo'),
        bImport.topSet('foo'),
      ],
    );
  }

  test_scope_ambiguous_notSdk_first() async {
    newFile('/test/lib/a.dart', content: r'''
var pi = 4;
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart' as prefix;

// ignore:unused_import
import 'dart:math' as prefix;
''');

    var scope = findElement.prefix('prefix').scope;
    var aImport = findElement.importFind('package:test/a.dart');

    assertElement(
      scope.lookup(id: 'pi', setter: false),
      aImport.topGet('pi'),
    );
  }

  test_scope_ambiguous_notSdk_second() async {
    newFile('/test/lib/a.dart', content: r'''
var pi = 4;
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as prefix;

// ignore:unused_import
import 'a.dart' as prefix;
''');

    var scope = findElement.prefix('prefix').scope;
    var aImport = findElement.importFind('package:test/a.dart');

    assertElement(
      scope.lookup(id: 'pi', setter: false),
      aImport.topGet('pi'),
    );
  }

  test_scope_ambiguous_same() async {
    newFile('/test/lib/a.dart', content: r'''
var foo = 0;
''');

    newFile('/test/lib/b.dart', content: r'''
export 'a.dart';
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart' as prefix;

// ignore:unused_import
import 'b.dart' as prefix;
''');

    var scope = findElement.prefix('prefix').scope;
    var importFind = findElement.importFind('package:test/a.dart');

    assertElement(
      scope.lookup(id: 'foo', setter: false),
      importFind.topGet('foo'),
    );

    assertElement(
      scope.lookup(id: 'foo', setter: true),
      importFind.topSet('foo'),
    );
  }

  test_scope_differentPrefix() async {
    newFile('/test/lib/a.dart', content: r'''
var foo = 0;
''');

    newFile('/test/lib/b.dart', content: r'''
var bar = 0;
''');

    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'a.dart' as prefix;

// ignore:unused_import
import 'b.dart' as prefix2;
''');

    var scope = findElement.prefix('prefix').scope;
    var importFind = findElement.importFind('package:test/a.dart');

    assertElement(
      scope.lookup(id: 'foo', setter: false),
      importFind.topGet('foo'),
    );
    assertElement(
      scope.lookup(id: 'foo', setter: true),
      importFind.topSet('foo'),
    );

    assertElementNull(
      scope.lookup(id: 'bar', setter: false),
    );
    assertElementNull(
      scope.lookup(id: 'bar', setter: true),
    );
  }

  test_scope_notFound() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math;
''');

    var scope = findElement.prefix('math').scope;

    assertElementNull(
      scope.lookup(id: 'noSuchGetter', setter: false),
    );

    assertElementNull(
      scope.lookup(id: 'noSuchSetter', setter: true),
    );
  }

  test_scope_respectsCombinator_hide() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math hide sin;
''');

    var scope = findElement.prefix('math').scope;
    var mathFind = findElement.importFind('dart:math');

    assertElementNull(
      scope.lookup(id: 'sin', setter: false),
    );

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
import 'dart:math' as math show sin;
''');

    var scope = findElement.prefix('math').scope;
    var mathFind = findElement.importFind('dart:math');

    assertElement(
      scope.lookup(id: 'sin', setter: false),
      mathFind.topFunction('sin'),
    );

    assertElementNull(
      scope.lookup(id: 'cos', setter: false),
    );
  }

  void _assertMultiplyDefinedElement(
    MultiplyDefinedElementImpl element,
    List<Element> expected,
  ) {
    expect(element.conflictingElements, unorderedEquals(expected));
  }
}
