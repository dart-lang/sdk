// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTypeTest);
  });
}

DynamicTypeImpl get dynamicType => DynamicTypeImpl.instance;

@reflectiveTest
class FunctionTypeTest extends AbstractTypeSystemTest {
  InterfaceType get intType => typeProvider.intType;

  ClassElement get listElement => typeProvider.listElement;

  ClassElement get mapElement => typeProvider.mapElement;

  InterfaceTypeImpl get objectType => typeProvider.objectType;

  void basicChecks(
    FunctionType f, {
    displayName = 'dynamic Function()',
    returnType,
    namedParameterTypes = isEmpty,
    normalParameterNames = isEmpty,
    normalParameterTypes = isEmpty,
    optionalParameterNames = isEmpty,
    optionalParameterTypes = isEmpty,
    parameters = isEmpty,
    typeFormals = isEmpty,
    typeParameters = isEmpty,
  }) {
    // DartType properties
    expect(f.getDisplayString(), displayName, reason: 'displayName');
    // FunctionType properties
    expect(
      f.namedParameterTypes,
      namedParameterTypes,
      reason: 'namedParameterTypes',
    );
    expect(
      f.normalParameterTypes,
      normalParameterTypes,
      reason: 'normalParameterTypes',
    );
    expect(
      f.optionalParameterTypes,
      optionalParameterTypes,
      reason: 'optionalParameterTypes',
    );
    expect(f.formalParameters, parameters, reason: 'parameters');
    expect(f.returnType, returnType ?? same(dynamicType), reason: 'returnType');
    expect(f.typeParameters, typeFormals, reason: 'typeFormals');
  }

  DartType listOf(DartType elementType) => listElement.instantiate(
    typeArguments: [elementType],
    nullabilitySuffix: NullabilitySuffix.none,
  );

