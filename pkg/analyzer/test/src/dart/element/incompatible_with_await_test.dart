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
    isNotIncompatible(intNone);
    isNotIncompatible(intQuestion);
  }

  test_extensionType_implementsFuture() {
    isNotIncompatible(
      interfaceTypeNone(
        buildExtensionType(
          const ExtensionTypeSpec(
            name: 'A',
            representationType: 'Future<int>',
            interfaces: ['Future<int>'],
          ),
        ),
      ),
    );
  }

  test_extensionType_notImplementsFuture() {
    isIncompatible(
      interfaceTypeNone(
        buildExtensionType(
          const ExtensionTypeSpec(name: 'A', representationType: 'Future<int>'),
        ),
      ),
    );
  }

  test_futureInt() {
    isNotIncompatible(futureNone(intNone));
  }

  test_futureOrInt() {
    isNotIncompatible(futureOrNone(intNone));
  }

  test_typeParameter_bound_extensionType_implementsFuture() {
    var A = buildExtensionType(
      const ExtensionTypeSpec(
        name: 'A',
        representationType: 'Future<int>',
        interfaces: ['Future<int>'],
      ),
    );

    isNotIncompatible(
      typeParameterTypeNone(typeParameter('T', bound: interfaceTypeNone(A))),
    );
  }

  test_typeParameter_bound_extensionType_notImplementsFuture() {
    var A = buildExtensionType(
      const ExtensionTypeSpec(name: 'A', representationType: 'Future<int>'),
    );

    isIncompatible(
      typeParameterTypeNone(typeParameter('T', bound: interfaceTypeNone(A))),
    );
  }

  test_typeParameter_bound_numNone() {
    isNotIncompatible(
      typeParameterTypeNone(typeParameter('T', bound: numNone)),
    );
  }

  test_typeParameter_promotedBound_extensionType_implementsFuture() {
    // Incompatible with `await`, used as a bound.
    // Does not matter, `T` is promoted to not incompatible.
    testLibrary = buildTestLibrary(
      const LibrarySpec(
        uri: 'package:test/test.dart',
        imports: ['dart:core', 'dart:async'],
        extensionTypes: [
          ExtensionTypeSpec(name: 'N', representationType: 'Future<int>'),
          ExtensionTypeSpec(
            name: 'F',
            representationType: 'Future<int>',
            interfaces: ['Future<int>'],
          ),
        ],
      ),
    );
    var N = testLibrary.getExtensionType('N')!;
    var F = testLibrary.getExtensionType('F')!;

    isNotIncompatible(
      typeParameterTypeNone(
        typeParameter('T', bound: interfaceTypeNone(N)),
        promotedBound: interfaceTypeNone(F),
      ),
    );
  }

  test_typeParameter_promotedBound_extensionType_notImplementsFuture() {
    var A = buildExtensionType(
      const ExtensionTypeSpec(name: 'A', representationType: 'Future<int>'),
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
      typeParameterTypeNone(typeParameter('T'), promotedBound: intNone),
    );
  }
}
