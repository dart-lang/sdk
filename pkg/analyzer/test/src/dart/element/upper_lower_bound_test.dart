// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/test_utilities/test_library_builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BoundsHelperPredicatesTest);
    defineReflectiveTests(LowerBoundTest);
    defineReflectiveTests(UpperBound_FunctionTypes_Test);
    defineReflectiveTests(UpperBound_InterfaceTypes_Test);
    defineReflectiveTests(UpperBound_RecordTypes_Test);
    defineReflectiveTests(UpperBoundTest);
  });
}

@reflectiveTest
class BoundsHelperPredicatesTest extends _BoundsTestBase {
  static final Map<String, StackTrace> _isMoreBottomChecked = {};
  static final Map<String, StackTrace> _isMoreTopChecked = {};

  void isBottom(TypeImpl type) {
    expect(type.isBottom, isTrue, reason: '$type');
  }

  void isMoreBottom(TypeImpl T, TypeImpl S) {
    _assertIsBottomOrNull(T);
    _assertIsBottomOrNull(S);

    var str = '$T vs $S';
    _checkUniqueTypeStr(_isMoreBottomChecked, str);

    expect(typeSystem.isMoreBottom(T, S), isTrue, reason: str);
  }

  void isMoreTop(TypeImpl T, TypeImpl S) {
    _assertIsTopOrObject(T);
    _assertIsTopOrObject(S);

    var str = '$T vs $S';
    _checkUniqueTypeStr(_isMoreTopChecked, str);

    expect(typeSystem.isMoreTop(T, S), isTrue, reason: str);
  }

  void isNotBottom(TypeImpl type) {
    expect(type.isBottom, isFalse, reason: '$type');
  }

  void isNotMoreBottom(TypeImpl T, TypeImpl S) {
    _assertIsBottomOrNull(T);
    _assertIsBottomOrNull(S);

    var str = '$T vs $S';
    _checkUniqueTypeStr(_isMoreBottomChecked, str);

    expect(typeSystem.isMoreBottom(T, S), isFalse, reason: str);
  }

  void isNotMoreTop(TypeImpl T, TypeImpl S) {
    _assertIsTopOrObject(T);
    _assertIsTopOrObject(S);

    var str = '$T vs $S';
    _checkUniqueTypeStr(_isMoreTopChecked, str);

    expect(typeSystem.isMoreTop(T, S), isFalse, reason: str);
  }

  void isNotNull(TypeImpl type) {
    expect(typeSystem.isNull(type), isFalse, reason: '$type');
  }

  void isNotObject(TypeImpl type) {
    expect(typeSystem.isObject(type), isFalse, reason: '$type');
  }

  void isNotTop(TypeImpl type) {
    expect(typeSystem.isTop(type), isFalse, reason: '$type');
  }

  void isNull(TypeImpl type) {
    expect(typeSystem.isNull(type), isTrue, reason: '$type');
  }

  void isObject(TypeImpl type) {
    expect(typeSystem.isObject(type), isTrue, reason: '$type');
  }

  void isTop(TypeImpl type) {
    expect(typeSystem.isTop(type), isTrue, reason: '$type');
  }

  test_isBottom() {
    // BOTTOM(Never) is true
    isBottom(parseType('Never'));
    isNotBottom(parseType('Never?'));

    // BOTTOM(X&T) is true iff BOTTOM(T)
    withTypeParameterScope('T extends Object?', (scope) {
      isBottom(scope.parseType('T & Never'));
      isNotBottom(scope.parseType('(T & Never)?'));
      isNotBottom(scope.parseType('T & Never?'));
      isNotBottom(scope.parseType('(T & Never?)?'));
    });

    // BOTTOM(X extends T) is true iff BOTTOM(T)
    withTypeParameterScope('T extends Never', (scope) {
      isBottom(scope.parseType('T'));
      isNotBottom(scope.parseType('T?'));
    });

    withTypeParameterScope('T extends Never?', (scope) {
      isNotBottom(scope.parseType('T'));
      isNotBottom(scope.parseType('T?'));
    });

    // BOTTOM(T) is false otherwise
    isNotBottom(parseType('dynamic'));
    isNotBottom(parseType('InvalidType'));
    isNotBottom(parseType('void'));

    isNotBottom(parseType('Object'));
    isNotBottom(parseType('Object?'));

    isNotBottom(parseType('int'));
    isNotBottom(parseType('int?'));

    withTypeParameterScope('T extends num', (scope) {
      isNotBottom(scope.parseType('T'));
      isNotBottom(scope.parseType('T?'));
      isNotBottom(scope.parseType('T & int'));
      isNotBottom(scope.parseType('(T & int)?'));
    });
  }

  test_isMoreBottom() {
    // MOREBOTTOM(Never, T) = true
    isMoreBottom(parseType('Never'), parseType('Never'));
    isMoreBottom(parseType('Never'), parseType('Never?'));

    isMoreBottom(parseType('Never'), parseType('Null'));

    // MOREBOTTOM(T, Never) = false
    isNotMoreBottom(parseType('Never?'), parseType('Never'));

    isNotMoreBottom(parseType('Null'), parseType('Never'));

    // MOREBOTTOM(Null, T) = true
    isMoreBottom(parseType('Null'), parseType('Never?'));

    isMoreBottom(parseType('Null'), parseType('Null'));

    // MOREBOTTOM(T, Null) = false
    isNotMoreBottom(parseType('Never?'), parseType('Null'));

    // MOREBOTTOM(X&T, Y&S) = MOREBOTTOM(T, S)
    withTypeParameterScope('T extends Object?, S extends Object?', (scope) {
      isMoreBottom(
        scope.parseType('T & Never'),
        scope.parseType('(S & Never)?'),
      );
    });

    // MOREBOTTOM(X&T, S) = true
    withTypeParameterScope('T extends Object?, S extends Never', (scope) {
      isMoreBottom(scope.parseType('T & Never'), scope.parseType('S'));
    });

    // MOREBOTTOM(T, X&S) = false
    withTypeParameterScope('T extends Never, S extends Object?', (scope) {
      isNotMoreBottom(scope.parseType('T'), scope.parseType('S & Never'));
    });

    // MOREBOTTOM(X extends T, Y extends S) = MOREBOTTOM(T, S)
    withTypeParameterScope('T extends Never, S extends Never', (scope) {
      isMoreBottom(scope.parseType('T'), scope.parseType('S?'));
    });
  }

  test_isMoreTop() {
    // MORETOP(void, T) = true
    isMoreTop(parseType('void'), parseType('void'));
    isMoreTop(parseType('void'), parseType('dynamic'));
    isMoreTop(parseType('void'), parseType('InvalidType'));
    isMoreTop(parseType('void'), parseType('Object'));
    isMoreTop(parseType('void'), parseType('Object?'));
    isMoreTop(parseType('void'), parseType('FutureOr<Object>'));
    isMoreTop(parseType('void'), parseType('FutureOr<Object?>'));

    // MORETOP(T, void) = false
    isNotMoreTop(parseType('dynamic'), parseType('void'));
    isNotMoreTop(parseType('InvalidType'), parseType('void'));
    isNotMoreTop(parseType('Object'), parseType('void'));
    isNotMoreTop(parseType('Object?'), parseType('void'));
    isNotMoreTop(parseType('FutureOr<Object>'), parseType('void'));
    isNotMoreTop(parseType('FutureOr<Object?>'), parseType('void'));

    // MORETOP(dynamic, T) = true
    isMoreTop(parseType('dynamic'), parseType('dynamic'));
    isMoreTop(parseType('dynamic'), parseType('Object'));
    isMoreTop(parseType('dynamic'), parseType('Object?'));
    isMoreTop(parseType('dynamic'), parseType('FutureOr<Object>'));
    isMoreTop(parseType('dynamic'), parseType('FutureOr<Object?>'));

    // MORETOP(parseType('InvalidType'), T) = true
    isMoreTop(parseType('InvalidType'), parseType('dynamic'));
    isMoreTop(parseType('InvalidType'), parseType('Object'));
    isMoreTop(parseType('InvalidType'), parseType('Object?'));
    isMoreTop(parseType('InvalidType'), parseType('FutureOr<Object>'));
    isMoreTop(parseType('InvalidType'), parseType('FutureOr<Object?>'));

    // MORETOP(T, dynamic) = false
    isNotMoreTop(parseType('Object'), parseType('dynamic'));
    isNotMoreTop(parseType('Object?'), parseType('dynamic'));
    isNotMoreTop(parseType('FutureOr<Object>'), parseType('dynamic'));
    isNotMoreTop(parseType('FutureOr<Object?>'), parseType('dynamic'));

    // MORETOP(T, parseType('InvalidType')) = false
    isNotMoreTop(parseType('Object'), parseType('InvalidType'));
    isNotMoreTop(parseType('Object?'), parseType('InvalidType'));
    isNotMoreTop(parseType('FutureOr<Object>'), parseType('InvalidType'));
    isNotMoreTop(parseType('FutureOr<Object?>'), parseType('InvalidType'));

    // MORETOP(Object, T) = true
    isMoreTop(parseType('Object'), parseType('Object'));
    isMoreTop(parseType('Object'), parseType('Object?'));
    isMoreTop(parseType('Object'), parseType('FutureOr<Object>'));
    isMoreTop(parseType('Object'), parseType('FutureOr<Object>?'));

    // MORETOP(T, Object) = false
    isNotMoreTop(parseType('Object?'), parseType('Object'));
    isNotMoreTop(parseType('FutureOr<Object>'), parseType('Object'));
    isNotMoreTop(parseType('FutureOr<Object>?'), parseType('Object'));

    // MORETOP(T?, S?) = MORETOP(T, S)
    isMoreTop(parseType('Object?'), parseType('Object?'));
    isMoreTop(parseType('FutureOr<void>?'), parseType('FutureOr<void>?'));
    isMoreTop(parseType('FutureOr<void>?'), parseType('FutureOr<dynamic>?'));
    isMoreTop(
      parseType('FutureOr<void>?'),
      parseType('FutureOr<InvalidType>?'),
    );
    isMoreTop(parseType('FutureOr<void>?'), parseType('FutureOr<Object>?'));

    // MORETOP(T, S?) = true
    isMoreTop(parseType('FutureOr<Object>'), parseType('FutureOr<void>?'));
    isMoreTop(parseType('FutureOr<Object>'), parseType('FutureOr<dynamic>?'));
    isMoreTop(
      parseType('FutureOr<Object>'),
      parseType('FutureOr<InvalidType>?'),
    );
    isMoreTop(parseType('FutureOr<Object>'), parseType('FutureOr<Object>?'));

    // MORETOP(T?, S) = false
    isNotMoreTop(parseType('FutureOr<void>?'), parseType('FutureOr<Object>'));
    isNotMoreTop(
      parseType('FutureOr<dynamic>?'),
      parseType('FutureOr<Object>'),
    );
    isNotMoreTop(
      parseType('FutureOr<InvalidType>?'),
      parseType('FutureOr<Object>'),
    );
    isNotMoreTop(parseType('FutureOr<Object>?'), parseType('FutureOr<Object>'));

    // MORETOP(FutureOr<T>, FutureOr<S>) = MORETOP(T, S)
    isMoreTop(parseType('FutureOr<void>'), parseType('FutureOr<void>'));
    isMoreTop(parseType('FutureOr<void>'), parseType('FutureOr<dynamic>'));
    isMoreTop(parseType('FutureOr<void>'), parseType('FutureOr<InvalidType>'));
    isMoreTop(parseType('FutureOr<void>'), parseType('FutureOr<Object>'));
    isNotMoreTop(parseType('FutureOr<dynamic>'), parseType('FutureOr<void>'));
    isNotMoreTop(
      parseType('FutureOr<InvalidType>'),
      parseType('FutureOr<void>'),
    );
    isNotMoreTop(parseType('FutureOr<Object>'), parseType('FutureOr<void>'));
  }

