// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
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
    _assertNotValid(parseType('void Function()'));
  }

  test_interfaceType() {
    _assertValid(parseType('num'));
  }

  test_interfaceType_extensionType() {
    buildTestLibrary(
      extensionTypes: [ExtensionTypeSpec('extension type A(int it)')],
    );
    _assertValid(parseType('A'));
  }

  test_interfaceType_function() {
    _assertNotValid(parseType('Function'));
  }

  test_interfaceType_futureOr() {
    _assertNotValid(parseType('FutureOr<int>'));
  }

  test_interfaceType_null() {
    _assertNotValid(parseType('Null'));
  }

  test_interfaceType_nullable() {
    _assertNotValid(parseType('num?'));
  }

  test_interfaceType_record() {
    _assertNotValid(parseType('Record'));
  }

  test_recordType() {
    _assertNotValid(parseType('(int, String)'));
  }

  test_topType() {
    _assertNotValid(parseType('dynamic'));
    _assertNotValid(parseType('void'));
    _assertNotValid(parseType('Object?'));
  }

  test_typeParameterType() {
    withTypeParameterScope('T', (scope) {
      _assertNotValid(scope.parseType('T'));
    });
  }

  void _assertNotValid(DartType type) {
    expect(typeSystem.isValidExtensionTypeSuperinterface(type), isFalse);
  }

  void _assertValid(DartType type) {
    expect(typeSystem.isValidExtensionTypeSuperinterface(type), isTrue);
  }
}
