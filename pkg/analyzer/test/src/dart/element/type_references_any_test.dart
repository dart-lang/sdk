// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeReferencesAnyTest);
  });
}

@reflectiveTest
class TypeReferencesAnyTest extends AbstractTypeSystemTest {
  late TypeParameterElementImpl2 T;
  late TypeParameterTypeImpl T_none;

  @override
  void setUp() {
    super.setUp();

    T = typeParameter2('T') as TypeParameterElementImpl2;
    T_none = typeParameterTypeNone2(T);
  }

  test_false() {
    _checkFalse(dynamicType);
    _checkFalse(intNone);
    _checkFalse(neverNone);
    _checkFalse(voidNone);
    _checkFalse(listNone(intNone));
  }

  test_true() {
    _checkTrue(T_none);
    _checkTrue(listNone(T_none));
    _checkTrue(mapNone(T_none, intNone));
    _checkTrue(mapNone(intNone, T_none));

    _checkTrue(functionTypeNone(returnType: T_none));

    _checkTrue(
      functionTypeNone(returnType: voidNone, parameters: [
        requiredParameter(type: T_none),
      ]),
    );

    _checkTrue(
      functionTypeNone(
        typeFormals: [
          typeParameter('U', bound: T_none),
        ],
        returnType: voidNone,
      ),
    );
  }

  void _checkFalse(DartType type) {
    var actual = (type as TypeImpl).referencesAny2({T});
    expect(actual, isFalse);
  }

  void _checkTrue(DartType type) {
    var actual = (type as TypeImpl).referencesAny2({T});
    expect(actual, isTrue);
  }
}
