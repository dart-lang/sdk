// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/non_covariant_type_parameter_position.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonCovariantTypeParameterPositionVisitorTest);
  });
}

@reflectiveTest
class NonCovariantTypeParameterPositionVisitorTest
    extends AbstractTypeSystemTest {
  void expectNonCovariant(DartType type, TypeParameterElementImpl T) {
    var actual = _compute(type, T);
    expect(actual, isTrue);
  }

  void expectNotNonCovariant(DartType type, TypeParameterElementImpl T) {
    var actual = _compute(type, T);
    expect(actual, isFalse);
  }

  test_dynamic() {
    withTypeParameterScope('T', (scope) {
      expectNotNonCovariant(parseType('dynamic'), scope.typeParameter('T'));
    });
  }

  test_function() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      expectNotNonCovariant(scope.parseType('T Function()'), T);

      // void Function(T)
      expectNonCovariant(scope.parseType('void Function([T])'), T);

      // void Function(T) Function()
      expectNonCovariant(scope.parseType('void Function([T]) Function()'), T);

      // void Function(void Function(T))
      expectNotNonCovariant(
        scope.parseType('void Function([void Function([T])])'),
        T,
      );

      // T Function(T)
      expectNonCovariant(scope.parseType('T Function([T])'), T);

      // void Function<U extends T>()
      expectNonCovariant(scope.parseType('void Function<U extends T>()'), T);
    });

    // Not the `T` for which we check.
    withTypeParameterScope('T', (scope1) {
      var T = scope1.typeParameter('T');
      scope1.withTypeParameterScope('T', (scope2) {
        expectNotNonCovariant(scope2.parseType('void Function([T])'), T);
      });
    });
  }

  test_interface() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      expectNotNonCovariant(parseType('int'), T);
      expectNotNonCovariant(scope.parseType('List<T>'), T);
      expectNonCovariant(scope.parseType('List<void Function([T])>'), T);
    });
  }

  test_invalidType() {
    withTypeParameterScope('T', (scope) {
      expectNotNonCovariant(parseType('InvalidType'), scope.typeParameter('T'));
    });
  }

  test_never() {
    withTypeParameterScope('T', (scope) {
      expectNotNonCovariant(parseType('Never'), scope.typeParameter('T'));
    });
  }

  test_record() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      expectNotNonCovariant(scope.parseType('(T,)'), T);
      expectNonCovariant(scope.parseType('(void Function([T]),)'), T);
      expectNonCovariant(scope.parseType('(T, void Function([T]))'), T);
      expectNotNonCovariant(scope.parseType('({T a})'), T);
      expectNonCovariant(scope.parseType('({void Function([T]) a})'), T);
    });
  }

  test_typeParameter() {
    withTypeParameterScope('T', (scope1) {
      var T = scope1.typeParameter('T');
      scope1.withTypeParameterScope('U', (scope2) {
        expectNotNonCovariant(scope2.parseType('U'), T);
      });
    });

    withTypeParameterScope('T', (scope) {
      expectNotNonCovariant(scope.parseType('T'), scope.typeParameter('T'));
    });
  }

  test_void() {
    withTypeParameterScope('T', (scope) {
      expectNotNonCovariant(parseType('void'), scope.typeParameter('T'));
    });
  }

  bool _compute(DartType type, TypeParameterElementImpl T) {
    return type.accept(
      NonCovariantTypeParameterPositionVisitor([
        T,
      ], initialVariance: Variance.covariant),
    );
  }
}
