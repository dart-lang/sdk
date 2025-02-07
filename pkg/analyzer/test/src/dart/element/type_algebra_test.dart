// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubstituteEmptyTest);
    defineReflectiveTests(SubstituteFromInterfaceTypeTest);
    defineReflectiveTests(SubstituteFromPairsTest);
    defineReflectiveTests(SubstituteTest);
    defineReflectiveTests(SubstituteWithNullabilityTest);
  });
}

@reflectiveTest
class SubstituteEmptyTest extends _Base {
  test_interface() async {
    // class A<T> {}
    var T = typeParameter2('T');
    var A = class_2(name: 'A', typeParameters: [T]);

    var type = interfaceTypeNone(A, typeArguments: [intNone]);

    var result = Substitution.empty.substituteType(type);
    expect(result, same(type));
  }
}

@reflectiveTest
class SubstituteFromInterfaceTypeTest extends _Base {
  test_interface() async {
    // class A<T> {}
    var T = typeParameter2('T');
    var A = class_2(name: 'A', typeParameters: [T]);

    // class B<U>  {}
    var U = typeParameter2('U');
    var B = class_2(name: 'B', typeParameters: [U]);

    var BofInt = interfaceTypeNone(B, typeArguments: [intNone]);
    var substitution = Substitution.fromInterfaceType(BofInt);

    // A<U>
    var type = interfaceTypeNone(A, typeArguments: [typeParameterTypeNone2(U)]);
    assertType(type, 'A<U>');

    var result = substitution.substituteType(type);
    assertType(result, 'A<int>');
  }
}

@reflectiveTest
class SubstituteFromPairsTest extends _Base {
  test_interface() async {
    // class A<T, U> {}
    var T = typeParameter2('T');
    var U = typeParameter2('U');
    var A = class_2(name: 'A', typeParameters: [T, U]);

    var type = interfaceTypeNone(
      A,
      typeArguments: [
        typeParameterTypeNone2(T),
        typeParameterTypeNone2(U),
      ],
    );

    var result = Substitution.fromPairs2(
      [T, U],
      [intNone, doubleNone],
    ).substituteType(type);
    assertType(result, 'A<int, double>');
  }
}

@reflectiveTest
class SubstituteTest extends _Base {
  test_bottom() async {
    var T = typeParameter2('T');
    _assertIdenticalType(typeProvider.bottomType, {T: intNone});
  }

  test_dynamic() async {
    var T = typeParameter2('T');
    _assertIdenticalType(typeProvider.dynamicType, {T: intNone});
  }

  test_function_fromAlias_hasRef() async {
    // typedef Alias<T> = void Function();
    var T = typeParameter2('T');
    var Alias = typeAlias2(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: functionTypeNone2(
        returnType: voidNone,
      ),
    );

    var U = typeParameter2('U');
    var type = typeAliasTypeNone2(Alias, typeArguments: [
      typeParameterTypeNone2(U),
    ]);
    assertType(type, 'void Function() via Alias<U>');
    _assertSubstitution(type, {U: intNone}, 'void Function() via Alias<int>');
  }

  test_function_fromAlias_noRef() async {
    // typedef Alias<T> = void Function();
    var T = typeParameter2('T');
    var Alias = typeAlias2(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: functionTypeNone2(
        returnType: voidNone,
      ),
    );

    var type = typeAliasTypeNone2(Alias, typeArguments: [doubleNone]);
    assertType(type, 'void Function() via Alias<double>');

    var U = typeParameter2('U');
    _assertIdenticalType(type, {U: intNone});
  }

  test_function_fromAlias_noTypeParameters() async {
    // typedef Alias<T> = void Function();
    var T = typeParameter2('T');
    var Alias = typeAlias2(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: functionTypeNone2(
        returnType: voidNone,
      ),
    );

    var type = typeAliasTypeNone2(Alias, typeArguments: [intNone]);
    assertType(type, 'void Function() via Alias<int>');

    var U = typeParameter2('U');
    _assertIdenticalType(type, {U: intNone});
  }

