// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapSubstitutionTest);
    defineReflectiveTests(SubstituteEmptyTest);
    defineReflectiveTests(SubstituteFromInterfaceTypeTest);
    defineReflectiveTests(SubstituteFromPairsTest);
    defineReflectiveTests(SubstituteTest);
    defineReflectiveTests(SubstituteWithNullabilityTest);
  });
}

/// Returns a type where all occurrences of the given type parameters have been
/// replaced with the corresponding types.
///
/// This will copy only the sub-terms of [type] that contain substituted
/// variables; all other [DartType] objects will be reused.
///
/// In particular, if no type parameters were substituted, this is guaranteed
/// to return the [type] instance (not a copy), so the caller may use
/// [identical] to efficiently check if a distinct type was created.
DartType substitute(
  DartType type,
  Map<TypeParameterElement, DartType> substitution,
) {
  if (substitution.isEmpty) {
    return type;
  }
  return Substitution.fromMap(substitution).substituteType(type);
}

@reflectiveTest
class MapSubstitutionTest extends _Base {
  test_andThen_empty_andThenNotEmpty() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      var after = Substitution.fromMap({T: scope.parseType('int')});

      var combined = Substitution.empty.andThen(after);
      expect(combined, same(Substitution.empty));
    });
  }

  test_andThen_notEmpty_andThenEmpty() {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      var inner = Substitution.fromMap({T: scope.parseType('int')});

      var combined = inner.andThen(Substitution.empty);
      expect(combined, same(inner));
    });
  }

  test_andThen_notEmpty_andThenNotEmpty() {
    withTypeParameterScope('T, G', (scope) {
      var T = scope.typeParameter('T');
      var G = scope.typeParameter('G');
      var inner = Substitution.fromMap({T: scope.parseType('List<G>')});
      var after = Substitution.fromMap({G: parseType('String')});

      var combined = inner.andThen(after);
      var result = combined.substituteType(scope.parseType('T'));
      assertType(result, 'List<String>');
    });
  }
}

@reflectiveTest
class SubstituteEmptyTest extends _Base {
  test_interface() async {
    // class A<T> {}
    buildTestLibrary(classes: [ClassSpec('class A<T>')]);

    var type = parseType('A<int>');

    var result = Substitution.empty.substituteType(type);
    expect(result, same(type));
  }
}

@reflectiveTest
class SubstituteFromInterfaceTypeTest extends _Base {
  test_methodReturnType() async {
    buildTestLibrary(
      classes: [
        ClassSpec('class A<T>', methods: [MethodSpec('List<T> foo()')]),
      ],
    );

    var substitution = Substitution.fromInterfaceType(
      parseInterfaceType('A<int>'),
    );

    var type = classElement('A').getMethod('foo')!.returnType;
    assertType(type, 'List<T>');

    var result = substitution.substituteType(type);
    assertType(result, 'List<int>');
  }
}

@reflectiveTest
class SubstituteFromPairsTest extends _Base {
  test_methodReturnType() async {
    buildTestLibrary(
      classes: [
        ClassSpec('class A<T, U>', methods: [MethodSpec('Map<T, U> foo()')]),
      ],
    );
    var A = classElement('A');
    var T = A.typeParameters[0];
    var U = A.typeParameters[1];

    var type = A.getMethod('foo')!.returnType;
    assertType(type, 'Map<T, U>');

    var result = Substitution.fromPairs2(
      [T, U],
      [parseType('int'), parseType('double')],
    ).substituteType(type);
    assertType(result, 'Map<int, double>');
  }
}

