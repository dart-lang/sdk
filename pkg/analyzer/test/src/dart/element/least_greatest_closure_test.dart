// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GreatestClosureTest);
  });
}

@reflectiveTest
class GreatestClosureTest extends AbstractTypeSystemTest {
  late final TypeParameterElement T;
  late final TypeParameterType T_none;
  late final TypeParameterType T_question;

  @override
  void setUp() {
    super.setUp();

    T = typeParameter('T');
    T_none = typeParameterTypeNone(T);
    T_question = typeParameterTypeQuestion(T);
  }

  test_contravariant() {
    _check(
      functionTypeNone(returnType: voidNone, parameters: [
        requiredParameter(type: T_none),
      ]),
      greatest: 'void Function(Never)',
      least: 'void Function(Object?)',
    );

    _check(
      functionTypeNone(
        returnType: functionTypeNone(
          returnType: voidNone,
          parameters: [
            requiredParameter(type: T_none),
          ],
        ),
      ),
      greatest: 'void Function(Never) Function()',
      least: 'void Function(Object?) Function()',
    );
  }

  test_covariant() {
    _check(T_none, greatest: 'Object?', least: 'Never');
    _check(T_question, greatest: 'Object?', least: 'Never?');

    _check(
      listNone(T_none),
      greatest: 'List<Object?>',
      least: 'List<Never>',
    );

    _check(
        functionTypeNone(returnType: voidNone, parameters: [
          requiredParameter(
            type: functionTypeNone(returnType: intNone, parameters: [
              requiredParameter(type: T_none),
            ]),
          ),
        ]),
        greatest: 'void Function(int Function(Object?))',
        least: 'void Function(int Function(Never))');
  }

  test_function() {
    // void Function<U extends T>()
    _check(
      functionTypeNone(
        typeFormals: [
          typeParameter('U', bound: T_none),
        ],
        returnType: voidNone,
      ),
      greatest: 'Function',
      least: 'Never',
    );
  }

  test_unrelated() {
    _check1(intNone, 'int');
    _check1(intQuestion, 'int?');

    _check1(listNone(intNone), 'List<int>');
    _check1(listQuestion(intNone), 'List<int>?');

    _check1(objectNone, 'Object');
    _check1(objectQuestion, 'Object?');

    _check1(neverNone, 'Never');
    _check1(neverQuestion, 'Never?');

    _check1(dynamicType, 'dynamic');

    _check1(
      functionTypeNone(returnType: stringNone, parameters: [
        requiredParameter(type: intNone),
      ]),
      'String Function(int)',
    );

    _check1(
      typeParameterTypeNone(
        typeParameter('U'),
      ),
      'U',
    );
  }

  void _check(
    DartType type, {
    required String greatest,
    required String least,
  }) {
    var greatestResult = typeSystem.greatestClosure(type, [T]);
    expect(
      greatestResult.getDisplayString(),
      greatest,
    );

    var leastResult = typeSystem.leastClosure(type, [T]);
    expect(
      leastResult.getDisplayString(),
      least,
    );
  }

  void _check1(DartType type, String expected) {
    _check(type, greatest: expected, least: expected);
  }
}
