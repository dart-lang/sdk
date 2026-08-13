// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
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
  final Map<String, InterfaceTypeImpl> _classTypes = {};

  ClassElement get listElement => typeProvider.listElement;

  ClassElement get mapElement => typeProvider.mapElement;

  InterfaceTypeImpl get objectType => typeProvider.objectType;

  void basicChecks(
    FunctionType f, {
    displayName = 'dynamic Function()',
    returnType = 'dynamic',
    namedParameterTypes = isEmpty,
    normalParameterNames = isEmpty,
    normalParameterTypes = isEmpty,
    optionalParameterNames = isEmpty,
    optionalParameterTypes = isEmpty,
    parameters = isEmpty,
    typeFormals = isEmpty,
  }) {
    // DartType properties
    expect(f.getDisplayString(), displayName, reason: 'displayName');
    // FunctionType properties
    expect(
      f.namedParameterTypes.map((name, type) {
        return MapEntry(name, _typeStr(type));
      }),
      namedParameterTypes,
      reason: 'namedParameterTypes',
    );
    expect(
      f.formalParameters
          .where((parameter) => parameter.isRequiredPositional)
          .map((parameter) => parameter.name)
          .toList(),
      normalParameterNames,
      reason: 'normalParameterNames',
    );
    expect(
      f.normalParameterTypes.map(_typeStr).toList(),
      normalParameterTypes,
      reason: 'normalParameterTypes',
    );
    expect(
      f.formalParameters
          .where((parameter) => parameter.isOptionalPositional)
          .map((parameter) => parameter.name)
          .toList(),
      optionalParameterNames,
      reason: 'optionalParameterNames',
    );
    expect(
      f.optionalParameterTypes.map(_typeStr).toList(),
      optionalParameterTypes,
      reason: 'optionalParameterTypes',
    );
    expect(f.formalParameters, parameters, reason: 'parameters');
    expect(_typeStr(f.returnType), returnType, reason: 'returnType');
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
    var f1 = parseFunctionType('void Function(int a)');
    var f2 = parseFunctionType('void Function([int a])');
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_differentName() {
    var f1 = parseFunctionType('void Function({int a})');
    var f2 = parseFunctionType('void Function({int b})');
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_differentType() {
    var f1 = parseFunctionType('void Function({int a})');
    var f2 = parseFunctionType('void Function({double a})');
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_equal() {
    var f1 = parseFunctionType('void Function({int a, double b})');
    var f2 = parseFunctionType('void Function({int a, double b})');
    expect(f1, f2);
  }

  test_equality_namedParameters_extraLeft() {
    var f1 = parseFunctionType('void Function({int a, double b})');
    var f2 = parseFunctionType('void Function({int a})');
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_extraRight() {
    var f1 = parseFunctionType('void Function({int a})');
    var f2 = parseFunctionType('void Function({int a, double b})');
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_required_left() {
    var f1 = parseFunctionType('void Function({required int a})');
    var f2 = parseFunctionType('void Function({int a})');
    expect(f1, isNot(equals(f2)));
  }

  test_equality_namedParameters_required_right() {
    var f1 = parseFunctionType('void Function({int a})');
    var f2 = parseFunctionType('void Function({required int a})');
    expect(f1, isNot(equals(f2)));
  }

  test_equality_requiredParameters_extraLeft() {
    var f1 = parseFunctionType('void Function(int a, double b)');
    var f2 = parseFunctionType('void Function(int a)');
    expect(f1, isNot(equals(f2)));
  }

  test_equality_requiredParameters_extraRight() {
    var f1 = parseFunctionType('void Function(int a)');
    var f2 = parseFunctionType('void Function(int a, double b)');
    expect(f1, isNot(equals(f2)));
  }

  test_hash_namedParameterOptionality() {
    _testHashesSometimesDifferPairwise(
      (i) => (
        parseFunctionType('void Function({int p$i})'),
        parseFunctionType('void Function({required int p$i})'),
      ),
    );
  }

  test_hash_nullabilitySuffix() {
    _testHashesSometimesDifferPairwise((i) {
      _classType('C$i');
      return (
        parseFunctionType('void Function(C$i x)'),
        parseFunctionType('void Function(C$i x)?'),
      );
    });
  }

  test_hash_optionalNamedParameterName() {
    _testHashesSometimesDiffer(
      (i) => parseFunctionType('void Function({int p$i})'),
    );
  }

  test_hash_optionalNamedParameterType() {
    _testHashesSometimesDiffer((i) {
      _classType('C$i');
      return parseFunctionType('void Function({C$i x})');
    });
  }

  test_hash_optionalPositionalParameterName() {
    // Optional parameter names are irrelevant
    _testHashesAlwaysEqual(
      (i) => parseFunctionType('void Function([int p$i])'),
    );
  }

  test_hash_optionalPositionalParameterType() {
    _testHashesAlwaysEqual((i) {
      _classType('C$i');
      return parseFunctionType('void Function([C$i x])');
    });
  }

  test_hash_positionalParameterOptionality() {
    _testHashesSometimesDifferPairwise(
      (i) => (
        parseFunctionType('void Function(int p$i)'),
        parseFunctionType('void Function([int p$i])'),
      ),
    );
  }

  test_hash_requiredNamedParameterName() {
    _testHashesSometimesDiffer(
      (i) => parseFunctionType('void Function({required int p$i})'),
    );
  }

  test_hash_requiredNamedParameterType() {
    _testHashesSometimesDiffer((i) {
      _classType('C$i');
      return parseFunctionType('void Function({required C$i x})');
    });
  }

  test_hash_requiredPositionalParameterName() {
    // Required parameter names are irrelevant
    _testHashesAlwaysEqual((i) => parseFunctionType('void Function(int p$i)'));
  }

  test_hash_requiredPositionalParameterType() {
    _testHashesAlwaysEqual((i) {
      _classType('C$i');
      return parseFunctionType('void Function(C$i x)');
    });
  }

  test_hash_returnType() {
    _testHashesSometimesDiffer((i) {
      _classType('C$i');
      return parseFunctionType('C$i Function()');
    });
  }

  test_hash_typeFormalNames() {
    _testHashesAlwaysEqual(
      (i) => parseFunctionType('void Function<T$i, U$i>(T$i x, T$i y)'),
    );
  }

  test_new_sortsNamedParameters() {
    var f = parseFunctionType('void Function(int a, {int c, int b})');
    var parameters = f.formalParameters;
    expect(parameters, hasLength(3));
    expect(parameters[0].name, 'a');
    expect(parameters[1].name, 'b');
    expect(parameters[2].name, 'c');
  }

  test_synthetic() {
    FunctionType f = parseFunctionType('dynamic Function()');
    basicChecks(f);
  }

  test_synthetic_instantiate() {
    // T Function<T>(T x)
    FunctionType f = parseFunctionType('T Function<T>(T x)');
    FunctionType instantiated = f.instantiate([objectType]);
    basicChecks(
      instantiated,
      displayName: 'Object Function(Object)',
      returnType: 'Object',
      normalParameterNames: ['x'],
      normalParameterTypes: ['Object'],
      parameters: hasLength(1),
    );
  }

  test_synthetic_instantiate_argument_length_mismatch() {
    // dynamic Function<T>()
    FunctionType f = parseFunctionType('dynamic Function<T>()');
    expect(() => f.instantiate([]), throwsA(TypeMatcher<ArgumentError>()));
  }

  test_synthetic_instantiate_no_type_formals() {
    FunctionType f = parseFunctionType('dynamic Function()');
    expect(f.instantiate([]), same(f));
  }

  test_synthetic_namedParameter() {
    FunctionType f = parseFunctionType('dynamic Function({Object x})');
    basicChecks(
      f,
      displayName: 'dynamic Function({Object x})',
      namedParameterTypes: {'x': 'Object'},
      parameters: hasLength(1),
    );
    expect(f.formalParameters[0].isNamed, isTrue);
    expect(f.formalParameters[0].name, 'x');
    expect(_typeStr(f.formalParameters[0].type), 'Object');
  }

  test_synthetic_normalParameter() {
    FunctionType f = parseFunctionType('dynamic Function(Object x)');
    basicChecks(
      f,
      displayName: 'dynamic Function(Object)',
      normalParameterNames: ['x'],
      normalParameterTypes: ['Object'],
      parameters: hasLength(1),
    );
    expect(f.formalParameters[0].isRequiredPositional, isTrue);
    expect(f.formalParameters[0].name, 'x');
    expect(_typeStr(f.formalParameters[0].type), 'Object');
  }

  test_synthetic_optionalParameter() {
    FunctionType f = parseFunctionType('dynamic Function([Object x])');
    basicChecks(
      f,
      displayName: 'dynamic Function([Object])',
      optionalParameterNames: ['x'],
      optionalParameterTypes: ['Object'],
      parameters: hasLength(1),
    );
    expect(f.formalParameters[0].isOptionalPositional, isTrue);
    expect(f.formalParameters[0].name, 'x');
    expect(_typeStr(f.formalParameters[0].type), 'Object');
  }

  test_synthetic_returnType() {
    FunctionType f = parseFunctionType('Object Function()');
    basicChecks(f, displayName: 'Object Function()', returnType: 'Object');
  }

  test_synthetic_typeFormals() {
    FunctionType f = parseFunctionType('T Function<T>()');
    var t = f.typeParameters.single;
    basicChecks(
      f,
      displayName: 'T Function<T>()',
      returnType: 'T',
      typeFormals: [same(t)],
    );
    expect((f.returnType as TypeParameterType).element, same(t));
  }

  InterfaceTypeImpl _classType(String name) {
    return _classTypes.putIfAbsent(name, () {
      buildTestLibrary(classes: [ClassSpec('class $name')]);
      return classElement(name).thisType;
    });
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
    }
    fail('Hashes never differed');
  }

  String _typeStr(DartType type) => type.getDisplayString();
}
