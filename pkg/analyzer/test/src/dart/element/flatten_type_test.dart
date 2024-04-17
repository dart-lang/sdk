// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
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
    _check(dynamicType, 'dynamic');
  }

  test_interfaceType() {
    _check(intNone, 'int');
    _check(intQuestion, 'int?');
  }

  test_interfaceType_none_hasFutureType() {
    _check(futureNone(intNone), 'int');
    _check(futureNone(intQuestion), 'int?');

    _check(futureQuestion(intNone), 'int?');
    _check(futureQuestion(intQuestion), 'int?');

    _check(futureOrNone(intNone), 'int');
    _check(futureOrNone(intQuestion), 'int?');

    _check(futureOrQuestion(intNone), 'int?');
    _check(futureOrQuestion(intQuestion), 'int?');

    _check(futureOrNone(futureNone(intNone)), 'Future<int>');
    _check(futureOrNone(futureNone(intQuestion)), 'Future<int?>');

    _check(futureOrQuestion(futureNone(intNone)), 'Future<int>?');
    _check(futureOrQuestion(futureNone(intQuestion)), 'Future<int?>?');
  }

  test_interfaceType_question() {
    _check(futureQuestion(intNone), 'int?');
    _check(futureQuestion(intQuestion), 'int?');
  }

  test_typeParameterType_none() {
    // T extends Future<int>
    _check(
      typeParameterTypeNone(
        typeParameter('T', bound: futureNone(intNone)),
      ),
      'int',
    );

    // T extends FutureOr<int>
    _check(
      typeParameterTypeNone(
        typeParameter('T', bound: futureOrNone(intNone)),
      ),
      'int',
    );

    // T & Future<int>
    _check(
      typeParameterTypeNone(
        typeParameter('T'),
        promotedBound: futureNone(intNone),
      ),
      'int',
    );

    // T & FutureOr<int>
    _check(
      typeParameterTypeNone(
        typeParameter('T'),
        promotedBound: futureOrNone(intNone),
      ),
      'int',
    );

    // T extends int
    _check(
      typeParameterTypeNone(
        typeParameter('T', bound: intNone),
      ),
      'T',
    );

    // T & int
    _check(
      typeParameterTypeNone(
        typeParameter('T'),
        promotedBound: intNone,
      ),
      'T',
    );
  }

  test_typeParameterType_question() {
    // T extends Future<int>
    _check(
      typeParameterTypeQuestion(
        typeParameter('T', bound: futureNone(intNone)),
      ),
      'int?',
    );

    // T extends FutureOr<int>
    _check(
      typeParameterTypeQuestion(
        typeParameter('T', bound: futureOrNone(intNone)),
      ),
      'int?',
    );
  }

  test_unknownInferredType() {
    var type = UnknownInferredType.instance;
    expect(typeSystem.flatten(type), same(type));
  }

  void _check(DartType T, String expected) {
    var result = typeSystem.flatten(T);
    expect(
      result.getDisplayString(),
      expected,
    );
  }
}

@reflectiveTest
class FutureTypeTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _check(dynamicType, null);
  }

  test_functionType() {
    _check(functionTypeNone(returnType: voidNone), null);
  }

  test_implements_Future() {
    var A = class_(name: 'A', interfaces: [
      futureNone(intNone),
    ]);

    _check(interfaceTypeNone(A), 'Future<int>');
    _check(interfaceTypeQuestion(A), null);
  }

  test_interfaceType() {
    _check(objectNone, null);
    _check(objectQuestion, null);

    _check(intNone, null);
    _check(intQuestion, null);

    _check(listNone(intNone), null);
    _check(listNone(intQuestion), null);

    _check(listQuestion(intNone), null);
    _check(listQuestion(intQuestion), null);

    _check(futureNone(intNone), 'Future<int>');
    _check(futureNone(intQuestion), 'Future<int?>');

    _check(futureQuestion(intNone), 'Future<int>?');
    _check(futureQuestion(intQuestion), 'Future<int?>?');

    _check(futureOrNone(intNone), 'FutureOr<int>');
    _check(futureOrNone(intQuestion), 'FutureOr<int?>');

    _check(futureOrQuestion(intNone), 'FutureOr<int>?');
    _check(futureOrQuestion(intQuestion), 'FutureOr<int?>?');

    _check(futureNone(futureNone(intNone)), 'Future<Future<int>>');
    _check(futureNone(futureOrNone(intNone)), 'Future<FutureOr<int>>');
    _check(futureOrNone(futureNone(intNone)), 'FutureOr<Future<int>>');
    _check(futureOrNone(futureOrNone(intNone)), 'FutureOr<FutureOr<int>>');
  }

  test_typeParameterType_none() {
    // T extends Future<int>
    _check(
      typeParameterTypeNone(
        typeParameter('T', bound: futureNone(intNone)),
      ),
      'Future<int>',
    );

    // T extends FutureOr<int>
    _check(
      typeParameterTypeNone(
        typeParameter('T', bound: futureOrNone(intNone)),
      ),
      'FutureOr<int>',
    );

    // T & Future<int>
    _check(
      typeParameterTypeNone(
        typeParameter('T'),
        promotedBound: futureNone(intNone),
      ),
      'Future<int>',
    );

    // T & FutureOr<int>
    _check(
      typeParameterTypeNone(
        typeParameter('T'),
        promotedBound: futureOrNone(intNone),
      ),
      'FutureOr<int>',
    );

    // T extends int
    _check(
      typeParameterTypeNone(
        typeParameter('T', bound: intNone),
      ),
      null,
    );

    // T & int
    _check(
      typeParameterTypeNone(
        typeParameter('T'),
        promotedBound: intNone,
      ),
      null,
    );
  }

  test_unknownInferredType() {
    _check(UnknownInferredType.instance, null);
  }

  void _check(DartType T, String? expected) {
    var result = typeSystem.futureType(T);
    if (result == null) {
      expect(expected, isNull);
    } else {
      expect(
        result.getDisplayString(),
        expected,
      );
    }
  }
}
