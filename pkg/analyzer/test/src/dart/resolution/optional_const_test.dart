// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionalConstDriverResolutionTest);
  });
}

@reflectiveTest
class OptionalConstDriverResolutionTest extends DriverResolutionTest
    with OptionalConstMixin {}

mixin OptionalConstMixin implements ResolutionTest {
  Map<String, LibraryElement> libraries = {};

  LibraryElement get libraryA => libraries['package:test/a.dart'];

  test_instantiateToBounds_notPrefixed_named() async {
    var creation = await _resolveImplicitConst('B.named()');
    assertInstanceCreation(
      creation,
      libraryA.getType('B'),
      'B<num>',
      constructorName: 'named',
      expectedConstructorMember: true,
    );
  }

  test_instantiateToBounds_notPrefixed_unnamed() async {
    var creation = await _resolveImplicitConst('B()');
    assertInstanceCreation(
      creation,
      libraryA.getType('B'),
      'B<num>',
      expectedConstructorMember: true,
    );
  }

  test_instantiateToBounds_prefixed_named() async {
    var creation = await _resolveImplicitConst('p.B.named()', prefix: 'p');
    assertInstanceCreation(
      creation,
      libraryA.getType('B'),
      'B<num>',
      constructorName: 'named',
      expectedConstructorMember: true,
    );
  }

  test_instantiateToBounds_prefixed_unnamed() async {
    var creation = await _resolveImplicitConst('p.B()', prefix: 'p');
    assertInstanceCreation(
      creation,
      libraryA.getType('B'),
      'B<num>',
      expectedConstructorMember: true,
    );
  }

  test_notPrefixed_named() async {
    var creation = await _resolveImplicitConst('A.named()');
    assertInstanceCreation(
      creation,
      libraryA.getType('A'),
      'A',
      constructorName: 'named',
    );
  }

  test_notPrefixed_unnamed() async {
    var creation = await _resolveImplicitConst('A()');
    assertInstanceCreation(
      creation,
      libraryA.getType('A'),
      'A',
    );
  }

  test_prefixed_named() async {
    var creation = await _resolveImplicitConst('p.A.named()', prefix: 'p');
    // Note, that we don't resynthesize the import prefix.
    assertInstanceCreation(
      creation,
      libraryA.getType('A'),
      'A',
      constructorName: 'named',
    );
  }

  test_prefixed_unnamed() async {
    var creation = await _resolveImplicitConst('p.A()', prefix: 'p');
    // Note, that we don't resynthesize the import prefix.
    assertInstanceCreation(
      creation,
      libraryA.getType('A'),
      'A',
    );
  }

  void _fillLibraries([LibraryElement library]) {
    library ??= result.unit.declaredElement.library;
    var uriStr = library.source.uri.toString();
    if (!libraries.containsKey(uriStr)) {
      libraries[uriStr] = library;
      library.importedLibraries.forEach(_fillLibraries);
    }
  }

  Future<InstanceCreationExpression> _resolveImplicitConst(String expr,
      {String prefix}) async {
    newFile('/test/lib/a.dart', content: '''
class A {
  const A();
  const A.named();
}
class B<T extends num> {
  const B();
  const B.named();
}
''');

    if (prefix != null) {
      newFile('/test/lib/b.dart', content: '''
import 'a.dart' as $prefix;
const a = $expr;
''');
    } else {
      newFile('/test/lib/b.dart', content: '''
import 'a.dart';
const a = $expr;
''');
    }

    addTestFile(r'''
import 'b.dart';
var v = a;
''');
    await resolveTestFile();
    _fillLibraries();

    PropertyAccessorElement vg = findNode.simple('a;').staticElement;
    var v = vg.variable as ConstVariableElement;

    InstanceCreationExpression creation = v.constantInitializer;
    expect(creation.keyword.keyword, Keyword.CONST);

    return creation;
  }
}