  test_isNull() {
    // NULL(Null) is true
    isNull(parseType('Null'));

    // NULL(T?) is true iff NULL(T) or BOTTOM(T)
    isNull(parseType('Never?'));
    withTypeParameterScope('T extends Never', (scope) {
      isNull(scope.parseType('T?'));
    });

    // NULL(T) is false otherwise
    isNotNull(parseType('dynamic'));
    isNotNull(parseType('InvalidType'));
    isNotNull(parseType('void'));

    isNotNull(parseType('Object'));
    isNotNull(parseType('Object?'));

    isNotNull(parseType('int'));
    isNotNull(parseType('int?'));

    isNotNull(parseType('FutureOr<Null>'));

    isNotNull(parseType('FutureOr<Null>?'));
  }

  test_isObject() {
    // OBJECT(Object) is true
    isObject(parseType('Object'));
    isNotObject(parseType('Object?'));

    // OBJECT(FutureOr<T>) is OBJECT(T)
    isObject(parseType('FutureOr<Object>'));
    isNotObject(parseType('FutureOr<Object?>'));

    isNotObject(parseType('FutureOr<Object>?'));
    isNotObject(parseType('FutureOr<Object?>?'));

    // OBJECT(T) is false otherwise
    isNotObject(parseType('dynamic'));
    isNotObject(parseType('InvalidType'));
    isNotObject(parseType('void'));
    isNotObject(parseType('int'));
  }

  test_isTop() {
    // TOP(T?) is true iff TOP(T) or OBJECT(T)
    isTop(parseType('Object?'));
    isTop(parseType('FutureOr<dynamic>?'));
    isTop(parseType('FutureOr<InvalidType>?'));
    isTop(parseType('FutureOr<void>?'));

    isTop(parseType('FutureOr<Object>?'));
    isTop(parseType('FutureOr<Object?>?'));

    isNotTop(parseType('FutureOr<int>?'));
    isNotTop(parseType('FutureOr<int?>?'));

    // TOP(dynamic) is true
    isTop(parseType('dynamic'));
    isTop(parseType('InvalidType'));
    expect(typeSystem.isTop(UnknownInferredType.instance), isTrue);

    // TOP(void) is true
    isTop(parseType('void'));

    // TOP(FutureOr<T>) is TOP(T)
    isTop(parseType('FutureOr<dynamic>'));
    isTop(parseType('FutureOr<InvalidType>'));
    isTop(parseType('FutureOr<void>'));

    isNotTop(parseType('FutureOr<Object>'));
    isTop(parseType('FutureOr<Object?>'));

    // TOP(T) is false otherwise
    isNotTop(parseType('Object'));

    isNotTop(parseType('int'));
    isNotTop(parseType('int?'));

    isNotTop(parseType('Never'));
    isNotTop(parseType('Never?'));
  }

  /// [TypeSystemImpl.isMoreBottom] can be used only for `BOTTOM` or `NULL`
  /// types. No need to check other types.
  void _assertIsBottomOrNull(TypeImpl type) {
    expect(type.isBottom || typeSystem.isNull(type), isTrue, reason: '$type');
  }

  /// [TypeSystemImpl.isMoreTop] can be used only for `TOP` or `OBJECT`
  /// types. No need to check other types.
  void _assertIsTopOrObject(TypeImpl type) {
    expect(
      typeSystem.isTop(type) || typeSystem.isObject(type),
      isTrue,
      reason: '$type',
    );
  }

  void _checkUniqueTypeStr(Map<String, StackTrace> map, String str) {
    var previousStack = map[str];
    if (previousStack != null) {
      fail('Not unique: $str\n$previousStack');
    } else {
      map[str] = StackTrace.current;
    }
  }
}

