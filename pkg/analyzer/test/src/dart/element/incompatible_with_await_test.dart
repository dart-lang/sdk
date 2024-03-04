// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsIncompatibleWithAwaitTest);
  });
}

@reflectiveTest
class IsIncompatibleWithAwaitTest extends AbstractTypeSystemTest {
  void isIncompatible(DartType type) {
    expect(typeSystem.isIncompatibleWithAwait(type), isTrue);
  }

  void isNotIncompatible(DartType type) {
    expect(typeSystem.isIncompatibleWithAwait(type), isFalse);
  }

  test_class_int() {
    isNotIncompatible(intNone);
    isNotIncompatible(intQuestion);
  }

  test_extensionType_implementsFuture() {
    var futureOfIntNone = futureNone(intNone);
    isNotIncompatible(
      interfaceTypeNone(
        extensionType(
          'A',
          representationType: futureOfIntNone,
          interfaces: [futureOfIntNone],
        ),
      ),
    );
  }

  test_extensionType_notImplementsFuture() {
    var futureOfIntNone = futureNone(intNone);

    isIncompatible(
      interfaceTypeNone(
        extensionType(
          'A',
          representationType: futureOfIntNone,
        ),
      ),
    );
  }

  test_futureInt() {
    isNotIncompatible(
      futureNone(intNone),
    );
  }

  test_futureOrInt() {
    isNotIncompatible(
      futureOrNone(intNone),
    );
  }

  test_typeParameter_bound_extensionType_implementsFuture() {
    var futureOfIntNone = futureNone(intNone);

    var A = extensionType(
      'A',
      representationType: futureOfIntNone,
      interfaces: [futureOfIntNone],
    );

    isNotIncompatible(
      typeParameterTypeNone(
        typeParameter(
          'T',
          bound: interfaceTypeNone(A),
        ),
      ),
    );
  }

  test_typeParameter_bound_extensionType_notImplementsFuture() {
    var futureOfIntNone = futureNone(intNone);

    var A = extensionType(
      'A',
      representationType: futureOfIntNone,
    );

    isIncompatible(
      typeParameterTypeNone(
        typeParameter(
          'T',
          bound: interfaceTypeNone(A),
        ),
      ),
    );
  }

  test_typeParameter_bound_numNone() {
    isNotIncompatible(
      typeParameterTypeNone(
        typeParameter('T', bound: numNone),
      ),
    );
  }

  test_typeParameter_promotedBound_extensionType_implementsFuture() {
    var futureOfIntNone = futureNone(intNone);

    // Incompatible with `await`, used as a bound.
    // Does not matter, `T` is promoted to not incompatible.
    var N = extensionType(
      'N',
      representationType: futureOfIntNone,
    );

    var F = extensionType(
      'F',
      representationType: futureOfIntNone,
      interfaces: [
        futureOfIntNone,
      ],
    );

    isNotIncompatible(
      typeParameterTypeNone(
        typeParameter(
          'T',
          bound: interfaceTypeNone(N),
        ),
        promotedBound: interfaceTypeNone(F),
      ),
    );
  }

  test_typeParameter_promotedBound_extensionType_notImplementsFuture() {
    var futureOfIntNone = futureNone(intNone);

    var A = extensionType(
      'A',
      representationType: futureOfIntNone,
    );

    isIncompatible(
      typeParameterTypeNone(
        typeParameter('T'),
        promotedBound: interfaceTypeNone(A),
      ),
    );
  }

  test_typeParameter_promotedBound_intNone() {
    isNotIncompatible(
      typeParameterTypeNone(
        typeParameter('T'),
        promotedBound: intNone,
      ),
    );
  }
}
