// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BoundsHelperPredicatesTest);
    defineReflectiveTests(LowerBoundTest);
    defineReflectiveTests(UpperBoundTest);
  });
}

@reflectiveTest
class BoundsHelperPredicatesTest extends _BoundsTestBase {
  static final Map<String, StackTrace> _isMoreBottomChecked = {};
  static final Map<String, StackTrace> _isMoreTopChecked = {};

  @override
  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting(
      additionalFeatures: [Feature.non_nullable],
    );
  }

  void isBottom(DartType type) {
    expect(typeSystem.isBottom(type), isTrue, reason: _typeString(type));
  }

  void isMoreBottom(DartType T, DartType S) {
    _assertIsBottomOrNull(T);
    _assertIsBottomOrNull(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreBottomChecked, str);

    expect(typeSystem.isMoreBottom(T, S), isTrue, reason: str);
  }

  void isMoreTop(DartType T, DartType S) {
    _assertIsTopOrObject(T);
    _assertIsTopOrObject(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreTopChecked, str);

    expect(typeSystem.isMoreTop(T, S), isTrue, reason: str);
  }

  void isNotBottom(DartType type) {
    expect(typeSystem.isBottom(type), isFalse, reason: _typeString(type));
  }

  void isNotMoreBottom(DartType T, DartType S) {
    _assertIsBottomOrNull(T);
    _assertIsBottomOrNull(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreBottomChecked, str);

    expect(typeSystem.isMoreBottom(T, S), isFalse, reason: str);
  }

  void isNotMoreTop(DartType T, DartType S) {
    _assertIsTopOrObject(T);
    _assertIsTopOrObject(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreTopChecked, str);

    expect(typeSystem.isMoreTop(T, S), isFalse, reason: str);
  }

  void isNotNull(DartType type) {
    expect(typeSystem.isNull(type), isFalse, reason: _typeString(type));
  }

  void isNotObject(DartType type) {
    expect(typeSystem.isObject(type), isFalse, reason: _typeString(type));
  }

  void isNotTop(DartType type) {
    expect(typeSystem.isTop(type), isFalse, reason: _typeString(type));
  }

  void isNull(DartType type) {
    expect(typeSystem.isNull(type), isTrue, reason: _typeString(type));
  }

  void isObject(DartType type) {
    expect(typeSystem.isObject(type), isTrue, reason: _typeString(type));
  }

  void isTop(DartType type) {
    expect(typeSystem.isTop(type), isTrue, reason: _typeString(type));
  }

  test_isBottom() {
    TypeParameterElement T;

    // BOTTOM(Never) is true
    isBottom(neverNone);
    isNotBottom(neverQuestion);
    isNotBottom(neverStar);

    // BOTTOM(X&T) is true iff BOTTOM(T)
    T = typeParameter('T', bound: objectQuestion);

    isBottom(promotedTypeParameterTypeNone(T, neverNone));
    isBottom(promotedTypeParameterTypeQuestion(T, neverNone));
    isBottom(promotedTypeParameterTypeStar(T, neverNone));

    isNotBottom(promotedTypeParameterTypeNone(T, neverQuestion));
    isNotBottom(promotedTypeParameterTypeQuestion(T, neverQuestion));
    isNotBottom(promotedTypeParameterTypeStar(T, neverQuestion));

    // BOTTOM(X extends T) is true iff BOTTOM(T)
    T = typeParameter('T', bound: neverNone);
    isBottom(typeParameterTypeNone(T));
    isBottom(typeParameterTypeQuestion(T));
    isBottom(typeParameterTypeStar(T));

    T = typeParameter('T', bound: neverQuestion);
    isNotBottom(typeParameterTypeNone(T));
    isNotBottom(typeParameterTypeQuestion(T));
    isNotBottom(typeParameterTypeStar(T));

    // BOTTOM(T) is false otherwise
    isNotBottom(dynamicNone);
    isNotBottom(voidNone);

    isNotBottom(objectNone);
    isNotBottom(objectQuestion);
    isNotBottom(objectStar);

    isNotBottom(intNone);
    isNotBottom(intQuestion);
    isNotBottom(intStar);

    T = typeParameter('T', bound: numNone);
    isNotBottom(typeParameterTypeNone(T));
    isNotBottom(typeParameterTypeQuestion(T));
    isNotBottom(typeParameterTypeStar(T));

    T = typeParameter('T', bound: numStar);
    isNotBottom(typeParameterTypeNone(T));
    isNotBottom(typeParameterTypeQuestion(T));
    isNotBottom(typeParameterTypeStar(T));

    isNotBottom(promotedTypeParameterTypeNone(T, intNone));
    isNotBottom(promotedTypeParameterTypeQuestion(T, intNone));
    isNotBottom(promotedTypeParameterTypeStar(T, intNone));
  }

  test_isMoreBottom() {
    // MOREBOTTOM(Never, T) = true
    isMoreBottom(neverNone, neverNone);
    isMoreBottom(neverNone, neverQuestion);
    isMoreBottom(neverNone, neverStar);

    isMoreBottom(neverNone, nullNone);
    isMoreBottom(neverNone, nullQuestion);
    isMoreBottom(neverNone, nullStar);

    // MOREBOTTOM(T, Never) = false
    isNotMoreBottom(neverQuestion, neverNone);
    isNotMoreBottom(neverStar, neverNone);

    isNotMoreBottom(nullNone, neverNone);
    isNotMoreBottom(nullQuestion, neverNone);
    isNotMoreBottom(nullStar, neverNone);

    // MOREBOTTOM(Null, T) = true
    isMoreBottom(nullNone, neverQuestion);
    isMoreBottom(nullNone, neverStar);

    isMoreBottom(nullNone, nullNone);
    isMoreBottom(nullNone, nullQuestion);
    isMoreBottom(nullNone, nullStar);

    // MOREBOTTOM(T, Null) = false
    isNotMoreBottom(neverQuestion, nullNone);
    isNotMoreBottom(neverStar, nullNone);

    isNotMoreBottom(nullQuestion, nullNone);
    isNotMoreBottom(nullStar, nullNone);

    // MOREBOTTOM(T?, S?) = MOREBOTTOM(T, S)
    isMoreBottom(neverQuestion, nullQuestion);
    isNotMoreBottom(nullQuestion, neverQuestion);

    // MOREBOTTOM(T, S?) = true
    isMoreBottom(neverStar, nullQuestion);
    isMoreBottom(nullStar, neverQuestion);

    // MOREBOTTOM(T?, S) = false
    isNotMoreBottom(neverQuestion, nullStar);
    isNotMoreBottom(nullQuestion, neverStar);

    // MOREBOTTOM(T*, S*) = MOREBOTTOM(T, S)
    isMoreBottom(neverStar, nullStar);
    isNotMoreBottom(nullStar, neverStar);

    // MOREBOTTOM(T, S*) = true
    isMoreBottom(
      typeParameterTypeNone(
        typeParameter('S', bound: neverNone),
      ),
      nullStar,
    );

    // MOREBOTTOM(T*, S) = false
    isNotMoreBottom(
      nullStar,
      typeParameterTypeNone(
        typeParameter('S', bound: neverNone),
      ),
    );

    // MOREBOTTOM(X&T, Y&S) = MOREBOTTOM(T, S)
    isMoreBottom(
      promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      ),
      promotedTypeParameterTypeQuestion(
        typeParameter('S', bound: objectQuestion),
        neverNone,
      ),
    );

    // MOREBOTTOM(X&T, S) = true
    isMoreBottom(
      promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      ),
      typeParameterTypeNone(
        typeParameter('S', bound: neverNone),
      ),
    );

    // MOREBOTTOM(T, X&S) = false
    isNotMoreBottom(
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
      promotedTypeParameterTypeNone(
        typeParameter('S', bound: objectQuestion),
        neverNone,
      ),
    );

    // MOREBOTTOM(X extends T, Y extends S) = MOREBOTTOM(T, S)
    isMoreBottom(
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
      typeParameterTypeQuestion(
        typeParameter('S', bound: neverNone),
      ),
    );
  }

  test_isMoreTop() {
    // MORETOP(void, T) = true
    isMoreTop(voidNone, voidNone);
    isMoreTop(voidNone, dynamicNone);
    isMoreTop(voidNone, objectNone);
    isMoreTop(voidNone, objectQuestion);
    isMoreTop(voidNone, objectStar);
    isMoreTop(voidNone, futureOrNone(objectNone));
    isMoreTop(voidNone, futureOrNone(objectQuestion));
    isMoreTop(voidNone, futureOrNone(objectStar));

    // MORETOP(T, void) = false
    isNotMoreTop(dynamicNone, voidNone);
    isNotMoreTop(objectNone, voidNone);
    isNotMoreTop(objectQuestion, voidNone);
    isNotMoreTop(objectStar, voidNone);
    isNotMoreTop(futureOrNone(objectNone), voidNone);
    isNotMoreTop(futureOrNone(objectQuestion), voidNone);
    isNotMoreTop(futureOrNone(objectStar), voidNone);

    // MORETOP(dynamic, T) = true
    isMoreTop(dynamicNone, dynamicNone);
    isMoreTop(dynamicNone, objectNone);
    isMoreTop(dynamicNone, objectQuestion);
    isMoreTop(dynamicNone, objectStar);
    isMoreTop(dynamicNone, futureOrNone(objectNone));
    isMoreTop(dynamicNone, futureOrNone(objectQuestion));
    isMoreTop(dynamicNone, futureOrNone(objectStar));

    // MORETOP(T, dynamic) = false
    isNotMoreTop(objectNone, dynamicNone);
    isNotMoreTop(objectQuestion, dynamicNone);
    isNotMoreTop(objectStar, dynamicNone);
    isNotMoreTop(futureOrNone(objectNone), dynamicNone);
    isNotMoreTop(futureOrNone(objectQuestion), dynamicNone);
    isNotMoreTop(futureOrNone(objectStar), dynamicNone);

    // MORETOP(Object, T) = true
    isMoreTop(objectNone, objectNone);
    isMoreTop(objectNone, objectQuestion);
    isMoreTop(objectNone, objectStar);
    isMoreTop(objectNone, futureOrNone(objectNone));
    isMoreTop(objectNone, futureOrQuestion(objectNone));
    isMoreTop(objectNone, futureOrStar(objectNone));

    // MORETOP(T, Object) = false
    isNotMoreTop(objectQuestion, objectNone);
    isNotMoreTop(objectStar, objectNone);
    isNotMoreTop(futureOrNone(objectNone), objectNone);
    isNotMoreTop(futureOrQuestion(objectNone), objectNone);
    isNotMoreTop(futureOrStar(objectNone), objectNone);

    // MORETOP(T*, S*) = MORETOP(T, S)
    isMoreTop(objectStar, objectStar);
    isMoreTop(objectStar, futureOrStar(objectNone));
    isMoreTop(objectStar, futureOrStar(objectQuestion));
    isMoreTop(objectStar, futureOrStar(objectStar));
    isMoreTop(futureOrStar(objectNone), futureOrStar(objectNone));

    // MORETOP(T, S*) = true
    isMoreTop(futureOrNone(objectNone), futureOrStar(voidNone));
    isMoreTop(futureOrNone(objectNone), futureOrStar(dynamicNone));
    isMoreTop(futureOrNone(objectNone), futureOrStar(objectNone));
    isMoreTop(futureOrQuestion(objectNone), futureOrStar(voidNone));
    isMoreTop(futureOrQuestion(objectNone), futureOrStar(dynamicNone));
    isMoreTop(futureOrQuestion(objectNone), futureOrStar(objectNone));

    // MORETOP(T*, S) = false
    isNotMoreTop(futureOrStar(voidNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrStar(dynamicNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrStar(objectNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrStar(voidNone), futureOrQuestion(objectNone));
    isNotMoreTop(futureOrStar(dynamicNone), futureOrQuestion(objectNone));
    isNotMoreTop(futureOrStar(objectNone), futureOrQuestion(objectNone));

    // MORETOP(T?, S?) = MORETOP(T, S)
    isMoreTop(objectQuestion, objectQuestion);
    isMoreTop(futureOrQuestion(voidNone), futureOrQuestion(voidNone));
    isMoreTop(futureOrQuestion(voidNone), futureOrQuestion(dynamicNone));
    isMoreTop(futureOrQuestion(voidNone), futureOrQuestion(objectNone));

    // MORETOP(T, S?) = true
    isMoreTop(futureOrNone(objectNone), futureOrQuestion(voidNone));
    isMoreTop(futureOrNone(objectNone), futureOrQuestion(dynamicNone));
    isMoreTop(futureOrNone(objectNone), futureOrQuestion(objectNone));

    // MORETOP(T?, S) = false
    isNotMoreTop(futureOrQuestion(voidNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrQuestion(dynamicNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrQuestion(objectNone), futureOrNone(objectNone));

    // MORETOP(FutureOr<T>, FutureOr<S>) = MORETOP(T, S)
    isMoreTop(futureOrNone(voidNone), futureOrNone(voidNone));
    isMoreTop(futureOrNone(voidNone), futureOrNone(dynamicNone));
    isMoreTop(futureOrNone(voidNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrNone(dynamicNone), futureOrNone(voidNone));
    isNotMoreTop(futureOrNone(objectNone), futureOrNone(voidNone));
  }

  test_isNull() {
    // NULL(Null) is true
    isNull(nullNone);

    // NULL(T?) is true iff NULL(T) or BOTTOM(T)
    isNull(nullQuestion);
    isNull(neverQuestion);
    isNull(
      typeParameterTypeQuestion(
        typeParameter('T', bound: neverNone),
      ),
    );

    // NULL(T*) is true iff NULL(T) or BOTTOM(T)
    isNull(nullStar);
    isNull(neverStar);
    isNull(
      typeParameterTypeStar(
        typeParameter('T', bound: neverNone),
      ),
    );

    // NULL(T) is false otherwise
    isNotNull(dynamicNone);
    isNotNull(voidNone);

    isNotNull(objectNone);
    isNotNull(objectQuestion);
    isNotNull(objectStar);

    isNotNull(intNone);
    isNotNull(intQuestion);
    isNotNull(intStar);

    isNotNull(futureOrNone(nullNone));
    isNotNull(futureOrNone(nullQuestion));
    isNotNull(futureOrNone(nullStar));

    isNotNull(futureOrQuestion(nullNone));
    isNotNull(futureOrQuestion(nullQuestion));
    isNotNull(futureOrQuestion(nullStar));

    isNotNull(futureOrStar(nullNone));
    isNotNull(futureOrStar(nullQuestion));
    isNotNull(futureOrStar(nullStar));
  }

  test_isObject() {
    // OBJECT(Object) is true
    isObject(objectNone);
    isNotObject(objectQuestion);
    isNotObject(objectStar);

    // OBJECT(FutureOr<T>) is OBJECT(T)
    isObject(futureOrNone(objectNone));
    isNotObject(futureOrNone(objectQuestion));
    isNotObject(futureOrNone(objectStar));

    isNotObject(futureOrQuestion(objectNone));
    isNotObject(futureOrQuestion(objectQuestion));
    isNotObject(futureOrQuestion(objectStar));

    isNotObject(futureOrStar(objectNone));
    isNotObject(futureOrStar(objectQuestion));
    isNotObject(futureOrStar(objectStar));

    // OBJECT(T) is false otherwise
    isNotObject(dynamicNone);
    isNotObject(voidNone);
    isNotObject(intNone);
  }

  test_isTop() {
    // TOP(T?) is true iff TOP(T) or OBJECT(T)
    isTop(objectQuestion);
    isTop(futureOrQuestion(dynamicNone));
    isTop(futureOrQuestion(voidNone));

    isTop(futureOrQuestion(objectNone));
    isTop(futureOrQuestion(objectQuestion));
    isTop(futureOrQuestion(objectStar));

    isNotTop(futureOrQuestion(intNone));
    isNotTop(futureOrQuestion(intQuestion));
    isNotTop(futureOrQuestion(intStar));

    // TOP(T*) is true iff TOP(T) or OBJECT(T)
    isTop(objectStar);
    isTop(futureOrStar(dynamicNone));
    isTop(futureOrStar(voidNone));

    isTop(futureOrStar(objectNone));
    isTop(futureOrStar(objectQuestion));
    isTop(futureOrStar(objectStar));

    isNotTop(futureOrStar(intNone));
    isNotTop(futureOrStar(intQuestion));
    isNotTop(futureOrStar(intStar));

    // TOP(dynamic) is true
    isTop(dynamicNone);
    isTop(UnknownInferredType.instance);

    // TOP(void) is true
    isTop(voidNone);

    // TOP(FutureOr<T>) is TOP(T)
    isTop(futureOrNone(dynamicNone));
    isTop(futureOrNone(voidNone));

    isNotTop(futureOrNone(objectNone));
    isTop(futureOrNone(objectQuestion));
    isTop(futureOrNone(objectStar));

    // TOP(T) is false otherwise
    isNotTop(objectNone);

    isNotTop(intNone);
    isNotTop(intQuestion);
    isNotTop(intStar);

    isNotTop(neverNone);
    isNotTop(neverQuestion);
    isNotTop(neverStar);
  }

  /// [TypeSystemImpl.isMoreBottom] can be used only for `BOTTOM` or `NULL`
  /// types. No need to check other types.
  void _assertIsBottomOrNull(DartType type) {
    expect(typeSystem.isBottom(type) || typeSystem.isNull(type), isTrue,
        reason: _typeString(type));
  }

  /// [TypeSystemImpl.isMoreTop] can be used only for `TOP` or `OBJECT`
  /// types. No need to check other types.
  void _assertIsTopOrObject(DartType type) {
    expect(typeSystem.isTop(type) || typeSystem.isObject(type), isTrue,
        reason: _typeString(type));
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
    void check(DartType T1, DartType T2) {
      expect(typeSystem.isBottom(T1), isTrue, reason: _typeString(T1));
      expect(typeSystem.isBottom(T2), isFalse, reason: _typeString(T2));
      _checkGreatestLowerBound(T1, T2, T1);
    }

    check(neverNone, objectNone);
    check(neverNone, objectStar);
    check(neverNone, objectQuestion);

    check(neverNone, intNone);
    check(neverNone, intQuestion);
    check(neverNone, intStar);

    check(neverNone, listNone(intNone));
    check(neverNone, listQuestion(intNone));
    check(neverNone, listStar(intNone));

    check(neverNone, futureOrNone(intNone));
    check(neverNone, futureOrQuestion(intNone));
    check(neverNone, futureOrStar(intNone));

    {
      var T = typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      );
      check(T, intNone);
      check(T, intQuestion);
      check(T, intStar);
    }

    {
      var T = promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      );
      check(T, intNone);
      check(T, intQuestion);
      check(T, intStar);
    }
  }

  test_bottom_bottom() {
    void check(DartType T1, DartType T2) {
      expect(typeSystem.isBottom(T1), isTrue, reason: _typeString(T1));
      expect(typeSystem.isBottom(T2), isTrue, reason: _typeString(T2));
      _checkGreatestLowerBound(T1, T2, T1);
    }

    check(
      neverNone,
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
    );

    check(
      neverNone,
      promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      ),
    );
  }

  test_functionType2_parameters_conflicts() {
    _checkGreatestLowerBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
      ),
      neverNone,
    );

    _checkGreatestLowerBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          positionalParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
      ),
      neverNone,
    );
  }

  test_functionType2_parameters_named() {
    FunctionType build(
      List<DartType> requiredTypes,
      Map<String, DartType> namedMap,
      Map<String, DartType> namedRequiredMap,
    ) {
      var parameters = <ParameterElement>[];

      for (var requiredType in requiredTypes) {
        parameters.add(
          requiredParameter(type: requiredType),
        );
      }

      for (var entry in namedMap.entries) {
        parameters.add(
          namedParameter(name: entry.key, type: entry.value),
        );
      }

      for (var entry in namedRequiredMap.entries) {
        parameters.add(
          namedRequiredParameter(name: entry.key, type: entry.value),
        );
      }

      return functionTypeNone(
        returnType: voidNone,
        parameters: parameters,
      );
    }

    void check(FunctionType T1, FunctionType T2, DartType expected) {
      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(
      build([], {}, {}),
      build([], {}, {}),
      build([], {}, {}),
    );

    {
      check(
        build([], {'a': intNone}, {}),
        build([], {'a': intNone}, {}),
        build([], {'a': intNone}, {}),
      );

      check(
        build([], {'a': intNone}, {}),
        build([], {}, {'a': intNone}),
        build([], {'a': intNone}, {}),
      );

      check(
        build([], {}, {'a': intNone}),
        build([], {}, {'a': intNone}),
        build([], {}, {'a': intNone}),
      );
    }

    {
      check(
        build([], {'a': intNone, 'b': intNone}, {}),
        build([], {'a': intNone, 'c': intNone}, {}),
        build([], {'a': intNone, 'b': intNone, 'c': intNone}, {}),
      );

      check(
        build([], {'a': intNone}, {'b': intNone}),
        build([], {'a': intNone}, {'c': intNone}),
        build([], {'a': intNone, 'b': intNone, 'c': intNone}, {}),
      );
    }

    {
      check(
        build([], {'a': intNone}, {}),
        build([], {'a': numNone}, {}),
        build([], {'a': numNone}, {}),
      );

      check(
        build([], {'a': intNone}, {}),
        build([], {'a': doubleNone}, {}),
        build([], {'a': numNone}, {}),
      );

      check(
        build([], {'a': intNone}, {}),
        build([], {'a': doubleQuestion}, {}),
        build([], {'a': numQuestion}, {}),
      );

      check(
        build([], {'a': intNone}, {}),
        build([], {'a': doubleStar}, {}),
        build([], {'a': numStar}, {}),
      );
    }
  }

  test_functionType2_parameters_positional() {
    FunctionType build(
      List<DartType> requiredTypes,
      List<DartType> positionalTypes,
    ) {
      var parameters = <ParameterElement>[];

      for (var requiredType in requiredTypes) {
        parameters.add(
          requiredParameter(type: requiredType),
        );
      }

      for (var positionalType in positionalTypes) {
        parameters.add(
          positionalParameter(type: positionalType),
        );
      }

      return functionTypeNone(
        returnType: voidNone,
        parameters: parameters,
      );
    }

    void check(FunctionType T1, FunctionType T2, DartType expected) {
      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(
      build([], []),
      build([], []),
      build([], []),
    );

    check(
      build([intNone], []),
      build([intNone], []),
      build([intNone], []),
    );

    check(
      build([intNone], []),
      build([numNone], []),
      build([numNone], []),
    );

    check(
      build([intNone], []),
      build([doubleNone], []),
      build([numNone], []),
    );

    check(
      build([intNone], []),
      build([doubleQuestion], []),
      build([numQuestion], []),
    );

    check(
      build([intNone], []),
      build([doubleStar], []),
      build([numStar], []),
    );

    {
      check(
        build([intNone], []),
        build([], [intNone]),
        build([], [intNone]),
      );

      check(
        build([intNone], []),
        build([], []),
        build([], [intNone]),
      );

      check(
        build([], [intNone]),
        build([], [intNone]),
        build([], [intNone]),
      );

      check(
        build([], [intNone]),
        build([], []),
        build([], [intNone]),
      );
    }
  }

  test_functionType2_returnType() {
    void check(DartType T1_ret, DartType T2_ret, DartType expected_ret) {
      _checkGreatestLowerBound(
        functionTypeNone(returnType: T1_ret),
        functionTypeNone(returnType: T2_ret),
        functionTypeNone(returnType: expected_ret),
      );
    }

    check(intNone, intNone, intNone);
    check(intNone, numNone, intNone);

    check(intNone, voidNone, intNone);
    check(intNone, neverNone, neverNone);
  }

  test_functionType2_typeParameters() {
    void check(FunctionType T1, FunctionType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _checkGreatestLowerBound(T1, T2, expected, checkSubtype: false);
    }

    check(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T'),
        ],
      ),
      functionTypeNone(returnType: voidNone),
      neverNone,
    );

    check(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T', bound: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T', bound: numNone),
        ],
      ),
      neverNone,
    );

    {
      var T = typeParameter('T', bound: numNone);
      var U = typeParameter('U', bound: numNone);
      var R = typeParameter('R', bound: numNone);
      check(
        functionTypeNone(
          returnType: typeParameterTypeNone(T),
          typeFormals: [T],
        ),
        functionTypeNone(
          returnType: typeParameterTypeNone(U),
          typeFormals: [U],
        ),
        functionTypeNone(
          returnType: typeParameterTypeNone(R),
          typeFormals: [R],
        ),
      );
    }
  }

  test_functionType_interfaceType() {
    void check(FunctionType T1, InterfaceType T2, DartType expected) {
      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(
      functionTypeNone(returnType: voidNone),
      intNone,
      neverNone,
    );
  }

  test_functionType_interfaceType_Function() {
    void check(FunctionType T1) {
      _assertNullabilityNone(T1);
      _checkGreatestLowerBound(T1, functionNone, T1);
    }

    check(functionTypeNone(returnType: voidNone));

    check(
      functionTypeNone(
        returnType: intNone,
        parameters: [
          requiredParameter(type: numQuestion),
        ],
      ),
    );
  }

  test_futureOr() {
    InterfaceType futureOrFunction(DartType T, String str) {
      var result = futureOrNone(
        functionTypeNone(returnType: voidNone, parameters: [
          requiredParameter(type: T),
        ]),
      );
      expect(result.getDisplayString(withNullability: true), str);
      return result;
    }

    // DOWN(FutureOr<T1>, FutureOr<T2>) = FutureOr<S>, S = DOWN(T1, T2)
    _checkGreatestLowerBound(
      futureOrNone(intNone),
      futureOrNone(numNone),
      futureOrNone(intNone),
    );
    _checkGreatestLowerBound(
      futureOrFunction(intNone, 'FutureOr<void Function(int)>'),
      futureOrFunction(doubleNone, 'FutureOr<void Function(double)>'),
      futureOrFunction(numNone, 'FutureOr<void Function(num)>'),
    );

    // DOWN(FutureOr<T1>, Future<T2>) = Future<S>, S = DOWN(T1, T2)
    // DOWN(Future<T1>, FutureOr<T2>) = Future<S>, S = DOWN(T1, T2)
    _checkGreatestLowerBound(
      futureOrNone(numNone),
      futureNone(intNone),
      futureNone(intNone),
    );
    _checkGreatestLowerBound(
      futureOrNone(intNone),
      futureNone(numNone),
      futureNone(intNone),
    );

    // DOWN(FutureOr<T1>, T2) = S, S = DOWN(T1, T2)
    // DOWN(T1, FutureOr<T2>) = S, S = DOWN(T1, T2)
    _checkGreatestLowerBound(
      futureOrNone(numNone),
      intNone,
      intNone,
    );
    _checkGreatestLowerBound(
      futureOrNone(intNone),
      numNone,
      intNone,
    );
  }

  test_identical() {
    void check(DartType type) {
      _checkGreatestLowerBound(type, type, type);
    }

    check(intNone);
    check(intQuestion);
    check(intStar);
    check(listNone(intNone));
  }

  test_interfaceType2() {
    void check(InterfaceType T1, InterfaceType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intNone, intNone, intNone);
    check(numNone, intNone, intNone);
    check(doubleNone, intNone, neverNone);

    check(listNone(intNone), listNone(intNone), listNone(intNone));
    check(listNone(numNone), listNone(intNone), listNone(intNone));
    check(listNone(doubleNone), listNone(intNone), neverNone);
  }

  void test_interfaceType2_interfaces() {
    // class A
    // class B implements A
    // class C implements B
    var A = class_(name: 'A');
    var B = class_(name: 'B', interfaces: [interfaceTypeNone(A)]);
    var C = class_(name: 'C', interfaces: [interfaceTypeNone(B)]);
    _checkGreatestLowerBound(
      interfaceTypeNone(A),
      interfaceTypeNone(C),
      interfaceTypeNone(C),
    );
  }

  void test_interfaceType2_mixins() {
    // class A
    // class B
    // class C
    // class D extends A with B, C
    var A = class_(name: 'A');
    var typeA = interfaceTypeNone(A);

    var B = class_(name: 'B');
    var typeB = interfaceTypeNone(B);

    var C = class_(name: 'C');
    var typeC = interfaceTypeNone(C);

    var D = class_(
      name: 'D',
      superType: interfaceTypeNone(A),
      mixins: [typeB, typeC],
    );
    var typeD = interfaceTypeNone(D);

    _checkGreatestLowerBound(typeA, typeD, typeD);
    _checkGreatestLowerBound(typeB, typeD, typeD);
    _checkGreatestLowerBound(typeC, typeD, typeD);
  }

  void test_interfaceType2_superType() {
    // class A
    // class B extends A
    // class C extends B
    var A = class_(name: 'A');
    var B = class_(name: 'B', superType: interfaceTypeNone(A));
    var C = class_(name: 'C', superType: interfaceTypeNone(B));
    _checkGreatestLowerBound(
      interfaceTypeNone(A),
      interfaceTypeNone(C),
      interfaceTypeNone(C),
    );
  }

  test_none_question() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intNone, intQuestion, intNone);

    check(numNone, intQuestion, intNone);
    check(intNone, numQuestion, intNone);

    check(doubleNone, intQuestion, neverNone);
    check(intNone, doubleQuestion, neverNone);
  }

  test_none_star() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intNone, intStar, intNone);

    check(numNone, intStar, intNone);
    check(intNone, numStar, intNone);

    check(doubleNone, intStar, neverNone);
    check(intNone, doubleStar, neverNone);
  }

  test_null_any() {
    void check(DartType T2, DartType expected) {
      var T2_str = _typeString(T2);

      expect(typeSystem.isNull(T2), isFalse, reason: 'isNull: $T2_str');
      expect(typeSystem.isTop(T2), isFalse, reason: 'isTop: $T2_str');
      expect(typeSystem.isBottom(T2), isFalse, reason: 'isBottom: $T2_str');

      _checkGreatestLowerBound(nullNone, T2, expected);
    }

    void checkNull(DartType T2) {
      check(T2, nullNone);
    }

    void checkNever(DartType T2) {
      check(T2, neverNone);
    }

    checkNull(futureOrNone(nullNone));
    checkNull(futureOrNone(nullQuestion));
    checkNull(futureOrNone(nullStar));

    checkNull(futureOrQuestion(nullNone));
    checkNull(futureOrQuestion(nullQuestion));
    checkNull(futureOrQuestion(nullStar));

    checkNull(futureOrStar(nullNone));
    checkNull(futureOrStar(nullQuestion));
    checkNull(futureOrStar(nullStar));

    checkNever(objectNone);

    checkNever(intNone);
    checkNull(intQuestion);
    checkNull(intStar);

    checkNever(listNone(intNone));
    checkNull(listQuestion(intNone));
    checkNull(listStar(intNone));

    checkNever(listNone(intQuestion));
    checkNull(listQuestion(intQuestion));
    checkNull(listStar(intQuestion));
  }

  test_null_null() {
    void check(DartType T1, DartType T2) {
      var T1_str = _typeString(T1);
      var T2_str = _typeString(T2);

      expect(typeSystem.isNull(T1), isTrue, reason: 'isNull: $T1_str');
      expect(typeSystem.isNull(T2), isTrue, reason: 'isNull: $T2_str');

      expect(typeSystem.isBottom(T1), isFalse, reason: 'isBottom: $T1_str');
      expect(typeSystem.isBottom(T2), isFalse, reason: 'isBottom: $T2_str');

      _checkGreatestLowerBound(T1, T2, T1);
    }

    check(nullNone, nullQuestion);
    check(nullNone, nullStar);
  }

  test_object_any() {
    void check(DartType T2, DartType expected) {
      var T2_str = _typeString(T2);
      expect(typeSystem.isObject(T2), isFalse, reason: 'isObject: $T2_str');

      _checkGreatestLowerBound(objectNone, T2, expected);
    }

    void checkNever(DartType T2) {
      check(T2, neverNone);
    }

    check(intNone, intNone);
    check(intQuestion, intNone);
    check(intStar, intStar);

    check(futureOrNone(intNone), futureOrNone(intNone));
    check(futureOrQuestion(intNone), futureOrNone(intNone));
    check(futureOrNone(intNone), futureOrNone(intNone));

    checkNever(futureOrNone(intQuestion));
    checkNever(futureOrQuestion(intQuestion));
    checkNever(futureOrNone(intQuestion));

    {
      var T = typeParameter('T', bound: objectNone);
      check(typeParameterTypeNone(T), typeParameterTypeNone(T));
      check(typeParameterTypeQuestion(T), typeParameterTypeNone(T));
      check(typeParameterTypeStar(T), typeParameterTypeStar(T));
    }

    {
      var T = typeParameter('T', bound: objectQuestion);
      check(
        typeParameterTypeNone(T),
        promotedTypeParameterTypeNone(T, objectNone),
      );
      check(
        typeParameterTypeQuestion(T),
        promotedTypeParameterTypeNone(T, objectNone),
      );
      check(
        typeParameterTypeStar(T),
        promotedTypeParameterTypeNone(T, objectNone),
      );
    }

    {
      var T = typeParameter('T', bound: futureOrNone(objectQuestion));
      checkNever(typeParameterTypeNone(T));
      checkNever(typeParameterTypeQuestion(T));
      checkNever(typeParameterTypeStar(T));
    }
  }

  test_object_object() {
    void check(DartType T1, DartType T2) {
      var T1_str = _typeString(T1);
      var T2_str = _typeString(T2);

      expect(typeSystem.isObject(T1), isTrue, reason: 'isObject: $T1_str');
      expect(typeSystem.isObject(T2), isTrue, reason: 'isObject: $T2_str');

      _checkGreatestLowerBound(T1, T2, T1);
    }

    check(futureOrNone(objectNone), objectNone);

    check(
      futureOrNone(
        futureOrNone(objectNone),
      ),
      futureOrNone(objectNone),
    );
  }

  test_question_question() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityQuestion(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intQuestion, intQuestion, intQuestion);

    check(numQuestion, intQuestion, intQuestion);
    check(intQuestion, numQuestion, intQuestion);

    check(doubleQuestion, intQuestion, neverQuestion);
    check(intQuestion, doubleQuestion, neverQuestion);
  }

  test_self() {
    var T = typeParameter('T');

    List<DartType> types = [
      dynamicType,
      voidNone,
      neverNone,
      typeParameterTypeStar(T),
      intNone,
      functionTypeNone(returnType: voidNone),
    ];

    for (var type in types) {
      _checkGreatestLowerBound(type, type, type);
    }
  }

  test_star_question() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityQuestion(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intQuestion, intStar, intStar);

    check(numQuestion, intStar, intStar);
    check(intQuestion, numStar, intStar);

    check(doubleQuestion, intStar, neverStar);
    check(intQuestion, doubleStar, neverStar);
  }

  test_star_star() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityStar(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intStar, numStar, intStar);
    check(intStar, doubleStar, neverStar);
  }

  test_top_any() {
    void check(DartType T1, DartType T2) {
      expect(typeSystem.isTop(T1), isTrue, reason: _typeString(T1));
      expect(typeSystem.isTop(T2), isFalse, reason: _typeString(T2));
      _checkGreatestLowerBound(T1, T2, T2);
    }

    check(voidNone, objectNone);
    check(voidNone, intNone);
    check(voidNone, intQuestion);
    check(voidNone, intStar);
    check(voidNone, listNone(intNone));
    check(voidNone, futureOrNone(intNone));
    check(voidNone, neverNone);
    check(voidNone, functionTypeNone(returnType: voidNone));

    check(dynamicNone, objectNone);
    check(dynamicNone, intNone);
    check(dynamicNone, intQuestion);
    check(dynamicNone, intStar);
    check(dynamicNone, listNone(intNone));
    check(dynamicNone, futureOrNone(intNone));
    check(dynamicNone, neverNone);
    check(dynamicNone, functionTypeNone(returnType: voidNone));

    check(objectQuestion, objectNone);
    check(objectQuestion, intNone);
    check(objectQuestion, intQuestion);
    check(objectQuestion, intStar);
    check(objectQuestion, listNone(intNone));
    check(objectQuestion, futureOrNone(intNone));
    check(objectQuestion, neverNone);
    check(objectQuestion, functionTypeNone(returnType: voidNone));

    check(objectStar, objectNone);
    check(objectStar, intNone);
    check(objectStar, intQuestion);
    check(objectStar, intStar);
    check(objectStar, listNone(intNone));
    check(objectStar, futureOrNone(intNone));
    check(objectStar, neverNone);
    check(objectStar, functionTypeNone(returnType: voidNone));

    check(futureOrNone(voidNone), intNone);
    check(futureOrQuestion(voidNone), intNone);
    check(futureOrStar(voidNone), intNone);
  }

  test_top_top() {
    void check(DartType T1, DartType T2) {
      expect(typeSystem.isTop(T1), isTrue, reason: _typeString(T1));
      expect(typeSystem.isTop(T2), isTrue, reason: _typeString(T2));
      _checkGreatestLowerBound(T1, T2, T2);
    }

    check(voidNone, dynamicNone);
    check(voidNone, objectStar);
    check(voidNone, objectQuestion);
    check(voidNone, futureOrNone(voidNone));
    check(voidNone, futureOrNone(dynamicNone));
    check(voidNone, futureOrNone(objectQuestion));
    check(voidNone, futureOrNone(objectStar));

    check(dynamicNone, objectStar);
    check(dynamicNone, objectQuestion);
    check(dynamicNone, futureOrNone(voidNone));
    check(dynamicNone, futureOrNone(dynamicNone));
    check(dynamicNone, futureOrNone(objectQuestion));
    check(dynamicNone, futureOrNone(objectStar));
    check(
      dynamicNone,
      futureOrStar(objectStar),
    );

    check(objectQuestion, futureOrQuestion(voidNone));
    check(objectQuestion, futureOrQuestion(dynamicNone));
    check(objectQuestion, futureOrQuestion(objectNone));
    check(objectQuestion, futureOrQuestion(objectQuestion));
    check(objectQuestion, futureOrQuestion(objectStar));

    check(objectQuestion, futureOrStar(voidNone));
    check(objectQuestion, futureOrStar(dynamicNone));
    check(objectQuestion, futureOrStar(objectNone));
    check(objectQuestion, futureOrStar(objectQuestion));
    check(objectQuestion, futureOrStar(objectStar));

    check(objectStar, futureOrStar(voidNone));
    check(objectStar, futureOrStar(dynamicNone));
    check(objectStar, futureOrStar(objectNone));
    check(objectStar, futureOrStar(objectQuestion));
    check(objectStar, futureOrStar(objectStar));

    check(futureOrNone(voidNone), objectQuestion);
    check(futureOrNone(dynamicNone), objectQuestion);
    check(futureOrNone(objectQuestion), objectQuestion);
    check(futureOrNone(objectStar), objectQuestion);

    check(futureOrNone(voidNone), futureOrNone(dynamicNone));
    check(futureOrNone(voidNone), futureOrNone(objectQuestion));
    check(futureOrNone(voidNone), futureOrNone(objectStar));
    check(futureOrNone(dynamicNone), futureOrNone(objectQuestion));
    check(futureOrNone(dynamicNone), futureOrNone(objectStar));
  }

  test_typeParameter() {
    void check({DartType bound, DartType T2}) {
      var T1 = typeParameterTypeNone(
        typeParameter('T', bound: bound),
      );
      _checkGreatestLowerBound(T1, T2, neverNone);
    }

    check(
      bound: null,
      T2: functionTypeNone(returnType: voidNone),
    );
    check(bound: null, T2: intNone);
    check(bound: numNone, T2: intNone);
  }

  void _checkGreatestLowerBound(DartType T1, DartType T2, DartType expected,
      {bool checkSubtype = true}) {
    var expectedStr = _typeString(expected);

    var result = typeSystem.getGreatestLowerBound(T1, T2);
    var resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');

    // Check that the result is a lower bound.
    if (checkSubtype) {
      expect(typeSystem.isSubtypeOf2(result, T1), true);
      expect(typeSystem.isSubtypeOf2(result, T2), true);
    }

    // Check for symmetry.
    result = typeSystem.getGreatestLowerBound(T2, T1);
    resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');
  }
}

