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
  test_scope_lookup() async {
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
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: false),
      importFind.topGet('foo'),
    );

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: true),
      importFind.topSet('foo'),
    );
  }

  test_scope_lookup2() async {
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
      scope.lookup2('foo').getter,
      importFind.topGet('foo'),
    );

    assertElement(
      scope.lookup2('foo').setter,
      importFind.topSet('foo'),
    );
  }

  test_scope_lookup2_ambiguous_notSdk_both() async {
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
      scope.lookup2('foo').getter,
      [
        aImport.topGet('foo'),
        bImport.topGet('foo'),
      ],
    );

    _assertMultiplyDefinedElement(
      scope.lookup2('foo').setter,
      [
        aImport.topSet('foo'),
        bImport.topSet('foo'),
      ],
    );
  }

  test_scope_lookup2_ambiguous_notSdk_first() async {
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
      scope.lookup2('pi').getter,
      aImport.topGet('pi'),
    );
  }

  test_scope_lookup2_ambiguous_notSdk_second() async {
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
      scope.lookup2('pi').getter,
      aImport.topGet('pi'),
    );
  }

  test_scope_lookup2_ambiguous_same() async {
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
      scope.lookup2('foo').getter,
      importFind.topGet('foo'),
    );

    assertElement(
      scope.lookup2('foo').setter,
      importFind.topSet('foo'),
    );
  }

  test_scope_lookup2_differentPrefix() async {
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
      scope.lookup2('foo').getter,
      importFind.topGet('foo'),
    );
    assertElement(
      scope.lookup2('foo').setter,
      importFind.topSet('foo'),
    );

    assertElementNull(
      scope.lookup2('bar').getter,
    );
    assertElementNull(
      scope.lookup2('bar').setter,
    );
  }

  test_scope_lookup2_notFound() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math;
''');

    var scope = findElement.prefix('math').scope;

    assertElementNull(
      scope.lookup2('noSuchGetter').getter,
    );

    assertElementNull(
      scope.lookup2('noSuchSetter').setter,
    );
  }

  test_scope_lookup2_respectsCombinator_hide() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math hide sin;
''');

    var scope = findElement.prefix('math').scope;
    var mathFind = findElement.importFind('dart:math');

    assertElementNull(
      scope.lookup2('sin').getter,
    );

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
import 'dart:math' as math show sin;
''');

    var scope = findElement.prefix('math').scope;
    var mathFind = findElement.importFind('dart:math');

    assertElement(
      scope.lookup2('sin').getter,
      mathFind.topFunction('sin'),
    );

    assertElementNull(
      scope.lookup2('cos').getter,
    );
  }

  test_scope_lookup_ambiguous_notSdk_both() async {
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
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: false),
      [
        aImport.topGet('foo'),
        bImport.topGet('foo'),
      ],
    );

    _assertMultiplyDefinedElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: true),
      [
        aImport.topSet('foo'),
        bImport.topSet('foo'),
      ],
    );
  }

  test_scope_lookup_ambiguous_notSdk_first() async {
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
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'pi', setter: false),
      aImport.topGet('pi'),
    );
  }

  test_scope_lookup_ambiguous_notSdk_second() async {
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
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'pi', setter: false),
      aImport.topGet('pi'),
    );
  }

  test_scope_lookup_ambiguous_same() async {
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
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: false),
      importFind.topGet('foo'),
    );

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: true),
      importFind.topSet('foo'),
    );
  }

  test_scope_lookup_differentPrefix() async {
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
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: false),
      importFind.topGet('foo'),
    );
    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'foo', setter: true),
      importFind.topSet('foo'),
    );

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'bar', setter: false),
    );
    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'bar', setter: true),
    );
  }

  test_scope_lookup_notFound() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math;
''');

    var scope = findElement.prefix('math').scope;

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'noSuchGetter', setter: false),
    );

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'noSuchSetter', setter: true),
    );
  }

  test_scope_lookup_respectsCombinator_hide() async {
    await assertNoErrorsInCode(r'''
// ignore:unused_import
import 'dart:math' as math hide sin;
''');

    var scope = findElement.prefix('math').scope;
    var mathFind = findElement.importFind('dart:math');

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'sin', setter: false),
    );

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
import 'dart:math' as math show sin;
''');

    var scope = findElement.prefix('math').scope;
    var mathFind = findElement.importFind('dart:math');

    assertElement(
      // ignore: deprecated_member_use_from_same_package
      scope.lookup(id: 'sin', setter: false),
      mathFind.topFunction('sin'),
    );

    assertElementNull(
      // ignore: deprecated_member_use_from_same_package
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
