// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceTopBottomTest);
  });
}

@reflectiveTest
class ReplaceTopBottomTest extends AbstractTypeSystemTest {
  test_contravariant_bottom() {
    // Not contravariant.
    _check(parseType('Never'), 'Never');

    _check(parseFunctionType('int Function(Never)'), 'int Function(Object?)');

    withTypeParameterScope('T extends Never', (scope) {
      _check(scope.parseType('int Function(T)'), 'int Function(Object?)');
    });
  }

  test_notContravariant_covariant_top() {
    _check(parseType('Object?'), 'Never');
    _check(parseType('dynamic'), 'Never');
    _check(parseType('void'), 'Never');

    _check(parseType('List<Object?>'), 'List<Never>');
    _check(parseType('List<dynamic>'), 'List<Never>');
    _check(parseType('List<void>'), 'List<Never>');

    _check(parseType('FutureOr<Object?>'), 'Never');
    _check(parseType('FutureOr<dynamic>'), 'Never');
    _check(parseType('FutureOr<void>'), 'Never');
    _check(parseType('FutureOr<FutureOr<void>>'), 'Never');

    _check(
      parseType('int Function(int Function(Object?))'),
      'int Function(int Function(Never))',
    );

    _check(parseType('int'), 'int');
    _check(parseType('int?'), 'int?');

    _check(parseType('List<int>'), 'List<int>');
    _check(parseType('List<int?>'), 'List<int?>');
    _check(parseType('List<int>?'), 'List<int>?');
    _check(parseType('List<int?>?'), 'List<int?>?');
  }

  test_notContravariant_invariant() {
    // typedef F<T> = T Function(T);
    buildTestLibrary(
      typeAliases: [TypeAliasSpec('typedef F<inout T> = T Function(T)')],
    );

    _check(parseType('F<dynamic>'), 'Never Function(Never)');
  }

  void _check(TypeImpl type, String expectedStr) {
    var result = typeSystem.replaceTopAndBottom(type);
    expect('$result', expectedStr);
  }
}