@reflectiveTest
class SubstituteTest extends _Base {
  test_bottom() async {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _assertIdenticalType(typeProvider.bottomType, {
        T: scope.parseType('int'),
      });
    });
  }

  test_dynamic() async {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _assertIdenticalType(typeProvider.dynamicType, {
        T: scope.parseType('int'),
      });
    });
  }

  test_function_fromAlias_hasRef() async {
    // typedef Alias<T> = void Function();
    buildTestLibrary(
      typeAliases: [TypeAliasSpec('typedef Alias<T> = void Function()')],
    );

    withTypeParameterScope('U', (scope) {
      var U = scope.typeParameter('U');
      var type = scope.parseType('Alias<U>');
      assertType(type, 'void Function() via Alias<U>');
      _assertSubstitution(type, {
        U: parseType('int'),
      }, 'void Function() via Alias<int>');
    });
  }

  test_function_fromAlias_noRef() async {
    // typedef Alias<T> = void Function();
    buildTestLibrary(
      typeAliases: [TypeAliasSpec('typedef Alias<T> = void Function()')],
    );

    var type = parseType('Alias<double>');
    assertType(type, 'void Function() via Alias<double>');

    withTypeParameterScope('U', (scope) {
      var U = scope.typeParameter('U');
      _assertIdenticalType(type, {U: scope.parseType('int')});
    });
  }

  test_function_fromAlias_noTypeParameters() async {
    // typedef Alias<T> = void Function();
    buildTestLibrary(
      typeAliases: [TypeAliasSpec('typedef Alias<T> = void Function()')],
    );

    var type = parseType('Alias<int>');
    assertType(type, 'void Function() via Alias<int>');

    withTypeParameterScope('U', (scope) {
      var U = scope.typeParameter('U');
      _assertIdenticalType(type, {U: scope.parseType('int')});
    });
  }

  test_function_noSubstitutions() async {
    var type = parseType('bool Function(int)');

    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _assertIdenticalType(type, {T: scope.parseType('int')});
    });
  }

  test_function_parameters_returnType() async {
    // typedef F<T, U> = T Function(U u, bool);
    withTypeParameterScope('T, U', (scope) {
      var T = scope.typeParameter('T');
      var U = scope.typeParameter('U');
      var type = scope.parseType('T Function(U, bool)');

      assertType(type, 'T Function(U, bool)');
      _assertSubstitution(type, {T: parseType('int')}, 'int Function(U, bool)');
      _assertSubstitution(type, {
        T: parseType('int'),
        U: parseType('double'),
      }, 'int Function(double, bool)');
    });
  }

  test_function_typeFormals() async {
    // typedef F<T> = T Function<U extends T>(U);
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      var type = scope.parseType('T Function<U extends T>(U)');

      assertType(type, 'T Function<U extends T>(U)');
      _assertSubstitution(type, {
        T: parseType('int'),
      }, 'int Function<U extends int>(U)');
    });
  }

  test_function_typeFormals_bounds() async {
    // class Triple<X, Y, Z> {}
    // typedef F<V> = bool Function<T extends Triple<T, U, V>, U>();
    buildTestLibrary(classes: [ClassSpec('class Triple<X, Y, Z>')]);

    withTypeParameterScope('V', (scope) {
      var V = scope.typeParameter('V');
      var type = scope.parseType(
        'bool Function<T extends Triple<T, U, V>, U>()',
      );

      assertType(type, 'bool Function<T extends Triple<T, U, V>, U>()');

      var result = substitute(type, {V: parseType('int')}) as FunctionType;
      assertType(result, 'bool Function<T extends Triple<T, U, int>, U>()');
      var T2 = result.typeParameters[0];
      var U2 = result.typeParameters[1];
      var T2boundArgs = (T2.bound as InterfaceType).typeArguments;
      expect((T2boundArgs[0] as TypeParameterType).element, same(T2));
      expect((T2boundArgs[1] as TypeParameterType).element, same(U2));
    });
  }

  test_interface_arguments() async {
    // class A<T> {}
    buildTestLibrary(classes: [ClassSpec('class A<T>')]);

    withTypeParameterScope('U', (scope) {
      var U = scope.typeParameter('U');
      var type = scope.parseType('A<U>');

      assertType(type, 'A<U>');
      _assertSubstitution(type, {U: parseType('int')}, 'A<int>');
    });
  }

  test_interface_arguments_deep() async {
    buildTestLibrary(classes: [ClassSpec('class A<T>')]);

    withTypeParameterScope('U', (scope) {
      var U = scope.typeParameter('U');
      var type = scope.parseType('A<List<U>>');
      assertType(type, 'A<List<U>>');

      _assertSubstitution(type, {U: parseType('int')}, 'A<List<int>>');
    });
  }

  test_interface_noArguments() async {
    // class A {}
    buildTestLibrary(classes: [ClassSpec('class A')]);

    var type = parseInterfaceType('A');
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _assertIdenticalType(type, {T: scope.parseType('int')});
    });
  }

  test_interface_noArguments_inArguments() async {
    // class A<T> {}
    buildTestLibrary(classes: [ClassSpec('class A<T>')]);

    var type = parseInterfaceType('A<int>');

    withTypeParameterScope('U', (scope) {
      var U = scope.typeParameter('U');
      _assertIdenticalType(type, {U: scope.parseType('double')});
    });
  }

  test_interface_noTypeParameters_fromAlias_hasRef() async {
    // class A {}
    buildTestLibrary(
      classes: [ClassSpec('class A')],
      typeAliases: [TypeAliasSpec('typedef Alias<T> = A')],
    );

    withTypeParameterScope('U', (scope) {
      var U = scope.typeParameter('U');
      var type = scope.parseType('Alias<U>');
      assertType(type, 'A via Alias<U>');
      _assertSubstitution(type, {U: parseType('int')}, 'A via Alias<int>');
    });
  }

  test_interface_noTypeParameters_fromAlias_noRef() async {
    // class A {}
    buildTestLibrary(
      classes: [ClassSpec('class A')],
      typeAliases: [TypeAliasSpec('typedef Alias<T> = A')],
    );

    var type = parseType('Alias<double>');
    assertType(type, 'A via Alias<double>');

    withTypeParameterScope('U', (scope) {
      var U = scope.typeParameter('U');
      _assertIdenticalType(type, {U: scope.parseType('int')});
    });
  }

  test_interface_noTypeParameters_fromAlias_noTypeParameters() async {
    // class A {}
    buildTestLibrary(
      classes: [ClassSpec('class A')],
      typeAliases: [TypeAliasSpec('typedef Alias = A')],
    );

    var type = parseType('Alias');
    assertType(type, 'A via Alias');

    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _assertIdenticalType(type, {T: scope.parseType('int')});
    });
  }

  test_invalid() async {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _assertIdenticalType(InvalidTypeImpl.instance, {
        T: scope.parseType('int'),
      });
    });
  }

  test_record_doesNotUseTypeParameter2() async {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      var type = parseRecordType('(int,)');
      assertType(type, '(int,)');

      _assertIdenticalType(type, {T: scope.parseType('int')});
    });
  }

  test_record_fromAlias() async {
    // typedef Alias<T> = (int, String);
    buildTestLibrary(
      typeAliases: [TypeAliasSpec('typedef Alias<T> = (int, String)')],
    );

    withTypeParameterScope('U', (scope) {
      var U = scope.typeParameter('U');
      var type = scope.parseType('Alias<U>');
      assertType(type, '(int, String) via Alias<U>');
      _assertSubstitution(type, {
        U: parseType('int'),
      }, '(int, String) via Alias<int>');
    });
  }

  test_record_fromAlias2() async {
    // typedef Alias<T> = (T, List<T>);
    buildTestLibrary(
      typeAliases: [TypeAliasSpec('typedef Alias<T> = (T, List<T>)')],
    );

    var type = parseType('Alias<int>');
    assertType(type, '(int, List<int>) via Alias<int>');
  }

  test_record_named() async {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      var type = scope.parseType('({T f1, List<T> f2})');

      assertType(type, '({T f1, List<T> f2})');
      _assertSubstitution(type, {
        T: parseType('int'),
      }, '({int f1, List<int> f2})');
    });
  }

  test_record_positional() async {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      var type = scope.parseType('(T, List<T>)');

      assertType(type, '(T, List<T>)');
      _assertSubstitution(type, {T: parseType('int')}, '(int, List<int>)');
    });
  }

  test_typeParameter_nullability() async {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');

      void check(String type, DartType typeArgument, DartType expectedType) {
        var result = Substitution.fromMap({
          T: typeArgument,
        }).substituteType(scope.parseType(type));
        expect(result, expectedType);
      }

      check('T', parseType('int'), parseType('int'));
      check('T', parseType('int?'), parseType('int?'));

      check('T?', parseType('int'), parseType('int?'));
      check('T?', parseType('int?'), parseType('int?'));
    });
  }

  test_unknownInferredType() async {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _assertIdenticalType(UnknownInferredType.instance, {
        T: scope.parseType('int'),
      });
    });
  }

  test_void() async {
    withTypeParameterScope('T', (scope) {
      var T = scope.typeParameter('T');
      _assertIdenticalType(typeProvider.voidType, {T: scope.parseType('int')});
    });
  }

  test_void_emptyMap() async {
    _assertIdenticalType(parseType('int'), {});
  }

  void _assertIdenticalType(
    DartType type,
    Map<TypeParameterElement, DartType> substitution,
  ) {
    var result = substitute(type, substitution);
    expect(result, same(type));
  }
}

