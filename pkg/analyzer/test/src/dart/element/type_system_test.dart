// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsValidExtensionTypeSuperinterfaceTest);
  });
}

@reflectiveTest
class IsValidExtensionTypeSuperinterfaceTest extends AbstractTypeSystemTest {
  test_functionType() {
    _assertNotValid(
      functionTypeNone(returnType: voidNone),
    );
  }

  test_interfaceType() {
    _assertValid(numNone);
  }

  test_interfaceType_extensionType() {
    var element = extensionType('A', representationType: intNone);
    _assertValid(
      interfaceTypeNone(element),
    );
  }

  test_interfaceType_function() {
    _assertNotValid(functionNone);
  }

  test_interfaceType_futureOr() {
    _assertNotValid(
      futureOrNone(intNone),
    );
  }

  test_interfaceType_null() {
    _assertNotValid(nullNone);
  }

  test_interfaceType_nullable() {
    _assertNotValid(numQuestion);
  }

  test_interfaceType_record() {
    _assertNotValid(recordNone);
  }

  test_recordType() {
    _assertNotValid(
      recordTypeNone(
        positionalTypes: [intNone, stringNone],
      ),
    );
  }

  test_topType() {
    _assertNotValid(dynamicType);
    _assertNotValid(voidNone);
    _assertNotValid(objectQuestion);
  }

  test_typeParameterType() {
    var T = typeParameter('T');
    _assertNotValid(
      typeParameterTypeNone(T),
    );
  }

  void _assertNotValid(DartType type) {
    expect(typeSystem.isValidExtensionTypeSuperinterface(type), isFalse);
  }

  void _assertValid(DartType type) {
    expect(typeSystem.isValidExtensionTypeSuperinterface(type), isTrue);
  }
}
