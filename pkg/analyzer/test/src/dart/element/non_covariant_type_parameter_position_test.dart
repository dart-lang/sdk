// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/non_covariant_type_parameter_position.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
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
  late final T_element = typeParameter('T');
  late final T = typeParameterTypeNone(T_element);

  FunctionType get _contravariantT {
    return functionTypeNone(
      returnType: voidNone,
      parameters: [
        positionalParameter(type: T),
      ],
    );
  }

  void expectNonCovariant(DartType type) {
    final actual = _compute(type);
    expect(actual, isTrue);
  }

  void expectNotNonCovariant(DartType type) {
    final actual = _compute(type);
    expect(actual, isFalse);
  }

  test_dynamic() {
    expectNotNonCovariant(dynamicType);
  }

  test_function() {
    expectNotNonCovariant(
      functionTypeNone(
        returnType: T,
      ),
    );

    // void Function(T)
    expectNonCovariant(_contravariantT);

    // void Function(T) Function()
    expectNonCovariant(
      functionTypeNone(
        returnType: _contravariantT,
      ),
    );

    // void Function(void Function(T))
    expectNotNonCovariant(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          positionalParameter(type: _contravariantT),
        ],
      ),
    );

    // T Function(T)
    expectNonCovariant(
      functionTypeNone(
        returnType: T,
        parameters: [
          positionalParameter(type: T),
        ],
      ),
    );

    // Not the `T` for which we check.
    final T2 = typeParameter('T');
    expectNotNonCovariant(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          positionalParameter(
            type: typeParameterTypeNone(T2),
          ),
        ],
      ),
    );

    // void Function<U extends T>()
    expectNonCovariant(
      functionTypeNone(
        typeFormals: [
          typeParameter('U', bound: T),
        ],
        returnType: voidNone,
      ),
    );
  }

  test_interface() {
    expectNotNonCovariant(intNone);
    expectNotNonCovariant(listNone(T));
    expectNonCovariant(listNone(_contravariantT));
  }

  test_invalidType() {
    expectNotNonCovariant(invalidType);
  }

  test_never() {
    expectNotNonCovariant(neverNone);
  }

  test_record() {
    expectNotNonCovariant(
      recordTypeNone(
        positionalTypes: [T],
      ),
    );

    expectNonCovariant(
      recordTypeNone(
        positionalTypes: [_contravariantT],
      ),
    );

    expectNonCovariant(
      recordTypeNone(
        positionalTypes: [T, _contravariantT],
      ),
    );

    expectNotNonCovariant(
      recordTypeNone(
        namedTypes: {'a': T},
      ),
    );

    expectNonCovariant(
      recordTypeNone(
        namedTypes: {'a': _contravariantT},
      ),
    );
  }

  test_typeParameter() {
    expectNotNonCovariant(T);

    final U = typeParameter('U');
    expectNotNonCovariant(typeParameterTypeNone(U));
  }

  test_void() {
    expectNotNonCovariant(voidNone);
  }

  bool _compute(DartType type) {
    return type.accept(
      NonCovariantTypeParameterPositionVisitor(
        [T_element],
        initialVariance: Variance.covariant,
      ),
    );
  }
}