  test_function_noSubstitutions() async {
    var type = functionTypeNone2(
      parameters: [
        requiredParameter2(type: intNone),
      ],
      returnType: boolNone,
    );

    var T = typeParameter2('T');
    _assertIdenticalType(type, {T: intNone});
  }

  test_function_parameters_returnType() async {
    // typedef F<T, U> = T Function(U u, bool);
    var T = typeParameter2('T');
    var U = typeParameter2('U');
    var type = functionTypeNone2(
      parameters: [
        requiredParameter2(type: typeParameterTypeNone2(U)),
        requiredParameter2(type: boolNone),
      ],
      returnType: typeParameterTypeNone2(T),
    );

    assertType(type, 'T Function(U, bool)');
    _assertSubstitution(
      type,
      {T: intNone},
      'int Function(U, bool)',
    );
    _assertSubstitution(
      type,
      {T: intNone, U: doubleNone},
      'int Function(double, bool)',
    );
  }

  test_function_typeFormals() async {
    // typedef F<T> = T Function<U extends T>(U);
    var T = typeParameter2('T');
    var U = typeParameter2('U', bound: typeParameterTypeNone2(T));
    var type = functionTypeNone2(
      typeFormals: [U],
      parameters: [
        requiredParameter2(type: typeParameterTypeNone2(U)),
      ],
      returnType: typeParameterTypeNone2(T),
    );

    assertType(type, 'T Function<U extends T>(U)');
    _assertSubstitution(
      type,
      {T: intNone},
      'int Function<U extends int>(U)',
    );
  }

  test_function_typeFormals_bounds() async {
    // class Triple<X, Y, Z> {}
    // typedef F<V> = bool Function<T extends Triplet<T, U, V>, U>();
    var classTriplet = class_2(name: 'Triple', typeParameters: [
      typeParameter2('X'),
      typeParameter2('Y'),
      typeParameter2('Z'),
    ]);

    var T = typeParameter2('T');
    var U = typeParameter2('U');
    var V = typeParameter2('V');

    T.firstFragment.bound = interfaceTypeNone(
      classTriplet,
      typeArguments: [
        typeParameterTypeNone2(T),
        typeParameterTypeNone2(U),
        typeParameterTypeNone2(V),
      ],
    );
    T.bound = T.firstFragment.bound;

    var type = functionTypeNone2(
      typeFormals: [T, U],
      returnType: boolNone,
    );

    assertType(
      type,
      'bool Function<T extends Triple<T, U, V>, U>()',
    );

    var result = substitute2(type, {V: intNone}) as FunctionType;
    assertType(
      result,
      'bool Function<T extends Triple<T, U, int>, U>()',
    );
    var T2 = result.typeParameters[0];
    var U2 = result.typeParameters[1];
    var T2boundArgs = (T2.bound as InterfaceType).typeArguments;
    expect((T2boundArgs[0] as TypeParameterType).element3, same(T2));
    expect((T2boundArgs[1] as TypeParameterType).element3, same(U2));
  }

  test_interface_arguments() async {
    // class A<T> {}
    var T = typeParameter2('T');
    var A = class_2(name: 'A', typeParameters: [T]);

    var U = typeParameter2('U');
    var type = interfaceTypeNone(A, typeArguments: [
      typeParameterTypeNone2(U),
    ]);

    assertType(type, 'A<U>');
    _assertSubstitution(type, {U: intNone}, 'A<int>');
  }

  test_interface_arguments_deep() async {
    var T = typeParameter2('T');
    var A = class_2(name: 'A', typeParameters: [T]);

    var U = typeParameter2('U');
    var type = interfaceTypeNone(A, typeArguments: [
      interfaceTypeNone(
        typeProvider.listElement,
        typeArguments: [
          typeParameterTypeNone2(U),
        ],
      )
    ]);
    assertType(type, 'A<List<U>>');

    _assertSubstitution(type, {U: intNone}, 'A<List<int>>');
  }

