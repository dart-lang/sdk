// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubstituteEmptyTest);
    defineReflectiveTests(SubstituteFromInterfaceTypeTest);
    defineReflectiveTests(SubstituteFromPairsTest);
    defineReflectiveTests(SubstituteFromUpperAndLowerBoundsTest);
    defineReflectiveTests(SubstituteTest);
    defineReflectiveTests(SubstituteWithNullabilityTest);
  });
}

@reflectiveTest
class SubstituteEmptyTest extends _Base {
  test_interface() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var type = interfaceTypeStar(A, typeArguments: [intType]);

    var result = Substitution.empty.substituteType(type);
    expect(result, same(type));
  }
}

@reflectiveTest
class SubstituteFromInterfaceTypeTest extends _Base {
  test_interface() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    // class B<U>  {}
    var U = typeParameter('U');
    var B = class_(name: 'B', typeParameters: [U]);

    var BofInt = interfaceTypeStar(B, typeArguments: [intType]);
    var substitution = Substitution.fromInterfaceType(BofInt);

    // A<U>
    var type = interfaceTypeStar(A, typeArguments: [typeParameterTypeStar(U)]);
    assertType(type, 'A<U>');

    var result = substitution.substituteType(type);
    assertType(result, 'A<int>');
  }
}

@reflectiveTest
class SubstituteFromPairsTest extends _Base {
  test_interface() async {
    // class A<T, U> {}
    var T = typeParameter('T');
    var U = typeParameter('U');
    var A = class_(name: 'A', typeParameters: [T, U]);

    var type = interfaceTypeStar(
      A,
      typeArguments: [
        typeParameterTypeStar(T),
        typeParameterTypeStar(U),
      ],
    );

    var result = Substitution.fromPairs(
      [T, U],
      [intType, doubleType],
    ).substituteType(type);
    assertType(result, 'A<int, double>');
  }
}

@reflectiveTest
class SubstituteFromUpperAndLowerBoundsTest extends _Base {
  test_function() async {
    // T Function(T)
    var T = typeParameter('T');
    var type = functionTypeStar(
      parameters: [
        requiredParameter(type: typeParameterTypeStar(T)),
      ],
      returnType: typeParameterTypeStar(T),
    );

    var result = Substitution.fromUpperAndLowerBounds(
      {T: typeProvider.intType},
      {T: NeverTypeImpl.instance},
    ).substituteType(type);
    assertType(result, 'int Function(Never)');
  }
}

@reflectiveTest
class SubstituteTest extends _Base {
  test_bottom() async {
    var T = typeParameter('T');
    _assertIdenticalType(typeProvider.bottomType, {T: intType});
  }

  test_dynamic() async {
    var T = typeParameter('T');
    _assertIdenticalType(typeProvider.dynamicType, {T: intType});
  }

  test_function_noSubstitutions() async {
    var type = functionTypeStar(
      parameters: [
        requiredParameter(type: intType),
      ],
      returnType: boolType,
    );

    var T = typeParameter('T');
    _assertIdenticalType(type, {T: intType});
  }

  test_function_parameters_returnType() async {
    // typedef F<T, U> = T Function(U u, bool);
    var T = typeParameter('T');
    var U = typeParameter('U');
    var type = functionTypeStar(
      parameters: [
        requiredParameter(type: typeParameterTypeStar(U)),
        requiredParameter(type: boolType),
      ],
      returnType: typeParameterTypeStar(T),
    );

    assertType(type, 'T Function(U, bool)');
    _assertSubstitution(
      type,
      {T: intType},
      'int Function(U, bool)',
    );
    _assertSubstitution(
      type,
      {T: intType, U: doubleType},
      'int Function(double, bool)',
    );
  }

  test_function_typeFormals() async {
    // typedef F<T> = T Function<U extends T>(U);
    var T = typeParameter('T');
    var U = typeParameter('U', bound: typeParameterTypeStar(T));
    var type = functionTypeStar(
      typeFormals: [U],
      parameters: [
        requiredParameter(type: typeParameterTypeStar(U)),
      ],
      returnType: typeParameterTypeStar(T),
    );

    assertType(type, 'T Function<U extends T>(U)');
    _assertSubstitution(
      type,
      {T: intType},
      'int Function<U extends int>(U)',
    );
  }

  test_function_typeFormals_bounds() async {
    // class Triple<X, Y, Z> {}
    // typedef F<V> = bool Function<T extends Triplet<T, U, V>, U>();
    var classTriplet = class_(name: 'Triple', typeParameters: [
      typeParameter('X'),
      typeParameter('Y'),
      typeParameter('Z'),
    ]);

    var T = typeParameter('T');
    var U = typeParameter('U');
    var V = typeParameter('V');
    T.bound = interfaceTypeStar(classTriplet, typeArguments: [
      typeParameterTypeStar(T),
      typeParameterTypeStar(U),
      typeParameterTypeStar(V),
    ]);
    var type = functionTypeStar(
      typeFormals: [T, U],
      returnType: boolType,
    );

    assertType(
      type,
      'bool Function<T extends Triple<T, U, V>, U>()',
    );

    var result = substitute(type, {V: intType}) as FunctionType;
    assertType(
      result,
      'bool Function<T extends Triple<T, U, int>, U>()',
    );
    var T2 = result.typeFormals[0];
    var U2 = result.typeFormals[1];
    var T2boundArgs = (T2.bound as InterfaceType).typeArguments;
    expect((T2boundArgs[0] as TypeParameterType).element, same(T2));
    expect((T2boundArgs[1] as TypeParameterType).element, same(U2));
  }

