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
    defineReflectiveTests(IsAlwaysExhaustiveTest);
  });
}

@reflectiveTest
class IsAlwaysExhaustiveTest extends AbstractTypeSystemTest {
  void isAlwaysExhaustive(DartType type) {
    expect(typeSystem.isAlwaysExhaustive(type), isTrue);
  }

  void isNotAlwaysExhaustive(DartType type) {
    expect(typeSystem.isAlwaysExhaustive(type), isFalse);
  }

  test_class_bool() {
    isAlwaysExhaustive(parseType('bool'));
    isAlwaysExhaustive(parseType('bool?'));
  }

  test_class_int() {
    isNotAlwaysExhaustive(parseType('int'));
    isNotAlwaysExhaustive(parseType('int?'));
  }

  test_class_Null() {
    isAlwaysExhaustive(parseType('Null'));
  }

  test_class_sealed() {
    buildTestLibrary(classes: [ClassSpec('sealed class A')]);
    isAlwaysExhaustive(parseType('A'));
    isAlwaysExhaustive(parseType('A?'));
  }

  test_enum() {
    buildTestLibrary(enums: [EnumSpec('enum E')]);
    isAlwaysExhaustive(parseType('E'));
    isAlwaysExhaustive(parseType('E?'));
  }

  test_extensionType() {
    buildTestLibrary(
      extensionTypes: [ExtensionTypeSpec('extension type A(bool it)')],
    );
    isAlwaysExhaustive(parseType('A'));

    buildTestLibrary(
      extensionTypes: [ExtensionTypeSpec('extension type A(bool? it)')],
    );
    isAlwaysExhaustive(parseType('A'));

    buildTestLibrary(
      extensionTypes: [ExtensionTypeSpec('extension type A(int it)')],
    );
    isNotAlwaysExhaustive(parseType('A'));
  }

  test_futureOr() {
    isAlwaysExhaustive(parseType('FutureOr<bool>'));
    isAlwaysExhaustive(parseType('FutureOr<bool>?'));

    isAlwaysExhaustive(parseType('FutureOr<bool?>'));
    isAlwaysExhaustive(parseType('FutureOr<bool?>?'));

    isNotAlwaysExhaustive(parseType('FutureOr<int>'));
    isNotAlwaysExhaustive(parseType('FutureOr<int>?'));
  }

  test_recordType() {
    isAlwaysExhaustive(parseType('(bool,)'));

    isAlwaysExhaustive(parseType('({bool f0})'));

    isNotAlwaysExhaustive(parseType('(int,)'));

    isNotAlwaysExhaustive(parseType('(bool, int)'));

    isNotAlwaysExhaustive(parseType('({int f0})'));

    isNotAlwaysExhaustive(parseType('({bool f0, int f1})'));
  }

  test_typeParameter() {
    withTypeParameterScope('T extends bool', (scope) {
      isAlwaysExhaustive(scope.parseType('T'));
    });

    withTypeParameterScope('T extends num', (scope) {
      isNotAlwaysExhaustive(scope.parseType('T'));
    });

    withTypeParameterScope('T', (scope) {
      isAlwaysExhaustive(scope.parseType('T & bool'));
      isNotAlwaysExhaustive(scope.parseType('T & int'));
    });
  }
}