  test_interface_noArguments() async {
    // class A {}
    var A = class_2(name: 'A');

    var type = interfaceTypeNone(A);
    var T = typeParameter2('T');
    _assertIdenticalType(type, {T: intNone});
  }

  test_interface_noArguments_inArguments() async {
    // class A<T> {}
    var T = typeParameter2('T');
    var A = class_2(name: 'A', typeParameters: [T]);

    var type = interfaceTypeNone(A, typeArguments: [intNone]);

    var U = typeParameter2('U');
    _assertIdenticalType(type, {U: doubleNone});
  }

  test_interface_noTypeParameters_fromAlias_hasRef() async {
    // class A {}
    var A = class_2(name: 'A');

    // typedef Alias<T> = A;
    var T = typeParameter2('T');
    var Alias = typeAlias2(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: interfaceTypeNone(A),
    );

    var U = typeParameter2('U');
    var type = typeAliasTypeNone2(Alias, typeArguments: [
      typeParameterTypeNone2(U),
    ]);
    assertType(type, 'A via Alias<U>');
    _assertSubstitution(type, {U: intNone}, 'A via Alias<int>');
  }

  test_interface_noTypeParameters_fromAlias_noRef() async {
    // class A {}
    var A = class_2(name: 'A');

    // typedef Alias<T> = A;
    var T = typeParameter2('T');
    var Alias = typeAlias2(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: interfaceTypeNone(A),
    );

    var type = typeAliasTypeNone2(Alias, typeArguments: [doubleNone]);
    assertType(type, 'A via Alias<double>');

    var U = typeParameter2('U');
    _assertIdenticalType(type, {U: intNone});
  }

  test_interface_noTypeParameters_fromAlias_noTypeParameters() async {
    // class A {}
    var A = class_2(name: 'A');

    // typedef Alias = A;
    var Alias = typeAlias2(
      name: 'Alias',
      typeParameters: [],
      aliasedType: interfaceTypeNone(A),
    );

    var type = typeAliasTypeNone2(Alias);
    assertType(type, 'A via Alias');

    var T = typeParameter2('T');
    _assertIdenticalType(type, {T: intNone});
  }

  test_invalid() async {
    var T = typeParameter2('T');
    _assertIdenticalType(InvalidTypeImpl.instance, {T: intNone});
  }

  test_record_doesNotUseTypeParameter2() async {
    var T = typeParameter2('T');

    var type = recordTypeNone(
      positionalTypes: [intNone],
    );

    assertType(type, '(int,)');
    _assertIdenticalType(type, {T: intNone});
  }

  test_record_fromAlias() async {
    // typedef Alias<T> = (int, String);
    var T = typeParameter2('T');
    var Alias = typeAlias2(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: recordTypeNone(
        positionalTypes: [intNone, stringNone],
      ),
    );

    var U = typeParameter2('U');
    var type = typeAliasTypeNone2(Alias, typeArguments: [
      typeParameterTypeNone2(U),
    ]);
    assertType(type, '(int, String) via Alias<U>');
    _assertSubstitution(type, {U: intNone}, '(int, String) via Alias<int>');
  }

  test_record_fromAlias2() async {
    // typedef Alias<T> = (T, List<T>);
    var T = typeParameter2('T');
    var T_none = typeParameterTypeNone2(T);
    var Alias = typeAlias2(
      name: 'Alias',
      typeParameters: [T],
      aliasedType: recordTypeNone(
        positionalTypes: [
          T_none,
          listNone(T_none),
        ],
      ),
    );

    var type = typeAliasTypeNone2(Alias, typeArguments: [intNone]);
    assertType(type, '(int, List<int>) via Alias<int>');
  }