@reflectiveTest
class SubstituteWithNullabilityTest extends _Base {
  SubstituteWithNullabilityTest();

  test_interface_none() async {
    // class A<T> {}
    buildTestLibrary(classes: [ClassSpec('class A<T>')]);

    withTypeParameterScope('U', (scope) {
      var U = scope.typeParameter('U');
      var type = scope.parseType('A<U>');
      _assertSubstitution(type, {U: parseType('int')}, 'A<int>');
    });
  }

  test_interface_question() async {
    // class A<T> {}
    buildTestLibrary(classes: [ClassSpec('class A<T>')]);

    withTypeParameterScope('U', (scope) {
      var U = scope.typeParameter('U');
      var type = scope.parseType('A<U>?');
      _assertSubstitution(type, {U: parseType('int')}, 'A<int>?');
    });
  }

  test_withNullability_updatesAlias_function() {
    buildTestLibrary(
      typeAliases: [TypeAliasSpec('typedef A = void Function()')],
    );
    var alias = typeAliasElement('A');
    var type = alias.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );

    var result = type.withNullability(NullabilitySuffix.none);
    expect(result.alias?.nullabilitySuffix, NullabilitySuffix.none);
    expect(result.getDisplayString(preferTypeAlias: true), 'A');
  }

  test_withNullability_updatesAlias_interface() {
    buildTestLibrary(typeAliases: [TypeAliasSpec('typedef A = int')]);
    var alias = typeAliasElement('A');
    var type = alias.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );

    var result = type.withNullability(NullabilitySuffix.none);
    expect(result.alias?.nullabilitySuffix, NullabilitySuffix.none);
    expect(result.getDisplayString(preferTypeAlias: true), 'A');
  }

  test_withNullability_updatesAlias_record() {
    buildTestLibrary(typeAliases: [TypeAliasSpec('typedef A = (int,)')]);
    var alias = typeAliasElement('A');
    var type = alias.instantiateImpl(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );

    var result = type.withNullability(NullabilitySuffix.none);
    expect(result.alias?.nullabilitySuffix, NullabilitySuffix.none);
    expect(result.getDisplayString(preferTypeAlias: true), 'A');
  }

  test_withNullability_updatesAlias_typeParameter() {
    buildTestLibrary(typeAliases: [TypeAliasSpec('typedef A<T> = T')]);
    var alias = typeAliasElement('A');

    withTypeParameterScope('U', (scope) {
      var type = alias.instantiateImpl(
        typeArguments: [scope.parseType('U')],
        nullabilitySuffix: NullabilitySuffix.question,
      );

      var result = type.withNullability(NullabilitySuffix.none);
      expect(result.alias, isNotNull);
      expect(result.alias?.nullabilitySuffix, NullabilitySuffix.none);
    });
  }
}

class _Base extends AbstractTypeSystemTest {
  void assertType(DartType type, String expected) {
    var typeStr = _typeStr(type);
    expect(typeStr, expected);
  }

  void _assertSubstitution(
    DartType type,
    Map<TypeParameterElement, DartType> substitution,
    String expected,
  ) {
    var result = substitute(type, substitution);
    assertType(result, expected);
    expect(result, isNot(same(type)));
  }

  static String _typeStr(DartType type) {
    var result = type.getDisplayString();

    var alias = type.alias;
    if (alias != null) {
      result += ' via ${alias.element.name}';
      var typeArgumentStrList = alias.typeArguments.map(_typeStr).toList();
      if (typeArgumentStrList.isNotEmpty) {
        result += '<${typeArgumentStrList.join(', ')}>';
      }
    }

    return result;
  }
}