@reflectiveTest
class LowerBoundTest extends _BoundsTestBase {
  test_bottom_any() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertBottom(T1);
      _assertNotBottom(T2);
      _checkGreatestLowerBound(T1, T2, T1);
    }

    check(parseType('Never'), parseType('Object'));
    check(parseType('Never'), parseType('Object?'));

    check(parseType('Never'), parseType('int'));
    check(parseType('Never'), parseType('int?'));

    check(parseType('Never'), parseType('List<int>'));
    check(parseType('Never'), parseType('List<int>?'));

    check(parseType('Never'), parseType('FutureOr<int>'));
    check(parseType('Never'), parseType('FutureOr<int>?'));

    withTypeParameterScope('T extends Never', (scope) {
      var T = scope.parseType('T');
      check(T, parseType('int'));
      check(T, parseType('int?'));
    });

    withTypeParameterScope('T extends Object?', (scope) {
      var T = scope.parseType('T & Never');
      check(T, parseType('int'));
      check(T, parseType('int?'));
    });
  }

  test_bottom_bottom() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertBottom(T1);
      _assertBottom(T2);
      _checkGreatestLowerBound(T1, T2, T1);
    }

    withTypeParameterScope('T extends Never', (scope) {
      check(parseType('Never'), scope.parseType('T'));
    });

    withTypeParameterScope('T extends Object?', (scope) {
      check(parseType('Never'), scope.parseType('T & Never'));
    });
  }

  test_functionType2_parameters_conflicts() {
    _checkGreatestLowerBound(
      parseFunctionType('void Function(int a)'),
      parseFunctionType('void Function({int a})'),
      parseType('Never'),
    );

    _checkGreatestLowerBound(
      parseFunctionType('void Function([int a])'),
      parseFunctionType('void Function({int a})'),
      parseType('Never'),
    );
  }

  test_functionType2_parameters_named() {
    _checkGreatestLowerBound(
      parseFunctionType('void Function()'),
      parseFunctionType('void Function()'),
      parseFunctionType('void Function()'),
    );

    {
      _checkGreatestLowerBound(
        parseFunctionType('void Function({int a})'),
        parseFunctionType('void Function({int a})'),
        parseFunctionType('void Function({int a})'),
      );

      _checkGreatestLowerBound(
        parseFunctionType('void Function({int a})'),
        parseFunctionType('void Function({required int a})'),
        parseFunctionType('void Function({int a})'),
      );

      _checkGreatestLowerBound(
        parseFunctionType('void Function({required int a})'),
        parseFunctionType('void Function({required int a})'),
        parseFunctionType('void Function({required int a})'),
      );
    }

    {
      _checkGreatestLowerBound(
        parseFunctionType('void Function({int a, int b})'),
        parseFunctionType('void Function({int a, int c})'),
        parseFunctionType('void Function({int a, int b, int c})'),
      );

      _checkGreatestLowerBound(
        parseFunctionType('void Function({int a, required int b})'),
        parseFunctionType('void Function({int a, required int c})'),
        parseFunctionType('void Function({int a, int b, int c})'),
      );
    }

    {
      _checkGreatestLowerBound(
        parseFunctionType('void Function({int a})'),
        parseFunctionType('void Function({num a})'),
        parseFunctionType('void Function({num a})'),
      );

      _checkGreatestLowerBound(
        parseFunctionType('void Function({int a})'),
        parseFunctionType('void Function({double a})'),
        parseFunctionType('void Function({num a})'),
      );

      _checkGreatestLowerBound(
        parseFunctionType('void Function({int a})'),
        parseFunctionType('void Function({double? a})'),
        parseFunctionType('void Function({num? a})'),
      );

      _checkGreatestLowerBound(
        parseFunctionType('void Function({int a})'),
        parseFunctionType('void Function({double a})'),
        parseFunctionType('void Function({num a})'),
      );
    }
  }

  test_functionType2_parameters_positional() {
    _checkGreatestLowerBound(
      parseFunctionType('void Function()'),
      parseFunctionType('void Function()'),
      parseFunctionType('void Function()'),
    );

    _checkGreatestLowerBound(
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function(int)'),
    );

    _checkGreatestLowerBound(
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function(num)'),
      parseFunctionType('void Function(num)'),
    );

    _checkGreatestLowerBound(
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function(double)'),
      parseFunctionType('void Function(num)'),
    );

    _checkGreatestLowerBound(
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function(double?)'),
      parseFunctionType('void Function(num?)'),
    );

    _checkGreatestLowerBound(
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function(double)'),
      parseFunctionType('void Function(num)'),
    );

    {
      _checkGreatestLowerBound(
        parseFunctionType('void Function(int)'),
        parseFunctionType('void Function([int])'),
        parseFunctionType('void Function([int])'),
      );

      _checkGreatestLowerBound(
        parseFunctionType('void Function(int)'),
        parseFunctionType('void Function()'),
        parseFunctionType('void Function([int])'),
      );

      _checkGreatestLowerBound(
        parseFunctionType('void Function([int])'),
        parseFunctionType('void Function([int])'),
        parseFunctionType('void Function([int])'),
      );

      _checkGreatestLowerBound(
        parseFunctionType('void Function([int])'),
        parseFunctionType('void Function()'),
        parseFunctionType('void Function([int])'),
      );
    }
  }

  test_functionType2_returnType() {
    _checkGreatestLowerBound(
      parseFunctionType('int Function()'),
      parseFunctionType('int Function()'),
      parseFunctionType('int Function()'),
    );

    _checkGreatestLowerBound(
      parseFunctionType('int Function()'),
      parseFunctionType('num Function()'),
      parseFunctionType('int Function()'),
    );

    _checkGreatestLowerBound(
      parseFunctionType('int Function()'),
      parseFunctionType('void Function()'),
      parseFunctionType('int Function()'),
    );

    _checkGreatestLowerBound(
      parseFunctionType('int Function()'),
      parseFunctionType('Never Function()'),
      parseFunctionType('Never Function()'),
    );
  }

  test_functionType2_typeParameters() {
    void check(FunctionTypeImpl T1, FunctionTypeImpl T2, TypeImpl expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _checkGreatestLowerBound(T1, T2, expected, checkSubtype: false);
    }

    check(
      parseFunctionType('void Function<T>()'),
      parseFunctionType('void Function()'),
      parseType('Never'),
    );

    check(
      parseFunctionType('void Function<T extends int>()'),
      parseFunctionType('void Function<T extends num>()'),
      parseType('Never'),
    );

    check(
      parseFunctionType('T Function<T extends num>()'),
      parseFunctionType('U Function<U extends num>()'),
      parseFunctionType('R Function<R extends num>()'),
    );
  }

  test_functionType_interfaceType() {
    void check(FunctionTypeImpl T1, TypeImpl T2, TypeImpl expected) {
      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(
      parseFunctionType('void Function()'),
      parseType('int'),
      parseType('Never'),
    );
  }

  test_functionType_interfaceType_Function() {
    void check(FunctionTypeImpl T1) {
      _assertNullabilityNone(T1);
      _checkGreatestLowerBound(T1, parseType('Function'), T1);
    }

    check(parseFunctionType('void Function()'));

    check(parseFunctionType('int Function(num?)'));
  }

  test_futureOr() {
    InterfaceTypeImpl futureOrFunction(String str) {
      var result = parseInterfaceType(str);
      expect(result.getDisplayString(), str);
      return result;
    }

    // DOWN(FutureOr<T1>, FutureOr<T2>) = FutureOr<S>, S = DOWN(T1, T2)
    _checkGreatestLowerBound(
      parseType('FutureOr<int>'),
      parseType('FutureOr<num>'),
      parseType('FutureOr<int>'),
    );
    _checkGreatestLowerBound(
      futureOrFunction('FutureOr<void Function(int)>'),
      futureOrFunction('FutureOr<void Function(double)>'),
      futureOrFunction('FutureOr<void Function(num)>'),
    );

    // DOWN(FutureOr<T1>, Future<T2>) = Future<S>, S = DOWN(T1, T2)
    // DOWN(Future<T1>, FutureOr<T2>) = Future<S>, S = DOWN(T1, T2)
    _checkGreatestLowerBound(
      parseType('FutureOr<num>'),
      parseType('Future<int>'),
      parseType('Future<int>'),
    );
    _checkGreatestLowerBound(
      parseType('FutureOr<int>'),
      parseType('Future<num>'),
      parseType('Future<int>'),
    );

    // DOWN(FutureOr<T1>, T2) = S, S = DOWN(T1, T2)
    // DOWN(T1, FutureOr<T2>) = S, S = DOWN(T1, T2)
    _checkGreatestLowerBound(
      parseType('FutureOr<num>'),
      parseType('int'),
      parseType('int'),
    );
    _checkGreatestLowerBound(
      parseType('FutureOr<int>'),
      parseType('num'),
      parseType('int'),
    );
  }

  test_identical() {
    void check(TypeImpl type) {
      _checkGreatestLowerBound(type, type, type);
    }

    check(parseType('int'));
    check(parseType('int?'));
    check(parseType('List<int>'));
  }

  test_interfaceType2() {
    void check(TypeImpl T1, TypeImpl T2, TypeImpl expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(parseType('int'), parseType('int'), parseType('int'));
    check(parseType('num'), parseType('int'), parseType('int'));
    check(parseType('double'), parseType('int'), parseType('Never'));

    check(
      parseType('List<int>'),
      parseType('List<int>'),
      parseType('List<int>'),
    );
    check(
      parseType('List<num>'),
      parseType('List<int>'),
      parseType('List<int>'),
    );
    check(
      parseType('List<double>'),
      parseType('List<int>'),
      parseType('Never'),
    );
  }

  void test_interfaceType2_interfaces() {
    // class A
    // class B implements A
    // class C implements B
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B implements A'),
        ClassSpec('class C implements B'),
      ],
    );
    _checkGreatestLowerBound(
      parseInterfaceType('A'),
      parseInterfaceType('C'),
      parseInterfaceType('C'),
    );
  }

  void test_interfaceType2_mixins() {
    // class A
    // class B
    // class C
    // class D extends A with B, C
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B'),
        ClassSpec('class C'),
        ClassSpec('class D extends A with B, C'),
      ],
    );
    _checkGreatestLowerBound(
      parseInterfaceType('A'),
      parseInterfaceType('D'),
      parseInterfaceType('D'),
    );
    _checkGreatestLowerBound(
      parseInterfaceType('B'),
      parseInterfaceType('D'),
      parseInterfaceType('D'),
    );
    _checkGreatestLowerBound(
      parseInterfaceType('C'),
      parseInterfaceType('D'),
      parseInterfaceType('D'),
    );
  }

  void test_interfaceType2_superType() {
    // class A
    // class B extends A
    // class C extends B
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec('class C extends B'),
      ],
    );
    _checkGreatestLowerBound(
      parseInterfaceType('A'),
      parseInterfaceType('C'),
      parseInterfaceType('C'),
    );
  }

  test_none_question() {
    void check(TypeImpl T1, TypeImpl T2, TypeImpl expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(parseType('int'), parseType('int?'), parseType('int'));

    check(parseType('num'), parseType('int?'), parseType('int'));
    check(parseType('int'), parseType('num?'), parseType('int'));

    check(parseType('double'), parseType('int?'), parseType('Never'));
    check(parseType('int'), parseType('double?'), parseType('Never'));
  }

  test_null_any() {
    void check(TypeImpl T2, TypeImpl expected) {
      _assertNotBottom(T2);
      _assertNotNull(T2);
      _assertNotTop(T2);

      _checkGreatestLowerBound(parseType('Null'), T2, expected);
    }

    void checkNull(TypeImpl T2) {
      check(T2, parseType('Null'));
    }

    void checkNever(TypeImpl T2) {
      check(T2, parseType('Never'));
    }

    checkNull(parseType('FutureOr<Null>'));

    checkNull(parseType('FutureOr<Null>?'));

    checkNever(parseType('Object'));

    checkNever(parseType('int'));
    checkNull(parseType('int?'));

    checkNever(parseType('List<int>'));
    checkNull(parseType('List<int>?'));

    checkNever(parseType('List<int?>'));
    checkNull(parseType('List<int?>?'));
  }

  test_null_null() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertNull(T1);
      _assertNull(T2);

      _assertNotBottom(T1);
      _assertNotBottom(T2);

      _checkGreatestLowerBound(T1, T2, T1);
    }

    check(parseType('Null'), parseType('Null'));
  }

  test_object_any() {
    void check(TypeImpl T2, TypeImpl expected) {
      _assertNotObject(T2);

      _checkGreatestLowerBound(parseType('Object'), T2, expected);
    }

    void checkNever(TypeImpl T2) {
      check(T2, parseType('Never'));
    }

    check(parseType('int'), parseType('int'));
    check(parseType('int?'), parseType('int'));

    check(parseType('FutureOr<int>'), parseType('FutureOr<int>'));
    check(parseType('FutureOr<int>?'), parseType('FutureOr<int>'));
    check(parseType('FutureOr<int>'), parseType('FutureOr<int>'));

    checkNever(parseType('FutureOr<int?>'));
    checkNever(parseType('FutureOr<int?>?'));
    checkNever(parseType('FutureOr<int?>'));

    withTypeParameterScope('T extends Object', (scope) {
      check(scope.parseType('T'), scope.parseType('T'));
      check(scope.parseType('T?'), scope.parseType('T'));
    });

    withTypeParameterScope('T extends Object?', (scope) {
      check(scope.parseType('T'), scope.parseType('T & Object'));
      check(scope.parseType('T?'), scope.parseType('T & Object'));
    });

    withTypeParameterScope('T extends FutureOr<Object?>', (scope) {
      checkNever(scope.parseType('T'));
      checkNever(scope.parseType('T?'));
    });
  }

  test_object_object() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertObject(T1);
      _assertObject(T2);

      _checkGreatestLowerBound(T1, T2, T1);
    }

    check(parseType('FutureOr<Object>'), parseType('Object'));

    check(
      parseType('FutureOr<FutureOr<Object>>'),
      parseType('FutureOr<Object>'),
    );
  }

  test_question_question() {
    void check(TypeImpl T1, TypeImpl T2, TypeImpl expected) {
      _assertNullabilityQuestion(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(parseType('int?'), parseType('int?'), parseType('int?'));

    check(parseType('num?'), parseType('int?'), parseType('int?'));
    check(parseType('int?'), parseType('num?'), parseType('int?'));

    check(parseType('double?'), parseType('int?'), parseType('Never?'));
    check(parseType('int?'), parseType('double?'), parseType('Never?'));
  }

  test_recordType2_differentShape() {
    void check(String T1, String T2) {
      _checkGreatestLowerBound2(T1, T2, 'Never');
    }

    check('(int,)', '(int, String)');
    check('(int,)', r'({int $1})');

    check('({int f1, String f2})', '({int f1})');
    check('({int f1})', '({int f2})');
  }

  test_recordType2_sameShape_named() {
    _checkGreatestLowerBound2('({int f1})', '({int f1})', '({int f1})');

    _checkGreatestLowerBound2('({int f1})', '({num f1})', '({int f1})');

    _checkGreatestLowerBound2('({int f1})', '({double f1})', '({Never f1})');

    _checkGreatestLowerBound2(
      '({int f1, double f2})',
      '({double f1, int f2})',
      '({Never f1, Never f2})',
    );
  }

  test_recordType2_sameShape_positional() {
    _checkGreatestLowerBound2('(int,)', '(int,)', '(int,)');
    _checkGreatestLowerBound2('(int,)', '(num,)', '(int,)');
    _checkGreatestLowerBound2('(int,)', '(double,)', '(Never,)');

    _checkGreatestLowerBound2(
      '(int, String)',
      '(int, String)',
      '(int, String)',
    );

    _checkGreatestLowerBound2(
      '(int, double)',
      '(double, int)',
      '(Never, Never)',
    );
  }

  test_recordType_andNot() {
    _checkGreatestLowerBound2('(int,)', 'int', 'Never');
    _checkGreatestLowerBound2('(int,)', 'void Function()', 'Never');
  }

  test_recordType_dartCoreRecord() {
    void check(String T) {
      _checkGreatestLowerBound2(T, 'Record', T);
    }

    check('(int, String)');
    check('({int f1, String f2})');
  }

  test_self() {
    withTypeParameterScope('T', (scope) {
      List<TypeImpl> types = [
        parseType('dynamic'),
        parseType('InvalidType'),
        parseType('void'),
        parseType('Never'),
        scope.parseType('T'),
        parseType('int'),
        parseFunctionType('void Function()'),
      ];

      for (var type in types) {
        _checkGreatestLowerBound(type, type, type);
      }
    });
  }

  test_top_any() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertTop(T1);
      _assertNotTop(T2);
      _checkGreatestLowerBound(T1, T2, T2);
    }

    check(parseType('void'), parseType('Object'));
    check(parseType('void'), parseType('int'));
    check(parseType('void'), parseType('int?'));
    check(parseType('void'), parseType('List<int>'));
    check(parseType('void'), parseType('FutureOr<int>'));
    check(parseType('void'), parseType('Never'));
    check(parseType('void'), parseFunctionType('void Function()'));
    check(parseType('void'), parseType('(int, int)'));

    check(parseType('dynamic'), parseType('Object'));
    check(parseType('dynamic'), parseType('int'));
    check(parseType('dynamic'), parseType('int?'));
    check(parseType('dynamic'), parseType('List<int>'));
    check(parseType('dynamic'), parseType('FutureOr<int>'));
    check(parseType('dynamic'), parseType('Never'));
    check(parseType('dynamic'), parseFunctionType('void Function()'));
    check(parseType('dynamic'), parseType('(int, int)'));

    check(parseType('InvalidType'), parseType('Object'));
    check(parseType('InvalidType'), parseType('int'));
    check(parseType('InvalidType'), parseType('int?'));
    check(parseType('InvalidType'), parseType('List<int>'));
    check(parseType('InvalidType'), parseType('FutureOr<int>'));
    check(parseType('InvalidType'), parseType('Never'));
    check(parseType('InvalidType'), parseFunctionType('void Function()'));
    check(parseType('InvalidType'), parseType('(int, int)'));

    check(parseType('Object?'), parseType('Object'));
    check(parseType('Object?'), parseType('int'));
    check(parseType('Object?'), parseType('int?'));
    check(parseType('Object?'), parseType('List<int>'));
    check(parseType('Object?'), parseType('FutureOr<int>'));
    check(parseType('Object?'), parseType('Never'));
    check(parseType('Object?'), parseFunctionType('void Function()'));
    check(parseType('Object?'), parseType('(int, int)'));

    check(parseType('FutureOr<void>'), parseType('int'));
    check(parseType('FutureOr<void>?'), parseType('int'));
  }

  test_top_top() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertTop(T1);
      _assertTop(T2);
      _checkGreatestLowerBound(T1, T2, T2);
    }

    check(parseType('void'), parseType('dynamic'));
    check(parseType('void'), parseType('InvalidType'));
    check(parseType('void'), parseType('Object?'));
    check(parseType('void'), parseType('FutureOr<void>'));
    check(parseType('void'), parseType('FutureOr<dynamic>'));
    check(parseType('void'), parseType('FutureOr<InvalidType>'));
    check(parseType('void'), parseType('FutureOr<Object?>'));

    check(parseType('dynamic'), parseType('Object?'));
    check(parseType('dynamic'), parseType('FutureOr<void>'));
    check(parseType('dynamic'), parseType('FutureOr<dynamic>'));
    check(parseType('dynamic'), parseType('FutureOr<Object?>'));

    check(parseType('InvalidType'), parseType('Object?'));
    check(parseType('InvalidType'), parseType('FutureOr<void>'));
    check(parseType('InvalidType'), parseType('FutureOr<dynamic>'));
    check(parseType('InvalidType'), parseType('FutureOr<Object?>'));

    check(parseType('Object?'), parseType('FutureOr<void>?'));
    check(parseType('Object?'), parseType('FutureOr<dynamic>?'));
    check(parseType('Object?'), parseType('FutureOr<InvalidType>?'));
    check(parseType('Object?'), parseType('FutureOr<Object>?'));
    check(parseType('Object?'), parseType('FutureOr<Object?>?'));

    check(parseType('FutureOr<void>'), parseType('Object?'));
    check(parseType('FutureOr<dynamic>'), parseType('Object?'));
    check(parseType('FutureOr<InvalidType>'), parseType('Object?'));
    check(parseType('FutureOr<Object?>'), parseType('Object?'));

    check(parseType('FutureOr<void>'), parseType('FutureOr<dynamic>'));
    check(parseType('FutureOr<void>'), parseType('FutureOr<InvalidType>'));
    check(parseType('FutureOr<void>'), parseType('FutureOr<Object?>'));
    check(parseType('FutureOr<dynamic>'), parseType('FutureOr<Object?>'));
    check(parseType('FutureOr<InvalidType>'), parseType('FutureOr<Object?>'));
  }

  test_typeParameter() {
    void check({String? bound, required TypeImpl T2}) {
      withTypeParameterScope(bound == null ? 'T' : 'T extends $bound', (scope) {
        _checkGreatestLowerBound(scope.parseType('T'), T2, parseType('Never'));
      });
    }

    check(T2: parseFunctionType('void Function()'));
    check(T2: parseType('int'));
    check(bound: 'num', T2: parseType('int'));
  }

  void _checkGreatestLowerBound(
    TypeImpl T1,
    TypeImpl T2,
    TypeImpl expected, {
    bool checkSubtype = true,
  }) {
    var expectedStr = '$expected';

    var result = typeSystem.greatestLowerBound(T1, T2);
    var resultStr = '$result';
    expect(
      result,
      expected,
      reason:
          '''
expected: $expectedStr
actual: $resultStr
''',
    );

    // Check that the result is a lower bound.
    if (checkSubtype) {
      expect(typeSystem.isSubtypeOf(result, T1), true);
      expect(typeSystem.isSubtypeOf(result, T2), true);
    }

    // Check for symmetry.
    result = typeSystem.greatestLowerBound(T2, T1);
    resultStr = '$result';
    expect(
      result,
      expected,
      reason:
          '''
expected: $expectedStr
actual: $resultStr
''',
    );
  }

  void _checkGreatestLowerBound2(String T1, String T2, String expected) {
    _checkGreatestLowerBound(parseType(T1), parseType(T2), parseType(expected));
  }
}

