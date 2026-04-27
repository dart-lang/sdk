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
  });
}

@reflectiveTest
class FlattenTypeTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _check(parseType('dynamic'), 'dynamic');
  }

  test_interfaceType() {
    _check(parseType('int'), 'int');
    _check(parseType('int?'), 'int?');
  }

  test_interfaceType_none_hasFutureType() {
    _check(parseType('Future<int>'), 'int');
    _check(parseType('Future<int?>'), 'int?');

    _check(parseType('Future<int>?'), 'int?');
    _check(parseType('Future<int?>?'), 'int?');

    _check(parseType('FutureOr<int>'), 'int');
    _check(parseType('FutureOr<int?>'), 'int?');

    _check(parseType('FutureOr<int>?'), 'int?');
    _check(parseType('FutureOr<int?>?'), 'int?');

    _check(parseType('FutureOr<Future<int>>'), 'Future<int>');
    _check(parseType('FutureOr<Future<int?>>'), 'Future<int?>');

    _check(parseType('FutureOr<Future<int>>?'), 'Future<int>?');
    _check(parseType('FutureOr<Future<int?>>?'), 'Future<int?>?');
  }

  test_interfaceType_question() {
    _check(parseType('Future<int>?'), 'int?');
    _check(parseType('Future<int?>?'), 'int?');
  }

  test_typeParameterType_none() {
    // T extends Future<int>
    withTypeParameterScope('T extends Future<int>', (scope) {
      _check(scope.parseType('T'), 'int');
    });

    // T extends FutureOr<int>
    withTypeParameterScope('T extends FutureOr<int>', (scope) {
      _check(scope.parseType('T'), 'int');
    });

    // T & Future<int>
    withTypeParameterScope('T', (scope) {
      _check(scope.parseType('T & Future<int>'), 'int');
    });

    // T & FutureOr<int>
    withTypeParameterScope('T', (scope) {
      _check(scope.parseType('T & FutureOr<int>'), 'int');
    });

    // T extends int
    withTypeParameterScope('T extends int', (scope) {
      _check(scope.parseType('T'), 'T');
    });

    // T & int
    withTypeParameterScope('T', (scope) {
      _check(scope.parseType('T & int'), 'T');
    });
  }

  test_typeParameterType_question() {
    // T extends Future<int>
    withTypeParameterScope('T extends Future<int>', (scope) {
      _check(scope.parseType('T?'), 'int?');
    });

    // T extends FutureOr<int>
    withTypeParameterScope('T extends FutureOr<int>', (scope) {
      _check(scope.parseType('T?'), 'int?');
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
  test_dynamic() {
    _check(parseType('dynamic'), null);
  }

  test_functionType() {
    _check(parseType('void Function()'), null);
  }

  test_implements_Future() {
    buildTestLibrary(
      imports: ['dart:core', 'dart:async'],
      classes: [ClassSpec('class A implements Future<int>')],
    );
    _check(parseType('A'), 'Future<int>');
    _check(parseType('A?'), null);
  }

  test_interfaceType() {
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

  test_typeParameterType_none() {
    // T extends Future<int>
    withTypeParameterScope('T extends Future<int>', (scope) {
      _check(scope.parseType('T'), 'Future<int>');
    });

    // T extends FutureOr<int>
    withTypeParameterScope('T extends FutureOr<int>', (scope) {
      _check(scope.parseType('T'), 'FutureOr<int>');
    });

    // T & Future<int>
    withTypeParameterScope('T', (scope) {
      _check(scope.parseType('T & Future<int>'), 'Future<int>');
    });

    // T & FutureOr<int>
    withTypeParameterScope('T', (scope) {
      _check(scope.parseType('T & FutureOr<int>'), 'FutureOr<int>');
    });

    // T extends int
    withTypeParameterScope('T extends int', (scope) {
      _check(scope.parseType('T'), null);
    });

    // T & int
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