@reflectiveTest
class UpperBoundTest extends _BoundsTestBase {
  test_bottom_any() {
    void check(DartType T1, DartType T2) {
      expect(typeSystem.isBottom(T1), isTrue, reason: _typeString(T1));
      expect(typeSystem.isBottom(T2), isFalse, reason: _typeString(T2));
      _checkLeastUpperBound(T1, T2, T2);
    }

    check(neverNone, objectNone);
    check(neverNone, objectStar);
    check(neverNone, objectQuestion);

    check(neverNone, intNone);
    check(neverNone, intQuestion);
    check(neverNone, intStar);

    check(neverNone, listNone(intNone));
    check(neverNone, listQuestion(intNone));
    check(neverNone, listStar(intNone));

    check(neverNone, futureOrNone(intNone));
    check(neverNone, futureOrQuestion(intNone));
    check(neverNone, futureOrStar(intNone));

    {
      var T = typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      );
      check(T, intNone);
      check(T, intQuestion);
      check(T, intStar);
    }

    {
      var T = promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      );
      check(T, intNone);
      check(T, intQuestion);
      check(T, intStar);
    }
  }

  test_bottom_bottom() {
    void check(DartType T1, DartType T2) {
      expect(typeSystem.isBottom(T1), isTrue, reason: _typeString(T1));
      expect(typeSystem.isBottom(T2), isTrue, reason: _typeString(T2));
      _checkLeastUpperBound(T1, T2, T2);
    }

    check(
      neverNone,
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
    );

    check(
      neverNone,
      promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      ),
    );
  }

  test_functionType2_parameters_optionalNamed() {
    FunctionType build(Map<String, DartType> namedTypes) {
      return functionTypeNone(
        returnType: voidNone,
        parameters: namedTypes.entries.map((entry) {
          return namedParameter(name: entry.key, type: entry.value);
        }).toList(),
      );
    }

    void check(Map<String, DartType> T1_named, Map<String, DartType> T2_named,
        Map<String, DartType> expected_named) {
      var T1 = build(T1_named);
      var T2 = build(T2_named);
      var expected = build(expected_named);
      _checkLeastUpperBound(T1, T2, expected);
    }

    check({'a': intNone}, {}, {});
    check({'a': intNone}, {'b': intNone}, {});

    check({'a': intNone}, {'a': intNone}, {'a': intNone});
    check({'a': intNone}, {'a': intQuestion}, {'a': intNone});

    check({'a': intNone, 'b': doubleNone}, {'a': intNone}, {'a': intNone});
  }

  test_functionType2_parameters_optionalPositional() {
    FunctionType build(List<DartType> positionalTypes) {
      return functionTypeNone(
        returnType: voidNone,
        parameters: positionalTypes.map((type) {
          return positionalParameter(type: type);
        }).toList(),
      );
    }

    void check(List<DartType> T1_positional, List<DartType> T2_positional,
        DartType expected) {
      var T1 = build(T1_positional);
      var T2 = build(T2_positional);
      _checkLeastUpperBound(T1, T2, expected);
    }

    check([intNone], [], build([]));
    check([intNone, doubleNone], [intNone], build([intNone]));

    check([intNone], [intNone], build([intNone]));
    check([intNone], [intQuestion], build([intNone]));

    check([intNone], [intStar], build([intNone]));
    check([intNone], [doubleNone], build([neverNone]));

    check([intNone], [numNone], build([intNone]));

    check(
      [doubleNone, numNone],
      [numNone, intNone],
      build([doubleNone, intNone]),
    );
  }

  test_functionType2_parameters_requiredNamed() {
    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionNone,
    );

    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          positionalParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionNone,
    );

    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'b', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionNone,
    );

    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
    );

    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
          namedRequiredParameter(name: 'b', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'b', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'b', type: intNone),
        ],
      ),
    );

    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: numNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
    );
  }

  test_functionType2_parameters_requiredPositional() {
    FunctionType build(List<DartType> requiredTypes) {
      return functionTypeNone(
        returnType: voidNone,
        parameters: requiredTypes.map((type) {
          return requiredParameter(type: type);
        }).toList(),
      );
    }

    void check(List<DartType> T1_required, List<DartType> T2_required,
        DartType expected) {
      var T1 = build(T1_required);
      var T2 = build(T2_required);
      _checkLeastUpperBound(T1, T2, expected);
    }

    check([intNone], [], functionNone);

    check([intNone], [intNone], build([intNone]));
    check([intNone], [intQuestion], build([intNone]));

    check([intNone], [intStar], build([intNone]));
    check([intNone], [doubleNone], build([neverNone]));

    check([intNone], [numNone], build([intNone]));

    check(
      [doubleNone, numNone],
      [numNone, intNone],
      build([doubleNone, intNone]),
    );
  }

  test_functionType2_returnType() {
    void check(DartType T1_ret, DartType T2_ret, DartType expected_ret) {
      _checkLeastUpperBound(
        functionTypeNone(returnType: T1_ret),
        functionTypeNone(returnType: T2_ret),
        functionTypeNone(returnType: expected_ret),
      );
    }

    check(intNone, intNone, intNone);
    check(intNone, intQuestion, intQuestion);
    check(intNone, intStar, intStar);

    check(intNone, numNone, numNone);
    check(intQuestion, numNone, numQuestion);
    check(intStar, numNone, numStar);

    check(intNone, dynamicNone, dynamicNone);
    check(intNone, neverNone, intNone);
  }

  test_functionType2_typeParameters() {
    void check(FunctionType T1, FunctionType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T'),
        ],
      ),
      functionTypeNone(returnType: voidNone),
      functionNone,
    );

    check(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T', bound: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T', bound: numNone),
        ],
      ),
      functionNone,
    );

    {
      var T = typeParameter('T', bound: numNone);
      var U = typeParameter('U', bound: numNone);
      var R = typeParameter('R', bound: numNone);
      check(
        functionTypeNone(
          returnType: typeParameterTypeNone(T),
          typeFormals: [T],
        ),
        functionTypeNone(
          returnType: typeParameterTypeNone(U),
          typeFormals: [U],
        ),
        functionTypeNone(
          returnType: typeParameterTypeNone(R),
          typeFormals: [R],
        ),
      );
    }
  }

  test_functionType_interfaceType() {
    void check(FunctionType T1, InterfaceType T2, InterfaceType expected) {
      _checkLeastUpperBound(T1, T2, expected);
    }

    check(
      functionTypeNone(returnType: voidNone),
      intNone,
      objectNone,
    );
  }

  test_functionType_interfaceType_Function() {
    void check(FunctionType T1, InterfaceType T2, InterfaceType expected) {
      _checkLeastUpperBound(T1, T2, expected);
    }

    void checkNone(FunctionType T1) {
      _assertNullabilityNone(T1);
      check(T1, functionNone, functionNone);
    }

    checkNone(functionTypeNone(returnType: voidNone));

    checkNone(
      functionTypeNone(
        returnType: intNone,
        parameters: [
          requiredParameter(type: numQuestion),
        ],
      ),
    );

    check(
      functionTypeQuestion(returnType: voidNone),
      functionNone,
      functionQuestion,
    );
  }

  test_identical() {
    void check(DartType type) {
      _checkLeastUpperBound(type, type, type);
    }

    check(intNone);
    check(intQuestion);
    check(intStar);
    check(listNone(intNone));
  }

  test_none_question() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(doubleNone, intQuestion, numQuestion);
    check(numNone, doubleQuestion, numQuestion);
    check(numNone, intQuestion, numQuestion);
  }

  test_none_star() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(doubleNone, intStar, numStar);
    check(numNone, doubleStar, numStar);
    check(numNone, intStar, numStar);
  }

  test_null_any() {
    void check(DartType T1, DartType T2, DartType expected) {
      var T1_str = _typeString(T1);
      var T2_str = _typeString(T2);

      expect(typeSystem.isNull(T1), isTrue, reason: 'isNull: $T1_str');
      expect(typeSystem.isNull(T2), isFalse, reason: 'isNull: $T2_str');

      expect(typeSystem.isTop(T1), isFalse, reason: 'isTop: $T1_str');
      expect(typeSystem.isTop(T2), isFalse, reason: 'isTop: $T2_str');

      expect(typeSystem.isBottom(T1), isFalse, reason: 'isBottom: $T1_str');
      expect(typeSystem.isBottom(T2), isFalse, reason: 'isBottom: $T2_str');

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(nullNone, objectNone, objectQuestion);

    check(nullNone, intNone, intQuestion);
    check(nullNone, intQuestion, intQuestion);
    check(nullNone, intStar, intStar);

    check(nullQuestion, intNone, intQuestion);
    check(nullQuestion, intQuestion, intQuestion);
    check(nullQuestion, intStar, intStar);

    check(nullStar, intNone, intStar);
    check(nullStar, intQuestion, intQuestion);
    check(nullStar, intStar, intStar);

    check(nullNone, listNone(intNone), listQuestion(intNone));
    check(nullNone, listQuestion(intNone), listQuestion(intNone));
    check(nullNone, listStar(intNone), listStar(intNone));

    check(nullNone, futureOrNone(intNone), futureOrQuestion(intNone));
    check(nullNone, futureOrQuestion(intNone), futureOrQuestion(intNone));
    check(nullNone, futureOrStar(intNone), futureOrStar(intNone));

    check(nullNone, futureOrNone(intQuestion), futureOrNone(intQuestion));
    check(nullNone, futureOrStar(intQuestion), futureOrStar(intQuestion));

    check(
      nullNone,
      functionTypeNone(returnType: intNone),
      functionTypeQuestion(returnType: intNone),
    );
  }

  test_null_null() {
    void check(DartType T1, DartType T2) {
      var T1_str = _typeString(T1);
      var T2_str = _typeString(T2);

      expect(typeSystem.isNull(T1), isTrue, reason: 'isNull: $T1_str');
      expect(typeSystem.isNull(T2), isTrue, reason: 'isNull: $T2_str');

      expect(typeSystem.isBottom(T1), isFalse, reason: 'isBottom: $T1_str');
      expect(typeSystem.isBottom(T2), isFalse, reason: 'isBottom: $T2_str');

      _checkLeastUpperBound(T1, T2, T2);
    }

    check(nullNone, nullQuestion);
    check(nullNone, nullStar);
  }

  test_object_any() {
    void check(DartType T1, DartType T2, DartType expected) {
      var T1_str = _typeString(T1);
      var T2_str = _typeString(T2);

      expect(typeSystem.isObject(T1), isTrue, reason: 'isObject: $T1_str');
      expect(typeSystem.isObject(T2), isFalse, reason: 'isObject: $T2_str');

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(objectNone, intNone, objectNone);
    check(objectNone, intQuestion, objectQuestion);
    check(objectNone, intStar, objectNone);

    check(objectNone, futureOrNone(intQuestion), objectQuestion);

    check(futureOrNone(objectNone), intNone, futureOrNone(objectNone));
    check(futureOrNone(objectNone), intQuestion, futureOrQuestion(objectNone));
    check(futureOrNone(objectNone), intStar, futureOrNone(objectNone));
  }

  test_object_object() {
    void check(DartType T1, DartType T2) {
      var T1_str = _typeString(T1);
      var T2_str = _typeString(T2);

      expect(typeSystem.isObject(T1), isTrue, reason: 'isObject: $T1_str');
      expect(typeSystem.isObject(T2), isTrue, reason: 'isObject: $T2_str');

      _checkLeastUpperBound(T1, T2, T2);
    }

    check(futureOrNone(objectNone), objectNone);

    check(
      futureOrNone(
        futureOrNone(objectNone),
      ),
      futureOrNone(objectNone),
    );
  }

  test_question_question() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityQuestion(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(doubleQuestion, intQuestion, numQuestion);
    check(numQuestion, doubleQuestion, numQuestion);
    check(numQuestion, intQuestion, numQuestion);
  }

  test_question_star() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityQuestion(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(doubleQuestion, intStar, numQuestion);
    check(numQuestion, doubleStar, numQuestion);
    check(numQuestion, intStar, numQuestion);
  }

  test_star_star() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityStar(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(doubleStar, intStar, numStar);
    check(numStar, doubleStar, numStar);
    check(numStar, intStar, numStar);
  }

  test_top_any() {
    void check(DartType T1, DartType T2) {
      expect(typeSystem.isTop(T1), isTrue, reason: _typeString(T1));
      expect(typeSystem.isTop(T2), isFalse, reason: _typeString(T2));
      _checkLeastUpperBound(T1, T2, T1);
    }

    check(voidNone, objectNone);
    check(voidNone, intNone);
    check(voidNone, intQuestion);
    check(voidNone, intStar);
    check(voidNone, listNone(intNone));
    check(voidNone, futureOrNone(intNone));

    check(dynamicNone, objectNone);
    check(dynamicNone, intNone);
    check(dynamicNone, intQuestion);
    check(dynamicNone, intStar);
    check(dynamicNone, listNone(intNone));
    check(dynamicNone, futureOrNone(intNone));

    check(objectQuestion, objectNone);
    check(objectQuestion, intNone);
    check(objectQuestion, intQuestion);
    check(objectQuestion, intStar);
    check(objectQuestion, listNone(intNone));
    check(objectQuestion, futureOrNone(intNone));

    check(objectStar, objectNone);
    check(objectStar, intNone);
    check(objectStar, intQuestion);
    check(objectStar, intStar);
    check(objectStar, listNone(intNone));
    check(objectStar, futureOrNone(intNone));

    check(futureOrNone(voidNone), intNone);
    check(futureOrQuestion(voidNone), intNone);
    check(futureOrStar(voidNone), intNone);
  }

  test_top_top() {
    void check(DartType T1, DartType T2) {
      expect(typeSystem.isTop(T1), isTrue, reason: _typeString(T1));
      expect(typeSystem.isTop(T2), isTrue, reason: _typeString(T2));
      _checkLeastUpperBound(T1, T2, T1);
    }

    check(voidNone, dynamicNone);
    check(voidNone, objectStar);
    check(voidNone, objectQuestion);
    check(voidNone, futureOrNone(voidNone));
    check(voidNone, futureOrNone(dynamicNone));
    check(voidNone, futureOrNone(objectQuestion));
    check(voidNone, futureOrNone(objectStar));

    check(dynamicNone, objectStar);
    check(dynamicNone, objectQuestion);
    check(dynamicNone, futureOrNone(voidNone));
    check(dynamicNone, futureOrNone(dynamicNone));
    check(dynamicNone, futureOrNone(objectQuestion));
    check(dynamicNone, futureOrNone(objectStar));
    check(
      dynamicNone,
      futureOrStar(objectStar),
    );

    check(objectQuestion, futureOrQuestion(voidNone));
    check(objectQuestion, futureOrQuestion(dynamicNone));
    check(objectQuestion, futureOrQuestion(objectNone));
    check(objectQuestion, futureOrQuestion(objectQuestion));
    check(objectQuestion, futureOrQuestion(objectStar));

    check(objectQuestion, futureOrStar(voidNone));
    check(objectQuestion, futureOrStar(dynamicNone));
    check(objectQuestion, futureOrStar(objectNone));
    check(objectQuestion, futureOrStar(objectQuestion));
    check(objectQuestion, futureOrStar(objectStar));

    check(objectStar, futureOrStar(voidNone));
    check(objectStar, futureOrStar(dynamicNone));
    check(objectStar, futureOrStar(objectNone));
    check(objectStar, futureOrStar(objectQuestion));
    check(objectStar, futureOrStar(objectStar));

    check(futureOrNone(voidNone), objectQuestion);
    check(futureOrNone(dynamicNone), objectQuestion);
    check(futureOrNone(objectQuestion), objectQuestion);
    check(futureOrNone(objectStar), objectQuestion);

    check(futureOrNone(voidNone), futureOrNone(dynamicNone));
    check(futureOrNone(voidNone), futureOrNone(objectQuestion));
    check(futureOrNone(voidNone), futureOrNone(objectStar));
    check(futureOrNone(dynamicNone), futureOrNone(objectQuestion));
    check(futureOrNone(dynamicNone), futureOrNone(objectStar));
  }

  test_typeParameter_bound() {
    void check(TypeParameterType T1, DartType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    {
      var T = typeParameter('T', bound: intNone);
      check(typeParameterTypeNone(T), numNone, numNone);
    }

    {
      var T = typeParameter('T', bound: intNone);
      var U = typeParameter('U', bound: numNone);
      check(typeParameterTypeNone(T), typeParameterTypeNone(U), numNone);
    }

    {
      var T = typeParameter('T', bound: intNone);
      var U = typeParameter('U', bound: numQuestion);
      check(typeParameterTypeNone(T), typeParameterTypeNone(U), numQuestion);
    }

    {
      var T = typeParameter('T', bound: intQuestion);
      var U = typeParameter('U', bound: numNone);
      check(typeParameterTypeNone(T), typeParameterTypeNone(U), numQuestion);
    }

    {
      var T = typeParameter('T', bound: numNone);
      var T_none = typeParameterTypeNone(T);
      var U = typeParameter('U', bound: T_none);
      check(T_none, typeParameterTypeNone(U), T_none);
    }
  }

  void _checkLeastUpperBound(DartType T1, DartType T2, DartType expected) {
    var expectedStr = _typeString(expected);

    var result = typeSystem.getLeastUpperBound(T1, T2);
    var resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');

    // Check that the result is an upper bound.
    expect(typeSystem.isSubtypeOf2(T1, result), true);
    expect(typeSystem.isSubtypeOf2(T2, result), true);

    // Check for symmetry.
    result = typeSystem.getLeastUpperBound(T2, T1);
    resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');
  }
}

@reflectiveTest
class _BoundsTestBase extends AbstractTypeSystemNullSafetyTest {
  void _assertNotBottom(DartType type) {
    if (typeSystem.isBottom(type)) {
      fail('isBottom must be false: ' + _typeString(type));
    }
  }

  void _assertNotNull(DartType type) {
    if (typeSystem.isNull(type)) {
      fail('isNull must be false: ' + _typeString(type));
    }
  }

  void _assertNotObject(DartType type) {
    if (typeSystem.isObject(type)) {
      fail('isObject must be false: ' + _typeString(type));
    }
  }

  void _assertNotSpecial(DartType type) {
    _assertNotBottom(type);
    _assertNotNull(type);
    _assertNotObject(type);
    _assertNotTop(type);
  }

  void _assertNotTop(DartType type) {
    if (typeSystem.isTop(type)) {
      fail('isTop must be false: ' + _typeString(type));
    }
  }

  void _assertNullability(DartType type, NullabilitySuffix expected) {
    if (type.nullabilitySuffix != expected) {
      fail('Expected $expected in ' + _typeString(type));
    }
  }

  void _assertNullabilityNone(DartType type) {
    _assertNullability(type, NullabilitySuffix.none);
  }

  void _assertNullabilityQuestion(DartType type) {
    _assertNullability(type, NullabilitySuffix.question);
  }

  void _assertNullabilityStar(DartType type) {
    _assertNullability(type, NullabilitySuffix.star);
  }

  String _typeParametersStr(TypeImpl type) {
    var typeStr = '';

    var typeParameterCollector = _TypeParameterCollector();
    type.accept(typeParameterCollector);
    for (var typeParameter in typeParameterCollector.typeParameters) {
      typeStr += ', $typeParameter';
    }
    return typeStr;
  }

  String _typeString(TypeImpl type) {
    if (type == null) return null;
    return type.getDisplayString(withNullability: true) +
        _typeParametersStr(type);
  }
}

class _TypeParameterCollector
    implements TypeVisitor<void>, InferenceTypeVisitor<void> {
  final Set<String> typeParameters = {};

  /// We don't need to print bounds for these type parameters, because
  /// they are already included into the function type itself, and cannot
  /// be promoted.
  final Set<TypeParameterElement> functionTypeParameters = {};

  @override
  void visitDynamicType(DynamicType type) {}

  @override
  void visitFunctionType(FunctionType type) {
    functionTypeParameters.addAll(type.typeFormals);
    for (var typeParameter in type.typeFormals) {
      var bound = typeParameter.bound;
      if (bound != null) {
        bound.accept(this);
      }
    }
    for (var parameter in type.parameters) {
      parameter.type.accept(this);
    }
    type.returnType.accept(this);
  }

  @override
  void visitInterfaceType(InterfaceType type) {
    for (var typeArgument in type.typeArguments) {
      typeArgument.accept(this);
    }
  }

  @override
  void visitNeverType(NeverType type) {}

  @override
  void visitTypeParameterType(TypeParameterType type) {
    if (!functionTypeParameters.contains(type.element)) {
      var bound = type.element.bound;
      var promotedBound = (type as TypeParameterTypeImpl).promotedBound;

      if (bound == null && promotedBound == null) {
        return;
      }

      var str = '';

      if (bound != null) {
        var boundStr = bound.getDisplayString(withNullability: true);
        str += '${type.element.name} extends ' + boundStr;
      }

      if (promotedBound != null) {
        var promotedBoundStr = promotedBound.getDisplayString(
          withNullability: true,
        );
        if (str.isNotEmpty) {
          str += ', ';
        }
        str += '${type.element.name} & ' + promotedBoundStr;
      }

      typeParameters.add(str);
    }
  }

  @override
  void visitUnknownInferredType(UnknownInferredType type) {}

  @override
  void visitVoidType(VoidType type) {}
}