@reflectiveTest
class UpperBound_FunctionTypes_Test extends _BoundsTestBase {
  void test_nested2_upParameterType() {
    var T1 = parseFunctionType(
      'void Function(void Function(String, int, int))',
    );
    expect('$T1', 'void Function(void Function(String, int, int))');

    var T2 = parseFunctionType(
      'void Function(void Function(int, double, num))',
    );
    expect('$T2', 'void Function(void Function(int, double, num))');

    var expected = parseFunctionType(
      'void Function(void Function(Object, num, num))',
    );
    expect('$expected', 'void Function(void Function(Object, num, num))');

    _checkLeastUpperBound(T1, T2, expected);
  }

  void test_nested3_downParameterTypes() {
    var T1 = parseFunctionType(
      'void Function(void Function(void Function(String, int, int)))',
    );
    expect(
      '$T1',
      'void Function(void Function(void Function(String, int, int)))',
    );

    var T2 = parseFunctionType(
      'void Function(void Function(void Function(int, double, num)))',
    );
    expect(
      '$T2',
      'void Function(void Function(void Function(int, double, num)))',
    );

    var expected = parseFunctionType(
      'void Function(void Function(void Function(Never, Never, int)))',
    );
    expect(
      '$expected',
      'void Function(void Function(void Function(Never, Never, int)))',
    );

    _checkLeastUpperBound(T1, T2, expected);
  }

  void test_parameters_fuzzyArrows() {
    var T1 = parseFunctionType('void Function(dynamic)');

    var T2 = parseFunctionType('void Function(int)');

    var expected = parseFunctionType('void Function(int)');

    _checkLeastUpperBound(T1, T2, expected);
  }

