// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlattenTypeTest);
    defineReflectiveTests(FutureTypeTest);
    defineReflectiveTests(UnionFreeTypeTest);
  });
}

@reflectiveTest
class FlattenTypeTest extends AbstractTypeSystemTest {
  test_interfaceType_conflictingFutureInterfaces() {
    // Repeated generic elements in the hierarchy should not trip the
    // recursion guard, and traversal order still determines the future type.
    buildTestLibrary(
      imports: ['dart:core', 'dart:async'],
      classes: [
        ClassSpec('abstract class Derived<T> implements Future<T>'),
        ClassSpec(
          'abstract class A extends Derived<int> implements Derived<num>',
        ),
        ClassSpec('abstract class A1 implements Future<int>'),
        ClassSpec('abstract class A2 extends A1 implements Future<num>'),
        ClassSpec('abstract class B1 implements Future<num>'),
        ClassSpec('abstract class B2 extends B1 implements Future<int>'),
      ],
    );
    _check(parseType('A'), 'int');
    _check(parseType('A2'), 'int');
    _check(parseType('B2'), 'num');
  }

  test_interfaceType_conflictingFutureInterfaces_disjoint() {
    // Neither 'String' nor 'int' is more specific than the other, meaning
    // they are completely disjoint. Conflict resolution handles this
    // deterministically via parent-first interface traversal order.
    buildTestLibrary(
      imports: ['dart:core', 'dart:async'],
      classes: [
        ClassSpec('abstract class A1 implements Future<int>'),
        ClassSpec('abstract class A2 extends A1 implements Future<String>'),
        ClassSpec('abstract class B1 implements Future<String>'),
        ClassSpec('abstract class B2 extends B1 implements Future<int>'),
      ],
    );
    _check(parseType('A2'), 'int');
    _check(parseType('B2'), 'String');
  }

  test_interfaceType_implementsFuture() {
    buildTestLibrary(
      imports: ['dart:core', 'dart:async'],
      classes: [ClassSpec('abstract class Derived<T> implements Future<T>')],
    );
    _check(parseType('Derived<dynamic>'), 'dynamic');
    _check(parseType('Derived<int>'), 'int');
    _check(parseType('Derived<Derived>'), 'Derived');
    _check(parseType('Derived<Derived<int>>'), 'Derived<int>');
  }

  test_interfaceType_recursiveHierarchy() {
    // Even though there is a loop in the class hierarchy,
    // flatten() should terminate successfully.
    buildTestLibrary(
      classes: [ClassSpec('class A extends B'), ClassSpec('class B extends A')],
    );
    _check(parseType('A'), 'A');
    _check(parseType('B'), 'B');
  }

  test_simpleTypes() {
    _check(parseType('dynamic'), 'dynamic');
    _check(parseType('int'), 'int');
    _check(parseType('int?'), 'int?');

    _check(parseType('Future<int>'), 'int');
    _check(parseType('Future<int?>'), 'int?');
    _check(parseType('Future<int>?'), 'int?');
    _check(parseType('Future<int?>?'), 'int?');

    _check(parseType('FutureOr<int>'), 'int');
    _check(parseType('FutureOr<int?>'), 'int?');
    _check(parseType('FutureOr<int>?'), 'int?');
    _check(parseType('FutureOr<int?>?'), 'int?');

    _check(parseType('Future<Future<int>>'), 'Future<int>');
    _check(parseType('Future<Future<int>?>'), 'Future<int>?');
    _check(parseType('FutureOr<Future<int>>'), 'Future<int>');
    _check(parseType('FutureOr<Future<int?>>'), 'Future<int?>');
    _check(parseType('FutureOr<Future<int>>?'), 'Future<int>?');
    _check(parseType('FutureOr<Future<int?>>?'), 'Future<int?>?');
  }

  test_typeParameter() {
    // Bounds with future type are flattened.
    withTypeParameterScope('T extends Future<int>', (scope) {
      _check(scope.parseType('T'), 'int');
    });
    withTypeParameterScope('T extends FutureOr<int>', (scope) {
      _check(scope.parseType('T'), 'int');
    });

    // Nullable type parameters preserve nullability after flattening.
    withTypeParameterScope('T extends Future<int>', (scope) {
      _check(scope.parseType('T?'), 'int?');
    });
    withTypeParameterScope('T extends FutureOr<int>', (scope) {
      _check(scope.parseType('T?'), 'int?');
    });

    // Promoted bounds are used when they have a future type.
    withTypeParameterScope('T', (scope) {
      _check(scope.parseType('T & Future<int>'), 'int');
      _check(scope.parseType('T & FutureOr<int>'), 'int');
    });

    // Without a future type, the type parameter itself is unchanged.
    withTypeParameterScope('T extends int', (scope) {
      _check(scope.parseType('T'), 'T');
    });
    withTypeParameterScope('T', (scope) {
      _check(scope.parseType('T & int'), 'T');
    });
  }

