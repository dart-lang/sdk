// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsKnownTest);
  });
}

@reflectiveTest
class IsKnownTest extends AbstractTypeSystemTest {
  test_dynamic() {
    _checkKnown(dynamicType);
  }

  test_function() {
    _checkKnown(
      functionTypeNone(returnType: voidNone),
    );

    _checkUnknown(
      functionTypeNone(returnType: unknownInferredType),
    );

    _checkUnknown(
      functionTypeNone(returnType: voidNone, parameters: [
        requiredParameter(type: unknownInferredType),
      ]),
    );
  }

  test_interface() {
    _checkKnown(intNone);
    _checkKnown(listNone(intNone));
    _checkUnknown(listNone(unknownInferredType));
  }

  test_never() {
    _checkKnown(neverNone);
  }

  test_null() {
    _checkKnown(nullStar);
  }

  test_record() {
    _checkKnown(recordTypeNone(
      positionalTypes: [intNone],
    ));

    _checkUnknown(recordTypeNone(
      positionalTypes: [unknownInferredType],
    ));

    _checkKnown(recordTypeNone(
      namedTypes: {
        'x': intNone,
      },
    ));

    _checkUnknown(recordTypeNone(
      namedTypes: {
        'x': unknownInferredType,
      },
    ));
  }

  test_unknownInferredType() {
    _checkUnknown(unknownInferredType);
  }

  test_void() {
    _checkKnown(voidNone);
  }

  void _checkKnown(DartType type) {
    expect(UnknownInferredType.isKnown(type), isTrue);
    expect(UnknownInferredType.isUnknown(type), isFalse);
  }

  void _checkUnknown(DartType type) {
    expect(UnknownInferredType.isKnown(type), isFalse);
    expect(UnknownInferredType.isUnknown(type), isTrue);
  }
}