  test_record_named() async {
    var T = typeParameter2('T');
    var T_none = typeParameterTypeNone2(T);

    var type = recordTypeNone(
      namedTypes: {
        'f1': T_none,
        'f2': listNone(T_none),
      },
    );

    assertType(type, '({T f1, List<T> f2})');
    _assertSubstitution(type, {T: intNone}, '({int f1, List<int> f2})');
  }

  test_record_positional() async {
    var T = typeParameter2('T');
    var T_none = typeParameterTypeNone2(T);

    var type = recordTypeNone(
      positionalTypes: [
        T_none,
        listNone(T_none),
      ],
    );

    assertType(type, '(T, List<T>)');
    _assertSubstitution(type, {T: intNone}, '(int, List<int>)');
  }

  test_typeParameter_nullability() async {
    var tElement = typeParameter2('T');

    void check(
      NullabilitySuffix typeParameterNullability,
      InterfaceType typeArgument,
      InterfaceType expectedType,
    ) {
      var result = Substitution.fromMap2({
        tElement: typeArgument,
      }).substituteType(
        tElement.instantiate(
          nullabilitySuffix: typeParameterNullability,
        ),
      );
      expect(result, expectedType);
    }

    check(NullabilitySuffix.none, intNone, intNone);
    check(NullabilitySuffix.none, intQuestion, intQuestion);

    check(NullabilitySuffix.question, intNone, intQuestion);
    check(NullabilitySuffix.question, intQuestion, intQuestion);
  }

  test_unknownInferredType() async {
    var T = typeParameter2('T');
    _assertIdenticalType(UnknownInferredType.instance, {T: intNone});
  }

  test_void() async {
    var T = typeParameter2('T');
    _assertIdenticalType(typeProvider.voidType, {T: intNone});
  }

  test_void_emptyMap() async {
    _assertIdenticalType(intNone, {});
  }

  void _assertIdenticalType(
      DartType type, Map<TypeParameterElement2, DartType> substitution) {
    var result = substitute2(type, substitution);
    expect(result, same(type));
  }
}

@reflectiveTest
class SubstituteWithNullabilityTest extends _Base {
  SubstituteWithNullabilityTest();

  test_interface_none() async {
    // class A<T> {}
    var T = typeParameter2('T');
    var A = class_2(name: 'A', typeParameters: [T]);

    var U = typeParameter2('U');
    var type = A.instantiate(
      typeArguments: [
        U.instantiate(nullabilitySuffix: NullabilitySuffix.none),
      ],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    _assertSubstitution(type, {U: intNone}, 'A<int>');
  }

  test_interface_question() async {
    // class A<T> {}
    var T = typeParameter2('T');
    var A = class_2(name: 'A', typeParameters: [T]);

    var U = typeParameter2('U');
    var type = A.instantiate(
      typeArguments: [
        U.instantiate(nullabilitySuffix: NullabilitySuffix.none),
      ],
      nullabilitySuffix: NullabilitySuffix.question,
    );
    _assertSubstitution(type, {U: intNone}, 'A<int>?');
  }
}

class _Base extends AbstractTypeSystemTest {
  void assertType(DartType type, String expected) {
    var typeStr = _typeStr(type);
    expect(typeStr, expected);
  }

  void _assertSubstitution(
    DartType type,
    Map<TypeParameterElement2, DartType> substitution,
    String expected,
  ) {
    var result = substitute2(type, substitution);
    assertType(result, expected);
    expect(result, isNot(same(type)));
  }

  static String _typeStr(DartType type) {
    var result = type.getDisplayString();

    var alias = type.alias;
    if (alias != null) {
      result += ' via ${alias.element2.name3}';
      var typeArgumentStrList = alias.typeArguments.map(_typeStr).toList();
      if (typeArgumentStrList.isNotEmpty) {
        result += '<${typeArgumentStrList.join(', ')}>';
      }
    }

    return result;
  }
}