  test_unknownInferredType() {
    var type = UnknownInferredType.instance;
    expect(typeSystem.flatten(type), same(type));
  }

  void _check(TypeImpl T, String expected) {
    var result = typeSystem.flatten(T);
    expect(result.getDisplayString(), expected);
  }
}

@reflectiveTest
class FutureTypeTest extends AbstractTypeSystemTest {
  test_interfaceType_implementsFuture() {
    buildTestLibrary(
      imports: ['dart:core', 'dart:async'],
      classes: [ClassSpec('class A implements Future<int>')],
    );
    _check(parseType('A'), 'Future<int>');
    _check(parseType('A?'), null);
  }

  test_simpleTypes() {
    _check(parseType('dynamic'), null);
    _check(parseType('void Function()'), null);

    _check(parseType('Object'), null);
    _check(parseType('Object?'), null);

    _check(parseType('int'), null);
    _check(parseType('int?'), null);

    _check(parseType('List<int>'), null);
    _check(parseType('List<int?>'), null);

    _check(parseType('List<int>?'), null);
    _check(parseType('List<int?>?'), null);

    _check(parseType('Future<int>'), 'Future<int>');
    _check(parseType('Future<int?>'), 'Future<int?>');

    _check(parseType('Future<int>?'), 'Future<int>?');
    _check(parseType('Future<int?>?'), 'Future<int?>?');

    _check(parseType('FutureOr<int>'), 'FutureOr<int>');
    _check(parseType('FutureOr<int?>'), 'FutureOr<int?>');

    _check(parseType('FutureOr<int>?'), 'FutureOr<int>?');
    _check(parseType('FutureOr<int?>?'), 'FutureOr<int?>?');

    _check(parseType('Future<Future<int>>'), 'Future<Future<int>>');
    _check(parseType('Future<FutureOr<int>>'), 'Future<FutureOr<int>>');
    _check(parseType('FutureOr<Future<int>>'), 'FutureOr<Future<int>>');
    _check(parseType('FutureOr<FutureOr<int>>'), 'FutureOr<FutureOr<int>>');
  }

  test_typeParameter() {
    // Bounds with future type are returned as the future type.
    withTypeParameterScope('T extends Future<int>', (scope) {
      _check(scope.parseType('T'), 'Future<int>');
    });
    withTypeParameterScope('T extends FutureOr<int>', (scope) {
      _check(scope.parseType('T'), 'FutureOr<int>');
    });

    // Promoted bounds are used when they have a future type.
    withTypeParameterScope('T', (scope) {
      _check(scope.parseType('T & Future<int>'), 'Future<int>');
      _check(scope.parseType('T & FutureOr<int>'), 'FutureOr<int>');
    });

    // Without a future type, there is no future type result.
    withTypeParameterScope('T extends int', (scope) {
      _check(scope.parseType('T'), null);
    });
    withTypeParameterScope('T', (scope) {
      _check(scope.parseType('T & int'), null);
    });
  }

  test_unknownInferredType() {
    _check(UnknownInferredType.instance, null);
  }

  void _check(TypeImpl T, String? expected) {
    var result = typeSystem.futureType(T);
    if (result == null) {
      expect(expected, isNull);
    } else {
      expect(result.getDisplayString(), expected);
    }
  }
}

@reflectiveTest
class UnionFreeTypeTest extends AbstractTypeSystemTest {
  test_simpleTypes() {
    _check(parseType('Future<int>?'), 'Future<int>');
    _check(parseType('FutureOr<int>'), 'int');
    _check(parseType('FutureOr<FutureOr<int?>?>?'), 'int');
    _check(parseType('int?'), 'int');
    _check(parseType('int'), 'int');
  }

  test_unknownInferredType() {
    var type = UnknownInferredType.instance;
    expect(typeSystem.unionFreeType(type), same(type));
  }

  void _check(TypeImpl T, String expected) {
    var result = typeSystem.unionFreeType(T);
    expect(result.getDisplayString(), expected);
  }
}
