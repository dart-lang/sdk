// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BoundsHelperPredicatesTest);
    defineReflectiveTests(UpperBoundTest);
  });
}

@reflectiveTest
class BoundsHelperPredicatesTest extends _SubtypingTestBase {
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
    TypeParameterMember T2;

    // BOTTOM(Never) is true
    isBottom(neverNone);
    isNotBottom(neverQuestion);
    isNotBottom(neverStar);

    // BOTTOM(X&T) is true iff BOTTOM(T)
    T = typeParameter('T', bound: objectQuestion);

    T2 = promoteTypeParameter(T, neverNone);
    isBottom(typeParameterTypeNone(T2));
    isBottom(typeParameterTypeQuestion(T2));
    isBottom(typeParameterTypeStar(T2));

    T2 = promoteTypeParameter(T, neverQuestion);
    isNotBottom(typeParameterTypeNone(T2));
    isNotBottom(typeParameterTypeQuestion(T2));
    isNotBottom(typeParameterTypeStar(T2));

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

    T2 = promoteTypeParameter(typeParameter('T'), intNone);
    isNotBottom(typeParameterTypeNone(T2));
    isNotBottom(typeParameterTypeQuestion(T2));
    isNotBottom(typeParameterTypeStar(T2));
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
      typeParameterTypeNone(
        promoteTypeParameter(
          typeParameter('T', bound: objectQuestion),
          neverNone,
        ),
      ),
      typeParameterTypeQuestion(
        promoteTypeParameter(
          typeParameter('S', bound: objectQuestion),
          neverNone,
        ),
      ),
    );

    // MOREBOTTOM(X&T, S) = true
    isMoreBottom(
      typeParameterTypeNone(
        promoteTypeParameter(
          typeParameter('T', bound: objectQuestion),
          neverNone,
        ),
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
      typeParameterTypeNone(
        promoteTypeParameter(
          typeParameter('S', bound: objectQuestion),
          neverNone,
        ),
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

  String _typeParametersStr(TypeImpl type) {
    var typeStr = '';

    var typeParameterCollector = _TypeParameterCollector();
    DartTypeVisitor.visit(type, typeParameterCollector);
    for (var typeParameter in typeParameterCollector.typeParameters) {
      if (typeParameter is TypeParameterMember) {
        var base = typeParameter.declaration;
        var baseBound = base.bound as TypeImpl;
        if (baseBound != null) {
          var baseBoundStr = baseBound.toString(withNullability: true);
          typeStr += ', ${typeParameter.name} extends ' + baseBoundStr;
        }

        var bound = typeParameter.bound as TypeImpl;
        var boundStr = bound.toString(withNullability: true);
        typeStr += ', ${typeParameter.name} & ' + boundStr;
      } else {
        var bound = typeParameter.bound as TypeImpl;
        if (bound != null) {
          var boundStr = bound.toString(withNullability: true);
          typeStr += ', ${typeParameter.name} extends ' + boundStr;
        }
      }
    }
    return typeStr;
  }
}

@reflectiveTest
class UpperBoundTest extends _SubtypingTestBase {
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
      var T = typeParameterTypeNone(
        promoteTypeParameter(
          typeParameter('T', bound: objectQuestion),
          neverNone,
        ),
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
      typeParameterTypeNone(
        promoteTypeParameter(
          typeParameter('T', bound: objectQuestion),
          neverNone,
        ),
      ),
    );
  }

  test_functionType2_parameters_named() {
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

    // TODO(scheglov) Uncomment when DOWN is NNBD based.
//    check([intNone], [intStar], build([intNone]));
//    check([intNone], [doubleNone], build([neverNone]));

    check([intNone], [numNone], build([intNone]));

    check(
      [doubleNone, numNone],
      [numNone, intNone],
      build([doubleNone, intNone]),
    );
  }

  test_functionType2_parameters_required() {
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

    // TODO(scheglov) Uncomment when DOWN is NNBD based.
//    check([intNone], [intStar], build([intNone]));
//    check([intNone], [doubleNone], build([neverNone]));

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
    check(nullNone, intStar, intQuestion);

    check(nullQuestion, intNone, intQuestion);
    check(nullQuestion, intQuestion, intQuestion);
    check(nullQuestion, intStar, intQuestion);

    check(nullStar, intNone, intQuestion);
    check(nullStar, intQuestion, intQuestion);
    check(nullStar, intStar, intQuestion);

    check(nullNone, listNone(intNone), listQuestion(intNone));
    check(nullNone, listQuestion(intNone), listQuestion(intNone));
    check(nullNone, listStar(intNone), listQuestion(intNone));

    check(nullNone, futureOrNone(intNone), futureOrQuestion(intNone));
    check(nullNone, futureOrQuestion(intNone), futureOrQuestion(intNone));
    check(nullNone, futureOrStar(intNone), futureOrQuestion(intNone));

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
    if ((type as TypeImpl).nullabilitySuffix != expected) {
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

  void _checkLeastUpperBound(DartType T1, DartType T2, DartType expected) {
    var expectedStr = _typeString(expected);

    var result = typeSystem.getLeastUpperBound(T1, T2);
    var resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');

    // Check that the result is an upper bound.
    expect(typeSystem.isSubtypeOf(T1, result), true);
    expect(typeSystem.isSubtypeOf(T2, result), true);

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
class _SubtypingTestBase with ElementsTypesMixin {
  TypeProvider typeProvider;

  TypeSystemImpl typeSystem;

  InterfaceType _intNone;
  InterfaceType _intQuestion;
  InterfaceType _intStar;

  InterfaceType get doubleNone {
    var element = typeProvider.doubleType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get doubleQuestion {
    var element = typeProvider.doubleType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get doubleStar {
    var element = typeProvider.doubleType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  DartType get dynamicNone => typeProvider.dynamicType;

  InterfaceType get functionNone {
    var element = typeProvider.functionType.element;
    return interfaceTypeNone(element);
  }

  InterfaceType get functionQuestion {
    var element = typeProvider.functionType.element;
    return interfaceTypeQuestion(element);
  }

  InterfaceType get functionStar {
    var element = typeProvider.functionType.element;
    return interfaceTypeStar(element);
  }

  InterfaceType get intNone {
    if (_intNone != null) return _intNone;

    var element = typeProvider.intType.element;
    return _intNone = element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get intQuestion {
    if (_intQuestion != null) return _intQuestion;

    var element = typeProvider.intType.element;
    return _intQuestion = element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get intStar {
    if (_intStar != null) return _intStar;

    var element = typeProvider.intType.element;
    return _intStar = element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType get nullNone {
    var element = typeProvider.nullType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get nullQuestion {
    var element = typeProvider.nullType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get nullStar {
    var element = typeProvider.nullType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType get numNone {
    var element = typeProvider.numType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get numQuestion {
    var element = typeProvider.numType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get numStar {
    var element = typeProvider.numType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType get objectNone {
    var element = typeProvider.objectType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType get objectQuestion {
    var element = typeProvider.objectType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType get objectStar {
    var element = typeProvider.objectType.element;
    return element.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  FeatureSet get testFeatureSet {
    return FeatureSet.forTesting();
  }

  VoidType get voidNone => typeProvider.voidType;

  InterfaceTypeImpl futureOrNone(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceTypeImpl futureOrQuestion(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceTypeImpl futureOrStar(DartType type) {
    return typeProvider.futureOrElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  InterfaceType listNone(DartType type) {
    return typeProvider.listElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  InterfaceType listQuestion(DartType type) {
    return typeProvider.listElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.question,
    );
  }

  InterfaceType listStar(DartType type) {
    return typeProvider.listElement.instantiate(
      typeArguments: [type],
      nullabilitySuffix: NullabilitySuffix.star,
    );
  }

  void setUp() {
    var analysisContext = TestAnalysisContext(
      featureSet: testFeatureSet,
    );
    typeProvider = analysisContext.typeProvider;
    typeSystem = analysisContext.typeSystem;
  }

  String _typeParametersStr(TypeImpl type) {
    var typeStr = '';

    var typeParameterCollector = _TypeParameterCollector();
    DartTypeVisitor.visit(type, typeParameterCollector);
    for (var typeParameter in typeParameterCollector.typeParameters) {
      if (typeParameter is TypeParameterMember) {
        var base = typeParameter.declaration;
        var baseBound = base.bound as TypeImpl;
        if (baseBound != null) {
          var baseBoundStr = baseBound.toString(withNullability: true);
          typeStr += ', ${typeParameter.name} extends ' + baseBoundStr;
        }

        var bound = typeParameter.bound as TypeImpl;
        var boundStr = bound.toString(withNullability: true);
        typeStr += ', ${typeParameter.name} & ' + boundStr;
      } else {
        var bound = typeParameter.bound as TypeImpl;
        if (bound != null) {
          var boundStr = bound.toString(withNullability: true);
          typeStr += ', ${typeParameter.name} extends ' + boundStr;
        }
      }
    }
    return typeStr;
  }

  String _typeString(TypeImpl type) {
    if (type == null) return null;
    return type.toString(withNullability: true) + _typeParametersStr(type);
  }
}

class _TypeParameterCollector extends DartTypeVisitor<void> {
  final Set<TypeParameterElement> typeParameters = Set();

  /// We don't need to print bounds for these type parameters, because
  /// they are already included into the function type itself, and cannot
  /// be promoted.
  final Set<TypeParameterElement> functionTypeParameters = Set();

  @override
  void defaultDartType(DartType type) {
    throw UnimplementedError('(${type.runtimeType}) $type');
  }

  @override
  void visitDynamicType(DynamicTypeImpl type) {}

  @override
  void visitFunctionType(FunctionType type) {
    functionTypeParameters.addAll(type.typeFormals);
    for (var typeParameter in type.typeFormals) {
      var bound = typeParameter.bound;
      if (bound != null) {
        DartTypeVisitor.visit(bound, this);
      }
    }
    for (var parameter in type.parameters) {
      DartTypeVisitor.visit(parameter.type, this);
    }
    DartTypeVisitor.visit(type.returnType, this);
  }

  @override
  void visitInterfaceType(InterfaceType type) {
    for (var typeArgument in type.typeArguments) {
      DartTypeVisitor.visit(typeArgument, this);
    }
  }

  @override
  void visitNeverType(NeverTypeImpl type) {}

  @override
  void visitTypeParameterType(TypeParameterType type) {
    if (!functionTypeParameters.contains(type.element)) {
      typeParameters.add(type.element);
    }
  }

  @override
  void visitVoidType(VoidType type) {}
}