  test_parameters_optionalNamed() {
    _checkLeastUpperBound(
      parseFunctionType('void Function({int a})'),
      parseFunctionType('void Function()'),
      parseFunctionType('void Function()'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function({int a})'),
      parseFunctionType('void Function({int b})'),
      parseFunctionType('void Function()'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function({int a})'),
      parseFunctionType('void Function({int a})'),
      parseFunctionType('void Function({int a})'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function({int a})'),
      parseFunctionType('void Function({int? a})'),
      parseFunctionType('void Function({int a})'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function({int a, double b})'),
      parseFunctionType('void Function({int a})'),
      parseFunctionType('void Function({int a})'),
    );
  }

  test_parameters_optionalPositional() {
    _checkLeastUpperBound(
      parseFunctionType('void Function([int])'),
      parseFunctionType('void Function()'),
      parseFunctionType('void Function()'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function([int, double])'),
      parseFunctionType('void Function([int])'),
      parseFunctionType('void Function([int])'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function([int])'),
      parseFunctionType('void Function([int])'),
      parseFunctionType('void Function([int])'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function([int])'),
      parseFunctionType('void Function([int?])'),
      parseFunctionType('void Function([int])'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function([int])'),
      parseFunctionType('void Function([double])'),
      parseFunctionType('void Function([Never])'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function([int])'),
      parseFunctionType('void Function([num])'),
      parseFunctionType('void Function([int])'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function([double, num])'),
      parseFunctionType('void Function([num, int])'),
      parseFunctionType('void Function([double, int])'),
    );
  }

  test_parameters_requiredNamed() {
    _checkLeastUpperBound(
      parseFunctionType('void Function(int a)'),
      parseFunctionType('void Function({required int a})'),
      parseType('Function'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function([int a])'),
      parseFunctionType('void Function({required int a})'),
      parseType('Function'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function({int b})'),
      parseFunctionType('void Function({required int a})'),
      parseType('Function'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function({int a})'),
      parseFunctionType('void Function({required int a})'),
      parseFunctionType('void Function({required int a})'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function({int a, required int b})'),
      parseFunctionType('void Function({required int b})'),
      parseFunctionType('void Function({required int b})'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function({required int a})'),
      parseFunctionType('void Function({required num a})'),
      parseFunctionType('void Function({required int a})'),
    );
  }

  test_parameters_requiredPositional() {
    _checkLeastUpperBound(
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function()'),
      parseType('Function'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function(int)'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function(int?)'),
      parseFunctionType('void Function(int)'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function(double)'),
      parseFunctionType('void Function(Never)'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function(int)'),
      parseFunctionType('void Function(num)'),
      parseFunctionType('void Function(int)'),
    );

    _checkLeastUpperBound(
      parseFunctionType('void Function(double, num)'),
      parseFunctionType('void Function(num, int)'),
      parseFunctionType('void Function(double, int)'),
    );
  }

  void test_parameters_requiredPositional_differentArity() {
    var T1 = parseFunctionType('void Function(int, int)');

    var T2 = parseFunctionType('void Function(int, int, int)');

    _checkLeastUpperBound(T1, T2, typeProvider.functionType);
  }

  test_returnType() {
    _checkLeastUpperBound(
      parseFunctionType('int Function()'),
      parseFunctionType('int Function()'),
      parseFunctionType('int Function()'),
    );
    _checkLeastUpperBound(
      parseFunctionType('int Function()'),
      parseFunctionType('int? Function()'),
      parseFunctionType('int? Function()'),
    );

    _checkLeastUpperBound(
      parseFunctionType('int Function()'),
      parseFunctionType('num Function()'),
      parseFunctionType('num Function()'),
    );
    _checkLeastUpperBound(
      parseFunctionType('int? Function()'),
      parseFunctionType('num Function()'),
      parseFunctionType('num? Function()'),
    );

    _checkLeastUpperBound(
      parseFunctionType('int Function()'),
      parseFunctionType('dynamic Function()'),
      parseFunctionType('dynamic Function()'),
    );
    _checkLeastUpperBound(
      parseFunctionType('int Function()'),
      parseFunctionType('InvalidType Function()'),
      parseFunctionType('InvalidType Function()'),
    );
    _checkLeastUpperBound(
      parseFunctionType('int Function()'),
      parseFunctionType('Never Function()'),
      parseFunctionType('int Function()'),
    );
  }

  void test_sameType_withNamed() {
    var T1 = parseFunctionType('int Function(String, int, num, {num n})');

    var T2 = parseFunctionType('int Function(String, int, num, {num n})');

    var expected = parseFunctionType('int Function(String, int, num, {num n})');

    _checkLeastUpperBound(T1, T2, expected);
  }

  void test_sameType_withOptional() {
    var T1 = parseFunctionType('int Function(String, int, num, [double])');

    var T2 = parseFunctionType('int Function(String, int, num, [double])');

    var expected = parseFunctionType(
      'int Function(String, int, num, [double])',
    );

    _checkLeastUpperBound(T1, T2, expected);
  }

  test_typeParameters() {
    void check(FunctionTypeImpl T1, FunctionTypeImpl T2, TypeImpl expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(
      parseFunctionType('void Function<T>()'),
      parseFunctionType('void Function()'),
      parseType('Function'),
    );

    check(
      parseFunctionType('void Function<T extends int>()'),
      parseFunctionType('void Function<T extends num>()'),
      parseType('Function'),
    );

    {
      var T1 = parseFunctionType('T Function<T extends num>()');
      var T2 = parseFunctionType('U Function<U extends num>()');
      {
        var result = typeSystem.leastUpperBound(T1, T2);
        var resultStr = '$result';
        expect(resultStr, 'T Function<T extends num>()');
      }
      {
        var result = typeSystem.leastUpperBound(T2, T1);
        var resultStr = '$result';
        expect(resultStr, 'U Function<U extends num>()');
      }
    }
  }

  test_unrelated() {
    var T1 = parseFunctionType('int Function()');

    _checkLeastUpperBound(T1, parseType('int'), parseType('Object'));
    _checkLeastUpperBound(T1, parseType('int?'), parseType('Object?'));

    _checkLeastUpperBound(
      T1,
      parseType('FutureOr<Function?>'),
      parseType('Object?'),
    );
  }
}

@reflectiveTest
class UpperBound_InterfaceTypes_Test extends _BoundsTestBase {
  test_directInterface() {
    // class A
    // class B implements A
    // class C implements B

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B implements A'),
        ClassSpec('class C implements B'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('C'),
      parseInterfaceType('B'),
    );
  }

  test_directSuperclass() {
    // class A
    // class B extends A
    // class C extends B

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec('class C extends B'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('C'),
      parseInterfaceType('B'),
    );
  }

  void test_directSuperclass_nullability() {
    buildTestLibrary(
      classes: [ClassSpec('class A'), ClassSpec('class B extends A')],
    );
    var aQuestion = parseInterfaceType('A?');
    var aNone = parseInterfaceType('A');
    var bNoneQuestion = parseInterfaceType('B?');
    var bNoneNone = parseInterfaceType('B');

    void assertLUB(TypeImpl type1, TypeImpl type2, TypeImpl expected) {
      expect(typeSystem.leastUpperBound(type1, type2), expected);
      expect(typeSystem.leastUpperBound(type2, type1), expected);
    }

    assertLUB(bNoneQuestion, aQuestion, aQuestion);
    assertLUB(bNoneQuestion, aNone, aQuestion);

    assertLUB(bNoneNone, aQuestion, aQuestion);
    assertLUB(bNoneNone, aNone, aNone);
  }

  void test_implementationsOfComparable() {
    _checkLeastUpperBound(
      parseType('String'),
      parseType('num'),
      parseType('Object'),
    );
  }

  void test_mixinAndClass_constraintAndInterface() {
    buildTestLibrary(
      classes: [ClassSpec('class A'), ClassSpec('class B implements A')],
      mixins: [MixinSpec('mixin M on A')],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('M'),
      parseInterfaceType('A'),
    );
  }

  void test_mixinAndClass_object() {
    buildTestLibrary(
      classes: [ClassSpec('class A')],
      mixins: [MixinSpec('mixin M')],
    );
    _checkLeastUpperBound(
      parseInterfaceType('A'),
      parseInterfaceType('M'),
      parseType('Object'),
    );
  }

  void test_mixinAndClass_sharedInterface() {
    buildTestLibrary(
      classes: [ClassSpec('class A'), ClassSpec('class B implements A')],
      mixins: [MixinSpec('mixin M implements A')],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('M'),
      parseInterfaceType('A'),
    );
  }

  void test_sameElement_nullability() {
    buildTestLibrary(classes: [ClassSpec('class A')]);
    var aQuestion = parseInterfaceType('A?');
    var aNone = parseInterfaceType('A');

    void assertLUB(TypeImpl type1, TypeImpl type2, TypeImpl expected) {
      expect(typeSystem.leastUpperBound(type1, type2), expected);
      expect(typeSystem.leastUpperBound(type2, type1), expected);
    }

    assertLUB(aQuestion, aQuestion, aQuestion);
    assertLUB(aQuestion, aNone, aQuestion);

    assertLUB(aNone, aQuestion, aQuestion);
    assertLUB(aNone, aNone, aNone);
  }

  void test_sharedMixin1() {
    // mixin M {}
    // class B with M {}
    // class C with M {}

    buildTestLibrary(
      classes: [ClassSpec('class B with M'), ClassSpec('class C with M')],
      mixins: [MixinSpec('mixin M')],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('C'),
      parseInterfaceType('M'),
    );
  }

  void test_sharedMixin2() {
    // mixin M1 {}
    // mixin M2 {}
    // mixin M3 {}
    // class A with M1, M2 {}
    // class B with M1, M3 {}

    buildTestLibrary(
      classes: [
        ClassSpec('class A with M1, M2'),
        ClassSpec('class B with M1, M3'),
      ],
      mixins: [
        MixinSpec('mixin M1'),
        MixinSpec('mixin M2'),
        MixinSpec('mixin M3'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('A'),
      parseInterfaceType('B'),
      parseInterfaceType('M1'),
    );
  }

  void test_sharedMixin3() {
    // mixin M1 {}
    // mixin M2 {}
    // mixin M3 {}
    // class A with M2, M1 {}
    // class B with M3, M1 {}

    buildTestLibrary(
      classes: [
        ClassSpec('class A with M2, M1'),
        ClassSpec('class B with M3, M1'),
      ],
      mixins: [
        MixinSpec('mixin M1'),
        MixinSpec('mixin M2'),
        MixinSpec('mixin M3'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('A'),
      parseInterfaceType('B'),
      parseInterfaceType('M1'),
    );
  }

  void test_sharedSuperclass1() {
    // class A {}
    // class B extends A {}
    // class C extends A {}

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec('class C extends A'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('C'),
      parseInterfaceType('A'),
    );
  }

  void test_sharedSuperclass1_nullability() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec('class C extends A'),
      ],
    );
    var aQuestion = parseInterfaceType('A?');
    var aNone = parseInterfaceType('A');
    var bNoneQuestion = parseInterfaceType('B?');
    var bNoneNone = parseInterfaceType('B');
    var cNoneQuestion = parseInterfaceType('C?');
    var cNoneNone = parseInterfaceType('C');

    void assertLUB(TypeImpl type1, TypeImpl type2, TypeImpl expected) {
      expect(typeSystem.leastUpperBound(type1, type2), expected);
      expect(typeSystem.leastUpperBound(type2, type1), expected);
    }

    assertLUB(bNoneQuestion, cNoneQuestion, aQuestion);
    assertLUB(bNoneQuestion, cNoneNone, aQuestion);

    assertLUB(bNoneNone, cNoneQuestion, aQuestion);
    assertLUB(bNoneNone, cNoneNone, aNone);
  }

  void test_sharedSuperclass2() {
    // class A {}
    // class B extends A {}
    // class C extends A {}
    // class D extends C {}

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec('class C extends A'),
        ClassSpec('class D extends C'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('D'),
      parseInterfaceType('A'),
    );
  }

  void test_sharedSuperclass3() {
    // class A {}
    // class B extends A {}
    // class C extends B {}
    // class D extends B {}

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec('class C extends B'),
        ClassSpec('class D extends B'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('C'),
      parseInterfaceType('D'),
      parseInterfaceType('B'),
    );
  }

  void test_sharedSuperclass4() {
    // class A {}
    // class A2 {}
    // class A3 {}
    // class B extends A implements A2 {}
    // class C extends A implement A3 {}

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class A2'),
        ClassSpec('class A3'),
        ClassSpec('class B extends A implements A2'),
        ClassSpec('class C extends A implements A3'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('C'),
      parseInterfaceType('A'),
    );
  }

  void test_sharedSuperinterface1() {
    // class A {}
    // class B implements A {}
    // class C implements A {}

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B implements A'),
        ClassSpec('class C implements A'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('C'),
      parseInterfaceType('A'),
    );
  }

  void test_sharedSuperinterface2() {
    // class A {}
    // class B implements A {}
    // class C implements A {}
    // class D implements C {}

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B implements A'),
        ClassSpec('class C implements A'),
        ClassSpec('class D implements C'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('D'),
      parseInterfaceType('A'),
    );
  }

  void test_sharedSuperinterface3() {
    // class A {}
    // class B implements A {}
    // class C implements B {}
    // class D implements B {}

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B implements A'),
        ClassSpec('class C implements B'),
        ClassSpec('class D implements B'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('C'),
      parseInterfaceType('D'),
      parseInterfaceType('B'),
    );
  }

  void test_sharedSuperinterface4() {
    // class A {}
    // class A2 {}
    // class A3 {}
    // class B implements A, A2 {}
    // class C implements A, A3 {}

    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class A2'),
        ClassSpec('class A3'),
        ClassSpec('class B implements A, A2'),
        ClassSpec('class C implements A, A3'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('C'),
      parseInterfaceType('A'),
    );
  }
}

@reflectiveTest
class UpperBound_RecordTypes_Test extends _BoundsTestBase {
  test_differentShape() {
    void check(String T1, String T2) {
      _checkLeastUpperBound2(T1, T2, 'Record');
    }

    check('(int,)', '(int, String)');
    check('(int,)', r'({int $1})');

    check('({int f1, String f2})', '({int f1})');
    check('({int f1})', '({int f2})');
  }

  test_Never() {
    _checkLeastUpperBound2('(int,)', 'Never', '(int,)');
  }

  test_record_andNot() {
    _checkLeastUpperBound2('(int,)', 'int', 'Object');
    _checkLeastUpperBound2('(int,)', 'void Function()', 'Object');
  }

  test_record_dartCoreRecord() {
    void check(String T1) {
      _checkLeastUpperBound2(T1, 'Record', 'Record');
    }

    check('(int, String)');
    check('({int f1, String f2})');
  }

  test_sameShape_named() {
    _checkLeastUpperBound2('({int f1})', '({int f1})', '({int f1})');

    _checkLeastUpperBound2('({int f1})', '({num f1})', '({num f1})');

    _checkLeastUpperBound2('({int f1})', '({double f1})', '({num f1})');

    _checkLeastUpperBound2(
      '({int f1, double f2})',
      '({double f1, int f2})',
      '({num f1, num f2})',
    );
  }

  test_sameShape_positional() {
    _checkLeastUpperBound2('(int,)', '(int,)', '(int,)');
    _checkLeastUpperBound2('(int,)', '(num,)', '(num,)');
    _checkLeastUpperBound2('(int,)', '(double,)', '(num,)');

    _checkLeastUpperBound2('(int, String)', '(int, String)', '(int, String)');

    _checkLeastUpperBound2('(int, double)', '(double, int)', '(num, num)');
  }

  test_top() {
    _checkLeastUpperBound2('(int,)', 'dynamic', 'dynamic');
    _checkLeastUpperBound2('(int,)', 'Object?', 'Object?');
  }
}

@reflectiveTest
class UpperBoundTest extends _BoundsTestBase {
  test_bottom_any() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertBottom(T1);
      _assertNotBottom(T2);
      _checkLeastUpperBound(T1, T2, T2);
    }

    check(parseType('Never'), parseType('dynamic'));
    check(parseType('Never'), parseType('InvalidType'));

    check(parseType('Never'), parseType('Object'));
    check(parseType('Never'), parseType('Object?'));

    check(parseType('Never'), parseType('int'));
    check(parseType('Never'), parseType('int?'));

    check(parseType('Never'), parseType('List<int>'));
    check(parseType('Never'), parseType('List<int>?'));

    check(parseType('Never'), parseType('FutureOr<int>'));
    check(parseType('Never'), parseType('FutureOr<int>?'));

    check(parseType('Never'), parseFunctionType('void Function()'));
    check(parseType('Never'), parseFunctionType('void Function()?'));

    {
      withTypeParameterScope('T', (scope) {
        check(parseType('Never'), scope.parseType('T'));
        check(parseType('Never'), scope.parseType('T?'));
      });
    }

    {
      withTypeParameterScope('T extends Never', (scope) {
        var T = scope.parseType('T');
        check(T, parseType('int'));
        check(T, parseType('int?'));
      });
    }

    {
      withTypeParameterScope('T extends Object?', (scope) {
        var T = scope.parseType('T & Never');
        check(T, parseType('int'));
        check(T, parseType('int?'));
      });
    }
  }

  test_bottom_bottom() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertBottom(T1);
      _assertBottom(T2);
      _checkLeastUpperBound(T1, T2, T2);
    }

    withTypeParameterScope('T extends Never', (scope) {
      check(parseType('Never'), scope.parseType('T'));
    });

    withTypeParameterScope('T extends Object?', (scope) {
      check(parseType('Never'), scope.parseType('T & Never'));
    });
  }

  void test_extensionType_implementExtensionType_implicitObjectQuestion() {
    // extension type A(Object?) {}
    // extension type B(Object?) implements A {}
    // extension type C(Object?) implements A {}

    buildTestLibrary(
      extensionTypes: [
        ExtensionTypeSpec('extension type A(Object? it)'),
        ExtensionTypeSpec('extension type B(Object? it) implements A'),
        ExtensionTypeSpec('extension type C(Object? it) implements A'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('B'),
      parseInterfaceType('C'),
      parseInterfaceType('A'),
    );
  }

  void test_extensionType_noTypeParameters_interfaces() {
    // extension type A(int) implements int {}
    // extension type B(double) implements double {}

    buildTestLibrary(
      extensionTypes: [
        ExtensionTypeSpec('extension type A(int it) implements int'),
        ExtensionTypeSpec('extension type B(double it) implements double'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('A'),
      parseInterfaceType('B'),
      parseType('num'),
    );
  }

  void test_extensionType_noTypeParameters_noInterfaces() {
    // extension type A(int) {}
    // extension type B(double) {}

    buildTestLibrary(
      extensionTypes: [
        ExtensionTypeSpec('extension type A(int it)'),
        ExtensionTypeSpec('extension type B(double it)'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('A'),
      parseInterfaceType('B'),
      parseType('Object?'),
    );
  }

  void test_extensionType_withTypeParameters_objectNone() {
    buildTestLibrary(
      extensionTypes: [
        ExtensionTypeSpec('extension type A<T>(T it) implements Object?'),
        ExtensionTypeSpec('extension type B<T>(T it) implements Object?'),
      ],
    );
    _checkLeastUpperBound(
      parseInterfaceType('A<String>'),
      parseInterfaceType('B<num>'),
      parseType('Object'),
    );
  }

  void test_extensionType_withTypeParameters_withInterfaces() {
    buildTestLibrary(
      extensionTypes: [
        ExtensionTypeSpec('extension type E<T>(T it) implements Object?'),
        ExtensionTypeSpec(
          'extension type A<T1 extends String>(T1 it) implements E<T1>, String',
        ),
        ExtensionTypeSpec(
          'extension type B<T2 extends int>(T2 it) implements E<T2?>, num',
        ),
      ],
    );
    // A<T1> implements E<T1>, String
    // B<T2> implements E<T2?>, num
    _checkLeastUpperBound(
      parseInterfaceType('A<String>'),
      parseInterfaceType('B<num>'),
      parseType('Object'),
    );
  }

  test_functionType_interfaceType() {
    void check(FunctionTypeImpl T1, TypeImpl T2, TypeImpl expected) {
      _checkLeastUpperBound(T1, T2, expected);
    }

    check(
      parseFunctionType('void Function()'),
      parseType('int'),
      parseType('Object'),
    );
  }

  test_functionType_interfaceType_Function() {
    void check(FunctionTypeImpl T1, TypeImpl T2, TypeImpl expected) {
      _checkLeastUpperBound(T1, T2, expected);
    }

    void checkNone(FunctionTypeImpl T1) {
      _assertNullabilityNone(T1);
      check(T1, parseType('Function'), parseType('Function'));
    }

    checkNone(parseFunctionType('void Function()'));

    checkNone(parseFunctionType('int Function(num?)'));

    check(
      parseFunctionType('void Function()?'),
      parseType('Function'),
      parseType('Function?'),
    );
  }

  /// `UP(Future<T1>, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)`
  /// `UP(FutureOr<T1>, Future<T2>) = FutureOr<T3> where T3 = UP(T1, T2)`
  test_futureOr_future() {
    _checkLeastUpperBound(
      parseType('Future<int>'),
      parseType('FutureOr<double>'),
      parseType('FutureOr<num>'),
    );

    _checkLeastUpperBound(
      parseType('Future<int>'),
      parseType('FutureOr<String>'),
      parseType('FutureOr<Object>'),
    );
  }

  /// `UP(FutureOr<T1>, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)`
  test_futureOr_futureOr() {
    _checkLeastUpperBound(
      parseType('FutureOr<int>'),
      parseType('FutureOr<double>'),
      parseType('FutureOr<num>'),
    );

    _checkLeastUpperBound(
      parseType('FutureOr<int>'),
      parseType('FutureOr<String>'),
      parseType('FutureOr<Object>'),
    );
  }

  /// `UP(T1, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)`
  /// `UP(FutureOr<T1>, T2) = FutureOr<T3> where T3 = UP(T1, T2)`
  test_futureOr_other() {
    _checkLeastUpperBound(
      parseType('FutureOr<int>'),
      parseType('double'),
      parseType('FutureOr<num>'),
    );

    _checkLeastUpperBound(
      parseType('FutureOr<int>'),
      parseType('String'),
      parseType('FutureOr<Object>'),
    );
  }

  test_identical() {
    void check(TypeImpl type) {
      _checkLeastUpperBound(type, type, type);
    }

    check(parseType('int'));
    check(parseType('int?'));
    check(parseType('List<int>'));
  }

  void test_interfaceType_functionType() {
    buildTestLibrary(classes: [ClassSpec('class A')]);
    _checkLeastUpperBound(
      parseInterfaceType('A'),
      parseFunctionType('void Function()'),
      parseType('Object'),
    );
  }

  test_none_question() {
    void check(TypeImpl T1, TypeImpl T2, TypeImpl expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(parseType('double'), parseType('int?'), parseType('num?'));
    check(parseType('num'), parseType('double?'), parseType('num?'));
    check(parseType('num'), parseType('int?'), parseType('num?'));
  }

  test_null_any() {
    void check(TypeImpl T1, TypeImpl T2, TypeImpl expected) {
      _assertNull(T1);
      _assertNotNull(T2);

      _assertNotTop(T1);
      _assertNotTop(T2);

      _assertNotBottom(T1);
      _assertNotBottom(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(parseType('Null'), parseType('Object'), parseType('Object?'));

    check(parseType('Null'), parseType('int'), parseType('int?'));
    check(parseType('Null'), parseType('int?'), parseType('int?'));

    check(parseType('Null'), parseType('List<int>'), parseType('List<int>?'));
    check(parseType('Null'), parseType('List<int>?'), parseType('List<int>?'));

    check(
      parseType('Null'),
      parseType('FutureOr<int>'),
      parseType('FutureOr<int>?'),
    );
    check(
      parseType('Null'),
      parseType('FutureOr<int>?'),
      parseType('FutureOr<int>?'),
    );

    check(
      parseType('Null'),
      parseType('FutureOr<int?>'),
      parseType('FutureOr<int?>'),
    );
    check(
      parseType('Null'),
      parseType('FutureOr<int?>?'),
      parseType('FutureOr<int?>?'),
    );

    check(
      parseType('Null'),
      parseFunctionType('int Function()'),
      parseFunctionType('int Function()?'),
    );
  }

  test_null_null() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertNull(T1);
      _assertNull(T2);

      _assertNotBottom(T1);
      _assertNotBottom(T2);

      _checkLeastUpperBound(T1, T2, T2);
    }

    check(parseType('Null'), parseType('Null'));
  }

  test_object_any() {
    void check(TypeImpl T1, TypeImpl T2, TypeImpl expected) {
      _assertObject(T1);
      _assertNotObject(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(parseType('Object'), parseType('int'), parseType('Object'));
    check(parseType('Object'), parseType('int?'), parseType('Object?'));

    check(
      parseType('Object'),
      parseType('FutureOr<int?>'),
      parseType('Object?'),
    );

    check(
      parseType('FutureOr<Object>'),
      parseType('int'),
      parseType('FutureOr<Object>'),
    );
    check(
      parseType('FutureOr<Object>'),
      parseType('int?'),
      parseType('FutureOr<Object>?'),
    );
  }

  test_object_object() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertObject(T1);
      _assertObject(T2);

      _checkLeastUpperBound(T1, T2, T2);
    }

    check(parseType('FutureOr<Object>'), parseType('Object'));

    check(
      parseType('FutureOr<FutureOr<Object>>'),
      parseType('FutureOr<Object>'),
    );
  }

  test_question_question() {
    void check(TypeImpl T1, TypeImpl T2, TypeImpl expected) {
      _assertNullabilityQuestion(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(parseType('double?'), parseType('int?'), parseType('num?'));
    check(parseType('num?'), parseType('double?'), parseType('num?'));
    check(parseType('num?'), parseType('int?'), parseType('num?'));
  }

  test_top_any() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertTop(T1);
      _assertNotTop(T2);
      _checkLeastUpperBound(T1, T2, T1);
    }

    void check2(TypeImpl T1) {
      check(T1, parseType('Object'));
      check(T1, parseType('int'));
      check(T1, parseType('int?'));
      check(T1, parseType('List<int>'));
      check(T1, parseType('FutureOr<int>'));
      check(T1, parseFunctionType('void Function()'));

      withTypeParameterScope('T', (scope) {
        check(T1, scope.parseType('T'));
        check(T1, scope.parseType('T?'));
      });
    }

    check2(parseType('void'));
    check2(parseType('dynamic'));
    check2(parseType('InvalidType'));
    check2(parseType('Object?'));

    check2(parseType('FutureOr<void>'));
    check2(parseType('FutureOr<void>?'));
  }

  test_top_top() {
    void check(TypeImpl T1, TypeImpl T2) {
      _assertTop(T1);
      _assertTop(T2);
      _checkLeastUpperBound(T1, T2, T1);
    }

    check(parseType('void'), parseType('dynamic'));
    check(parseType('void'), parseType('InvalidType'));
    check(parseType('void'), parseType('Object?'));
    check(parseType('void'), parseType('FutureOr<void>'));
    check(parseType('void'), parseType('FutureOr<dynamic>'));
    check(parseType('void'), parseType('FutureOr<InvalidType>'));
    check(parseType('void'), parseType('FutureOr<Object?>'));

    check(parseType('dynamic'), parseType('Object?'));
    check(parseType('dynamic'), parseType('FutureOr<void>'));
    check(parseType('dynamic'), parseType('FutureOr<dynamic>'));
    check(parseType('dynamic'), parseType('FutureOr<Object?>'));

    check(parseType('InvalidType'), parseType('Object?'));
    check(parseType('InvalidType'), parseType('FutureOr<void>'));
    check(parseType('InvalidType'), parseType('FutureOr<dynamic>'));
    check(parseType('InvalidType'), parseType('FutureOr<Object?>'));

    check(parseType('Object?'), parseType('FutureOr<void>?'));
    check(parseType('Object?'), parseType('FutureOr<dynamic>?'));
    check(parseType('Object?'), parseType('FutureOr<InvalidType>?'));
    check(parseType('Object?'), parseType('FutureOr<Object>?'));
    check(parseType('Object?'), parseType('FutureOr<Object?>?'));

    check(parseType('FutureOr<void>'), parseType('Object?'));
    check(parseType('FutureOr<dynamic>'), parseType('Object?'));
    check(parseType('FutureOr<InvalidType>'), parseType('Object?'));
    check(parseType('FutureOr<Object?>'), parseType('Object?'));

    check(parseType('FutureOr<void>'), parseType('FutureOr<dynamic>'));
    check(parseType('FutureOr<void>'), parseType('FutureOr<InvalidType>'));
    check(parseType('FutureOr<void>'), parseType('FutureOr<Object?>'));
    check(parseType('FutureOr<dynamic>'), parseType('FutureOr<Object?>'));
    check(parseType('FutureOr<InvalidType>'), parseType('FutureOr<Object?>'));
  }

  test_typeParameter_bound() {
    void check(TypeParameterTypeImpl T1, TypeImpl T2, TypeImpl expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    withTypeParameterScope('T extends int', (scope) {
      check(
        scope.parseTypeParameterType('T'),
        parseType('num'),
        parseType('num'),
      );
    });

    withTypeParameterScope('T extends int, U extends num', (scope) {
      check(
        scope.parseTypeParameterType('T'),
        scope.parseTypeParameterType('U'),
        parseType('num'),
      );
    });

    withTypeParameterScope('T extends int, U extends num?', (scope) {
      check(
        scope.parseTypeParameterType('T'),
        scope.parseTypeParameterType('U'),
        parseType('num?'),
      );
    });

    withTypeParameterScope('T extends int?, U extends num', (scope) {
      check(
        scope.parseTypeParameterType('T'),
        scope.parseTypeParameterType('U'),
        parseType('num?'),
      );
    });

    withTypeParameterScope('T extends num, U extends T', (scope) {
      var T = scope.parseTypeParameterType('T');
      check(T, scope.parseTypeParameterType('U'), T);
    });
  }

  void test_typeParameter_fBounded() {
    // class A<T> {}
    buildTestLibrary(classes: [ClassSpec('class A<T>')]);

    withTypeParameterScope('S, U', (scope) {
      var S = scope.typeParameter('S');
      S.bound = scope.parseType('A<S>');

      var U = scope.typeParameter('U');
      U.bound = scope.parseType('A<U>');

      _checkLeastUpperBound(
        scope.parseType('S'),
        scope.parseType('U'),
        parseType('A<Object?>'),
      );
    });
  }

  void test_typeParameter_function_bounded() {
    withTypeParameterScope('T extends Function', (scope) {
      _checkLeastUpperBound(
        scope.parseType('T'),
        parseFunctionType('void Function()'),
        typeProvider.functionType,
      );
    });
  }

  void test_typeParameter_function_noBound() {
    withTypeParameterScope('T extends Object?', (scope) {
      _checkLeastUpperBound(
        scope.parseType('T'),
        parseFunctionType('void Function()'),
        parseType('Object?'),
      );
    });
  }

  void test_typeParameter_greatestClosure_functionBounded() {
    withTypeParameterScope('T extends void Function(T)', (scope) {
      _checkLeastUpperBound(
        scope.parseType('T'),
        parseFunctionType('void Function(Null)'),
        parseFunctionType('void Function(Never)'),
      );
    });
  }

  void test_typeParameter_greatestClosure_functionPromoted() {
    withTypeParameterScope('T', (scope) {
      _checkLeastUpperBound(
        scope.parseType('T & void Function(T)'),
        parseFunctionType('void Function(Null)'),
        parseFunctionType('void Function(Never)'),
      );
    });
  }

  void test_typeParameter_interface_bounded() {
    buildTestLibrary(
      classes: [
        ClassSpec('class A'),
        ClassSpec('class B extends A'),
        ClassSpec('class C extends A'),
      ],
    );
    withTypeParameterScope('T extends B', (scope) {
      _checkLeastUpperBound(
        scope.parseType('T'),
        parseInterfaceType('C'),
        parseInterfaceType('A'),
      );
    });
  }

  void test_typeParameter_interface_bounded_objectQuestion() {
    withTypeParameterScope('T extends Object?', (scope) {
      _checkLeastUpperBound(
        scope.parseType('T'),
        parseType('int'),
        parseType('Object?'),
      );
    });
  }

  void test_typeParameter_interface_noBound() {
    withTypeParameterScope('T', (scope) {
      _checkLeastUpperBound(
        scope.parseType('T'),
        parseType('int'),
        parseType('Object?'),
      );
    });
  }

  void test_typeParameter_intersection_basic() {
    withTypeParameterScope('X extends num?, Y extends X', (scope) {
      var X_none = scope.parseType('X');
      var Y_none = scope.parseType('Y');
      var X_none_promoted = scope.parseType('X & num');

      // `UP(X & num, Y) == X`, because `Y <: X`.
      _checkLeastUpperBound(X_none_promoted, Y_none, X_none);

      // `UP(X & num, num?) == num?`, because `X <: num?`.
      _checkLeastUpperBound(
        X_none_promoted,
        parseType('num?'),
        parseType('num?'),
      );

      // `UP(X & num, String) == Object`.
      _checkLeastUpperBound(
        X_none_promoted,
        parseType('String'),
        parseType('Object'),
      );
    });
  }

  void test_typeParameter_intersection_fbounded() {
    // `X`, `class C<X> {}`, `Y extends C<Y>?`, `Y & C<Y>`.
    buildTestLibrary(classes: [ClassSpec('class C<X>')]);
    withTypeParameterScope('Y', (scope) {
      var Y = scope.typeParameter('Y');
      Y.bound = scope.parseType('C<Y>?');

      // `UP(Y & C<Y>, C<Never>) == C<Object?>`.
      _checkLeastUpperBound(
        scope.parseType('Y & C<Y>'),
        parseInterfaceType('C<Never>'),
        parseInterfaceType('C<Object?>'),
      );
    });
  }

  void test_typeParameter_intersection_null() {
    withTypeParameterScope('X', (scope) {
      // UP(X & num?, Null) == num?
      _checkLeastUpperBound(
        scope.parseType('X & num?'),
        parseType('Null'),
        parseType('num?'),
      );

      // UP(X & num, Null) == num?
      _checkLeastUpperBound(
        scope.parseType('X & num'),
        parseType('Null'),
        parseType('num?'),
      );
    });
  }

  void test_typeParameters_contravariant_different() {
    // class A<in T>
    buildTestLibrary(classes: [ClassSpec('class A<in T>')]);
    _checkLeastUpperBound(
      parseInterfaceType('A<int>'),
      parseInterfaceType('A<num>'),
      parseInterfaceType('A<int>'),
    );
  }

  void test_typeParameters_contravariant_same() {
    // class A<in T>
    buildTestLibrary(classes: [ClassSpec('class A<in T>')]);
    _checkLeastUpperBound(
      parseInterfaceType('A<num>'),
      parseInterfaceType('A<num>'),
      parseInterfaceType('A<num>'),
    );
  }

  void test_typeParameters_covariant_different() {
    // class A<out T>
    buildTestLibrary(classes: [ClassSpec('class A<out T>')]);
    _checkLeastUpperBound(
      parseInterfaceType('A<int>'),
      parseInterfaceType('A<num>'),
      parseInterfaceType('A<num>'),
    );
  }

  void test_typeParameters_covariant_same() {
    // class A<out T>
    buildTestLibrary(classes: [ClassSpec('class A<out T>')]);
    _checkLeastUpperBound(
      parseInterfaceType('A<num>'),
      parseInterfaceType('A<num>'),
      parseInterfaceType('A<num>'),
    );
  }

  void test_typeParameters_invariant_object() {
    // class A<inout T>
    buildTestLibrary(classes: [ClassSpec('class A<inout T>')]);
    _checkLeastUpperBound(
      parseInterfaceType('A<num>'),
      parseInterfaceType('A<int>'),
      parseType('Object'),
    );
  }

  void test_typeParameters_invariant_same() {
    // class A<inout T>
    buildTestLibrary(classes: [ClassSpec('class A<inout T>')]);
    _checkLeastUpperBound(
      parseInterfaceType('A<num>'),
      parseInterfaceType('A<num>'),
      parseInterfaceType('A<num>'),
    );
  }

  void test_typeParameters_multi_basic() {
    // class A<out T, inout U, in V>
    buildTestLibrary(classes: [ClassSpec('class A<out T, inout U, in V>')]);
    _checkLeastUpperBound(
      parseInterfaceType('A<num, num, num>'),
      parseInterfaceType('A<int, num, int>'),
      parseInterfaceType('A<num, num, int>'),
    );
  }

  void test_typeParameters_multi_objectInterface() {
    // class A<out T, inout U, in V>
    buildTestLibrary(classes: [ClassSpec('class A<out T, inout U, in V>')]);
    _checkLeastUpperBound(
      parseInterfaceType('A<num, String, num>'),
      parseInterfaceType('A<int, num, int>'),
      parseType('Object'),
    );
  }

  void test_typeParameters_multi_objectType() {
    // class A<out T, inout U, in V>
    buildTestLibrary(classes: [ClassSpec('class A<out T, inout U, in V>')]);
    _checkLeastUpperBound(
      parseInterfaceType('A<String, num, num>'),
      parseInterfaceType('A<int, num, int>'),
      parseInterfaceType('A<Object, num, int>'),
    );
  }

  /// Check least upper bound of the same class with different type parameters.
  void test_typeParameters_noVariance_different() {
    _checkLeastUpperBound(
      parseType('List<int>'),
      parseType('List<double>'),
      parseType('List<num>'),
    );
  }

  void test_typeParameters_noVariance_same() {
    var listOfInt = parseType('List<int>');
    _checkLeastUpperBound(listOfInt, listOfInt, listOfInt);
  }
}

@reflectiveTest
class _BoundsTestBase extends AbstractTypeSystemTest {
  void _assertBottom(TypeImpl type) {
    if (!type.isBottom) {
      fail('isBottom must be true: $type');
    }
  }

  void _assertNotBottom(TypeImpl type) {
    if (type.isBottom) {
      fail('isBottom must be false: $type');
    }
  }

  void _assertNotNull(TypeImpl type) {
    if (typeSystem.isNull(type)) {
      fail('isNull must be false: $type');
    }
  }

  void _assertNotObject(TypeImpl type) {
    if (typeSystem.isObject(type)) {
      fail('isObject must be false: $type');
    }
  }

  void _assertNotSpecial(TypeImpl type) {
    _assertNotBottom(type);
    _assertNotNull(type);
    _assertNotObject(type);
    _assertNotTop(type);
  }

  void _assertNotTop(TypeImpl type) {
    if (typeSystem.isTop(type)) {
      fail('isTop must be false: $type');
    }
  }

  void _assertNull(TypeImpl type) {
    if (!typeSystem.isNull(type)) {
      fail('isNull must be true: $type');
    }
  }

  void _assertNullability(TypeImpl type, NullabilitySuffix expected) {
    if (type.nullabilitySuffix != expected) {
      fail('Expected $expected in $type');
    }
  }

  void _assertNullabilityNone(TypeImpl type) {
    _assertNullability(type, NullabilitySuffix.none);
  }

  void _assertNullabilityQuestion(TypeImpl type) {
    _assertNullability(type, NullabilitySuffix.question);
  }

  void _assertObject(TypeImpl type) {
    if (!typeSystem.isObject(type)) {
      fail('isObject must be true: $type');
    }
  }

  void _assertTop(TypeImpl type) {
    if (!typeSystem.isTop(type)) {
      fail('isTop must be true: $type');
    }
  }

  void _checkLeastUpperBound(TypeImpl T1, TypeImpl T2, TypeImpl expected) {
    var expectedStr = '$expected';

    var result = typeSystem.leastUpperBound(T1, T2);
    var resultStr = '$result';
    expect(
      result,
      expected,
      reason:
          '''
expected: $expectedStr
actual: $resultStr
''',
    );

    // Check that the result is an upper bound.
    expect(typeSystem.isSubtypeOf(T1, result), true);
    expect(typeSystem.isSubtypeOf(T2, result), true);

    // Check for symmetry.
    result = typeSystem.leastUpperBound(T2, T1);
    resultStr = '$result';
    expect(
      result,
      expected,
      reason:
          '''
expected: $expectedStr
actual: $resultStr
''',
    );
  }

  void _checkLeastUpperBound2(String T1, String T2, String expected) {
    _checkLeastUpperBound(parseType(T1), parseType(T2), parseType(expected));
  }
}