  test_interface_arguments() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = interfaceTypeStar(A, typeArguments: [
      typeParameterTypeStar(U),
    ]);

    assertType(type, 'A<U>');
    _assertSubstitution(type, {U: intType}, 'A<int>');
  }

  test_interface_arguments_deep() async {
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = interfaceTypeStar(A, typeArguments: [
      interfaceTypeStar(
        typeProvider.listElement,
        typeArguments: [
          typeParameterTypeStar(U),
        ],
      )
    ]);
    assertType(type, 'A<List<U>>');

    _assertSubstitution(type, {U: intType}, 'A<List<int>>');
  }

  test_interface_noArguments() async {
    // class A {}
    var A = class_(name: 'A');

    var type = interfaceTypeStar(A);
    var T = typeParameter('T');
    _assertIdenticalType(type, {T: intType});
  }

  test_interface_noArguments_inArguments() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var type = interfaceTypeStar(A, typeArguments: [intType]);

    var U = typeParameter('U');
    _assertIdenticalType(type, {U: doubleType});
  }

  test_typeParameter_nullability() async {
    var tElement = typeParameter('T');

    void check(
      NullabilitySuffix typeParameterNullability,
      InterfaceTypeImpl typeArgument,
      InterfaceTypeImpl expectedType,
    ) {
      var result = Substitution.fromMap(
        {tElement: typeArgument},
      ).substituteType(
        TypeParameterTypeImpl(
          element: tElement,
          nullabilitySuffix: typeParameterNullability,
        ),
      );
      expect(result, expectedType);
    }

    check(NullabilitySuffix.none, intNone, intNone);
    check(NullabilitySuffix.none, intStar, intStar);
    check(NullabilitySuffix.none, intQuestion, intQuestion);

    check(NullabilitySuffix.star, intNone, intStar);
    check(NullabilitySuffix.star, intStar, intStar);
    check(NullabilitySuffix.star, intQuestion, intQuestion);

    check(NullabilitySuffix.question, intNone, intQuestion);
    check(NullabilitySuffix.question, intStar, intQuestion);
    check(NullabilitySuffix.question, intQuestion, intQuestion);
  }

  test_unknownInferredType() async {
    var T = typeParameter('T');
    _assertIdenticalType(UnknownInferredType.instance, {T: intType});
  }

  test_void() async {
    var T = typeParameter('T');
    _assertIdenticalType(typeProvider.voidType, {T: intType});
  }

  test_void_emptyMap() async {
    _assertIdenticalType(intType, {});
  }

  void _assertIdenticalType(
      DartType type, Map<TypeParameterElement, DartType> substitution) {
    var result = substitute(type, substitution);
    expect(result, same(type));
  }
}

@reflectiveTest
class SubstituteWithNullabilityTest extends _Base {
  SubstituteWithNullabilityTest() : super(useNnbd: true);

  test_interface_none() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = A.instantiate(
      typeArguments: [
        U.instantiate(nullabilitySuffix: NullabilitySuffix.none),
      ],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    _assertSubstitution(type, {U: intType}, 'A<int>');
  }

  test_interface_question() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = A.instantiate(
      typeArguments: [
        U.instantiate(nullabilitySuffix: NullabilitySuffix.none),
      ],
      nullabilitySuffix: NullabilitySuffix.question,
    );
    _assertSubstitution(type, {U: intType}, 'A<int>?');
  }

  test_interface_star() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = A.instantiate(
      typeArguments: [
        U.instantiate(nullabilitySuffix: NullabilitySuffix.none),
      ],
      nullabilitySuffix: NullabilitySuffix.star,
    );
    _assertSubstitution(type, {U: intType}, 'A<int>*');
  }
}

class _Base with ElementsTypesMixin {
  @override
  final TestTypeProvider typeProvider = TestTypeProvider();

  /// TODO(scheglov) remove it
  final bool useNnbd;

  _Base({this.useNnbd = false});

  InterfaceType get boolType => typeProvider.boolType;

  InterfaceType get doubleType => typeProvider.doubleType;

  InterfaceType get intType => typeProvider.intType;

  /// Whether `DartType.toString()` with nullability should be asked.
  bool get typeToStringWithNullability => useNnbd;

  void assertType(DartType type, String expected) {
    var typeStr = type.getDisplayString(
      withNullability: typeToStringWithNullability,
    );
    expect(typeStr, expected);
  }

  void _assertSubstitution(
    DartType type,
    Map<TypeParameterElement, DartType> substitution,
    String expected,
  ) {
    var result = substitute(type, substitution);
    assertType(result, expected);
  }
}
