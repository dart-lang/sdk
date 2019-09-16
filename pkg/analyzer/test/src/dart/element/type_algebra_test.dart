// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
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
  });
}

@reflectiveTest
class SubstituteEmptyTest extends _Base {
  test_interface() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var type = interfaceType(A, typeArguments: [intType]);

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

    var BofInt = interfaceType(B, typeArguments: [intType]);
    var substitution = Substitution.fromInterfaceType(BofInt);

    // A<U>
    var type = interfaceType(A, typeArguments: [typeParameterType(U)]);
    assertElementTypeString(type, 'A<U>');

    var result = substitution.substituteType(type);
    assertElementTypeString(result, 'A<int>');
  }
}

@reflectiveTest
class SubstituteFromPairsTest extends _Base {
  test_interface() async {
    // class A<T, U> {}
    var T = typeParameter('T');
    var U = typeParameter('U');
    var A = class_(name: 'A', typeParameters: [T, U]);

    var type = interfaceType(
      A,
      typeArguments: [
        typeParameterType(T),
        typeParameterType(U),
      ],
    );

    var result = Substitution.fromPairs(
      [T, U],
      [intType, doubleType],
    ).substituteType(type);
    assertElementTypeString(result, 'A<int, double>');
  }
}

@reflectiveTest
class SubstituteFromUpperAndLowerBoundsTest extends _Base {
  test_function() async {
    // T Function(T)
    var T = typeParameter('T');
    var type = functionType(
      required: [typeParameterType(T)],
      returns: typeParameterType(T),
    );

    var result = Substitution.fromUpperAndLowerBounds(
      {T: typeProvider.intType},
      {T: BottomTypeImpl.instance},
    ).substituteType(type);
    expect(result.toString(), 'int Function(Never)');
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

  test_function_noTypeParameters() async {
    var type = functionType(required: [intType], returns: boolType);

    var T = typeParameter('T');
    _assertIdenticalType(type, {T: intType});
  }

  test_function_typeFormals() async {
    // typedef F<T> = T Function<U extends T>(U);
    var T = typeParameter('T');
    var U = typeParameter('U', bound: typeParameterType(T));
    var type = functionType(
      typeFormals: [U],
      required: [
        typeParameterType(U),
      ],
      returns: typeParameterType(T),
    );

    assertElementTypeString(type, 'T Function<U extends T>(U)');
    _assertSubstitution(
      type,
      {T: intType},
      'int Function<U extends int>(U)',
    );
  }

  test_function_typeParameters() async {
    // typedef F<T, U> = T Function(U u, bool);
    var T = typeParameter('T');
    var U = typeParameter('U');
    var type = functionType(
      required: [
        typeParameterType(U),
        boolType,
      ],
      returns: typeParameterType(T),
    );

    assertElementTypeString(type, 'T Function(U, bool)');
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

  test_interface_arguments() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = interfaceType(A, typeArguments: [
      typeParameterType(U),
    ]);

    assertElementTypeString(type, 'A<U>');
    _assertSubstitution(type, {U: intType}, 'A<int>');
  }

  test_interface_arguments_deep() async {
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var U = typeParameter('U');
    var type = interfaceType(A, typeArguments: [
      interfaceType(
        typeProvider.listType.element,
        typeArguments: [
          typeParameterType(U),
        ],
      )
    ]);
    assertElementTypeString(type, 'A<List<U>>');

    _assertSubstitution(type, {U: intType}, 'A<List<int>>');
  }

  test_interface_noArguments() async {
    // class A {}
    var A = class_(name: 'A');

    var type = interfaceType(A);
    var T = typeParameter('T');
    _assertIdenticalType(type, {T: intType});
  }

  test_interface_noArguments_inArguments() async {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    var type = interfaceType(A, typeArguments: [intType]);

    var U = typeParameter('U');
    _assertIdenticalType(type, {U: doubleType});
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

  void _assertSubstitution(
    DartType type,
    Map<TypeParameterElement, DartType> substitution,
    String expected,
  ) {
    var result = substitute(type, substitution);
    assertElementTypeString(result, expected);
  }
}

class _Base with ElementsTypesMixin {
  final typeProvider = TestTypeProvider();

  InterfaceType get boolType => typeProvider.boolType;

  InterfaceType get doubleType => typeProvider.doubleType;

  InterfaceType get intType => typeProvider.intType;

  /// Whether `DartType.toString()` with nullability should be asked.
  bool get typeToStringWithNullability => false;

  void assertElementTypeString(DartType type, String expected) {
    TypeImpl typeImpl = type;
    expect(typeImpl.toString(withNullability: typeToStringWithNullability),
        expected);
  }
}
