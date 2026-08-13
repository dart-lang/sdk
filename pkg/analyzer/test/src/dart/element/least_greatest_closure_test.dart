// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GreatestClosureTest);
  });
}

@reflectiveTest
class GreatestClosureTest extends AbstractTypeSystemTest {
  test_contravariant() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _check(
        scope.parseType('void Function(T)'),
        typeParameters: [T],
        greatest: 'void Function(Never)',
        least: 'void Function(Object?)',
      );

      _check(
        scope.parseType('void Function(T) Function()'),
        typeParameters: [T],
        greatest: 'void Function(Never) Function()',
        least: 'void Function(Object?) Function()',
      );
    });
  }

  test_covariant() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      _check(
        scope.parseTypeParameterType('T'),
        typeParameters: [T],
        greatest: 'Object?',
        least: 'Never',
      );
      _check(
        scope.parseTypeParameterType('T?'),
        typeParameters: [T],
        greatest: 'Object?',
        least: 'Never?',
      );

      _check(
        scope.parseType('List<T>'),
        typeParameters: [T],
        greatest: 'List<Object?>',
        least: 'List<Never>',
      );

      _check(
        scope.parseType('void Function(int Function(T))'),
        typeParameters: [T],
        greatest: 'void Function(int Function(Object?))',
        least: 'void Function(int Function(Never))',
      );
    });
  }

  test_function() {
    // void Function<U extends T>()
    withTypeParameterScope('T', (scope) {
      _check(
        scope.parseType('void Function<U extends T>()'),
        typeParameters: [scope.typeParameter('T')],
        greatest: 'Function',
        least: 'Never',
      );
    });
  }

  test_unrelated() {
    withTypeParameterScope('T, U', (scope) {
      void checkUnchanged(TypeImpl type, String expected) {
        var T = scope.typeParameter('T');
        _check(type, typeParameters: [T], greatest: expected, least: expected);
      }

      checkUnchanged(parseType('int'), 'int');
      checkUnchanged(parseType('int?'), 'int?');

      checkUnchanged(parseType('List<int>'), 'List<int>');
      checkUnchanged(parseType('List<int>?'), 'List<int>?');

      checkUnchanged(parseType('Object'), 'Object');
      checkUnchanged(parseType('Object?'), 'Object?');

      checkUnchanged(parseType('Never'), 'Never');
      checkUnchanged(parseType('Never?'), 'Never?');

      checkUnchanged(parseType('dynamic'), 'dynamic');

      checkUnchanged(parseType('String Function(int)'), 'String Function(int)');

      checkUnchanged(scope.parseType('U'), 'U');
    });
  }

  void _check(
    TypeImpl type, {
    required List<TypeParameterElementImpl> typeParameters,
    required String greatest,
    required String least,
  }) {
    var greatestResult = typeSystem.greatestClosure(type, typeParameters);
    expect(greatestResult.getDisplayString(), greatest);

    var leastResult = typeSystem.leastClosure(type, typeParameters);
    expect(leastResult.getDisplayString(), least);
  }
}