  DartType mapOf(DartType keyType, DartType valueType) =>
      mapElement.instantiate(
        typeArguments: [keyType, valueType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

  test_equality_leftRequired_rightPositional() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        positionalParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_differentName() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [namedParameter(name: 'a', type: typeProvider.intType)],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [namedParameter(name: 'b', type: typeProvider.intType)],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_differentType() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [namedParameter(name: 'a', type: typeProvider.intType)],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        namedParameter(name: 'a', type: typeProvider.doubleType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_equal() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
        namedParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
        namedParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    expect(f1, f2);
  }

  test_equality_namedParameters_extraLeft() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
        namedParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [namedParameter(name: 'a', type: typeProvider.intType)],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_extraRight() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [namedParameter(name: 'a', type: typeProvider.intType)],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        namedParameter(name: 'a', type: typeProvider.intType),
        namedParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_required_left() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        namedRequiredParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [namedParameter(name: 'a', type: typeProvider.intType)],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_required_right() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [namedParameter(name: 'a', type: typeProvider.intType)],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        namedRequiredParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_requiredParameters_extraLeft() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
        requiredParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_equality_requiredParameters_extraRight() {
    var f1 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
      ],
    );
    var f2 = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
        requiredParameter(name: 'b', type: typeProvider.doubleType),
      ],
    );
    expect(f1, isNot(equals(f2)));
  }

  test_hash_namedParameterOptionality() {
    _testHashesSometimesDifferPairwise(
      (i) => (
        FunctionTypeImpl(
          typeParameters: const [],
          parameters: [namedParameter(name: 'p$i', type: typeProvider.intType)],
          returnType: typeProvider.voidType,
          nullabilitySuffix: NullabilitySuffix.none,
        ),
        FunctionTypeImpl(
          typeParameters: const [],
          parameters: [
            namedRequiredParameter(name: 'p$i', type: typeProvider.intType),
          ],
          returnType: typeProvider.voidType,
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      ),
    );
  }

  test_hash_nullabilitySuffix() {
    _testHashesSometimesDifferPairwise((i) {
      var cf = class_(name: 'C$i');
      var c = cf.element;
      return (
        FunctionTypeImpl(
          typeParameters: const [],
          parameters: [requiredParameter(name: 'x', type: c.thisType)],
          returnType: typeProvider.voidType,
          nullabilitySuffix: NullabilitySuffix.none,
        ),
        FunctionTypeImpl(
          typeParameters: const [],
          parameters: [requiredParameter(name: 'x', type: c.thisType)],
          returnType: typeProvider.voidType,
          nullabilitySuffix: NullabilitySuffix.question,
        ),
      );
    });
  }

  test_hash_optionalNamedParameterName() {
    _testHashesSometimesDiffer(
      (i) => FunctionTypeImpl(
        typeParameters: const [],
        parameters: [namedParameter(name: 'p$i', type: typeProvider.intType)],
        returnType: typeProvider.voidType,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
  }

  test_hash_optionalNamedParameterType() {
    _testHashesSometimesDiffer(
      (i) => FunctionTypeImpl(
        typeParameters: const [],
        parameters: [
          namedParameter(
            name: 'x',
            type: class_(name: 'C$i').element.thisType,
          ),
        ],
        returnType: typeProvider.voidType,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
  }

  test_hash_optionalPositionalParameterName() {
    // Optional parameter names are irrelevant
    _testHashesAlwaysEqual(
      (i) => FunctionTypeImpl(
        typeParameters: const [],
        parameters: [
          positionalParameter(name: 'p$i', type: typeProvider.intType),
        ],
        returnType: typeProvider.voidType,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
  }

  test_hash_optionalPositionalParameterType() {
    _testHashesAlwaysEqual(
      (i) => FunctionTypeImpl(
        typeParameters: const [],
        parameters: [
          positionalParameter(
            name: 'x',
            type: class_(name: 'C$i').element.thisType,
          ),
        ],
        returnType: typeProvider.voidType,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
  }

  test_hash_positionalParameterOptionality() {
    _testHashesSometimesDifferPairwise(
      (i) => (
        FunctionTypeImpl(
          typeParameters: const [],
          parameters: [
            requiredParameter(name: 'p$i', type: typeProvider.intType),
          ],
          returnType: typeProvider.voidType,
          nullabilitySuffix: NullabilitySuffix.none,
        ),
        FunctionTypeImpl(
          typeParameters: const [],
          parameters: [
            positionalParameter(name: 'p$i', type: typeProvider.intType),
          ],
          returnType: typeProvider.voidType,
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      ),
    );
  }

  test_hash_requiredNamedParameterName() {
    _testHashesSometimesDiffer(
      (i) => FunctionTypeImpl(
        typeParameters: const [],
        parameters: [
          namedRequiredParameter(name: 'p$i', type: typeProvider.intType),
        ],
        returnType: typeProvider.voidType,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
  }

  test_hash_requiredNamedParameterType() {
    _testHashesSometimesDiffer(
      (i) => FunctionTypeImpl(
        typeParameters: const [],
        parameters: [
          namedRequiredParameter(
            name: 'x',
            type: class_(name: 'C$i').element.thisType,
          ),
        ],
        returnType: typeProvider.voidType,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
  }

  test_hash_requiredPositionalParameterName() {
    // Required parameter names are irrelevant
    _testHashesAlwaysEqual(
      (i) => FunctionTypeImpl(
        typeParameters: const [],
        parameters: [
          requiredParameter(name: 'p$i', type: typeProvider.intType),
        ],
        returnType: typeProvider.voidType,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
  }

  test_hash_requiredPositionalParameterType() {
    _testHashesAlwaysEqual(
      (i) => FunctionTypeImpl(
        typeParameters: const [],
        parameters: [
          requiredParameter(
            name: 'x',
            type: class_(name: 'C$i').element.thisType,
          ),
        ],
        returnType: typeProvider.voidType,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
  }

  test_hash_returnType() {
    _testHashesSometimesDiffer(
      (i) => FunctionTypeImpl(
        typeParameters: const [],
        parameters: const [],
        returnType: class_(name: 'C$i').element.thisType,
        nullabilitySuffix: NullabilitySuffix.none,
      ),
    );
  }

  test_hash_typeFormalNames() {
    _testHashesAlwaysEqual((i) {
      var t = TypeParameterElementImpl.synthetic(name: 'T$i');
      var u = TypeParameterElementImpl.synthetic(name: 'U$i');
      return FunctionTypeImpl(
        typeParameters: [t, u],
        parameters: [
          requiredParameter(
            name: 'x',
            type: TypeParameterTypeImpl(
              element: t,
              nullabilitySuffix: NullabilitySuffix.none,
            ),
          ),
          requiredParameter(
            name: 'y',
            type: TypeParameterTypeImpl(
              element: t,
              nullabilitySuffix: NullabilitySuffix.none,
            ),
          ),
        ],
        returnType: typeProvider.voidType,
        nullabilitySuffix: NullabilitySuffix.none,
      );
    });
  }

  test_new_sortsNamedParameters() {
    var f = functionTypeNone(
      returnType: typeProvider.voidType,
      formalParameters: [
        requiredParameter(name: 'a', type: typeProvider.intType),
        namedParameter(name: 'c', type: typeProvider.intType),
        namedParameter(name: 'b', type: typeProvider.intType),
      ],
    );
    var parameters = f.formalParameters;
    expect(parameters, hasLength(3));
    expect(parameters[0].name, 'a');
    expect(parameters[1].name, 'b');
    expect(parameters[2].name, 'c');
  }

  test_synthetic() {
    FunctionType f = FunctionTypeImpl(
      typeParameters: const [],
      parameters: const [],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
    basicChecks(f);
  }

  test_synthetic_instantiate() {
    // T Function<T>(T x)
    var t = typeParameter('T');
    var x = requiredParameter(name: 'x', type: typeParameterTypeNone(t));
    FunctionType f = FunctionTypeImpl(
      typeParameters: [t],
      parameters: [x],
      returnType: typeParameterTypeNone(t),
      nullabilitySuffix: NullabilitySuffix.none,
    );
    FunctionType instantiated = f.instantiate([objectType]);
    basicChecks(
      instantiated,
      displayName: 'Object Function(Object)',
      returnType: same(objectType),
      normalParameterNames: ['x'],
      normalParameterTypes: [same(objectType)],
      parameters: hasLength(1),
    );
  }

  test_synthetic_instantiate_argument_length_mismatch() {
    // dynamic Function<T>()
    var t = typeParameter('T');
    FunctionType f = FunctionTypeImpl(
      typeParameters: [t],
      parameters: const [],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
    expect(() => f.instantiate([]), throwsA(TypeMatcher<ArgumentError>()));
  }

  test_synthetic_instantiate_no_type_formals() {
    FunctionType f = FunctionTypeImpl(
      typeParameters: const [],
      parameters: const [],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
    expect(f.instantiate([]), same(f));
  }

  test_synthetic_namedParameter() {
    var p = namedParameter(name: 'x', type: objectType);
    FunctionType f = FunctionTypeImpl(
      typeParameters: const [],
      parameters: [p],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
    basicChecks(
      f,
      displayName: 'dynamic Function({Object x})',
      namedParameterTypes: {'x': same(objectType)},
      parameters: hasLength(1),
    );
    expect(f.formalParameters[0].isNamed, isTrue);
    expect(f.formalParameters[0].name, 'x');
    expect(f.formalParameters[0].type, same(objectType));
  }

  test_synthetic_normalParameter() {
    var p = requiredParameter(name: 'x', type: objectType);
    FunctionType f = FunctionTypeImpl(
      typeParameters: const [],
      parameters: [p],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
    basicChecks(
      f,
      displayName: 'dynamic Function(Object)',
      normalParameterNames: ['x'],
      normalParameterTypes: [same(objectType)],
      parameters: hasLength(1),
    );
    expect(f.formalParameters[0].isRequiredPositional, isTrue);
    expect(f.formalParameters[0].name, 'x');
    expect(f.formalParameters[0].type, same(objectType));
  }

  test_synthetic_optionalParameter() {
    var p = positionalParameter(name: 'x', type: objectType);
    FunctionType f = FunctionTypeImpl(
      typeParameters: const [],
      parameters: [p],
      returnType: dynamicType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
    basicChecks(
      f,
      displayName: 'dynamic Function([Object])',
      optionalParameterNames: ['x'],
      optionalParameterTypes: [same(objectType)],
      parameters: hasLength(1),
    );
    expect(f.formalParameters[0].isOptionalPositional, isTrue);
    expect(f.formalParameters[0].name, 'x');
    expect(f.formalParameters[0].type, same(objectType));
  }

  test_synthetic_returnType() {
    FunctionType f = FunctionTypeImpl(
      typeParameters: const [],
      parameters: const [],
      returnType: objectType,
      nullabilitySuffix: NullabilitySuffix.none,
    );
    basicChecks(
      f,
      displayName: 'Object Function()',
      returnType: same(objectType),
    );
  }

  test_synthetic_typeFormals() {
    var t = typeParameter('T');
    FunctionType f = FunctionTypeImpl.v2(
      typeParameters: [t],
      formalParameters: const [],
      returnType: typeParameterTypeNone(t),
      nullabilitySuffix: NullabilitySuffix.none,
    );
    basicChecks(
      f,
      displayName: 'T Function<T>()',
      returnType: typeParameterTypeNone(t),
      typeFormals: [same(t)],
    );
  }

  /// Verifies that the objects returned by [generate] always have equal hashes,
  /// regardless of the integer passed to [generate].
  ///
  /// This can be used to verify that an implementation of `Object.hashCode`
  /// properly ignores a given property when computing the hash.
  ///
  /// The verification is done probabilistically, by calling [generate] 10 times
  /// (passing 10 different integer values), and verifying that all the hashes
  /// are the same.
  void _testHashesAlwaysEqual<T>(T Function(int) generate) {
    var x = generate(0);
    for (var i = 1; i < 10; i++) {
      var y = generate(i);
      expect(x.hashCode, y.hashCode);
      x = y;
    }
  }

  /// Verifies that the objects returned by [generate] sometimes have different
  /// hashes.
  ///
  /// This can be used to verify that an implementation of `Object.hashCode`
  /// properly includes a given property as part of the hash computation, if
  /// that property can take on a large number of possible values.
  ///
  /// To avoid spurious failures due to the probabilistic nature of hashing,
  /// [generate] is called 10 times (passing 10 different integer values), and
  /// the test only fails if all 10 returned values have the same hash.
  void _testHashesSometimesDiffer<T>(T Function(int) generate) {
    var x = generate(0);
    for (var i = 1; i < 10; i++) {
      var y = generate(i);
      if (x.hashCode != y.hashCode) return;
      x = y;
    }
    fail('Hashes never differed');
  }

  /// Verifies that the two objects returned by [generate] sometimes have
  /// different hashes.
  ///
  /// This can be used to verify that an implementation of `Object.hashCode`
  /// properly includes a given property as part of the hash computation, if
  /// that property can only take on two possible values.
  ///
  /// To avoid spurious failures due to the probabilistic nature of hashing,
  /// [generate] is called 10 times (passing 10 different integer values), and
  /// the test only fails if all 10 returned pairs have the same hash.
  void _testHashesSometimesDifferPairwise<T>((T, T) Function(int) generate) {
    for (var i = 1; i < 10; i++) {
      var (x, y) = generate(i);
      if (x.hashCode != y.hashCode) return;
      x = y;
    }
    fail('Hashes never differed');
  }
}
