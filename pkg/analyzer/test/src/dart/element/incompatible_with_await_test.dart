// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
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
  void isIncompatible(TypeImpl type) {
    expect(typeSystem.isIncompatibleWithAwait(type), isTrue);
  }

  void isNotIncompatible(TypeImpl type) {
    expect(typeSystem.isIncompatibleWithAwait(type), isFalse);
  }

  test_class_int() {
    isNotIncompatible(parseType('int'));
    isNotIncompatible(parseType('int?'));
  }

  test_extensionType_implementsFuture() {
    buildTestLibrary(
      imports: ['dart:core', 'dart:async'],
      extensionTypes: [
        ExtensionTypeSpec(
          'extension type A(Future<int> it) implements Future<int>',
        ),
      ],
    );
    isNotIncompatible(parseInterfaceType('A'));
  }

  test_extensionType_notImplementsFuture() {
    buildTestLibrary(
      imports: ['dart:core', 'dart:async'],
      extensionTypes: [ExtensionTypeSpec('extension type A(Future<int> it)')],
    );
    isIncompatible(parseInterfaceType('A'));
  }

  test_futureInt() {
    isNotIncompatible(parseType('Future<int>'));
  }

  test_futureOrInt() {
    isNotIncompatible(parseType('FutureOr<int>'));
  }

  test_typeParameter_bound_extensionType_implementsFuture() {
    buildTestLibrary(
      imports: ['dart:core', 'dart:async'],
      extensionTypes: [
        ExtensionTypeSpec(
          'extension type A(Future<int> it) implements Future<int>',
        ),
      ],
    );
    withTypeParameterScope('T extends A', (scope) {
      isNotIncompatible(scope.parseType('T'));
    });
  }

  test_typeParameter_bound_extensionType_notImplementsFuture() {
    buildTestLibrary(
      imports: ['dart:core', 'dart:async'],
      extensionTypes: [ExtensionTypeSpec('extension type A(Future<int> it)')],
    );
    withTypeParameterScope('T extends A', (scope) {
      isIncompatible(scope.parseType('T'));
    });
  }

  test_typeParameter_bound_numNone() {
    withTypeParameterScope('T extends num', (scope) {
      isNotIncompatible(scope.parseType('T'));
    });
  }

  test_typeParameter_promotedBound_extensionType_implementsFuture() {
    // Incompatible with `await`, used as a bound.
    // Does not matter, `T` is promoted to not incompatible.
    buildTestLibrary(
      imports: ['dart:core', 'dart:async'],
      extensionTypes: [
        ExtensionTypeSpec('extension type N(Future<int> it)'),
        ExtensionTypeSpec(
          'extension type F(Future<int> it) implements Future<int>',
        ),
      ],
    );
    withTypeParameterScope('T extends N', (scope) {
      isNotIncompatible(scope.parseType('T & F'));
    });
  }

  test_typeParameter_promotedBound_extensionType_notImplementsFuture() {
    buildTestLibrary(
      imports: ['dart:core', 'dart:async'],
      extensionTypes: [ExtensionTypeSpec('extension type A(Future<int> it)')],
    );
    withTypeParameterScope('T', (scope) {
      isIncompatible(scope.parseType('T & A'));
    });
  }

  test_typeParameter_promotedBound_intNone() {
    withTypeParameterScope('T', (scope) {
      isNotIncompatible(scope.parseType('T & int'));
    });
  }
}
