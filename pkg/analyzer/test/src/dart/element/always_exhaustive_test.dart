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
    isAlwaysExhaustive(boolNone);
    isAlwaysExhaustive(boolQuestion);
  }

  test_class_int() {
    isNotAlwaysExhaustive(intNone);
    isNotAlwaysExhaustive(intQuestion);
  }

  test_class_Null() {
    isAlwaysExhaustive(nullNone);
  }

  test_class_sealed() {
    testLibrary = buildTestLibrary(
      LibrarySpec(
        uri: 'package:test/test.dart',
        imports: const ['dart:core'],
        classes: [ClassSpec(name: 'A', isSealed: true)],
      ),
    );
    var A = testLibrary.getClass('A')!;
    isAlwaysExhaustive(interfaceTypeNone(A));
    isAlwaysExhaustive(interfaceTypeQuestion(A));
  }

  test_enum() {
    testLibrary = buildTestLibrary(
      LibrarySpec(
        uri: 'package:test/test.dart',
        imports: const ['dart:core'],
        enums: [EnumSpec(name: 'E')],
      ),
    );
    var E = testLibrary.getEnum('E')!;
    isAlwaysExhaustive(interfaceTypeNone(E));
    isAlwaysExhaustive(interfaceTypeQuestion(E));
  }

  test_extensionType() {
    isAlwaysExhaustive(
      interfaceTypeNone(
        buildExtensionType(
          const ExtensionTypeSpec(name: 'A', representationType: 'bool'),
        ),
      ),
    );

    isAlwaysExhaustive(
      interfaceTypeNone(
        buildExtensionType(
          const ExtensionTypeSpec(name: 'A', representationType: 'bool?'),
        ),
      ),
    );

    isNotAlwaysExhaustive(
      interfaceTypeNone(
        buildExtensionType(
          const ExtensionTypeSpec(name: 'A', representationType: 'int'),
        ),
      ),
    );
  }

  test_futureOr() {
    isAlwaysExhaustive(futureOrNone(boolNone));
    isAlwaysExhaustive(futureOrQuestion(boolNone));

    isAlwaysExhaustive(futureOrNone(boolQuestion));
    isAlwaysExhaustive(futureOrQuestion(boolQuestion));

    isNotAlwaysExhaustive(futureOrNone(intNone));
    isNotAlwaysExhaustive(futureOrQuestion(intNone));
  }

  test_recordType() {
    isAlwaysExhaustive(recordTypeNone(positionalTypes: [boolNone]));

    isAlwaysExhaustive(recordTypeNone(namedTypes: {'f0': boolNone}));

    isNotAlwaysExhaustive(recordTypeNone(positionalTypes: [intNone]));

    isNotAlwaysExhaustive(recordTypeNone(positionalTypes: [boolNone, intNone]));

    isNotAlwaysExhaustive(recordTypeNone(namedTypes: {'f0': intNone}));

    isNotAlwaysExhaustive(
      recordTypeNone(namedTypes: {'f0': boolNone, 'f1': intNone}),
    );
  }

  test_typeParameter() {
    isAlwaysExhaustive(
      typeParameterTypeNone(typeParameter('T', bound: boolNone)),
    );

    isNotAlwaysExhaustive(
      typeParameterTypeNone(typeParameter('T', bound: numNone)),
    );

    isAlwaysExhaustive(
      typeParameterTypeNone(typeParameter('T'), promotedBound: boolNone),
    );

    isNotAlwaysExhaustive(
      typeParameterTypeNone(typeParameter('T'), promotedBound: intNone),
    );
  }
}
